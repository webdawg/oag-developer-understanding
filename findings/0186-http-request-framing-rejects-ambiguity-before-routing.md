# 0186 — HTTP request framing rejects ambiguity before routing

Claim `B-0186`: at listend `b87dcac9a3c9e0059d90e698e2ec40fb2769ec41`,
`read_request` validates the header block and body framing before a route is
chosen. A declared body over the frame cap becomes 413; malformed heads,
multiple `Content-Length` headers, and any `Transfer-Encoding` become 400 with
a reason. `Expect: 100-continue` is sent only after those bounds pass.

## Order of behavior

1. The reader accumulates bytes in 1 KiB chunks under a 10-second timeout. A
   clean EOF before a complete head ends the connection without a response.
2. The head cap is checked both at the top of the loop and against the exact
   `pos + 4` blank-line boundary, closing a one-read soft-cap window. An
   oversized head produces a synthetic `BAD` request with
   `unread_body: true` and a specific reason.
3. The first line is split into method and path; either being empty is a bad
   request. Headers are parsed case-insensitively for `Content-Length`,
   `Content-Type`, `Range`, `If-None-Match`, `Transfer-Encoding`, and
   `Expect: 100-continue`.
4. A declared body longer than `MAX_BODY_BYTES` returns `BAD` with
   `too_large: true` before any `100 Continue`. More than one `Content-Length`
   is rejected as ambiguous. Any `Transfer-Encoding` value is rejected; only
   `Content-Length`-framed bodies are supported.
5. If the framing checks pass and `Expect: 100-continue` was present, the
   interim response is written and flushed. The reader then reads until the
   declared length, truncates extra bytes from the same read, and marks
   `unread_body` when the client sent less than declared.
6. `route` turns `too_large` into 413 and a `bad_reason` into 400 before any
   store access. An unread body is drained after the response is written.

## What is durable, rejected, and left behind

Durable: nothing is stored by parsing. Rejected requests are represented as
in-memory `BAD` requests and answered without touching the audio store. The
distinction matters operationally: 413 is a well-formed but oversized publish,
while 400 means the head or framing was malformed or ambiguous.

A short body leaves `unread_body` set; the carrier half-closes and drains what
remains so the already-written response is not lost to a TCP reset. Extra bytes
beyond `Content-Length` are truncated from the parsed body, not preserved for a
second request. No HTTP client or target test was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0186a | Implemented head parsing and cap checks | `crates/oag-listend/src/http.rs:205-268` |
| B-0186b | Implemented header and framing rules | `crates/oag-listend/src/http.rs:268-358` |
| B-0186c | Implemented body read and unread flag | `crates/oag-listend/src/http.rs:359-379` |
| B-0186d | Implemented response mapping | `crates/oag-listend/src/http.rs:406-419` |
| B-0186e | Unchanged rules at newer head | `git diff aad2d9b2..b87dcac9 -- crates/oag-listend/src/http.rs` (only generic-stream signature changes in this block) |

Verification: source inspection via `git show origin/master:<path>` and a scoped
diff. No HTTP request or target test was executed.

## Change since the previously explained commit

The framing rules are unchanged between
`aad2d9b2cc763239764fa8ba11ec7e871be00e11` and
`b87dcac9a3c9e0059d90e698e2ec40fb2769ec41`; `read_request` became generic over
async streams, and the surrounding carrier gained `ActiveGuard` and an explicit
timeout (finding 0185). Findings 0179 and 0183 describe the store sniff and
native frame parser called after routing; neither is rewritten here.

## Next investigation

Re-fetch on the next invocation, then trace `oag_listend::ipfs` fetch/CID
handling for the `GET /ipfs/{cid}` route.
