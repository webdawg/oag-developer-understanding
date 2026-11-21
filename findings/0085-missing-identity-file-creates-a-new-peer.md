# 0085 — A missing identity file silently creates a new signing peer

Claim `B-085`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, persistent
startup calls `PeerIdentity::load_or_generate` on `data_dir/identity.key`. If
the file is absent, it generates a new key, saves it, and continues. On Unix,
`save` sets mode `0600` after writing. Ephemeral mode never reads or writes that
file and generates an in-memory identity instead.

## Consequence

Deleting or failing to restore `identity.key` while retaining `oag.sqlite` does
not make startup fail. The process becomes a new peer ID and will sign new local
events with the new key. Existing events remain signed by the old key. Nothing
in `load_or_generate` compares the loaded or generated key with the database.
The identity backup warning says anyone with the file can sign as that peer;
the missing-file path is the opposite hazard, a new peer with the old database.

The file mode is applied after `fs::write`. A crash between those calls can
leave a key file with the process umask. That race was not tested. Non-Unix
builds have no mode adjustment in the inspected function.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-085a | Implemented | `crates/oag-crypto/src/identity.rs:21-28` and `49-58` |
| B-085b | Implemented | `crates/oag-cli/src/serve.rs:15-24` |

Verification: source inspection only. No identity file was created or removed.

## Next investigation

Trace ephemeral identity configuration and determine whether an ephemeral peer can still open and modify a persistent database from a previous persistent identity.