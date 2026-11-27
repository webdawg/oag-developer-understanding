# 0215 — Authority cache is cleared before recompute but survives rebuild

Claim `B-0215`: at core `fb54e431332a030a566099c76fb2558084765422`,
`recompute_authority` deletes all stored scores before writing replacements and
does not wrap the operation in one transaction. A failure partway through can
leave no or partial scores. `oag rebuild`, by contrast, deliberately preserves
the authority cache because replay reconstructs byte-identical edges.

## Order of behavior

1. `recompute_authority` reads all edges, converts each to a
   `(subject, object)` pair, runs batch PageRank, and gets scores plus iteration
   count.
2. It calls `node_authority::clear_all`, which executes `DELETE FROM
   node_authority`.
3. It stores one `upsert` per scored node with `computed_at = now()`. Storage
   converts the `f32` score to `f64` for SQLite and back on read.
4. `get_node_authority` returns `None` when no score row exists; a node with no
   edges receives no score from a recompute.
5. `clear_projection_tables` does not include `node_authority`. Its comment says
   edges reconstruct byte-identically from the event log, so existing authority
   scores remain valid without recomputation.

## What is durable, rejected, and left behind

Durable after a successful recompute: one score per edge-participating node.
Durable after a partial failure: whatever upserts completed before the error;
the clear is not rolled back by this function. A rejected/absent node is simply
missing from the score table.

Authority is not maintained on ordinary writes and is not recomputed at
startup. It can therefore be stale until an operator reruns it, even though
rebuild preserves it. No recompute, failure, or rebuild was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0215a | Implemented recompute sequence | `crates/oag-graph/src/authority.rs:91-124` |
| B-0215b | Implemented authority storage | `crates/oag-storage/src/repo/node_authority.rs:1-44` |
| B-0215c | Implemented rebuild exclusion | `crates/oag-storage/src/repo/rebuild.rs:1-13`, `20-44` |
| B-0215d | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-graph/src/authority.rs crates/oag-storage/src/repo/node_authority.rs crates/oag-storage/src/repo/rebuild.rs` (no output) |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No recompute or rebuild was executed.

## Change since the previously explained commit

The authority and rebuild code is unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Finding 0054 describes the
PageRank algorithm; this finding records the cache lifecycle and rebuild
boundary.

## Next investigation

Trace `oag_storage::repo::rebuild::clear_projection_tables` against the full
schema to list precisely which tables survive a projection wipe and why.
