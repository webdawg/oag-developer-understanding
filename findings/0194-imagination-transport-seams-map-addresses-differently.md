# 0194 — Imagination transport seams reinterpret the address field

Claim `B-0194`: at imagination `73fadb3ccdc6249fb21d0410e1b5a794be70fe40`,
the `Transport` trait's `address` is not a uniform endpoint. TCP treats it as
`host:port`, the proxy carrier as a CONNECT target, HTTP as a base URL, IPFS
read as a CID, and IPFS write ignores it. Each adaptation collapses its own
failure modes into `io::Error` or `None`.

## Order of behavior

1. `TcpTransport::send` connects to `address`, writes the framed JSON message,
   and reads one framed reply.
2. `ProxiedTransport::send` strips leading `http://`/`https://` from the target,
   connects to the configured proxy, writes `CONNECT <target> HTTP/1.1`, reads
   one 1024-byte buffer, and requires the reply to start with `HTTP/1.0 200` or
   `HTTP/1.1 200`. On success it runs the ordinary framed exchange over the
   tunnel. No timeout or credential handling is shown.
3. `HttpIpfsPublisher::publish` serializes the whole Message to JSON, posts it
   as a multipart `file` named `message` to `<api>/api/v0/add`, requires a 2xx
   status, parses the JSON reply, and returns its `Hash` string. Serialization,
   network, status, parse, and missing-Hash failures all become `None`.
4. `PublishingIpfsTransport` ignores its address, publishes the message, and
   for `Message::Request` sets `answer = {"cid": <cid>}` on a clone. Other
   message variants are returned unchanged with no answer field. Publication
   failure becomes an `io::Error`.
5. `IpfsTransport` treats the address as a CID, calls the injected `CidFetcher`,
   and parses fetched bytes as a `Message`. Fetch failure becomes
   `ErrorKind::NotFound`; invalid JSON becomes `InvalidData`.
6. `HttpTransport` posts the Message as JSON to
   `<address>/oag-imagination/v1/message`, requires a success status, and parses
   the reply as JSON; otherwise it returns an `io::Error`.

## What is durable, rejected, and left behind

Durable: these carriers store nothing themselves. IPFS publication delegates
persistence to the configured publisher; IPFS read delegates retrieval to the
fetcher. Rejected: non-200 CONNECT replies, non-2xx HTTP/IPFS replies, missing
or malformed JSON fields, publish failures, and fetch failures. Each is
represented by the seam's coarse error type rather than a typed carrier error.

No carrier authenticates a peer or validates that a CID's bytes correspond to
the identifier. The proxy carrier reads only one response buffer before
deciding whether CONNECT succeeded, and no timeout is applied to that read in
the shown code. Tests inspected cover the seams but were not run.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0194a | Implemented proxy and IPFS seams | `crates/oag-imagination/src/socket.rs:148-321` |
| B-0194b | Implemented HTTP carrier | `crates/oag-imagination/src/socket.rs:323-360` |
| B-0194c | Implemented base transport seam | `crates/oag-imagination/src/socket.rs:85-123` |
| B-0194d | Unchanged since explained commit | `git diff 7b7dcb8e..73fadb3c -- crates/oag-imagination/src/socket.rs` (no output) |

Verification: source inspection via `git show origin/master:<path>` and a scoped
diff. No network carrier, proxy, or IPFS node was executed.

## Change since the previously explained commit

The carrier code is unchanged between
`7b7dcb8eae70b2df2fa1329fdb7b2dd928e76d29` and
`73fadb3ccdc6249fb21d0410e1b5a794be70fe40`. Findings 0155 and 0156 describe
the URL resolver and Reticulum carrier; this finding documents the remaining
TCP, proxy, HTTP, and IPFS transport seams.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining gap from
the journal and revision table.
