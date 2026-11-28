# 0237 — `oag serve` wires live sync counters before building routers

Claim `B-0237`: at core `fb54e431332a030a566099c76fb2558084765422`, the CLI
captures the real `SyncService`'s error and replication-byte `Arc` counters
before configuring trust/cluster behavior or spawning gossip loops, then hands
those same arcs to `AppState` before building REST/MCP routers. Metrics reads
therefore see the running loop's values.

## Order of behavior

1. `serve::run` creates a `SyncService` from the sync pool, peer identity, key,
   and federation policy.
2. It calls `sync_errors_counter()` and `replication_bytes_counters()` and keeps
   those arcs. Later `with_minimum_trust`, `with_heartbeat_identity`, and
   `with_cluster` mutate the same service value, preserving its counter arcs.
3. It conditionally spawns heartbeat, cluster announce, and cluster gossip
   loops, always spawns the main gossip loop, and builds the sync router from
   clones of that service.
4. It creates `AppState::new(graph)` and chains `with_sync_errors` and
   `with_replication_bytes` with the captured arcs.
5. Only then does it call `build_router`, merge the sync router, optionally
   construct MCP, and build the app. Handler state therefore already contains
   the live counter references.

## What is durable, rejected, and left behind

Durable: none of these counters are persisted; they are process-lifetime atomic
values. If the wiring calls were omitted, `AppState`'s defaults would be fresh
zero counters and `/metrics` would under-report while gossip still ran. A
failure before app build prevents startup rather than exposing a partially
wired router.

The ordering matters for correctness but not because handlers poll during
startup: the arcs are shared references, so later increments by the spawned
loops are visible to metrics. No server or gossip loop was started here.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0237a | Implemented counter capture | `crates/oag-cli/src/serve.rs:43-52` |
| B-0237b | Implemented loop/router startup | `crates/oag-cli/src/serve.rs:53-78` |
| B-0237c | Implemented AppState injection | `crates/oag-cli/src/serve.rs:105-123` |
| B-0237d | Implemented service counter accessors | `crates/oag-sync/src/service.rs:167-185` |
| B-0237e | Changed replication-byte wiring | `git diff 87f9e8c1..fb54e431 -- crates/oag-cli/src/serve.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No CLI server, sync loop, or metrics scrape was executed.

## Change since the previously explained commit

Capture and injection of `replication_bytes_in`/`out` are new at `fb54e431...`;
`sync_errors` wiring and the general ordering predated it. Finding 0236 records
why AppState needs these arcs; this finding records where they come from.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining gap from
the journal and revision table.
