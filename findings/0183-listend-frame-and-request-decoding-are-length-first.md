# 0183 — Listend frame and request decoding are length-first

Claim `B-0183`: at listend `b87dcac9a3c9e0059d90e698e2ec40fb2769ec41`, the
native carrier reads a four-byte big-endian length and rejects an oversized
frame before allocating its body. Request fields are read through a checked
cursor; a fetch hash must be 64 ASCII hex digits and is lowercased before
lookup. These parsers are unchanged from `aad2d9b2...`.

## Order of behavior

1. `read_frame` reads up to four prefix bytes with a per-read timeout. A clean
   EOF before any byte ends the session with `None`; a timeout or I/O error
   becomes an error. A partial prefix is filled with bounded `read_exact`.
2. It decodes `len`, rejects `len > max_frame` with `InvalidData(WireError::TooLong)`
   **before** `vec![0u8; len]`, then fills the body under the same read timeout.
3. `decode_frame` enforces the same rule for already-buffered bytes: under four
   bytes is `Truncated`, an over-cap declared length is `TooLong` even if the
   buffer is shorter, and only a complete body is returned.
4. `decode_request` reads an opcode. `Hello` and `Ping` consume only that byte;
   `List` reads offset and limit; `Publish` reads an optional declared media
   type and treats the remaining body as audio bytes; `Fetch` reads a hash.
5. The `Reader` uses `checked_add` for every take. Strings read a `u16` length,
   refuse it when longer than the remaining buffer, and require UTF-8.
   `opt_string` treats length zero as `None`. `hash` requires exactly 64 hex
   bytes and returns the lowercase form; a shape error becomes the distinct
   `BadHash` wire error.

## What is durable, rejected, and left behind

Durable: decoded requests are in-memory values; the parser writes no store
state. Rejected: truncated or oversized frames, timeouts, unknown opcodes, bad
string lengths/UTF-8, and wrong-shape hashes. `BadHash` is special at the
session loop: it receives a `Response::Rejected` and keeps the connection open
so a client can retry. Other errors shut the stream down.

Trailing bytes after `Hello` or `Ping` are not checked because those branches
consume no more fields. An empty declared media type is read as absent, not as
an empty `Some`. No socket, malformed frame fixture, or target test was
executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0183a | Implemented stream frame reading | `crates/oag-listend/src/server.rs:372-403` |
| B-0183b | Implemented buffered frame check | `crates/oag-listend/src/protocol.rs:145-167` |
| B-0183c | Implemented checked cursor and hash | `crates/oag-listend/src/protocol.rs:189-254` |
| B-0183d | Implemented request opcodes | `crates/oag-listend/src/protocol.rs:293-316` |
| B-0183e | Unchanged since explained commit | `git diff aad2d9b2..b87dcac9 -- crates/oag-listend/src/protocol.rs crates/oag-listend/src/server.rs` (no relevant output) |

Verification: source inspection via `git show origin/master:<path>` and a
scoped diff. No target test or network request was executed.

## Change since the previously explained commit

The frame cap and request parser are unchanged between
`aad2d9b2cc763239764fa8ba11ec7e871be00e11` and
`b87dcac9a3c9e0059d90e698e2ec40fb2769ec41`. Finding 0182 covers the session
bounds around this parser; this finding documents the parser itself.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining gap across
the tracked source heads.
