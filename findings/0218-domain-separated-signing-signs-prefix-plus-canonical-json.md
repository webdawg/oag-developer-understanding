# 0218 — Domain-separated signing signs prefix plus canonical JSON

Claim `B-0218`: at core `fb54e431332a030a566099c76fb2558084765422`,
`sign_with_domain` signs the raw byte concatenation `domain_prefix ||
canonical_bytes` with Ed25519. Verification rebuilds the identical message.
There is no length prefix or delimiter added by the helper; the domain
constants themselves end in `:`.

## Order of behavior

1. Callers serialize the signed object with `canonical_json_bytes`, which is the
   single wrapper around `serde_jcs::to_vec` in core domain code.
2. `sign_with_domain` allocates `domain_prefix.len() + canonical_bytes.len()`,
   copies the UTF-8 domain bytes, then the canonical JSON bytes, and calls
   Ed25519 `sign`.
3. `verify_with_domain` rebuilds the same concatenation and calls Ed25519
   `verify`; any byte difference or different verification key fails.
4. Inspected tests assert that tampered canonical bytes and a different domain
   prefix fail verification. Those tests were read, not executed.
5. Core domains found in source include event, cluster, presence, gateway
   request/response, transfer request/receipt, and actor-key proof. Internal
   identifiers use a parallel `Hash32::derive` prefix scheme for node, edge,
   event, and actor IDs.

## What is durable, rejected, and left behind

Durable: no state is written by the helper; callers hex-encode/store the 64-byte
signature in their own envelopes. Rejected by verification: modified bytes, a
wrong key, or a wrong domain. Domain separation means a signature or hash
produced for one object class cannot be replayed as another if callers use the
correct constants.

The helper does not enforce that a domain ends in `:` or that bytes are valid
JSON; it trusts callers to pass canonical bytes and a stable domain. Other
repositories define their own constants (mesh bridge, claim, membership,
gateway NTP, for example) using the same helper or conventions. No signature
was created or verified in this pass.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0218a | Implemented sign/verify helpers | `crates/oag-crypto/src/signing.rs:1-24` |
| B-0218b | Test inspection, not executed | `crates/oag-crypto/src/signing.rs:26-52` |
| B-0218c | Implemented canonical JSON wrapper | `crates/oag-core/src/lib.rs:19-24` |
| B-0218d | Core domain constants | `git grep "DOMAIN" origin/main -- crates/**/*.rs` |
| B-0218e | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-crypto/src/signing.rs crates/oag-core/src/lib.rs` (no output) |

Verification: source inspection via `git show origin/main:<path>`, `git grep`,
and a scoped diff. No signature operation was executed.

## Change since the previously explained commit

The signing and canonicalization helpers are unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Finding 0217 records the identity
key behind the signer; this finding records the exact message construction.

## Next investigation

Trace `oag_events::envelope::SignedEvent` and `verify_and_derive_id` to document
how event IDs are derived from signed canonical envelopes and why callers
cannot trust a supplied ID.
