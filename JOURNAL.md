# Research journal

## 2026-11-22 — pass 0: pin inputs and plan the first slice

Examined the destination repository and recorded local or shallow-clone heads
for all six targets. No target source was modified. No tests or services were
run. Published as `6123450`.

Pinned:

- `open-agent-graph` `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`
- `oag-mesh` `9f5d89e9fcf944dc16eff61f17543e83fc6ad20c`
- `oag-listend` `aad2d9b2cc763239764fa8ba11ec7e871be00e11`
- `oag-collisions` `dfc8ca95ce9641c29dec6bebe1586936b113c883`
- `oag-imagination-random-data-compute` `7b7dcb8eae70b2df2fa1329fdb7b2dd928e76d29`
- `data-roads` `b5cd2f4e8618f955eb06dd1c4d3edc7234041a7e`

## 2026-11-22 — finding 0001: local assertion commit

Examined `create_assertion`, bearer authentication, permission checks, input
bounds, `GraphService::assert`, `commit_event`, `commit_local_event`, and
`project_assert_relation`.

Learned: one assertion event is signed, inserted, projected, and origin-advanced
in one transaction. Request evidence is committed afterward as separate events,
so HTTP failure does not imply that the assertion was not committed.

Unknown: crash recovery, multi-process locking, remote ingestion, and whether
the HTTP route is actually mounted with additional body limits.

Next: read `ingest_remote_event` and compare duplicate, gap, signature, and
projection behavior with the local path.

## 2026-11-22 — finding 0002: remote ingestion comparison

Examined `ingest_remote_event`, `verify_and_derive_id`, and `validate_chain`.

Learned: remote ingestion is idempotent for an exact duplicate, records a
different same-sequence event as a fork without projecting it, and rejects both
sequence gaps and predecessor mismatches. Its successful path shares insertion,
projection, origin advancement, and transaction commit with local commit.

Unknown: which caller supplies the trusted key, how sync requests ranges, and
whether concurrent ingestion has a lock.

Next: trace the caller and sync-range behavior.

## 2026-11-22 — finding 0003: sync key selection

Examined the pull loop in `oag-sync` and the push handler in its server.

Learned: pull selects a verifying key before fetching a contiguous range and
stops one origin after a fork or ingestion error. Push looks up the same kind of
stored key but continues after individual skipped events.

Unknown: peer discovery, federation admission, and the Reticulum caller.

Next: trace discovery and federation eligibility.

## 2026-11-22 — finding 0004: discovery and federation

Examined `discover_peers` and `federation_allows`.

Learned: discovery stores only peer IDs derived from their advertised keys and
enforces response and table caps. Same-cluster peers bypass federation policy
and minimum-trust checks.

Unknown: the source and administration of cluster membership, and the concrete
policy implementation.

Next: trace `same_cluster` and `FederationPolicy`.

## 2026-11-22 — finding 0005: cluster comparison

Examined `FederationPolicy` and `same_cluster`.

Learned: federation is open or allowlist-based, while cluster admission is a
configured-name comparison against the latest stored claim. Signature checking
is not in the comparison function.

Unknown: where cluster declarations are verified and stored.

Next: trace cluster-claim verification and persistence.

## 2026-11-22 — finding 0006: self-certified clusters

Examined cluster declaration verification and `post_cluster`.

Learned: the signature proves key possession and binds a claimed name, but no
cluster authority authorizes membership. The stored name can later bypass
federation.

Unknown: configuration distribution, broadcast recipients, and any later
constraint.

Next: trace cluster configuration and broadcast behavior.

## 2026-11-22 — finding 0007: cluster broadcast

Examined configuration loading, startup, and declaration broadcast.

Learned: cluster mode is opt-in through `cluster.name`; broadcasts go to every
known peer address and count attempts rather than acknowledgements.

Unknown: the additional behavior of cluster gossip.

Next: trace the cluster gossip loop.

## 2026-11-22 — finding 0008: cluster gossip scheduling

Examined both gossip loops and cluster address selection.

Learned: cluster gossip uses the same sync operation but a narrower address set
and independent interval. It can overlap ordinary gossip, and its membership
inherits self-certified cluster claims.

Unknown: concurrent same-address sync behavior and assertion projection identity
rules.

