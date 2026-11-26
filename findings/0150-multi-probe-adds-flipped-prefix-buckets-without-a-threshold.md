# 0150 — Multi-probe adds flipped-prefix buckets without a final threshold

Claim `B-0150`: at collisions `b19fc44d76c975f22cdd07cfa3bc2e4f60cc4c0b`,
`collide_multi_probe` widens recall by looking up 8-bit prefix buckets whose
high-order bits differ from the query by a small number of flips. It unions
those candidates with the normal prefix ladder, recomputes shared prefix and
Hamming distance from full stored hashes, sorts by Hamming, and returns them
without reapplying `MIN_COLLISION_BITS`.

## Order of behavior

1. The normal ladder probes `(length, hash >> (64-length))` for lengths from
   `MIN_COLLISION_BITS` (8) through the index's `prefix_levels`, collecting IDs
   into a set.
2. `probe_bits` is clamped to at most 8, and `max_flips` to at most
   `probe_bits`. `base` is the query hash's top 8 bits.
3. For every mask in `1..(1 << probe_bits)` whose `count_ones() <= max_flips`,
   the method probes `(8, base ^ mask)`. Each hit is added to the same candidate
   set. The source comment gives 36 extra lookups for 8 probe bits and 2 flips.
4. For each candidate ID it reads the full indexed hash, computes
   `shared_prefix(hash, item)` and Hamming distance via `count_ones()` of the
   XOR, then sorts ascending by Hamming distance. It does not filter the union
   by shared bits, so a candidate found only in a flipped bucket can be returned
   with fewer than 8 shared bits.
5. `collide_multi_probe_text` applies the index's tokenizer first and otherwise
   uses the same path. No index state is changed.

## What is durable, rejected, and left behind

Durable state is unchanged: this is a read-only query over existing buckets,
hashes, and insertion order. Rejected or clamped inputs are only the probe
parameters; an oversized `probe_bits` becomes 8 and an oversized `max_flips`
becomes `probe_bits`. With `probe_bits = 0`, the mask loop is empty and the query
reduces to the normal ladder, though it still sorts by Hamming instead of
longest shared prefix.

The recall gain is bought with false positives: every extra bucket can contain
unrelated items, and the method has no final shared-bit cutoff or distance cap.
The source comments cite `examples/recall.rs` and `examples/ranking_margin.rs`
measurements, including a 61% exclusion figure for the plain prefix filter;
those measurements are Documented intent here and were not reproduced. Finding
0061's warning that the candidate set is prefix-filtered still applies to the
plain `collide`, not to this widened query. No benchmark or target test was run.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0150a | Implemented multi-probe query | `crates/oag-collisions/src/lib.rs:647-699` |
| B-0150b | Implemented text wrapper and helpers | `crates/oag-collisions/src/lib.rs:287-303`, `702-720` |
| B-0150c | Implemented bucket storage and ordinary ladder | `crates/oag-collisions/src/lib.rs:401-426`, `578-613` |
| B-0150d | Compared unchanged library | `git diff dfc8ca95..b19fc44d -- crates/oag-collisions/src/lib.rs` (no output) |

Verification: source inspection via `git show origin/master:<path>` at the
stated commit. No experiment, benchmark, or target test was executed.

## Change since the previously explained commit

The collisions library is unchanged between `dfc8ca95ce9641c29dec6bebe1586936b113c883`
and `b19fc44d76c975f22cdd07cfa3bc2e4f60cc4c0b`; only scripts changed. Findings
0032, 0061, 0062, 0110, and 0149 therefore describe the same library code at
the newer commit.

## Next investigation

Trace `oag_collisions::simhash_with_domain` and every call site to determine
whether caller-chosen domains are actually used by an index or only defined as
a helper beside the empty-domain `simhash_weighted`.
