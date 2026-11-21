# 0031 — Listend publishes only after the local audio write succeeds

Claim `B-031`: at listend `aad2d9b2cc763239764fa8ba11ec7e871be00e11`,
`AudioStore::accept` rejects unrecognized bytes and oversized bytes before
storage. For a new directory-backed item, it awaits the audio-byte write before
publishing the item in memory. A media-type sidecar or IPFS mirror failure does
not by itself reject that item.

## Ordered behavior

1. Sniff the bytes. Unrecognized input returns `NotAudio`.
2. Compare the length with `servable_bound(max_bytes)`. Too-large input returns
   `TooLarge` and is not written.
3. Hash the bytes and retain the declared media type as metadata.
4. If the hash is already indexed and directory storage is enabled, restore the
   file when it is absent, then return the existing hash.
5. For a new directory-backed item, create the directory and write bytes under
   the hash. A byte-write failure returns `Persist` before publication.
6. Publish the item, attempt best-effort mirroring, drain eviction paths, and
   return the hash.

The sidecar write is explicitly ignored. The comment says mirroring failure is
recorded but not propagated; the mirror implementation itself was not traced in
this finding. `tokio::fs::write` completion is not a hardware fsync or power-loss
proof. No such durability guarantee is established.

Duplicate admission can restore a missing file, but a failed existence check is
treated as absence and then delegated to `persist`. Concurrent admission through
multiple store instances was not inspected.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-031 | Implemented | `oag-listend/crates/oag-listend/src/lib.rs:550-620` |

Verification: source inspection only.

## Next investigation

Trace collisions indexing and query behavior, especially prefix buckets, eviction,
and the discrepancy between comments and insertion logic.
