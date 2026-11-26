# 0131 — Projection applies events in insertion order, not `created_at` order

Claim `B-131`: at core `fb54e431332a030a566099c76fb2558084765422`, the order in
which events change projection tables is the order in which their rows were
inserted into `events`. The signed `created_at` value is copied into projected
rows such as `assertions.asserted_at` and `actor_keys.revoked_at`; it is not
used to sort application, and rebuild deliberately preserves insertion order.

## Order of behavior

1. `build_and_sign` puts a caller-supplied `created_at: i64` into the unsigned
   event, signs the canonical unsigned envelope, and derives the event ID from
   the canonical signed envelope. Receivers verify that signature and recompute
   the ID; they do not validate a clock window for this field.
2. `commit_local_event` and `ingest_remote_event` insert the raw event row with
   `created_at`, call `project` immediately, advance the origin head, and commit
   one transaction. Remote chain validation checks only the next sequence and
   the declared previous event. It does not check that `created_at` increases.
3. `project` dispatches on payload type. `project_assert_relation` stores
   `asserted_at: created_at`; `project_actor_key_add` stores key `created_at`;
   `project_actor_key_revoke` calls `revoke_key`, which writes `revoked_at =
   created_at` only if the key is still active. These are data writes, not
   comparisons against already-projected timestamps.
4. `rebuild_projection` wipes derived tables, loads `SELECT * FROM events ORDER
   BY rowid`, and replays each payload with its stored `row.created_at`. SQLite
   `rowid` is the insertion order. Rebuild therefore reproduces the original
   application order rather than sorting by signed time.

## What this means

A revocation event with `created_at = T2` can be projected before an assertion
event with `created_at = T1 < T2` when the revocation arrives first from another
origin. Per-origin sequence and `previous_event` constrain each origin's chain,
but they do not order events across origins and do not reject a backwards
timestamp within one origin. The later-arriving assertion is inserted after the
revocation with its own earlier `asserted_at`; nothing revisits already
projected state to reorder it. Finding 0130's separate local-auth check still
sees the key as revoked, because `find_active_key` filters on `revoked_at IS
NULL`, not on the assertion's timestamp.

What is durable is the event row, its `created_at` value, and the projection
writes made in that insertion order. Rebuild preserves that order. What is
rejected is a gap or wrong previous event in an origin chain; a non-monotonic
`created_at` is not rejected. If projection returns an error, the event row and
projection writes share one transaction and are not committed; no pending-event
queue was found on this path (Inferred from the transaction boundaries, not
executed).

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-131a | Implemented signing and chain validation | `oag-events/src/builder.rs:15-40`; `oag-events/src/validate.rs:31-49` |
| B-131b | Implemented insert-project-commit order | `oag-events/src/commit.rs:57-92`; `oag-events/src/ingest.rs:137-162` |
| B-131c | Implemented projection writes | `oag-events/src/projector.rs:92-122`, `385-401`, `405-421`; `oag-storage/src/repo/actors.rs:228-238` |
| B-131d | Implemented replay order | `oag-storage/src/repo/events.rs:180-183`; `oag-graph/src/rebuild.rs:53-61` |
| B-131e | Implemented auth filter | `oag-storage/src/repo/actors.rs:162-171` |

Verification: source inspection via `git show origin/main:<path>` at the stated
commit. No events were ingested, no rebuild was run, and no target test was
executed.

## Change since the previously explained commit

Comparing `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` with
`fb54e431332a030a566099c76fb2558084765422`, the relevant files changed only to
open transactions with `BEGIN IMMEDIATE` in `ingest.rs` and `rebuild.rs`. The
insert-then-project calls, `validate_chain`, the projection timestamp writes,
and `ORDER BY rowid` replay are unchanged. Finding 0130's claim that revocation
does not gate remote ingest still holds at the newer commit.

## Next investigation

Trace `oag_events::projector::project_add_evidence`: determine what happens to
an ingested event whose asserted target does not exist yet at projection time,
and whether the transaction leaves any trace after the error.
