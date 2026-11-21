# 0041 — An event ID commits to the signed envelope, not only its payload

Claim `B-041`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, local event
construction signs canonical unsigned JSON under the domain `OAG:EVENT:v1:` and
derives the event ID from canonical JSON of the complete signed envelope. The
same domain prefix is then applied again by `EventId::derive`.

## What changes identity

The unsigned event contains version, origin peer, sequence, previous event,
creation time, and flattened payload. Canonicalization uses RFC 8785 JSON
through `serde_jcs`. Changing payload content, order-independent JSON encoding,
sequence, predecessor, timestamp, origin, version, or signature changes the
canonical signed bytes and therefore can change the ID. The signature is itself
inside those bytes.

The signature is calculated before the signature field exists, over
`"OAG:EVENT:v1:" || canonical_unsigned`. Verification repeats that calculation.
Thus a valid signature does not cover the signature string, as expected, while
the event ID does. A caller-supplied ID is not part of the signed struct and is
not trusted by remote verification.

This is not a statement that all semantically identical payloads produce
identical IDs. Different timestamps, sequences, or peer identities intentionally
produce different events. Numeric JSON encoding and optional-field omission were
not exhaustively tested.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-041a | Implemented | `crates/oag-events/src/builder.rs:8-46` |
| B-041b | Implemented | `crates/oag-events/src/envelope.rs:5-31` |
| B-041c | Implemented | `crates/oag-core/src/lib.rs:19-24` and `crates/oag-core/src/ids.rs:19-84` |

Verification: source inspection only.

## Next investigation

Trace payload serialization for `AssertRelation`, including field names and flatten behavior, so a developer can predict which request changes affect the signed bytes.