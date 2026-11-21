# 0110 — The collisions index evicts the oldest item, not the lowest ranked

Claim `B-110`: at collisions `dfc8ca95ce9641c29dec6bebe1586936b113c883`,
`insert_units` removes any existing copy of the ID, appends it to an insertion
order, and then evicts from the front until the item count is within
`max_items`. The default capacity is 100,000. Eviction does not consult
similarity score, token weight, or query frequency.

## Consequences

Re-indexing an existing ID moves it to the newest end, so a refresh protects it
from being the next eviction. A newly inserted low-quality item can therefore
displace an older item that would rank higher for future queries. A
`max_items` of zero returns before the loop, so it does not evict the item just
inserted. In the inspected code, zero is an unlimited capacity, not an empty
index. The function returns whether any eviction happened, not which ID was
removed. No index was populated.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-110 | Implemented | `oag-collisions/src/lib.rs:41` and `505-546` |

Verification: source inspection only.

## Next investigation

Trace imagination node failure handling and determine whether a failed source aborts the run or is recorded and skipped.