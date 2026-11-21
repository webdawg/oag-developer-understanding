# 0048 — Crawler assertions use a local actor, not the caller's API key

Claim `B-048`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, crawl-generated
assertions are authorized by an in-process `AuthContext`, not by forwarding the
remote caller's bearer token. The crawler reuses one actor named `crawler` and
type `Crawler`, creating it without a public-key proof when absent, and grants
that context only `graph:assert`.

## Authority separation

`crawler_auth` searches by name and type. On the first use it calls
`declare_actor` without a key proof, so the actor ID follows finding 0044's
event-scoped derivation. Later lookups reuse the stored actor. The resulting
context is passed to `GraphService::assert`; no API key is created for it.

The remote caller still needed `graph:crawl` or admin to trigger the operation,
but the resulting assertion records the crawler actor as its author. LLM
candidates similarly use one actor per model name, created only when a candidate
exists, with only `graph:assert`. Neither internal context receives crawl,
verify, retraction, or admin permission.

This is local trust in the server process. It does not prove that a remote peer
can authenticate the crawler actor, because no public-key proof was supplied
during declaration.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-048 | Implemented | `crates/oag-crawler/src/crawler.rs:14` and `85-126` |

Verification: source inspection only. No crawl was executed.

## Next investigation

Trace `find_actor_by_name` uniqueness and determine whether duplicate names can select the wrong crawler actor.