# 0235 — The REST router applies global body and rate limits before handlers

Claim `B-0235`: at core `fb54e431332a030a566099c76fb2558084765422`,
`build_router` installs a 4 MiB request-body limit, a 120-request-per-minute
fixed-window limiter, tracing, and API latency measurement over the whole REST
router. These limits also apply to deliberately unauthenticated routes such as
`/metrics`, `/ipfs-site/*`, transfer fetch, and gateway query.

## Order of behavior

1. `Router::new()` registers top-level `/metrics`, `/api/v1/*`, `/ui/*`,
   `/ipfs-site/*`, `/oag/transfer/v1/fetch`, and `/oag/gateway/v1/query`.
2. `RequestBodyLimitLayer` caps request bodies at 4 MiB before handler parsing.
3. `rate_limit_middleware` keys on the raw `Authorization` header value, or the
   literal `"anonymous"` when absent. It calls `RateLimiter::check` before
   running the handler.
4. `RateLimiter` uses a 60-second fixed window and 120-request cap. It
   increments before comparison, so the 120th request passes and the next
   receives 429 with `Retry-After` seconds. Above 10,000 tracked keys, expired
   windows are swept.
5. `TraceLayer` and `api_latency_middleware` observe the request as a whole;
   latency was added at the newer commit.

## What is durable, rejected, and left behind

Durable: rate-limit windows are process-local in memory, not persisted.
Rejected: oversized bodies are stopped before parsing; over-limit keys get HTTP
429 and are told when to retry. Bogus Authorization headers can create distinct
keys; the sweep bounds the map to keys active in the last window rather than
every key ever seen.

The middleware rate limit is distinct from gateway and transfer-specific
limiters. Transfer's handler reuses the same `RateLimiter` class with the signed
`client_peer_id` as a better key, because the HTTP middleware cannot express
peer-signature identity. No request was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0235a | Implemented router routes and layers | `crates/oag-api/src/lib.rs:29-42`, `108-140` |
| B-0235b | Implemented fixed-window limiter | `crates/oag-api/src/rate_limit.rs:12-74` |
| B-0235c | Implemented header keying and 429 | `crates/oag-api/src/rate_limit.rs:94-116` |
| B-0235d | Implemented transfer reuse | `crates/oag-api/src/rate_limit.rs:54-59`; `crates/oag-api/src/transfer.rs:560-566` |
| B-0235e | Changed Retry-After and latency layer | `git diff 87f9e8c1..fb54e431 -- crates/oag-api/src/lib.rs crates/oag-api/src/rate_limit.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No HTTP request or rate-limit window was executed.

## Change since the previously explained commit

`Retry-After` and `api_latency_middleware` are new at `fb54e431...`; the 4 MiB
body cap and 120/min fixed-window limiter were already present. Finding 0018
describes the limiter at the older commit; this finding records the router-wide
placement and newer response behavior.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining gap from
the journal and revision table.
