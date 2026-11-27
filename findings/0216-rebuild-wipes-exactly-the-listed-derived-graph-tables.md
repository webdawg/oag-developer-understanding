# 0216 — Rebuild wipes exactly the listed derived graph tables

Claim `B-0216`: at core `fb54e431332a030a566099c76fb2558084765422`,
`clear_projection_tables` deletes rows from a fixed list of eleven graph
projection tables. Every other schema table — event log, peer state, operator
decisions, and several local caches — survives a rebuild. Only two redaction
tables are explicitly reapplied afterward.

## Order of behavior

1. `rebuild_projection` starts one `BEGIN IMMEDIATE` write transaction.
2. `clear_projection_tables` issues `DELETE FROM` statements in child-first
   order: evidence, observations, assertion disputes/retractions/supersessions,
   assertions, actor_keys, node_aliases, edges, actors, nodes.
3. It loads all event rows ordered by `rowid`, deserializes each signed payload,
   and calls the same projector used at first ingestion. Projection rebuilds the
   deleted graph tables.
4. It then reapplies evidence redactions and actor identity-URI redactions from
   their tombstones. Search suppressions are not replayed; they remain a live
   filter in `nodes::search`.
5. Tables absent from the wipe list are not touched by these statements. The
   migration inventory shows event-log tables (`events`, `event_refs`,
   `event_origins`), peer tables (`peers`, `peer_addresses`, `peer_forks`,
   `peer_known_heads`, `peer_presence`, `address_going_offline`,
   `peer_cluster_claims`), operator-state tables (`redactions`,
   `actor_identity_uri_redactions`, `search_suppressions`), and caches/indexes
   (`node_authority`, `node_embeddings`, `node_gravity`, `tensor_pads`,
   `pinned_cids`) all survive.

## What is durable, rejected, and left behind

Durable across rebuild: the event log, peer state, operator decisions, and the
listed caches/indexes. Derived graph rows are deleted and rebuilt in one
transaction; a projector failure aborts the whole rebuild, leaving the old
committed state rather than a partial wipe.

The module comment explicitly explains the event, peer, authority, and operator
exclusions. It does not give separate rationales for `node_embeddings`,
`node_gravity`, `tensor_pads`, or `pinned_cids`; their survival is an observed
consequence of the hardcoded delete list, not a documented policy in that file.
No rebuild was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0216a | Implemented wipe list and delete order | `crates/oag-storage/src/repo/rebuild.rs:1-44` |
| B-0216b | Implemented rebuild transaction and reapplication | `crates/oag-graph/src/rebuild.rs:31-82` |
| B-0216c | Schema table inventory | `git grep -n "^CREATE TABLE" origin/main -- crates/oag-storage/migrations` |
| B-0216d | Compared transaction change | `git diff 87f9e8c1..fb54e431 -- crates/oag-graph/src/rebuild.rs` |

Verification: source inspection via `git show origin/main:<path>`, `git grep`, and
a scoped diff. No database or rebuild was executed.

## Change since the previously explained commit

The wipe list is unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`; the rebuild service changed only to
use `BEGIN IMMEDIATE`. Finding 0055 described the broad preservation behavior;
this finding enumerates the exact delete list and the schema tables outside it.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining gap from
the journal and revision table.
