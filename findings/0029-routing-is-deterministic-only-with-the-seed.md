# 0029 — Imagination routing is reproducible only when its seed is shared

Claim `B-029`: at imagination
`7b7dcb8eae70b2df2fa1329fdb7b2dd928e76d29`, `route` is a pure function of the
pad, neighbor list, and 32-byte seed. `SoftwareRandom`, the source installed by
`NodeAdapter`, obtains that seed from `oag_crypto::random_bytes_32` and does not
record it in the inspected adapter.

## Deterministic decision

`route` returns `None` when there are no neighbors. Otherwise it uses nonnegative
pad weights, applies a floor of 1% of their mean or a tiny absolute floor, and
hashes domain bytes plus the seed with BLAKE3. The first four hash bytes select
a point in the cumulative weight range. Given the same inputs, this calculation
has no hidden clock or external read.

The function does not verify that a selected neighbor is reachable or that the
pad came from a trusted source. It also does not prove that the weighted choice
is a cryptographically fair sample; it is a deterministic mapping from the seed
and weights.

## What another peer cannot infer

The module comment explicitly says this is not a beacon and that a node knowing
its own source can predict its own contribution. `SoftwareRandom::next` returns
fresh software randomness. The inspected `NodeAdapter` passes the source into
the engine but does not persist each generated seed. Another peer therefore
cannot reproduce a decision unless some other message, log, or protocol includes
the pad, ordered neighbors, and seed. No such protocol was traced here.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-029a | Implemented | `oag-imagination/src/source.rs:14-27` |
| B-029b | Implemented | `oag-imagination/src/engine.rs:263-294` |
| B-029c | Implemented caller | `oag-imagination/src/node.rs:60-65` |

Verification: source inspection only. Convergence examples and tests were not
run.

## Next investigation

Trace listend's content admission path and determine what its content hash and
format sniffing do and do not prove.
