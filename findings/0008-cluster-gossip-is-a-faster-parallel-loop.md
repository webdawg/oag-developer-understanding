# 0008 — Cluster gossip is faster scheduling, not a different sync protocol

Claim `B-008`: at `open-agent-graph` `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
cluster gossip calls the same `sync_with_peer` path as ordinary gossip. The
difference is its address set and interval: it repeatedly selects same-cluster
addresses and can run on a shorter configured cadence while the ordinary loop
continues unchanged.

## Shared round behavior

Both loops call `sync_round`. For every address, that helper applies this
process's gravity delay and then calls `sync_with_peer`. One address failure
logs a warning and increments a shared error counter, but does not stop later
addresses. This finding does not interpret the gravity value as a security
boundary; its generator was not traced.

## Address selection

Ordinary gossip starts with configured bootstrap addresses, adds every known
peer address, sorts, deduplicates, syncs, and sleeps for the normal interval.

Cluster gossip asks `cluster_peer_addrs` on every tick. That list is empty when
no cluster is configured, making the loop a no-op. Otherwise it contains
addresses for peers whose latest stored cluster claim matches the local cluster
name. It therefore inherits the self-certification limitation from findings
0005–0007.

The loops are parallel, not alternatives. A matching cluster peer can be visited
by both loops. No lock preventing overlapping sync with the same address is
visible in these loops; concurrent behavior is **unknown**.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-008a | Implemented | `crates/oag-sync/src/gossip.rs:12-102` |
| B-008b | Implemented | `crates/oag-sync/src/service.rs:224-245` |

Verification: source inspection only. Gossip tests were not executed.

## Next investigation

Return to projection semantics for assertion events: trace node, edge, and
assertion IDs and determine which repeated assertions create new state versus
reuse existing rows.
