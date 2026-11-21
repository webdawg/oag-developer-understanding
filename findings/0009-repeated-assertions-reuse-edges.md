# 0009 — Repeated assertions reuse nodes and edges but add assertion rows

Claim `B-009`: at `open-agent-graph` `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
repeating the same subject, predicate, and object does not create a new edge
ID. It creates a new assertion because every assertion ID is the ID of its
`ASSERT_RELATION` event.

## Identity rules

- A node ID is derived from its canonical identifier. `INSERT OR IGNORE` makes
  node insertion idempotent by that ID.
- An edge ID is derived from subject ID, predicate, and object ID. Its insertion
  is also `INSERT OR IGNORE`, so the first edge's creation timestamp remains.
- An assertion ID aliases the creating event ID. Its repository insert is a
  normal `INSERT`, not an ignore-on-conflict operation.
- Evidence IDs are likewise event IDs. Adding evidence first checks that the
  referenced assertion already exists.

Thus two accepted assertions with the same canonical relationship contribute two
claims about one edge. They are not deduplicated by actor, confidence, time, or
evidence in the inspected projection path. Whether a database constraint rejects
an unexpected duplicate assertion ID depends on the schema and was not inspected
here; the event layer normally supplies distinct IDs.

## Developer consequence

An edge means “this relationship is being discussed,” not “the relationship is
true.” The edge type comment states that distinction, and the projection
implements it by separating reusable edge identity from per-event assertion
rows. Counting edges therefore does not count support. Counting assertions is
required, followed by their status, actor, evidence, disputes, retractions, and
supersession rules.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-009a | Implemented | `crates/oag-core/src/ids.rs:140-164`, `crates/oag-core/src/edge.rs:20-29` |
| B-009b | Implemented | `crates/oag-storage/src/repo/nodes.rs:75-96`, `crates/oag-storage/src/repo/edges.rs:34-49` |
| B-009c | Implemented | `crates/oag-events/src/projector.rs:98-164`, `crates/oag-storage/src/repo/assertions.rs:87-104` |

Verification: source inspection only.

## Next investigation

Trace assertion status transitions for dispute, retraction, and supersession,
including whether old rows remain readable and how repeated status events interact.
