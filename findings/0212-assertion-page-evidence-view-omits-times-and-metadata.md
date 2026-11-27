# 0212 — The assertion page shows evidence text but not evidence provenance fields

Claim `B-0212`: at core `fb54e431332a030a566099c76fb2558084765422`, the human
Assertion page renders each evidence item's type, title, excerpt, URI, and
content hash. It omits the evidence row's ID, observed/retrieved times, and
metadata. Redacted evidence simply appears without its blanked title/excerpt.

## Order of behavior

1. `assertion_page` calls `list_evidence(assertion_id)` and maps each row through
   `evidence_view`.
2. `EvidenceView` copies exactly five fields: `evidence_type`, `uri`, `title`,
   `excerpt`, and `content_hash`. The evidence ID, timestamps, and JSON metadata
   are dropped at this boundary.
3. The template emits one list item per evidence row: type in brackets, optional
   title, optional excerpt as a blockquote, optional URI as a link, and optional
   hash in `<code>`.
4. Askama HTML-escapes interpolated values. The URI is used directly as an
   `href`; no scheme allowlist is applied by this view.
5. Evidence order is whatever `list_evidence` returned; that SQL query has no
   `ORDER BY`. After evidence redaction, `title`/`excerpt` are null and those
   parts of the list item are absent.

## What is durable, rejected, and left behind

Durable: nothing is changed by rendering. Rejected: no evidence field is
rejected by this view; invalid or unusual URI text is escaped but not validated.
Timestamps and metadata are not lost from storage — they are simply not copied
into the view, so REST/MCP callers may still see them through other surfaces.

The page can display crawler-controlled text (titles/excerpts) and hashes, but
the source notes Askama's default escaping. It does not show which event created
the evidence or whether a pin CID was recorded. No page was rendered.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0212a | Implemented evidence view | `crates/oag-api/src/human.rs:96-112` |
| B-0212b | Implemented assertion handler call | `crates/oag-api/src/human.rs:443`, `481-488` |
| B-0212c | Implemented template rendering | `crates/oag-api/templates/assertion.html:50-65` |
| B-0212d | Implemented storage selection and redaction | `crates/oag-storage/src/repo/assertions.rs:193-213` |
| B-0212e | Unchanged evidence rendering | `git diff 87f9e8c1..fb54e431 -- crates/oag-api/src/human.rs crates/oag-api/templates/assertion.html` (no evidence-region changes) |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No HTTP request or page render was executed.

## Change since the previously explained commit

Evidence rendering is unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`; the changed regions in `human.rs`
are search paging. Finding 0205 records the stored evidence fields; this
finding records which subset reaches the human page.

## Next investigation

Trace `oag_api::human::observation_view` and the assertion template's
verification/dispute/retraction sections to document what audit state is visible.
