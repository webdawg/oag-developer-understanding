# 0144 — `llms.txt` produces site-level `links_to` facts

Claim `B-0144`: at core `fb54e431332a030a566099c76fb2558084765422`, a fetched
`/llms.txt` is parsed into facts about the site origin, not about the fetched
document. Every Markdown link bullet becomes `site -> links_to -> resolved URL`;
the first title becomes a `Name` alias for that same site origin. The crawler
attaches `documentation` evidence from the `llms.txt` response and asserts these
facts at confidence `0.5`.

## Order of behavior

1. The crawler joins `/llms.txt` against the crawled URL and calls `safe_fetch`.
   The parser receives the response body and that actual `llms.txt` URL as
   `base_url`.
2. `origin_of(base_url)` yields `scheme://host[:port]` with no path, query, or
   fragment. This string is the subject of every extracted fact and the node
   identifier of the extracted alias.
3. Lines are trimmed. The first `# ` heading with a non-empty remainder sets
   the title; an empty `# ` line does not consume the title slot, so a later
   heading can still set it. Heading lines are otherwise ignored, as are `##`
   sections.
4. A line starting with `- ` or `* ` is passed to the link parser, which finds
   `[text](url)`. A non-link bullet is ignored, not an error. The URL is joined
   against the `llms.txt` URL, so `/docs/start` becomes an absolute URL; if
   joining fails, the raw string is used.
5. Each accepted link produces `ExtractedFact { subject: site_origin,
   predicate: "links_to", object: resolved_url, subject_type/object_type: None }`.
   The title, if any, becomes `ExtractedAlias` of type `Name` on `site_origin`.
6. `assert_extracted` commits the facts with `ExtractionMethod::StructuredExtraction`,
   confidence `0.5`, and one shared evidence record: type `documentation`, URI
   equal to the `llms.txt` URL, its BLAKE3 content hash, retrieval time, and a
   best-effort pin CID. `llms_txt_found` is set when the fetch succeeds.

## What is durable, rejected, and left behind

Durable: the `links_to` assertions, their evidence row, and the site alias if
its node exists. Because the facts have `site_origin` as subject, the first
accepted fact normally creates that node before the alias attempt; if no link
fact survives, the alias can be skipped by the node-resolution guard.

Rejected or ignored: non-link bullets, empty headings before a real title,
malformed link syntax, a failed side fetch (`if let Ok` silently skips the whole
block), and any link the graph later refuses during assertion (counted as
`facts_skipped`). Inclusion in `llms.txt` is explicitly treated as neutral
linking, not authority or endorsement; the source comment and confidence value
both reflect that. No test or HTTP fetch was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0144a | Implemented parser | `oag-crawler/src/extract/llms_txt.rs:6-78` |
| B-0144b | Implemented site-origin helper | `oag-crawler/src/extract/mod.rs:8-18` |
| B-0144c | Implemented side-fetch and evidence | `oag-crawler/src/crawler.rs:284-306` |
| B-0144d | Implemented fact/alias assertion | `oag-crawler/src/crawler.rs:346-395` |
| B-0144e | Test inspection, not executed | `oag-crawler/src/extract/llms_txt.rs:80-141` |

Verification: source and test inspection via `git show origin/main:<path>` at
the stated commit. No crawl or target test was executed.

## Change since the previously explained commit

`llms_txt.rs` is unchanged between `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`
and `fb54e431332a030a566099c76fb2558084765422`. The crawler's nearby change is
best-effort pinning of the side-fetch body; parsing and confidence are
unchanged. Findings 0140-0143 still hold at the newer commit.

## Next investigation

Trace `oag_crawler::extract::ard::parse` to document how an ARD response is
interpreted and whether it produces facts about the site or about multiple
resources.
