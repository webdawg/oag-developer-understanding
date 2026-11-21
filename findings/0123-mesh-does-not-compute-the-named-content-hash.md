# 0123 — Mesh names a content hash it never computes

Claim `B-123`: at mesh `9f5d89e9fcf944dc16eff61f17543e83fc6ad20c`, no Rust
call site invokes `blake3_content_hash`. The only occurrence is the claim-report
comment. Tests sign literal strings such as `blake3:abc`. The connection from a
fetched page to a claim report is therefore absent in this crate, not
implemented.

## Separate core function

The inspected core checkout `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` defines
`blake3_content_hash` as `blake3:` plus the hexadecimal BLAKE3 digest. Crawler,
gateway, and transfer code call it. Mesh locks `oag-crypto` from core git
revision `ce1122589909c151056de33325b14d7022efe2f0`. That locked file was not
re-read here, so this finding does not claim the locked function body matches
the inspected checkout. Even if it does, mesh source does not call it before
`build_and_sign`. A signed label with a hash-like prefix is accepted by the
string checks in finding 0122. No hash was computed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-123a | Search | `blake3_content_hash` appears once in mesh, as a comment |
| B-123b | Implemented tests | `oag-mesh/src/corroboration.rs:426` |
| B-123c | Implemented core function | `oag-crypto/src/hashing.rs:5-7` at core `87f9e8c` |
| B-123d | Locked dependency | mesh `Cargo.lock` `oag-crypto` at `ce112258` |

Verification: source search only. No content was hashed.

## Next investigation

Trace core remote ingest gap handling and determine whether a missing sequence number is stored as a gap or rejected.