Next: trace assertion projection identities and repeated-write behavior.

## 2026-11-22 — finding 0009: assertion identity

Examined node, edge, and assertion identity derivation and insertion.

Learned: nodes and edges are deterministic and idempotent; each assertion is a
new event-identified row about a reused edge.

Unknown: status transitions and schema constraints for unexpected duplicate IDs.

Next: trace dispute, retraction, and supersession behavior.

## 2026-11-22 — finding 0010: status transitions

Examined dispute, retraction, and supersession service guards and projectors.

Learned: all three preserve history and update a status label. Ownership is
enforced for retraction before commit, while supersession existence is enforced
during projection. Later status events can overwrite the label.

Unknown: which read APIs expose non-active assertions.

Next: trace assertion read filtering and visibility.

## 2026-11-22 — finding 0011: assertion visibility

Examined direct assertion reads, node listings, and corroboration filtering.

Learned: status does not hide assertions from direct reads. Corroboration uses
active assertions for support and counts disputed assertions separately.

Unknown: the full corroboration formula and API response fields.

Next: trace corroboration scoring.

## 2026-11-22 — finding 0012: corroboration formula

Examined `get_edge_corroboration` and its identity-assurance test.

Learned: support comes from active assertions, disputes reduce agreement, and
source grouping limits repeated citations of one group. Retracted and superseded
rows remain outside the agreement ratio.

Unknown: evidence weights, URI grouping, observation weights, and freshness
constants.

Next: trace those scoring inputs.

## 2026-11-22 — finding 0013: evidence weights and groups

Examined URI grouping, evidence weights, verification weights, and freshness.

Learned: a group contributes only its strongest weight, so repeated citations
from one URI family or actor do not multiply independence. Freshness decays on a
180-day half-life.

Unknown: read authorization boundaries for search, corroboration, and direct
graph reads.

Next: compare those permission checks.

## 2026-11-22 — finding 0014: read permission boundary

Examined the principal REST read handlers and authentication helper.

Learned: those reads share `graph:read`, including historical assertion data.
Write operations use separate permissions. Sync must not be lumped into this
bearer-token boundary.

Unknown: whether human HTML routes bypass the gate.

Next: inspect human read routes.

## 2026-11-22 — finding 0015: human UI key transport

Examined human authentication and link generation.

Learned: HTML reads use the same key and `graph:read` permission, but carry the
raw key in query strings and generated links.

Unknown: whether logs redact that query parameter.

Next: trace human routing and request logging.

## 2026-11-22 — finding 0016: request span fields

Examined custom span construction and nearby route comments.

Learned: the custom route field uses the URL path, excluding the query string.
That does not prove every logger or proxy redacts `key`. Several routes are
explicitly outside bearer authentication.

Unknown: the gateway's alternate trust boundary.

Next: trace gateway query authentication.

## 2026-11-22 — finding 0017: gateway signature boundary

Examined gateway request verification, handler order, and resolution precedence.

Learned: the handler proves key possession, integrity, and freshness, then rate
limits. It does not show bearer or federation authorization.

Unknown: fanout cost, quorum semantics, and later authorization checks.

Next: trace gateway fanout and rate limiting.

## 2026-11-22 — finding 0018: gateway fanout and limits

Examined the reusable rate limiter, fanout, and quorum aggregation.

Learned: gateway requests are limited per verified peer ID, fanout is bounded by
configuration, and quorum requires a minimum number of successful agreeing
results. Failures are dropped rather than retried.

Unknown: replay detection beyond timestamp skew.

Next: trace gateway nonce and response verification.

## 2026-11-22 — finding 0019: gateway nonce scope

Examined response verification and both request paths.

Learned: callers bind responses to their expected nonce, but the server does not
persist seen request nonces. Skew and rate limits are not complete replay
protection.

Unknown: relay hop bounds and authenticated path history.

Next: trace relay loop prevention.

## 2026-11-22 — finding 0020: relay hop bounds

Examined `relay_gateway_query` and signed request construction.

Learned: this implementation stops at zero remaining hops, appends itself to the
path, and skips relays already in that path. The bound travels in the signed
request, but cross-version enforcement remains unverified.

Unknown: mesh's actual dependency revision and imported core surface.

Next: compare mesh and core revisions and begin the connection register.

