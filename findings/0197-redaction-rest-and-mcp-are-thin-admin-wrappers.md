# 0197 — Redaction REST and MCP surfaces add no business logic

Claim `B-0197`: at core `fb54e431332a030a566099c76fb2558084765422`, both REST
and MCP expose the same five redaction operations by authenticating the caller,
parsing IDs, and delegating to `GraphService`. `Permission::Admin` is enforced
inside the service, not separately in each handler. The audit view combines
evidence tombstones, suppressed nodes, and actor-identity tombstones.

## Order of behavior

1. REST registers five routes: redact evidence, list redactions, suppress node,
   unsuppress node, and redact actor identity. MCP exposes corresponding tools
   with the same delegate calls.
2. Every handler calls `authenticate`/`self.authenticate` first. REST parses
   path IDs into typed IDs; MCP parses string parameters and maps failures to
   invalid params. Evidence/actor redaction bodies carry only an optional
   `reason`.
3. The handlers call `redact_evidence`, `redact_actor_identity_uri`,
   `suppress_node_from_search`, or `unsuppress_node_from_search`. Successful
   mutations return `{"status":"accepted"}`; no handler performs its own
   redaction or suppression work.
4. Both list views call `list_redactions`, `list_suppressed_nodes`, and
   `list_actor_redactions`, then return the same three-key JSON object.
5. REST maps `InvalidInput` to 400, permission failures to 403, bad keys to 401,
   and `AlreadyRedacted`/`ActorAlreadyRedacted` to 409. MCP maps service errors
   through `map_err`.

## What is durable, rejected, and left behind

Durable changes are made by the service: blanked evidence/actor fields,
tombstones, and suppression rows. The handlers are stateless adapters. A
repeated evidence or actor redaction is rejected as a conflict rather than
silently reported as a fresh success; node suppression is idempotent.

These endpoints are local to this peer: the module description and finding
0056 record that the signed event log and other peers are untouched by
redaction. An admin API key is required, but that only authorizes the local
operation; it does not retract replicated copies. No REST or MCP request was
executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0197a | Implemented REST handlers | `crates/oag-api/src/redaction.rs:1-88` |
| B-0197b | Implemented REST routes | `crates/oag-api/src/lib.rs:91-107` |
| B-0197c | Implemented MCP tools | `crates/oag-mcp/src/server.rs:594-677` |
| B-0197d | Implemented status mapping | `crates/oag-api/src/error.rs:15-42` |
| B-0197e | Shared reason body | `crates/oag-api/src/dto.rs:123-130` |
| B-0197f | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-api/src/redaction.rs` (no output) |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No endpoint or target test was executed.

## Change since the previously explained commit

The REST redaction module and routes are unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Findings 0056 and 0057 describe
the service operations; this finding documents their authentication, parsing,
and response adapters.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining gap from
the journal and revision table.
