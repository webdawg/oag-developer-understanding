# 0104 — The locked Reticulum hash parser truncates and panics on bad digits

Claim `B-104`: core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` locks `reticulum`
0.1.0. `AddressHash` is 16 bytes. `new_from_hex_string` rejects strings shorter
than 32 hex characters with `RnsError::IncorrectHash`. For a longer string it
decodes only the first 32 characters and ignores the rest. A non-hex pair in
that prefix calls `unwrap`, which panics instead of returning the error.

## Effect on OAG

`parse_address_hash` trims surrounding slashes and passes the remainder to this
function. A display form such as `/<32 hex chars>/` therefore parses. An extra
suffix after 32 valid hex characters is silently ignored. An invalid digit is
not a clean CLI error: the panic escapes the `Result`. The accepted alphabet is
whatever Rust's base-16 parser accepts in the first 32 characters, including
upper and lower case. No checksum is checked.

This is locked-dependency behavior, not an OAG wrapper decision. It was not
executed. The TCP endpoint remains unvalidated by this parser.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-104a | Locked dependency | `Cargo.lock` reticulum `0.1.0`; `reticulum-0.1.0/src/hash.rs:13` and `96-107` |
| B-104b | OAG wrapper | `crates/oag-reticulum/src/lib.rs:21-22` |

Verification: source inspection only. No parse call was executed.

## Next investigation

Trace the locked Reticulum `TcpClient::new` and record whether a missing port or non-numeric host is rejected before a connection attempt.