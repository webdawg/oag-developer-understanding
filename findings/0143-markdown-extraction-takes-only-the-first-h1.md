# 0143 — Markdown extraction produces one Name alias from the first H1

Claim `B-0143`: at core `fb54e431332a030a566099c76fb2558084765422`, the
Markdown extractor emits no facts and at most one alias. It scans lines in
order for the first one whose left-trimmed text starts with exactly `"# "`,
trims the remainder, and returns it as a `Name` alias for the crawled page URL.
Later headings and all links are ignored.

## Order of behavior

1. `extract` iterates `markdown.lines()` and uses `find_map`, so it stops at
   the first matching line.
2. A match requires `line.trim_start().strip_prefix("# ")`. Leading spaces are
   tolerated; a `#Title` line without a space, `## heading`, or `#\thead` do
   not match.
3. The remainder is trimmed; an empty remainder yields no alias and does not
   stop the scan. The first non-empty remainder becomes one `ExtractedAlias`
   with `alias_type: Name` and `node_identifier: page_url`.
4. The orchestrator dispatches this extractor only for `text/markdown`.
   `text/plain` is accepted by `safe_fetch` but falls through the dispatch
   match with no deterministic extraction; the page still receives its
   baseline assertion.
5. `assert_extracted` attempts the alias only after the page node exists, and
   counts only successful declarations. There is no cross-extractor dedupe in
   this function.

## What is durable, rejected, and left behind

Durable after success: a `Name` alias on the page node. Rejected or ignored:
empty first H1, later H1s, subheadings, links, and any other Markdown syntax.
No assertion is created from Markdown extraction itself; the only assertion on
this path is the baseline page assertion created earlier by the crawler.
The alias may still fail later at `declare_alias`; that failure is reflected by
a missing increment in the crawl summary, not by a parse error.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0143a | Implemented extractor | `oag-crawler/src/extract/markdown.rs:3-31` |
| B-0143b | Implemented dispatch | `oag-crawler/src/crawler.rs:225-240`, `378-395` |
| B-0143c | Test inspection, not executed | `oag-crawler/src/extract/markdown.rs:33-75` |
| B-0143d | Compared unchanged file | `git diff 87f9e8c..fb54e43 -- crates/oag-crawler/src/extract/markdown.rs` (no output) |

Verification: source and test inspection only. No crawl or target test was
executed.

## Change since the previously explained commit

`markdown.rs` is unchanged between `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`
and `fb54e431332a030a566099c76fb2558084765422`. Findings 0140-0142 still hold
at the newer commit.

## Next investigation

Trace `oag_crawler::extract::llms_txt::extract` to document how the site-level
`llms.txt` fetch becomes candidate facts and which subject identifier it uses.
