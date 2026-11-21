# 0084 — Restore replaces the peer key, not the database snapshot

Claim `B-084`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, a search of
`crates/` finds no command that loads a `VACUUM INTO` snapshot back into the
data directory. `identity_restore` copies a 32-byte `identity.key` file. The
database backup and the peer-key backup are separate files and separate
operations.

## Key restore

The command refuses to overwrite an existing identity unless `--force` is set.
Its error text says overwriting would desynchronize the peer ID from events
already signed by the current key. On Unix it sets the destination mode to
`0600` after copying. `PeerIdentity::load` requires exactly 32 bytes and does
not check that the key signed any existing local events. `load_or_generate`
does not generate a replacement when the copied file exists; an invalid file
returns an error.

A database snapshot therefore does not by itself restore the ability to sign as
the original peer. Conversely, restoring only the key does not restore graph
state. No inspected command verifies a snapshot's event signatures before use.
The backup test opens a snapshot with `open_pool`, but that is a test, not a
user restore path.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-084a | Absence in searched commands | `rg restore crates` found identity restore and a backup test, not database restore |
| B-084b | Implemented | `crates/oag-cli/src/commands.rs:475-498` |
| B-084c | Implemented | `crates/oag-crypto/src/identity.rs:21-46` |

Verification: source inspection and search only. No key or database was restored.

## Next investigation

Trace peer-key generation at first startup and determine where `identity.key` is created, its file mode, and whether a missing file silently creates a new peer identity.