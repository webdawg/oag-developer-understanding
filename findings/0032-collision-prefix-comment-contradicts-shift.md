# 0032 — A one-level collision index is not exact-hash matching

Claim `B-032`: at collisions `dfc8ca95ce9641c29dec6bebe1586936b113c883`, the
constructor comment says a prefix-level count of one indexes only exact-hash
matches. Insertion and query instead compute `hash >> (64 - length)`. At length
one, that retains only the most significant bit.

## Implementation

`insert_units` removes any existing item, computes a weighted SimHash, records
the hash and insertion order, and adds the ID to buckets for lengths 1 through
`prefix_levels`. Query uses the same shift. Capacity eviction removes the oldest
ID; a configured capacity of zero bypasses eviction.

The comment and body cannot both be correct. The body is the executable
behavior: one level groups items by their high bit, not by all 64 bits. Full
exact-hash matching is not established by this prefix scheme. Exact hash lookup
may exist through the separate `hashes` map, but the prefix bucket at level one
does not provide it.

The type comment also describes storage as “small integers.” The bucket values
inspected here are cloned `String` IDs. That comment therefore understates the
memory retained per bucket membership. A complete memory model was not measured.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-032a | Documented intent | `oag-collisions/src/lib.rs:444-445` |
| B-032b | Implemented contradiction | `oag-collisions/src/lib.rs:516-531` and `612-618` |

Verification: source inspection only. Ranking examples and tests were not run.

## Next investigation

Trace Data Roads' tracked files and determine whether it contains executable
implementation or only proposed requirements.
