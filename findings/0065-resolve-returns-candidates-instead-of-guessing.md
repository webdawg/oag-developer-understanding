# 0065 — Resolution returns candidates instead of choosing among them

Claim `B-065`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, `resolve`
canonicalizes the input and returns `Found` with confidence `1.0` only when
that canonical identifier exists. Otherwise it runs the sanitized lexical search
and returns up to ten candidates, or `NotFound` when there are none. It does
not select one candidate automatically.

## Meaning of confidence

The confidence value is a comment-defined marker for exact identifier lookup,
not corroboration, authority, or truth. Canonicalization can make visibly
different strings exact-match the same node, as finding 0043 describes. The
fallback search uses `nodes::search`, so it inherits lexical suppression and
FTS sanitization. An exact canonical match is returned before that search and
is not suppressed by the inspected function.

The REST adapter preserves this distinction by emitting either one node or a
`candidates` array. Callers must not treat candidate order as an authoritative
choice; it follows the search rank.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-065a | Implemented | `crates/oag-graph/src/resolve.rs:8-42` |
| B-065b | Implemented adapter | `crates/oag-api/src/handlers.rs:261-271` |

Verification: source inspection only. No resolution request was executed.

## Next investigation

Update the repository coverage index, then trace transfer-receipt verification and its separation from bearer authentication.