# 0101 — `peer add` persists a URL after hello, without a prior allowlist

Claim `B-101`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, `oag peer add`
passes the operator string directly to `sync_with_peer`. There is no scheme or
host check before the request. If hello succeeds, that same string is stored as
the peer address and therefore survives restart through SQLite.

## Boundary

The command returns the sync summary even when individual origin fetches record
warnings. Address storage happens before those fetches, so a successful hello
persists the URL even if later event fetches fail. A hello failure returns
before storage. `peer_sync` later recognizes a stored `reticulum:` prefix and
refuses to treat it as HTTP, but the ordinary gossip loop from finding 0097 does
not have that special case.

This command is local filesystem access, not a network enrollment protocol. It
does not prove the stored URL remains the final host after redirects.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-101a | Implemented | `crates/oag-cli/src/commands.rs:30-41` and `55-64` |
| B-101b | Implemented storage point | `crates/oag-sync/src/service.rs:297-310` |

Verification: source inspection only. No peer was added.

## Next investigation

Trace `peer add-reticulum` and determine what TCP endpoint and address hash it trusts before dialing.