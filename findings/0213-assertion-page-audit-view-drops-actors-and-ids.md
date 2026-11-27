# 0213 — The assertion page shows audit events without actors or event IDs

Claim `B-0213`: at core `fb54e431332a030a566099c76fb2558084765422`, the human
Assertion page displays verification, dispute, retraction, and supersession
state, but its view structs keep only a small subset of each stored row. Actor
IDs, row IDs, observation creation times, and multiple supersede events are not
shown.

## Order of behavior

1. `observation_view` copies `result` and `observed_at` from an observation;
   `dispute_view` and `retraction_view` copy `reason` and `created_at`.
2. The assertion handler loads all observations, disputes, and retractions and
   maps them through those three functions. The storage queries use
   `SELECT * ... WHERE assertion_id/... = ?` with no `ORDER BY`, so list order
   is unspecified.
3. The template prints each observation as `<result> at <observed_at>`; each
   dispute/retraction as `<reason-or-(no reason given)> at <created_at>`.
   Empty lists print `(none)`; no retractions print `(not retracted)`.
4. Supersession is a single optional value. The handler searches the assertion
   history for the first event whose type is `SUPERSEDE_ASSERTION`, extracts
   `new_assertion_id`, and shows a link and timestamp. It does not choose the
   latest supersede event.
5. Current `status` is printed separately from the lifecycle lists.

## What is durable, rejected, and left behind

Durable: nothing is changed by rendering. Rejected: no audit row is filtered by
this view; all rows returned by storage are displayed in some form. Missing
reason values become a placeholder, not an error.

The displayed explanation is incomplete by design: a visitor cannot tell who
verified, disputed, or retracted from this page, nor which event recorded each
action. If several supersede events exist, the first in history order is shown.
Finding 0134 records that status may have been overwritten by later events;
this page shows the final status and one supersede link, not that conflict
history. No page was rendered.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0213a | Implemented view structs | `crates/oag-api/src/human.rs:114-139` |
| B-0213b | Implemented handler collection | `crates/oag-api/src/human.rs:443-462`, `481-488` |
| B-0213c | Implemented template sections | `crates/oag-api/templates/assertion.html:73-115` |
| B-0213d | Implemented unordered storage queries | `crates/oag-storage/src/repo/assertions.rs:309-319`, `361-371`, `444-454` |
| B-0213e | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-api/src/human.rs crates/oag-api/templates/assertion.html` (no audit-region changes) |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No HTTP request or page render was executed.

## Change since the previously explained commit

Audit rendering is unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`; the changed regions in `human.rs`
are search paging. Findings 0133 and 0134 describe the stored lifecycle and
status overwrites; this finding records the reduced human-facing view.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining gap from
the journal and revision table.
