# 0204 — The node page shows alias text and type, not provenance

Claim `B-0204`: at core `fb54e431332a030a566099c76fb2558084765422`, the human
node page renders every stored alias as `<alias> (<alias_type>)` in the order
`list_aliases` returned. The view drops the alias's source assertion, and no
timestamp exists on an alias row, so the page cannot show where or when an alias
was declared.

## Order of behavior

1. `node_page` authenticates the `?key=` query value, parses the node ID, and
   requires the node to exist. It renders `node.name` separately above the
   alias list, so the first-write node name remains the primary display name
   (finding 0202).
2. It calls `list_aliases(node_id)` and maps each `NodeAlias` to `AliasView`
   with only `alias` and `alias_type.as_str()`.
3. The Askama template iterates that vector and emits
   `<li>{{ a.alias }} ({{ a.alias_type }})</li>`; an empty vector prints
   `(none)`. Interpolation is HTML-escaped by default.
4. The `KeyQuery` value is copied into navigation links, but there is no link
   from an alias to a declaring event or assertion.

## What is durable, rejected, and left behind

Durable: the page is a read-only view of alias rows; nothing is written. A
missing node returns 404; invalid or missing keys fail before rendering. The
alias list has no deterministic order because its storage query has no
`ORDER BY`, so two renders can list the same aliases differently.

Source provenance is unavailable on this surface: projection currently stores
`source_assertion: None`, and `AliasView` has no field for it even if a future
row supplied one. No page was rendered in this pass.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0204a | Implemented alias view mapping | `crates/oag-api/src/human.rs:84-87`, `288-314` |
| B-0204b | Implemented template rendering | `crates/oag-api/templates/node.html:21-30` |
| B-0204c | Implemented node primary name field | `crates/oag-api/templates/node.html:12-19` |
| B-0204d | Implemented storage order/provenance | `crates/oag-storage/src/repo/nodes.rs:121-155`; `crates/oag-events/src/projector.rs:363-383` |
| B-0204e | Unchanged alias rendering | `git diff 87f9e8c1..fb54e431 -- crates/oag-api/src/human.rs crates/oag-api/templates/node.html` (no alias-region changes) |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No HTTP request or page render was executed.

## Change since the previously explained commit

Alias rendering is unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`; the changed regions in `human.rs`
are search paging. Finding 0203 records the alias storage shape; this finding
records what the human interface chooses to display from it.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining gap from
the journal and revision table.
