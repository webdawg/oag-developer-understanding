# 0044 — Actor keys are hashed, and revocation removes them from authentication

Claim `B-044`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, declaring an
actor commits an `ACTOR_DECLARE` event. Creating a key returns a raw
`oagk_`-prefixed secret once and commits only its BLAKE3 hash. Authentication
accepts a hash only when its stored key has `revoked_at IS NULL`.

## Identity behavior

If a declaration includes a public-key proof, the service verifies a
domain-separated signature over actor type, name, and identity URI before
commit. Projection derives the actor ID from the public-key hex. Repeating that
declaration therefore targets the same actor ID. Without a key, projection
derives the ID from the declaring event ID, so each declaration receives a
distinct actor identity.

`create_key` generates 32 random bytes, formats the raw key, hashes it, and
commits the hash with permissions. `revoke_key` first requires an active match
and then commits `ACTOR_KEY_REVOKE`. The projector treats an already-revoked or
unknown hash as a no-op, but the service method has already rejected that case
before committing. Authentication cannot return a revoked key because its query
filters `revoked_at IS NULL`.

There is a check-then-commit gap between the active-key lookup and revocation
event. Concurrent revocation behavior was not tested. The service comment says
key management is a local CLI/data-directory operation, not a REST/MCP route;
route exposure was not rechecked here.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-044a | Implemented | `crates/oag-graph/src/service.rs:188-299` |
| B-044b | Implemented | `crates/oag-events/src/projector.rs:308-343` and `405-419` |
| B-044c | Implemented | `crates/oag-storage/src/repo/actors.rs:162-176` |

Verification: source inspection only. No key was generated or revoked.

## Next investigation

Trace permission parsing and the bootstrap admin-key path to determine which permissions exist and how the first administrative credential enters the system.