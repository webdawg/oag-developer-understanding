# 0055 — Rebuild replays events and preserves selected operator state

Claim `B-055`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, projection
rebuild deletes derived graph tables, replays every stored event in insertion
order, and recommit the transaction only after reapplying preserved redactions.
It does not delete the event log, event origins, peer tables, authority scores,
redactions, or search suppressions.

## What changes

The deleted tables include evidence, observations, assertion history,
assertions, actor keys, aliases, edges, actors, and nodes. Replay deserializes
each canonical payload and calls the same projector used by normal ingestion.
Outstanding evidence and actor-identity redactions are applied again because
their tables survive deletion.

The comment says existing authority scores remain valid because edges rebuild
identically. That assumes the replayed edge set matches the set used for the
last authority run. The function does not recompute authority or embeddings, so
those caches can still represent an older graph if they were stale before
rebuild. Search suppression survives by not being deleted, not by being
replayed.

The operation holds one transaction. Its comment says concurrent writers wait
rather than observe corruption, but a live server can stall. That concurrency
behavior was not executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-055a | Implemented | `crates/oag-storage/src/repo/rebuild.rs:1-43` |
| B-055b | Implemented | `crates/oag-graph/src/rebuild.rs:35-68` |

Verification: source inspection only. Rebuild tests were not executed.

## Next investigation

Trace evidence redaction itself and determine what fields it removes, who can invoke it, and whether event payloads remain recoverable after projection redaction.