# 0011 — Non-active assertions remain directly readable

Claim `B-011`: at `open-agent-graph` `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
changing an assertion to disputed, retracted, or superseded does not remove it
from direct assertion reads or node assertion listings. Corroboration is the
inspected calculation that treats only `Active` assertions as supporting
evidence and separately counts disputed assertions.

## Read paths

`get_assertion` returns the stored row by ID without a status condition.
`list_assertions_for_node` lists every assertion on every edge touching the
node, also without filtering status. The function comment identifies this as
the backing behavior for `GET /nodes/{id}/assertions`.

By contrast, `get_edge_corroboration` loads all assertions but builds its
support calculation from `Active` rows only. It counts `Disputed` rows
separately. The inspected excerpt does not show retracted or superseded rows
contributing to the active support set.

Status is therefore a projection label and calculation input, not a universal
visibility barrier. A caller can still retrieve the historical assertion and its
status through the direct read path.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-011a | Implemented | `crates/oag-graph/src/assert.rs:339-348` |
| B-011b | Implemented | `crates/oag-graph/src/resolve.rs:84-99` |
| B-011c | Implemented | `crates/oag-graph/src/corroboration.rs:178-197` |

Verification: source inspection only. API route wiring and response serialization
were not rechecked in this finding.

## Next investigation

Trace one corroboration score from active assertions through evidence grouping
and verification observations, including which statuses and evidence fields
affect the result.
