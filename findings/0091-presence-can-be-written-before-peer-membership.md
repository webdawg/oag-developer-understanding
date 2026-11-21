# 0091 — A self-signed heartbeat can create presence before peer membership

Claim `B-091`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
`POST /oag/sync/v1/presence` is unauthenticated at HTTP and accepts any
heartbeat whose peer ID derives from its signing key and whose timestamp is
fresh. It stores that presence row without requiring a `peers` row. It cannot
sign a heartbeat for a peer ID the caller does not control.

## Effect

`presence::verify` checks key derivation, domain-separated signature, and clock
skew, then the handler records the heartbeat. Going-offline address records are
written only for addresses already stored for that peer ID. A new key with no
addresses can still create presence. `compute_trust` will later see that row and
can return a positive score even though `get_peer` is empty, as finding 0090
shows. The caller cannot use this endpoint to refresh a victim peer's presence
unless the caller has the victim's private key.

The global sync rate limit applies because the route is on the sync router. It
does not add an allowlist.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-091a | Implemented | `crates/oag-sync/src/server.rs:178-203` |
| B-091b | Implemented | `crates/oag-sync/src/presence.rs:107-128` |

Verification: source inspection only. No heartbeat was sent.

## Next investigation

Trace cluster declaration acceptance again only for its interaction with a not-yet-known peer: confirm a self-signed cluster claim can be stored before the peer row exists and still drive `same_cluster`.