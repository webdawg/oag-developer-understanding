# 0190 — Listend installs stop signals before serving and drains in two phases

Claim `B-0190`: at listend `b87dcac9a3c9e0059d90e698e2ec40fb2769ec41`,
`main` registers SIGINT/SIGTERM before printing any listening state, opens or
checks the store, binds optional carriers, seeds only an empty library, spawns
every carrier, and only then starts the best-effort IPFS mirror. On a stop
signal it asks all carriers to stop accepting, waits up to five seconds for each
run task, then waits up to two seconds for in-flight sessions to drain.

## Order of behavior

1. Argument parsing defaults to the native TCP listener on `0.0.0.0:7100`;
   HTTP, UDP, Unix, directory, IPFS API, and optional Reticulum are opt-in.
   `--check` prints a store report and returns before any bind or mirror.
2. Signal futures are constructed before store opening and before any
   "listening" output. On Unix they use eagerly registered signal streams so an
   early Ctrl+C or SIGTERM is not handled by the default terminate action.
3. The store is opened with `with_directory` or `check_directory` when a
   directory is supplied, otherwise in memory. A startup report names
   truncation/timeout. A probe file checks writability without trusting mode
   bits.
4. An IPFS publisher is installed into the store before wrapping it in
   `Arc<Mutex<_>>`. Native, HTTP, UDP, Unix, and optional Reticulum listeners
   bind next; each failure prints a requirement-oriented message and exits 1.
   Non-loopback binds get a plain notice.
5. Unless `--no-generate`, `publish_generated` seeds an empty store with three
   sounds plus the canonical ping; a non-empty store is skipped. The carrier
   tasks are spawned, then the startup mirror runs against the already serving
   store with its 30-second budget.
6. On SIGINT/SIGTERM, main prints a shutdown line and mirror summary, calls
   every carrier's shutdown handle, awaits each run task under a five-second
   timeout, then polls all active counters every 25 ms until zero or a two-second
   grace deadline expires.

## What is durable, rejected, and left behind

Durable: only the store and its sidecars; carrier tasks, sockets, and counters
are process state. `--check` makes no mirror or carrier side effect. Bind
failures stop startup rather than serving with a partially configured set of
carriers. A stop after the grace deadline prints that sessions remain active
and exits anyway, so a client that never reads cannot hold the daemon forever.

The five-second wait is per run task, followed by the separate two-second
session grace. Generated audio and the shared mirror were described in findings
0180 and 0154. No daemon, signal, or target test was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0190a | Implemented argument defaults and check path | `crates/oag-listend/src/main.rs:38-111`, `262-323` |
| B-0190b | Implemented early signal registration | `crates/oag-listend/src/main.rs:217-261` |
| B-0190c | Implemented carrier binds and startup seed | `crates/oag-listend/src/main.rs:325-437` |
| B-0190d | Implemented spawn order and post-bind mirror | `crates/oag-listend/src/main.rs:439-472` |
| B-0190e | Implemented stop sequence and grace | `crates/oag-listend/src/main.rs:474-543` |
| B-0190f | Compared change | `git diff aad2d9b2..b87dcac9 -- crates/oag-listend/src/main.rs` |

Verification: source inspection via `git show origin/master:<path>` and a scoped
diff. No daemon or signal was executed.

## Change since the previously explained commit

At `aad2d9b2cc763239764fa8ba11ec7e871be00e11`, signal futures were installed
after the listening line, the startup mirror used the owned store before
serving, and not every carrier contributed an active counter. At
`b87dcac9...`, those ordering and accounting paths are corrected. Findings 0154
and 0180 describe the mirror and generated seed; this finding records the
process lifecycle around them.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining gap from
the journal and revision table.
