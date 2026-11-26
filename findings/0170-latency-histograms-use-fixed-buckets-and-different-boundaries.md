# 0170 — Latency histograms use fixed buckets and different boundaries

Claim `B-0170`: at core `fb54e431332a030a566099c76fb2558084765422`, `api_latency`
and `search_latency` share one fixed-bucket histogram implementation, but they
observe different spans. API latency is recorded for every middleware response,
including errors; search latency is recorded only after a keyword or semantic
search succeeds, and starts after pool acquisition.

## Order of behavior

1. `LatencyHistogram::new` allocates 13 atomic counters: one per upper bound in
   `LATENCY_BUCKETS_MS` (1, 5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000,
   10000) plus `+Inf`. `record(ms)` clamps negative values to zero, increments
   the first bucket whose upper bound is at least `ms`, adds `(ms * 1000) as u64`
   microseconds to the sum, and increments count.
2. `snapshot()` converts per-bucket atomics into cumulative counts, ending with
   `+Inf`, and exposes `sum_ms` and `count`. `mean_ms` is sum/count or zero;
   `quantile_ms` returns the first cumulative bucket at or above the target and
   reports that bucket's finite upper bound, even for the `+Inf` bucket.
3. `api_latency_middleware` starts an `Instant` before `next.run(request)`,
   records `elapsed * 1000` after the response value is returned, and forwards
   the response unchanged. Errors are recorded because there is no status
   filter. It is installed on the API router as a layer.
4. `GraphService::search`, `search_page`, and `semantic_search` start their
   timer after argument sanitization and SQLite pool acquisition, immediately
   before the query/embedding-backed work. They call `record` only after the
   `?` on that work succeeds. Failed searches and pool waits are not recorded.
   Semantic search includes provider calls because the timer covers the whole
   ranked-result loop.
5. `metrics_snapshot` carries `search_latency`; the API handler separately
   passes `state.api_latency.snapshot()`. The renderer emits both as Prometheus
   `_bucket`, `_sum`, and `_count` families with millisecond HELP text.

## What is durable, rejected, and left behind

Durable: neither histogram is persisted; both are process-lifetime and reset on
restart. A rejected search leaves no `search_latency` observation, so that
histogram describes successful search work only. A failed REST request still
leaves an `api_latency` observation. The middleware records when the `Response`
is produced; the shown code does not await body transmission afterward.

The API HELP text says "including ... response", while the measured span is the
handler/middleware future returning a `Response` value. Fixed bucket bounds are
not configurable, so scrapes remain comparable; they also mean quantiles are
bucket-boundary approximations rather than exact timings. No server, search, or
metrics scrape was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0170a | Implemented shared histogram | `crates/oag-graph/src/latency.rs:23-132` |
| B-0170b | Implemented API middleware and router layer | `crates/oag-api/src/latency.rs:1-33`; `crates/oag-api/src/lib.rs:124-138` |
| B-0170c | Implemented search observation points | `crates/oag-graph/src/search.rs:58-68`, `130-139`; `crates/oag-graph/src/semantic_search.rs:108-116` |
| B-0170d | Implemented snapshot and rendering | `crates/oag-graph/src/metrics.rs:48-67`; `crates/oag-api/src/metrics.rs:20-44`, `189-224` |
| B-0170e | New since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-graph/src/latency.rs crates/oag-api/src/latency.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No metrics endpoint or search was run.

## Change since the previously explained commit

The two latency modules, their fields on `GraphService`/`AppState`, the search
observation calls, and the `/metrics` histogram families are new at
`fb54e431...` relative to explained `87f9e8c1...`. Finding 0169 records the
verification counters added in the same change; this finding covers duration
measurement.

## Next investigation

Trace `oag_storage::repo::stats::events_pending_chain` to document what counts
as a missing predecessor, what value means a complete local chain, and whether
a fork changes the metric.
