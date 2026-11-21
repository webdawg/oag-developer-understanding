# 0109 — Listend persists successful CIDs and forgets failed mirrors

Claim `B-109`: at listend `aad2d9b2cc763239764fa8ba11ec7e871be00e11`, a
successful IPFS add writes `<content hash>.cid` beside the audio and records
the association in memory. A failed add is appended only to an in-memory log of
at most 64 outcomes. The oldest outcome is dropped when the log is full. No
failure sidecar was found.

## Restart behavior

The success sidecar lets a later start skip re-adding that item. A write error
is ignored, so a successful add can still be retried after restart if the
sidecar is lost. A failure has no durable marker, so the next startup with
`--ipfs-api` offers the item again until the 30-second budget ends. The
in-memory failure reason disappears at process exit and can also disappear
earlier when the 64-entry log wraps. This is best-effort mirroring, not a
durable work queue.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-109a | Implemented | `oag-listend/src/lib.rs:387`, `655-679`, and `732-744` |
| B-109b | Implemented persistence | `oag-listend/src/lib.rs:880-897` |

Verification: source inspection only. No files were written.

## Next investigation

Trace collisions index eviction and determine whether a replacement can remove a higher-ranked item or only the oldest one.