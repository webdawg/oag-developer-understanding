# 0138 — HTTP fetches validate every DNS address, then pin one

Claim `B-138`: at core `fb54e431332a030a566099c76fb2558084765422`, crawler and
gateway HTTP fetches resolve the host themselves, reject the whole set if any
resolved address is blocked, reduce the set with an IPv4 preference, and pin
the connection to exactly the first remaining address. There is no automatic
second address if that pinned connection fails. The gateway reuses the
crawler's helpers rather than implementing a weaker SSRF guard, but deliberately
omits the crawler's content-type allowlist.

## Order of behavior

1. `resolve_and_validate` calls `lookup_host((host, port))`, returns
   `NoAddresses` on an empty result, and — unless `allow_private_networks` is
   set — checks every returned IP with `is_blocked_ip`. One blocked address
   rejects the fetch before a client is built.
2. `is_blocked_ip` rejects IPv4 loopback, private, link-local, unspecified,
   broadcast, documentation, multicast, and `0.x` addresses. It maps IPv4
   addresses embedded in IPv6 back to the IPv4 rules, and rejects IPv6 loopback,
   unspecified, multicast, unique-local `fc00::/7`, and link-local `fe80::/10`.
3. `prefer_ipv4` returns the first IPv4 address when one exists and otherwise
   leaves the set untouched. `build_pinned_client` then pins only
   `addrs.first()` through `reqwest`'s `resolve`. The URL, `Host` header, SNI,
   and certificate name still use the original hostname; only the socket target
   is fixed. Redirect following is disabled in the client.
4. `safe_fetch` handles redirects manually, repeating scheme, host, resolve,
   validate, prefer, and pin steps for each hop up to `MAX_REDIRECTS` (5). It
   applies the crawler's content-type allowlist and streamed response cap.
5. `fetch_upstream_http` in the gateway performs the same resolve/validate/
   prefer/pin sequence with a 15-second timeout and gateway user agent, but no
   content-type allowlist. It follows redirects manually up to its own cap,
   joins `Location` against the current URL, checks `Content-Length`, and caps
   the streamed body while reading. It hashes the final body with BLAKE3.

## What is durable, rejected, and left behind

Rejected: unsupported schemes, missing host/port, empty DNS results, any
blocked address when private networking is not enabled, too many redirects, a
redirect without `Location`, and a body over the configured cap. Failures in
the gateway path become `GatewayError::UpstreamBlocked`; the crawler returns a
`CrawlError`. No partial response body is returned from the gateway path: the
body is accumulated in memory and the size check runs during accumulation.

There is no fallback among resolved addresses after pinning. `build_pinned_client`
pins exactly one address; if it is unusable, the request fails. `prefer_ipv4`
makes the common dual-stack case deterministic but does not probe reachability.
The source comments describe a real dual-stack failure under the older
last-address-wins behavior; those measurements were not reproduced here.

## Change since the previously explained commit

This mechanism changed between `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. At the older commit,
`build_pinned_client` looped over the whole address set and reqwest's `resolve`
kept the last one. At the newer commit it pins only the first address, the new
`prefer_ipv4` helper is called by both `safe_fetch` and gateway
`fetch_upstream_http`, and tests were added for the first-address behavior.
The tests were read, not executed. `resolve_and_validate` and `ssrf.rs` are
unchanged. Findings 0131-0137 still hold at the newer commit.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-138a | Implemented resolve and validate | `oag-crawler/src/fetch.rs:49-85`; `oag-crawler/src/ssrf.rs:3-48` |
| B-138b | Implemented single-address pin | `oag-crawler/src/fetch.rs:87-125` |
| B-138c | Implemented crawler redirect path | `oag-crawler/src/fetch.rs:127-146` |
| B-138d | Implemented gateway reuse | `oag-api/src/gateway.rs:537-616` |
| B-138e | Compared change | `git diff 87f9e8c..fb54e43 -- crates/oag-crawler/src/fetch.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No fetch, resolver call, or target test was executed.

## Next investigation

Trace `oag_crawler::ssrf::is_blocked_v6` against transitional IPv6 address
forms to determine which non-global IPv6 ranges the current predicate does not
name explicitly.
