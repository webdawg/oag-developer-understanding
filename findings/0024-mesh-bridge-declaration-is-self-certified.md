# 0024 — A mesh bridge declaration proves a claim, not authorization

Claim `B-024`: at mesh `9f5d89e9fcf944dc16eff61f17543e83fc6ad20c`, a bridge
declaration is a self-signed claim that a member belongs to a mesh group.
Verification checks key derivation, signature, and timestamp freshness. It does
not check that the signer is authorized to administer either group.

## Lifecycle

`build_and_sign` rejects a mesh group naming itself directly as its own member,
canonicalizes the unsigned declaration with core JSON, and signs it in the
bridge domain. `verify` rejects malformed keys, mismatched peer IDs, bad
signatures, and timestamps beyond the configured skew.

`MeshTree::add` verifies before inserting. The in-memory map keys an edge by
`(mesh_group, member)` and stores a set of declaring peer IDs. Repeating the
same declaration from one peer does not increase that set. Distinct peers can
independently increase its corroboration count.

The type comment says this tree is built from declarations supplied by the
caller and does not talk to the network or core storage. No persistence,
replay cache, or authorization source is visible in this path. Timestamp skew
limits stale declarations only when the caller supplies the current time.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-024 | Implemented | `oag-mesh/crates/oag-mesh/src/bridge.rs:90-176` |

Verification: source inspection only. Mesh tests were not executed.

## Next investigation

Trace `MeshTree` corroboration thresholds and determine what minimum number of
distinct peers changes membership status.
