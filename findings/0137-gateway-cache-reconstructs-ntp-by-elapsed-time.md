# 0137 — Gateway cache reconstructs NTP answers from elapsed time

Claim `B-137`: at core `fb54e431332a030a566099c76fb2558084765422`, the gateway
cache is an in-memory map keyed by service/target. Only quorum-verified
resolutions populate it. On an NTP cache hit the gateway does not re-query a
peer or upstream: it adds the locally measured elapsed time to the previously
verified millisecond estimate and returns that as the current answer.

## Order of behavior

1. `AppState::new` constructs a fresh `GatewayCache`, an `Arc<RwLock<HashMap<...>>>`.
   Keys are the literal `"ntp"` or `"http:<url>"`. There is no persistence
   layer in the shown constructor.
2. `resolve_gateway_query` checks `cache.get(service)` before any other
   resolution step. A hit is returned as `ServedFrom::Cache`.
3. `get` reads the entry, measures `entry.computed_at.elapsed()` with
   `std::time::Instant`, and treats a zero TTL or elapsed time at/after the TTL
   as a miss. It does not delete the expired entry; it simply returns `None`.
4. On a live NTP hit, `adjust_for_elapsed` adds `elapsed.as_millis()` to the
   stored `estimated_unix_time_ms`. HTTP results are cloned unchanged. The
   source comment describes the NTP value as an offset in disguise: verified
   time minus local wall clock at computation time, reconstructed by adding
   elapsed time.
5. After a miss, resolution follows cache -> peer quorum -> direct upstream ->
   relay. Only the quorum branch calls `cache.put`, using a TTL from
   `compute_cache_ttl`. For NTP that TTL is `ntp_cache_ttl_ms.max(0)`
   (default 2000 ms); `put` with a zero TTL stores nothing.
6. Direct-upstream and relay results are returned without a cache write. A
   failed quorum returns `NoQuorum` before any put. The front-end listeners
   separately refuse to start unless configured query peers could meet the
   quorum threshold.

## What is durable, rejected, and left behind

Nothing here is durable across a process restart: a new `AppState` gets a new
empty map (Inferred from the constructor; no restart was run). A zero TTL is
rejected at `put`, and an expired or zero-TTL entry is rejected at `get`. An
expired entry remains in the map until a later `put` overwrites it; the shown
`get` performs no eviction. The HTTP cache is keyed per raw URL, so distinct
URLs create distinct entries; no size cap is visible in this cache struct.

A cache hit adds monotonic elapsed time rather than asking the network again.
If the local wall clock is stepped during the TTL, the reconstructed estimate
follows elapsed time, not a fresh verification; the code contains no check for
such a step (Inferred from `Instant` elapsed plus the stored wall-clock
estimate). No NTP answer from this cache is written into graph event timestamps
or freshness (finding 0136).

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-137a | Implemented cache map and keys | `oag-api/src/gateway.rs:249-274`; `oag-api/src/state.rs:99`, `145-150` |
| B-137b | Implemented hit, expiry, and elapsed reconstruction | `oag-api/src/gateway.rs:276-309` |
| B-137c | Implemented TTL selection | `oag-api/src/gateway.rs:311-329`, `227-235` |
| B-137d | Implemented resolver precedence and quorum-only write | `oag-api/src/gateway.rs:445-481` |
| B-137e | Implemented front-end startup guard | `oag-cli/src/serve.rs:149-162`; `oag-api/src/gateway.rs:490-504` |

Verification: source inspection via `git show origin/main:<path>` at the stated
commit. No gateway request or cache operation was executed.

## Change since the previously explained commit

Comparing `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` with
`fb54e431332a030a566099c76fb2558084765422`, the cache, TTL, resolver, and
front-end guard lines cited here are unchanged. The gateway diff moves an
HTTP-only IPv4 pinning helper to `oag-crawler`; it does not alter NTP caching.
Findings 0131-0136 still hold at the newer commit.

## Next investigation

Trace `oag_crawler::fetch::resolve_and_validate`, `build_pinned_client`, and
`prefer_ipv4` to document the SSRF checks and address choice reused by the
gateway's HTTP upstream path.
