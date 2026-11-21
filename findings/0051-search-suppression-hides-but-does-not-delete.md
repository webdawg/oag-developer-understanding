# 0051 — Search suppression hides a node without deleting it

Claim `B-051`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, lexical search
matches sanitized terms against node name, description, and canonical identifier.
An admin suppression row excludes that node from the search query, but direct
node storage, edges, and assertions remain.

## Query behavior

`sanitize_fts_query` replaces every non-alphanumeric, non-whitespace character
with a space, splits words, and quotes each word. An empty result returns no
rows before SQLite. The limit is clamped to the service maximum. The FTS table
is an external-content index maintained by insert, delete, and update triggers.

The search query excludes every `node_id` in `search_suppressions`. Suppression
requires admin, is idempotent, and has an idempotent reversal. The table
intentionally has no foreign key to `nodes`, so rebuilding and replaying nodes
does not erase suppression rows. The graph service comment says direct lookup
remains available; the query itself only changes this search path.

Suppression is not encryption, redaction, or access control for callers who know
the node ID. It also does not alter corroboration or event history.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-051a | Implemented | `crates/oag-graph/src/search.rs:20-47` |
| B-051b | Implemented | `crates/oag-storage/src/repo/nodes.rs:162-176` and migrations `0001_init.sql:173-196` |
| B-051c | Implemented | `crates/oag-graph/src/redaction.rs:142-149` and migrations `0006_redactions.sql:29-32` |

Verification: source inspection only. Search tests were not executed.

## Next investigation

Trace semantic search and embeddings to determine whether suppression also applies there or only to the lexical FTS path.