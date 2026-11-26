# 0169 — Verification counters count service attempts, not every rejection

Claim `B-0169`: at core `fb54e431332a030a566099c76fb2558084765422`,
`verification_jobs` increments once for every call that reaches
`GraphService::verify_assertion`, and `verification_failures` increments when
that call returns `Err`. The count includes a missing `graph:verify` permission
and a failed event commit. It does **not** include REST/MCP rejections that
happen before the service method, including malformed IDs, unknown result
strings, bad API keys, and bad timestamps. The `/metrics` help text is broader
than the measured boundary.

## Order of behavior

1. `GraphService::new` creates two process-lifetime `AtomicU64`s wrapped in
   `Arc`s. `verification_counters()` can hand those same `Arc`s to another
   caller; the graph metrics snapshot reads the instance it belongs to.
2. `verify_assertion` wraps `auth.require(Permission::GraphVerify)` and the
   `commit_event` call in one async block, awaits it, calls
   `record_verification(outcome.is_ok())`, then returns the outcome.
3. `record_verification` increments `verification_jobs` unconditionally with
   relaxed ordering and increments `verification_failures` only when `ok` is
   false.
4. `metrics_snapshot` copies both atomics into `MetricsSnapshot` next to the
   SQL-derived counts. The API `/metrics` handler calls that snapshot on
   `state.graph` and renders `verification_jobs` and `verification_failures` as
   Prometheus-style counters.
5. REST parsing happens earlier: `authenticate`, `parse_assertion_id`,
   `now_or(body.observed_at)`, and `VerifyResult::parse` all run before
   `graph.verify_assertion`. MCP likewise authenticates, parses the ID, reads
   the clock, and parses the result before calling the service. Those rejections
   never reach `record_verification`.

## What is durable, rejected, and left behind

Durable: counts live only in process memory and reset on restart; they are not
derived from the event log and are not persisted. A successful verification
commits a `VerifyAssertion` event and observation row; a counted failure leaves
no such event, only the incremented failure counter. A permission failure inside
the service is counted, while a bad API key or missing `graph:read` at
`authenticate` is not.

The field comment says failures are "bad assertion id, bad result string,
missing permission", and the `/metrics` HELP text repeats that. The inspected
call sites show the first two are normally rejected by transport parsers before
the service method; the service can still fail on a missing target assertion
during projection or a storage error. This finding records that mismatch rather
than rewriting the help text. No endpoint, counter read, or target test was
executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0169a | Implemented counters and recording | `crates/oag-graph/src/service.rs:97-106`, `113-123`, `129-148` |
| B-0169b | Implemented service boundary | `crates/oag-graph/src/assert.rs:250-282` |
| B-0169c | Implemented snapshot and rendering | `crates/oag-graph/src/metrics.rs:30-38`, `48-67`; `crates/oag-api/src/metrics.rs:20-44`, `141-154` |
| B-0169d | Implemented pre-service parsing | `crates/oag-api/src/handlers.rs:211-230`; `crates/oag-mcp/src/server.rs:475-491` |
| B-0169e | Documented intent that is broader than B-0169d | `crates/oag-graph/src/service.rs:101-104`; `crates/oag-api/src/metrics.rs:151` |
| B-0169f | Shared service instance in `serve` | `crates/oag-cli/src/serve.rs:105` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No metrics scrape or verification request was executed.

## Change since the previously explained commit

At `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, `verify_assertion` committed
directly without these counters. At `fb54e431...`, the two atomics,
`record_verification`, the snapshot fields, and the `/metrics` lines are added.
Finding 0147's description of LLM verification candidates still holds; this
finding records the new measurement boundary.

## Next investigation

Trace `oag_graph::latency::LatencyHistogram` and the API latency middleware to
document what the new `search_latency` and `api_latency` histograms actually
sample, clamp, and expose.
