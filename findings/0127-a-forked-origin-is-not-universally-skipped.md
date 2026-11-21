# 0127 — A forked origin is still offered unless ephemeral trust rejects it

Claim `B-127`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, detecting a
fork sets `peers.forked` and does not remove the origin or change
`highest_contiguous_sequence`. `local_heads` still advertises that sequence.
`sync_with_peer` does not read the fork flag directly.

## When the flag matters

`federation_allows` returns true immediately for a same-cluster claim, before
trust is computed. `FederationPolicy` checks only open-or-allowlist membership.
The default `minimum_trust` is 0, so a non-ephemeral service never consults
`trust_score`. Only `identity_ephemeral` sets the minimum to the smallest
positive `f32`, and then a forked peer scores 0 and is refused. A same-cluster
claim still bypasses that refusal.

On the tick that detects the fork, the loop stops that origin's remaining
events and continues with other origins in the same hello. A later tick offers
the forked origin again whenever the remote head is ahead and the policy above
allows it. No sync was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-127a | Implemented flag | `oag-storage/src/repo/peers.rs:127-133` |
| B-127b | Implemented heads | `oag-sync/src/service.rs:209-220` and `282-287` |
| B-127c | Implemented gate | `oag-sync/src/service.rs:254-273` and `348-350` |
| B-127d | Implemented mode | `oag-cli/src/serve.rs:51-53` and `oag-sync/src/trust.rs:33-37` and `81-83` |

Verification: source inspection only.

## Next investigation

Trace whether the conflicting event stored by `record_fork` is returned by the events range endpoint or remains invisible to later pullers.