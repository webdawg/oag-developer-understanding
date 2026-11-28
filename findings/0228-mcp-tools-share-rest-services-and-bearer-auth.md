# 0228 — MCP tools share REST services and bearer authentication

Claim `B-0228`: at core `fb54e431332a030a566099c76fb2558084765422`,
`oag_mcp::streamable_http_service` creates an MCP service whose session factory
clones the same `Arc<GraphService>`, embedding provider, and crawler used by
REST. Tools authenticate through `Authorization: Bearer <key>` and are wrapped
in a uniform `mcp_tool` span.

## Order of behavior

1. `streamable_http_service` constructs a `StreamableHttpService` with
   `LocalSessionManager::default()` and `StreamableHttpServerConfig::default()`.
2. Its factory calls `OagMcpServer::new` with clones of the shared service arcs
   for every session, so MCP calls reach the same projection, rate limits, and
   state as REST handlers.
3. `extract_bearer` requires the `Authorization` header with a `Bearer ` prefix.
   A missing header is an MCP invalid-params error; the human UI's `?key=`
   convention is not used here.
4. `authenticate` passes the key to `GraphService::authenticate` and records the
   resolved actor ID on the current span. `authenticate_read` additionally
   requires `graph:read`.
5. `traced` wraps every tool in an `mcp_tool` span carrying tool name and peer
   ID, then logs `duration_ms` and `ok`/`error` result. The module's `map_err`
   converts graph and crawl errors into MCP error data.

## What is durable, rejected, and left behind

Durable: no MCP-specific state is written; mutations go through `GraphService`.
Rejected: missing bearer key, invalid key, missing permission, invalid params,
and service errors as mapped by `map_err`. Failed tool calls still produce a
completion log with `result = "error"`.

Session management and streamable-HTTP defaults come from the external `rmcp`
types; this module does not configure them further. No MCP server or tool call
was started.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0228a | Implemented MCP session factory | `crates/oag-mcp/src/transport.rs:1-26` |
| B-0228b | Implemented bearer auth | `crates/oag-mcp/src/server.rs:45-52`, `87-102` |
| B-0228c | Implemented tool span wrapper | `crates/oag-mcp/src/server.rs:104-130` |
| B-0228d | Implemented error mapping | `crates/oag-mcp/src/server.rs:15-43` |
| B-0228e | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-mcp/src/transport.rs crates/oag-mcp/src/server.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No MCP server or tool call was executed.

## Change since the previously explained commit

MCP transport and tool wrapping are unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Findings 0197 and 0199 describe
specific MCP routes and REST logging; this finding records the shared service
and logging boundary for all tools.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining gap from
the journal and revision table.
