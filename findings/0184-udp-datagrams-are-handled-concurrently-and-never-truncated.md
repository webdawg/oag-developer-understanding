# 0184 — Listend UDP requests are concurrent and oversized replies are rejected

Claim `B-0184`: at listend `b87dcac9a3c9e0059d90e698e2ec40fb2769ec41`,
each UDP datagram is copied out of the shared receive buffer and handled in its
own bounded task. A reply larger than one datagram is converted into a typed
rejection instead of being silently truncated. This replaced inline handling
that could block all other datagrams behind one slow mirror.

## Order of behavior

1. `UdpCarrier::run` creates a 64-permit semaphore, subscribes to shutdown, and
   allocates one 65,507-byte receive buffer. `recv_from` yields bytes and the
   sender address; the bytes are copied into an owned vector before the loop
   receives again.
2. After acquiring a permit, the carrier clones the store, socket, and active
   counter, and spawns a task. The task holds the permit and an `ActiveGuard`,
   so concurrency and in-flight accounting are released on return, error, or
   panic.
3. `handle` calls `decode_frame` and `decode_request`; either parse error
   becomes `Response::Rejected`. Hello, Ping, List, Fetch, and Publish use the
   same store surface as the other carriers. List clamps its page to 900
   hashes, with zero meaning the default list limit.
4. The response is encoded and framed. If the framed response exceeds
   `MAX_DATAGRAM_BYTES`, `handle` replaces it with a `Rejected` reason naming
   both sizes. Only a frame that fits is sent back, under a 10-second timeout.
5. Shutdown changes the watch channel and the loop breaks; already running
   tasks keep their owned clones and permit until they finish or panic.

## What is durable, rejected, and left behind

Durable: accepted publishes are stored by the normal `accept_and_mirror` path;
the carrier itself stores no session data. Rejected: malformed frames/requests,
bad hashes, non-audio publishes, store errors, and replies too large for a
datagram all become typed rejection responses. A `send_to` timeout is ignored
after the response is built; this carrier has no retransmission, ordering, or
delivery guarantee.

The source comment records 9.70 s of head-of-line blocking before this change;
that is documented intent here, not a measurement reproduced in this pass.
The peer address comes from `recv_from` and is used only as the reply target;
no peer identity is authenticated by this carrier. No socket was opened and no
target test was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0184a | Implemented datagram loop | `crates/oag-listend/src/udp.rs:25-35`, `85-126` |
| B-0184b | Implemented request handling and size rejection | `crates/oag-listend/src/udp.rs:129-217` |
| B-0184c | Implemented list normalization | `crates/oag-listend/src/protocol.rs:59-65` |
| B-0184d | Implemented shared active guard | `crates/oag-listend/src/server.rs:32-50` |
| B-0184e | Compared change and documented rationale | `git diff aad2d9b2..b87dcac9 -- crates/oag-listend/src/udp.rs` |

Verification: source inspection via `git show origin/master:<path>` and a scoped
diff. No UDP socket or target test was executed.

## Change since the previously explained commit

At `aad2d9b2cc763239764fa8ba11ec7e871be00e11`, UDP handling was inline in the
receive loop with a plain `UdpSocket`. At `b87dcac9...`, the socket is
`Arc<UdpSocket>`, handling is spawned under a 64-permit semaphore, and an
`ActiveGuard` tracks tasks for shutdown. Findings 0181 and 0183 describe the
generated ping bytes and the frame parser this carrier uses; neither is
rewritten here.

## Next investigation

Trace `oag_listend::http::HttpCarrier::run` at the same head to document HTTP
connection concurrency, timeouts, and shutdown behavior.
