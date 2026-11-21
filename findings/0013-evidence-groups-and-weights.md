# 0013 — Evidence grouping prevents one URI family from multiplying support

Claim `B-013`: at `open-agent-graph` `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
corroboration groups evidence by a control key and keeps only that group's
highest evidence weight. Repeating citations from the same recognized URI group
or actor does not increase the number of independent groups.

## Grouping

`control_group_for_uri` parses a URL, lowercases its host, and returns:

- `host/first-path-segment` for a recognized multi-tenant host when the first
  path segment is non-empty;
- the host alone for a recognized multi-tenant host without an owner segment;
- a registrable-domain calculation for other hosts.

An unparseable URI or URL without a host produces `None`. The corroboration
caller then groups that evidence under the asserting actor instead. The exact
multi-tenant host list and registrable-domain helper were not reproduced in this
finding.

## Weights

Evidence weights are:

| Type | Weight |
| --- | --- |
| Specification | 1.0 |
| Source code, API response, service receipt | 0.85 |
| Repository | 0.8 |
| Dataset | 0.7 |
| Documentation | 0.65 |
| Manual, user observation, file | 0.45 |
| Agent observation | 0.35 |
| Web page | 0.3 |
| Other | 0.15 |

Verification observations map confirmed to 1, changed to 0.3, unknown or
unreachable to 0, not confirmed to -0.5, and contradicted to -1. An unparseable
stored result contributes 0.

Freshness uses a 180-day half-life. Age zero scores 1, one half-life scores
about 0.5, and future timestamps are clamped rather than exceeding 1. These
constants are implemented defaults, not measurements of external truth.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-013 | Implemented | `crates/oag-graph/src/corroboration.rs:58-143` |

Verification: source inspection only.

## Next investigation

Trace search and read authorization to determine whether corroboration and graph
reads share the same permission boundary or expose different information.
