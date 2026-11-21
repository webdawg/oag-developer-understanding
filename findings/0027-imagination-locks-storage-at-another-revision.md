# 0027 — Imagination locks core storage at a third revision

Claim `B-027`: at imagination
`7b7dcb8eae70b2df2fa1329fdb7b2dd928e76d29`, the manifest declares `oag-core`,
`oag-crypto`, and `oag-storage` as Git dependencies on core branch `main`.
`Cargo.lock` resolves all three to core commit
`4bdef2d00b706b9d210b9f2b1678978f94a2b4f1`.

That revision differs from both inspected core
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and mesh's locked core
`ce1122589909c151056de33325b14d7022efe2f0`. The locked commit has not yet been
fetched or compared.

## Consequence

Imagination has a direct storage dependency, so a runtime connection to core's
SQLite schema is possible. This lockfile entry does not prove which functions it
calls, whether it opens a core database, or whether its locked storage source
matches the inspected checkout. All such behavior remains **unknown** until the
locked revision and call sites are inspected.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-027a | Implemented manifest | `oag-imagination-random-data-compute/Cargo.toml:16-21` and `crates/oag-imagination/Cargo.toml:8-10` |
| B-027b | Implemented lockfile | `Cargo.lock:1388-1453` |

Verification: manifest and lockfile inspection only.

## Next investigation

Fetch core `4bdef2d00` read-only, compare `oag-storage` source with the inspected
checkout, and trace imagination's storage calls against the matching revision.
