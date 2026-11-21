# 0073 — The public IPFS page can disclose the embedded dial address

Claim `B-073`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
`GET /ipfs-site/{cid}` is intentionally unauthenticated. It does not retrieve
IPFS content on the server. It returns a page containing the CID and, when
available, a libp2p WebSocket multiaddr for the browser to dial.

## Address selection

Startup uses the configured `libp2p_ws_multiaddr` when present. Otherwise it
asks the pinning provider for dialable addresses and takes the first. The
embedded provider returns its actual bound addresses, which finding 0072 shows
default to an all-interface ephemeral WebSocket listener. Disabled and Kubo
providers return no such list unless the operator configured an override.

The page checks only that the path looks like a CID: non-empty, at most 100
ASCII alphanumeric characters. It does not check that the server has the CID,
that it is public, or that the caller is authorized. Any such request can
therefore receive the dial address when embedded mode or an override supplies
one. The JavaScript assignment is JSON-escaped, so this is an information
disclosure finding, not an HTML-injection finding.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-073a | Implemented and documented intent | `crates/oag-api/src/ipfs_site.rs:1-8` and `35-67` |
| B-073b | Implemented selection | `crates/oag-cli/src/serve.rs:88-105` |
| B-073c | Implemented embedded addresses | `crates/oag-ipfs/src/embedded.rs:167-176` |

Verification: source inspection only. No HTTP request was sent.

## Next investigation

Trace the Reticulum listener and determine whether it authenticates peers before ingesting events or exposes another unauthenticated ingress.