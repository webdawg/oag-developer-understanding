# 0163 — Mesh membership counts distinct attesters without expiry

Claim `B-0163`: at mesh `45f9fa8a16f65fc4a2e2fe5238bbbc2a5e462574`, a
`MembershipAttestation` is a signed claim by one peer that another peer belongs
to a cluster. The registry stores only a set of distinct attesters per
`(cluster, subject)`. Becoming a new attester costs escalating proof-of-work;
re-attesting an already-recorded fact is free. There is no expiry or revocation
path, and the attester's own standing in the cluster is not verified.

## Order of behavior

1. `build_and_sign` refuses a self-attestation, puts attester/subject/cluster/
   timestamp in the unsigned struct, signs canonical JSON under
   `OAG-MESH:MEMBERSHIP_ATTESTATION:v1:`, and hex-encodes the signature.
2. `verify` parses both peer IDs, checks the public key derives to the attester
   ID, verifies the signature, rejects more than 300 seconds of clock skew, and
   rejects self-attestation. It does not check that the attester belongs to the
   named cluster.
3. `required_difficulty_bits` returns 16 bits for the first attester of a fact
   and `16 + 4 * existing_distinct_attesters` for a new one. It returns 0 for an
   attester already in the set, so a repeat costs no work.
4. `add_verified` checks proof-of-work against that current requirement, inserts
   the attester into a `HashSet`, and increments `sequence` only if the set
   changed. A repeat succeeds without changing the version stamp.
5. `is_attested_member` compares `attester_count` against a caller threshold.
   `GET .../claim-report/{id}/best-fully-cross-checked` passes the registry and
   `min_membership_corroboration` (default 1) into the corroboration query.
6. Snapshots serialize attester sets. `merge_snapshot` unions sets and never
   re-checks signatures or proof-of-work, by explicit trust in the snapshot
   source. No removal, expiry, or revocation method appears in the module.

## What is durable, rejected, and left behind

Durable in a running registry: the union of attester IDs per fact and a
monotonic `sequence`. `MeshState` persists the membership snapshot in
`membership_registry.json` and serves it over the sync snapshot route (finding
0158), so a caller that saves survives a restart.

Rejected: malformed IDs/keys, signature or pairing failure, clock skew,
self-attestation, and insufficient proof-of-work. A rejected attestation is not
inserted and does not change `sequence`. An accepted attestation remains even if
the subject later leaves the cluster or the attester later loses standing;
those events are not modeled here.

Broadcasting solves proof-of-work against the sender's own registry view. A
receiver with more distinct attesters already recorded may require a higher
difficulty and reject that same submission. The source explicitly says
attestations are turtles all the way down without an out-of-band root of trust;
this module does not solve that. No submission, snapshot, or target test was
executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0163a | Implemented signing and verification | `crates/oag-mesh/src/membership.rs:36-60`, `178-233` |
| B-0163b | Implemented registry and difficulty | `crates/oag-mesh/src/membership.rs:235-327` |
| B-0163c | Implemented snapshot trust | `crates/oag-mesh/src/membership.rs:329-405` |
| B-0163d | Implemented route and broadcast | `crates/oag-mesh/src/transport.rs:1165-1201`, `1293-1318` |
| B-0163e | New since explained commit | `git diff 9f5d89e9..45f9fa8a -- crates/oag-mesh/src/membership.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No HTTP request or target test was executed.

## Change since the previously explained commit

`membership.rs`, its attestation route, the fully-cross-checked query, the
snapshot route, and the persisted store are new at `45f9fa8a...` relative to
explained `9f5d89e9...`. Findings 0120-0121 about caller-selected claim
thresholds still describe the earlier cross-checks; this adds a third,
membership-based one.

## Next investigation

Trace `oag_mesh::responder::ResponderAcknowledgmentLog` to document how an
acknowledgment is admitted, retained, cross-checked, and exposed.
