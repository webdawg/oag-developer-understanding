# 0117 — Anonymous-event proof of work raises cost but does not cap retention

Claim `B-117`: at mesh `9f5d89e9fcf944dc16eff61f17543e83fc6ad20c`,
`AnonymousEventLog` stores every accepted event in a map from
`corroboration_nonce` to a vector. `record` checks location length, time
rounding, and proof of work, then appends the event. No maximum nonce count,
nonce length, or vector length was found.

## Cost versus retention

The first report for a nonce needs 16 leading zero bits. Each additional stored
report for that same nonce adds 4 bits. A new nonce starts again at 16 bits and
creates a new map entry. Proof of work therefore makes repetition under one
nonce more expensive. It does not stop a submitter from creating many nonces,
and it does not remove old events. The difficulty formula uses `u32` addition
and multiplication with no saturating operation. Its overflow behavior depends
on the build profile and was not inspected. The log is process memory and is
lost on exit. No event was recorded.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-117 | Implemented | `oag-mesh/src/anonymous_event.rs:140-151` and `223-267` |

Verification: source inspection only.

## Next investigation

Trace claim-report corroboration storage and determine whether distinct cluster names are retained without a cap.