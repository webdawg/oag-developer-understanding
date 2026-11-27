# 0209 — REST timestamps are RFC3339 strings converted to seconds

Claim `B-0209`: at core `fb54e431332a030a566099c76fb2558084765422`, REST
accepts optional RFC3339 timestamp strings and converts them to Unix seconds
with `chrono`. A malformed string is rejected before service commit. Missing
timestamps remain absent for assertions/evidence, but verification substitutes
the server clock. MCP verification always uses the server clock and exposes no
timestamp parameter.

## Order of behavior

1. `parse_timestamp` calls `DateTime::parse_from_rfc3339` and returns
   `.timestamp()` as `i64`. Sub-second precision is discarded by that conversion.
2. `EvidenceRequest::into_input` parses `observed_at` and `retrieved_at` when
   each is present. `None` stays `None`; no server time is substituted for
   evidence metadata.
3. `AssertRequest::into_input` parses its optional `observed_at` the same way.
4. `now_or`, used by the REST verification handler, parses a supplied
   `observed_at`; when absent it reads `SystemTime::now()` in seconds.
5. MCP `graph_verify_assertion` has no timestamp parameter. It reads
   `SystemTime::now()` itself and passes that value to the same service method.
6. A parse error becomes `GraphError::InvalidInput` with the original string in
   the message. Because parsing occurs in the handler, no event is committed
   and the verification counter is not incremented.

## What is durable, rejected, and left behind

Durable after success: integer seconds stored in the signed event payload and
later projected into assertions, evidence, or observations. Rejected: a string
that chrono does not accept as RFC3339. There is no clock-skew check here; a
valid future timestamp is accepted and may later score as maximally fresh
because freshness clamps negative age to zero (finding 0170).

The two surfaces differ: REST callers can supply observation time; MCP callers
cannot. That difference is in the transport adapters, not `GraphService`, which
always receives an `i64`. No request was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0209a | Implemented RFC3339 parser | `crates/oag-api/src/dto.rs:7-11` |
| B-0209b | Implemented evidence/assert parsing | `crates/oag-api/src/dto.rs:32-45`, `88-99` |
| B-0209c | Implemented verify default | `crates/oag-api/src/dto.rs:179-187`; `crates/oag-api/src/handlers.rs:211-231` |
| B-0209d | Implemented MCP clock source | `crates/oag-mcp/src/server.rs:475-492` |
| B-0209e | Freshness clamp comparison | `crates/oag-graph/src/corroboration.rs:169-176` |
| B-0209f | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-api/src/dto.rs crates/oag-api/src/handlers.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No HTTP request or event was executed.

## Change since the previously explained commit

The timestamp parsing code is unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Finding 0169 records which rejected
verification attempts reach the counter; this finding records the earlier
timestamp parse that rejects a request before that point.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining gap from
the journal and revision table.
