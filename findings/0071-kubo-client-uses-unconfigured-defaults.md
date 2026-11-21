# 0071 — The Kubo client adds no explicit timeout, redirect, or size policy

Claim `B-071`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, IPFS pinning is
disabled unless configuration selects a provider. The Kubo provider is
constructed with `reqwest::Client::new()` and an optional API key. This
constructor sets no timeout, redirect policy, or response-size limit.

## Configuration boundary

The default provider name is `disabled`. Selecting `kubo` without
`api_base_url` also yields `DisabledProvider` rather than failing startup.
When both are present, the operator-configured base URL receives `/api/v0/cat`
and `/api/v0/add` requests. A bearer token is added only when `api_key` is
configured. The CID comes from the caller or stored pin, but the host does not.

`libp2p_ws_multiaddr` is documented as browser dial information and is not used
by the server-side provider. Thus a transfer fetch can induce a request to the
configured Kubo endpoint, not to an arbitrary host chosen in the CID.

The absence of an explicit client policy does not prove reqwest's defaults. The
locked reqwest version's timeout and redirect behavior were not inspected. No
size limit is visible in the provider itself, as finding 0070 established.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-071a | Implemented | `crates/oag-ipfs/src/provider.rs:81-86` |
| B-071b | Implemented | `crates/oag-cli/src/config.rs:292-360` |

Verification: source inspection only. No Kubo request was sent.

## Next investigation

Trace the embedded IPFS listener default and determine whether enabling embedded mode exposes a WebSocket listener beyond localhost.