# 0206 — Source independence uses heuristic URI control groups

Claim `B-0206`: at core `fb54e431332a030a566099c76fb2558084765422`,
corroboration collapses each evidence URI to a "who controls this" key with a
small hard-coded heuristic. For known multi-tenant hosts it uses the first path
segment; otherwise it uses a registrable domain approximation. An unparseable or
host-less URI falls back to the asserting actor, so malformed evidence does not
gain a shared source key.

## Order of behavior

1. `control_group_for_uri` parses the string with `Url::parse` and lowercases
   the host. Parse failure or no host returns `None`.
2. If the host is in `MULTI_TENANT_HOSTS` — GitHub, gist, raw.githubusercontent,
   GitLab, Bitbucket, npm, PyPI, crates.io, Hugging Face, SourceForge, including
   listed `www` forms — the first non-empty path segment becomes the owner.
   The key is `<host>/<owner>`, or the bare host when no owner segment exists.
3. Other hosts go through `registrable_domain`: the last two labels, extended
   by a third label for a fixed list of second-level suffixes such as `co.uk`
   or `com.au`. This is not a full Public Suffix List.
4. In `best_corroborated_value_for_edge`, each evidence item gets a source key
   from this function, or `actor:<assertion actor>` when it returns `None`. It
   also gets a content key `content:<content_hash>` when a non-empty hash is
   present, plus the evidence-type weight.
5. A union-find graph unions items that share either a content key or a source
   key. Each connected component contributes its maximum weight, and
   `source_independence` is `(distinct components - 1) / 2`, clamped to `[0,1]`.

## What is durable, rejected, and left behind

Durable: no control-group table is stored; the grouping is recomputed from
evidence rows during each corroboration query. Rejected: no URI is rejected by
this helper; an unparseable one silently becomes actor-keyed. A URL with an
unlisted multi-tenant structure collapses to its registrable domain, which can
over-group unrelated owners on that host.

The source comment says the heuristic is approximate and the suffix list is not
exhaustive. The newer union-find changed grouping from a single key per item to
connected components across content and source identities; finding 0013's
formula still holds, but its older one-key grouping description has been
superseded at this commit. No score was computed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0206a | Implemented host and suffix lists | `crates/oag-graph/src/corroboration.rs:10-39` |
| B-0206b | Implemented control-group function | `crates/oag-graph/src/corroboration.rs:41-72` |
| B-0206c | Implemented component grouping | `crates/oag-graph/src/corroboration.rs:233-320` |
| B-0206d | Changed grouping algorithm | `git diff 87f9e8c1..fb54e431 -- crates/oag-graph/src/corroboration.rs` |
| B-0206e | Unchanged control-group heuristic | same diff: first hunk starts after `control_group_for_uri` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No corroboration query or target test was executed.

## Change since the previously explained commit

The control-group heuristic is unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. The way those keys are combined
changed: the newer source uses union-find over content and source keys. This
finding is a correction to the older grouping detail, not a rewrite of finding
0013.

## Next investigation

Trace `oag_graph::corroboration::verify_result_weight` and the observation
aggregation path to document how verification results change `agreement`.
