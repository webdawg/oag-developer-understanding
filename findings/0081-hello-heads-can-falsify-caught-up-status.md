# 0081 — Hello heads are trusted as replication progress

Claim `B-081`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
`sync_with_peer` stores every decodable origin sequence from the remote hello as
that peer's known head. `replication_status` counts the peer fully caught up
when its stored sequence for this peer's own origin is greater than or equal to
the local sequence. The service comment says this is self-reported and not
independently verified.

## Effect

A peer that can complete hello can report an arbitrarily high sequence for this
peer's origin without proving it has those events. That increments
`peers_fully_caught_up`. The target is `max(3, ceil(sqrt(known_peer_count)))`.
Enough false reports can therefore make `meets_target` true. A redirected hello
from finding 0080 can supply the same unverified body, but a normal hello is
sufficient.

The inspected status function only reports this result. It does not delete data,
stop backups, or admit events. Whether any caller treats `meets_target` as a
safety gate was not traced. The unauthenticated replication-status route from
finding 0077 will publish the resulting counts and lagging peer IDs.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-081a | Implemented | `crates/oag-sync/src/service.rs:316-330` |
| B-081b | Implemented and documented intent | `crates/oag-sync/src/replication.rs:14-25` and `45-88` |

Verification: source inspection only. No false hello was sent.

## Next investigation

Search for callers of `meets_target` or `replication_status` and determine whether any operational decision treats the self-reported value as a gate.