## 2026-11-22 — finding 0021: mesh/core revision skew

Examined mesh manifest and lockfile.

Learned: mesh tracks core `main` but locks `ce112258`, not inspected core
`87f9e8c1`. Prior findings remain scoped to the inspected checkout.

Unknown: actual API differences between those core revisions.

Next: compare the locked and inspected `oag-core` and `oag-crypto` exports.

## 2026-11-22 — finding 0022: locked source comparison

Fetched locked core `ce112258` read-only and compared it with inspected core.

Learned: `oag-core` and `oag-crypto` source directories are identical. The only
changes between the commits are documentation and future-work files.

Unknown: which shared types mesh actually imports and whether any runtime path
connects the repositories.

Next: inspect mesh exports and imports.

## 2026-11-22 — finding 0023: mesh shared primitives

Searched mesh for core imports and inspected bridge and corroboration calls.

Learned: mesh reuses canonical JSON and signing primitives only. It does not
inspectably import core graph, event, storage, or sync services.

Unknown: bridge declaration lifecycle and failure behavior.

Next: trace one bridge declaration end to end.

## 2026-11-22 — finding 0024: mesh bridge declarations

Examined bridge signing, verification, and in-memory tree insertion.

Learned: verification proves a self-signed claim and freshness. Distinct peers
increase corroboration, while repeats do not. No authorization or persistence is
implemented in this path.

Unknown: the threshold that turns corroboration into accepted membership.

Next: trace `MeshTree` corroboration rules.

## 2026-11-22 — finding 0025: caller-selected thresholds

Examined `MeshTree` query methods.

Learned: the tree counts distinct signers and lets every caller choose the
minimum. Attesting a base-cluster name does not prove that a reporting peer
belongs to it.

Unknown: whether any production caller selects a default threshold.

Next: trace claim-report corroboration into this tree.

## 2026-11-22 — finding 0026: no selected threshold caller

Searched mesh source for production threshold callers.

Learned: the tree can filter by a caller-supplied minimum, but no inspected
production caller does so. Tests only read counts.

Unknown: imagination's locked core revision and imported surface.

Next: pin and compare imagination.

## 2026-11-22 — finding 0027: imagination revision skew

Examined imagination manifest and lockfile.

Learned: imagination locks a third core revision, `4bdef2d0`, and directly
depends on `oag-storage` as well as core and crypto.

Unknown: whether that locked storage source matches inspected core and which
functions imagination calls.

Next: fetch and compare the locked storage revision.

## 2026-11-22 — finding 0028: imagination storage read path

Fetched locked core `4bdef2d0` and inspected `NodeAdapter::load`.

Learned: the relevant crate source matches inspected core. Imagination reads one
snapshot of a tensor pad and peer addresses. `open_pool` may apply embedded core
migrations despite the adapter's own queries being reads.

Unknown: randomness, reproducibility, and routing verification.

Next: trace `SoftwareRandom` and engine routing.

## 2026-11-22 — finding 0029: routing reproducibility

Examined `SoftwareRandom` and `route`.

Learned: the decision is deterministic given pad, ordered neighbors, and seed.
The default seed is fresh software randomness and is not recorded by the
inspected adapter, so another peer cannot reproduce it from public state alone.

Unknown: listend admission and content validation.

Next: trace listend content admission.

## 2026-11-22 — finding 0030: listend identity versus sniffing

Examined `AudioItem::verify` and `AudioFormat::sniff`.

Learned: BLAKE3 proves exact bytes, while sniffing recognizes selected
signatures. Neither decodes or authorizes audio.

Unknown: admission order, persistence, and eviction.

Next: trace `AudioStore::accept`.

## 2026-11-22 — finding 0031: listend admission order

Examined `AudioStore::accept` and `persist`.

Learned: signature and size checks precede storage. New directory-backed audio is
written before in-memory publication, while sidecar and mirror failures have
different failure semantics. Write completion is not fsync durability.

Unknown: collisions indexing, query, and eviction behavior.

Next: trace collisions.

## 2026-11-22 — finding 0032: collisions prefix contradiction

Examined insertion, query, and constructor comments.

Learned: one prefix level shifts away all but the highest bit, despite a comment
saying it indexes exact hashes. Buckets store string IDs, not merely small
integers.

