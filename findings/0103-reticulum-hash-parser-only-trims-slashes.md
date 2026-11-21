# 0103 — OAG's Reticulum hash parser only trims slashes

Claim `B-103`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
`parse_address_hash` trims leading and trailing `/` characters and passes the
remaining string to `AddressHash::new_from_hex_string`. OAG adds no length,
character, or checksum check of its own. The TCP endpoint is not parsed by this
function at all.

## Boundary

The wrapper exists so the CLI does not depend directly on the Reticulum crate.
It accepts both the display form with surrounding slashes and the plain hex
form, according to its comment. Invalid strings return the dependency's
`RnsError`. The exact hex grammar and error text are in the locked Reticulum
crate and were not inspected. A missing port in the separate TCP argument is
therefore not rejected here. `peer add-reticulum` can fail at hash parsing
before dialing, but a valid hash does not validate the TCP target.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-103 | Implemented and documented intent | `crates/oag-reticulum/src/lib.rs:14-22` |

Verification: source inspection only. No hash strings were parsed.

## Next investigation

Inspect the locked Reticulum `AddressHash::new_from_hex_string` implementation if it is present in the local cargo registry, and record the exact accepted length and alphabet.