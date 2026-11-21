# 0124 — Remote ingest rejects a sequence gap instead of queueing it

Claim `B-124`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
`ingest_remote_event` accepts a new event only when its sequence equals the
origin's highest contiguous sequence plus one, or 1 when the origin is new.
`validate_chain` returns `SequenceGap` otherwise. The error happens before
insert and projection, so the missing number is not stored as a pending gap.

## Other sequence cases

If a row already exists at the offered sequence and the event ID matches, the
function returns `AlreadyKnown` and does not require that sequence to be the
next one. If a different event ID occupies that sequence, it records a fork and
does not advance the head. A future sequence with no row is a gap, not a fork.
The function comment says specification section 54 allows queueing or
rejection, and this implementation rejects because the sync client is expected
to fetch contiguous ranges. That client behavior was not re-checked in this
finding. The gap test exists and was not executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-124a | Implemented and documented intent | `oag-events/src/ingest.rs:36-39` and `79-128` |
| B-124b | Implemented check | `oag-events/src/validate.rs:31-46` |
| B-124c | Test intent | `oag-events/src/ingest.rs:246-258` |

Verification: source inspection only.

## Next investigation

Trace the sync client's range fetch and determine whether it actually requests the next contiguous sequence or can offer a gap to ingest.