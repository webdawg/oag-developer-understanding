# 0028 — Imagination reads core peer and tensor state through storage

Claim `B-028`: at imagination
`7b7dcb8eae70b2df2fa1329fdb7b2dd928e76d29`, `NodeAdapter::load` opens a core
SQLite database, reads one node's tensor pad, lists peers and their first
address, and constructs an engine. Its locked `oag-core`, `oag-crypto`, and
`oag-storage` source matches inspected core `87f9e8c1` for those source
directories.

## Runtime boundary

The adapter:

1. calls `open_pool` on the supplied database path;
2. reads `tensor_pads` for the supplied peer and substitutes an empty pad when
   absent;
3. lists peers, excludes the node itself, and selects each remaining peer's
   first address as a neighbor;
4. constructs an engine with `SoftwareRandom`.

The module comment says this adapter is not a writer and does not add its own
migration. It also acknowledges that `open_pool` runs core's embedded
migrations. Therefore “not a writer” describes this adapter's own queries, not
the complete side effect of opening the database. Migration behavior was not
re-reviewed at the locked revision in this finding, although the storage source
directory matches the inspected checkout.

No live refresh is implemented in `load`: it returns one engine snapshot. The
core writers named by the comment, `oag-sync` and `oag-brain`, were not traced
from this repository.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-028a | Implemented | `oag-imagination/src/node.rs:1-66` |
| B-028b | Read-only source comparison | Core commits `4bdef2d0` and `87f9e8c1`; empty diff for the three crate source directories |

Verification: source inspection and `git diff --quiet` only. The adapter tests
were not executed, and no database was opened for this finding.

## Next investigation

Trace `SoftwareRandom` and the engine's routing decision to determine what is
recorded, reproducible, or verifiable by another peer.
