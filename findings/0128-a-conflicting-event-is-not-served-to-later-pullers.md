# 0128 — A conflicting event is local evidence, not a served event

Claim `B-128`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, a fork
inserts the incoming signed JSON into `peer_forks`, not into `events`. The
events range query reads only `events`. A later puller therefore receives the
first event at that sequence and does not receive the conflicting payload
through the sync range endpoint.

## Retention limit

The table's primary key is `(peer_id, sequence)`. `record_fork` uses
`INSERT OR IGNORE`, so a second different conflict at the same sequence is not
stored. The first conflict's event IDs and signed JSON remain. No inspected
HTTP route lists `peer_forks`. The local CLI command `peer_forks` prints the
stored JSON, including the signed event body, to the operator's terminal. That
is local database access, not mesh replication. No fork was created.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-128a | Implemented storage | `oag-storage/src/repo/peers.rs:138-157` and `migrations/0002_peers.sql:22-29` |
| B-128b | Implemented serve path | `oag-storage/src/repo/events.rs:187-198` |
| B-128c | Implemented local reader | `oag-cli/src/commands.rs:232-249` |

Verification: source inspection only.

## Next investigation

Trace database rebuild and determine whether `peer_forks` survives a projection rebuild or is dropped with derived tables.