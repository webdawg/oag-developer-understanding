# 0107 — Listend's IPFS client is cleartext and does not add credentials

Claim `B-107`: at listend `aad2d9b2cc763239764fa8ba11ec7e871be00e11`,
`--ipfs-api` supplies a string stored on the publisher. `split_api` refuses
`https://` and accepts either `http://host[:port]` or a bare `host[:port]`. The
inspected cat request is plain HTTP to that host with no `Authorization`
header. A path after the host is ignored for the request target.

## Boundary

The comment says HTTPS is refused so the client does not silently speak
cleartext to an HTTPS port. The accepted configuration is itself cleartext.
The code does not parse userinfo into a credential header. If a userinfo-like
string is embedded in the host portion, it remains part of the connect address
and is not converted into authentication by the lines inspected. No connection
was made.

Startup with this flag also offers already stored audio to that node, bounded
by `STARTUP_MIRROR_BUDGET`. The exact budget and failure behavior are the next
trace, not part of this claim.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-107a | Implemented configuration | `oag-listend/src/main.rs:276-286` |
| B-107b | Implemented parser and request | `oag-listend/src/ipfs.rs:280-310` and `217-224` |

Verification: source inspection only.

## Next investigation

Trace startup mirroring and record how many stored items are offered, whether failures stop the daemon, and whether the operator must opt in per item.