# 0191 — Listend's Reticulum carrier isolates slow links per worker

Claim `B-0191`: at listend `b87dcac9a3c9e0059d90e698e2ec40fb2769ec41`, the
optional Reticulum carrier reassembles frames on a shared event loop but hands
each link's frames to its own worker. It caps links and queued frames, drops a
link's buffer when a peer outpaces its worker, and bounds each packet send to
10 seconds. The audio rule is unchanged.

## Order of behavior

1. `bind` derives a `PrivateIdentity` from the stable seed string, registers a
   Reticulum TCP server interface, and adds destination
   `("oag-listend", "audio")`. The same seed yields the same address after a
   restart.
2. `run` spawns an announce task that sends every five seconds. The event loop
   keeps a `LinkBuffers` map and a worker-sender map, both capped at 64 entries.
3. On activation it creates a buffer and worker if capacity allows. On close it
   drops both. Data from a link is appended to that link's buffer; the buffer is
   removed if it grows beyond `MAX_FRAME_BYTES + CHUNK_SIZE` or if a declared
   frame length exceeds `MAX_FRAME_BYTES`.
4. Complete frame bodies are tried on the link's bounded `mpsc` channel. A full
   or closed channel drops that link's buffer and worker rather than blocking
   the shared event loop.
5. Each worker owns its receiver in order. It decodes the frame with the shared
   protocol parser, calls the shared `handle`, and sends the response back in
   1400-byte packets. Any packet send that exceeds 10 seconds abandons the rest
   of that frame.
6. Shutdown ends the event loop; workers are tracked with `ActiveGuard` so the
   process-level grace period can wait for in-flight exchanges.

## What is durable, rejected, and left behind

Durable: no carrier state is persisted. Accepted publishes still go through
`AudioStore::accept`; rejected frames become `Response::Rejected`. A link whose
buffer exceeds bounds, whose worker is full, or whose send times out is dropped
or abandoned without stalling other links.

This is Reticulum over a TCP interface, not radio, and it is feature-gated
because the dependency is heavy. It calls the same `crate::server::handle` as
the other carriers, so there is no separate audio admission rule. No Reticulum
interface or target test was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0191a | Implemented feature gate, constants, and identity | `crates/oag-listend/src/reticulum.rs:1-61`, `134-170` |
| B-0191b | Implemented link reassembly bounds | `crates/oag-listend/src/reticulum.rs:63-118` |
| B-0191c | Implemented event loop and per-link workers | `crates/oag-listend/src/reticulum.rs:195-285` |
| B-0191d | Implemented chunked bounded reply | `crates/oag-listend/src/reticulum.rs:287-311` |
| B-0191e | Compared guard change | `git diff aad2d9b2..b87dcac9 -- crates/oag-listend/src/reticulum.rs` |

Verification: source inspection via `git show origin/master:<path>` and a scoped
diff. No Reticulum interface or target test was executed.

## Change since the previously explained commit

At `aad2d9b2cc763239764fa8ba11ec7e871be00e11`, worker entries used manual
`fetch_add`/`fetch_sub`. At `b87dcac9...`, `ActiveGuard` releases the active
counter on return or panic. Findings 0182 and 0190 describe the shared guard
and process grace period; this finding records the Reticulum-specific
concurrency structure.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining gap from
the journal and revision table.
