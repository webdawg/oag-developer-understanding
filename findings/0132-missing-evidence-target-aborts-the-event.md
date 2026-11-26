# 0132 — A missing assertion target aborts evidence ingest

Claim `B-132`: at core `fb54e431332a030a566099c76fb2558084765422`, an
`AddEvidence` event is accepted only if its target assertion already exists in
the local `assertions` table at projection time. The check happens after
signature and chain validation but before the event transaction commits. A
validly signed event that arrives before its target is rejected with
`EventsError::NotFound`; its raw event row and origin head are not committed.

## Order of behavior

1. `ingest_remote_event` verifies the signed envelope and origin key, opens a
   `BEGIN IMMEDIATE` transaction, and checks the origin's sequence and
   previous head. Only then does it insert the raw event row and call
   `project` (the same order is used by `commit_local_event`).
2. `project_add_evidence` parses `p.assertion_id` and calls
   `assertions::get_by_id`. If no row is returned, it returns
   `EventsError::NotFound("assertion <id>")` before constructing or inserting
   any evidence and before adding an `event_refs` row.
3. The `?` on `project(...)` leaves `tx.commit()` unreachable. No origin-head
   advance is reached either. With sqlx's transaction-drop semantics, the
   whole transaction rolls back (Inferred from the control flow; not executed).
4. On the pull path, `sync_with_peer` captures the error as
   `"<origin>@<sequence>: referenced object not found: assertion <id>"` in the
   call's `SyncSummary.errors` and breaks out of that origin's event loop. It
   does not mark the head as consumed: `local_heads` was read before the loop
   from `event_origins.highest_contiguous_sequence`, which the failed ingest
   did not advance. The next gossip tick can fetch and retry the same event.
5. On the push path, `post_events` counts any ingest `Err(_)` as `skipped` and
   continues with the next event in the submitted batch. It returns only
   `applied` and `skipped`; no per-event reason is sent to the submitter.

## What is durable, rejected, and left behind

Durable after success: the event row, evidence row, `event_refs` row, and
advanced origin head are in one committed transaction. Rejected here: a
correctly signed, chain-valid event whose target assertion is unknown *yet*.
The code does not queue it for later delivery; the only retry observed in this
mechanism is a later pull of the same unconsumed sequence. If the missing
assertion never arrives from any origin, the same evidence event is rejected
again on later ticks (Inferred from the unchanged head and the loop). The
push route's skipped count and the pull summary's error string are results of
that call; the shown code does not persist the error text.

This is a projection-time existence check, not an authorization check. It asks
whether the assertion row exists, not which actor created it or whether it is
active. Verify, dispute, retract, and supersede payloads have the same
`get_by_id` guard in this projector; supersede requires both named assertions
to exist.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-132a | Implemented target guard | `oag-events/src/projector.rs:149-175` |
| B-132b | Implemented error variant | `oag-events/src/error.rs:22-25` |
| B-132c | Implemented transaction order | `oag-events/src/ingest.rs:77-86`, `137-162`; `oag-events/src/commit.rs:63-92` |
| B-132d | Implemented pull behavior | `oag-sync/src/service.rs:331-340`, `396-406`, `439-452` |
| B-132e | Implemented push behavior | `oag-sync/src/server.rs:130-168` |
| B-132f | Implemented sibling guards | `oag-events/src/projector.rs:178-203`, `205-239`, `241-306` |

Verification: source inspection via `git show origin/main:<path>` at the stated
commit. No event was ingested and no sync round was run.

## Change since the previously explained commit

Comparing `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` with
`fb54e431332a030a566099c76fb2558084765422`, `projector.rs`, `error.rs`, and
`server.rs` are unchanged. `service.rs` gained address backoff state and a
`note_rate_limit` call around fetch failures; the per-event ingest error arm
and its `break` are unchanged. Finding 0131's insertion-order replay still
holds at the newer commit.

## Next investigation

Trace `oag_storage::repo::assertions::set_status` and determine whether a late
dispute, retraction, or supersede event can overwrite a status already set by
an event with a later `created_at`.
