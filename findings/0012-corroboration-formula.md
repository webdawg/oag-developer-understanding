# 0012 — Corroboration scores active support against disputes

Claim `B-012`: at `open-agent-graph` `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
edge corroboration reports total stored assertions but calculates support from
active assertions only. Disputed assertions reduce the agreement ratio.
Retracted and superseded assertions affect neither side of that ratio.

## Formula

For one existing edge:

- `source_independence` is `(distinct_source_groups - 1) / 2`, clamped to
  `0..=1`. One group scores 0, two score 0.5, and three or more score 1.
- `evidence_strength` is the average of each group's strongest evidence weight.
  An active assertion with no evidence contributes its actor as a group with
  weight 0. Evidence without a recognized URI group also falls back to that
  actor group.
- `agreement` starts as `active / (active + disputed)`. If verification
  observations exist, their mean weight is mapped from `-1..=1` into `0..=1`,
  and the result is averaged with the status ratio.
- `freshness` uses the newest `observed_at`, or `asserted_at` when observation
  time is absent, across active assertions. No active assertion yields 0.
- `identity_assurance` averages the inspected identity score of each distinct
  active actor. The test shows 0 without key or URI, 0.3 with URI only, 0.7
  with key only, and 1 with both.

`total_assertions` includes every status, so it can be larger than
`active_assertions + disputed_assertions`. That difference is the retracted,
superseded, or other non-counted population; the formula does not label those
rows individually.

## Limits

Evidence type weights, URI control-group parsing, observation weight mapping,
and freshness decay constants were not included in this finding. The function
was inspected but not executed. Its tests were not run, so the identity and
freshness expectations are documented test intent plus inspected formulas, not
fresh observations.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-012 | Implemented | `crates/oag-graph/src/corroboration.rs:178-286` |
| B-012-tests | Test inspection, not executed | `crates/oag-graph/src/corroboration.rs:313-338` |

## Next investigation

Trace evidence weight and URI control-group rules, then determine whether
multiple citations of one URI can inflate corroboration despite the grouping rule.
