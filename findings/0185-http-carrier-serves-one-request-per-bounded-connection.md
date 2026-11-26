# 0185 — Listend HTTP handles one request per bounded connection

Claim `B-0185`: at listend `b87dcac9a3c9e0059d90e698e2ec40fb2769ec41`,
HTTP is a hand-rolled HTTP/1.1 carrier: one request per connection, then close.
It admits at most 64 concurrent connections, bounds each whole connection to
1800 seconds and each I/O operation to 10 seconds, and releases its active
counter through the panic-safe `ActiveGuard`.

## Order of behavior

1. `HttpCarrier::run` creates a 64-permit semaphore, selects between shutdown
   and `listener.accept()`, and skips accept errors. A new connection waits for
   a permit before its task is spawned.
2. The task holds the permit and an `ActiveGuard`, then calls
   `serve_connection` with the 1800-second `REQUEST_TIMEOUT`. The guard replaces
   the older manual increment/decrement pair, so a panic cannot leave the active
   count permanently raised.
3. `serve_connection` wraps the entire read/route/write future in the timeout.
   `serve_connection_inner` reads one request; a clean EOF returns without a
   response. `OPTIONS` is answered immediately with a wildcard CORS preflight
   because the service has no credentials.
4. After `route` builds the response, `write_response` sends it under the I/O
   timeout. If the request body was not consumed, the connection is half-closed
   and up to `MAX_BODY_BYTES` of body is drained so TCP does not reset and
   discard the response already written.
5. Head size is capped at 16 KiB; body size is the native frame cap minus four
   bytes. POST bodies go through `accept_and_mirror`, the same entry point used
   by other carriers. The root response reports current bytes as "audio +
   declared types".

## What is durable, rejected, and left behind

Durable: HTTP itself stores no session state; accepted audio is stored by the
shared audio surface. Rejected: oversized heads/bodies, malformed heads,
non-audio publishes, and route-specific errors become HTTP responses. A total
or I/O timeout ends the connection without a crafted error body.

There is no keep-alive, chunked transfer encoding, or TLS. Wildcard CORS and
the absence of credentials are deliberate for a public audio service, not an
authentication mechanism. A drained unread body is discarded. No HTTP listener
or target test was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0185a | Implemented carrier limits and accept loop | `crates/oag-listend/src/http.rs:32-43`, `92-115` |
| B-0185b | Implemented per-connection timeout and body drain | `crates/oag-listend/src/http.rs:118-185` |
| B-0185c | Implemented request fields and routes | `crates/oag-listend/src/http.rs:187-203`, `441-455` |
| B-0185d | Implemented active guard | `crates/oag-listend/src/server.rs:32-50` |
| B-0185e | Compared change | `git diff aad2d9b2..b87dcac9 -- crates/oag-listend/src/http.rs` |

Verification: source inspection via `git show origin/master:<path>` and a scoped
diff. No listener, HTTP client, or target test was executed.

## Change since the previously explained commit

At `aad2d9b2cc763239764fa8ba11ec7e871be00e11`, the HTTP session functions were
concrete over `TcpStream` and the active counter used manual arithmetic. At
`b87dcac9...`, the handler functions are generic over async streams, the
timeout is passed explicitly, and `ActiveGuard` is used. Findings 0181 and 0183
describe the generated ping and parser called by this loop; neither is
rewritten here.

## Next investigation

Trace `oag_listend::http::read_request` head and body rules to document how a
declared length becomes `413`, how malformed heads are distinguished, and what
`unread_body` means for a route.
