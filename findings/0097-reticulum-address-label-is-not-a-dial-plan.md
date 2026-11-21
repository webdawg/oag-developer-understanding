# 0097 — A stored Reticulum address is only a label to the HTTP sync loop

Claim `B-097`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, the Reticulum
client stores `reticulum:{address hash}` in the shared `peer_addresses` table.
A search finds no reader that parses that prefix or dials it. HTTP gossip
passes every stored address to `sync_with_peer`, which joins it to
`/oag/sync/v1`.

## Consequence

The label records where the Reticulum identity was contacted, but it is not a
validated dial plan. If HTTP gossip later enumerates that peer's addresses, it
will attempt an HTTP request using the `reticulum:` string as a base URL. OAG
does not skip unknown schemes before that call. Whether reqwest rejects the
string was not executed. The Reticulum client itself is invoked with a separate
`AddressHash` argument, not by reading this label back.

Arbitrary address strings learned from a Reticulum peer list enter the same
table and have the same later HTTP treatment. That is the discovery path from
finding 0078 applied to this transport.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-097a | Implemented writer | `crates/oag-reticulum/src/client.rs:108` |
| B-097b | Search | `format!("reticulum:` occurs only at that writer |
| B-097c | Implemented consumer | `crates/oag-sync/src/gossip.rs:55-66` and `client.rs:56-62` |

Verification: source search and inspection only.

## Next investigation

Trace the HTTP gossip address enumeration and determine whether bootstrap addresses and discovered addresses are deduplicated before a malformed address can be retried forever.