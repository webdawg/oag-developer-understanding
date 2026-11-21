# 0015 — The human UI reuses read permission but puts the API key in URLs

Claim `B-015`: at `open-agent-graph` `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
human HTML handlers do not bypass authentication. They require the same API key
and `graph:read` permission, but accept the raw key in `?key=` and copy it into
generated links.

## Behavior

`authenticate_query` rejects a missing key, resolves the supplied key through
`GraphService::authenticate`, and requires `graph:read`. Invalid keys become
HTTP 401 and permission failure becomes HTTP 403. The inspected search, roadmap,
node, and assertion pages call this helper before loading graph data.

The module comment correctly says this does not make key-gated content public.
That is different from saying the transport exposure is equivalent to an
`Authorization` header. `node_link` and `assertion_link` embed the raw key into
`/ui/...?...key=` URLs. Query strings can be exposed through browser history,
screenshots, access logs, proxies, and the `Referer` header. Which of those
exposures occur depends on deployment and was not tested.

The comment also says template interpolation is HTML-escaped and no field is
marked safe. That reduces reflected HTML injection in the inspected templates,
but it does not remove query-string credential exposure.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-015a | Implemented and documented intent | `crates/oag-api/src/human.rs:1-74` |
| B-015b | Implemented calls | `crates/oag-api/src/human.rs:186-188`, `233-235`, `272-278`, `393-399` |

Verification: source inspection only. No browser or server was run.

## Next investigation

Trace the human router and logging configuration to see whether URLs containing
`key` are written to logs or otherwise redacted.
