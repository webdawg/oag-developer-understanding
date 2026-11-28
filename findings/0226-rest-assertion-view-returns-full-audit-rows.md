# 0226 — The REST assertion view returns full audit rows

Claim `B-0226`: at core `fb54e431332a030a566099c76fb2558084765422`,
`GET /api/v1/assertions/{id}` returns the assertion plus complete stored
evidence, observation, dispute, and retraction rows. This is richer than the
human Assertion page, which reduces those rows to display-only fields.

## Order of behavior

1. The handler requires `graph:read` and parses the assertion ID; a missing
   assertion returns 404.
2. It loads `get_assertion`, `list_evidence`, `list_observations`,
   `list_disputes`, and `list_retractions` with the same ID.
3. JSON is built with five keys: `assertion`, `evidence`, `observations`,
   `disputes`, and `retractions`. Storage structs are serialized directly, so
   IDs, actor IDs, timestamps, reasons, and metadata remain present.
4. Assertions are not filtered by status, and evidence is not filtered by
   redaction; a redacted evidence row still appears with null title/excerpt.
5. Provenance and history are separate surfaces. This response does not include
   the creating event's origin/signature check or `SUPERSEDE_ASSERTION` history.

## What is durable, rejected, and left behind

Durable: nothing is written. Rejected: auth failure, invalid ID, or missing
assertion. A caller with `graph:read` can see audit identifiers that the human
view drops; authorization is by capability, not by field sensitivity.

The view is node-local and reads projection tables, so it cannot show raw event
text beyond redacted evidence fields. No HTTP request was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0226a | Implemented REST assertion handler | `crates/oag-api/src/handlers.rs:105-128` |
| B-0226b | Implemented storage serializers | `crates/oag-core/src/evidence.rs:65-87`; `crates/oag-storage/src/repo/assertions.rs:270-341`, `399-423` |
| B-0226c | Human reduced views for contrast | `crates/oag-api/src/human.rs:96-139` |
| B-0226d | Separate provenance/history surfaces | `crates/oag-api/src/handlers.rs:339-347`; `crates/oag-graph/src/provenance.rs:31-69` |
| B-0226e | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-api/src/handlers.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No HTTP request was executed.

## Change since the previously explained commit

The REST assertion handler is unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Findings 0211–0213 describe the
human display reductions; this finding records the fuller REST view at the same
commit.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining gap from
the journal and revision table.
