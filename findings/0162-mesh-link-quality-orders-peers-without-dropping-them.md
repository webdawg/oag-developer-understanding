# 0162 — Mesh link quality orders peers without ever excluding them

Claim `B-0162`: at mesh `45f9fa8a16f65fc4a2e2fe5238bbbc2a5e462574`, each
observed delivery updates an exponential moving average per peer address. Route
search and anti-entropy use that score only to order peers; every configured
peer remains eligible. The ledger is in-memory, is not part of the seven-store
snapshot, and measures answer delivery rather than honesty.

## Order of behavior

1. A new peer score is `UNKNOWN_PEER_SCORE = 0.5`. `record(peer, delivered, now)`
   increments `attempts`, increments `successes` when delivered, and updates
   `score = 0.9 * old + 0.1 * (1 or 0)` with `QUALITY_LEARNING_RATE = 0.1`.
   `updated_at` is wall-clock Unix seconds.
2. Route-search tasks record `result.is_some()` after each outbound request: a
   usable reply is a success, a transport error or no answer is a failure.
   `pull_and_merge` records false for unreachable peers and for pull outcomes
   that did not deliver; successful store merges record true.
3. `ordered(peers)` gives unseen peers the neutral 0.5 score, sorts descending
   with a stable sort, and returns every input address exactly once. Equal
   scores therefore preserve configuration order.
4. `search_for_route` orders not-yet-asked peers before taking the first
   `fanout_budget` addresses. The budget, not the score, decides how many are
   asked.
5. `sync_with_all_peers` and `sync_with_all_peers_bounded` order pulls the same
   way. The bounded variant leaves later peers for the next tick when its
   deadline expires; it does not remove them.
6. `MeshState::save_to_dir` writes seven stores and does not include this
   ledger; `load_from_dir` constructs a fresh `LinkQualityLedger::default()`.

## What is durable, rejected, and left behind

Durable: nothing outside process memory. A restart re-learns scores from new
observations. Rejected: no peer is rejected by score. A peer whose EMA has
approached 0.0 is asked last, including under a tight fan-out budget; it can
still be selected if the budget reaches it. The EMA converges toward but does
not mathematically reach 0 or 1, and the raw `success_ratio()` is reported
separately from the smoothed score.

A peer that answers with false or malicious data scores as a success, because
the observation is only "a usable answer arrived"; corroboration is a different
layer. No request, pull, or target test was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0162a | Implemented ledger and scoring | `crates/oag-mesh/src/link_quality.rs:1-146` |
| B-0162b | Implemented route-search observation and ordering | `crates/oag-mesh/src/transport.rs:945-995` |
| B-0162c | Implemented pull observations and sync order | `crates/oag-mesh/src/transport.rs:1520-1560`, `1700-1738` |
| B-0162d | Implemented non-persistence | `crates/oag-mesh/src/transport.rs:321-377`, `379-450` |
| B-0162e | New since explained commit | `git diff 9f5d89e9..45f9fa8a -- crates/oag-mesh/src/link_quality.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No sync or target test was run.

## Change since the previously explained commit

The `link_quality.rs` module, its field on `MeshState`, and its call sites are
new at `45f9fa8a...` relative to explained `9f5d89e9...`. Findings 0158-0161
describe the persistence, limiter, dispatch, and onion mechanisms that coexist
with this ledger; none is rewritten here.

## Next investigation

Trace `oag_mesh::membership::MembershipRegistry` to document what a membership
attestation adds, how revocation or expiry is represented, and which snapshots
expose it.
