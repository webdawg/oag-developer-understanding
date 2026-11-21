# 0021 — Mesh locks a different core revision than the inspected core checkout

Claim `B-021`: at mesh `9f5d89e9fcf944dc16eff61f17543e83fc6ad20c`, the manifest
declares `oag-core` and `oag-crypto` as Git dependencies on core branch `main`.
`Cargo.lock` resolves both to core commit
`ce1122589909c151056de33325b14d7022efe2f0`. That is not the inspected core
checkout `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`.

## Consequence

Findings 0001–0020 describe the inspected core checkout only. They must not be
applied unchanged to the core revision mesh builds against. A branch dependency
records an update channel, while the lockfile records the actual build input.
The two commits have not yet been compared, so this finding establishes revision
skew, not behavioral incompatibility.

The lockfile search found no locked `oag-events`, `oag-storage`, or `oag-graph`
package in mesh. That absence does not prove mesh lacks equivalent behavior; it
only says those package names are not direct locked dependencies in this pass.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-021a | Implemented manifest | `oag-mesh/Cargo.toml:17-18` |
| B-021b | Implemented lockfile | `oag-mesh/Cargo.lock:798-816` |

Verification: manifest and lockfile inspection only. The locked core commit was
not fetched or diffed.

## Next investigation

Fetch or inspect core `ce1122589909c151056de33325b14d7022efe2f0` and compare the
types mesh imports with the newer core checkout, starting with `oag-core` and
`oag-crypto` public exports.
