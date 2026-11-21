# 0058 — Status and metrics disclose operational state without graph:read

Claim `B-058`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
`GET /api/v1/status` and `GET /metrics` do not call bearer authentication.
Status returns the local peer ID and a fixed running state. Metrics returns
aggregate counts, database size, crawl activity, sync errors, and replication
summary fields.

## Disclosure boundary

`/api/v1/status` returns `peer_id`, `status: "running"`, and `replication: null`.
It does not return graph payloads. The null replication field does not prove
replication is inactive; the handler hardcodes it.

`/metrics` is documented as intentionally unauthenticated. It renders event,
node, edge, assertion, evidence, and peer counts; SQLite size; process-local
crawl attempts and failures; sync-error count; and, when replication status can
be read, target, caught-up count, lagging count, and whether the target is met.
The lagging metric exposes a count, not the inspected list of peer identities.
A replication read failure omits those gauges rather than failing the scrape.

These routes disclose operational metadata to any caller who can reach the HTTP
service. They do not disclose assertion payloads, but peer ID, size, and
activity can still aid targeting or correlation. Network exposure depends on
deployment and was not tested.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-058a | Implemented | `crates/oag-api/src/lib.rs:42` and `83`; `handlers.rs:300-306` |
| B-058b | Implemented and documented intent | `crates/oag-api/src/metrics.rs:1-8`, `20-28`, and `51-145` |

Verification: source inspection only. The named auth-free tests were not executed.

## Next investigation

Trace MCP authentication and determine whether MCP tool calls share the REST bearer-token and permission gates or have a separate bypass.