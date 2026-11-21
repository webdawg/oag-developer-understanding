# 0087 — A new peer ID starts sequence 1 without erasing the old chain

Claim `B-087`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, local event
sequence is chosen from `event_origins` for the current identity's peer ID. If
that origin row is absent, the next sequence is 1 and there is no previous
event. A new ephemeral or regenerated identity therefore starts its own chain
in the same database.

## State

The old peer's events and origin row remain. The new peer does not continue the
old sequence and does not present the old head as its predecessor. Readers that
key history by origin see two peers. Replication status for the old peer ID is
not automatically transferred to the new one. Nothing in the sequence selector
deletes or re-signs old events.

This connects findings 0085 and 0086 to the commit path. It was not executed by
starting an ephemeral server against an existing database. The conclusion
follows from the peer-ID-keyed origin lookup and the startup identity selection.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-087 | Implemented | `crates/oag-events/src/commit.rs:35-50` |
| B-087-startup | Implemented identity selection | `crates/oag-cli/src/serve.rs:18-24` |

Verification: source inspection only.

## Next investigation

Trace whether remote ingestion of the new peer's sequence-1 event requires its key to be discovered first, and whether the old peer remains advertised through the peer table.