# 0007 — Cluster broadcast is enabled by configuration and sent to every known address

Claim `B-007`: at `open-agent-graph` `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
cluster behavior is absent unless configuration supplies `cluster.name`. When
present, startup attaches that name and an identity to sync, then periodic
broadcast attempts delivery of a freshly signed declaration to every known peer
address.

## Configuration and startup

`ResolvedConfig.cluster_name` comes from `file.cluster.name`. `oag serve` enters
the cluster branch only when that value is `Some`. It calls `with_cluster`,
starts the announce loop, and starts cluster gossip. No cluster configuration
means no cluster-based federation bypass from this service, because
`same_cluster` returns false without `own_cluster`.

The inspected config loader also merges environment variables prefixed with
`OAG_`, but this finding does not establish the exact environment key that
overrides `cluster.name`.

## Broadcast semantics

`broadcast_cluster_declaration` returns zero unless both a cluster identity and
configured name exist. It signs a declaration with the current timestamp and
iterates every known peer's addresses. Delivery errors are logged at debug level
and do not stop attempts to later addresses. The return value counts attempts,
not confirmed receipts.

There is no authorization check against the recipients and no restriction that
the declaration goes only to peers already in the named cluster. Receiving peers
still apply finding 0006's signature and freshness verification before storage.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-007a | Implemented | `crates/oag-cli/src/config.rs:793-798` |
| B-007b | Implemented | `crates/oag-cli/src/serve.rs:69-74` |
| B-007c | Implemented | `crates/oag-sync/src/service.rs:464-494` |

Verification: source inspection only. No server was started.

## Next investigation

Trace `spawn_cluster_gossip_loop` and determine whether cluster peers receive a
faster or privileged event-sync path beyond the federation bypass.
