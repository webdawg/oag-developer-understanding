# 0151 — Domain-separated SimHash exists but the index uses one domain

Claim `B-0151`: at collisions `b19fc44d76c975f22cdd07cfa3bc2e4f60cc4c0b`,
`simhash_with_domain(domain, units)` is a public primitive that prepends caller
bytes to each unit's BLAKE3 input. `CollisionIndex` never calls it with a
non-empty domain: it stores one hash per item through `simhash_weighted`, which
passes `b""`. Dual-hash recall is explored only in examples and an experiment
record, not in the index implementation.

## Order of behavior

1. `simhash_with_domain` creates a BLAKE3 hasher per unit, writes `domain`
   bytes then the unit string, takes the low 64 bits of the digest, and adds
   the unit's signed vote to each bit accumulator. The final bit is 1 where the
   accumulated weight is positive.
2. `simhash_weighted` is exactly `simhash_with_domain(b"", units)`. `simhash`
   delegates to it with unit weight 1.
3. `CollisionIndex::insert_units` calls `simhash_weighted` once and stores the
   result in `hashes: HashMap<String, u64>`. Prefix buckets are built from that
   one hash at `1..=prefix_levels`. There is no second domain field, second hash
   map, or dual-index union in the struct.
4. `examples/dual_hash.rs` calls `simhash_with_domain` with two caller-chosen
   domains, builds two independent ladder views in memory, and reports recall
   for A, B, and their union. `examples/recall_variance.rs` calls the helper with
   `b""` to compare variance among ordinary hashes. These are executable
   experiments, not code used by `CollisionIndex`.
5. `EXPERIMENTS.md` EXP-026 records a result that a second hash gained 2.5
   recall points over the better single hash at double the index memory and
   concludes it is not worth it. Those numbers are Documented experiment
   results here; this invocation did not run the example or reproduce them.

## What is durable, rejected, and left behind

The library's durable index state remains one hash and 1..=64 prefix buckets
per item. A caller can use the public helper to build and compare other hashes
outside the index, but nothing persists that comparison in this repository's
library. There is no validation of domain bytes, so any byte string is accepted
and different domains merely produce different deterministic hashes; the code
does not prove statistical independence.

No production query combines domains. EXP-026's dual-hash result is a recorded
experiment and proposal boundary, not an implemented index feature. Findings
0061, 0110, 0149, and 0150 describe the single-hash index that actually exists.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0151a | Implemented domain-separated hash | `crates/oag-collisions/src/lib.rs:305-361` |
| B-0151b | Implemented single-hash index | `crates/oag-collisions/src/lib.rs:401-426`, `500-560` |
| B-0151c | Example call sites, not run | `crates/oag-collisions/examples/dual_hash.rs:21-91`; `crates/oag-collisions/examples/recall_variance.rs:16-90` |
| B-0151d | Documented experiment result | `EXPERIMENTS.md:1415-1450` |
| B-0151e | Compared unchanged files | `git diff dfc8ca95..b19fc44d -- crates/oag-collisions/src/lib.rs EXPERIMENTS.md` (no output) |

Verification: source and experiment-text inspection only. No target example,
test, or benchmark was executed.

## Change since the previously explained commit

The collisions library and `EXPERIMENTS.md` are unchanged between
`dfc8ca95ce9641c29dec6bebe1586936b113c883` and
`b19fc44d76c975f22cdd07cfa3bc2e4f60cc4c0b`; only scripts changed. Findings
0032, 0061, 0062, 0110, 0149, and 0150 still describe the same library code.

## Next investigation

Check `oag-listend` master `b87dcac9a3c9e0059d90e698e2ec40fb2769ec41` against
the explained `aad2d9b2cc763239764fa8ba11ec7e871be00e11` and choose one changed
or undocumented admission/persistence mechanism.
