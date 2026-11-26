# Connection register

| ID | Endpoints | Revisions | State |
| --- | --- | --- | --- |
| C-001 | `oag-mesh` build-imports `oag-core::canonical_json_bytes` and `oag-crypto` signing types | Mesh `9f5d89e9`; locked core `ce112258`; inspected core `87f9e8c1` | Source matches. No event-log or runtime peer integration is established. |
| C-002 | `oag-imagination` reads core `tensor_pads`, `peers`, and `peer_addresses` through `oag-storage` | Imagination `7b7dcb8e`; locked core `4bdef2d0`; inspected core `87f9e8c1` | Source matches. One-shot read path inspected; opening the database can run core migrations. |
| C-003 | Data Roads proposes use of core events and mesh distribution | Data Roads `b5cd2f4e`; no executable dependency | Proposal only. No implementation or runtime connection found. |
| C-004 | Mesh object-history RFC proposes ownership-gated object records | Mesh `9f5d89e9`; no implementation symbol found | Proposal only. Not a transport or storage connection. |
| C-005 | `oag-mesh::MeshNodeAdapter` reads base `identity.key`, `peers`/`peer_addresses`, and writes `<data-dir>/mesh/` | Mesh `45f9fa8a`; locked core `59ccf3de`; inspected core head `fb54e431` | Implemented. Mesh shares the base peer identity and dials the base peer list; it does not write base graph rows. `load_or_generate` can create the identity file and `open_pool` can create/migrate the SQLite file. |

No other cross-repository connection has yet been established.
