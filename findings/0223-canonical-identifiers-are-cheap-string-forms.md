# 0223 — Canonical identifiers are cheap strings, not validated URIs

Claim `B-0223`: at core `fb54e431332a030a566099c76fb2558084765422`,
`canonical_identifier(kind, value)` is just `kind.trim().to_lowercase() + ":" +
value.trim()`. It does not validate the kind or value. A separate helper
generates `uuid:<UUIDv7>` for entities without a stable identifier, but no
production caller in this checkout uses that helper.

## Order of behavior

1. `canonical_identifier` trims and lowercases the kind, trims the value, and
   joins with a colon. The documented kinds include `url`, `domain`, `urn`,
   `package`, `doi`, `isbn`, `github`, `concept`, `agent`, and `peer`, but the
   function accepts any string.
2. `oag-graph::identifier::canonicalize_value` calls this helper for URL and
   bare-text cases; for explicit scheme values it lowercases the entire
   identifier itself. Node ID derivation then hashes the resulting string.
3. `generate_uuid_identifier` returns `uuid:` plus `Uuid::now_v7()`, intended
   for entities with no stable URI. A grep in the tracked source found only its
   definition and re-export, not a production event builder calling it.
4. `NodeId::from_canonical_identifier` hashes the exact string bytes under the
   `OAG:NODE:v1:` domain; no parsing occurs at that step.

## What is durable, rejected, and left behind

Durable: the canonical identifier string is stored on the node and determines
its ID. Rejected: nothing by `canonical_identifier` itself. Structural checks
must happen earlier in callers such as `canonicalize_value` or later in
payload validation.

Because value case is not normalized by this helper, callers must decide which
parts of a URL or identifier are case-sensitive. The helper's cheapness is the
point: replay does not depend on a future richer canonicalizer. No node or UUID
was generated in this pass.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0223a | Implemented identifier helpers | `crates/oag-core/src/canonicalize.rs:68-80` |
| B-0223b | Implemented callers in service layer | `crates/oag-graph/src/identifier.rs:11-41` |
| B-0223c | Implemented NodeId hashing | `crates/oag-core/src/ids.rs:145-151` |
| B-0223d | Caller search | `git grep generate_uuid_identifier origin/main -- crates/**/*.rs` |
| B-0223e | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-core/src/canonicalize.rs` (no output) |

Verification: source inspection via `git show origin/main:<path>`, `git grep`,
and a scoped diff. No node or UUID was generated.

## Change since the previously explained commit

Canonical identifier helpers are unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Finding 0202 records the node
identity consequence; this finding records the helper's exact string rules.

## Next investigation

Trace `oag_graph::roadmap` proposal hub and list behavior to document what a
proposal is, how it is anchored, and what mutations exist.
