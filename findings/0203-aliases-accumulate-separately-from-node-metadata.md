# 0203 — Aliases accumulate separately from node metadata

Claim `B-0203`: at core `fb54e431332a030a566099c76fb2558084765422`, a node
alias is a separate `node_aliases` row keyed by `(node_id, alias)`. Declaring an
alias never changes the `nodes.name`/description row. Repeating the same alias
text is ignored, even with a different alias type, because `alias_type` is not
part of the primary key.

## Order of behavior

1. `GraphService::declare_alias` requires `graph:assert`, checks the alias byte
   length (512), and commits a signed `NodeAlias` event. It does not check the
   node itself; the caller is expected to assert something about a new node
   first.
2. `project_node_alias` parses the node ID, requires that node to exist, and
   maps the alias type string to one of `name`, `url`, `urn`, `package`,
   `external_id`, or `acronym`. An unknown type is an
   `UnknownExtractionMethod` error and aborts projection.
3. `insert_alias` writes with `INSERT OR IGNORE`. The schema primary key is
   `(node_id, alias)`, so the first row's `alias_type` and `source_assertion`
   survive later duplicate declarations.
4. The projection currently sets `source_assertion: None`; the column exists but
   this event does not link the alias back to an assertion ID.
5. `list_aliases` selects rows by `node_id` with no `ORDER BY`, so the returned
   alias order is unspecified. Aliases do not create or merge nodes; they only
   annotate an existing `NodeId`.

## What is durable, rejected, and left behind

Durable: distinct alias rows attached to the node; the first declaration wins
for a repeated alias string. Rejected: missing `graph:assert`, overlong alias,
unknown node at projection, or unknown alias type. A duplicate is not an error
and leaves no new row.

Because `nodes.name` is frozen by first projection (finding 0202), aliases are
the mechanism for later names. They are not a global identity lookup: the same
alias text on two different node IDs creates two rows. No event was committed
or alias read in this pass.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0203a | Implemented service declaration | `crates/oag-graph/src/assert.rs:222-248` |
| B-0203b | Implemented projection | `crates/oag-events/src/projector.rs:363-383` |
| B-0203c | Implemented storage and schema key | `crates/oag-storage/src/repo/nodes.rs:121-155`; `crates/oag-storage/migrations/0001_init.sql:54-60` |
| B-0203d | Unchanged alias behavior | `git diff 87f9e8c1..fb54e431 -- crates/oag-storage/src/repo/nodes.rs crates/oag-events/src/projector.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No event or database query was executed.

## Change since the previously explained commit

Alias behavior is unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`; the changed regions in those files
are search additions and verification counters. Finding 0050's global-identity
boundary still holds; this finding records storage detail and first-write
behavior.

## Next investigation

Trace how `oag-api/src/human.rs` renders node aliases, and whether the UI can
show the alias type or source that storage keeps.
