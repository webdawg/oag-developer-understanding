# 0232 — Transfer receipt verification binds nonces and the claimed hash

Claim `B-0232`: at core `fb54e431332a030a566099c76fb2558084765422`,
`verify_receipt` checks five things: exact CID and client nonce, peer/key
pairing, Ed25519 signature, 300-second clock skew, and the mutual receipt hash
recomputed from the expected client nonce, the receipt's server nonce, and the
receipt's `content_hash` string. It does not itself hash downloaded bytes.

## Order of behavior

1. `build_and_sign_receipt` generates a random server nonce, sets
   `receipt_hash = mutual_receipt_hash(client_nonce, server_nonce, content_hash)`,
   and signs the canonical unsigned receipt under `OAG:TRANSFER_RECEIPT:v1:`.
2. `verify_receipt` first requires the receipt's CID and client nonce to equal
   the caller's expected values; otherwise `ReceiptMismatch`.
3. It parses the server peer ID and public key, requires the key to derive to
   that peer ID, and verifies the signature over the canonical unsigned receipt.
4. It rejects a `served_at` more than 300 seconds from the caller's clock.
5. It decodes the receipt's server nonce, recomputes
   `mutual_receipt_hash(expected_client_nonce, server_nonce,
   receipt.unsigned.content_hash)`, and requires equality with the signed
   `receipt_hash`. It then returns the verified server peer ID.

## What is durable, rejected, and left behind

Durable: no state is written by verification. Rejected: CID/nonce mismatch,
invalid key or peer/key mismatch, bad signature encoding or signature, clock
skew, invalid server nonce, and receipt-hash mismatch. Each is a typed
`TransferError`.

The mutual hash proves both parties' nonces contributed to a hash over the
claimed content-hash string; it does not prove those bytes were delivered. The
client's separate download-then-compare step is what binds the receipt to
received content (finding 0068). The server nonce is not checked against a
stored challenge here; replay resistance comes from the caller's unique client
nonce and exchange binding.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0232a | Implemented receipt construction | `crates/oag-api/src/transfer.rs:225-253` |
| B-0232b | Implemented receipt verification | `crates/oag-api/src/transfer.rs:255-300` |
| B-0232c | Implemented mutual hash | `crates/oag-crypto/src/hashing.rs:17-35` |
| B-0232d | Implemented download-then-compare caller | `crates/oag-api/src/transfer.rs:425-496`; finding 0068 |
| B-0232e | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-api/src/transfer.rs` (only a new test) |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No transfer or signature verification was executed.

## Change since the previously explained commit

Receipt construction and verification are unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Findings 0066 and 0068 describe
the admission boundary and download ordering; this finding records the exact
receipt checks.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining gap from
the journal and revision table.
