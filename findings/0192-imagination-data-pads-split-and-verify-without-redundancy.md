# 0192 — Imagination data pads split files but add no redundancy

Claim `B-0192`: at imagination `73fadb3ccdc6249fb21d0410e1b5a794be70fe40`,
`datapad` is a local split/reconstruct scheme. A file becomes ordered shards on
named pads; reconstruction checks shard count, contiguous indices, and the
BLAKE3 hash of the concatenated result. There is no erasure coding, replication,
consensus, or transport in this module.

## Order of behavior

1. `split(data, shard_count)` rejects zero shards. It computes
   `shard_size = data.len().div_ceil(shard_count).max(1)`, chunks the bytes, and
   pads the tail with empty shards until exactly `shard_count` shards exist.
2. The manifest stores `file_id` as the BLAKE3 of the whole file, plus
   `shard_count`, `shard_size`, and pad IDs in shard order. `split` uses generic
   `pad-0...` names; `split_to_pads` replaces them with caller-supplied pad IDs.
3. `attach` binds a `Shard` to a `DataPad` with routing weights. The shard is
   carried inside the pad structure; this module does not send it anywhere.
4. `gather` builds a pad-ID map and walks the manifest's pad IDs in order,
   collecting each pad's shard. A missing pad or a pad with no shard returns
   `CountMismatch` with the number of shards collected so far. A duplicate pad
   ID in the input map resolves to the last pad with that ID.
5. `reconstruct` requires the exact shard count, sorts by `shard.index`,
   requires indices `0..shard_count` with no gaps or duplicates, concatenates
   the data, and rejects a result whose BLAKE3 differs from `manifest.file_id`.
6. `NodeUnreachable`, `NotAPad`, and `Transport` errors exist in the error enum,
   but this module contains no carrier code that produces them.

## What is durable, rejected, and left behind

Durable: only the in-memory manifest, shards, and pads built by these pure
functions; there is no store write here. Rejected: zero shards, missing or
out-of-order shards, and hash mismatch. Empty tail shards are legitimate for a
small file and reconstruct exactly.

A missing shard is a failure, not a recoverable loss: the module explicitly is
not erasure coding. The manifest is caller-authored and not agreed by peers, so
a matching hash proves byte identity of the gathered data, not consensus about
where shards should live. Tests inspected cover exact reconstruction, empty
tail shards, missing shards, wrong indices, and a 1000-pad file; they were not
run.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0192a | Implemented split and manifest | `crates/oag-imagination/src/datapad.rs:1-104` |
| B-0192b | Implemented attach and reconstruction | `crates/oag-imagination/src/datapad.rs:106-149` |
| B-0192c | Test inspection, not executed | `crates/oag-imagination/src/datapad.rs:151-224` |
| B-0192d | Unchanged since explained commit | `git diff 7b7dcb8e..73fadb3c -- crates/oag-imagination/src/datapad.rs` (no output) |

Verification: source and test inspection via `git show origin/master:<path>` and
a scoped diff. No test, node, transport, or file operation was executed.

## Change since the previously explained commit

The datapad module is unchanged between
`7b7dcb8eae70b2df2fa1329fdb7b2dd928e76d29` and
`73fadb3ccdc6249fb21d0410e1b5a794be70fe40`. Findings 0028 and 0029 describe
the imagination layer's storage read and seed-dependent routing; this finding
documents its separate file-sharding structure.

## Next investigation

Trace `oag_imagination::socket::serve` and its `PadRequest`/`PadResponse`
handling to document how pads cross the TCP carrier and whether gathering is
wired into a node.
