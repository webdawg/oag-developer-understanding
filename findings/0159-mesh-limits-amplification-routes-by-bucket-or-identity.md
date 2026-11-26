# 0159 — Mesh uses four route-specific in-memory limiters

Claim `B-0159`: at mesh `45f9fa8a16f65fc4a2e2fe5238bbbc2a5e462574`, two
unauthenticated endpoints that can cause outbound traffic use node-wide token
buckets; two signed-submission endpoints use fixed windows keyed by the verified
peer ID. All four limiters are in-memory and reset on restart. None is a general
authentication or persistent abuse-control system.

## Order of behavior

1. `POST /oag-mesh/v1/route-search` takes a token from `route_search_limiter`
   before doing any work. Capacity is 8 tokens with 2 tokens/second refill.
   This route has no requester identity, so the bucket is node-wide.
2. `POST /oag-mesh/v1/onion` takes from `onion_limiter`: capacity 16,
   refill 0.5 tokens/second. The endpoint peels a layer to a caller-chosen next
   hop or target, so the bound is volume, not admission; the target's own
   proof-of-work still applies.
3. When a bucket is empty, the handler returns HTTP 429 with `Retry-After` and
   a JSON `retry_after_seconds`. The reported value is the exact duration
   rounded down to whole seconds and floored at 1, so a sub-second wait is
   advertised as one second. A rejected request does not take a token.
4. `POST /oag-mesh/v1/membership-attestation` verifies the attestation and
   derives the attester peer ID first. Only then does
   `membership_attestation_limiter.check(attester)` run: 30 requests per 60
   seconds. An invalid signature never consumes a token.
5. `POST /oag-mesh/v1/responder-acknowledgment` similarly verifies the signed
   acknowledgment, then applies 60 requests per 60 seconds keyed by peer ID.

## Fixed-window details

`RateLimiter::check` checks the current count before incrementing, so the first
`max_requests` requests in a window pass and the next returns the remaining
window as `Retry-After`. Entries are kept in a `HashMap` with a hard 10,000-key
limit. When the map reaches that size, expired windows are swept; if it is still
full, a new key is refused for the whole window. An existing key is not affected
by that new-key refusal.

All state is process-local: no file, database, or shared key is described. A
restart restores full buckets and empty fixed-window maps. The limits are
starting constants in source, not configuration or a derived traffic model.

## What is durable, rejected, and left behind

Rejected requests leave no limiter state change on the token-bucket path and no
increment on the fixed-window path. They do leave the HTTP 429 response and, for
the two signed routes, the earlier verification outcome. Durable state from
these limiters is none. A legitimate caller sharing a node-wide bucket with an
abusive caller sees the same 429; the transport cannot distinguish them. No
target test, HTTP request, or restart was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0159a | Implemented limiter types | `crates/oag-mesh/src/rate_limit.rs:1-133` |
| B-0159b | Implemented constants and routes | `crates/oag-mesh/src/transport.rs:88-114`, `454-497` |
| B-0159c | Implemented route checks | `crates/oag-mesh/src/transport.rs:613-635`, `805-825`, `860-882`, `1019-1045` |
| B-0159d | New since explained commit | `git diff 9f5d89e9..45f9fa8a -- crates/oag-mesh/src/rate_limit.rs crates/oag-mesh/src/transport.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No target test or service was run.

## Change since the previously explained commit

The explained `9f5d89e9...` findings describe bridge declarations, claim
reports, and anonymous events. The `rate_limit.rs` module, these four limiter
fields, the route-search and onion endpoints, and the two signed submission
routes with per-identity limits are new at `45f9fa8a...`. Older findings about
proof-of-work on those submissions still describe verification, not this new
volume control.

## Next investigation

Trace `oag_mesh::dispatch::ResponderInbox` and
`ResponderSubscriptionRegistry` to document what is stored, what is dropped,
and how a responder event reaches a subscriber.
