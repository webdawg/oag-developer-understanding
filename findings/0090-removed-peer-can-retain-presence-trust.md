# 0090 — Removing a peer does not remove the presence used for trust

Claim `B-090`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
`compute_trust` treats a missing peer row as not forked and still loads
`peer_presence` by peer ID. A fresh presence row produces non-zero trust until
heartbeat silence decays it. `remove_peer` does not delete that presence row.

## Scoring path

Forked peers score zero. No presence scores zero. Otherwise a recent heartbeat
returns a rebuild fraction, and an old heartbeat decays toward zero.
`announced_restart` requires one of the peer's stored addresses to have a recent
going-offline record. After removal, `list_addresses` returns no rows, so that
grace cannot be found through this function. Presence alone is still enough for
a positive score.

`federation_allows` consults this score only when the peer is not same-cluster
and `minimum_trust` is positive. A removed peer can therefore still pass the
trust check while its presence row remains fresh. The cluster-claim bypass from
finding 0089 is independent and does not require presence. No removal test was
executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-090a | Implemented | `crates/oag-sync/src/trust.rs:113-141` and `77-91` |
| B-090b | Implemented absence | `crates/oag-storage/src/repo/peers.rs:94-104` does not delete presence |
| B-090c | Implemented caller | `crates/oag-sync/src/service.rs:254-286` |

Verification: source inspection only.

## Next investigation

Trace the presence heartbeat endpoint and determine who can write a presence row for an arbitrary peer ID.