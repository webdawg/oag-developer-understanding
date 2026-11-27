# 0220 — The signed event vocabulary is a closed tagged enum

Claim `B-0220`: at core `fb54e431332a030a566099c76fb2558084765422`,
`EventPayload` has exactly ten variants serialized under an `event_type` tag in
`SCREAMING_SNAKE_CASE`. The enum is flattened into every unsigned event, so the
tag participates in the signature and derived event ID. An unknown variant
cannot be constructed locally or deserialized during replay.

## Order of behavior

1. The variants are ASSERT_RELATION, ADD_EVIDENCE, VERIFY_ASSERTION,
   DISPUTE_ASSERTION, RETRACT_ASSERTION, SUPERSEDE_ASSERTION, ACTOR_DECLARE,
   ACTOR_KEY_ADD, ACTOR_KEY_REVOKE, and NODE_ALIAS.
2. `type_str()` returns those exact strings and is used for the event row's
   `event_type` and history filtering. Serde's external tag is also
   `event_type`, so the stored type and canonical JSON tag agree.
3. `UnsignedEvent` flattens the payload, placing variant fields at the top
   level of canonical JSON alongside version, origin, chain, and timestamp.
4. `AssertRelation` stores already-canonicalized subject/object strings, so
   replay does not depend on future canonicalization rule changes.
5. `AddEvidence` gained `pinned_cid` and `metadata` with `#[serde(default)]`;
   older signed events lacking those fields still deserialize. Unknown enum
   variants have no such fallback.

## What is durable, rejected, and left behind

Durable: the signed event body and its type tag; all projected state is
replayable only from these variants. Rejected: a payload whose `event_type` is
unknown or whose fields do not deserialize. A future schema addition needs a
new enum variant or a `#[serde(default)]` field to keep legacy events flowing.

The source comment explicitly excludes NODE_DECLARE because nodes are created
as a side effect of assertion, while NODE_ALIAS is included for crawler
metadata. Adding a new event kind is therefore a code/schema change, not a
free-form client extension. No event was built or replayed in this pass.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0220a | Implemented enum and tag | `crates/oag-events/src/payload.rs:4-42` |
| B-0220b | Implemented payload fields and legacy defaults | `crates/oag-events/src/payload.rs:44-153` |
| B-0220c | Implemented envelope flattening | `crates/oag-events/src/envelope.rs:8-29` |
| B-0220d | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-events/src/payload.rs` (no output) |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No event was built or replayed.

## Change since the previously explained commit

The event vocabulary is unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Finding 0219 records the envelope
and ID construction; this finding enumerates what can occupy its payload.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining gap from
the journal and revision table.
