# 0224 — Roadmap proposals are ordinary corroborated assertions

Claim `B-0224`: at core `fb54e431332a030a566099c76fb2558084765422`, a roadmap
proposal is not a special object or vote. It is an assertion
`(proposal, instance_of, concept:oag-roadmap-proposal)` with ordinary evidence,
created through the normal `GraphService::assert` path. The roadmap module only
adds a listing view that ranks proposals by corroboration signals.

## Order of behavior

1. `ROADMAP_PROPOSAL_HUB` is a fixed canonical identifier; no row is pre-seeded.
   The first proposal's normal `resolve_or_create_node` creates the hub node.
2. The proposal predicate is `instance_of`, not a new vocabulary term. The
   source says submission is just `assert` / `POST /api/v1/assertions`.
3. `list_roadmap_proposals` first looks up the hub. If absent, it returns an
   empty list, not an error.
4. It finds edges with `instance_of` and the hub as object, loads each subject
   node, and calls `get_edge_corroboration` for that edge.
5. Results are sorted descending by `active_assertions`, then
   `source_independence`, then `evidence_strength`. NaN partial comparisons
   fall back to equal. There is no collapsed overall score.
6. REST `/api/v1/roadmap` and the human roadmap page both call this service
   method.

## What is durable, rejected, and left behind

Durable: only the ordinary assertion, evidence, nodes, edge, and derived
corroboration projection. The listing view writes nothing. A malformed or
unauthorized proposal is rejected by the existing assert path, not by roadmap
code; a proposal with weak evidence is still listed, lower in the order.

The module is discovery, not governance: no acceptance threshold, voting, or
status transition is defined here. Corroboration signals measure support in
the local graph and cannot by themselves decide what the project should build.
No proposal was submitted or listed in this pass.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0224a | Implemented hub, predicate, and listing | `crates/oag-graph/src/roadmap.rs:1-87` |
| B-0224b | Implemented proposal test path | `crates/oag-graph/src/roadmap.rs:117-190` |
| B-0224c | Implemented REST/human callers | `crates/oag-api/src/handlers.rs:149-156`; `crates/oag-api/src/human.rs:265`; `crates/oag-api/src/lib.rs:85` |
| B-0224d | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-graph/src/roadmap.rs` (no output) |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No assertion or listing request was executed.

## Change since the previously explained commit

The roadmap module is unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Findings 0012/0013 and 0206/0207
describe the corroboration signals used here; this finding records the
proposal representation and deterministic ranking.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining gap from
the journal and revision table.
