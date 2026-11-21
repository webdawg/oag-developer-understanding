# 0019 — Gateway nonces bind a response, but requests are not remembered

Claim `B-019`: at `open-agent-graph` `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
gateway response verification rejects a response whose nonce differs from the
nonce expected by that caller. The incoming query handler verifies and decodes
the request nonce, but the inspected path does not store it as a consumed
replay identifier.

## What the nonce proves

`query_peer` generates a fresh 32-byte nonce, includes it in its signed request,
and passes that same nonce to `verify_gateway_response`. The verifier rejects a
different or malformed response nonce before accepting the responder's key and
signature. This binds the response to the caller's current exchange and prevents
substitution of another response with a valid but different nonce.

`query_inner` verifies an incoming request and then returns the request nonce in
its signed response. No inspected call records that nonce in a persistent or
in-memory seen set. Timestamp skew limits how old a signed request appears, but
within the allowed skew the same signed request can pass verification again.
Rate limiting may constrain repetition, but it is not nonce-specific replay
detection.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-019a | Implemented | `crates/oag-api/src/gateway.rs:404-428` |
| B-019b | Implemented | `crates/oag-api/src/gateway.rs:713-735` |
| B-019c | Implemented absence in handler | `crates/oag-api/src/gateway.rs:809-823` |

Verification: source inspection only. Replay was not executed.

## Next investigation

Trace hop-budget and path handling to determine whether relay loops are bounded
and how path history is authenticated.
