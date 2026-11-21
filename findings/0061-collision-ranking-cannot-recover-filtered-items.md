# 0061 — Hamming ranking reorders prefix candidates; it does not search everything

Claim `B-061`: at collisions `dfc8ca95ce9641c29dec6bebe1586936b113c883`,
`collide` only considers prefix buckets from `MIN_COLLISION_BITS` (8) through
the configured prefix depth. `collide_by_hamming` sorts those candidates by full
hash distance. An item whose first difference is in the top eight bits is absent
from the candidate set, even if the remaining hash is close.

## Ranking boundary

Prefix calculation uses `hash >> (64 - length)`, so length 8 retains the top
eight bits. The query starts at 8 rather than 1, which avoids treating a
one-bit bucket as a meaningful collision, but it also makes high-bit changes
invisible. The implementation comment states this limitation and cites an
unexecuted example measuring excluded variants. That measurement is documented
intent, not a result reproduced here.

`collide_by_hamming` explicitly sorts the prefix result. It can correct ordering
among found candidates, including pairs whose longest shared prefix disagrees
with Hamming distance, but it cannot add a candidate the prefix filter missed.
Multi-probe can search selected flipped high-bit prefixes and trades recall for
false positives. Its reported measurements were not run.

A one-level index from finding 0032 is especially weak here: if `prefix_levels`
is below 8, the query loop from 8 to that depth is empty, so normal collision
queries return no prefix candidates. That interaction follows the inspected
bounds but was not executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-061a | Implemented | `oag-collisions/src/lib.rs:31`, `292`, and `612-640` |
| B-061b | Implemented and documented intent | `oag-collisions/src/lib.rs:620-676` |

Verification: source inspection only. Ranking examples were not executed.

## Next investigation

Trace weighted SimHash accumulation and determine whether token order affects the default unigram hash.