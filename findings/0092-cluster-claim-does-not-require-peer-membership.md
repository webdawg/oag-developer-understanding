# 0092 — A cluster claim does not require a peer-table row

Claim `B-092`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
`POST /oag/sync/v1/cluster` verifies a self-signed declaration and upserts
`peer_cluster_claims` for the derived peer ID. It does not check that the peer
exists in `peers`, that anyone authorized the cluster name, or that the signer
has previously synced.

## Admission effect

`same_cluster` reads that claim table directly. Once the claim matches the
local configured cluster, `federation_allows` returns true before policy and
trust checks. A new keypair that knows or guesses the cluster name can therefore
install the bypass for its new peer ID before it has a peer row, address, or
accepted event. The signature proves key possession and freshness, not
membership. This sharpens finding 0006: the claim is not only self-certified,
it is also independent of peer-table membership.

The route shares the unauthenticated sync router and its global rate limit.
That limit does not validate the cluster name.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-092a | Implemented | `crates/oag-sync/src/server.rs:214-234` |
| B-092b | Implemented consumer | `crates/oag-sync/src/service.rs:209-220` and `254-260` |

Verification: source inspection only. No cluster declaration was submitted.

## Next investigation

Trace whether an event origin with only a cluster claim and no stored verifying key can still be fetched, or whether missing key material stops ingestion despite the federation bypass.