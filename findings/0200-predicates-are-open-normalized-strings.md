# 0200 — Predicates are open strings with one normalization rule

Claim `B-0200`: at core `fb54e431332a030a566099c76fb2558084765422`, a
`Predicate` is an open string newtype, not an enum. `Predicate::new` trims,
lowercases, and joins internal whitespace with underscores. `KNOWN_PREDICATES`
documents a v0 vocabulary but does not constrain accepted values.

## Order of behavior

1. `GraphService::assert` copies the raw predicate string into
   `AssertRelationPayload`; its validation checks only byte length, not
   membership in a vocabulary (finding 0148).
2. During projection, `project_assert_relation` calls
   `Predicate::new(&p.predicate)` before constructing the `Edge`. The normalized
   string is what the edge table and derived edge ID use.
3. `Predicate::new` trims the whole string, lowercases it, splits on Unicode
   whitespace, and joins the pieces with `_`. Thus `" Implements "` and
   `"implements"` resolve to the same predicate.
4. `From<&str>` and `From<String>` delegate to the same constructor.
   `KNOWN_PREDICATES` lists names such as `instance_of`, `links_to`, and
   `provides_capability`; its comment explicitly says new predicates may be
   asserted freely and unknown predicates must not be rejected.
5. An empty or whitespace-only predicate normalizes to an empty string. The
   shown constructor returns no error.

## What is durable, rejected, and left behind

Durable: the normalized predicate string participates in the projected edge.
Two raw strings that normalize identically target the same edge identity; a
custom predicate survives without registry approval. Rejected: nothing at this
layer for being unknown or empty. A too-long raw string was already rejected by
`AssertInput::validate`.

The vocabulary is documentation, not enforcement. This is a deliberate
anti-ontology choice in the source comment, and it means a typo becomes a new
predicate rather than a validation error. No assertion or projection was
executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0200a | Implemented newtype and normalization | `crates/oag-core/src/predicate.rs:5-49` |
| B-0200b | Documented v0 vocabulary | `crates/oag-core/src/predicate.rs:51-95` |
| B-0200c | Implemented projection use | `crates/oag-events/src/projector.rs:98-103` |
| B-0200d | Implemented input length-only check | `crates/oag-graph/src/assert.rs:105-121` |
| B-0200e | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-core/src/predicate.rs` (no output) |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No target test or assertion was executed.

## Change since the previously explained commit

The predicate type and vocabulary are unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Finding 0148 recorded that assert
validation does not enforce a vocabulary; this finding explains the actual
normalization applied later in projection.

## Next investigation

Trace `oag_core::edge::EdgeId` derivation to document exactly which fields make
an edge stable and how predicate normalization affects edge reuse.
