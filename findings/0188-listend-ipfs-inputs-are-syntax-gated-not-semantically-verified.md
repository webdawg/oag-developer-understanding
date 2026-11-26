# 0188 — Listend IPFS inputs are syntax-gated, not semantically verified

Claim `B-0188`: at listend `b87dcac9a3c9e0059d90e698e2ec40fb2769ec41`,
CIDs and the configured API address are reduced to narrow ASCII forms before
they reach a request line. A CID is checked as a short token, not as an IPFS
multihash; an `https://` API address is refused rather than downgraded to
cleartext. The add-reply parser scans text for a Hash field and then applies the
same CID syntax check.

## Order of behavior

1. `validate_cid` accepts only a non-empty string of at most 128 bytes whose
   characters are ASCII alphanumeric, `-`, or `_`. Other bytes, including `/`,
   `?`, spaces, and non-ASCII, are rejected before a request line or response
   header is built.
2. `cat` calls `validate_cid` before formatting
   `POST /api/v0/cat?arg=<cid>`. `add` calls `validate_cid` on the CID extracted
   from the Kubo reply before returning it to the mirror recorder.
3. `split_api` trims the configured address and rejects any `https://` prefix.
   It strips an optional `http://`, takes everything before the first `/` as
   the TCP host, rejects an empty host, and ignores the configured path by
   always returning `/api/v0/add`.
4. `parse_add_response` lossily converts the reply, finds the first `"Hash"`
   substring, requires a colon and a quoted value, and returns that value. It
   is a small scanner, not a JSON parser; the subsequent CID check is what
   prevents header injection from a hostile reply.
5. Connect/write/read errors are `IpfsError::Connect`; malformed or oversized
   replies are `NotAdd`, `TooLarge`, or `ChunkedFraming`. Mirror callers record
   these without failing local audio acceptance.

## What is durable, rejected, and left behind

Durable: no request text or malformed CID is stored by this module. Rejected:
implausible CIDs, HTTPS configuration, empty hosts, non-add replies, and reply
size/framing violations. A refused mirror attempt leaves the already accepted
audio intact and records a failure outcome.

The syntax check proves only that a CID cannot alter the request line or
headers. It does not prove that the identifier is a real multihash, and the
add-reply scanner does not parse general JSON. No Kubo node or target test was
executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0188a | Implemented CID validation | `crates/oag-listend/src/ipfs.rs:261-275` |
| B-0188b | Implemented API address split | `crates/oag-listend/src/ipfs.rs:284-316` |
| B-0188c | Implemented add-reply extraction | `crates/oag-listend/src/ipfs.rs:318-334` |
| B-0188d | Implemented call sites | `crates/oag-listend/src/ipfs.rs:125-204`, `206-258` |
| B-0188e | Unchanged since explained commit | `git diff aad2d9b2..b87dcac9 -- crates/oag-listend/src/ipfs.rs` (only chunk-overflow change) |

Verification: source inspection via `git show origin/master:<path>` and a scoped
diff. No HTTP request or target test was executed.

## Change since the previously explained commit

The CID and API parsing rules are unchanged between
`aad2d9b2cc763239764fa8ba11ec7e871be00e11` and
`b87dcac9a3c9e0059d90e698e2ec40fb2769ec41`. Finding 0187 records the only
changed part of `ipfs.rs`: checked arithmetic in chunk decoding.

## Next investigation

Re-fetch on the next invocation, then trace `oag_listend::unix::UnixCarrier` at
the same head to document path handling and shared session rules.
