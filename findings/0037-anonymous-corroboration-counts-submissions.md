# 0037 — Anonymous corroboration counts paid submissions, not identities

Claim `B-037`: at mesh `9f5d89e9fcf944dc16eff61f17543e83fc6ad20c`, an anonymous
event log groups reports by `corroboration_nonce` and counts every accepted
submission. It has no identity with which to deduplicate one party. Proof of
work makes each additional submission under that nonce more expensive, but it
does not reject a semantically repeated event.

## Acceptance rule

`record` first validates location coarseness and rounded time. It then requires
a proof whose BLAKE3 hash, over a mesh-specific domain and selected event
fields, has at least `16 + 4 * existing_count` leading zero bits. The first
report needs 16 bits; each existing report adds four bits.

On success, the event is appended to a vector. `corroboration_for` returns that
vector's length. The same event content can therefore be recorded again if the
submitter solves a new proof at the newly escalated difficulty. A proof is bound
to the event content, so it cannot be reused for a different event, but binding
does not create a seen-proof cache.

The comments correctly say this cannot stop a well-resourced attacker and cannot
determine whether a caller-selected nonce contains identifying information.
Transport comments separately state that plain HTTP does not hide source IP.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-037a | Implemented and documented intent | `oag-mesh/src/anonymous_event.rs:132-151` and `247-267` |
| B-037b | Implemented proof binding | `oag-mesh/src/anonymous_event.rs:156-198` |

Verification: source inspection only. Proof-of-work tests were not executed.

## Next investigation

Trace claim-report corroboration and its cross-check against bridge attestations, including the default threshold of one.