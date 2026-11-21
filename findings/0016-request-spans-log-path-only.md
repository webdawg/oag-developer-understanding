# 0016 — Custom request spans log the path, not the query string

Claim `B-016`: at `open-agent-graph` `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
the custom HTTP span records `request.uri().path()` in its `route` field. That
method excludes the query string, so the custom field does not itself contain a
human-UI `?key=` value.

## What is and is not established

The span also records a process-local request ID, peer ID, method, and an
initially empty actor ID. Authentication later records the actor ID. The
response callback records status, duration, and a coarse `ok` or `error` result.
The logging comment does not claim query redaction, and no explicit redaction
function is present in this file.

This does not prove that no other logger can observe the full URI. The router
uses `tower_http::trace::TraceLayer`, whose default request and failure events
were not inspected. Deployment log collectors and reverse proxies are outside
the repository. The safe conclusion is limited to the custom span fields.

## Nearby unauthenticated routes

The same router explicitly comments that `/ipfs-site/{cid}`,
`/oag/transfer/v1/fetch`, and `/oag/gateway/v1/query` are outside bearer-token
authentication. Their alternate signature or public-content assumptions were not
verified in this finding. They show that “the API uses bearer authentication”
is not a universal statement about every route.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-016a | Implemented | `crates/oag-api/src/logging.rs:42-68` |
| B-016b | Implemented and documented intent | `crates/oag-api/src/lib.rs:104-130` |

Verification: source inspection only.

## Next investigation

Choose one explicitly unauthenticated route, starting with gateway query, and
trace its signature or trust boundary before describing it as safe.