Unknown: whether Data Roads contains executable implementation.

Next: inventory Data Roads.

## 2026-11-22 — finding 0033: Data Roads classification

Inventoried the tracked Data Roads files and read its README.

Learned: the repository is an RFC and companion paper. Its proposed core and mesh
integration has no executable implementation in the tracked inventory.

Unknown: detailed RFC requirements and unresolved design sections.

Next: extract the RFC's ownership and access requirements as proposals.

## 2026-11-22 — finding 0034: unresolved Data Roads requirements

Read the RFC terminology, principles, architecture, lifecycle, open questions,
and security heading.

Learned: ownership, custody, access, and compensation are explicitly separate,
but event mappings, redundancy, renewal, disputes, and threat modeling are
unresolved. The RFC itself says several mesh-backed guarantees do not exist.

Unknown: the linked mesh object-history RFC and its revision.

Next: refresh the destination index and coverage summary.

## 2026-11-22 — finding 0035: object-history proposal

Read `oag-mesh/spec/07-object-history-and-ownership-rfc.md` at `9f5d89e9` and searched implementation crates.

Learned: the RFC is explicitly unimplemented. It separates identity, ownership, custody, authorship, and access, and states that signatures and tags do not prove legal or physical facts.

Unknown: mesh transport's actual persistence and retry behavior.

Next: trace mesh transport push behavior.

## 2026-11-22 — finding 0036: mesh transport durability

Examined `MeshState`, bridge receive/push, and both broadcast helpers.

Learned: accepted mesh state is in memory. Broadcast is best-effort, does not retry higher proof-of-work demands, and a 204 does not establish network-wide replication.

Unknown: anonymous-event deduplication and difficulty escalation.

Next: trace anonymous-event recording.

## 2026-11-22 — finding 0037: anonymous corroboration

Examined anonymous-event validation, proof-of-work, and recording.

Learned: corroboration is a count of accepted submissions. Difficulty escalates by four bits per existing report, but repeated content is not inherently deduplicated.

Unknown: claim-report cross-checking and its default threshold.

Next: trace claim-report corroboration.

## 2026-11-22 — finding 0038: claim-report cross-check

Examined claim-report admission, ranking, and bridge cross-checking.

Learned: ranking deduplicates peers and cluster strings. Cross-checking only verifies that a cluster name was attested; it does not prove the reporter's membership.

Unknown: core transaction rollback and crash behavior after a commit error.

Next: trace the SQLite transaction boundary.

## 2026-11-22 — finding 0039: SQLite durability boundary

Examined pool options and transaction usage.

Learned: WAL, foreign keys, busy timeout, and a bounded pool are configured. Event functions use sqlx transactions, but no explicit immediate transaction, synchronous setting, or crash test proves power-loss atomicity.

Unknown: schema constraints protecting event sequence and origin head.

Next: inspect the events schema and origin update.

## 2026-11-22 — finding 0040: event uniqueness

Examined the initial schema and event insertion helpers.

Learned: event ID and origin sequence are unique, but `INSERT OR IGNORE` turns conflicts into a false result. Origin advancement overwrites both sequence fields and does not prove contiguity by itself. Predecessor links are not foreign-keyed.

Unknown: canonical event identity and signature-domain binding.

Next: trace event-ID derivation.

## 2026-11-22 — finding 0041: event identity

Examined event construction, canonical JSON, and ID derivation.

Learned: the signature covers domain-prefixed canonical unsigned JSON. The event ID hashes the canonical signed envelope under the event domain again. Timestamp, sequence, predecessor, origin, payload, and signature can all change identity.

Unknown: exact serialized field names for assertion payloads.

Next: trace `AssertRelation` serialization.

## 2026-11-22 — finding 0042: assertion serialization

Examined `EventPayload` and `AssertRelationPayload`.

Learned: assertions are tagged `ASSERT_RELATION` and flattened into the signed event. Signed field names differ from the HTTP request after service-layer canonicalization.

Unknown: which raw inputs converge to one canonical identifier and node ID.

Next: trace identifier canonicalization.

## 2026-11-22 — finding 0043: identifier canonicalization

Examined assertion input canonicalization and URL normalization.

