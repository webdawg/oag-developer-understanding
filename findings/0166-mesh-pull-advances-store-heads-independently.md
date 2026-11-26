# 0166 — Mesh pull advances each store head independently

Claim `B-0166`: at mesh `45f9fa8a16f65fc4a2e2fe5238bbbc2a5e462574`,
anti-entropy compares five version stamps from a peer and fetches only changed
stores. After the pull, each store's remembered head advances only if that store
was attempted and succeeded. A failed store keeps its old head and is retried
next time, without forcing healthy stores to be re-fetched.

## Order of behavior

1. `pull_and_merge` first calls `pull_heads`. A connect error or timeout marks
   the peer unreachable: it records failure in link quality and skips the
   full-pull fallback. An HTTP rejection falls back to attempting all five
   stores.
2. `heads_changed` compares the remembered `StoreHeads` with the peer's current
   heads. No prior heads means all five are fetched. A changed `instance_id`
   also marks all five, because a restarted peer has new process-local state.
   Otherwise a store changes only when its own version differs.
3. `pull_changed_stores` fetches only the marked stores — bridge tree, claim
   corroboration, membership registry, anonymous events, responder
   acknowledgments — and calls each store's `merge_snapshot`/`merge` on success.
   Failures are logged and leave `ok[i] = false`.
4. `merge_heads` copies `instance_id` from the remote unconditionally. For each
   store it keeps the remote version only when `attempted[i] && ok[i]`; otherwise
   it keeps the old version. First-seen stores use `UNKNOWN_VERSION = u64::MAX`,
   which cannot equal a reported monotonic sequence, so they remain changed.
5. `link_quality` records whether all attempted pulls succeeded. Periodic
   helpers call peers in quality order; this crate does not schedule them by
   itself.

## What is durable, rejected, and left behind

Successful merges update in-memory stores; they become durable only if a caller
invokes `MeshState::save_to_dir` (finding 0158). A failed store's snapshot is not
partially applied by this function because the merge is called only after a
successful fetch. Its old head remains, so the next pull sees the same version
difference and retries. Healthy stores whose heads advanced are not re-fetched
just because another store failed.

Rejected/unreachable: a connect or timeout failure ends the pull before any
store fetch. An HTTP rejection of heads does not end it; the full-pull fallback
is attempted. Snapshot merges trust the configured peer's data; this function
does not re-run per-item signature or proof-of-work checks. No peer, HTTP
request, or target test was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0166a | Implemented pull decision | `crates/oag-mesh/src/transport.rs:1520-1566` |
| B-0166b | Implemented heads comparison and merge | `crates/oag-mesh/src/transport.rs:1568-1628` |
| B-0166c | Implemented store fetches | `crates/oag-mesh/src/transport.rs:1630-1694` |
| B-0166d | Implemented periodic order | `crates/oag-mesh/src/transport.rs:1696-1738` |
| B-0166e | New since explained commit | `git diff 9f5d89e9..45f9fa8a -- crates/oag-mesh/src/transport.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No sync round or target test was executed.

## Change since the previously explained commit

The five-store snapshot protocol, `StoreHeads`, `heads_changed`, `merge_heads`,
and `pull_changed_stores` are new at `45f9fa8a...` relative to explained
`9f5d89e9...`. Findings 0158-0165 describe the stores, ordering, and search that
coexist with this pull path; none is rewritten here.

## Next investigation

Trace `oag_mesh::transport::spawn_periodic_sync_with_jitter` to document when a
caller's sync loop actually runs, how jitter is chosen, and how it stops.
