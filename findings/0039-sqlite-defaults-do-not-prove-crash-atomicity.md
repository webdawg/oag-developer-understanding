# 0039 — SQLite defaults do not by themselves prove crash atomicity

Claim `B-039`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, `open_pool`
configures SQLite WAL mode, foreign keys, a five-second busy timeout, and at
most eight connections, then runs embedded migrations. Local commit and remote
ingestion use `pool.begin()` and `tx.commit()`, but this repository does not
explicitly issue `BEGIN IMMEDIATE` in those functions.

## What the code establishes

Both event paths perform their reads, insertion, projection, and origin update
through one sqlx transaction value and return success only after `commit`
succeeds. If an error occurs before that call, the function returns an error
and does not report success. That is necessary but not sufficient evidence for
crash recovery: no test in this finding kills the process during commit, checks
rollback after power loss, or inspects sqlx's generated transaction statement.

The five-second busy timeout changes lock-waiting behavior but does not replace
the process-local `commit_lock`. Multiple processes can still use the same
database through separate pools. Their interaction remains untested.

WAL mode is a journaling configuration, not a claim that every write has been
synchronized to stable storage. The inspected options do not set an explicit
`synchronous` level, so that durability setting remains the SQLite/sqlx default
and was not verified here.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-039a | Implemented | `crates/oag-storage/src/pool.rs:13-28` |
| B-039b | Implemented transaction use | `crates/oag-events/src/commit.rs:33` and `97`; `ingest.rs:77` |

Verification: source inspection only. No database or crash test was run.

## Next investigation

Inspect the events table schema and origin-head update statement to determine which constraints prevent duplicate sequences or gaps.