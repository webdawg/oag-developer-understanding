# 0067 — A transfer relay forwards the caller's CID within a hop budget

Claim `B-067`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, when local CID
fetch fails and relay peers are configured, `relay_fetch` forwards the incoming
request's CID to configured relays. It stops at zero remaining hops, appends its
own peer ID to the path, and skips relays already in that path.

## Forwarding behavior

The function uses `req.unsigned.cid` unchanged and passes
`relay_hops_remaining - 1` to `fetch_and_verify`. The first successful relay
result is returned. Individual failures are logged and the next configured relay
is tried. There is no inspected allowlist of CIDs or check that the CID belongs
to local graph content. A signature-valid caller can therefore cause this peer
to request that CID from its configured relays until the hop budget or peer list
is exhausted.

The path check prevents this peer from immediately forwarding to a peer already
recorded in the path. It does not prove every other software version enforces
the same rule. Cost depends on configured relay count, hop budget, response
size, and rate limiting; none of those costs was measured.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-067 | Implemented | `crates/oag-api/src/transfer.rs:514-545` |

Verification: source inspection only. No relay request was sent.

## Next investigation

Trace `fetch_and_verify` response-size and content-hash checks to determine what a relayed CID fetch can return to the original caller.