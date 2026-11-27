# 0205 — Evidence types are closed, and each has a fixed corroboration weight

Claim `B-0205`: at core `fb54e431332a030a566099c76fb2558084765422`,
`EvidenceType` is a closed 13-value enum parsed from exact snake_case strings.
An unknown string is rejected during `AddEvidence` projection, and each known
type has a hard-coded weight in corroboration. The label therefore affects both
admission and scoring.

## Order of behavior

1. `EvidenceType::as_str` and `parse` define the accepted vocabulary:
   `web_page`, `documentation`, `source_code`, `repository`, `api_response`,
   `dataset`, `file`, `manual`, `specification`, `user_observation`,
   `agent_observation`, `service_receipt`, and `other`.
2. `project_add_evidence` calls `EvidenceType::parse`; failure returns
   `EventsError::UnknownExtractionMethod` with the raw string. Despite the
   error name, this is an evidence-type check.
3. The accepted type is stored on the evidence row alongside the event ID,
   assertion ID, URI, title, excerpt, content hash, timestamps, and metadata.
   Metadata defaults to an empty JSON object.
4. `evidence_type_weight` maps the type to a fixed `f32`: specification 1.0;
   source_code/api_response/service_receipt 0.85; repository 0.8; dataset 0.7;
   documentation 0.65; manual/user_observation/file 0.45;
   agent_observation 0.35; web_page 0.3; other 0.15.
5. Those weights feed corroboration's evidence-strength grouping, alongside
   content-hash and control-group identity (finding 0013).

## What is durable, rejected, and left behind

Durable: the stored evidence type and its derived score contribution. Rejected:
an unrecognized evidence-type string aborts the `AddEvidence` projection; the
raw event row and projection changes share one transaction and are not left
committed by that path. A caller cannot invent a new higher-weight label by
naming it freely.

The weights are policy constants, not measurements from this event. The source
explains the higher `service_receipt` tier as nonce-bound and harder to fake.
`Evidence.content_hash` remains an unchecked string (finding 0148); the enum
check does not validate hash syntax. No evidence event or score was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0205a | Implemented evidence enum and parser | `crates/oag-core/src/evidence.rs:6-63` |
| B-0205b | Implemented projection rejection | `crates/oag-events/src/projector.rs:149-176` |
| B-0205c | Implemented weight table | `crates/oag-graph/src/corroboration.rs:110-126` |
| B-0205d | Implemented evidence record | `crates/oag-core/src/evidence.rs:65-87` |
| B-0205e | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-core/src/evidence.rs crates/oag-events/src/projector.rs crates/oag-graph/src/corroboration.rs` (no evidence-type changes) |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No event or corroboration computation was executed.

## Change since the previously explained commit

The evidence vocabulary and weights are unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Finding 0013 summarized the
corroboration formula; this finding records the exact closed vocabulary and
weight constants still used at the newer commit.

## Next investigation

Trace `oag_graph::corroboration::control_group_for_uri` to document which URI
strings collapse into one source group and how the collapse combines with these
weights.
