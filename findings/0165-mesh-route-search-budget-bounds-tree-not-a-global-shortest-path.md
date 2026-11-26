# 0165 — Mesh route-search budget bounds the tree, not path optimality

Claim `B-0165`: at mesh `45f9fa8a16f65fc4a2e2fe5238bbbc2a5e462574`, a
distributed route search carries a fan-out budget that is spent one unit per
outbound request and divided among children. The result is the shortest path
found by nodes that answered within that budget and hop limit, not a proven
global shortest path. A separate inbound token bucket limits how many route
requests one node accepts per second.

## Order of behavior

1. `find_route_across_mesh` starts with `DEFAULT_ROUTE_SEARCH_FANOUT_BUDGET =
   256`, caller-supplied `max_hops` and `min_corroboration`, and an empty
   `already_asked` list. `find_route_across_mesh_with_budget(..., 0, ...)`
   permits local lookup only.
2. At each node, `search_for_route` first tries its own
   `MeshTree::shortest_path`; a local answer returns without network traffic.
3. If no local answer, `remaining_hops == 0` or `fanout_budget == 0` ends that
   branch. Otherwise the node orders configured peers not already in that
   branch's `already_asked` by link quality (finding 0162).
4. It asks `ask_count = min(peer_count, fanout_budget)` peers, spends that many
   budget units, and gives every child the integer-divided remainder
   `(fanout_budget - ask_count) / ask_count`. A budget of 1 therefore asks one
   peer and gives its children zero.
5. Each outbound request uses the same `RouteSearchRequest` with
   `remaining_hops - 1`, an extended `already_asked`, and the child budget.
   `already_asked` is per branch: two branches can still contact the same peer
   with different histories.
6. Tasks run in a `JoinSet`; the shortest returned path wins. A path of length
   two or less is treated as the global minimum and aborts the remaining tasks.
   `None` means nothing was found within this search's hop/budget reach.

## What the two limits do and do not bound

The fan-out budget is a field in the serialized request body and is divided
recursively, so a single started search cannot create more outbound
route-search requests than its starting budget. The inbound `TokenBucket`
(capacity 8, refill 2/s, finding 0159) is node-wide and has no requester
identity: it throttles accepted requests at one node regardless of which search
or caller produced them. Neither limit proves global path optimality or
deduplicates all visits across branches.

Rejected/admitted: a node with no local path and no remaining hops or budget
returns `None`; a node whose inbound bucket is empty answers 429 before running
local search. Failed or rejected peer requests are still link-quality
observations. No HTTP request or target test was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0165a | Implemented recursive search | `crates/oag-mesh/src/transport.rs:916-1017` |
| B-0165b | Implemented entry points and default budget | `crates/oag-mesh/src/transport.rs:83`, `1064-1124` |
| B-0165c | Implemented inbound gate | `crates/oag-mesh/src/transport.rs:1019-1045`; `crates/oag-mesh/src/rate_limit.rs:17-80` |
| B-0165d | New since explained commit | `git diff 9f5d89e9..45f9fa8a -- crates/oag-mesh/src/transport.rs crates/oag-mesh/src/rate_limit.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No mesh search was run.

## Change since the previously explained commit

Distributed route search, the fan-out budget, its inbound limiter, and the
route-search endpoint are new at `45f9fa8a...` relative to explained
`9f5d89e9...`. Findings 0159 and 0162 describe its limiter and ordering input;
this finding describes the search itself. No older finding is rewritten.

## Next investigation

Trace `oag_mesh::transport::pull_and_merge` and `heads_changed` to document how
sync decides a store is stale, what it merges, and what a partial pull leaves
behind.
