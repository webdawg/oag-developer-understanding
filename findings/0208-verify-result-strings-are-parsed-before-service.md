# 0208 — Verify-result strings are closed at the transport boundary

Claim `B-0208`: at core `fb54e431332a030a566099c76fb2558084765422`,
`VerifyResult` accepts exactly six snake_case strings. REST and MCP parse the
caller's string into that enum before calling `GraphService`, so an unknown
result is rejected as invalid input and never becomes a signed event or a
verification counter.

## Order of behavior

1. `VerifyResult::as_str`/`parse` define `confirmed`, `not_confirmed`, `changed`,
   `contradicted`, `unreachable`, and `unknown`. Parsing is exact; no case
   folding or whitespace trimming occurs here.
2. REST `verify_assertion` authenticates, parses the assertion ID, derives
   `observed_at` from the optional body string or the server clock, then parses
   `body.result`. An unparseable result returns `InvalidInput` with the accepted
   vocabulary. Only then does it call the service.
3. MCP `graph_verify_assertion` authenticates, parses the assertion ID, uses the
   current server time for `observed_at`, then parses `p.result`; failure is an
   MCP invalid-params error. It also calls the service only after parsing.
4. `GraphService::verify_assertion` receives the typed enum, writes
   `result.as_str()` into the `VerifyAssertion` payload, and commits the event.
   Projection stores it in the observations table.
5. Corroboration parses the stored string again with `VerifyResult::parse`
   before applying the fixed weights in finding 0207. An unparseable stored
   value is treated as neutral there.

## What is durable, rejected, and left behind

Durable after success: a signed verification event and an observation row whose
result string is one of the six canonical values. Rejected before the service:
bad keys, malformed IDs, malformed timestamps, and unknown result strings. None
of those increments `verification_jobs` (finding 0169), because the service
method is never reached.

The write boundary is strict; the read/scoring boundary is defensive. That
allows replicated data from other software versions to contain unknown strings
without a panic, while new local writes cannot create them through these two
surfaces. No verification request was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0208a | Implemented result vocabulary | `crates/oag-core/src/assertion.rs:78-115` |
| B-0208b | Implemented REST parsing order | `crates/oag-api/src/handlers.rs:211-231` |
| B-0208c | Implemented MCP parsing order | `crates/oag-mcp/src/server.rs:475-492` |
| B-0208d | Implemented service payload | `crates/oag-graph/src/assert.rs:250-282` |
| B-0208e | Implemented defensive score parse | `crates/oag-graph/src/corroboration.rs:128-142` |
| B-0208f | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-core/src/assertion.rs crates/oag-api/src/handlers.rs crates/oag-mcp/src/server.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No endpoint or verification event was executed.

## Change since the previously explained commit

The result vocabulary and parsing order are unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Finding 0207 records how accepted
results are scored; this finding records the write-side boundary that makes
unknown strings fail before a counter or event exists.

## Next investigation

Trace `oag_api::dto::parse_timestamp` and `now_or` to document accepted
timestamp forms, rejected forms, and what MCP does differently.
