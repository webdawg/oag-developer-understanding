# 0042 — Assertion events serialize explicit fields under `ASSERT_RELATION`

Claim `B-042`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, an assertion
payload is internally tagged with `event_type: "ASSERT_RELATION"` and flattened
into the unsigned event. Its signed content uses the struct's snake-case field
names rather than the original HTTP request names.

## Serialized contract

The fields are `subject_identifier`, `subject_type`, `predicate`,
`object_identifier`, `object_type`, `actor_id`, `actor_confidence`,
`observed_at`, and `extraction_method`. Subject and object are comments-defined
as already canonicalized identifiers. Optional confidence and observation time
may be absent or null according to serde's standard option behavior; that exact
encoding was not executed.

Because the payload is flattened into the event, these fields share one JSON
object with version, origin, sequence, predecessor, and creation time. A change
to any included field changes canonical bytes and can change both the signature
input and event ID.

`AddEvidencePayload` uses `#[serde(default)]` for `pinned_cid` and `metadata`,
so older events lacking those fields can deserialize. `AssertRelationPayload`
has no equivalent optional compatibility field in the inspected struct. This
does not prove old assertion events survive every future schema addition.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-042 | Implemented | `crates/oag-events/src/payload.rs:14-61` and `crates/oag-events/src/envelope.rs:9-17` |

Verification: source inspection only. No canonical JSON fixture was generated.

## Next investigation

Trace identifier canonicalization and determine which raw subject strings converge to the same node ID before signing.