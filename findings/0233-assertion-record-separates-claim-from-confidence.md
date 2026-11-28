# 0233 — An assertion record separates the claim from its confidence

Claim `B-0233`: at core `fb54e431332a030a566099c76fb2558084765422`, an
`Assertion` is one actor's claim about an edge. Its `actor_confidence` is the
submitter's own value, not the system's confidence; corroboration signals are
computed separately at the edge level. The assertion's ID is the ID of the
`ASSERT_RELATION` event that created it.

## Order of behavior

1. `project_assert_relation` constructs `Assertion` with `id = event_id`,
   subject/object nodes resolved into an `Edge`, and `edge_id = edge.id`.
2. It stores `actor_id`, the payload's `actor_confidence`, `observed_at`, and
   `asserted_at: created_at`; `extraction_method` comes from the event payload,
   defaulting to `Direct` for REST callers.
3. `status` starts `Active`. Later dispute/retract/supersede events overwrite
   this single derived field while their own history rows remain (finding 0133).
4. `oag_graph::EdgeCorroboration` later computes `agreement`,
   `evidence_strength`, `source_independence`, and `freshness` from many
   assertions and observations. It does not collapse those into
   `actor_confidence`.
5. Reading an assertion by ID returns the projected row; REST also returns its
   evidence, observations, disputes, and retractions (finding 0226).

## What is durable, rejected, and left behind

Durable: the assertion row keyed by its creating event ID. A repeated claim
with the same triple adds another assertion row on the same edge; it does not
replace the first. Rejected: malformed IDs, oversized fields, and projection
failures; they leave no committed assertion from that call.

`actor_confidence: None` is not a low score; it means the submitter supplied no
value. A high value is not evidence of truth and does not bypass corroboration.
No assertion was created in this pass.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0233a | Implemented assertion struct and comment | `crates/oag-core/src/assertion.rs:117-137` |
| B-0233b | Implemented projection construction | `crates/oag-events/src/projector.rs:92-127` |
| B-0233c | Implemented status overwrites | `crates/oag-events/src/projector.rs:205-306`; finding 0133 |
| B-0233d | Implemented separate corroboration | `crates/oag-graph/src/corroboration.rs:221-342` |
| B-0233e | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-core/src/assertion.rs crates/oag-events/src/projector.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No assertion was created.

## Change since the previously explained commit

The assertion record and projection are unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Findings 0001 and 0042 describe the
commit and serialization; this finding records the field semantics.

## Next investigation

Trace `oag_core::ExtractionMethod` parsing and defaults to document how direct,
structured, and LLM origins are represented in assertions.
