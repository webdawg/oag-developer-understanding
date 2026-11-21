# 0072 — Embedded IPFS defaults to an all-interface WebSocket listener

Claim `B-072`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, embedded IPFS
is not enabled by default. When the operator selects `pinning_provider =
"embedded"` and does not set listen addresses, configuration supplies
`/ip4/0.0.0.0/tcp/0/ws`. The provider then starts a node with TCP, WebSocket,
and mDNS enabled and binds those addresses.

## Exposure

`0.0.0.0` means every IPv4 interface, not localhost. Port `0` selects an
ephemeral port at bind time. The provider reads the actual listening addresses
after startup and appends its peer ID so a browser can dial them. The config
comment identifies WebSocket as the browser-dialable transport. mDNS is enabled
in the builder, but this finding does not establish what it announces or whether
the dependency actually binds the supplied address.

This is an operator-selected mode, not the default disabled provider. It is
still a materially different exposure from a localhost-only listener, and the
default does not require the operator to choose that exposure explicitly.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-072a | Implemented default | `crates/oag-cli/src/config.rs:313-316` and `364-371` |
| B-072b | Implemented startup | `crates/oag-ipfs/src/embedded.rs:36-48` |

Verification: source inspection only. No embedded node was started.

## Next investigation

Trace the `/ipfs-site/{cid}` page and determine whether it publishes the embedded dial addresses to unauthenticated HTTP clients.