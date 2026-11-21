# 0122 — A claim report's observed value is an unchecked string

Claim `B-122`: at mesh `9f5d89e9fcf944dc16eff61f17543e83fc6ad20c`,
`verify` checks peer-ID derivation, the Ed25519 signature over the canonical
unsigned report, and a 300-second window around `observed_at`. It does not
decode `observed_value_hash`, require hex, or require a fixed length.

## Comparison consequence

The field comment says the value should be a comparable hash and names
`blake3_content_hash` as an example. That is documented intent. The type is
`String`, and `build_and_sign` copies the caller string without transformation.
Later aggregation groups reports by exact string equality. `AA` and `aa`, a
hash and a label, or an empty string are different or equal only as text. The
signature binds whatever string was signed. It does not prove the string is a
hash of content the reporter fetched. No report was constructed.

`claim_id` and `reporter_cluster` are also opaque strings. The crate comment
says it does not interpret `claim_id`.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-122a | Documented intent | `oag-mesh/src/corroboration.rs:59-71` |
| B-122b | Implemented checks | `oag-mesh/src/corroboration.rs:30-33` and `175-219` |
| B-122c | Implemented grouping | `oag-mesh/src/corroboration.rs:308-322` |

Verification: source inspection only.

## Next investigation

Search the mesh crate for a caller that computes `blake3_content_hash` before signing a claim report, and label the connection implemented or absent.