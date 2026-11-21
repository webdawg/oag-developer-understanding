# 0017 — Gateway verification proves a signature, not admission

Claim `B-017`: at `open-agent-graph` `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
`POST /oag/gateway/v1/query` verifies a self-signed request before doing work.
The inspected handler does not consult bearer authentication, `graph:read`, or
`federation_allows`.

## Verified properties

`verify_gateway_request`:

1. parses the requester peer ID and public key;
2. rejects a peer ID that does not derive from that key;
3. verifies the signature over canonical unsigned JSON in the gateway request
   domain;
4. rejects timestamps more than the configured maximum skew from the verifier's
   current time;
5. decodes and returns a 32-byte nonce.

The handler then applies a per-peer rate limit and resolves the requested
service. Resolution checks an in-memory cache, optionally performs configured
peer fanout and quorum verification, tries direct resolution, and finally relays
according to the hop budget. Those later stages were not fully traced.

## Consequence

Any caller that can generate a valid keypair can create a request that passes
this signature check, subject to clock skew and rate limiting. Signature
verification establishes requester identity and request integrity. It does not
establish that the requester is a known, allowlisted, clustered, or trusted peer.
Whether fanout or direct resolvers add authorization later remains **unknown**.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-017a | Implemented | `crates/oag-api/src/gateway.rs:364-385` |
| B-017b | Implemented | `crates/oag-api/src/gateway.rs:809-823` |
| B-017c | Implemented resolution order | `crates/oag-api/src/gateway.rs:445-478` |

Verification: source inspection only.

## Next investigation

Trace `fanout_and_verify` and the gateway rate limiter to determine how much
unsolicited signed traffic can cost a peer and what quorum agreement means.
