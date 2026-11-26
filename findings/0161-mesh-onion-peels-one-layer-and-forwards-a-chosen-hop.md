# 0161 — Mesh onion relays peel one layer and trust the recovered hop

Claim `B-0161`: at mesh `45f9fa8a16f65fc4a2e2fe5238bbbc2a5e462574`, an onion
layer is ChaCha20-Poly1305 ciphertext under an ephemeral X25519 shared secret
with a relay key derived from that relay's Ed25519 identity. A relay peels one
layer, reads a `next_hop` string from the recovered plaintext, and POSTs either
the next layer or the final anonymous-event submission there. The recovered hop
is not checked against a peer registry or path policy.

## Order of behavior

1. `fetch_onion_key` GETs `<relay>/oag-mesh/v1/onion-key` and takes
   `x25519_public_key` from the JSON. The response also contains `peer_id`, but
   the field is explicitly unused in deserialization and this function does not
   bind the key to an identity.
2. `build_onion` requires a non-empty path and one key per path entry. It starts
   with the final `Submission { event, pow }` and target URL, then wraps from the
   last relay backward. Each `OnionInner` contains `next_hop` plus either the
   next layer or the submission. No path-length cap appears in these functions.
3. `wrap_layer` generates a fresh X25519 ephemeral secret and 12-byte nonce,
   derives a BLAKE3 key over `"OAG-MESH:ONION:v1:" || shared_secret`, encrypts
   the serialized inner JSON with no additional data, and returns hex fields.
4. `POST /oag-mesh/v1/onion` first takes a token from the node-wide onion
   bucket. `peel_layer` decodes hex fields, recomputes the shared secret using
   the relay's own Ed25519-derived X25519 static secret, decrypts, and parses
   `OnionInner`. Hex/length/decrypt/JSON failures become HTTP 400.
5. If the payload is another layer, the relay POSTs it to `<next_hop>/oag-mesh/v1/onion`.
   If it is a submission, the relay POSTs it to
   `<next_hop>/oag-mesh/v1/anonymous-event`. A forwarding failure becomes 502;
   success is 204. The final target still applies its anonymous-event
   proof-of-work check.

## What is durable, rejected, and left behind

This path stores no onion state: each relay forwards and forgets. Rejected
inputs are empty paths, key/path length mismatch, malformed hex or lengths,
failed AEAD authentication, unparseable inner JSON, and a depleted node-wide
bucket (429 with `Retry-After`). Forwarding errors leave the peeled plaintext in
the handling task only; no retry or dead-letter store is shown.

A relay learns the address it was contacted from and the recoverable `next_hop`;
it does not learn the reporter's identity from the payload. The fetched relay
key is not verified against the returned `peer_id` here, so this function's
trust is in the fetched bytes. The module warns that timing/volume correlation,
visible relay addresses, and a globally positioned adversary remain outside its
protections. No HTTP request, relay, or target test was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0161a | Implemented key derivation and layers | `crates/oag-mesh/src/onion.rs:1-144` |
| B-0161b | Implemented onion construction | `crates/oag-mesh/src/onion.rs:146-177` |
| B-0161c | Implemented relay handler | `crates/oag-mesh/src/transport.rs:613-658` |
| B-0161d | Implemented key fetch and forwarding | `crates/oag-mesh/src/transport.rs:1345-1415` |
| B-0161e | New since explained commit | `git diff 9f5d89e9..45f9fa8a -- crates/oag-mesh/src/onion.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No target test or service was run.

## Change since the previously explained commit

The `onion.rs` module, `/onion-key`, `/onion`, the onion limiter, and the onion
push helpers are new at `45f9fa8a...` relative to explained `9f5d89e9...`.
Finding 0159 documents the limiter; this finding documents the cryptographic
layer and relay behavior. No older finding is rewritten.

## Next investigation

Trace `oag_mesh::link_quality::LinkQualityLedger` to document what peer behavior
changes scores, what thresholds exist, and whether any route decision consumes
them.
