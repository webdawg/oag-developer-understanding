# 0221 — Node types are open, but alias types are closed

Claim `B-0221`: at core `fb54e431332a030a566099c76fb2558084765422`,
`NodeType` is an extensible string newtype, while `AliasType` is a closed six
value enum. Unknown node types pass through; unknown alias types fail parsing
and therefore fail `NODE_ALIAS` projection.

## Order of behavior

1. `NodeType::new` trims and lowercases raw text. `KNOWN_NODE_TYPES` lists
   conventional values (`url`, `document`, `website`, `software`, `concept`,
   `peer`, `unknown`, and others) but is documentation/helpers, not a validator.
2. `Node::new` derives `NodeId` from the canonical identifier and initializes
   `canonical_uri`, `name`, and `description` to `None`, and metadata to an
   empty JSON object.
3. `AliasType` accepts exactly `name`, `url`, `urn`, `package`, `external_id`,
   and `acronym` in snake_case. `parse` returns `None` for anything else.
4. `NODE_ALIAS` projection maps the payload string through `AliasType::parse`
   and rejects an unknown value before inserting an alias row (finding 0203).
5. The source distinguishes node type `peer` (`peer:<PeerId>` as a subject or
   object) from `ActorType::Peer` (an actor that submitted something).

## What is durable, rejected, and left behind

Durable: the normalized node type string on the node row and one of six alias
type strings on alias rows. Rejected: unknown alias types, because they cannot
be represented; unknown node types are preserved after lowercase/trim.

The asymmetry is deliberate in the source comments: the relationship
vocabulary must remain extensible, while alias display categories are a fixed
set understood by storage and UI. No node or alias was created in this pass.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0221a | Implemented open node type | `crates/oag-core/src/node.rs:8-75` |
| B-0221b | Implemented node construction | `crates/oag-core/src/node.rs:77-117` |
| B-0221c | Implemented closed alias type | `crates/oag-core/src/node.rs:119-160` |
| B-0221d | Implemented projection rejection | `crates/oag-events/src/projector.rs:363-383` |
| B-0221e | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-core/src/node.rs` (no output) |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No node or alias was written.

## Change since the previously explained commit

Node and alias types are unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Finding 0203 records the alias
storage behavior; this finding records the type vocabularies behind it.

## Next investigation

Trace `oag_core::actor::ActorType` and `Permission` to document actor kinds and
the permission strings used by REST/MCP authentication.
