# 0189 — The Unix carrier adds only path binding and stale-socket care

Claim `B-0189`: at listend `b87dcac9a3c9e0059d90e698e2ec40fb2769ec41`,
the Unix domain socket carrier does not define a second protocol or audio rule.
It binds a filesystem path, decides whether an existing path is a stale socket,
and then runs every connection through the same `serve_session` used by TCP:
64 permits, 10-second read/write timeouts, a 1800-second session timeout, and
panic-safe active accounting.

## Order of behavior

1. `bind_shared` checks the path. A regular file or directory is refused rather
   than deleted. A socket that accepts a connection is treated as a live daemon
   and refused; only a socket that fails to connect is removed as stale.
2. It binds a fresh `UnixListener`, stores the path, and creates a fresh active
   counter and shutdown channel.
3. `run` selects between shutdown and `listener.accept()`. Each accepted stream
   waits for a semaphore permit, then spawns a task holding the permit and an
   `ActiveGuard`.
4. The task calls `serve_session` with the TCP carrier's read timeout, write
   timeout, frame cap, and `SESSION_TIMEOUT`. The protocol decode and audio
   rule are therefore identical on Unix and TCP.
5. After shutdown breaks the accept loop, the carrier unlinks its socket file
   so a later start does not find a dead path.

## What is durable, rejected, and left behind

Durable: the socket path is filesystem state, removed on clean shutdown. A
stale socket is removed at bind; a non-socket path is never overwritten, and a
live daemon's socket is not stolen. Rejected sessions end through the same
frame/protocol errors as TCP, without a carrier-specific rule.

Permissions on the socket path decide who can connect; the frame protocol adds
no separate caller authentication. A crash may still leave a socket file, but
the next bind's connect probe identifies and removes it. No daemon, socket, or
target test was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0189a | Implemented bind and stale-socket policy | `crates/oag-listend/src/unix.rs:1-8`, `37-75` |
| B-0189b | Implemented accept loop and shared session call | `crates/oag-listend/src/unix.rs:95-129` |
| B-0189c | Implemented shared session bounds | `crates/oag-listend/src/server.rs:21-31`, `227-247` |
| B-0189d | Compared guard change | `git diff aad2d9b2..b87dcac9 -- crates/oag-listend/src/unix.rs` |

Verification: source inspection via `git show origin/master:<path>` and a scoped
diff. No socket or target test was executed.

## Change since the previously explained commit

At `aad2d9b2cc763239764fa8ba11ec7e871be00e11`, the Unix task used manual
`fetch_add`/`fetch_sub` and did not pass `SESSION_TIMEOUT` into the spawned
session. At `b87dcac9...`, `ActiveGuard` and the explicit timeout argument are
used. Findings 0182 and 0183 describe the shared session and frame rules; this
finding records the Unix-specific binding around them.

## Next investigation

Trace `oag_listend::main` carrier startup and shutdown ordering to document
which listeners are spawned, what startup sounds are published, and how a
clean stop drains active sessions.
