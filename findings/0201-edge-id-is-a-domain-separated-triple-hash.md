# 0201 — Edge ID is a domain-separated triple hash

Claim `B-0201`: at core `fb54e431332a030a566099c76fb2558084765422`, an edge's
identity is `BLAKE3("OAG:EDGE:v1:" || subject_hex || ":" || predicate || ":" ||
object_hex)`. The predicate is already normalized (finding 0200). Actor,
confidence, assertion status, and creation time do not affect the edge ID.

## Order of behavior

1. `Edge::new` calls `EdgeId::from_triple` with the subject `NodeId`, the
   normalized `Predicate::as_str()`, and the object `NodeId`.
2. `from_triple` writes the subject's 64-hex ID, a colon, the predicate bytes, a
   colon, and the object's 64-hex ID into a buffer, then calls
   `EdgeId::derive`.
3. `EdgeId::derive` prefixes `OAG:EDGE:v1:` and hashes with BLAKE3. The same
   domain-separation macro gives other ID kinds their own prefixes, so an edge
   cannot collide with a node or event hash merely by sharing input bytes.
4. `edges::insert_if_missing` uses `INSERT OR IGNORE` keyed by `edge_id`. A
   later assertion with the same triple reuses the existing edge and does not
   overwrite its stored `created_at`.
5. Direction is part of the triple: swapping subject and object changes the
   hash. There is no normalization to an undirected edge.

## What is durable, rejected, and left behind

Durable: the edge row and its first arrival timestamp. Repeated assertions of
the same triple add assertion rows but not edge rows. Rejected: nothing at this
layer for an odd predicate beyond the earlier length check; an empty normalized
predicate still participates in a valid triple hash.

A failed edge insert is ignored by `INSERT OR IGNORE`, so projection continues
with the existing row. If the same triple arrives with a different raw
predicate that normalizes identically, both map to the same edge ID; if they
normalize differently, they are separate edges. No edge was inserted in this
documentation pass.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0201a | Implemented edge construction | `crates/oag-core/src/edge.rs:6-29` |
| B-0201b | Implemented triple encoding and domain prefix | `crates/oag-core/src/ids.rs:6-24`, `72-140`, `154-165` |
| B-0201c | Implemented insert-if-missing | `crates/oag-storage/src/repo/edges.rs:19-50` |
| B-0201d | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-core/src/edge.rs crates/oag-core/src/ids.rs` (no output) |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No assertion or database write was executed.

## Change since the previously explained commit

The edge and identifier code is unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Finding 0148 already noted that
repeated assertions reuse nodes and edges; this finding explains the exact
hash input that makes the reuse deterministic.

## Next investigation

Trace `oag_core::NodeId::from_canonical_identifier` and node insertion to
document which identifier strings converge on one node and what metadata a
repeat insert leaves unchanged.
