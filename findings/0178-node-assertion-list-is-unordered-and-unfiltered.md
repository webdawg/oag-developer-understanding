# 0178 — A node's assertion list is unordered and unfiltered

Claim `B-0178`: at core `fb54e431332a030a566099c76fb2558084765422`,
`list_assertions_for_node` returns every assertion attached to any edge that
touches the node. It does not sort the edges or assertions and does not filter
by assertion status. The same request can therefore produce the same facts in a
different order on different executions.

## Order of behavior

1. `list_assertions_for_node` loads the node's edges through
   `edges::list_touching`, whose SQL selects rows where the node is either
   subject or object with no `ORDER BY`.
2. It iterates those edges and calls `assertions::list_by_edge` for each one.
   That query is `SELECT * FROM assertions WHERE edge_id = ?`, also with no
   `ORDER BY`.
3. Each returned assertion vector is appended to one flat result. There is no
   status predicate, so active, disputed, retracted, superseded, and any other
   stored status are all included.
4. The result is a read-only view over projection tables. No event log row or
   node/edge/assertion row is modified.

## What is durable, rejected, and left behind

Durable: no new state. A missing node is not checked here; an unknown ID simply
has no touching edges and produces an empty list. SQL errors abort the whole
method, leaving no partial response.

Ordering is unspecified at both levels. Unlike `get_subgraph` (finding 0176),
this path was not given a deterministic sort at the newer commit. Callers that
need a stable view must sort locally. The function also makes no visibility
decision: a suppressed node's edges and assertions still appear through this
route, because suppression only affects search queries. No request was
executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0178a | Implemented service loop | `crates/oag-graph/src/resolve.rs:82-99` |
| B-0178b | Implemented edge query | `crates/oag-storage/src/repo/edges.rs:111-124` |
| B-0178c | Implemented assertion query | `crates/oag-storage/src/repo/assertions.rs:117-126` |
| B-0178d | Unchanged except unrelated signature | `git diff 87f9e8c1..fb54e431 -- crates/oag-graph/src/resolve.rs crates/oag-storage/src/repo/edges.rs crates/oag-storage/src/repo/assertions.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No request or target test was executed.

## Change since the previously explained commit

Between `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`, `resolve.rs` changed only because
the underlying `nodes::search` signature gained an offset argument. The
assertion-list behavior is unchanged. Finding 0176's deterministic subgraph
ordering does not apply to this route.

## Next investigation

Re-fetch on the next invocation, then search for an undocumented mechanism in
`oag-api/src/transfer.rs` at the newer core commit.
