# 0068 — Transfer verification checks the hash after the body is downloaded

Claim `B-068`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
`fetch_and_verify` reads the entire successful response body into memory, hashes
it, and only then compares that hash with the signed receipt. The inspected
function has no response-size limit before `bytes()`.

## Order

The client signs a fresh request, posts it, and rejects a non-success status.
On success it requires an `x-oag-transfer-receipt` header, parses it, downloads
the body, and compares `blake3_content_hash(body)` with the receipt's content
hash. It then verifies the receipt against the expected CID and client nonce
and checks the server peer ID. Only after those checks does it record a transfer
event and return the bytes.

A mismatched hash or receipt therefore does not prevent the download cost. The
error path for non-success responses also reads the response body into an error
string. Neither path shows a maximum byte count. Upstream server limits may
exist but were not traced in this function.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-068 | Implemented | `crates/oag-api/src/transfer.rs:425-496` |

Verification: source inspection only. No transfer was executed.

## Next investigation

Trace the server-side transfer response path for a body-size limit or streaming bound that the client function does not enforce.