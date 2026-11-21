# 0050 — Node aliases are labels, not globally unique identities

Claim `B-050`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, a node alias
is unique only together with its node ID. Repeating the same node and alias is
ignored, while the same alias text may belong to multiple nodes. Reads list
aliases for a known node; no inspected lookup resolves an alias string to one
node.

## Behavior

The primary key is `(node_id, alias)`. `insert_alias` uses `INSERT OR IGNORE`,
so the first alias type and source assertion remain when the same pair is
repeated. A different node can store the same alias text because node ID is
part of the key. Alias type is not part of that key, so a repeated pair cannot
change from name to URL through this insert.

`list_aliases` filters by node ID and returns all matches. A search of graph and
storage repository code finds no `WHERE alias = ?` reverse lookup. Search uses
the node FTS index instead. Therefore an alias can enrich a known node, but it
does not by itself select or prove a canonical node.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-050a | Implemented schema | `crates/oag-storage/migrations/0001_init.sql:54-60` |
| B-050b | Implemented insert and list | `crates/oag-storage/src/repo/nodes.rs:120-153` |
| B-050c | Absence in searched reads | Repository search found no alias-to-node query outside insert/list/rebuild |

Verification: source inspection and search only. No database test was run.

## Next investigation

Trace lexical search, including FTS query construction and search suppression, to determine what a read query can disclose or hide.