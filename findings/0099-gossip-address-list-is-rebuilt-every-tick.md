# 0099 — Gossip copies addresses per tick and has no long-lived cache

Claim `B-099`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, the ordinary
gossip loop constructs a new local address vector on every iteration. Cluster
gossip also asks for its address list on every iteration. Neither loop keeps a
process-wide cache of addresses beyond the vector used by the current
`sync_round`.

## Removal timing

`peer_remove` deletes address rows immediately. A tick that has already copied
those strings into its local vector will still attempt them. The next tick reads
the database again and will not include the deleted rows unless another path
adds them. There is no inspected cancellation of an in-flight attempt when the
row disappears. The configured bootstrap vector is captured when the loop is
spawned and is independent of peer removal, so a bootstrap address continues
even after every peer row is gone.

This is a scheduling observation, not a measured race. The code shows the copy
and the sleep boundary; it was not executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-099a | Implemented | `crates/oag-sync/src/gossip.rs:54-72` and `89-98` |
| B-099b | Implemented deletion | `crates/oag-storage/src/repo/peers.rs:94-99` |

Verification: source inspection only.

## Next investigation

Trace bootstrap address configuration and determine whether a bootstrap address is validated before the gossip loop is spawned.