# 0053 — Embeddings remain stale until an operator rebuilds them

Claim `B-053`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, node embeddings
are rebuilt by `recompute_embeddings`, which clears the entire embedding table
and regenerates one vector per current node. Ordinary assertion or node writes
do not update embeddings incrementally.

## Lifecycle

The embedded text joins canonical identifier, name, and description when
present. The operation lists all nodes, clears all embeddings, and upserts a
fresh vector with provider name, model name, and timestamp. A provider or model
change therefore avoids mixed vector spaces only after this full rebuild
completes. If the process fails midway, the earlier `clear_all` has already
removed old vectors; crash recovery for that sequence was not tested.

The CLI exposes this through `embeddings_recompute`. Search uses semantic mode
only when explicitly requested or enabled in configuration. Neither path invokes
recompute automatically. A newly inserted or renamed node can consequently be
absent or outdated in semantic results until the next batch run.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-053a | Implemented and documented intent | `crates/oag-graph/src/semantic_search.rs:1-10` and `36-82` |
| B-053b | Implemented caller | `crates/oag-cli/src/commands.rs:314-341` |

Verification: source inspection only. Embedding tests were not executed.

## Next investigation

Trace authority recomputation and determine whether its stored scores are incremental, batch-rebuilt, and included in search ranking.