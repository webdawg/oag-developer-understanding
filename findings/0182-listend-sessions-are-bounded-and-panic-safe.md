# 0182 — Listend sessions are bounded and release their slot on panic

Claim `B-0182`: at listend `b87dcac9a3c9e0059d90e698e2ec40fb2769ec41`, the
native TCP/Unix accept loop admits at most 64 concurrent sessions, wraps each
session in a 1800-second timeout, and uses an `ActiveGuard` whose `Drop` lowers
the active-session counter even during panic unwinding. This guard replaced a
hand-written decrement that a panic could skip.

## Order of behavior

1. `ListendServer::run` creates a `Semaphore` with `max_connections` permits and
   selects between the shutdown watch channel and `listener.accept()`.
2. Each accepted stream waits for an owned semaphore permit before spawning a
   task, so a full server makes new connections wait rather than exceeding the
   cap. Accept errors are skipped.
3. The spawned task raises the active counter with `ActiveGuard::raise`, then
   calls `serve_session`. The guard and permit are held by scoped variables, so
   they are released on normal return, error, or panic.
4. `serve_session` wraps `serve_session_inner` in
   `tokio::time::timeout(SESSION_TIMEOUT, ...)`, converting expiry into an
   `io::ErrorKind::TimedOut`. Inner reads and writes have separate 10-second
   timeouts.
5. A malformed frame or non-hash protocol error shuts the stream down without a
   reply. A `BadHash` field is special: the loop sends `Response::Rejected` and
   keeps the session alive so a buggy client can correct it.
6. `ShutdownHandle::shutdown` sends on the watch channel; `run()` breaks the
   accept loop on the next select iteration.

## What is durable, rejected, and left behind

Durable: no session state is stored. The semaphore permit and active counter
are process-local and released by RAII. Rejected: requests beyond the frame cap,
read/write timeouts, and most decode errors end the session. A `BadHash` payload
leaves a rejection response and an open session.

The older manual `fetch_add`/`fetch_sub` pair could leave the active count
permanently raised if a session panicked, making every later shutdown wait out
the grace period for a dead session. The new guard closes that accounting path;
a test asserts release during `catch_unwind`, but it was inspected, not run. No
listener or carrier was started.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0182a | Implemented limits and guard | `crates/oag-listend/src/server.rs:21-50` |
| B-0182b | Implemented accept loop | `crates/oag-listend/src/server.rs:188-224` |
| B-0182c | Implemented session timeout and loop | `crates/oag-listend/src/server.rs:227-295` |
| B-0182d | Implemented shutdown handle | `crates/oag-listend/src/server.rs:65-79`, `179-186` |
| B-0182e | Compared change and test inspection | `git diff aad2d9b2..b87dcac9 -- crates/oag-listend/src/server.rs` |

Verification: source and diff inspection via `git show origin/master:<path>`.
No listener, panic test, or target test was executed.

## Change since the previously explained commit

At `aad2d9b2cc763239764fa8ba11ec7e871be00e11`, the active counter used a manual
increment/decrement around `serve_session`, and the session timeout parameter
was not passed through the spawned call. At `b87dcac9...`, `ActiveGuard` and the
explicit timeout argument are new. Findings 0152/0153 describe store bounds and
loading; this finding describes connection lifetime.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining source gap
from the journal and revision table.
