# 0014 — Inspected graph reads share one permission gate

Claim `B-014`: at `open-agent-graph` `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
the inspected node, edge, assertion, actor, and search handlers all call
`authenticate_read` before returning data. That helper requires a valid bearer
key plus `graph:read` or `admin`. It does not grant write authority.

## What the gate covers

The shared read gate protects:

- lexical or semantic search;
- actor, node, edge, and assertion lookup;
- node edges and all node assertions;
- source, evidence, observation, dispute, and retraction listings;
- edge corroboration.

`get_assertion` returns the assertion together with evidence, observations,
disputes, and retractions. `get_node_assertions` returns the unfiltered listing
established in finding 0011. A reader with `graph:read` can therefore inspect
historical status data, not only active support.

Write handlers such as `create_assertion` call `authenticate` and then enforce
their specific permission in the service. Passing the read gate is neither
necessary nor sufficient for those writes at the handler level: write handlers
do not call `authenticate_read`, and read permission does not imply
`graph:assert`.

## Limits

This finding covers the inspected handlers, not every route in the API or MCP
surface. Route mounting, public human HTML handlers, and sync endpoints need
separate inspection. In particular, sync endpoints were already documented as
transport-unauthenticated and must not be described as protected by
`graph:read`.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-014a | Implemented | `crates/oag-api/src/handlers.rs:15-159` |
| B-014b | Implemented | `crates/oag-api/src/auth.rs:9-30` |

Verification: source inspection only.

## Next investigation

Inspect human HTML routes and determine whether any user-visible read path
bypasses the bearer-token `graph:read` gate.
