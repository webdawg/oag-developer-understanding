# 0093 — A federation bypass does not supply the key needed for ingestion

Claim `B-093`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, passing
`federation_allows` does not by itself let a pull sync fetch and ingest an
origin. After the allow check, the loop still needs a verifying key. It uses
the hello key only when the origin is the contacted peer. Every other origin
requires a stored peer key and is skipped when that key is missing or malformed.

## Separation

A cluster claim can make `federation_allows` return true for a new peer ID, but
the claim table does not contain a public key. Unless that peer is the one
being contacted, or discovery has already stored its key, the fetch is not
attempted. The push handler similarly skips an event whose origin key is not
already known. Federation admission and signature-key availability are separate
gates. The bypass removes the policy and trust checks; it does not create trust
material for event verification.

This was not executed. A contacted peer can still supply its own key in hello
and have its own events ingested, which is finding 0088, not a contradiction.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-093a | Implemented pull loop | `crates/oag-sync/src/service.rs:348-370` |
| B-093b | Implemented push comparison | `crates/oag-sync/src/server.rs:136-154` |

Verification: source inspection only.

## Next investigation

Trace the sync HTTP hello route's lack of rate-limit exemption and determine whether a peer that cannot complete hello can still be admitted through a previously stored cluster claim.