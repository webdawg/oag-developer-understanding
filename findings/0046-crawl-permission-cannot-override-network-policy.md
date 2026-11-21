# 0046 — Crawl permission does not let a request override network policy

Claim `B-046`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
`POST /api/v1/crawl` requires `graph:crawl` or `admin` and accepts only a URL.
The request has no field that enables private-network access. Default fetching
rejects selected loopback, private, link-local, multicast, documentation, and
IPv6-mapped equivalents before connecting.

## Boundary

`resolve_and_validate` resolves the host and checks every returned address when
`allow_private_networks` is false. `safe_fetch` repeats that validation on every
manual redirect hop and pins the HTTP client to the validated addresses. A
blocked address becomes `BlockedAddress`, which the API maps to HTTP 403.

This is an implemented guard, not a completed SSRF certification. It does not
prove protection against DNS rebinding after the pinned connection, proxy
evasion, non-IP targets, or every address Rust classifies outside these helper
checks. The configuration can disable the guard. Tests exist for representative
blocked addresses but were not executed.

An admin key from finding 0045 can pass the permission check because admin
bypasses specific permissions, but it still cannot override the server's crawl
configuration through this request.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-046a | Implemented | `crates/oag-api/src/crawl.rs:1-8` and `74-86` |
| B-046b | Implemented | `crates/oag-crawler/src/fetch.rs:68-89` and `104-122` |
| B-046c | Implemented and test intent | `crates/oag-crawler/src/ssrf.rs:8-75` |

Verification: source and test inspection only. No crawl request or network test was run.

## Next investigation

Trace robots and content-type handling to determine what a permitted crawl fetches, stores, and refuses after the network guard succeeds.