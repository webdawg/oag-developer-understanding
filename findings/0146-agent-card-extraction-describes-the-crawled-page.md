# 0146 — Agent-card extraction describes the crawled page, not the card URL

Claim `B-0146`: at core `fb54e431332a030a566099c76fb2558084765422`, an A2A
agent card fetched from `/.well-known/agent-card.json` yields facts whose
subject is the **original crawled page URL**, not the card URL. A valid card
always adds `instance_of concept:a2a-agent`; name, provider, and skills add
aliases and facts only when present.

## Order of behavior

1. The crawler joins `/.well-known/agent-card.json` against the page URL and
   calls `safe_fetch`. It passes the parsed body and `final_url` (the page, not
   `a2a_url`) to `a2a::parse`.
2. `parse` deserializes only `name`, `provider.{organization,url}`, and
   `skills[].{name,id}`. A body that does not deserialize yields an empty
   `ExtractedPage`; unknown fields are ignored.
3. Any successfully deserialized object adds
   `final_url instance_of concept:a2a-agent` with subject type `agent` and
   object type `concept`. This is emitted even when all optional fields are
   absent.
4. A non-empty trimmed `name` becomes a `Name` alias on `final_url`. A provider
   contributes `operated_by` using its `url` if present, otherwise its
   `organization` name. Each skill contributes `provides_capability` using
   `name` first, then `id`; skills without either are skipped.
5. `assert_extracted` commits these facts with `StructuredExtraction`,
   confidence `0.7`, and `api_response` evidence whose URI is the card URL and
   whose hash and pin CID come from the card body. `a2a_found` is set when the
   fetch succeeds. The alias is attempted after the facts, so the baseline
   `instance_of` fact normally creates the page node first.

## What is durable, rejected, and left behind

Durable: the a2a-agent type fact, optional name alias, operator and capability
facts, and shared card evidence. Rejected or ignored: malformed JSON, unknown
fields, empty names, provider without either value, and skills without name or
id. A failed card fetch is silently skipped by `if let Ok`; a later failed
assertion increments `facts_skipped` rather than failing the crawl.

The subject choice means two different pages whose cards describe different
agents are modeled as two different page nodes, while the evidence URI remains
the distinct card URL. The parser does not validate provider or skill strings
as URLs or identifiers. No fetch or target test was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0146a | Implemented narrow card subset | `oag-crawler/src/extract/a2a.rs:6-79` |
| B-0146b | Implemented fetch, subject choice, and evidence | `oag-crawler/src/crawler.rs:326-341` |
| B-0146c | Implemented fact/alias assertion | `oag-crawler/src/crawler.rs:346-395` |
| B-0146d | Test inspection, not executed | `oag-crawler/src/extract/a2a.rs:81-133` |
| B-0146e | Compared unchanged file | `git diff 87f9e8c..fb54e43 -- crates/oag-crawler/src/extract/a2a.rs` (no output) |

Verification: source and test inspection only.

## Change since the previously explained commit

`a2a.rs` is unchanged between `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`; the crawler change in this block is
the best-effort pin CID. Findings 0140-0145 still hold at the newer commit.

## Next investigation

Trace `oag_crawler::llm_extract::LlmExtractor::extract` and the
OpenAI-compatible implementation to document when an external model is called,
what it returns, and how failure is handled.
