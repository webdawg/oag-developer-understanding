# 0153 — Listend directory load is bounded; `--check` is read-only

Claim `B-0153`: at listend `b87dcac9a3c9e0059d90e698e2ec40fb2769ec41`,
startup loading and operator verification share one directory loader with two
modes. A daemon startup creates the directory and unlinks evicted files; a check
creates nothing and unlinks nothing. Both stop at 100,000 audio entries or a
300-second wall-clock deadline and report truncation or timeout rather than
silently ignoring the rest.

## Order of behavior

1. `with_directory` calls `load_dir_impl(..., read_only=false, LOAD_DEADLINE)`;
   `check_directory` passes `read_only=true`. The non-check mode starts with
   `create_dir_all`; the check mode treats a missing directory as an error.
2. Before each directory entry, the loader compares `Instant::now()` with the
   deadline. The check is above the sidecar filter so a directory of nothing but
   sidecars cannot walk forever. A read already blocked in the kernel is not
   interrupted; the source states that limit explicitly.
3. Entries with an extension are skipped as sidecars. The entry cap counts only
   audio candidates; reaching it sets `truncated`. Non-regular files, names that
   are not 64 ASCII hex digits, and files larger than `servable_bound(max_bytes)`
   are skipped without being read.
4. A read file must still verify as the BLAKE3 of its own filename and sniff as
   audio. Its `.json` and `.cid` sidecars are read only when they are regular
   files within their byte caps. A valid `.cid` restores the hash-to-CID and
   CID-to-hash maps.
5. Each accepted file goes through `publish`, which enforces both the footprint
   byte bound and `MAX_STORE_ENTRIES` (100,000), evicting oldest first. The
   loader queues evicted audio/JSON/CID paths in `forget`. After the loop, only
   the non-check mode unlinks those paths. `LoadReport` sets `evicted` to
   accepted-minus-retained, and `loaded` to the retained count.

## What is durable, rejected, and left behind

Startup mode changes the directory: evicted files are removed in the same
best-effort way as elsewhere, and a missing directory is created. Check mode
leaves the directory byte-for-byte unchanged while still reporting what a load
would reject or evict. In both modes, bad names, bad hashes, non-audio bytes,
oversized files, unsafe sidecar types, and unreadable entries increment
`skipped`; no error is returned for those individual items.

A truncated or timed-out load leaves later entries untouched and unexamined;
the operator sees `truncated`/`timed_out` in the report. A single stalled
filesystem call can still exceed the deadline because the loader is synchronous;
that is a documented limit, not an achieved guarantee. No daemon, `--check`
command, or target test was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0153a | Implemented mode split and deadline | `crates/oag-listend/src/lib.rs:131-153`, `462-547` |
| B-0153b | Implemented entry validation and sidecars | `crates/oag-listend/src/lib.rs:548-610`, `1139-1175` |
| B-0153c | Implemented eviction and report | `crates/oag-listend/src/lib.rs:612-623`, `845-886` |
| B-0153d | Implemented bounds | `crates/oag-listend/src/lib.rs:1049-1077`, `426-438` |
| B-0153e | Compared change | `git diff aad2d9b2..b87dcac9 -- crates/oag-listend/src/lib.rs` |

Verification: source inspection via `git show origin/master:<path>` and a scoped
diff. No directory load or target test was executed.

## Change since the previously explained commit

Finding 0108 described startup mirroring at
`aad2d9b2cc763239764fa8ba11ec7e871be00e11`; it did not describe this loader. At
`b87dcac9...`, `check_directory`, `read_only`, `timed_out`, `LOAD_DEADLINE`,
bounded sidecar reads, and the entry cap in `publish`/load are new. Finding 0152
records the related change to the accept path; neither older finding is
rewritten here.

## Next investigation

Trace `mirror_existing_shared` and `offer_shared` to document how the startup
IPFS pass snapshots items, releases the store lock during network calls, and
records timeouts.
