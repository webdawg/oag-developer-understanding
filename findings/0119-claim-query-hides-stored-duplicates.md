# 0119 — The claim query hides duplicates that storage still retains

Claim `B-119`: at mesh `9f5d89e9fcf944dc16eff61f17543e83fc6ad20c`,
`best_corroborated_value` groups stored reports by observed value hash. It
counts distinct cluster strings and distinct peer IDs. A repeated report from
the same peer and cluster does not increase either count. The underlying vector
is unchanged.

## What the caller sees

The returned agreement contains the winning value hash, a cluster count, and a
peer count. It does not contain the number of stored reports, the free repeats,
or the memory they occupy. Ties in both counts are resolved by `max_by_key`
over a `HashMap` iterator. The comment calls that arbitrary. HashMap iteration
order is not a stable ranking, so two equal agreements do not have an inspected
deterministic winner. A missing claim returns `None`. No query was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-119 | Implemented and documented intent | `oag-mesh/src/corroboration.rs:308-331` |

Verification: source inspection only.

## Next investigation

Trace the HTTP best-value response and determine whether a missing claim and a tie are distinguishable to an API caller.