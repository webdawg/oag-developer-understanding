# 0001 — A local assertion is authenticated before it becomes one signed event

Claim `B-001`: at `open-agent-graph` `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
`POST` assertion creation requires a valid bearer API key and `graph:assert`
permission, validates bounded input, and commits the relationship as one local
signed event plus its projection. Evidence attached to that request is not part
of that same transaction.

## Why it matters

This is the first user-visible write that turns a claim into durable graph
state. Treating “accepted” as one atomic claim-plus-evidence operation would
misstate the recovery and retry behavior.

## Synthetic request

```json
{
  "subject": "synthetic:alpha",
  "predicate": "relates-to",
  "object": "synthetic:beta",
  "evidence": [{ "uri": "https://example.invalid/evidence", "title": "synthetic" }]
}
```

No such request was sent. The example only names the fields inspected in
`AssertRequest`.

## Ordered behavior

1. `create_assertion` reads `Authorization: Bearer <key>` through
   `authenticate`. A missing or malformed header becomes an invalid-key error.
2. `GraphService::authenticate` hashes the raw key with BLAKE3 and looks up the
   hash. The inspected comment says raw keys are not persisted. An inactive or
   unknown key is rejected.
3. `GraphService::assert` requires `graph:assert`. `AuthContext::require` also
   accepts `admin` as a substitute for the specific permission.
4. `AssertInput::validate` bounds identifiers, predicate, optional types, and
   evidence fields. More than 20 evidence items is rejected before any commit.
5. Subject and object are canonicalized. Missing explicit types fall back to a
   recognized identifier kind, then to `"unknown"`.
6. The service commits `EventPayload::AssertRelation`. REST callers leave
   `extraction_method` unset, so the payload records `Direct`.
7. `commit_event` holds the service's process-local mutex, then calls
   `commit_local_event`.
8. Inside one immediate SQLite transaction, the routine reads this peer's
   origin, chooses sequence 1 or `highest_contiguous_sequence + 1`, signs the
   event, inserts it, projects it, advances the origin, and commits.
9. Projection resolves or creates both nodes, inserts the edge if absent, and
   inserts an active assertion whose ID is the event ID.
10. Only after that commit returns does the service loop through evidence. Each
    item is committed separately by `add_evidence_internal`.

The HTTP response contains the assertion ID and `"status": "accepted"`. It does
not describe evidence outcomes or remote replication.

## State and failure boundaries

- Before success, no new assertion event is committed by this call.
- After the assertion commit, the event log, projection, and origin head move
  together for that one event. This is **implemented**, not crash-tested here.
- If a later evidence commit fails, the assertion can already be durable while
  the HTTP call returns an error. Retry behavior for that partial result was
  not executed.
- A duplicate local event ID is treated as unexpected and rejected rather than
  projected twice. The comment says normal self-sequencing should make this
  unreachable.
- Concurrent calls through one `GraphService` wait on `commit_lock`. The event
  function itself documents that direct concurrent calls for the same peer can
  fail under WAL snapshot contention. That warning was not reproduced here.
- Multiple processes using the same database are not serialized by this
  in-process mutex. Their behavior is **unknown**.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-001a | Implemented | `crates/oag-api/src/handlers.rs:167-180`, `crates/oag-api/src/auth.rs:9-30` |
| B-001b | Implemented | `crates/oag-graph/src/service.rs:109-160` |
| B-001c | Implemented | `crates/oag-graph/src/assert.rs:102-169` |
| B-001d | Implemented | `crates/oag-events/src/commit.rs:27-104` |
| B-001e | Implemented | `crates/oag-events/src/projector.rs:28-132` |

Verification: source inspection only. No API server, database migration, or test
command was run.

## Next investigation

Compare this local path with `ingest_remote_event`: identify which checks happen
before insertion, whether projection shares the transaction, and how duplicates,
gaps, and rejected signatures differ.
