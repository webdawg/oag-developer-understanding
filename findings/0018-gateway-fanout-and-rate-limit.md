# 0018 — Gateway fanout is bounded by configuration and a separate rate limit

Claim `B-018`: at `open-agent-graph` `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
gateway query handling rate-limits each verified requester peer ID before
resolution. When query peers are configured, fanout queries a bounded prefix
concurrently and accepts a result only when the configured agreement threshold
is met.

## Rate limit

The reusable limiter is a fixed 60-second window with a default maximum of 120
requests. It increments before comparison, so the 120th request passes and the
next fails. At more than 10,000 tracked keys it removes expired windows. The
general HTTP middleware keys by the complete `Authorization` header or
`"anonymous"`, but the gateway handler calls `check` with the verified peer ID.
The two uses therefore do not share the same caller identity namespace unless
their limiter instances are explicitly shared; this finding does not establish
that sharing.

## Fanout and quorum

`fanout_and_verify` selects all configured query peers when `fanout_count` is
zero, otherwise the configured count capped by available peers. It spawns one
task per selected peer. Each task signs a request, posts it to that peer's
`/oag/gateway/v1/query`, verifies the response and nonce, and checks that the
responding peer ID matches the configured peer.

`aggregate_quorum` discards failed responses. For NTP it requires a sufficiently
large cluster within tolerance and returns its median. For HTTP it groups by
content hash and requires the largest group to contain at least
`quorum_min_agree` results. Failed peers reduce the number of successful votes;
they are not individually retried in this function.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-018a | Implemented | `crates/oag-api/src/rate_limit.rs:12-73` |
| B-018b | Implemented | `crates/oag-api/src/gateway.rs:673-760` |

Verification: source inspection only. The comment's historical memory-growth
measurement was not reproduced.

## Next investigation

Trace response verification and nonce handling to determine whether replayed
gateway requests or responses are detected beyond timestamp skew.
