# 0089 — Peer removal deletes the peer row but leaves its trust records

Claim `B-089`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
`remove_peer` deletes `peer_addresses` for that peer and then the `peers` row.
It does not delete `peer_forks`, `peer_known_heads`, or `peer_cluster_claims`.
Those tables have no foreign key to `peers`, so the peer deletion succeeds and
the related rows remain.

## Consequence

`same_cluster` reads `peer_cluster_claims` by peer ID and does not require a
`peers` row. A removed peer's last cluster claim can therefore still match the
local cluster and bypass federation for that origin. Known-head rows no longer
affect `replication_status` through the peer list, because that function
iterates current `peers` rows, but they remain stored. Fork evidence also
remains. The operator command reports the peer removed without reporting these
residues.

This is an inspection of the delete statements and schemas, not an executed
removal. Presence and gravity tables were not included in the delete list
either; their exact effects were not traced in this finding.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-089a | Implemented | `crates/oag-storage/src/repo/peers.rs:94-104` |
| B-089b | Schema | `migrations/0002_peers.sql:23-29`, `0003_replication_tracking.sql:8-13`, `0011_peer_cluster.sql:12-15` |
| B-089c | Implemented cluster lookup | `crates/oag-sync/src/service.rs:209-220` |

Verification: source inspection only.

## Next investigation

Trace peer presence records and determine whether a removed or expired peer can still receive a trust boost from an address-level going-offline record.