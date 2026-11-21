# 0075 — HTTP sync reads disclose events without authenticating the reader

Claim `B-075`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
`GET /oag/sync/v1/events/{origin}` requires no bearer token or federation check.
It returns up to 1,000 canonical signed event payloads for the requested origin
and sequence range. The module comment says session credentials are unnecessary
because events are self-authenticating, but a signature authenticates the
event's author, not the reader requesting the payload.

## Comparison

Push handling does consult `federation_allows` before ingestion and caps a batch
at 1,000 events and 4 MiB. Read handling caps the returned range at 1,000
events but does not check whether this peer is willing to disclose that origin's
events. A malformed origin or inverted range is rejected. A valid origin with
stored events is serialized from `canonical_payload`.

Reticulum finding 0074 therefore mirrors this read behavior rather than omitting
a federation check that HTTP has. Both paths need a separate reader-authorization
decision if event payloads are sensitive. The global sync rate limit may reduce
volume, but it was not re-read in this finding and is not reader authentication.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-075a | Implemented and documented intent | `crates/oag-sync/src/server.rs:20-38` and `82-108` |
| B-075b | Implemented push comparison | `crates/oag-sync/src/server.rs:110-136` |

Verification: source inspection only. No sync request was sent.

## Next investigation

Trace the sync rate limiter's keying and limits so the remaining operational bound is explicit rather than assumed.