# 0230 — Actor identity is key-derived or event-scoped

Claim `B-0230`: at core `fb54e431332a030a566099c76fb2558084765422`, an actor
declared with a public key gets an `ActorId` derived from that key string; one
without a key gets an ID derived from the declaring event. A public-key proof
binds the actor type, name, and identity URI to the key under
`OAG:ACTOR_KEY_PROOF:v1:` before the event is committed.

## Order of behavior

1. `declare_actor` checks name/URI lengths. With a `PublicKeyProof`, it parses
   the 32-byte key, rebuilds the canonical `ActorKeyProofMessage`, and verifies
   the signature with `verify_with_domain`. A failed proof is `InvalidInput`.
2. On success the key is hex-encoded into `ActorDeclarePayload`; without a
   proof the payload's `public_key` is `None`.
3. `project_actor_declare` parses the actor type and any 32-byte key. The seed
   for `ActorId::derive` is the payload's public-key hex if present, otherwise
   the declaring event's hex ID.
4. `actors::insert` uses `INSERT OR IGNORE` keyed by `actor_id`. A repeat
   declaration of a keyed actor is a no-op that keeps the first row's type,
   name, identity URI, and creation time. A keyless actor has a fresh ID per
   declaration event.
5. `sign_actor_key_proof` exists for callers that hold the key in-process; the
   source names transfer's per-request `ActorType::Peer` declaration as its
   first real use.

## What is durable, rejected, and left behind

Durable: the actor row keyed by derived ID. Rejected: invalid key bytes, invalid
proof signature, unknown actor type, and overlong name/URI. A repeat keyed
declaration is ignored rather than producing a second row or an error.

The proof binds descriptive fields but not the actor ID; the ID is recomputed
from the key at projection. Keyless actors are deliberately event-scoped, so
repeated local declarations do not converge on one actor. No actor was
declared in this pass.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0230a | Implemented proof sign/verify | `crates/oag-graph/src/service.rs:45-69`, `245-283` |
| B-0230b | Implemented projection identity rule | `crates/oag-events/src/projector.rs:308-349` |
| B-0230c | Implemented insert-if-missing | `crates/oag-storage/src/repo/actors.rs:38-55` |
| B-0230d | Implemented actor types | `crates/oag-core/src/actor.rs:6-51` |
| B-0230e | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-graph/src/service.rs crates/oag-events/src/projector.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No actor was declared.

## Change since the previously explained commit

Actor declaration and proof behavior are unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Finding 0222 records the actor and
permission vocabularies; this finding records identity derivation and proof.

## Next investigation

Trace `oag_api::transfer`'s actor declaration on fetch to document when the
idempotent peer actor is created and which identity signs it.
