# 0102 — Reticulum peer add parses the hash but not the TCP endpoint

Claim `B-102`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
`oag peer add-reticulum` parses the destination hash and returns an error for
an invalid hash. The TCP string is passed unchanged to `sync_with_peer`, which
spawns a TCP client with it. There is no inspected host, port, or
private-network check on that string.

## Side effects

The command calls `load_or_generate` before dialing. If `identity.key` is
missing, this creates a new persistent signing identity even if the dial later
fails. A successful sync stores `reticulum:{hash}` through the client path in
finding 0097. The TCP endpoint itself is not stored by the lines inspected here.
The command prints applied, already-known, and fork counts, and warnings for
per-origin errors, but still returns success when the sync function returns
`Ok`. A sync summary with errors is therefore not a command failure.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-102 | Implemented | `crates/oag-cli/src/commands.rs:264-281` |
| B-102-dial | Implemented | `crates/oag-reticulum/src/client.rs:78-82` |

Verification: source inspection only. No Reticulum peer was added.

## Next investigation

Trace `parse_address_hash` and the TCP client constructor only far enough to record accepted hash format and whether a missing port is rejected by OAG or left to the dependency.