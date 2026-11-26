# 0187 — IPFS GET prefers held bytes and checks audio, not the CID

Claim `B-0187`: at listend `b87dcac9a3c9e0059d90e698e2ec40fb2769ec41`,
`GET /ipfs/{cid}` serves a locally held copy when the CID maps to stored audio.
Only an unknown CID causes a Kubo `/api/v0/cat` fetch. Returned bytes are
sniffed as audio and labeled with their BLAKE3 hash, but the crate does not
verify that the bytes match the IPFS multihash in the CID.

## Order of behavior

1. The route extracts the CID from the path and asks the store for a mapped
   content hash. If that item is present, its bytes are used without a network
   call, so a down Kubo node does not take held audio with it.
2. For an unknown CID, a missing publisher yields 404. Otherwise
   `IpfsPublisher::cat` validates the CID text (non-empty, at most 128 ASCII
   alphanumeric/`-`/`_` characters) before writing it into a request line, then
   POSTs `/api/v0/cat?arg=<cid>` over plain HTTP/1.1 with `Connection: close`.
3. The reply is read under a 10-second per-read timeout and a total of
   `MAX_CAT_BYTES + MAX_RESPONSE_BYTES`. `split_reply` handles chunked or
   non-chunked bodies; `decode_chunked` now uses checked arithmetic and a
   saturating accumulated-size check.
4. A non-2xx status becomes `502 Bad Gateway`. Non-audio bytes become `400` with
   a fixed reason, and the returned bytes are not echoed. A successful response
   uses the sniff-derived media type, `ETag: "<cid>"`, `Cache-Control: public,
   max-age=31536000, immutable`, `X-Content-Hash: <BLAKE3>`, and a CID-based
   filename. Ranges are not advertised.
5. Nothing is stored by this route. It is reachability for bytes already in
   IPFS, not a new inbound publish channel.

## What is durable, rejected, and left behind

Durable: the route changes no store state. Rejected: malformed CIDs, connect or
read timeouts, oversized replies, malformed chunk framing, non-2xx statuses,
and non-audio payloads. Each leaves either 404/400/502 or no response from the
publisher; the original store remains unchanged.

Two identities are reported separately: ETag names the CID supplied by the
caller, while `X-Content-Hash` is computed from the bytes actually returned.
The source explicitly says there is no IPFS multihash verifier here, so a node
or on-path attacker could supply bytes that do not correspond to the CID; the
audio sniff is the only content gate. No Kubo node or HTTP request was started.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0187a | Implemented route and header construction | `crates/oag-listend/src/http.rs:688-765` |
| B-0187b | Implemented cat fetch and CID validation | `crates/oag-listend/src/ipfs.rs:206-270` |
| B-0187c | Implemented reply bounds and chunk parsing | `crates/oag-listend/src/ipfs.rs:25-48`, `50-107`, `229-257` |
| B-0187d | Implemented mirror intent | `crates/oag-listend/src/ipfs.rs:1-16` |
| B-0187e | Compared overflow fix | `git diff aad2d9b2..b87dcac9 -- crates/oag-listend/src/ipfs.rs` |

Verification: source inspection via `git show origin/master:<path>` and a scoped
diff. No IPFS node, daemon, or target test was executed.

## Change since the previously explained commit

At `aad2d9b2cc763239764fa8ba11ec7e871be00e11`, chunked decoding used unchecked
`pos + size` and `out.len() + size`, which could wrap on a hostile size. At
`b87dcac9...`, it uses `checked_add` and `saturating_add`, with a test for a
near-`usize::MAX` chunk. Finding 0106 described the unauthenticated bounded
fetch at the earlier commit; this finding records the newer bounds and the
exact response contract.

## Next investigation

Trace `oag_listend::ipfs::validate_cid` and `split_api` to document what text is
allowed into request lines and how an operator-supplied API address becomes a
host and path.
