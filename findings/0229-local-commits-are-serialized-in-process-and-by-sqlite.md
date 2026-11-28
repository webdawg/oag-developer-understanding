# 0229 — Local commits are serialized in-process and by SQLite

Claim `B-0229`: at core `fb54e431332a030a566099c76fb2558084765422`,
`GraphService::commit_event` holds a process-local Tokio mutex around
`commit_local_event`. The latter now opens `BEGIN IMMEDIATE`, so the mutex is no
longer the primary fix for concurrent same-peer commits; the source comment
calls it defence in depth.

## Order of behavior

1. Every `GraphService` mutation is expected to go through `commit_event`; the
   method takes `commit_lock`, then calls `commit_local_event`.
2. `commit_local_event` opens `BEGIN IMMEDIATE`, reads this peer's origin row,
   derives the next sequence and previous head, signs a new event, and inserts
   it before projecting.
3. Projection, event references, and origin-head advancement occur in the same
   transaction. A duplicate insert returns an error rather than guessing a new
   sequence.
4. `tx.commit()` is the single commit point; an earlier `?` leaves the
   transaction uncommitted.
5. The mutex only covers calls through one `GraphService` instance in one
   process. Separate processes or a direct `commit_local_event` caller rely on
   SQLite's transaction lock.

## What is durable, rejected, and left behind

Durable after success: one signed event with contiguous sequence, its derived
projection, refs, and advanced origin head. Rejected: duplicate event insertion
(or other errors) aborts before commit; no partial sequence advance is visible.

The source comment records measured concurrency improvements from switching to
`BEGIN IMMEDIATE`; those measurements were not reproduced here. At the older
explained commit the mutex comment described the race as live. The newer code
says the cause is fixed and keeps the mutex as defence in depth. No event was
committed in this pass.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0229a | Implemented service serialization | `crates/oag-graph/src/service.rs:74-96`, `158-167` |
| B-0229b | Implemented transactional commit | `crates/oag-events/src/commit.rs:25-45`, `63-94` |
| B-0229c | Documented measurement in comment | `crates/oag-graph/src/service.rs:89-95` |
| B-0229d | Changed transaction and comment | `git diff 87f9e8c1..fb54e431 -- crates/oag-graph/src/service.rs crates/oag-events/src/commit.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No event was committed.

## Change since the previously explained commit

Between `87f9e8c1...` and `fb54e431...`, `commit_local_event` changed from a
deferred `pool.begin()` to `BEGIN IMMEDIATE`, and the `commit_lock` comment was
rewritten to say the race is fixed at its cause. The mutex remains. This is a
correction finding for the earlier lock description, not a rewrite of it.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining gap from
the journal and revision table.
