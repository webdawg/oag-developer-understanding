# 0106 — Listend's IPFS route fetches a caller-chosen CID without authentication

Claim `B-106`: at listend `aad2d9b2cc763239764fa8ba11ec7e871be00e11`,
`GET /ipfs/{cid}` has no authentication check. If the daemon already holds audio
for that CID, it serves those bytes. Otherwise, when an IPFS publisher is
configured, it asks that configured node to cat the CID, sniffs the result, and
serves it only if it looks like audio. The fetched bytes are not stored.

## Bounds

`cat` rejects an empty CID, a CID longer than 128 characters, or a CID
containing a byte other than ASCII alphanumeric, `-`, or `_`. The connect and
read attempts use a 10-second timeout. The reply is rejected when it grows
beyond `MAX_CAT_BYTES + MAX_RESPONSE_BYTES`, and `MAX_CAT_BYTES` is
`16 MiB - 256`. The comment states that the CID is not verified against an IPFS
multihash. A cat error becomes HTTP 502 and includes the error string. A
non-audio body becomes HTTP 400 and does not echo the bytes.

The host is the configured IPFS API, not a host taken from the CID. This is an
unauthenticated trigger of the configured node, not an open SSRF to an arbitrary
host. No request was sent.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-106a | Implemented route | `oag-listend/src/http.rs:677-714` |
| B-106b | Implemented fetch limits | `oag-listend/src/ipfs.rs:26-32` and `209-275` |
| B-106c | Implemented size constant | `oag-listend/src/protocol.rs:19` and `53` |

Verification: source inspection only.

## Next investigation

Trace listend IPFS configuration and determine whether the API address can include credentials and whether the daemon dials it in cleartext.