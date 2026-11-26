# 0145 — ARD extraction creates one subject per resource

Claim `B-0145`: at core `fb54e431332a030a566099c76fb2558084765422`, an Agent
Resource Description is parsed as a narrow `resources` array. Each resource
gets its own subject identifier, its own `instance_of` fact, its own `Name`
alias, and its own operator/capability facts. The site origin is only a
fallback subject for a resource without a `url`.

## Order of behavior

1. The crawler fetches `/.well-known/ard.json` with the guarded fetch, parses
   the JSON, and passes both body and site origin to `ard::parse`.
2. `parse` deserializes a struct containing only `resources: Vec<ArdResource>`.
   Malformed JSON or a missing/wrong-shaped `resources` field yields an empty
   page, not an error. Each resource may contain `name`, `type`, `url`,
   `capabilities`, and `operator` (`name`/`url`).
3. `resource_id` is the resource's raw `url` string, or the site origin when
   `url` is absent. The parser does not resolve a relative resource URL against
   the ARD URL; it uses the value as written.
4. `type` is compared case-insensitively: `mcp_server` or `mcp-server` maps to
   node type `mcp_server`, and every other value or absence maps to `agent`.
   A fact `resource_id instance_of concept:<node_type>` is always emitted.
5. A non-empty trimmed `name` becomes a `Name` alias on that `resource_id`.
   An operator with a `url` contributes `operated_by` using the URL; if no URL
   is present but a name is, the name is used as the object. Each capability
   string becomes `provides_capability` with object type `capability`.
6. The crawler asserts all facts with `ExtractionMethod::StructuredExtraction`,
   `api_response` evidence from the ARD fetch, BLAKE3 hash and pin CID, and
   confidence `0.7`; `ard_found` is set when the fetch succeeds.

## What is durable, rejected, and left behind

Durable: one node per resource URL (or one shared site-origin node for all
URL-less resources), its type fact, aliases, and capability/operator facts.
Rejected or ignored: malformed JSON, unknown resource fields, empty names,
and missing operator values. A relative `url` is passed through unchanged;
whether graph validation later accepts it is outside this parser. All facts
share the same ARD response evidence even when they describe different
resources, so their hash groups them to one fetched document in corroboration.

Aliases are attempted after facts by `assert_extracted`; a fact rejected later
can leave its resource node unresolved and its alias skipped. The ARD parser
itself has no side effects. No fetch or target test was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0145a | Implemented narrow ARD subset | `oag-crawler/src/extract/ard.rs:6-88` |
| B-0145b | Implemented side-fetch and evidence | `oag-crawler/src/crawler.rs:309-323` |
| B-0145c | Implemented fact/alias assertion | `oag-crawler/src/crawler.rs:346-395` |
| B-0145d | Test inspection, not executed | `oag-crawler/src/extract/ard.rs:90-172` |
| B-0145e | Compared unchanged file | `git diff 87f9e8c..fb54e43 -- crates/oag-crawler/src/extract/ard.rs` (no output) |

Verification: source and test inspection only.

## Change since the previously explained commit

`ard.rs` is unchanged between `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. The crawler diff adds a best-effort
pin CID to the ARD evidence block. Findings 0140-0144 still hold at the newer
commit.

## Next investigation

Trace `oag_crawler::extract::a2a::parse` to document how an agent card differs
from ARD in subject choice, predicates, and evidence.
