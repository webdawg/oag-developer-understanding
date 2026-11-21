# 0126 — A sequence gap is retried; a full page resumes at the new head

Claim `B-126`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, the next
fetch start is the local origin's highest contiguous sequence plus one. A
`SequenceGap` or other ingest error does not advance that sequence. The next
gossip tick therefore requests the same start again.

## Successful page

The server returns at most 1000 events beginning at the requested `from`. If
those events ingest and advance the origin, the following tick starts after the
new head and can request the remainder through the hello head. A permanent hole
does not advance, so the same failing range is attempted on every tick until
the stored rows change or the peer is no longer selected. The loop does not
record a quarantine or skip count. No gossip tick was run.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-126a | Implemented start | `oag-sync/src/service.rs:280-287` and `351-353` |
| B-126b | Implemented stop | `oag-sync/src/service.rs:385-389` |
| B-126c | Implemented page cap | `oag-sync/src/server.rs:78-92` |

Verification: source inspection only.

## Next investigation

Trace `local_heads` after a fork and determine whether a forked origin is still offered to later peers or skipped.