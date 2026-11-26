# 0141 — JSON-LD extraction is a narrow, silent subset

Claim `B-0141`: at core `fb54e431332a030a566099c76fb2558084765422`, the JSON-LD
extractor recognizes only a handful of schema.org shapes. It turns each match
into candidate facts with the page URL as subject; malformed JSON and unknown
types are silently skipped. The orchestrator commits every resulting fact as a
`StructuredExtraction` assertion carrying the page's evidence.

## Order of behavior

1. For HTML/XHTML pages the orchestrator merges `extract_from_html`; for
   `application/ld+json` bodies it calls `extract_from_json`. The HTML variant
   selects `<script type="application/ld+json">` blocks, collects their text,
   and parses each independently with `serde_json`. A malformed block is
   skipped while other blocks still contribute facts.
2. `process_document` walks arrays and `@graph` arrays recursively. An object
   without `@graph` goes to `process_node`; a non-object JSON value is ignored.
3. `@type` is read as a string or string array and lowercased. A non-empty
   trimmed `name` always becomes a `Name` alias for the page URL.
   `SoftwareApplication` or `SoftwareSourceCode` adds `instance_of concept:software`;
   a string `codeRepository` adds `repository_at` with the raw value as object.
   `Organization` with a string `url` adds `operated_by`. A string or array
   `sameAs` adds one `related_to` fact per string value. Every other type or
   field shape is ignored, not reported as an error.
4. `ExtractedPage.facts` and `.aliases` are merged with other deterministic
   extractors. `assert_extracted` commits one `AssertInput` per fact using the
   page evidence (same URI and BLAKE3 content hash), `ExtractionMethod::StructuredExtraction`,
   and confidence `0.7`. A failed fact assertion increments `facts_skipped`
   but does not fail the crawl. Aliases are attempted only if the node already
   exists; a skipped fact can therefore leave its alias skipped too.
5. JSON-LD candidates are asserted before the optional LLM fallback. The LLM
   path uses a separate model actor and `LlmExtraction` evidence type, so its
   claims are distinguishable from these deterministic ones.

## What is durable, rejected, and left behind

Durable after a successful crawl: one assertion per accepted candidate, the
shared page evidence row, and any alias whose target node exists. The observer
is the stable in-process crawler actor with only `GraphAssert`, not the REST
caller's API key (finding 0045-style permissions are not inherited here).

Rejected or dropped: malformed JSON blocks, unrecognized types, wrong-shaped
fields, facts rejected by graph validation, and aliases whose node cannot be
resolved. These produce no error response from the extractor itself; the crawl
summary counts asserted versus skipped facts. No extractor talks to
`GraphService` directly — it returns `ExtractedPage` data — so the parsing
layer has no side effects of its own.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0141a | Implemented narrow schema subset | `oag-crawler/src/extract/json_ld.rs:7-85` |
| B-0141b | Implemented recursion and parse tolerance | `oag-crawler/src/extract/json_ld.rs:87-130` |
| B-0141c | Implemented extractor data contract | `oag-crawler/src/extract/mod.rs:20-57` |
| B-0141d | Implemented dispatch and assertion | `oag-crawler/src/crawler.rs:225-240`, `346-395` |
| B-0141e | Test inspection, not executed | `oag-crawler/src/extract/json_ld.rs:132-180` |

Verification: source and test inspection via `git show origin/main:<path>` at
the stated commit. No crawl or target test was executed.

## Change since the previously explained commit

`json_ld.rs` and `extract/mod.rs` are unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. The crawler diff adds best-effort
pin CIDs to page and side-fetch evidence; the fact/alias loop cited here is
unchanged. Findings 0131-0140 still hold at the newer commit.

## Next investigation

Trace `oag_crawler::extract::html_meta::extract` to document which HTML tags and
attributes become facts or aliases, and how they differ from the JSON-LD
subset.
