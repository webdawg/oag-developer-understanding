# 0196 — Node sources is an unfiltered evidence sweep

Claim `B-0196`: at core `fb54e431332a030a566099c76fb2558084765422`,
`GraphService::find_sources` answers "why is this relationship here" by
returning every evidence row attached to every assertion on every edge touching
the node. REST and MCP expose the same helper. It does not filter by assertion
status, deduplicate evidence, or impose an order.

## Order of behavior

1. Both surfaces require `graph:read`, parse the node ID, and call
   `find_sources`. REST responds at `GET /api/v1/nodes/{id}/sources` with
   `{"sources": [...]}`; MCP's `graph_find_sources` returns the same shape.
2. `find_sources` acquires one connection and calls `edges::list_touching`,
   which selects edges where the node is subject or object with no `ORDER BY`.
3. For each edge it calls `assertions::list_by_edge`, which has no status
   predicate and no `ORDER BY`. For each assertion it calls
   `assertions::list_evidence`, also without an explicit order.
4. All evidence vectors are appended into one flat result. There is no
   deduplication by URI, content hash, source, or evidence ID, and no cap in
   this method.
5. A SQL error aborts the whole call. An unknown node has no touching edges and
   returns an empty list rather than `NotFound`.

## What is durable, rejected, and left behind

Durable: no state is changed. Rejected: missing/invalid API key or node ID at
the transport boundary; database errors inside the sweep. A result may include
evidence backing active, disputed, retracted, or superseded assertions, because
the helper is evidence-oriented rather than a current-truth query.

The endpoint was MCP-only before this commit; REST was added as the explicit
counterpart. The `sources.rs` helper itself is unchanged, so its ordering and
status behavior are the same in both revisions. No REST or MCP request was
executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0196a | Implemented evidence sweep | `crates/oag-graph/src/sources.rs:1-27` |
| B-0196b | Implemented REST surface and route | `crates/oag-api/src/handlers.rs:89-103`; `crates/oag-api/src/lib.rs:53` |
| B-0196c | Implemented MCP surface | `crates/oag-mcp/src/server.rs:333-345` |
| B-0196d | Implemented unordered/edge queries | `crates/oag-storage/src/repo/edges.rs:111-124`; `crates/oag-storage/src/repo/assertions.rs:117-126`, `204-213` |
| B-0196e | New REST surface since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-api/src/handlers.rs crates/oag-api/src/lib.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No endpoint or target test was executed.

## Change since the previously explained commit

At `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, `find_sources` existed only
behind MCP. At `fb54e431...`, the REST route and handler were added with the
same response shape. Findings 0178 and 0176 describe the same unordered storage
queries used for assertion and subgraph reads; neither is rewritten here.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining gap from
the journal and revision table.
