# 0219 — Event ID is derived from the whole signed envelope

Claim `B-0219`: at core `fb54e431332a030a566099c76fb2558084765422`, an event
ID is not carried on the wire or accepted from a caller. It is
`BLAKE3("OAG:EVENT:v1:" || JCS(SignedEvent))`. The signature covers only the
canonical unsigned envelope under the same domain prefix.

## Order of behavior

1. `UnsignedEvent` contains version, origin peer, sequence, previous event,
   creation time, and the flattened payload. `SignedEvent` is that struct plus
   a hex signature string; neither struct has an `event_id` field.
2. `build_and_sign` canonicalizes the unsigned event with `serde_jcs`, signs
   `OAG:EVENT:v1:` concatenated with those bytes, attaches the hex signature,
   then canonicalizes the entire signed envelope.
3. `EventId::derive` uses `Hash32::derive` with the `OAG:EVENT:v1:` prefix, so
   the ID is a BLAKE3 digest of prefix + canonical signed-envelope bytes.
4. `verify_and_derive_id` canonicalizes `signed.unsigned`, requires a 64-byte
   hex signature, verifies under the event domain, then canonicalizes the whole
   `SignedEvent` and recomputes the ID. It returns that ID; callers cannot
   supply one.
5. Because the signature string is part of the signed envelope's canonical
   JSON, its exact textual form participates in the event ID even though the
   signature bytes are what Ed25519 verifies (Inferred from the two canonical
   byte sets; no signature was generated).

## What is durable, rejected, and left behind

Durable: event rows are keyed by the derived ID; assertions reuse that ID as
their assertion ID. Rejected: a bad hex length, invalid signature, or changed
unsigned bytes. A changed signature text that still decodes to the same bytes
would change the derived ID while remaining cryptographically valid; callers
should preserve envelope bytes rather than normalize hex case.

The signature and ID use the same domain string but different inputs: the
former signs the unsigned envelope, the latter hashes the whole signed
envelope. No event was built or verified in this pass.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0219a | Implemented envelope structs | `crates/oag-events/src/envelope.rs:1-29` |
| B-0219b | Implemented build pipeline | `crates/oag-events/src/builder.rs:8-43` |
| B-0219c | Implemented verification and ID derivation | `crates/oag-events/src/validate.rs:7-25` |
| B-0219d | Implemented EventId domain | `crates/oag-core/src/ids.rs:133-139` |
| B-0219e | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-events/src/envelope.rs crates/oag-events/src/builder.rs crates/oag-events/src/validate.rs` (no output) |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No signature operation was executed.

## Change since the previously explained commit

The event envelope and ID pipeline are unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Finding 0218 records the underlying
domain-separated signing helper; this finding records how events use it.

## Next investigation

Trace `oag_events::payload::EventPayload` variants and their canonical type
strings to document what can be signed and projected as an event.
