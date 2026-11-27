# 0210 — Event provenance reopens and re-verifies the raw event

Claim `B-0210`: at core `fb54e431332a030a566099c76fb2558084765422`, an
assertion's provenance is not taken from the projected assertion row.
`get_event_provenance` loads the event whose ID equals the assertion ID, parses
its canonical payload, derives the origin's key from local identity/peer state,
and re-runs signature verification. A missing key produces `signature_valid:
false` and `origin_key_known: false`, never a false "valid" result.

## Order of behavior

1. The event ID is the assertion ID: the raw event is fetched with
   `events_repo::get_by_id`. A missing row returns `None`.
2. `row.canonical_payload` is deserialized into `SignedEvent`, and
   `unsigned.origin_peer` is parsed as a `PeerId`. An unparseable stored origin
   is `InvalidInput`.
3. If the origin is this peer, the current local verifying key is used.
   Otherwise the peer table supplies the stored public key; an invalid stored
   key is `InvalidInput`.
4. With a key, the function calls `verify_and_derive_id` and marks the signature
   valid only if verification succeeds and the recomputed event ID equals the
   requested ID. With no key, both verification and key knowledge are
   reported as false.
5. The returned `EventProvenance` carries event ID, origin peer, event type,
   creation time, signature validity, and key knowledge — not the payload or
   assertion body.

## What is durable, rejected, and left behind

Durable: no new state is written. Rejected: a missing event (`None`), malformed
stored origin/key, or a payload that cannot deserialize. A bad signature is not
an error response; it is `signature_valid: false` in the returned view.

This check uses currently stored peer keys, so a later key change can alter the
reported validity of an old event. It verifies the full signed envelope and
recomputed ID rather than trusting the event row's stored metadata. Redaction
of evidence text does not alter this payload (finding 0056). No event or
provenance request was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0210a | Implemented provenance struct and lookup | `crates/oag-graph/src/provenance.rs:1-29`, `31-69` |
| B-0210b | Implemented signature re-derivation | `crates/oag-events/src/validate.rs:7-25` |
| B-0210c | Human assertion-page caller | `crates/oag-api/src/human.rs:440-443` |
| B-0210d | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-graph/src/provenance.rs` (no output) |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No request or signature check was executed.

## Change since the previously explained commit

The provenance module is unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Findings 0056 and 0057 noted that
provenance does not expose redacted text; this finding explains what it does
compute.

## Next investigation

Trace the human Assertion page's use of `EventProvenance` fields to document
what a visitor sees about origin, signature, and redacted content.
