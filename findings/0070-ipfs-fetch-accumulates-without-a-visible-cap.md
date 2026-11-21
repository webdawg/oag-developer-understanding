# 0070 — Inspected IPFS fetch implementations accumulate the full CID

Claim `B-070`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, both inspected
IPFS `fetch` implementations return a `Vec<u8>` containing every received chunk.
Neither function checks a maximum length before extending that vector.

## Providers

The Kubo-compatible provider posts the CID to `/api/v0/cat`, optionally adds a
bearer API key, requires HTTP success, and calls `response.bytes()`. The
embedded provider parses the CID as an IPFS path, cats it, and appends every
stream chunk. A disabled provider returns an error instead of fetching. No
timeout or size option is visible in these two functions; a client-wide timeout
may exist outside them and was not established.

Thus finding 0069 is not rescued by an obvious cap in the inspected provider
implementations. A CID that resolves to a very large UnixFS object can make the
transfer handler hash and return a very large body. That cost was not measured,
and provider configuration may still impose limits not visible in these
functions.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-070a | Implemented | `crates/oag-ipfs/src/provider.rs:122-131` |
| B-070b | Implemented | `crates/oag-ipfs/src/embedded.rs:109-117` |

Verification: source inspection only. No IPFS node was contacted.

## Next investigation

Trace the HTTP client builder used by the Kubo provider for timeout and redirect behavior, then determine whether transfer requests can trigger outbound fetches to an operator-configured but unauthenticated IPFS endpoint.