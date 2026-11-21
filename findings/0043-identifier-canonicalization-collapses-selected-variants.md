# 0043 — Identifier canonicalization collapses only selected variants

Claim `B-043`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, assertion
inputs pass through `canonicalize_value` before signing. HTTP(S) URLs receive
URL normalization and a `url:` prefix. Existing scheme-like strings pass through
lowercased. Other text becomes a hyphenated `concept:` slug.

## Convergence rules

For HTTP(S), parsing lowercases scheme and host, removes listed tracking
parameters, drops an empty fragment, and removes an empty query. Non-empty
fragments remain. The implementation comment and tests show that
`https://Example.com/Path?utm_source=x` becomes
`url:https://example.com/Path`. Query order, encoding, default ports, and
trailing-slash behavior were not exhaustively tested; only the parser's
documented behavior and this implementation were inspected.

A string such as `concept:Model` passes through lowercased rather than being
parsed as a URL. Bare text such as `Model Context Protocol` becomes
`concept:model-context-protocol`. Repeated whitespace converges in the slug
tests. A UUID identifier generator exists, but this assertion path does not call
it.

These rules determine the node ID because the ID is derived from the canonical
string. Two visibly different request strings can therefore become one signed
subject or object, while two semantically similar strings can remain distinct
when their differences are outside the implemented normalization.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-043a | Implemented | `crates/oag-graph/src/identifier.rs:11-39` |
| B-043b | Implemented and test intent | `crates/oag-core/src/canonicalize.rs:34-74`; tests at `identifier.rs:46-65` were not executed |

Verification: source and test inspection only.

## Next investigation

Trace actor declaration and API-key creation to determine how the bearer identity used in assertions is established and revoked.