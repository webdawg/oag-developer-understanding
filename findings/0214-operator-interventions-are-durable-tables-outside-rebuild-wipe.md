# 0214 — Operator interventions are durable tables outside the rebuild wipe

Claim `B-0214`: at core `fb54e431332a030a566099c76fb2558084765422`, evidence
redactions, actor identity-URI redactions, and node search suppressions are
stored in dedicated tables that projection rebuild does not wipe. Rebuild
reapplies the two redactions after replaying events; suppression remains a live
filter over the search query.

## Order of behavior

1. Evidence `redactions` rows hold an event ID, timestamp, and optional reason.
   `insert` is a plain `INSERT`; the service checks `exists` first so a repeated
   redaction becomes a conflict rather than a duplicate row.
2. `actor_identity_uri_redactions` rows hold actor ID, timestamp, and reason
   with the same insert/exists/list pattern.
3. `search_suppressions` rows hold node ID and timestamp. `suppress` uses
   `INSERT OR IGNORE`, so a repeat keeps the first timestamp without error;
   `unsuppress` deletes the row; `is_suppressed` answers a membership check.
4. All three modules expose `list_all` for the combined audit view. None of
   those queries has an explicit `ORDER BY`.
5. `rebuild_projection` clears derived graph tables, replays events, then reads
   the redaction tombstone tables and reapplies their field-blanking effects.
   It does not clear these tables, and suppression is not replayed because it is
   already a separate live filter.

## What is durable, rejected, and left behind

Durable: the operator decisions survive restart and rebuild. Evidence/actor
redactions are effectively one-way at this layer — there is no unredact
function — while suppression is explicitly reversible. Rejected: duplicate
redactions are caught at the service layer; duplicate suppression is a no-op.

These tables do not erase the signed event log or replicated copies. Their role
is local scrubbing and local search visibility, with enough tombstone data to
reapply the decision after projection is regenerated. No redaction or rebuild
was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0214a | Implemented evidence tombstone storage | `crates/oag-storage/src/repo/redactions.rs:1-57` |
| B-0214b | Implemented actor tombstone storage | `crates/oag-storage/src/repo/actor_redactions.rs:1-59` |
| B-0214c | Implemented suppression storage | `crates/oag-storage/src/repo/search_suppressions.rs:1-64` |
| B-0214d | Implemented rebuild reapplication | `crates/oag-graph/src/rebuild.rs:53-75` |
| B-0214e | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-storage/src/repo/redactions.rs crates/oag-storage/src/repo/actor_redactions.rs crates/oag-storage/src/repo/search_suppressions.rs` (no output) |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No endpoint, migration, or rebuild was executed.

## Change since the previously explained commit

These operator-state tables are unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Findings 0051, 0055, 0056, and 0057
describe their effects; this finding records the shared storage and rebuild
boundary.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining gap from
the journal and revision table.
