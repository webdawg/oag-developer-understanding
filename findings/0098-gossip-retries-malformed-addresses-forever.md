# 0098 — Gossip retries every stored address on every tick

Claim `B-098`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, the ordinary
gossip loop rebuilds its address list on every tick from configured bootstrap
addresses plus every address stored for every known peer. It sorts and
deduplicates exact strings, then attempts all of them. A failed attempt does
not remove the address.

## Retry behavior

`sync_round` logs a warning and increments an error counter when `sync_with_peer`
returns an error, then continues with the next address. The loop sleeps and
repeats. There is no inspected failure threshold, quarantine, or scheme filter.
A malformed or redirecting address therefore remains a target until an operator
removes the peer or the address is otherwise deleted. Deduplication only removes
identical strings; `http://peer` and `http://peer/` are different if both are
stored, because trimming occurs later inside the client rather than before
dedup.

Bootstrap addresses are added even when database reads fail, so configured
targets survive a transient peer-list error. Cluster gossip uses a different
address function, but its per-address attempt is the same `sync_round`.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-098a | Implemented | `crates/oag-sync/src/gossip.rs:12-30` and `54-72` |
| B-098b | Implemented dedup input | The loop sorts and deduplicates the raw address list before `sync_with_peer` |

Verification: source inspection only. No gossip loop was run.

## Next investigation

Trace `peer_remove` address deletion against gossip timing and determine whether an in-flight tick can retain a removed address until the next rebuild. The current loop rebuilds the list each tick, so removal takes effect on the following tick unless a tick already copied the address. State that explicitly after confirming no in-memory cache beyond the current tick.