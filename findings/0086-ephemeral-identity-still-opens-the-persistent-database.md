# 0086 — Ephemeral identity does not isolate the persistent database

Claim `B-086`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
`identity.ephemeral` defaults to false. When true, `oag serve` generates a fresh
in-memory identity and does not read or write `identity.key`. It then opens
`data_dir/oag.sqlite` through the same path used by persistent mode.

## Consequence

Ephemeral mode changes the signing identity, not the database location. A start
with `ephemeral = true` in a data directory that already contains a graph can
read and write that graph as a new peer. Local events it commits are signed by
the temporary key. The old `identity.key`, if present, is left untouched. The
comment describes this as a clean fork of the identity path, and the code
matches that narrower claim. It is not a disposable database or a sandbox.

The default remains persistent identity. Enabling ephemeral is an operator
configuration change, not an automatic fallback when the key file is missing.
The missing-file behavior in finding 0085 is a different path.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-086a | Implemented and documented intent | `crates/oag-cli/src/config.rs:606-615` |
| B-086b | Implemented | `crates/oag-cli/src/serve.rs:15-28` |

Verification: source inspection only. No ephemeral server was started.

## Next investigation

Trace local event signing under a changed identity and determine whether the origin chain is per peer ID, so a new ephemeral identity starts at sequence 1 in the same database.