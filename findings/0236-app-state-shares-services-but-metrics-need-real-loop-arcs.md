# 0236 — AppState shares services, but metrics need the real loop's counters

Claim `B-0236`: at core `fb54e431332a030a566099c76fb2558084765422`,
`AppState::new` builds one `Arc<GraphService>` used by REST, MCP, and the
crawler. It also builds a separate `SyncService` handle for read-only metrics;
sync error and replication-byte counters must be injected from the real gossip
loop or they remain zero.

## Order of behavior

1. `AppState::new(graph)` clones the graph into a `CrawlerService` with default
   config, disabled extractor, and disabled IPFS provider. It stores the graph
   arc itself for REST and MCP.
2. It constructs a second `SyncService` from `graph.pool()` and identity. Its
   doc comment says this is sufficient for `replication_status()` reads but not
   for counters belonging to the running gossip loop.
3. `sync_errors`, `replication_bytes_in`, and `replication_bytes_out` are fresh
   zero `Arc<AtomicU64>` values by default. `oag serve` must call
   `with_sync_errors` and `with_replication_bytes` with the live loop's arcs.
4. The API's `reqwest::Client` now has a 10-second connect timeout and 120-second
   total timeout for peer-to-peer gateway/relay requests. The previous default
   client had no explicit bounds.
5. Transfer and gateway each have their own `RateLimiter`, distinct from the
   bearer/anonymous REST limiter, because signed peer IDs are available there.
   IPFS providers, relays, and gateway peers default to empty/disabled.

## What is durable, rejected, and left behind

Durable: no AppState fields are persisted; they are process-local arcs and
configuration. Rejected: an outbound peer request that exceeds connect/total
timeouts is abandoned. Empty opt-in fields cause endpoint-specific disabled or
no-relay behavior rather than a startup failure.

If the live counter arcs are not injected, `/metrics` reports zero for sync
errors and replication bytes even though the gossip loop is active. That is a
wiring property of AppState, not evidence that no replication happened. No
server, gateway, or transfer was started.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0236a | Implemented shared graph/crawler and separate sync handle | `crates/oag-api/src/state.rs:21-44`, `111-150` |
| B-0236b | Implemented counter injection helpers | `crates/oag-api/src/state.rs:204-231` |
| B-0236c | Implemented outbound timeouts | `crates/oag-api/src/state.rs:9-18`, `138-150` |
| B-0236d | Implemented separate limiters and opt-in providers | `crates/oag-api/src/state.rs:57-104` |
| B-0236e | Changed fields and client | `git diff 87f9e8c1..fb54e431 -- crates/oag-api/src/state.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No app server or metric scrape was executed.

## Change since the previously explained commit

New at `fb54e431...`: API connect/request timeout constants, replication byte
counters, the `with_replication_bytes` injector, and the bounded reqwest client.
The GraphService-sharing and separate-sync-handle design predates it. Findings
0209 and 0235 describe consumers of these fields.

## Next investigation

Trace `oag-cli/src/serve.rs` to document where the live gossip loop's counters
are handed to AppState and when that wiring happens relative to router startup.
