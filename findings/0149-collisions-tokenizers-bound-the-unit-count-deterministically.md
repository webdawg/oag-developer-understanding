# 0149 — Collisions tokenizers can bound the unit count deterministically

Claim `B-0149`: at collisions `b19fc44d76c975f22cdd07cfa3bc2e4f60cc4c0b`,
`Tokenizer` offers word, character, stride-sampled, shuffle-sampled, and
window-sampled unit generation. The three budget variants cap the number of
units fed to SimHash without truncating only the document tail. All are pure and
deterministic; none validates semantic content. The default remains word
unigrams with bigrams off.

## Order of behavior

1. `Tokenizer::tokenize` returns `(unit, vote_weight)` pairs. `Words` lowercases
   alphanumeric runs, assigns each unigram `max(unigram_weight, 1)`, and adds
   n-grams only when `shingle >= 2` and `bigram_weight != 0`.
2. `Characters` calls `char_shingles`, which collects Unicode scalar values,
   clamps `n` to at least 1, preserves case, and returns the whole text as
   one-character units when it is shorter than `n`.
3. `WordsBudget` first builds `Words` units. If there are more than
   `max(target_units, 1)`, it computes `stride = ceil(len / target)` and keeps
   `step_by(stride).take(target)`. This samples across the document but only at
   positions congruent modulo the stride.
4. `WordsShuffledBudget` builds the same `Words` units, shuffles indices with a
   deterministic LCG seeded by the caller's `seed` and `wrapping` arithmetic,
   takes the first `target` indices, then sorts them back into document order.
   The same seed and text produce the same sample; a different seed changes
   which positions are visible.
5. `WordsWindowBudget` builds overlapping joined token windows of `window`
   tokens (or the whole token list when shorter), then applies the same stride
   reduction. `describe()` produces reporting strings only; it does not affect
   hashing.

## What is durable, rejected, and left behind

These functions store nothing and accept no invalid-input error path. They
clamp `n`, `unigram_weight`, and `target_units`, skip n-gram generation when
disabled, and return an empty vector for empty text. A budgeted tokenizer
intentionally discards information: stride sampling has a periodic blind spot,
shuffle sampling can miss an edit by chance, and window sampling makes each unit
coarser. The source comments cite `EXPERIMENTS.md` entries for those trade-offs;
they are Documented intent here, not measurements reproduced in this repository.

A unit's weight later controls the sign and magnitude of its contribution in
`simhash_weighted`; a zero weight is skipped there. The tokenizer itself does
not check weight ranges, so a negative bigram weight is passed through as a
vote rather than rejected. No experiments, targets, or tests were executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0149a | Implemented tokenizer variants and defaults | `crates/oag-collisions/src/lib.rs:69-147` |
| B-0149b | Implemented unit generation and reductions | `crates/oag-collisions/src/lib.rs:149-244` |
| B-0149c | Implemented description and character units | `crates/oag-collisions/src/lib.rs:246-285` |
| B-0149d | Implemented hash consumer | `crates/oag-collisions/src/lib.rs:315-361` |
| B-0149e | Compared unchanged library | `git diff dfc8ca95..b19fc44d -- crates/oag-collisions/src/lib.rs` (no output) |

Verification: source inspection via `git show origin/master:<path>` at the
stated commit. No experiment, target test, or benchmark was run.

## Change since the previously explained commit

The collisions explained commit `dfc8ca95ce9641c29dec6bebe1586936b113c883`
differs from latest `b19fc44d76c975f22cdd07cfa3bc2e4f60cc4c0b` only in
`scripts/README.md`, `scripts/prune-target.py`, and
`scripts/test_prune_target.py`. The library is unchanged, so findings 0032,
0061, 0062, and 0110 still describe the same code at the newer commit.

## Next investigation

Trace `oag_collisions::simhash_with_domain` and the multi-hash index path to
document how a second caller-chosen domain changes recall without changing the
first hash.
