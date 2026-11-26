# 0154 — Listend's startup IPFS mirror now runs beside live traffic

Claim `B-0154`: at listend `b87dcac9a3c9e0059d90e698e2ec40fb2769ec41`, the
startup mirror pass starts only after carriers are serving. It snapshots
`Arc<AudioItem>` handles under the store lock, releases that lock for each
network call, and keeps only a bounded 30-second whole-pass budget. This
replaces the older owned-store pass that ran before anything bound and could
delay serving for a slow IPFS node.

## Order of behavior

1. `main` spawns the native, HTTP, UDP, Unix, and optional Reticulum servers
   first. If `--ipfs-api` is configured and the store is non-empty, it calls
   `mirror_existing_shared` with `STARTUP_MIRROR_BUDGET` (30 s) and prints how
   many items were offered.
2. `mirror_existing_shared` locks the store only long enough to take sorted
   content hashes and clone `Arc<AudioItem>` handles via `serve`. Sorted hashes
   come from `AudioStore::hashes`; directory iteration order is deliberately not
   exposed to clients.
3. For each item it computes the remaining pass time; an expired deadline ends
   the loop. Items not reached are not offered in this pass.
4. `offer_shared` locks the store briefly to read the IPFS provider, directory,
   and whether the hash already has a recorded CID. Already-mirrored items and
   a missing provider return false without an offer.
5. `add_to_ipfs` runs under `tokio::time::timeout(remaining, ...)`. A timeout
   becomes a `Failed` outcome with reason "the node did not answer in time".
   A successful mirror writes `<hash>.cid` beside the audio under the storage
   timeout, then a second brief lock records the outcome through
   `record_mirror`. Failures are recorded but no CID sidecar is written.
6. On shutdown, `main` prints the in-memory mirror summary and the last 64
   outcomes from the bounded mirror log.

## What is durable, rejected, and left behind

Durable after success: the CID sidecar plus in-memory hash-to-CID and CID-to-hash
maps. Durable after failure: only the bounded in-memory `MirrorOutcome` log; no
CID is stored, so a later restart can offer the item again. A timed-out offer
consumes pass time and moves to the next item; it is not retried inside this
pass. Lock contention during the brief snapshot and record steps is bounded by
the store mutex, not by the IPFS node's response time.

The old `AudioStore::mirror_existing` still exists in the library but is not the
path `main` uses at startup. Finding 0108's "startup mirrors the stored library"
remains true at a high level; this finding corrects its ordering and lock
behavior. Finding 0109's "mirror failures are memory-only" remains true, while
successes now persist a CID sidecar. No daemon or IPFS node was started.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0154a | Implemented startup ordering | `crates/oag-listend/src/main.rs:453-472`, `481-485` |
| B-0154b | Implemented shared mirror pass | `crates/oag-listend/src/lib.rs:959-1010`, `1012-1040` |
| B-0154c | Implemented budget and log bound | `crates/oag-listend/src/lib.rs:427-435` |
| B-0154d | Implemented CID persistence | `crates/oag-listend/src/lib.rs:1123-1137` |
| B-0154e | Compared change | `git diff aad2d9b2..b87dcac9 -- crates/oag-listend/src/lib.rs crates/oag-listend/src/main.rs` |

Verification: source and diff inspection only. No IPFS node, daemon, or target
test was run.

## Change since the previously explained commit

At `aad2d9b2cc763239764fa8ba11ec7e871be00e11`, `main` called the owned-store
`mirror_existing` before the daemon was serving. At `b87dcac9...`, that call is
replaced by `mirror_existing_shared` after server tasks are spawned; the new
helper, `offer_shared`, and the "the node did not answer in time" failure reason
are added. Findings 0152 and 0153 record the related listend changes; no older
finding is rewritten here.

## Next investigation

Move to `oag-imagination-random-data-compute` master
`73fadb3ccdc6249fb21d0410e1b5a794be70fe40`, compare it with explained
`7b7dcb8eae70b2df2fa1329fdb7b2dd928e76d29`, and document one changed or still
undocumented mechanism.
