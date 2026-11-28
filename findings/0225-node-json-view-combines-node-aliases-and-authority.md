# 0225 — The node JSON view combines node, aliases, and cached authority

Claim `B-0225`: at core `fb54e431332a030a566099c76fb2558084765422`,
`GET /api/v1/nodes/{id}` returns exactly three keys: `node`, `aliases`, and
`authority`. It is a direct lookup, not a search result, so search suppression
does not hide the node. Edges, assertions, evidence, and provenance are on
other endpoints.

## Order of behavior

1. The handler requires `graph:read`, parses the path ID into a `NodeId`, and
   returns 404 if no node row exists.
2. It calls `get_node`, `list_aliases`, and `get_node_authority` with the same
   parsed ID.
3. JSON is built as `{"node": node, "aliases": aliases, "authority": authority}`.
   `authority` is `null` when the authority cache has no score for that node.
4. Alias order is whatever storage returned; the alias query has no `ORDER BY`.
   The node object includes canonical identifier, optional URI/name/description,
   metadata, type, creation time, and ID.
5. Related endpoints supply edges, assertions, evidence sources, and history;
   this view does not expand them.

## What is durable, rejected, and left behind

Durable: nothing is written. Rejected: unauthenticated reads, invalid IDs, and
missing nodes. A suppressed node still returns here because suppression is a
filter in `nodes::search`, not a flag on the node row.

The authority value is a cached derived score, not recomputed for this request
and not a truth signal. No HTTP request was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0225a | Implemented handler | `crates/oag-api/src/handlers.rs:50-65` |
| B-0225b | Implemented alias/authority services | `crates/oag-storage/src/repo/nodes.rs:146-155`; `crates/oag-graph/src/authority.rs:119-124` |
| B-0225c | Implemented suppression boundary | `crates/oag-storage/src/repo/nodes.rs:157-163`; finding 0051 |
| B-0225d | Related endpoints | `crates/oag-api/src/handlers.rs:67-103` |
| B-0225e | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-api/src/handlers.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No HTTP request was executed.

## Change since the previously explained commit

The node JSON handler is unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`; the changed regions in `handlers.rs`
are other added endpoints. Findings 0202 and 0215 describe node metadata and
authority; this finding records their REST composition.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining gap from
the journal and revision table.
