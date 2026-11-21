# 0025 — Mesh corroboration has no built-in membership threshold

Claim `B-025`: at mesh `9f5d89e9fcf944dc16eff61f17543e83fc6ad20c`,
`MeshTree` reports the number of distinct declaring peers but does not define a
universal number that makes a declaration true. Callers pass
`min_corroboration` into each query.

## Behavior

`corroboration_for` returns zero when no verified declaration recorded the edge.
`members_of` returns direct members whose distinct-peer count is at least the
caller-selected threshold. Recursive base-cluster discovery uses that same
caller-selected count and records visited groups to stop cycles.

`is_attested_base_cluster` confirms only that a cluster name was placed under
some mesh group by enough distinct peers. Its comment explicitly says this does
not establish whether any particular reporting peer belongs to that base cluster.
The inspected tree therefore cannot close peer membership inside a named cluster.

A threshold of one accepts a single self-declaration. The comment compares that
case to the base project's unauthenticated cluster label. Higher thresholds are
policy choices made by the caller, not facts enforced by this data structure.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-025 | Implemented and documented intent | `oag-mesh/crates/oag-mesh/src/bridge.rs:177-205` |

Verification: source inspection only.

## Next investigation

Trace the claim-report corroboration path that consumes this tree and determine
what default threshold, if any, an actual caller selects.
