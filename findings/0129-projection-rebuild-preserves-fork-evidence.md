# 0129 — Projection rebuild preserves fork evidence and does not replay it

Claim `B-129`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
`clear_projection_tables` deletes a fixed list of graph tables. `peer_forks`
is not in that list. The comment explicitly excludes peer-network tables. The
graph rebuild calls that function, replays rows from `events` in insertion
order, reapplies redactions, and commits.

## What survives

A fork row remains after rebuild because nothing deletes it. The conflicting
event is not inserted into `events` by the replay, so rebuild cannot turn fork
evidence into a projected assertion. The first event at the occupied sequence
is replayed if it is in `events`. The comment also says a live server would
stall for the transaction. That stall was not measured. No rebuild was run.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-129a | Implemented exclusion | `oag-storage/src/repo/rebuild.rs:1-11` and `20-41` |
| B-129b | Implemented replay | `oag-graph/src/rebuild.rs:41-64` |

Verification: source inspection only.

## Next investigation

Trace actor-key revocation and determine whether a remote event signed by a revoked key is rejected during ingest or only hidden later.