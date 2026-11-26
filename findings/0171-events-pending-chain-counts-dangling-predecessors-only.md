# 0171 — `events_pending_chain` counts dangling predecessor references

Claim `B-0171`: at core `fb54e431332a030a566099c76fb2558084765422`, the
`events_pending_chain` metric is a live SQL count of stored events whose
`previous_event_id` names an event ID not present in the local `events` table.
Zero means no dangling references; it does not prove global chain completeness
per origin, and it does not count fork evidence.

## Order of behavior

1. The query left-joins `events e` to `events p` on `p.event_id =
   e.previous_event_id`, then counts rows where `previous_event_id IS NOT NULL`
   and the joined `p.event_id IS NULL`.
2. A genesis event with no predecessor is never counted. A child whose
   predecessor row exists is not counted. A child whose declared predecessor is
   absent contributes one.
3. The self-join is on the `event_id` primary key. The source calls this
   `O(n log n)` rather than a scan-compare-scan; no benchmark was reproduced.
4. `metrics_snapshot` calls this function alongside the other cheap SQL counts
   and the API renderer exposes the value as the `events_pending_chain` gauge.
5. Normal ingest rejects a sequence gap before inserting the event and records
   a conflicting event in `peer_forks` rather than in `events`. Neither a
   rejected gap nor a fork therefore adds to this count. The tests construct
   dangling rows by direct SQL insertion because the normal path does not
   produce them.

## What is durable, rejected, and left behind

Durable: nothing is stored for the metric. It is recomputed from the event table
on each snapshot, so it reflects the current database, including WAL state
visible to the connection. A transient replication gap can raise it and later
clear when the predecessor arrives; a permanently absent predecessor leaves it
non-zero. A query error propagates out of `metrics_snapshot`; no partial gauge
value is shown.

The metric cannot distinguish a few missing predecessors from many, identify
which origin is affected, or report how long the condition has persisted. It
also says nothing about forks: the conflicting signed JSON is held outside
`events` (finding 0128). No scrape, ingest, or target test was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0171a | Implemented metric query and comment | `crates/oag-storage/src/repo/stats.rs:46-63` |
| B-0171b | Implemented snapshot and rendering | `crates/oag-graph/src/metrics.rs:48-67`; `crates/oag-api/src/metrics.rs:206-212` |
| B-0171c | Implemented event key schema | `crates/oag-storage/migrations/0001_init.sql:7-18` |
| B-0171d | Implemented ingest gap/fork handling | `crates/oag-events/src/ingest.rs:88-120` |
| B-0171e | Test inspection, not executed | `crates/oag-storage/src/repo/stats.rs:105-150` |
| B-0171f | New since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-storage/src/repo/stats.rs` |

Verification: source and test inspection via `git show origin/main:<path>` and a
scoped diff. No metrics scrape or ingest was executed.

## Change since the previously explained commit

`events_pending_chain` and its direct-insertion test are new at `fb54e431...`
relative to explained `87f9e8c1...`. Findings 0124 and 0128 still describe why
normal ingest does not leave a dangling row or put fork evidence in `events`;
this finding describes the new gauge over the resulting table.

## Next investigation

Trace `oag_graph::pins::GraphService::holds_pin` and `list_pins` to document
where CID pins are recorded, what bounds the listing, and what "holds" actually
means.
