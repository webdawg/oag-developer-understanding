# 0133 — Assertion status is a last-write cache, not a state machine

Claim `B-133`: at core `fb54e431332a030a566099c76fb2558084765422`,
`assertions.status` is a single derived value that the last projected status
event overwrites. Dispute, retraction, and supersede events do not compare
their `created_at` with the status event already applied, and `set_status` has
no guard on the current status. The dedicated dispute/retraction/supersession
tables keep the individual events; the status column keeps only the winner of
insertion order.

## Order of behavior

1. `AssertionStatus` is declared with four values — `active`, `disputed`,
   `retracted`, `superseded` — and its own source comment calls it a derived,
   overwritable cache whose event log and dedicated tables are authoritative.
2. `AssertRelation` inserts a row with `status: Active` (finding 0131).
3. `project_dispute_assertion`, `project_retract_assertion`, and
   `project_supersede_assertion` each parse the target ID, require only that
   the assertion row exists, insert a row into the matching history table with
   the event's `created_at`, and then call `set_status` with a fixed new value.
   Supersede checks both IDs but does not check either one's current status.
4. `set_status` executes `UPDATE assertions SET status = ? WHERE id = ?`. The
   statement has no `WHERE status = ...` precondition, no timestamp comparison,
   and no check of affected rows. A second status event therefore succeeds
   even if the first already marked the assertion retracted or superseded.
5. Because finding 0131 established that events are projected in insertion
   order and rebuild replays `ORDER BY rowid`, the final status is the one set
   by the last status event inserted, not the one with the greatest
   `created_at`.

## What is durable, rejected, and left behind

Durable after each successful status event: its history row, its `event_refs`
row, and the new value of the single `assertions.status` column. Earlier status
rows are not deleted, but their values are no longer reflected in that column.
A late retraction created at `T1` can arrive after a dispute created at `T2 >
T1` and leave the assertion `retracted`; a rebuild reproduces `retracted`
because it replays in the same insertion order (Inferred from the replay path
in finding 0131; no rebuild was executed).

Nothing is rejected solely because the assertion is already disputed,
retracted, or superseded. The only projection-time rejection on these paths is
the missing-target check from finding 0132. Local API calls add their own
entry checks — dispute requires `graph:assert`, retract requires
`graph:retract-own` plus ownership or admin, supersede requires `graph:assert`
— but none of those checks the current status. Remote ingest does not perform
the local ownership check at all; it projects the signed payload.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-133a | Documented intent and implemented enum | `oag-core/src/assertion.rs:43-55` |
| B-133b | Implemented unconditional update | `oag-storage/src/repo/assertions.rs:128-139` |
| B-133c | Implemented projection sequence | `oag-events/src/projector.rs:205-239`, `241-275`, `277-306` |
| B-133d | Implemented local entry checks | `oag-graph/src/assert.rs:284-303`, `305-337`, `339-357` |
| B-133e | Implemented insertion order and replay | finding 0131; `oag-storage/src/repo/events.rs:180-183`; `oag-graph/src/rebuild.rs:53-61` |

Verification: source inspection via `git show origin/main:<path>` at the stated
commit. No event was ingested and no status transition was executed.

## Change since the previously explained commit

Comparing `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` with
`fb54e431332a030a566099c76fb2558084765422`, `assertion.rs` (core),
`repo/assertions.rs`, and `projector.rs` are unchanged. The changes in
`oag-graph/src/assert.rs` are pinned-CID recording on evidence and verification
outcome counting; the dispute, retract, and supersede methods shown above are
unchanged. Findings 0131 and 0132 still hold at the newer commit.

## Next investigation

Trace `oag_graph::history::GraphService::get_history` and
`oag-api/src/human.rs::HistoryEntryView` to determine whether a developer can
see both status events and their order, or only the overwritten final status.
