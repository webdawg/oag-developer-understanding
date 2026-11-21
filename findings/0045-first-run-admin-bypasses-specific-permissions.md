# 0045 — First run creates one admin key that bypasses specific permissions

Claim `B-045`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, `oag serve`
creates a bootstrap admin key only when `has_any_actor` is false. The key
belongs to a keyless service actor named `admin` and carries only the `admin`
permission. `AuthContext::require` treats `admin` as satisfying every specific
permission check.

## Permission inventory

The parsed permissions are `graph:read`, `graph:assert`, `graph:verify`,
`graph:retract-own`, `graph:crawl`, and `admin`. Unknown permission strings are
dropped by `Permission::parse`, including during key projection. Thus a stored
unknown permission does not become authority.

The bootstrap actor is declared without a public-key proof, so finding 0044's
event-scoped actor-ID rule applies. A later empty database creates another
first-run actor and key; an existing actor suppresses bootstrap. The raw key is
printed to standard output and the comment says it is not stored. No file,
terminal scrollback, or process-output retention guarantee is implemented.

This is a local startup path, not a network enrollment protocol. It does not
establish who can access the data directory or stdout where the key appears.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-045a | Implemented | `crates/oag-cli/src/serve.rs:38-42` and `272-287` |
| B-045b | Implemented | `crates/oag-core/src/actor.rs:75-115` |
| B-045c | Implemented admin bypass | `crates/oag-graph/src/service.rs:135-141` |

Verification: source inspection only. No server was started.

## Next investigation

Trace `graph:crawl` request handling and its SSRF or private-network guard before describing crawl permission as sufficient protection.