# 0078 — Discovered peer addresses become later sync request targets

Claim `B-078`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, peer discovery
stores up to five address strings per advertised peer with no inspected scheme,
host, or private-network validation. Later gossip passes those strings to
`sync_with_peer`, which requests `{address}/oag/sync/v1/hello`.

## Boundary

`add_address` inserts the string unchanged. `SyncClient::base` only trims a
trailing slash and appends the sync prefix. It does not check that the address
is HTTP(S), public, or the peer that was originally contacted. A peer that this
node already syncs can therefore advertise an address that a later gossip tick
will request. This is not by itself an unauthenticated internet caller inserting
an address: the inspected insertion path is discovery during an outbound sync.

The sync client streams responses and stops at 4 MiB before JSON parsing. That
bounds memory for one response but does not validate the target. The client is
the default reqwest client, whose redirect and timeout policy was not inspected.
No private-network guard comparable to the crawler was found in this path.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-078a | Implemented storage | `crates/oag-storage/src/repo/peers.rs:81-88` and discovery loop in `service.rs:540-561` |
| B-078b | Implemented request construction | `crates/oag-sync/src/client.rs:28-62` and `service.rs:297-310` |

Verification: source inspection only. No malicious peer list was submitted.

## Next investigation

Trace reqwest redirect behavior only if the locked crate is available; otherwise inspect whether sync URLs can include embedded credentials or non-HTTP schemes by caller convention and tests.