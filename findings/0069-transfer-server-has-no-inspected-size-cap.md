# 0069 — The transfer server returns full fetched bytes without an inspected cap

Claim `B-069`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, after request
verification and provider or relay fetch, the server hashes the full byte
vector, signs a receipt, records a transfer event, and returns those bytes with
the receipt header. The inspected function does not reject `content.len()`
against a maximum before that work.

## Consequence

A signature-valid caller who can name a CID available to the local provider or
to a configured relay can make this peer hash, persist a transfer record for,
and return the full content. The general API body-size limit applies to the
incoming request, not to the fetched response. No transfer-specific response
limit appears in `transfer.rs`; the only size-related constant found there is
the 300-second clock skew.

This does not prove the IPFS provider lacks its own limit. That provider was not
inspected. The safe claim is that the transfer handler adds no independent cap
around the bytes it receives from the provider or relay.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-069a | Implemented | `crates/oag-api/src/transfer.rs:585-630` |
| B-069b | Absence in searched file | `rg max_.*bytes transfer.rs` found no response-size constant |

Verification: source inspection only. No CID fetch was performed.

## Next investigation

Trace the IPFS provider fetch implementation for its own size, timeout, and authentication limits before describing transfer as bounded.