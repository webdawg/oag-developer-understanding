# 0211 — The assertion page shows a three-state signature status

Claim `B-0211`: at core `fb54e431332a030a566099c76fb2558084765422`, the human
Assertion page renders origin and signature information from `EventProvenance`.
Signature status has three distinct outcomes: valid, invalid against a known
key, and unverifiable because no key is stored. A missing event is reported as
unknown rather than valid or invalid.

## Order of behavior

1. `assertion_page` loads the assertion, its edge, subject/object nodes, and
   actor. It converts the assertion ID into an `EventId` because assertion IDs
   are their creating event IDs.
2. It calls `get_event_provenance(event_id)` and passes the optional result
   directly to `AssertionTemplate`.
3. The template prints `assertion_id` as Event ID. If provenance is `None`, it
   prints an unknown-origin message and unknown signature status.
4. With provenance, it prints `p.origin_peer`. Signature status is:
   - `valid` when `signature_valid` is true;
   - `INVALID — signature does not verify against the origin's known public key`
     when false but `origin_key_known` is true;
   - `unverifiable — this peer does not have the origin's public key on file`
     when the key is unknown.
5. The actor block is separate from the origin block: an assertion can name an
   actor while its signed event came from a different origin peer.

## What is durable, rejected, and left behind

Durable: nothing is written by rendering. Rejected: the page request fails if
the assertion, edge, or related lookups required by the handler fail; missing
actor data is displayed as anonymous/unknown rather than aborting.

The page does not display the raw signed payload, so evidence text redaction is
not undone by this view (finding 0056). It also does not explain why a known
key failed, only that verification failed. No page was rendered in this pass.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0211a | Implemented provenance lookup in handler | `crates/oag-api/src/human.rs:430-443`, `469-490` |
| B-0211b | Implemented template status branches | `crates/oag-api/templates/assertion.html:27-48` |
| B-0211c | Implemented provenance semantics | `crates/oag-graph/src/provenance.rs:17-69` |
| B-0211d | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-api/templates/assertion.html crates/oag-api/src/human.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No HTTP request or page render was executed.

## Change since the previously explained commit

The assertion provenance rendering is unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Finding 0210 records the service
that computes the three states; this finding records their presentation.

## Next investigation

Trace `oag_api::human::evidence_view` and the assertion template's evidence
section to document which stored evidence fields a visitor can see.
