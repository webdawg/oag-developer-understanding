# 0076 — The sync rate limit is global, not per caller

Claim `B-076`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
`SyncRateLimiter` allows 600 requests per 60-second window for the whole
process. `check` takes no caller, source address, or peer ID. When the window
expires, the counter resets; the 600th request passes and the next is rejected.

## Consequence

The implementation comment states that sync is unauthenticated and that IP
keying was deliberately not added. The limiter therefore bounds total sync work,
not one caller's fair share. One busy caller can consume the window and cause
other peers to receive HTTP 429 or Reticulum's rate-limit error. It also does
not prevent 600 event-read requests from disclosing up to 600,000 events per
minute, subject to available data and response size. That volume was not
measured.

Reticulum uses the same `check` method, so its opt-in listener has the same
global bound rather than a separate authenticated quota.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-076 | Implemented and documented intent | `crates/oag-sync/src/rate_limit.rs:10-66` |

Verification: source inspection only. The limiter test was not executed.

## Next investigation

Trace whether sync hello and peer-list responses disclose the same peer
addresses and public keys as Reticulum, and whether those routes share this
rate limit.