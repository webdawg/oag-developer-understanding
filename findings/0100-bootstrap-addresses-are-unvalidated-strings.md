# 0100 — Bootstrap addresses are unvalidated strings

Claim `B-100`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
`network.bootstrap_peers` is a list of strings with an empty default. Startup
prints the count and passes the list to `spawn_gossip_loop`. No inspected
parser checks scheme, host, port, or private-network status before the loop is
spawned.

## Behavior

The default sync interval is 30 seconds. An empty list does not start active
outbound gossip; the log says replication is passive until another peer syncs
or `oag peer add` is used. A non-empty string is retained for the process
lifetime as the bootstrap vector from finding 0099. It is concatenated into
sync URLs on every tick. Invalid strings therefore fail repeatedly rather than
being rejected at configuration load. The configuration comment describes who
to contact, but the type system accepts any string.

Environment and file merging may supply the list. This finding does not
establish the exact environment variable name.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-100a | Implemented | `crates/oag-cli/src/config.rs:136-155` |
| B-100b | Implemented | `crates/oag-cli/src/serve.rs:74` and `165-172` |

Verification: source inspection only. No configuration was loaded.

## Next investigation

Trace `oag peer add` and determine whether manually added addresses have the same lack of validation and whether they persist across restart.