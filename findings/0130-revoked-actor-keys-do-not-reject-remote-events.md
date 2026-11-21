# 0130 — Revoking an actor key does not reject a later remote event

Claim `B-130`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, remote ingest
verifies the origin peer's signature and then projects the payload. Assertion
projection parses the actor ID and inserts the assertion. It does not look up
`actor_keys` or `revoked_at`.

## Separate local check

`GraphService::authenticate` hashes a bearer token and calls `find_active_key`,
which selects only rows with `revoked_at IS NULL`. A revoked key therefore
fails a later local API call. That check is not on the ingest path. A
revocation event only sets `revoked_at` when projected. An already accepted
assertion remains. A later peer-signed assertion naming the same actor is still
projected if the origin chain is valid. No event was ingested.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-130a | Implemented projection | `oag-events/src/projector.rs:92-122` and `405-421` |
| B-130b | Implemented local auth | `oag-graph/src/service.rs:145-159` and `oag-storage/src/repo/actors.rs:162-167` |

Verification: source inspection only.

## Next investigation

Trace whether a revocation event can be ordered after assertions that were created earlier but arrive later, and whether projection uses event time or arrival order.