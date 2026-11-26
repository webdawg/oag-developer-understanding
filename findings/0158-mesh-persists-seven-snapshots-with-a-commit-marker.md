# 0158 — Mesh persistence writes seven JSON snapshots plus a commit marker

Claim `B-0158`: at mesh `45f9fa8a16f65fc4a2e2fe5238bbbc2a5e462574`,
`MeshState::save_to_dir` snapshots seven in-memory stores into individual JSON
files and writes `commit.json` last with each file's BLAKE3. Loading verifies
that marker before trusting the set: a mismatched set is refused, while a
directory with no marker is accepted as legacy. This module did not exist at
the explained `9f5d89e9...`.

## Order of behavior

1. `save_to_dir` takes snapshots in a fixed order: `bridge_tree.json`,
   `claim_corroboration.json`, `anonymous_events.json`,
   `membership_registry.json`, `responder_acknowledgments.json`,
   `responder_subscriptions.json`, and `responder_inbox.json`.
2. Each save serializes pretty JSON to `<name>.<pid>.<counter>.tmp`, then
   renames it over the destination. On Unix the rename replaces atomically; on
   Windows the destination is removed first, leaving a non-atomic window. Two
   processes get different temp names, but there is no cross-process lock.
3. After each file is written, `hash_file` reads its exact bytes and records
   `CommitEntry { file, blake3 }`. Once all seven succeed, `write_commit_marker`
   atomically saves `commit.json` with version `1` and those entries.
4. `load_from_dir` calls `verify_commit_marker` first. No marker returns
   `CommitState::Legacy` and loading continues with whatever files exist. A
   marker with an unsupported version, a missing/unreadable file, or a hash
   mismatch returns `TornSet` and no state is built.
5. On a consistent or legacy directory, each JSON file is loaded independently
   and a missing file defaults to an empty store. Identity, peer list, HTTP
   client, rate limiters, random `instance_id`, sync heads, relay target, and
   the link-quality ledger are constructed fresh rather than restored.

## What is durable, rejected, and left behind

Durable: the seven JSON stores and their commit marker. Whole files are
rewritten on every save; there is no WAL, incremental write, or automatic save
on each in-memory mutation. The caller chooses when to save.

Rejected at load: a marker that describes a different set than the files on
disk. A crash after some files were replaced but before the new marker was
written leaves the old marker disagreeing with the new files; the load returns
`TornSet` rather than guessing or rolling back (Inferred from write order; no
crash was injected). Orphaned `.tmp` files are not cleaned by the shown code.
A legacy directory with no marker is deliberately still loaded, so a mixed set
written by an older version is not rejected. No save or load was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0158a | Implemented snapshot set and call order | `crates/oag-mesh/src/transport.rs:321-377` |
| B-0158b | Implemented marker verification | `crates/oag-mesh/src/persistence.rs:46-151` |
| B-0158c | Implemented file write and read | `crates/oag-mesh/src/persistence.rs:165-197` |
| B-0158d | Implemented load reconstruction | `crates/oag-mesh/src/transport.rs:379-450` |
| B-0158e | New module and state since explained commit | `git diff 9f5d89e9..45f9fa8a -- crates/oag-mesh/src/persistence.rs crates/oag-mesh/src/transport.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No target test or filesystem crash was executed.

## Change since the previously explained commit

The explained `9f5d89e9...` mesh findings describe in-memory bridge, claim, and
anonymous-event stores. At `45f9fa8a...`, `persistence.rs` and the
`save_to_dir`/`load_from_dir` methods are new; the seven-store snapshot and
commit-marker behavior has no earlier mesh finding. Older findings about those
in-memory mechanisms still describe their in-memory logic, but not this new
durability layer.

## Next investigation

Trace `oag_mesh::rate_limit::RateLimiter` and `TokenBucket` to document which
new mesh routes use which limiter and what a rejected request leaves behind.
