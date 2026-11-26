# 0156 — Imagination's Reticulum carrier is a separate framed transport

Claim `B-0156`: at imagination `73fadb3ccdc6249fb21d0410e1b5a794be70fe40`,
the `oag-imagination-reticulum` crate adapts the engine to Reticulum with a
seed-derived identity, a 4-byte length-prefixed JSON frame split into 1400-byte
chunks, an 8 MiB logical message cap, and three explicit send timeouts. It is a
separate crate from both `oag-imagination` and the base project's Reticulum
transport; sharing the wire shape is documented intent, not shared code.

## Order of behavior

1. `connect` derives a `PrivateIdentity` from a caller-supplied seed string via
   `new_from_name`, creates a Reticulum transport with application name
   `oag-imagination`, and spawns a TCP client to the supplied uplink. A stable
   seed is required because it determines the node's address.
2. A send acquires `send_lock`, parses the destination address, waits up to
   `ANNOUNCE_WAIT` (30 s, overridable) for a matching announce, creates a link,
   and waits up to `LINK_ACTIVATE_WAIT` (15 s) for activation.
3. `encode_message` serializes JSON, rejects bodies over 8 MiB, and prepends a
   big-endian 32-bit length. The frame is sent in 1400-byte `data_packet`
   chunks. The client waits up to `REPLY_WAIT` (15 s), reassembling reply chunks
   with a per-request `Reassembler` and decoding a framed `Message`.
4. Any error on the `ReticulumCarrier::send` path becomes `None`. The
   `Transport::send` adapter converts that `None` into an `io::Error` of kind
   `TimedOut`; the source text does not distinguish announce, link, reply, and
   framing failures at that boundary.
5. The server announces every 5 seconds, keeps one `Reassembler` per link ID,
   removes buffers on close or framing error, and answers only
   `Message::Request`. The engine mutates the request in place and the mutated
   request is sent back; the result of `engine.handle` is discarded at this call
   site. Non-request messages are ignored.

## What is durable, rejected, and left behind

Durable state is limited to Reticulum's own transport and the engine's in-memory
state; this crate adds no storage. Rejected before engine handling: invalid
addresses, oversized declared or actual frames, malformed JSON, and messages
that are not requests. A send failure leaves no reply and is degraded to the
engine's normal failure path.

The server has no oag-crypto identity check: the crate does not depend on
`oag-crypto`, and its identity comes from a seed string. The module comment says
the wire format matches the base project's Reticulum transport so the two could
interoperate, but there is no shared framing module in the manifest. The TCP
carrier's logical frame cap is 16 MiB (finding 0155); this carrier's is 8 MiB.
No Reticulum link, announce, or target test was run.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0156a | Implemented identity, limits, and errors | `crates/oag-imagination-reticulum/src/lib.rs:19-34`, `52-111` |
| B-0156b | Implemented framing and reassembly | `crates/oag-imagination-reticulum/src/lib.rs:113-176` |
| B-0156c | Implemented client sequence and timeouts | `crates/oag-imagination-reticulum/src/lib.rs:178-342` |
| B-0156d | Implemented server loop | `crates/oag-imagination-reticulum/src/lib.rs:351-470` |
| B-0156e | Confirmed crate boundary | `crates/oag-imagination-reticulum/Cargo.toml:7-15`; `crates/oag-imagination/src/socket.rs:25-34` |

Verification: source inspection via `git show origin/master:<path>` at the
stated commit. No network or target test was executed.

## Change since the previously explained commit

The imagination library is unchanged between
`7b7dcb8eae70b2df2fa1329fdb7b2dd928e76d29` and
`73fadb3ccdc6249fb21d0410e1b5a794be70fe40`; only scripts changed. Finding
0155's plain URL resolver still holds at the newer commit. This finding
documents the separate Reticulum crate at the same head.

## Next investigation

Inspect `data-roads` main `b5cd2f4e8618f955eb06dd1c4d3edc7234041a7e` for the
largest unresolved requirement in its proposal, and record what is still
unknown rather than presenting it as implementation.
