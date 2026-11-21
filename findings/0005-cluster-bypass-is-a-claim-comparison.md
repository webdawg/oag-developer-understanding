# 0005 — Cluster admission compares a stored claim with local configuration

Claim `B-005`: at `open-agent-graph` `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
ordinary federation policy is either open or an explicit peer allowlist. The
cluster override is a string comparison between this peer's configured cluster
and another peer's latest stored cluster claim. The implementation comment says
the claim is signed, but this function does not itself verify a signature.

## Exact behavior

`FederationPolicy::allows` returns true for every peer in `Open` mode and only
for contained peer IDs in `Allowlist` mode.

`same_cluster` returns false when this service has no configured cluster, when
the database connection cannot be acquired, or when no matching stored claim
exists. Otherwise it compares `claim.cluster` with the configured name.

Because `federation_allows` checks `same_cluster` first, a matching claim bypasses
both the allowlist and minimum-trust test. The comment explicitly identifies
this as a security tradeoff rather than an accident. Signature verification,
claim freshness, and authorization to join a cluster are outside this function
and remain **unknown** until their storage path is traced.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-005a | Implemented | `crates/oag-sync/src/federation.rs:11-23` |
| B-005b | Implemented and documented intent | `crates/oag-sync/src/service.rs:209-220` and `254-286` |

Verification: source inspection only.

## Next investigation

Trace the cluster-claim storage and verification path: who signs a declaration,
where it is validated, and whether an unverified or stale claim can reach
`peer_cluster::get`.
