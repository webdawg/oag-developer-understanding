# 0148 — Assert input bounds bytes, not meaning, then canonicalizes IDs

Claim `B-0148`: at core `fb54e431332a030a566099c76fb2558084765422`,
`GraphService::assert` checks field and evidence byte limits, canonicalizes
subject and object strings into node identifiers, and then commits the
assertion and each evidence item as separate events. It does not require a
known predicate vocabulary, a valid content hash format, or a confidence range.
An evidence failure after the assertion commit does not undo the assertion.

## Order of behavior

1. `assert` requires `graph:assert` and calls `AssertInput::validate`. Limits
   are 2048 bytes for subject/object and evidence URI, 128 for predicate and
   content hash/pinned CID, 64 for node types, 512 for title and alias, 4096 for
   excerpt, 8192 for serialized evidence metadata, and at most 20 evidence
   items. Lengths are byte counts; no non-empty check is performed here.
2. `canonicalize_value(subject)` and `canonicalize_value(object)` decide node
   identifiers. `http(s)` values are parsed and normalized (empty path becomes
   `/`, empty fragment dropped, tracking parameters removed) and prefixed with
   `url:`. Other `scheme:value` strings with no spaces and an alphanumeric/`-`/`_`
   scheme are lowercased and passed through. Everything else is lowercased,
   whitespace-joined with `-`, and prefixed with `concept:`.
3. `subject_type`/`object_type` come from the caller, else from the inferred
   kind (`url` or `concept`), else `"unknown"`. The predicate string is copied
   unchanged. `extraction_method` defaults to `Direct`; the crawler passes
   `StructuredExtraction`, LLM candidates pass `LlmExtraction`.
4. One `AssertRelation` event is committed first. Then `add_evidence_internal`
   is called once per evidence item, each committing its own `AddEvidence`
   event. There is no transaction spanning the whole loop.
5. `EvidenceInput::validate` checks URI, title, excerpt, content hash, pinned
   CID lengths and serialized metadata size. It does not check that the hash
   starts with `blake3:`, that the CID parses, or that `evidence_type` is known.

## What is durable, rejected, and left behind

Rejected before any event is committed: missing `graph:assert`, oversized
fields or evidence metadata, and more than 20 evidence items. The error is
`InvalidInput` with a byte count. Accepted strings become identifiers even when
they are semantically odd: a bare LLM phrase becomes a `concept:` slug, and any
short predicate string is accepted as written.

Durable after success: the assertion row, its nodes/edge, and one evidence row
per committed evidence item. If a later evidence commit fails, the earlier
assertion and earlier evidence events remain committed; this partial outcome is
Inferred from the separate `commit_event` calls, not executed. A failed
assertion commit happens before the evidence loop and leaves no new assertion
row from that call.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0148a | Implemented limits and validation | `oag-graph/src/assert.rs:12-47`, `49-123` |
| B-0148b | Implemented commit sequence | `oag-graph/src/assert.rs:125-171`; `oag-graph/src/service.rs:158-167` |
| B-0148c | Implemented identifier rules | `oag-graph/src/identifier.rs:1-41` |
| B-0148d | Implemented URL normalization | `oag-core/src/canonicalize.rs:9-66` |
| B-0148e | Test inspection, not executed | `oag-graph/src/identifier.rs:43-71` |

Verification: source and test inspection via `git show origin/main:<path>` at
the stated commit. No assertion was committed.

## Change since the previously explained commit

`identifier.rs` is unchanged between `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`
and `fb54e431332a030a566099c76fb2558084765422`. The changes in `assert.rs` add
best-effort pin recording on evidence and verification counter handling; the
limits, canonicalization call, and assertion-then-evidence loop cited here are
unchanged. Findings 0140-0147 still hold at the newer commit.

## Next investigation

Move away from the crawler path: trace the collisions repository's queue and
eviction behavior in `oag-collisions` at `b19fc44d76c975f22cdd07cfa3bc2e4f60cc4c0b`.
