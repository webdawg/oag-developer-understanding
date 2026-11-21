# 0088 — A new peer key is learned from hello or discovery; the old peer remains

Claim `B-088`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, a newly
generated identity does not need a pre-stored key to have its own events
accepted by a peer that syncs with it directly. That sync uses the hello's
public key when the advertised origin is the contacted peer. The old peer row
is not removed automatically.

## Acceptance path

`sync_with_peer` rejects a hello whose peer ID does not derive from its public
key. For origins equal to that remote peer, event ingestion uses the hello key
directly. Other origins use a key already stored in the peer table and are
skipped when it is missing. `discover_peers` runs before that fetch loop and can
store a derived key from the remote peer list in the same sync. A transitive
peer therefore needs to be advertised with a matching key before its events are
fetched. A direct hello is enough for the contacted peer's own new chain.

`upsert_peer` inserts a new peer ID. On conflict it updates `last_seen` and
possibly name, not `public_key`. Identity change works because the new key has
a new peer ID; it is not a rotation of the old row. Nothing in startup or sync
deletes the old peer ID. The only inspected removal is the operator command
`peer_remove`. The same address can be stored for both peer IDs because
`peer_addresses` is unique on `(peer_id, address)`, not on address alone.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-088a | Implemented | `crates/oag-sync/src/service.rs:297-310` and `336-361` |
| B-088b | Implemented | `crates/oag-storage/src/repo/peers.rs:40-48` and migrations `0002_peers.sql:14-17` |
| B-088c | Implemented removal | `crates/oag-cli/src/commands.rs:223-230` |

Verification: source inspection only. No identity rotation was executed.

## Next investigation

Trace `remove_peer` and determine whether it removes addresses, known heads, and fork records or leaves those references behind.