# 0234 — Extraction method is provenance, not confidence

Claim `B-0234`: at core `fb54e431332a030a566099c76fb2558084765422`,
`ExtractionMethod` has four exact snake_case values — `direct`,
`structured_extraction`, `llm_extraction`, and `verification`. It records how a
candidate relationship was produced; machine extraction is explicitly a
candidate, not a fact. It is not a confidence score or a truth flag.

## Order of behavior

1. `GraphService::assert` defaults `None` to `Direct`; REST DTOs do not expose
   this field, so REST assertions are direct. The crawler passes
   `StructuredExtraction` for deterministic extractors and `LlmExtraction` for
   its optional model pass.
2. Transfer records use `Verification` on the client side after a receipt
   verifies, and `Direct` on the server side after serving.
3. The method string is embedded in `AssertRelationPayload`; projection parses
   it with `ExtractionMethod::parse` and returns
   `UnknownExtractionMethod` for an unrecognized value before storing the
   assertion.
4. The stored field participates in REST/MCP assertion responses and human
   displays but does not enter corroboration weights or status transitions.

## What is durable, rejected, and left behind

Durable: the method string on each assertion row and in its signed event.
Rejected: an unparseable method prevents assertion projection; the event
transaction is not committed. A valid method does not make the claim true or
false.

The four values distinguish human/agent assertion, deterministic extraction,
model extraction, and independently verified transfer. They are provenance
labels that complement `actor_confidence` and separate derived scoring, not
substitutes for either. No assertion was created in this pass.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0234a | Implemented enum and parser | `crates/oag-core/src/assertion.rs:5-40` |
| B-0234b | Implemented service default | `crates/oag-graph/src/assert.rs:99-102`, `156-160` |
| B-0234c | Implemented projection rejection | `crates/oag-events/src/projector.rs:101-119` |
| B-0234d | Implemented transfer usage | `crates/oag-api/src/transfer.rs:417-423`, `490-500`, `607-614` |
| B-0234e | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-core/src/assertion.rs crates/oag-events/src/projector.rs` (no output) |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No assertion was created.

## Change since the previously explained commit

Extraction-method semantics are unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Finding 0233 records the confidence
field; this finding records the adjacent provenance label.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining gap from
the journal and revision table.
