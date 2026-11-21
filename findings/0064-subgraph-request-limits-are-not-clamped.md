# 0064 — Subgraph requests are not clamped before traversal

Claim `B-064`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
`GET` subgraph handling requires `graph:read` and defaults a missing depth to 1
and a missing `max_nodes` to 200. If the caller supplies either value, it is
passed directly to `get_subgraph`. The query struct defines no maximum.

## Consequence

A caller can request `depth` up to the full `u32` range and `max_nodes` up to
the platform `usize` range. Combined with finding 0063, the service has neither
a hard node cap nor a request-size clamp. Traversal is still bounded by the
actual local graph, but a broad, highly connected graph can make one authorized
read expensive. The route has the general API rate limit only if that middleware
wraps the router; this finding does not re-verify middleware order.

Default values are not evidence of a safe maximum. They apply only to omitted
parameters.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-064 | Implemented | `crates/oag-api/src/handlers.rs:276-286` and `crates/oag-api/src/dto.rs:128-132` |

Verification: source inspection only. No subgraph request was issued.

## Next investigation

Trace identifier resolution and determine whether one query can return multiple candidate nodes or silently choose one.