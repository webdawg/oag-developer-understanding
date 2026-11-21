# 0083 — Backup snapshots the whole database, and pinning uploads that snapshot

Claim `B-083`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, `oag backup`
opens the live database and runs `VACUUM INTO` to the output path. That is a
whole-database snapshot, not a filtered event export. Optional `--pin` reads
the resulting file and sends every byte to the configured IPFS provider.

## Contents and authority

The snapshot includes event canonical payloads, projections, actor key hashes,
peer public keys and addresses, redaction tombstones, and search suppressions.
Raw API keys are not stored, so they are not in the snapshot unless some payload
happens to contain one. Evidence text and identity URIs that remain in events
are included even after projected redaction.

The CLI comment says backup and rebuild are authorized by filesystem access to
the data directory, not by an API key. The command prints success after the
snapshot is written. If pinning is requested and fails, the snapshot still
exists and the command returns an error. The printed CID is explicitly described
as an unverified retrieval pointer.

`VACUUM INTO` is used to avoid copying WAL files inconsistently. Whether it
overwrites an existing output path was not verified. Opening the pool also runs
migrations before the snapshot; that side effect was not separately tested.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-083a | Implemented | `crates/oag-storage/src/backup.rs:1-16` |
| B-083b | Implemented | `crates/oag-cli/src/commands.rs:503-531` and `545-548` |

Verification: source inspection only. No backup was created.

## Next investigation

Trace restore, if one exists, and determine whether a snapshot can be loaded without revalidating signatures or redactions.