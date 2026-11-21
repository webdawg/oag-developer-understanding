# 0059 — MCP tools reuse REST bearer authentication and service permissions

Claim `B-059`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, inspected MCP
tools authenticate `Authorization: Bearer` through `GraphService::authenticate`.
Read tools additionally require `graph:read`. Writes pass the resulting
`AuthContext` into the same graph service methods used by REST, and crawl
explicitly requires `graph:crawl`.

## Shared gate

`extract_bearer` rejects a missing or malformed header. `authenticate` hashes
and looks up the key through the graph service, so revoked keys fail in the
same way as REST. `graph_assert` then calls `GraphService::assert`, which
requires `graph:assert` or admin. `graph_crawl` checks `graph:crawl` before
calling the crawler. `graph_redact_evidence` passes the context to
`redact_evidence`, whose service implementation requires admin.

The tool description also states that evidence redaction does not alter the
signed event, matching finding 0056. MCP therefore does not bypass the
authorization model, although the triggering caller's identity is still
distinct from the crawler's internal assertion actor established in finding
0048.

This pass inspected the shared helpers and representative tools, not every tool
body. A tool that authenticated but forgot to pass the context into a
permission-checking service would be a separate defect; no such inspected
example was found.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-059a | Implemented | `crates/oag-mcp/src/server.rs:46-101` |
| B-059b | Implemented | `crates/oag-mcp/src/server.rs:365-380`, `516-545` |

Verification: source inspection only. MCP tests were not executed.

## Next investigation

Trace listend's serving route and determine whether retrieved audio requires authentication or is content-addressed public retrieval.