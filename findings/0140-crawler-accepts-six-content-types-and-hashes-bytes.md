# 0140 — The crawler accepts six content types and hashes the exact body

Claim `B-0140`: at core `fb54e431332a030a566099c76fb2558084765422`, a crawler
fetch succeeds only when the final response has one of six normalized content
types and a body within the configured byte cap. The BLAKE3 hash is computed
over the exact accumulated body bytes and is carried into evidence, where
corroboration uses it to group separate URIs carrying the same content.

## Order of behavior

1. After manual redirect handling, `safe_fetch` calls `error_for_status_ref()`.
   It reads `Content-Type`, takes the substring before `;`, trims it, and
   lowercases it. The accepted set is exactly `text/html`,
   `application/xhtml+xml`, `application/json`, `application/ld+json`,
   `text/plain`, and `text/markdown`. A missing or unrecognized value becomes
   `UnsupportedContentType`.
2. A declared `Content-Length` over the cap is rejected before streaming. The
   stream is then accumulated chunk by chunk; if `body.len()` exceeds the cap,
   `ResponseTooLarge` is returned and no `FetchedPage` is produced.
3. `blake3_content_hash(&body)` is computed on the accumulated bytes. The
   returned `FetchedPage` contains `final_url`, normalized `content_type`,
   `body`, and `content_hash` (the `blake3:<hex>` form noted in its field
   comment).
4. `Crawler::crawl` puts that hash into `EvidenceInput.content_hash`, along
   with the final URL as `uri`, `evidence_type: "web_page"`, and a retrieval
   time. The graph service commits `AddEvidence` with those fields.
5. `corroboration_for_edge` builds a `content:<hash>` key for each evidence
   item with a non-empty hash and unions it with the source-control-group key.
   Two URIs carrying the same bytes therefore fall into one connected source
   group for source independence.

## What is durable, rejected, and left behind

Rejected at the fetch layer: HTTP error statuses, unsupported or absent content
type, oversized declared or streamed body, bad redirects, and earlier network
guard failures. The REST route maps `UnsupportedContentType` and
`ResponseTooLarge` to HTTP 502; blocked addresses and robots denials are 403.
No partial body is stored from a rejected streamed response.

Durable after a successful crawl: the evidence row keeps the content hash and
URI; the event log keeps the signed `AddEvidence` payload. A best-effort IPFS
pin (default provider disabled) is recorded separately and cannot fail the
crawl. The gateway's own HTTP upstream path reuses the same resolve/pin/body
cap/hash primitives but deliberately does **not** apply this content-type
allowlist, because it proxies arbitrary content.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0140a | Implemented content-type normalization and allowlist | `oag-crawler/src/fetch.rs:11-19`, `127-181` |
| B-0140b | Implemented size cap and hash | `oag-crawler/src/fetch.rs:183-205` |
| B-0140c | Implemented evidence handoff | `oag-crawler/src/crawler.rs:177-200`; `oag-graph/src/assert.rs:187-219` |
| B-0140d | Implemented corroboration grouping | `oag-graph/src/corroboration.rs:233-265` |
| B-0140e | Implemented HTTP error mapping and gateway difference | `oag-api/src/crawl.rs:46-66`; `oag-api/src/gateway.rs:537-541`, `592-613` |

Verification: source inspection via `git show origin/main:<path>` at the stated
commit. No crawl, HTTP request, or target test was executed.

## Change since the previously explained commit

Comparing `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` with
`fb54e431332a030a566099c76fb2558084765422`, the content-type, body-cap, and
hash lines in `fetch.rs` are unchanged; the crawler diff adds `prefer_ipv4` to
the address step. `crawler.rs` gained best-effort pin recording, and
`assert.rs` gained pin indexing, but the hash-to-evidence fields cited here are
unchanged. Findings 0131-0139 still hold at the newer commit.

## Next investigation

Trace `oag_crawler::extract::json_ld::extract_from_html` and
`extract_from_json` to document which extracted fields become assertions and
which evidence is attached to them.
