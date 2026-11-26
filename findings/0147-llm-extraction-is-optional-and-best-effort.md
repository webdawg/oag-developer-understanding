# 0147 — LLM extraction is optional, bounded, and best-effort

Claim `B-0147`: at core `fb54e431332a030a566099c76fb2558084765422`, the LLM
fallback is disabled unless the operator selects `openai_compatible` with a base
URL. When enabled it makes one chat-completions request per HTML page, accepts
only a JSON array of subject/predicate/object/confidence objects, clamps
confidence, and treats a malformed model response as "no candidates" rather than
a crawl failure.

## Order of behavior

1. Config maps `"disabled"` (the default), any other provider string, or
   `openai_compatible` without a base URL to `DisabledExtractor`. That
   implementation's `extract` always returns an empty vector and its
   `model_name()` is empty.
2. The crawler calls `extract` unconditionally after deterministic extraction,
   but only for HTML/XHTML pages. Its input is `body_text` with script and
   style content removed, whitespace collapsed, and truncated to
   `LLM_EXTRACTION_MAX_CHARS = 8_000`.
3. `OpenAiCompatibleExtractor::extract` POSTs to
   `<base_url>/chat/completions` with `temperature: 0`, a prompt containing the
   source URL and page text, and an optional bearer token. The client has a
   10-second connect timeout and a 120-second total timeout.
4. The prompt asks for only a JSON array with exactly `subject`, `predicate`
   (snake_case), `object`, and `confidence` (0.0 to 1.0), or `[]` when nothing
   is confidently extractable. The implementation reads only
   `choices[0].message.content`.
5. `parse_candidates` strips leading/trailing code fences, parses the content,
   drops candidates with any blank trimmed string, clamps confidence to
   `[0, 1]`, and logs a warning for invalid JSON before returning no candidates.
6. If candidates exist, the crawler declares or reuses an actor named
   `llm-extractor:<model>`, then commits each candidate as an `AssertInput` with
   `LlmExtraction`, `agent_observation` evidence copied from the page, and the
   candidate's confidence. A model error is ignored by `if let Ok`; a failed
   per-candidate assertion increments `facts_skipped`.

## What is durable, rejected, and left behind

Durable after success: candidate assertions attributed to the model actor,
with the page's URI/hash/pin as evidence. Rejected: transport or HTTP errors
(`CrawlError` from `error_for_status`/JSON decode), invalid model JSON, blank
fields, and graph validation failures on individual candidates. Transport and
JSON decode errors are skipped at the crawler call site; invalid JSON is turned
into an empty vector inside the extractor. Nothing is retried in this function.

Because the default provider returns no candidates and `model_name()` is
empty, the disabled path never declares a model actor and makes no outbound
request. Tests were inspected for plain JSON, code fences, confidence
clamping, blank fields, malformed JSON, and bearer auth; they were not executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0147a | Implemented provider selection | `oag-cli/src/config.rs:272-288` |
| B-0147b | Implemented trait, default, and client | `oag-crawler/src/llm_extract.rs:1-94` |
| B-0147c | Implemented request, prompt, and parse | `oag-crawler/src/llm_extract.rs:96-178` |
| B-0147d | Implemented orchestration and text cap | `oag-crawler/src/crawler.rs:20`, `242-281`, `134-148`; `oag-crawler/src/extract/mod.rs:59-82` |
| B-0147e | Test inspection, not executed | `oag-crawler/src/llm_extract.rs:180-300` |

Verification: source and test inspection via `git show origin/main:<path>` at
the stated commit. No model server was called and no target test was executed.

## Change since the previously explained commit

Between `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`, `llm_extract.rs` gained the two
explicit timeouts and switched client construction from `reqwest::Client::new()`
to a builder with those timeouts. The prompt, parsing, and orchestration lines
cited above are otherwise unchanged. Findings 0140-0146 still hold at the
newer commit.

## Next investigation

Trace `oag_graph::assert::GraphService::assert` and `AssertInput::validate` to
document which LLM candidate strings are accepted, normalized, or rejected
before an event is committed.
