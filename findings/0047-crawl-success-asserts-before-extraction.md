# 0047 — A successful crawl asserts the page before extraction finishes

Claim `B-047`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, crawl processing
checks robots, fetches through the guarded client, and only then creates a
baseline `instance_of` assertion. Failure before that assertion returns an
error. Later extraction does not make the baseline assertion conditional.

## Pipeline

`check_robots` fetches `/robots.txt` through `safe_fetch`. Any robots fetch
error allows all paths. A parsed disallow rule for the target path returns
`RobotsDisallowed`, and the API maps that to HTTP 403.

The page fetch accepts only `text/html`, XHTML, JSON, JSON-LD, plain text, and
Markdown after removing content-type parameters. It also enforces the configured
response-size limit while streaming. Unsupported types and oversized responses
fail before graph writes.

After fetch, IPFS pinning is best-effort. The crawler then asserts the final URL
as a website or document with confidence `0.95`, structured-extraction method,
and web-page evidence containing URL, content hash, retrieval time, and optional
CID. Deterministic extractors and optional LLM extraction add further assertions.
The inspected code increments the fact count after the baseline assertion; a
later extraction error is not shown rolling it back.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-047a | Implemented | `crates/oag-crawler/src/fetch.rs:12-19`, `146-157`, and `185-197` |
| B-047b | Implemented | `crates/oag-crawler/src/crawler.rs:150-205` |

Verification: source inspection only. Crawl tests were not executed.

## Next investigation

Trace the crawler's own actor and permissions to determine which key authorizes these internally generated assertions.