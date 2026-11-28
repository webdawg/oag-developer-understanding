# 0227 — REST write DTOs map fields but defer most validation

Claim `B-0227`: at core `fb54e431332a030a566099c76fb2558084765422`, REST
assertion and evidence DTOs rename JSON `type` to `evidence_type`, parse RFC3339
timestamps, and otherwise pass fields to `GraphService`. They cannot set
`extraction_method`, so REST-generated assertions are `Direct`. Alias DTOs parse
`AliasType` at the boundary but leave alias length to the service.

## Order of behavior

1. `EvidenceRequest` expects an optional JSON field named `type`, mapped to
   `evidence_type`, plus URI/title/excerpt/hash, optional timestamp strings,
   `pinned_cid`, and free-form metadata.
2. `into_input` parses `observed_at` and `retrieved_at` with the RFC3339 helper;
   all other fields are copied. It does not validate hash syntax, CID syntax, or
   evidence count.
3. `AssertRequest` defaults `evidence` to an empty vector, converts every
   evidence item, parses its own `observed_at`, and sets `extraction_method:
   None`. The service later defaults that to `Direct`.
4. `DeclareAliasRequest` maps JSON `type` to `alias_type` and calls
   `AliasType::parse` immediately; an unknown type is `InvalidInput` before the
   service is called.
5. Service validation still applies: field lengths, at most 20 evidence items,
   known evidence type during projection, and alias length.

## What is durable, rejected, and left behind

Durable after success: the signed event payload produced by the service. The
DTO layer writes nothing itself. Rejected at this layer: malformed timestamps
and alias types. Rejected later: oversized fields, too many evidence items,
unknown evidence types at projection, and permission failures.

`pinned_cid` is explicitly a caller-asserted, unverified retrieval pointer. REST
callers cannot claim structured or LLM extraction by setting a method; only
internal crawlers pass those methods directly to `GraphService`. No HTTP request
was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0227a | Implemented evidence DTO | `crates/oag-api/src/dto.rs:13-46` |
| B-0227b | Implemented assertion DTO | `crates/oag-api/src/dto.rs:68-100` |
| B-0227c | Implemented alias DTO | `crates/oag-api/src/dto.rs:48-66` |
| B-0227d | Implemented service validation | `crates/oag-graph/src/assert.rs:105-123`, `222-248` |
| B-0227e | New alias DTO since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-api/src/dto.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No HTTP request was executed.

## Change since the previously explained commit

`DeclareAliasRequest` is new at `fb54e431...`; evidence/assert DTO behavior is
unchanged. Finding 0209 records the timestamp helper; this finding records the
full write-side mapping and validation boundary.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining gap from
the journal and revision table.
