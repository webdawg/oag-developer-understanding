# 0202 — Node identity freezes the first projection metadata

Claim `B-0202`: at core `fb54e431332a030a566099c76fb2558084765422`, a
`NodeId` is `BLAKE3("OAG:NODE:v1:" || canonical_identifier)`. The projector
inserts a node only if that derived ID is absent; later assertions with the same
canonical identifier reuse the row and leave its first node type, name,
description, metadata, and creation time unchanged.

## Order of behavior

1. `GraphService::assert` calls `canonicalize_value` on subject and object.
   HTTP(S) strings become `url:<canonicalized>`; an explicit space-free scheme
   is lowercased; other text is lowercased, whitespace-joined with hyphens, and
   prefixed `concept:`.
2. `canonical_identifier(kind, value)` lowercases the kind and formats
   `kind:value`. `NodeId::from_canonical_identifier` hashes those UTF-8 bytes
   with the `OAG:NODE:v1:` domain prefix.
3. `project_assert_relation` resolves each identifier through
   `resolve_or_create_node`. If `nodes::get_by_id` is `None`, it constructs and
   inserts a `Node` with the event's `created_at`; otherwise it returns the ID.
4. `nodes::insert_if_missing` uses `INSERT OR IGNORE` keyed by `node_id`. A
   concurrent or repeated insert cannot overwrite the first row.
5. The event log still contains every later assertion. Only the thin node
   projection is reused; aliases and edges can still be added around that node.

## What is durable, rejected, and left behind

Durable: the first node row's descriptive fields and timestamp. A later source
that canonicalizes to the same identifier cannot change them through assertion
projection. This matters when two crawled sources provide different names for
the same URL: the first name wins in the node row, while aliases remain a
separate mechanism.

Rejected: nothing in `NodeId::from_canonical_identifier` validates the string;
even an empty string hashes to a valid ID. Input validation happens earlier in
the service where applicable. A failed projection transaction leaves no new
node row. No node was inserted in this pass.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0202a | Implemented NodeId derivation and domain prefix | `crates/oag-core/src/ids.rs:6-24`, `136-152` |
| B-0202b | Implemented identifier canonicalization | `crates/oag-graph/src/identifier.rs:1-42`; `crates/oag-core/src/canonicalize.rs:68-80` |
| B-0202c | Implemented projector resolution | `crates/oag-events/src/projector.rs:78-89` |
| B-0202d | Implemented insert-if-missing | `crates/oag-storage/src/repo/nodes.rs:74-97` |
| B-0202e | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-core/src/ids.rs crates/oag-events/src/projector.rs crates/oag-storage/src/repo/nodes.rs` (no output) |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No projection or database write was executed.

## Change since the previously explained commit

The node identity and insertion code is unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Finding 0148 described the
canonicalization rules; this finding records their effect on node identity and
first-write metadata.

## Next investigation

Trace `oag_storage::repo::nodes::list_aliases` and alias insertion to document
how aliases accumulate without changing the canonical node row.
