# 0056 — Evidence redaction blanks a projection but history returns the event

Claim `B-056`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, admin evidence
redaction sets the projected evidence row's `title` and `excerpt` to null and
records a tombstone. It does not modify `events.canonical_payload`. The history
API deserializes that payload and returns it to a caller with `graph:read`.

## What is and is not removed

`redact_evidence` requires admin, rejects an existing tombstone, blanks the two
projected fields, and inserts the tombstone in one transaction. URI, content
hash, evidence type, and timestamps remain on the projection. Rebuild reapplies
the same projected-field update because the tombstone survives.

`get_history` loads event rows by reference and returns their canonical JSON
payload without consulting redaction tombstones. The history route protects
this with `authenticate_read`, not admin. Provenance separately deserializes the
same payload for signature verification but returns only metadata in
`EventProvenance`; that does not make the history payload redacted.

Redaction is therefore not deletion, encryption, or a guarantee that disclosed
evidence text becomes unreadable. Any event-log copy, backup, or peer that
received the original event can also retain it. Those external copies were not
traced here.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-056a | Implemented | `crates/oag-graph/src/redaction.rs:43-73` |
| B-056b | Implemented | `crates/oag-storage/src/repo/assertions.rs:186-199` |
| B-056c | Implemented | `crates/oag-graph/src/history.rs:16-54` and `crates/oag-api/src/handlers.rs:290-297` |

Verification: source inspection only. No redaction or history request was executed.

## Next investigation

Trace actor identity-URI redaction and determine whether its original value also remains available through an event or history path.