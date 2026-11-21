# 0074 — Reticulum sync answers are unauthenticated when the listener is enabled

Claim `B-074`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, Reticulum TCP
listening is off unless configured. When enabled, an incoming link request is
handled without peer authentication. A global rate limiter can reject excess
requests, but a permitted request can return heads, event payloads, or the peer
table.

## What a request returns

`Hello` returns this peer's ID, public key, and origin heads. `Events` returns
up to 1,000 signed event envelopes for a requested origin and sequence range,
deserialized from `canonical_payload`. `Peers` returns known peer IDs, public
keys, addresses, and last-seen times. The handler does not consult
`federation_allows` or require a signed client identity.

The listener comment explicitly says these requests mirror the unauthenticated
HTTP sync endpoints. The rate limiter's `check` takes no caller identity, so it
is a process-wide throttle rather than per-peer authorization. Default
configuration leaves `listen_tcp` unset, so this ingress is opt-in. Enabling it
on a reachable address exposes event content to anyone who can open a link,
subject to the rate limit and transport reachability. Those were not tested.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-074a | Implemented | `crates/oag-reticulum/src/listener.rs:49-64` and `120-186` |
| B-074b | Implemented | `crates/oag-reticulum/src/handlers.rs:20-88` |
| B-074c | Implemented default | `crates/oag-cli/src/config.rs:571-585` |

Verification: source inspection only. No Reticulum listener was started.

## Next investigation

Compare the HTTP sync event endpoint and determine whether it has the same payload disclosure and any additional bound or federation check.