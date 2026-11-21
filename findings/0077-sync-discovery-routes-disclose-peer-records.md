# 0077 — Sync discovery routes disclose peer identity and replication detail

Claim `B-077`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, the
unauthenticated sync router exposes hello, heads, peers, and replication-status
routes behind the same global rate limit. They disclose this peer's identity,
known peers, and lagging peer IDs without a reader credential.

## Responses

`hello` returns protocol, version, this peer's ID and public key, and local
origin heads. A database error becomes an empty head map rather than an HTTP
error. `heads` returns the same head map. `peers` returns each known peer's ID,
public key, addresses, and last-seen time. A connection or query failure becomes
an empty list.

`replication-status` returns counts plus `lagging_peers`, whose struct contains
peer IDs and the sequence each has reported. This is more specific than the
metrics gauge, which exposes only the lagging count. The service comment says
these sequences are self-reported and not independently verified.

None of these handlers checks bearer authentication or federation policy. They
share the router middleware, so the 600-request global window applies, but that
does not redact the fields.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-077a | Implemented | `crates/oag-sync/src/server.rs:33-66` and `237-255` |
| B-077b | Implemented | `crates/oag-sync/src/server.rs:42` and `259-263`; `replication.rs:29-42` |

Verification: source inspection only. No sync request was sent.

## Next investigation

Trace whether peer addresses stored by discovery can include attacker-supplied URLs that later gossip will contact, creating a server-side request from an unauthenticated peer list.