# 0152 — Listend accept bounds audio and stored metadata separately

Claim `B-0152`: at listend `b87dcac9a3c9e0059d90e698e2ec40fb2769ec41`, an
accepted item must satisfy two different byte limits: the audio alone must fit
a fetch frame, and audio plus its persisted declared media type must fit the
store bound. Every filesystem operation on the accept path has a 60-second
timeout. This is a change from the explained
`aad2d9b2cc763239764fa8ba11ec7e871be00e11`, which checked only raw audio bytes
against the servable bound.

## Order of behavior

1. `accept` first sniffs the bytes for a recognized audio signature; failure is
   `NotAudio` before any hashing or storage. `AudioItem::new` then computes the
   BLAKE3 content hash and trims the declared media type, dropping it when empty
   or longer than `MAX_SIDECAR_BYTES` (4096).
2. The audio bytes are checked against `servable_bound(max_bytes)`, which is
   `min(max_bytes, MAX_FRAME_BYTES - 256)`. `MAX_FRAME_BYTES` is 16 MiB; the
   reserve lets the hash, length prefix, and optional CID fit in one reply.
3. The item's `footprint()` — `bytes.len() + media_type.len()` — is then checked
   against `max_bytes` itself. This prevents a small audio file with a large
   declared type from defeating the on-disk bound. The media type is persisted
   as `<hash>.json` beside the audio.
4. For a duplicate hash, the store stats the durable audio file under a
   `STORAGE_TIMEOUT` (60 s). A timeout, error, or missing file is treated as
   absent, and the existing item is re-persisted under the same timeout before
   the successful duplicate response.
5. For a new item, `persist` writes the audio and then best-effort sidecar under
   the timeout. A failed or timed-out audio write becomes `Persist` before the
   item is published in memory. A sidecar write failure is ignored. IPFS mirroring
   happens after the local write, and evicted files are unlinked under the same
   timeout.

## What is durable, rejected, and left behind

Rejected: non-audio bytes, audio over the frame/servable bound, footprint over
the store bound, and a durable write that fails or does not answer in 60 seconds.
The error carries the measured length and applicable bound, but not rejected
content. A sidecar write failure leaves audio durable and answerable without its
declared type; the next directory load simply reads no media type.

A timed-out `tokio::fs::write` has no shown cleanup, so whether a partial file
remains on disk is Unknown; the in-memory publish is not reached on that path.
Eviction removes an item from the index and queues its audio/JSON/CID files for
bounded unlinking; a failed unlink is best-effort. No target test or filesystem
fault was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0152a | Implemented item bounds | `crates/oag-listend/src/lib.rs:58-105`, `121-129`, `426-438` |
| B-0152b | Implemented accept path | `crates/oag-listend/src/lib.rs:626-711` |
| B-0152c | Implemented bounded filesystem helpers | `crates/oag-listend/src/lib.rs:1064-1077`, `1083-1135` |
| B-0152d | Implemented frame reserve | `crates/oag-listend/src/protocol.rs:19`, `49-53` |
| B-0152e | Compared change | `git diff aad2d9b2..b87dcac9 -- crates/oag-listend/src/lib.rs` |

Verification: source inspection via `git show origin/master:<path>` and a scoped
diff. No daemon, carrier, or target test was run.

## Change since the previously explained commit

Finding 0030 described the old `accept` order at
`aad2d9b2cc763239764fa8ba11ec7e871be00e11`: sniff, one servable byte bound,
then build and persist `AudioItem`. At `b87dcac9...` the sniff remains first and
persistence still precedes the answer, but the item is constructed before the
bounds, there are two bounds, media type length is capped, duplicate restores
are bounded, and all accept-path filesystem operations have the 60-second
timeout. Findings 0030 and 0109 are not rewritten here; this is the correction
finding for those changed details.

## Next investigation

Trace `AudioStore::with_directory`, `check_directory`, and `load_dir_impl` to
document the 300-second load deadline, read-only check mode, and what the
`LoadReport` counts after a partial load.
