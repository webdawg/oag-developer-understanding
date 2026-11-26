# 0168 — MeshNodeAdapter is the implemented base-to-mesh connection

Claim `B-0168`: at mesh `45f9fa8a16f65fc4a2e2fe5238bbbc2a5e462574`,
`MeshNodeAdapter::load` builds mesh state from an existing Open Agent Graph data
directory: the same `identity.key`, the base peer table, and a private
`<data-dir>/mesh/` store directory. This is a source-backed cross-repository
connection, unlike the Data Roads proposal. The adapter does not write base
graph rows, but `load_or_generate` and `open_pool` can create the identity file
or database and run embedded migrations if they are absent or behind.

## Order of behavior

1. `load(data_dir)` calls `PeerIdentity::load_or_generate(identity.key)`. The
   mesh therefore shares the base peer's cryptographic identity, generating the
   file on a first run rather than minting a second identity.
2. `dialable_peers(data_dir/oag.sqlite)` opens the base SQLite pool and calls
   `peers::list_peers`, which selects rows ordered by `first_seen`. For each
   peer it takes only the **first** address from `peers::list_addresses`.
3. `dial_address` prepends `http://` when the stored address has no `http://`
   or `https://` scheme, matching the base sync client's convention.
4. `MeshState::load_from_dir(identity, peers, data_dir/mesh)` restores the seven
   mesh snapshots through the commit-marker check (finding 0158). A first run
   with no files yields empty stores.
5. `save(state, data_dir)` creates `<data-dir>/mesh/` and calls
   `save_to_dir`. The adapter does not call save automatically; a caller still
   chooses when persistence happens.

## What is durable, rejected, and left behind

Durable: the mesh snapshots under `data_dir/mesh/`, including `commit.json`.
The base `identity.key` and `oag.sqlite` are the source inputs and are not
replaced by `save`. On load, however, a missing identity file is generated and a
missing SQLite file is created with WAL, foreign keys, a 5-second busy timeout,
and embedded migrations. That is a write side effect of the "read" adapter on a
fresh or stale data directory.

Rejected here: a torn mesh snapshot set (`load_from_dir` returns
`PersistenceError::TornSet`); a legacy directory with no marker is still
accepted. A peer with no stored address contributes no dialable URL. Only the
first stored address per peer is used, so additional addresses are ignored for
mesh dialing. No daemon, migration, or target test was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0168a | Implemented adapter | `crates/oag-mesh/src/node.rs:1-102` |
| B-0168b | Implemented base identity and peer reads at locked core | core `59ccf3de`: `crates/oag-storage/src/repo/peers.rs:74-79`, `109-118` |
| B-0168c | Implemented database open at locked core | core `59ccf3de`: `crates/oag-storage/src/pool.rs:9-28` |
| B-0168d | Manifest pins core main with a lock entry | mesh `Cargo.toml:12-22`; mesh `Cargo.lock` `oag-storage` entry `59ccf3de` |
| B-0168e | Implemented mesh persistence | `crates/oag-mesh/src/transport.rs:321-450` |

Verification: source inspection via `git show origin/main:<path>` for mesh and
`git show 59ccf3de:<path>` for the locked core revision. No service was started.

## Change since the previously explained commit

At explained `9f5d89e9...`, the module comment says no caller existed for
`MeshState::save_to_dir`/`load_from_dir`. At `45f9fa8a...`, `node.rs` is new and
supplies that caller, along with the identity/peer bridge to the base project.
Findings 0158-0167 describe the state and routines this adapter wires together;
none is rewritten here.

## Next investigation

The source branch heads were fetched at the start of this session and remain
unchanged in `specs/revisions.md`. Re-run the fetch on the next invocation, then
choose the largest remaining gap from the journal.
