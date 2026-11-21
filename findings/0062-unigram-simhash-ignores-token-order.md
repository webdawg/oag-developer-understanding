# 0062 — Default SimHash accumulation ignores token order

Claim `B-062`: at collisions `dfc8ca95ce9641c29dec6bebe1586936b113c883`,
`simhash_weighted` hashes each token independently, converts the first eight
digest bytes into 64 bit votes, and adds or subtracts that token's weight from
per-bit accumulators. The final bit is set only when its accumulated weight is
positive. Addition is commutative, so the same multiset of tokens and weights
produces the same hash regardless of order.

## What this does and does not mean

A zero weight is skipped. A negative weight reverses the token's votes. Nothing
in the loop records adjacent tokens, position, or sequence. Thus unweighted
unigrams are order-blind by algorithm, not merely by an untested example. The
comment's experimental claim that this was measured is documented intent; the
commutativity follows directly from the inspected accumulation.

Order can affect a hash only when the tokenizer emits different units, such as
bigrams or windows whose membership changes with sequence. This finding does not
inspect every tokenizer variant. It also does not say that equal hashes prove
equal meaning: different multisets can still accumulate to the same bit signs.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-062 | Implemented and documented intent | `oag-collisions/src/lib.rs:315-356` |

Verification: source inspection only. No hash fixture was executed.

## Next investigation

Trace Data Roads' companion paper only if it adds executable requirements; otherwise update the coverage index and select the highest remaining core gap: subgraph limits and cycle handling.