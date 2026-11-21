# 0066 — Transfer requests prove a signature, not graph admission

Claim `B-066`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
`POST /oag/transfer/v1/fetch` verifies a self-signed transfer request, rate-limits
the derived peer ID, and fetches the requested CID. The handler does not call
bearer authentication, `graph:read`, or federation admission.

## What verification establishes

`verify_request` checks that the peer ID derives from the supplied public key,
verifies the signature over canonical JSON in the transfer-request domain, and
rejects timestamps outside the maximum skew. It returns the peer ID and client
nonce. Any caller able to generate a valid keypair can pass this check, subject
to skew and the transfer rate limiter.

`verify_receipt` additionally binds the expected CID and client nonce, verifies
the server key and signature, and checks a mutual receipt hash. That protects a
specific exchange from substitution. It does not by itself prove the bytes are
authorized graph content or that the server was an approved peer; the caller
must compare the returned content hash with the receipt and decide which server
key to trust. Server-side nonce persistence was not found in the inspected
handler, so timestamp skew remains the visible replay bound.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-066a | Implemented | `crates/oag-api/src/transfer.rs:202-225` and `262-275` |
| B-066b | Implemented handler | `crates/oag-api/src/transfer.rs:553-568` |
| B-066c | Route comment | `crates/oag-api/src/lib.rs:104-110` |

Verification: source inspection only. No transfer request was sent.

## Next investigation

Trace whether transfer relay decrements and signs a hop budget before forwarding, and whether a relay can be made to fetch arbitrary CIDs from configured peers.