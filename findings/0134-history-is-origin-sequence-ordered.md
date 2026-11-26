# 0134 — History is ordered by origin and sequence, not by time

Claim `B-134`: at core `fb54e431332a030a566099c76fb2558084765422`, the history
API returns every event that touched an object with its payload and signed
`created_at`, but sorts by `(origin_peer_id, sequence)`. That is neither global
insertion order nor `created_at` order. The "oldest first" wording in the
service comment and MCP tool description is documented intent, not what the SQL
guarantees.

## Order of behavior

1. `GraphService::get_history` accepts only `node`, `edge`, or `assertion` and
   a parseable 32-byte hex ID. Other object type strings and malformed IDs
   return `InvalidInput` before a history query runs.
2. It calls `events_repo::history_for`, which joins `event_refs` to `events`
   on `event_id` and filters by the requested ref type and ID. The query ends
   with `ORDER BY events.origin_peer_id, events.sequence`. Events are grouped
   by the raw origin peer bytes, with that origin's chain in ascending
   sequence; cross-origin ordering follows the peer-ID bytes.
3. Each row is turned into a `HistoryEntry` containing `event_id`, `event_type`,
   the stored event's `created_at`, and the parsed `canonical_payload` JSON.
   REST `GET /api/v1/history/{object_type}/{id}` and MCP `graph_get_history`
   both require `graph:read` and serialize these full entries under a
   `history` key.
4. The human Node page calls the same service but maps each entry to a
   `HistoryEntryView` with only `event_id`, `event_type`, and `created_at`; it
   drops `payload`. The human Assertion page does not render the history list.
   It renders `assertion.status` separately, renders all disputes and
   retractions from their dedicated lists, and derives a single supersession
   link by taking the **first** `SUPERSEDE_ASSERTION` entry in `get_history`
   order and reading `new_assertion_id` from its payload.
5. `list_disputes` and `list_retractions` use `SELECT * FROM ... WHERE
   <target> = ?` with no `ORDER BY`. Each view retains `reason` and
   `created_at`; the shown SQL does not specify a stable ordering.

## What this changes about finding 0133

REST and MCP expose enough history to see every status event, its payload, and
its `created_at`, so the history behind an overwritten status is not hidden.
But the returned order cannot be read as "when this happened": two origins can
interleave arbitrarily in insertion order while the response groups them by
peer ID. The human supersession link follows the first supersede event in that
grouped order, which need not be the event whose `set_status` ran last in
insertion order (finding 0133). The displayed status itself is the final
derived value, not a replay of history (Inferred by combining the displayed
fields with the projection path; no page was rendered).

## What is durable, rejected, and left behind

Durable history entries exist only when the originating event was successfully
projected: `add_ref` writes `event_refs` in the same transaction as the event
row (finding 0132). An event rejected at projection leaves no history row.
Malformed history requests are rejected as `InvalidInput`; a well-formed ID
with no matching refs yields an empty list from the shown query. The REST and
MCP responses are serialized views of stored rows; the human page's reduced
view is a rendering choice, not a deletion of payload data.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-134a | Implemented service and ordering | `oag-graph/src/history.rs:6-12`, `20-53`; `oag-storage/src/repo/events.rs:115-133` |
| B-134b | Documented intent contradicted by B-134a | `oag-graph/src/history.rs:17-19`; `oag-mcp/src/server.rs:563` |
| B-134c | Implemented REST and MCP exposure | `oag-api/src/handlers.rs:339-347`; `oag-mcp/src/server.rs:564-575` |
| B-134d | Implemented human views | `oag-api/src/human.rs:154-158`, `365-371`, `440-462`, `469-489` |
| B-134e | Implemented unordered detail lists | `oag-storage/src/repo/assertions.rs:309-319`, `361-371` |

Verification: source inspection via `git show origin/main:<path>` at the stated
commit. No endpoint was called and no page was rendered.

## Change since the previously explained commit

Comparing `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` with
`fb54e431332a030a566099c76fb2558084765422`, `history.rs`, `events.rs`,
`repo/assertions.rs`, and the history arms of `handlers.rs`, `human.rs`, and
`server.rs` are unchanged. The changed regions in those files add search
paging, pins, and alias tools; they do not alter history retrieval. Findings
0131-0133 still hold at the newer commit.

## Next investigation

Trace `oag_storage::repo::assertions::list_observations` and
`oag-api/src/human.rs::observation_view` to determine how `max_by_key` on
`observed_at` chooses a displayed observation when timestamps tie or arrive
out of order.
