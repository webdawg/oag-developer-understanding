# 0164 — Mesh responder acks are latest-signed state, not a count

Claim `B-0164`: at mesh `45f9fa8a16f65fc4a2e2fe5238bbbc2a5e462574`, a
responder acknowledgment signs `active: true/false` for a corroboration nonce.
The log keeps one record per `(nonce, responder)`, replaces it with a newer or
equally recent signed statement, and exposes only responders whose latest
record is active. There is no proof-of-work, no check that the nonce exists, and
no promise that an active responder actually acted.

## Order of behavior

1. `build_and_sign` puts responder peer ID, public key, `corroboration_nonce`,
   `active`, and `acknowledged_at` into the unsigned struct, signs canonical
   JSON under `OAG-MESH:RESPONDER_ACKNOWLEDGMENT:v1:`, and hex-encodes it.
2. `verify` checks that the public key derives to the claimed peer ID, verifies
   the signature, and rejects clock skew over 300 seconds. It explicitly does
   not check that any event used the nonce.
3. The transport verifies first, applies the 60-per-minute per-responder fixed
   window (finding 0159), then calls `add_verified`, so verification is not
   repeated and invalid signatures never consume a token.
4. `add_verified` looks up `nonce -> responder`. If an existing record has a
   strictly newer `acknowledged_at`, the incoming statement is ignored.
   Otherwise the record is replaced and `sequence` increments — including on an
   equal timestamp, where arrival order decides.
5. `active: false` is the stand-down; there is no separate retract type.
   `active_responders_for` filters the latest records by `active == true`. The
   GET route returns those peer IDs as strings; they come from a `HashMap`
   iterator with no explicit sort.
6. `MeshState` persists the acknowledgment log in
   `responder_acknowledgments.json` and serves it through the sync snapshot
   route (finding 0158).

## What is durable, rejected, and left behind

Durable: one latest state per responder/nonce pair, the monotonic sequence, and
the snapshot if a caller saves. Rejected: bad IDs/keys, signature failures,
clock skew, and per-identity rate-limit overflow. A stale acknowledgment is
accepted by verification but ignored by the log; it leaves no state change and
no sequence bump.

The query is advisory: a non-empty `active_responders` list means those peers
signed a recent claim, not that they are doing anything. A fabricated but
structurally valid nonce is accepted and can produce an active responder list.
An equal-timestamp conflict lets the later delivery overwrite the earlier one.
No submission, poll, or target test was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0164a | Implemented signing and verification | `crates/oag-mesh/src/responder.rs:35-142` |
| B-0164b | Implemented latest-state log | `crates/oag-mesh/src/responder.rs:144-215` |
| B-0164c | Implemented transport admission and query | `crates/oag-mesh/src/transport.rs:860-914` |
| B-0164d | Implemented persistence | `crates/oag-mesh/src/transport.rs:321-377`, `379-450` |
| B-0164e | New since explained commit | `git diff 9f5d89e9..45f9fa8a -- crates/oag-mesh/src/responder.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No HTTP request or target test was executed.

## Change since the previously explained commit

`responder.rs`, its acknowledgment and active-responder routes, its limiter, and
its snapshot store are new at `45f9fa8a...` relative to explained `9f5d89e9...`.
Findings 0159 and 0160 cover the limiter and blinded dispatch around this
mechanism; neither is rewritten here.

## Next investigation

Trace `oag_mesh::transport::search_for_route` fan-out budgeting and path
selection to document what the new route-search rate limit actually bounds.
