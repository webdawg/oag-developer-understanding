# 0173 — Search cursor is a row boundary, not an offset position

Claim `B-0173`: at core `fb54e431332a030a566099c76fb2558084765422`,
`search_page` accepts either `offset` or an opaque `next_cursor`; when both are
present the cursor wins. The cursor stores the last node ID, and the next page
is the rows whose current FTS5 `(rank, node_id)` sorts after it. A malformed or
stale cursor restarts the walk rather than returning an error.

## Order of behavior

1. REST `GET /api/v1/search` calls `search_page(query, limit, offset, cursor)`
   after `graph:read`. The query DTO documents that cursor takes precedence and
   that a cursor is preferred when the result set can change.
2. `search_page` calls `search_after` whenever `cursor` is `Some`; otherwise it
   calls the older offset-based `search` and offers a cursor when the returned
   page is full. That offset-path cursor is derived from the last returned node.
3. `SearchCursor` encodes a `NodeId` as 64 hex digits. `decode` returns `None`
   for an invalid string, and `search_after` treats `None` as a fresh walk.
4. The storage layer recomputes the boundary node's current FTS5 `rank` for
   this query. If that node no longer matches, `current_rank` yields `None` and
   the SQL `WHERE ? IS NULL OR ...` starts from the beginning.
5. `search_after` fetches `limit + 1` rows from the suppressed-filtered FTS
   view, orders by `search_rank, node_id`, keeps those strictly after the
   boundary, truncates to `limit`, and returns `next_cursor` only when the extra
   row showed more results.
6. `limit` is clamped to `[0, 1000]`; an empty sanitized query returns an empty
   page with no cursor. Latency is recorded only after a successful query.

## What is durable, rejected, and left behind

No cursor server state is durable or stored: the token is just a node ID, and
the rank is recomputed against the current index. A cursor from a different
query is accepted but meaningless because rank is query-specific; a malformed
or stale cursor silently starts over. Neither is an error response.

Offset walking can repeat or skip a row if a newly ranked document changes the
ordering. Keyset walking tolerates insertions before the boundary but cannot
fix a true reordering of rows around it. The offset path emits a cursor on a
full page even when it happens to be the last page; the caller may receive one
empty continuation. No search request or test was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0173a | Implemented service pagination | `crates/oag-graph/src/search.rs:70-150` |
| B-0173b | Implemented cursor and keyset SQL | `crates/oag-storage/src/repo/nodes.rs:200-305` |
| B-0173c | Implemented REST surface | `crates/oag-api/src/handlers.rs:16-30`; `crates/oag-api/src/dto.rs:145-159` |
| B-0173d | New since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-graph/src/search.rs crates/oag-storage/src/repo/nodes.rs crates/oag-api/src/handlers.rs crates/oag-api/src/dto.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No search request or target test was executed.

## Change since the previously explained commit

`SearchPage`, `search_page`, `search_after`, `SearchCursor`, the REST `cursor`
field, and `next_cursor` response are new at `fb54e431...` relative to explained
`87f9e8c1...`. Finding 0170 records where search timing is sampled; this finding
records what the paged contract actually guarantees.

## Next investigation

Trace `oag_api::handlers::search` and `oag_mcp::OagMcpServer::graph_search` to
document where the semantic branch diverges from cursor pagination and what
`limit` means on each path.
