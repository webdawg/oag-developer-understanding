# 0167 — Mesh periodic sync starts immediately and is explicitly opted into

Claim `B-0167`: at mesh `45f9fa8a16f65fc4a2e2fe5238bbbc2a5e462574`,
constructing `MeshState` does not schedule anti-entropy. A caller must spawn one
of the periodic helpers; it runs a full sync immediately, then sleeps for
`interval + jitter` after each tick completes. Jitter is a non-cryptographic
phase spread, not a security control.

## Order of behavior

1. `spawn_periodic_sync(state, interval)` delegates to
   `spawn_periodic_sync_with_jitter(state, interval, Duration::ZERO)`. Both
   return a `tokio::task::JoinHandle<()>`.
2. Each loop iteration calls `sync_with_all_peers(&state).await` first, then
   computes jitter and sleeps. The interval therefore starts after the tick
   finishes; a slow tick delays the next one.
3. `random_jitter(max)` returns zero when `max` is zero. Otherwise it builds a
   `std::collections::hash_map::RandomState` hasher, hashes the current Unix
   nanoseconds, and returns `hash % max.as_nanos()`. The seed is per-process and
   not persisted; a restart re-randomizes the phase.
4. `spawn_periodic_sync_with_budget` uses `sync_with_all_peers_bounded` and a
   plain `interval` sleep with no jitter. A zero or negative tick budget behaves
   like the unbounded form, leaving later peers for the next tick.
5. Dropping the runtime or calling `.abort()` on the handle stops the loop. The
   source notes that cancellation happens at the next `.await` point; there is
   no separate graceful mid-tick shutdown.

## What is durable, rejected, and left behind

The schedule itself is not durable: no cadence or phase is saved, and a restart
requires the caller to spawn it again. An unreachable peer on one tick is logged
by the pull path and retried on the next tick; it never ends the loop. A tick
that exceeds a bounded budget leaves unsynced peers for later.

Jitter uses a hash of the clock rather than a cryptographic RNG because it only
has to desynchronize independent nodes; the source explicitly does not claim
adversarial unpredictability. No scheduler, timer, or peer was executed in this
documentation pass.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0167a | Implemented opt-in and immediate loop | `crates/oag-mesh/src/transport.rs:1740-1779` |
| B-0167b | Implemented budget variant | `crates/oag-mesh/src/transport.rs:1781-1798` |
| B-0167c | Implemented jitter generation | `crates/oag-mesh/src/transport.rs:1800-1814` |
| B-0167d | Implemented underlying peer order | `crates/oag-mesh/src/transport.rs:1700-1738` |
| B-0167e | New since explained commit | `git diff 9f5d89e9..45f9fa8a -- crates/oag-mesh/src/transport.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No task, timer, or sync round was executed.

## Change since the previously explained commit

`spawn_periodic_sync`, its jitter and budget variants, and the explicit "not
scheduled by default" posture are new at `45f9fa8a...` relative to explained
`9f5d89e9...`. Finding 0166 describes what one tick does; this finding describes
when ticks happen. No older finding is rewritten.

## Next investigation

Inspect `oag_mesh::node::NodeAdapter` at the same head to document what a caller
must provide to run a mesh node and which engine/state objects it owns.
