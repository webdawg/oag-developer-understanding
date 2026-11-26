# 0172 — Pin discovery is a durable record, not a live availability check

Claim `B-0172`: at core `fb54e431332a030a566099c76fb2558084765422`,
`GET /api/v1/pins` answers from a `pinned_cids` table. A `holds: true` response
means this peer once recorded that CID, not that the bytes are currently
retrievable. Listing is bounded, newest first, and the table is a separate index
fed by every local pinning path plus a one-time evidence backfill.

## Order of behavior

1. `record_pin(cid, source)` checks only CID byte length (128 max), then inserts
   into `pinned_cids`. `ON CONFLICT(cid) DO UPDATE SET pinned_at = excluded.pinned_at`
   refreshes the timestamp and keeps the original `source`.
2. Source strings distinguish `evidence`, `cli-pin`, `backup-pin`, and
   `host-page`. The source is operator metadata, not a permission or trust
   signal.
3. `list_pins(limit)` clamps the caller's limit to `[0, 1000]` at the service
   layer; default callers use 100. Storage orders by `pinned_at DESC, cid ASC`
   and returns only the CID strings to the service.
4. `holds_pin(cid)` runs `SELECT COUNT(*) ... WHERE cid = ? LIMIT 1` with no CID
   format validation. `pin_count()` counts distinct rows. The REST handler
   requires `graph:read`; `?cid=` returns `{"cid", "holds"}`, otherwise it
   returns `{"pins", "total", "limit"}`.
5. Migration `0015_pinned_cids.sql` creates the table and backfills from
   `evidence.metadata`'s `ipfs_cid` key, using `MAX(COALESCE(retrieved_at, 0))`
   per CID and `INSERT OR IGNORE` so reruns do not duplicate rows.

## What is durable, rejected, and left behind

Durable: one row per recorded CID with timestamp and originating source. The
backfill preserves older evidence pins across upgrade. Nothing in this path
fetches from IPFS, checks a daemon's current pin set, or removes a row when
content is garbage-collected; a stale `holds: true` is expected behavior and is
documented as a pointer rather than a guarantee.

Rejected: `record_pin` with a CID over the length bound. `holds_pin` and
`list_pins` do not validate CID syntax, so a structurally odd string can be
reported if a row exists. A list limit outside the range is clamped rather than
rejected. No pin route, migration, or target test was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0172a | Implemented service helpers | `crates/oag-graph/src/pins.rs:1-67` |
| B-0172b | Implemented storage queries | `crates/oag-storage/src/repo/pinned_cids.rs:1-68` |
| B-0172c | Implemented schema and backfill | `crates/oag-storage/migrations/0015_pinned_cids.sql:1-25` |
| B-0172d | Implemented REST surface | `crates/oag-api/src/handlers.rs:308-337` |
| B-0172e | Test inspection, not executed | `crates/oag-storage/src/repo/pinned_cids.rs:70-139` |
| B-0172f | New since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-graph/src/pins.rs crates/oag-storage/src/repo/pinned_cids.rs` |

Verification: source and test inspection via `git show origin/main:<path>` and a
scoped diff. No HTTP request or migration was executed.

## Change since the previously explained commit

`pins.rs`, `pinned_cids.rs`, migration 0015, and the `/api/v1/pins` handler are
new at `fb54e431...` relative to explained `87f9e8c1...`. Finding 0140 already
noted that crawler evidence passes a `pinned_cid`; this finding documents the
durable discovery index and its limits.

## Next investigation

Trace `oag_graph::redaction::GraphService::redact_evidence` to document what is
removed from which table, what remains in the signed event log, and what a
rebuild reapplies.
