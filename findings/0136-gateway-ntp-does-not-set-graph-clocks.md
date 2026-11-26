# 0136 — Gateway NTP answers are separate from graph clocks

Claim `B-136`: at core `fb54e431332a030a566099c76fb2558084765422`, graph
freshness and local event timestamps come from the peer's own `SystemTime`.
The optional gateway NTP front-end can produce a verified time estimate for
outside NTP clients, but no code path feeds that estimate into
`GraphService::now`, event `created_at`, or corroboration freshness. This is a
confirmed non-connection inside the same repository.

## Two clocks, one direction only outward

1. `GraphService::now` calls `chrono_now`, which reads
   `SystemTime::now()`. Local graph methods pass `self.now()` into
   `commit_event` as `created_at`. `corroboration_for_edge` calls `self.now()`
   again and computes freshness with `freshness_from_age`; a timestamp in the
   future yields age zero and freshness `1.0`, never more.
2. The gateway's HTTP request/receipt clock (`transfer::now_unix`) is also
   `SystemTime` in seconds. It bounds gateway message skew; it is not set
   from an NTP estimate either.
3. The gateway NTP front-end is optional. `oag serve` starts it only when a
   listen address is configured, after `require_quorum_capable` verifies that
   enough query peers are configured to meet `quorum_min_agree`.
4. For each UDP request the front-end calls the same resolver: cache first;
   peer fan-out with quorum second; direct configured upstream third; relay
   last. A direct upstream call uses the full four-timestamp NTP exchange in
   `ntp_wire::query_upstream` with 5-second timeouts and rejects a response
   from any sender other than the addressed server. Peer answers get an
   RTT/2 adjustment; quorum selects the largest cluster within
   `ntp_tolerance_ms` and returns its median.
5. The front-end writes NTP wire responses from that verified estimate. If
   resolution fails it sends nothing: the source comment explicitly says it
   never substitutes the peer's own unverified system clock as a fallback.

## What is durable, rejected, and left behind

An NTP answer cached by the gateway can be served until its configured TTL;
for NTP the cache reconstructs elapsed time from the cached estimate rather
than returning a stale timestamp verbatim. A failed front-end resolution
leaves no UDP reply and no changed graph clock (Inferred from the code path;
no UDP listener was started). A skewed system clock still shapes locally
committed `created_at` values and freshness scores; there is no check in
`oag-graph` that consults a verified time source. Future assertion timestamps
are clamped for freshness, but they are not rejected.

Non-connection evidence: `git grep -n -w ntp origin/main -- crates/oag-graph`
returned no matches, and `git grep -n gateway origin/main -- crates/oag-graph`
returned only a comment in `pins.rs`. The graph crate imports neither the API
gateway nor the NTP wire module.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-136a | Implemented graph clock and freshness | `oag-graph/src/service.rs:150-175`; `oag-graph/src/corroboration.rs:169-176`, `344-349` |
| B-136b | Implemented gateway clock | `oag-api/src/transfer.rs:32-42` |
| B-136c | Implemented NTP resolution and front-end | `oag-api/src/gateway.rs:445-488`, `495-520`, `682-725`, `727-765`, `844-878`; `oag-cli/src/serve.rs:149-159` |
| B-136d | Implemented upstream wire exchange | `oag-api/src/ntp_wire.rs:120-160` |
| B-136e | Confirmed non-connection | `git grep -n -w ntp origin/main -- crates/oag-graph` (empty); `git grep -n gateway origin/main -- crates/oag-graph` (comment only) |

Verification: source inspection via `git show origin/main:<path>` at the stated
commit. No NTP server, client, gateway front-end, or graph score was run.

## Change since the previously explained commit

Comparing `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` with
`fb54e431332a030a566099c76fb2558084765422`, `ntp_wire.rs` is unchanged and the
gateway diff moves the HTTP-only IPv4 preference helper to the crawler crate.
The cited NTP resolver, quorum, front-end, `chrono_now`, and freshness lines
are unchanged. Findings 0131-0135 still hold at the newer commit.

## Next investigation

Trace `oag_api::gateway::compute_cache_ttl` and `adjust_for_elapsed` to document
exactly what a cached NTP answer returns during its TTL and what happens after
expiry.
