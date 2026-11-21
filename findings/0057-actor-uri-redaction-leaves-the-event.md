# 0057 — Actor URI redaction does not erase its declaration event

Claim `B-057`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, admin actor
redaction sets the projected `actors.identity_uri` to null and records a
tombstone. The declaration event payload still contains `identity_uri`, and the
inspected actor projector does not create an actor history reference that would
surface that event through the node/edge/assertion history API.

## Boundary

`redact_actor_identity_uri` requires admin, rejects a repeated tombstone, blanks
the projected field, and commits the tombstone. Name, actor type, and public key
remain. The service comment correctly treats the URI as descriptive metadata
rather than cryptographic identity, but that does not make the original event
unreadable.

`ActorDeclarePayload` serializes `identity_uri` into the signed event stored in
`events.canonical_payload`. Rebuild replays that payload and then reapplies the
projected null. A database reader or backup can therefore recover the URI from
the event even after the actor row is blanked.

The history API accepts only `node`, `edge`, and `assertion`. The inspected
actor projector does not call `add_ref` for an actor, so this particular
history route is not the disclosure path. Provenance deserializes the payload
for verification but returns metadata only. Absence of an actor history route
is not deletion from the event log.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-057a | Implemented | `crates/oag-graph/src/redaction.rs:92-125` and `crates/oag-storage/src/repo/actors.rs:71-76` |
| B-057b | Implemented payload | `crates/oag-events/src/payload.rs:119-124` |
| B-057c | Implemented history limit | `crates/oag-graph/src/history.rs:14` and `projector.rs:308-343` |

Verification: source inspection only. No actor or redaction operation was executed.

## Next investigation

Trace the unauthenticated status and metrics routes and determine what operational state they disclose without `graph:read`.