Learned: HTTP(S) inputs get selected normalization and a `url:` prefix; scheme-like strings pass through lowercased; other text becomes a concept slug. These strings determine node identity.

Unknown: actor declaration and API-key lifecycle.

Next: trace actor and API-key creation.

## 2026-11-22 — finding 0044: actor keys

Examined actor declaration, key creation, revocation, projection, and active-key lookup. Published after `d4d179c`.

Learned: a verified public key stabilizes actor identity; keyless actors are event-scoped. Raw keys are returned once, and authentication excludes revoked hashes.

Unknown: the permission inventory and bootstrap admin-key path.

Next: trace permissions and first-key bootstrap.

## 2026-11-22 — finding 0045: bootstrap admin

Examined the permission enum, admin bypass, and first-run bootstrap.

Learned: the first empty database receives one printed admin key for a keyless service actor. Admin satisfies every specific permission check. Bootstrap does not recur after any actor exists.

Unknown: crawl permission enforcement and private-network guards.

Next: trace crawl authorization and egress checks.

## 2026-11-22 — finding 0046: crawl network policy

Examined the crawl handler, redirect validation, and blocked-IP predicate.

Learned: `graph:crawl` authorizes triggering egress but cannot override the server's private-network policy. Redirects are revalidated and connections are pinned to checked addresses. This is not a universal SSRF proof.

Unknown: robots, content-type acceptance, and what fetched content becomes in the graph.

Next: trace post-guard crawl processing.

## 2026-11-22 — finding 0047: crawl assertion pipeline

Examined robots checking, content-type acceptance, and baseline assertion creation.

Learned: robots and fetch failures stop before graph writes. A successful fetch creates a high-confidence page assertion before optional extraction, and pinning failure does not fail the crawl.

Unknown: which internal actor and permissions authorize crawler assertions.

Next: trace `crawler_auth`.

## 2026-11-22 — finding 0048: crawler assertion authority

Examined crawler and LLM extractor authentication helpers.

Learned: crawler assertions use a reused local actor named `crawler` with only `graph:assert`. The triggering caller's API key is not the recorded author, and no crawler API key is issued.

Unknown: whether actor name lookup is unique.

Next: trace `find_actor_by_name` and its storage constraint.

## 2026-11-22 — finding 0049: actor name ambiguity

Examined actor schema, insertion, and name/type lookup.

Learned: name plus type is not unique. The lookup asks SQLite for one optional row without ordering, so duplicate crawler actors can make reuse ambiguous.

Unknown: node alias duplication and read behavior.

Next: trace node alias insertion and lookup.

## 2026-11-22 — finding 0050: node aliases

Examined alias schema, insertion, listing, and repository search use.

Learned: aliases are unique only per node. Repeats preserve the first row, duplicate text may identify multiple nodes, and no inspected reverse lookup resolves an alias to one node.

Unknown: lexical search disclosure and suppression behavior.

Next: trace node search and suppression.

## 2026-11-22 — finding 0051: search suppression

Examined lexical search, FTS triggers, query sanitization, and suppression.

Learned: search matches quoted sanitized terms in name, description, and canonical identifier. Admin suppression excludes a node from that query without deleting graph state or preventing direct lookup.

Unknown: whether semantic search honors the same suppression table.

Next: trace semantic search and embeddings.

## 2026-11-22 — finding 0052: semantic suppression gap

Examined semantic ranking and embedding retrieval.

Learned: semantic search scans all stored embeddings and resolves nodes directly. It does not consult the lexical suppression table, so suppression is not a global disclosure boundary.

Unknown: when embeddings are built, refreshed, and invalidated.

Next: trace embedding lifecycle.

## 2026-11-22 — finding 0053: embedding lifecycle

Examined embedding recomputation and its CLI command.

Learned: embeddings are wiped and rebuilt in a batch. Normal writes do not refresh them, so semantic search can lag node changes until an operator runs recomputation.

Unknown: authority recomputation and whether its scores affect search.

Next: trace authority scoring.

## 2026-11-22 — finding 0054: authority scoring

Examined PageRank and authority recomputation.

Learned: authority is an operator-triggered batch score over local edges. It is cleared and replaced, does not update on writes, and is not used by the inspected search rankers. Assertion status is not considered.

Unknown: which projections rebuild preserves or replays.

Next: trace rebuild behavior.
