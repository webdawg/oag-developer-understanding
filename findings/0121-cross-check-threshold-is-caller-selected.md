# 0121 — The cross-check threshold defaults to one and accepts zero

Claim `B-121`: at mesh `9f5d89e9fcf944dc16eff61f17543e83fc6ad20c`, the
cross-checked best-value route reads `min_bridge_corroboration` from the query
string. A missing value defaults to 1. The handler does not clamp the value.

## Effect of zero

`is_attested_base_cluster` returns true when some edge places that exact name
as a `BaseCluster` and the declaring-peer set length is greater than or equal
to the threshold. Zero therefore accepts every existing base-cluster edge,
including a single self-signed declaration. It does not accept a name that has
no edge: the search still requires a matching entry. A mesh-group member with
the same string does not count, because the match requires `BaseCluster`. A
threshold of 2 rejects a name attested by only one peer. The caller chooses the
threshold on an unauthenticated GET. No query was sent.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-121a | Implemented route | `oag-mesh/src/transport.rs:217-244` |
| B-121b | Implemented comparison | `oag-mesh/src/bridge.rs:200-205` |
| B-121c | Implemented test intent | `oag-mesh/src/bridge.rs:396-407` |

Verification: source inspection only. The unit test was not executed.

## Next investigation

Trace claim-report signature verification and determine whether the observed value hash is checked as a hash or accepted as any string.