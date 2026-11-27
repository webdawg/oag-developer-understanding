# 0217 — Peer ID is a BLAKE3 hash of the Ed25519 public key

Claim `B-0217`: at core `fb54e431332a030a566099c76fb2558084765422`, a
`PeerId` is `BLAKE3(ed25519_verifying_key_bytes)` encoded as `oagp_` plus
lowercase unpadded Base32. Parsing accepts uppercase Base32 by uppercasing the
suffix, but still requires exactly 32 decoded bytes. A raw-byte constructor
exists and performs no key derivation check.

## Order of behavior

1. `PeerIdentity` holds an Ed25519 `SigningKey`, stored as exactly 32 raw bytes
   in `identity.key` and loaded/saved with owner-only permissions on Unix.
2. `PeerIdentity::peer_id` calls `PeerId::from_public_key(verifying_key)`, which
   hashes the 32 verifying-key bytes with plain BLAKE3.
3. `Display` renders `oagp_` followed by `BASE32_NOPAD` of the digest, lowercased.
4. `FromStr` requires the `oagp_` prefix, decodes the uppercased suffix as
   unpadded Base32, and rejects a decoded length other than 32 bytes.
5. `PeerId::from_bytes` wraps arbitrary 32 bytes directly. Its doc comment says
   it does not prove those bytes derive from a key; callers needing that
   guarantee must compare with `from_public_key`.

## What is durable, rejected, and left behind

Durable: the peer ID is derived, not stored separately in `PeerIdentity`; the
private key file is the persistent identity. Rejected: a missing prefix, invalid
Base32, or a decoded length other than 32 bytes. Uppercase input is accepted
because parsing normalizes it.

The ID hash has no OAG domain prefix, unlike `Hash32::derive` used for node,
edge, event, and actor IDs. That is a deliberate difference between public
identity naming and domain-separated internal identifiers. Verification helpers
still compare a supplied public key against a claimed peer ID where identity
matters (finding 0136). No key was generated or parsed in this pass.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0217a | Implemented peer-ID derivation and encoding | `crates/oag-crypto/src/peer_id.rs:7-64` |
| B-0217b | Implemented persistent Ed25519 identity | `crates/oag-crypto/src/identity.rs:9-73` |
| B-0217c | Implemented peer/key comparison at ingest | `crates/oag-events/src/ingest.rs:59-68` |
| B-0217d | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-crypto/src/peer_id.rs crates/oag-crypto/src/identity.rs` (no output) |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No key was generated or parsed.

## Change since the previously explained commit

Peer-ID derivation is unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Findings 0084 and 0085 describe
backup and missing-file consequences; this finding records the identity format
those consequences act on.

## Next investigation

Trace `oag_crypto::sign_with_domain` and `verify_with_domain` to document the
exact signed message and the cross-domain failure guarantee.
