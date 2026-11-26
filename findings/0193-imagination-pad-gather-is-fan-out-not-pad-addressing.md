# 0193 — Imagination pad gathering asks nodes, not pads

Claim `B-0193`: at imagination `73fadb3ccdc6249fb21d0410e1b5a794be70fe40`,
a TCP node answers every `PadRequest` with its own local `DataPad`; the
request's `pad_id` field is ignored. `gather_file_with` sends identical empty-ID
requests to a caller-supplied node list, up to 32 in flight, then relies on
`datapad::gather` matching the returned pads' real IDs to the manifest.

## Order of behavior

1. `serve_on_with_limits` acquires a connection permit before accepting, so a
   full server stops accepting rather than queuing unread sockets. The default
   cap is 1024 and the inbound read is bounded.
2. A `Message::Request` goes through the engine and may be forwarded to the
   next hop. A `Message::PadRequest(_)` does not: the server locks the engine
   and returns `Message::PadResponse(engine.data_pad())`. A `PadResponse` sent
   by a client is ignored.
3. `Engine::data_pad` builds a pad with `pad_id = node_id`, the current routing
   weights, and the node's optional shard. The request's stated pad ID is not
   used to select a pad.
4. `gather_file_with` spawns one padded request per address in `nodes`, bounded
   by `MAX_CONCURRENT_GATHERS = 32`. Every request carries
   `PadRequest { pad_id: String::new() }`.
5. Completed messages are pushed into a pad vector as they arrive; any
   non-`PadResponse` is `NotAPad`, and task/transport errors become
   `DataPadError::Transport`. `datapad::gather` then maps pads by their returned
   `pad_id`, follows `manifest.pad_ids` order, and `reconstruct` verifies count,
   indices, and BLAKE3.

## What is durable, rejected, and left behind

Durable: the server reads existing engine state and writes nothing; gathering
builds only in-memory pads and the reconstructed bytes. Rejected: read timeouts
drop a connection, unexpected responses are `NotAPad`, and missing pad IDs,
missing shards, count/index errors, or hash mismatch come from the datapad
layer. There is no retry in this gather path.

Because senders ignore the requested pad ID, the caller must supply node
addresses whose returned `pad_id` values match the manifest. Completion order
does not matter after `gather`, but duplicate returned pad IDs collapse in its
map to the last one. No TCP server, gather call, or target test was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0193a | Implemented server pad branch and limits | `crates/oag-imagination/src/socket.rs:448-550` |
| B-0193b | Implemented concurrent gather | `crates/oag-imagination/src/socket.rs:552-607` |
| B-0193c | Implemented local pad source | `crates/oag-imagination/src/engine.rs:501-508` |
| B-0193d | Implemented pad matching and verification | `crates/oag-imagination/src/datapad.rs:131-149`, `111-129` |
| B-0193e | Unchanged since explained commit | `git diff 7b7dcb8e..73fadb3c -- crates/oag-imagination/src/socket.rs` (no output) |

Verification: source inspection via `git show origin/master:<path>` and a scoped
diff. No carrier or gather was executed.

## Change since the previously explained commit

The TCP serving and pad-gather code is unchanged between
`7b7dcb8eae70b2df2fa1329fdb7b2dd928e76d29` and
`73fadb3ccdc6249fb21d0410e1b5a794be70fe40`. Finding 0192 describes the split
and verification primitives; this finding records the carrier's fan-out and the
ignored request pad ID.

## Next investigation

Trace `oag_imagination::socket::ProxiedTransport` and `HttpIpfsPublisher` to
document the remaining carrier seams and their failure boundaries.
