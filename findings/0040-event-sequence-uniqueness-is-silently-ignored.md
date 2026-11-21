# 0040 — Event sequence uniqueness does not surface a constraint error

Claim `B-040`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, the `events`
table has a primary key on `event_id` and a unique constraint on
`(origin_peer_id, sequence)`. `insert_event` uses `INSERT OR IGNORE` and
returns whether any row was affected. A duplicate event ID or origin sequence
therefore yields `false`, not an SQL constraint error.

## State transition

`event_origins` stores one row per origin, including
`highest_contiguous_sequence`, `highest_seen_sequence`, and `head_event_id`.
`advance_origin` sets both sequence fields to the supplied sequence and replaces
the head. It does not calculate a maximum or verify contiguity itself; callers
must supply the correct next sequence.

On the local path, a false insert result becomes an unexpected-existence error
before projection and origin advancement. On the remote path, the caller checks
for an existing sequence before insertion, but the insertion result itself is
not inspected in the section read earlier. A race between that check and insert
was not tested. Because both operations are intended to share one transaction,
another transaction should not observe a partial projection, subject to the
unproven crash limits in finding 0039.

The schema does not constrain `previous_event_id` to reference an existing
event. Predecessor continuity is enforced by application code, not by this
foreign key. `event_refs.event_id` does reference `events`, so a projection
reference cannot outlive insertion inside foreign-key enforcement.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-040a | Implemented schema | `crates/oag-storage/migrations/0001_init.sql:7-39` |
| B-040b | Implemented insertion and head update | `crates/oag-storage/src/repo/events.rs:20-38` and `74-92` |

Verification: source inspection only. No migration or constraint test was run.

## Next investigation

Trace canonical JSON and event-ID derivation to determine which payload changes alter identity and which signature domain binds an event.