# 0222 — Actor and permission vocabularies are closed strings

Claim `B-0222`: at core `fb54e431332a030a566099c76fb2558084765422`,
`ActorType` accepts nine snake_case values and `Permission` accepts six fixed
strings (`graph:read`, `graph:assert`, `graph:verify`, `graph:retract-own`,
`graph:crawl`, `admin`). Unknown permission strings stored on a key are
silently dropped when that key authenticates.

## Order of behavior

1. `ActorType` values are human, agent, model, crawler, organization, domain,
   service, peer, and anonymous. `parse` is exact; `as_str` is the stored form.
2. `Actor` carries an ID, one of those types, optional name, optional 32-byte
   Ed25519 public key, optional identity URI, metadata defaulting to an empty
   object, and creation time.
3. `Permission` values render with colons/kebab-case despite serde's
   `rename_all = "kebab-case"` derive; `as_str`/`parse` define the authoritative
   wire strings.
4. `find_active_key` loads a key only when `revoked_at IS NULL`, parses its
   JSON permission array, then uses `filter_map(Permission::parse)`. A malformed
   or future permission string becomes no permission rather than an auth error.
5. `graph:crawl` is deliberately separate from `graph:assert` because it lets a
   caller direct this peer's outbound HTTP egress.

## What is durable, rejected, and left behind

Durable: actor type and permission strings on actors/API keys. Rejected by
typed APIs: unknown actor types and unknown input permission strings. Rejected
at auth time: an unparseable stored permission is ignored, not surfaced; a key
with only unknown strings authenticates with an empty permission set.

An actor is a submitter role, not a network peer: one peer can serve many
actors, and `ActorType::Peer`/node type `peer` address different concepts. No
actor or key was created in this pass.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0222a | Implemented actor type and struct | `crates/oag-core/src/actor.rs:6-69` |
| B-0222b | Implemented permission strings | `crates/oag-core/src/actor.rs:71-114` |
| B-0222c | Implemented auth-time permission parsing | `crates/oag-storage/src/repo/actors.rs:162-184` |
| B-0222d | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-core/src/actor.rs` (no output) |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No actor or key was created.

## Change since the previously explained commit

Actor and permission vocabularies are unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Finding 0221 records the parallel
node/alias vocabularies; this finding records identity and authorization.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining gap from
the journal and revision table.
