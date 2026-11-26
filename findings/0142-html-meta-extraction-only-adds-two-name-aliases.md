# 0142 — HTML meta extraction adds at most two Name aliases

Claim `B-0142`: at core `fb54e431332a030a566099c76fb2558084765422`, the HTML
meta extractor produces no facts. It reads the first `<title>` and the first
`<meta property="og:title">`, trims them, deduplicates them within that one
extract call, and returns each distinct non-empty value as a `Name` alias for
the crawled page URL.

## Order of behavior

1. `extract` parses the body with `scraper` and creates a local `HashSet`.
2. It selects `title` and takes only `next()`. The element's descendant text is
   collected, trimmed, and skipped if empty or already in the set. A surviving
   value becomes `ExtractedAlias { node_identifier: page_url, alias: title,
   alias_type: Name }`.
3. It then selects `meta[property="og:title"]`, again takes only the first
   element, reads its `content` attribute, trims it, and applies the same
   non-empty and local-set checks. An identical title and OG title therefore
   yield one alias; a third repetition elsewhere in the document is not read.
4. The returned `ExtractedPage` has no facts. The orchestrator merges it with
   the JSON-LD result for HTML pages, then `assert_extracted` attempts each
   alias against a node that must already exist. The baseline
   `instance_of` assertion is committed before extraction, so the page node
   normally exists by then.
5. A failed `declare_alias` is not surfaced as an error from `assert_extracted`;
   only successful ones increment `summary.aliases_declared`.

## What is durable, rejected, and left behind

Durable: alias rows attached to the page node after a successful declare call.
Rejected inside the extractor: empty strings and values repeated between the
two inspected tags. The `HashSet` is local to this extract call: the extractor
does not consult JSON-LD's `name` alias, other extractors, or existing database
rows, so deduplication across those sources is not performed here. Additional
`title` or `og:title` elements are ignored, not merged.

Meta description and other metadata are explicitly left for a future pass; the
source comment says there is no matching `AliasType` variant in this
milestone's model. No network or database access happens in the extractor
itself.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0142a | Implemented extractor | `oag-crawler/src/extract/html_meta.rs:5-42` |
| B-0142b | Implemented orchestration | `oag-crawler/src/crawler.rs:207-223`, `225-240`, `378-395` |
| B-0142c | Test inspection, not executed | `oag-crawler/src/extract/html_meta.rs:44-81` |
| B-0142d | Compared unchanged file | `git diff 87f9e8c..fb54e43 -- crates/oag-crawler/src/extract/html_meta.rs` (no output) |

Verification: source and test inspection only. No crawl or target test was
executed.

## Change since the previously explained commit

`html_meta.rs` is unchanged between `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`
and `fb54e431332a030a566099c76fb2558084765422`. The crawler's nearby change is
best-effort pin CIDs, not alias extraction. Findings 0140 and 0141 still hold
at the newer commit.

## Next investigation

Trace `oag_crawler::extract::markdown::extract` to document which Markdown
links or headings become candidate facts and aliases.
