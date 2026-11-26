# 0199 — REST logging is a span plus one completion event

Claim `B-0199`: at core `fb54e431332a030a566099c76fb2558084765422`, every REST
request gets an `http_request` info span with a process-local request ID, peer
ID, path, method, and initially empty actor/status fields. Authentication fills
`actor_id`; response completion fills `status` and emits a separate info event
with `duration_ms` and an `ok`/`error` result.

## Order of behavior

1. The router installs `TraceLayer` with `ApiMakeSpan::new(peer_id)`, the API
   latency middleware, the rate limiter, and a request body limit.
2. `make_span` allocates `request_id` as `<pid>-<monotonic counter>` using a
   relaxed atomic. It is unique within one running process, not across peers or
   restarts.
3. The span records `peer_id`, `route = request.uri().path()`, and `method`.
   The URI path excludes the query string. `actor_id` and `status` start empty.
4. `auth::authenticate` validates `Authorization: Bearer <key>` and records the
   resolved `actor_id` on the current span. A request that fails before or
   during authentication leaves that field empty.
5. `on_response` records the numeric HTTP status on the span, then emits a
   separate `request completed` info event carrying `duration_ms` and
   `result = "ok"` for any 2xx status, otherwise `"error"`.
6. The module scope explicitly excludes per-event fields, MCP request spans,
   and query-string values. Those are documented deferrals, not hidden fields.

## What is durable, rejected, and left behind

Durable: no log table is written here; these are `tracing` events whose
destination is configured elsewhere. Rejected requests still get a span,
status, duration, and error result; failed authentication simply lacks an
actor ID. A redirect or 3xx is classified as `error` because the code checks
`status.is_success()`, not specifically 4xx/5xx.

The completion event is separate from the span, so a log consumer needs the
span context to associate `duration_ms`/`result` with `request_id`, `route`,
and `actor_id`. No HTTP request or log sink was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0199a | Implemented span factory and completion event | `crates/oag-api/src/logging.rs:1-69` |
| B-0199b | Implemented actor recording | `crates/oag-api/src/auth.rs:7-23` |
| B-0199c | Implemented router layers | `crates/oag-api/src/lib.rs:120-140` |
| B-0199d | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-api/src/logging.rs` (no output) |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No request or tracing subscriber was run.

## Change since the previously explained commit

The logging module is unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Finding 0016 recorded the path-only
field choice at the earlier commit; this finding describes the full span and
completion-event shape still present at the newer one.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining gap from
the journal and revision table.
