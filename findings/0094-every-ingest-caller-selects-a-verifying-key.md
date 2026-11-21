# 0094 — Every production ingest caller selects a verifying key first

Claim `B-094`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, a search of
`crates/` finds three production callers of `ingest_remote_event`: sync pull,
sync push, and the Reticulum client. Each passes a `VerifyingKey` chosen by the
caller. None derives that key from a cluster claim, presence row, or federation
result.

## Caller pattern

Sync pull and the Reticulum client use the contacted peer's hello key for its
own origin and a stored peer key for every other origin, skipping when the
stored key is absent. Sync push looks up the stored key and skips unknown
origins. The ingest function itself still checks that the supplied key derives
to the claimed origin, so a caller cannot use an unrelated stored key
successfully. Tests also pass keys, but they are not production ingress.

A cluster claim can change admission policy, but it is not an ingestion path.
There is no inspected production call that ingests an event with only a cluster
name and no key.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-094a | Search | Production calls in `oag-sync/src/service.rs:382`, `oag-sync/src/server.rs:162`, and `oag-reticulum/src/client.rs:168` |
| B-094b | Implemented Reticulum key selection | `crates/oag-reticulum/src/client.rs:136-152` |

Verification: source search and inspection only. No ingest call was executed.

## Next investigation

Trace the Reticulum client's hello verification and determine whether its link setup authenticates the remote destination before trusting the hello key.