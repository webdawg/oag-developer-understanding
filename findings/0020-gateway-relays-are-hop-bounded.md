# 0020 — Gateway relays stop at zero hops and avoid path repeats

Claim `B-020`: at `open-agent-graph` `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
gateway relay attempts stop when the remaining hop count is zero or no relay
peers are configured. Before each attempt, the current peer appends its own ID
to the path and skips a relay already present in that path.

## Loop bound

`relay_gateway_query` tries configured relay peers in order and returns the
first successful result. It passes `hops_remaining - 1` and the extended path to
`query_peer`. Because that function builds a signed request containing both
fields, the next peer receives a signed hop budget and path rather than an
unsigned routing hint.

The local skip prevents this peer from immediately forwarding to a peer already
recorded in the path. It does not by itself prove that every peer on the network
enforces the same rule. A peer running different or older software was not
compared. The zero-hop check bounds forwarding performed by this implementation.

Failure of one relay logs a warning and tries the next configured relay. Exhausting
all choices returns `None`, which the resolver turns into `CannotResolve` when no
other resolution path succeeded.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-020 | Implemented | `crates/oag-api/src/gateway.rs:639-668` and `713-716` |

Verification: source inspection only. No relay network was run.

## Next investigation

Move from core gateway behavior to the first cross-repository boundary: compare
the pinned mesh lockfile revision with this core revision and identify the
actual imported core APIs.
