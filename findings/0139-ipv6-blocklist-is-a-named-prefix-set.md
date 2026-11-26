# 0139 — The IPv6 SSRF blocklist is an explicit prefix set

Claim `B-139`: at core `fb54e431332a030a566099c76fb2558084765422`,
`is_blocked_v6` blocks a specific list of IPv6 forms: IPv4-mapped addresses
(delegated to the IPv4 rules), loopback, unspecified, multicast, unique-local
`fc00::/7`, and link-local `fe80::/10`. It does not contain explicit branches
for the IPv6 documentation prefix `2001:db8::/32`, 6to4 `2002::/16`, Teredo
`2001::/32`, the discard-only prefix `100::/64`, or IPv4-compatible
`::a.b.c.d` addresses. This refines, not reverses, finding 0046's warning that
the guard is not a completed SSRF certification.

## Order of behavior

1. `resolve_and_validate` resolves the hostname and, unless
   `allow_private_networks` is true, calls `is_blocked_ip` on every returned
   address. A true result rejects the fetch before a client is built.
2. `is_blocked_ip` dispatches on address family. IPv6 addresses first pass
   through `to_ipv4_mapped`; a mapped address is evaluated by `is_blocked_v4`.
3. `is_blocked_v6` then tests, in order, `is_loopback()`, `is_unspecified()`,
   `is_multicast()`, `(segments[0] & 0xfe00) == 0xfc00`, and
   `(segments[0] & 0xffc0) == 0xfe80`. Any other IPv6 value is returned as not
   blocked. There is no generic "is globally routable" predicate here.
4. The unit tests printed cover loopback, RFC1918, cloud metadata, ULA,
   link-local, mapped private addresses, three public examples, and multicast.
   They do not assert any of the prefixes named in the claim above. The tests
   were inspected, not executed.

## What is durable, rejected, and left behind

Rejected: any address matching the named predicates, which makes the whole
resolve step fail with `BlockedAddress` (or gateway `UpstreamBlocked`). No
connection is attempted for that fetch. Allowed by this predicate: values that
do not match the named forms. Whether a transitional or documentation address
can actually reach a private host in a given deployment depends on OS and
network behavior that this repository does not model, so that reachability is
Unknown. The code does not probe it and does not file a runtime error.

The configuration flag `allow_private_networks` bypasses the entire IP check,
as documented in finding 0046. `prefer_ipv4` and single-address pinning (finding
0138) happen only after validation succeeds; they do not add another IP check.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-139a | Implemented predicate | `oag-crawler/src/ssrf.rs:1-48` |
| B-139b | Implemented caller | `oag-crawler/src/fetch.rs:49-85` |
| B-139c | Test inspection, not executed | `oag-crawler/src/ssrf.rs:50-101` |
| B-139d | Compared unchanged file | `git diff 87f9e8c..fb54e43 -- crates/oag-crawler/src/ssrf.rs` (no output) |

Verification: source and test inspection only. No DNS resolution, network
request, or target test was executed.

## Change since the previously explained commit

`ssrf.rs` is unchanged between `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Finding 0046's characterization of
the guard at the older commit therefore still describes the same predicate at
the newer commit. Findings 0131-0138 still hold at the newer commit.

## Next investigation

Trace `oag_crawler::fetch::safe_fetch` after the network guard: determine how
`Content-Type` is normalized, which body sizes are accepted, and where the
BLAKE3 content hash goes.
