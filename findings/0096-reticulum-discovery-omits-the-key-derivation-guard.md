# 0096 — Reticulum peer discovery stores pairs HTTP discovery would reject

Claim `B-096`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, HTTP
`discover_peers` rejects an advertised peer ID that does not derive from its
public key before storing it. The Reticulum client's `discover_peers` parses
both fields and calls `upsert_peer` without that comparison.

## Consequence

A peer list received over the Reticulum link can therefore introduce a peer ID
paired with a non-derived key. Because `upsert_peer` does not replace
`public_key` on conflict, the first stored pair for a new peer ID remains. A
wrong first pair can make later signature checks for the real key fail, which
is the denial-of-replication case the HTTP comment explicitly guards. The
Reticulum path still caps one response at 200 peers and five addresses each.
The HTTP global 10,000-peer cap was not found in this Reticulum function.

The hello path on this same client does check derivation before its own upsert.
The omission is specific to the peer-list loop, not to every Reticulum identity
check. No peer list was submitted.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-096a | Implemented omission | `crates/oag-reticulum/src/client.rs:190-207` |
| B-096b | Implemented HTTP guard | `crates/oag-sync/src/service.rs:540-552` |
| B-096c | Implemented non-rotation | `crates/oag-storage/src/repo/peers.rs:40-48` |

Verification: source comparison only.

## Next investigation

Trace Reticulum address storage and determine whether a discovered `reticulum:` address or an arbitrary address string is later dialed without validation.