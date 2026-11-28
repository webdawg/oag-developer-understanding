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

## 2026-11-22 — finding 0055: rebuild preservation

Examined projection clearing and replay.

Learned: rebuild deletes derived graph rows and replays the event log, while preserving events, peer state, authority, embeddings, redactions, and search suppression. It reapplies redactions but does not refresh stale caches.

Unknown: what evidence redaction removes and whether raw event payloads remain readable.

Next: trace evidence redaction.

## 2026-11-22 — finding 0056: evidence redaction limits

Examined evidence redaction, provenance, and history.

Learned: admin redaction blanks projected title and excerpt and records a tombstone. History still deserializes and returns the original canonical event payload to `graph:read` callers.

Unknown: whether actor identity-URI redaction has the same event-log residue.

Next: trace actor identity redaction.

## 2026-11-22 — finding 0057: actor URI redaction residue

Examined actor URI redaction, declaration payload, and history object types.

Learned: redaction blanks the projected URI and preserves a tombstone. The original URI remains in the declaration event payload. The history route does not list actor events, but that is not erasure.

Unknown: what unauthenticated status and metrics routes disclose.

Next: trace status and metrics disclosure.

## 2026-11-22 — finding 0058: unauthenticated operational routes

Examined `/api/v1/status` and `/metrics`.

Learned: neither route uses bearer authentication. Status discloses the local peer ID, and metrics discloses aggregate graph, crawl, sync, database-size, and replication counts.

Unknown: whether MCP uses the same authorization gates.

Next: trace MCP authentication and tool permissions.

## 2026-11-22 — finding 0059: MCP authorization

Examined MCP bearer extraction and representative read, assert, crawl, and redaction tools.

Learned: MCP uses the same key lookup and service permission checks as REST. It is not an authorization bypass, though crawler assertions still use the internal crawler actor.

Unknown: listend retrieval authentication and content-addressed serving.

Next: trace listend serving.

## 2026-11-22 — finding 0060: listend HTTP access

Examined HTTP routes and `AudioStore::serve` at listend `aad2d9b2`.

Learned: the HTTP carrier has no authentication or TLS in the inspected server. Hash listing and content retrieval are public, and publication is gated only by audio sniffing and size.

Unknown: collisions query cutoff and ranking behavior.

Next: trace collisions query ranking.

## 2026-11-22 — finding 0061: collision ranking limits

Examined `collide`, `collide_by_hamming`, and the eight-bit minimum prefix.

Learned: Hamming ranking only reorders candidates already found by prefix buckets. Items differing in the top eight bits are invisible to the normal query, and a one-level index can produce an empty candidate loop.

Unknown: whether default unigram SimHash ignores token order.

Next: trace weighted SimHash accumulation.

## 2026-11-22 — finding 0062: SimHash order

Examined `simhash_weighted` and `simhash_with_domain`.

Learned: per-token bit votes are summed. The same tokens and weights produce the same hash in any order. Order matters only when a tokenizer emits order-dependent units. Equal hashes do not prove equal meaning.

Unknown: subgraph traversal limits and cycle handling.

Next: trace subgraph retrieval.

## 2026-11-22 — finding 0063: subgraph traversal

Examined `get_subgraph`.

Learned: traversal is bidirectional, cycle-safe, and status-unfiltered. `max_nodes` is checked between edges, so one accepted edge and later frontier nodes can exceed the requested cap.

Unknown: REST default depth and maximum, and whether request values are clamped.

Next: trace subgraph API limits.

## 2026-11-22 — finding 0064: subgraph request limits

Examined the subgraph handler and query struct.

Learned: omitted depth and max-nodes default to 1 and 200, but supplied values are not clamped.

Unknown: whether identifier resolution chooses one node or returns candidates.

Next: trace `resolve`.

## 2026-11-22 — finding 0065: identifier resolution

Examined `GraphService::resolve` and its REST adapter.

Learned: exact canonical matches return confidence 1.0. Nonexact input returns up to ten lexical candidates or not found; the service does not guess one candidate. Confidence here is not corroboration.

Unknown: transfer-receipt authentication.

Next: refresh the coverage index, then trace transfer receipts.

## 2026-11-22 — finding 0066: transfer signature boundary

Examined transfer request verification, receipt binding, and the fetch handler.

Learned: transfer authentication is a self-signed peer request plus rate limiting. It does not use bearer tokens or federation admission. Receipts bind one exchange but do not grant graph authorization.

Unknown: relay hop handling and arbitrary CID fetch cost.

Next: trace transfer relay forwarding.

## 2026-11-22 — finding 0067: transfer relay forwarding

Examined `relay_fetch`.

Learned: a verified caller can cause this peer to request its chosen CID from configured relays. Hop count and path membership bound forwarding; there is no CID allowlist in the inspected function.

Unknown: response size limits and content-hash verification before bytes are returned.

Next: trace `fetch_and_verify` result checks.

## 2026-11-22 — finding 0068: transfer download order

Examined `fetch_and_verify`.

Learned: the client downloads the full success body before hash and receipt verification. The inspected function has no response-size cap, so a bad receipt does not avoid the download cost.

Unknown: whether the server-side transfer response enforces a size bound.

Next: trace the server transfer response limit.

## 2026-11-22 — finding 0069: server transfer size boundary

Examined the server response construction in `fetch_with_receipt_inner`.

Learned: the handler hashes and returns the full fetched vector and records its length. No transfer-specific maximum was found. Provider-level limits remain unverified.

Unknown: IPFS provider fetch bounds and authentication.

Next: trace provider fetch limits.

## 2026-11-22 — finding 0070: IPFS fetch accumulation

Examined Kubo-compatible and embedded IPFS fetch implementations.

Learned: both accumulate every chunk into a vector. No size cap is visible in either function. The Kubo path can attach a bearer API key, but that is endpoint authentication, not a byte limit.

Unknown: client timeout, redirects, and whether the configured IPFS endpoint is trusted.

Next: trace the Kubo HTTP client builder.

## 2026-11-22 — finding 0071: Kubo client defaults

Examined `KuboHttpProvider::new` and `[ipfs]` configuration.

Learned: pinning is disabled by default. Kubo is used only with an operator-configured base URL. The client constructor sets no explicit timeout, redirect, or size policy, and the API key is optional.

Unknown: embedded listener exposure.

Next: trace the embedded IPFS listen default.

## 2026-11-22 — finding 0072: embedded listener default

Examined embedded provider startup and its configuration default.

Learned: embedded mode is opt-in, but its default listen address is all IPv4 interfaces on an ephemeral WebSocket port, with mDNS enabled. Actual bind and announcement behavior were not executed.

Unknown: whether the public IPFS site page discloses those dial addresses.

Next: trace `/ipfs-site/{cid}`.

## 2026-11-22 — finding 0073: public IPFS dial disclosure

Examined the IPFS site page and startup address selection.

Learned: the unauthenticated page does not fetch content, but it can embed the first embedded dial address or an operator override. CID shape is checked; CID possession and authorization are not.

Unknown: Reticulum ingress authentication.

Next: trace the Reticulum listener.

## 2026-11-22 — finding 0074: Reticulum sync ingress

Examined the Reticulum listener, request handler, and configuration default.

Learned: TCP listening is opt-in. When enabled, hello, event, and peer requests are unauthenticated and can return signed event payloads and peer addresses. A global rate limit is not authentication.

Unknown: whether the HTTP sync event endpoint adds a federation or payload bound that Reticulum lacks.

Next: compare HTTP sync event retrieval.

## 2026-11-22 — finding 0075: HTTP sync read disclosure

Examined `get_events`, its route comment, and the push path's federation check.

Learned: HTTP event reads are unauthenticated and do not check federation. The comment equates author signatures with reader authorization, which the code does not enforce. The response is capped at 1,000 events.

Unknown: the exact sync rate-limit window and whether it is global or per caller.

Next: trace `SyncRateLimiter`.

## 2026-11-22 — finding 0076: global sync rate limit

Examined `SyncRateLimiter`.

Learned: the limit is 600 requests per process per minute, with no per-caller identity. It bounds aggregate load but does not authenticate readers or prevent one caller from crowding out others.

Unknown: the exact fields returned by HTTP hello and peer-list routes.

Next: trace those sync disclosure routes.

## 2026-11-22 — finding 0077: sync discovery disclosure

Examined hello, heads, peers, and replication-status.

Learned: these unauthenticated routes disclose this peer's key, known peer addresses, and lagging peer IDs with reported sequences. The global rate limit does not redact them.

Unknown: whether discovered addresses are later contacted without validation.

Next: trace gossip use of discovered peer addresses.

## 2026-11-22 — finding 0078: discovered sync targets

Examined address storage, sync URL construction, and the response cap.

Learned: addresses from a peer this node already syncs are stored verbatim and later requested. There is no inspected private-network or scheme guard. One response is capped at 4 MiB.

Unknown: default redirect behavior and whether non-HTTP addresses are rejected by the HTTP client.

Next: inspect sync address assumptions in tests and client errors.

## 2026-11-22 — finding 0079: sync redirects

Examined `SyncClient` and the locked reqwest 0.13.5 defaults.

Learned: OAG has no scheme or host allowlist. The default client follows up to 10 redirects with no host filter and has no application-level total timeout. Peer-key checks happen after the redirected response.

Unknown: whether the original address remains bound to the peer after a redirected hello.

Next: trace address retention after hello.

## 2026-11-22 — finding 0080: redirected identity binding

Examined `sync_with_peer` and `SyncClient::hello`.

Learned: the stored address is the pre-redirect argument. The peer identity comes from the final body. The client API does not return the final URL, so the application cannot detect the host change.

Unknown: whether hello heads can falsify replication status through that path.

Next: trace known-head updates from hello.

## 2026-11-22 — finding 0081: self-reported replication

Examined hello head storage and `replication_status`.

Learned: a hello sequence at least as high as the local head counts as fully caught up. The target is at least 3 and grows with the square root of known peers. The inspected function reports the result; it does not itself change replication behavior.

Unknown: whether any caller uses `meets_target` as an operational gate.

Next: search callers of replication status.

## 2026-11-22 — finding 0082: replication target is observational

Searched crate callers of `meets_target` and read the CLI status commands.

Learned: the value is printed or serialized. No inspected caller uses it to block a write, backup, or sync.

Unknown: what `oag backup` copies and whether it includes key material.

Next: trace the backup command.

## 2026-11-22 — finding 0083: database backup

Examined `VACUUM INTO` and the CLI backup command.

Learned: backup copies the whole database, including event payloads and key hashes, but not raw API keys unless they were stored inside a payload. Optional pinning uploads that entire snapshot. Filesystem access is the authorization boundary.

Unknown: whether a restore path revalidates signatures and redactions.

Next: search for a restore command.

## 2026-11-22 — finding 0084: restore scope

Searched restore commands and read identity restore and key loading.

Learned: there is no inspected database-snapshot restore command. Identity restore copies a separate 32-byte private key, refuses overwrite without `--force`, and does not verify that the key matches existing events.

Unknown: first-startup identity creation and file permissions.

Next: trace `identity.key` creation.

## 2026-11-22 — finding 0085: missing identity file

Examined `load_or_generate`, `save`, and serve startup.

Learned: a missing persistent key file generates a new peer and saves it with mode 0600 on Unix. Startup does not check that the key matches the database. Ephemeral mode ignores the file entirely.

Unknown: whether ephemeral mode still opens and writes the persistent database.

Next: trace ephemeral startup against the database path.

## 2026-11-22 — finding 0086: ephemeral identity scope

Examined identity configuration and serve startup.

Learned: ephemeral mode generates a fresh signing identity but opens the same SQLite file. It does not create a disposable database or sandbox.

Unknown: whether the new peer ID starts a separate origin chain in that database.

Next: connect ephemeral identity to per-peer origin sequencing.

## 2026-11-22 — finding 0087: separate origin chains

Examined local sequence selection and startup identity choice.

Learned: a new peer ID with no origin row starts at sequence 1. The old chain remains in the same database and is not re-signed or erased.

Unknown: whether peers must discover the new key before accepting its first event, and whether the old peer remains advertised.

Next: trace key discovery for a newly generated local identity.

## 2026-11-22 — finding 0088: new peer key discovery

Examined hello key selection, peer upsert, address uniqueness, and peer removal callers.

Learned: a direct hello supplies the key for that peer's own events. Transitive origins need a stored derived key. A new identity is a new peer row; the old peer remains until an operator removes it, and the same address may be stored for both.

Unknown: whether `remove_peer` cleans every related record.

Next: trace `remove_peer` cleanup.

## 2026-11-22 — finding 0089: incomplete peer removal

Examined `remove_peer` and the related peer schemas.

Learned: removal deletes addresses and the peer row only. Forks, known heads, and cluster claims remain. A remaining cluster claim can still satisfy `same_cluster` because that lookup does not require the peer row.

Unknown: whether presence and going-offline records grant trust after removal.

Next: trace peer presence and trust scoring.

## 2026-11-22 — finding 0090: presence survives removal

Examined `compute_trust`, `trust_score`, and the removal statements.

Learned: a missing peer row is treated as not forked, while a remaining presence row can still produce positive trust. Address-based restart grace cannot be found after addresses are deleted.

Unknown: who can write a presence row for an arbitrary peer ID.

Next: trace the presence heartbeat endpoint.

## 2026-11-22 — finding 0091: presence admission

Examined presence verification and `post_presence`.

Learned: any self-signed fresh heartbeat creates a presence row without a peer-table membership. It cannot forge another peer ID. Going-offline address records require stored addresses.

Unknown: whether a cluster claim can likewise be stored before the peer row and still bypass federation.

Next: confirm cluster-claim storage prerequisites.

## 2026-11-22 — finding 0092: cluster claim without membership

Examined `post_cluster` and `same_cluster`.

Learned: a self-signed cluster claim is stored without a peer-table row and can bypass federation for that new peer ID. It still does not prove authorization to use the cluster name.

Unknown: whether the federation bypass alone lets events be fetched when the verifying key is absent.

Next: trace the fetch loop's key requirement after federation allows the origin.

## 2026-11-22 — finding 0093: federation bypass versus verifying key

Examined the pull-loop key selection and the push handler's stored-key requirement.

Learned: federation admission does not provide a verifying key. Non-contacted origins without a stored key are skipped. A cluster claim alone cannot make their events ingest.

Unknown: whether any other ingress accepts events after only a cluster claim.

Next: search event-ingestion callers for a path that bypasses the stored-key requirement.

## 2026-11-22 — finding 0094: ingest caller inventory

Searched production `ingest_remote_event` callers and read the Reticulum client's key selection.

Learned: all three production callers select a verifying key first. A cluster claim is not an ingestion path and cannot replace a missing key.

Unknown: whether the Reticulum client authenticates the remote destination before trusting its hello key.

Next: trace Reticulum hello verification and link setup.

## 2026-11-22 — finding 0095: Reticulum hello binding

Examined announce waiting, hello checks, and Reticulum address derivation.

Learned: the client matches the dialed address hash and checks that the hello key matches its own peer ID. It does not prove those two identities are the same. Library-level announce authenticity was not inspected.

Unknown: whether Reticulum peer discovery checks key derivation before storing a peer.

Next: compare Reticulum and HTTP peer discovery.

## 2026-11-22 — finding 0096: Reticulum discovery guard

Compared HTTP and Reticulum peer-list storage.

Learned: HTTP rejects a peer ID that does not derive from its advertised key. The Reticulum loop stores the pair without that check. The first stored key is not replaced on conflict.

Unknown: whether discovered Reticulum addresses are later dialed automatically.

Next: trace use of stored `reticulum:` addresses.

## 2026-11-22 — finding 0097: Reticulum address label

Searched readers of the `reticulum:` address prefix and compared them with HTTP gossip.

Learned: the prefix is written once and never parsed. HTTP gossip can later treat it as a URL base. It is not a dial plan.

Unknown: whether malformed addresses are retried forever and how they mix with bootstrap addresses.

Next: trace gossip address enumeration and deduplication.

## 2026-11-22 — finding 0098: gossip retries

Examined ordinary gossip address assembly and `sync_round`.

Learned: every stored address is retried on every tick. Failures do not remove it. Dedup is exact string equality before slash trimming.

Unknown: whether any other loop caches addresses across ticks.

Next: confirm gossip has no long-lived address cache beyond the current tick.

## 2026-11-22 — finding 0099: per-tick address copy

Examined both gossip loops and peer address deletion.

Learned: addresses are copied into a local vector each tick. Removal is visible on the next tick, but the current tick can still use its copy. Bootstrap addresses are captured at spawn and are not removed with peer rows.

Unknown: whether bootstrap addresses are validated before the loop starts.

Next: trace bootstrap address configuration.

## 2026-11-22 — finding 0100: bootstrap addresses

Examined network configuration and serve startup.

Learned: bootstrap peers are unvalidated strings. Empty means passive inbound replication. Non-empty strings are retried every 30 seconds by default without a load-time scheme or host check.

Unknown: whether `oag peer add` validates or persists addresses.

Next: trace manual peer addition.

## 2026-11-22 — finding 0101: manual peer add

Examined `peer_add` and the hello storage point.

Learned: the operator string is requested immediately and stored after a successful hello. There is no prior allowlist. `peer_sync` rejects stored `reticulum:` addresses, unlike ordinary gossip.

Unknown: what `peer add-reticulum` trusts before dialing.

Next: trace that command.

## 2026-11-22 — finding 0102: Reticulum peer add

Examined `peer_add_reticulum` and its dial call.

Learned: the address hash is parsed, but the TCP endpoint is not validated by OAG. The command can create `identity.key` before dialing and can return success while reporting per-origin warnings.

Unknown: the exact hash grammar and TCP constructor rejection behavior.

Next: trace hash parsing and the TCP client constructor.

## 2026-11-22 — finding 0103: Reticulum hash wrapper

Examined `parse_address_hash`.

Learned: OAG only trims surrounding slashes and delegates. It does not validate the TCP endpoint. The dependency's exact hex grammar was not inspected.

Unknown: accepted hash length and alphabet.

Next: inspect the locked Reticulum address parser if available locally.

## 2026-11-22 — finding 0104: Reticulum hash grammar

Inspected locked reticulum 0.1.0 `AddressHash::new_from_hex_string`.

Learned: the hash is 16 bytes. Strings shorter than 32 hex characters error. Longer strings use only the first 32 characters. Invalid digits panic through `unwrap` rather than returning `IncorrectHash`.

Unknown: TCP client constructor validation.

Next: trace `TcpClient::new` in the locked crate.

## 2026-11-22 — finding 0105: Reticulum TCP client

Inspected locked `TcpClient::new` and its connect loop.

Learned: the constructor does not parse host or port. Connect failures are retried every five seconds with no inspected retry limit.

Unknown: listend IPFS retrieval authentication and content checks.

Next: trace `GET /ipfs/{cid}`.

## 2026-11-22 — finding 0106: listend IPFS fetch

Examined the IPFS HTTP route and `IpfsPublisher::cat`.

Learned: the route is unauthenticated and can cat a caller-chosen CID from the configured node. CID characters and response size are bounded. Audio sniffing gates the response, but the CID multihash is not verified.

Unknown: how the IPFS API address is configured and whether it is cleartext.

Next: trace listend IPFS configuration.

## 2026-11-22 — finding 0107: listend IPFS address

Examined `--ipfs-api` and `split_api`.

Learned: HTTPS is refused. The accepted address is cleartext HTTP or a bare host. The cat request adds no Authorization header. Startup also offers stored audio when the flag is set.

Unknown: the startup mirror budget and failure behavior.

Next: trace `mirror_existing`.

## 2026-11-22 — finding 0108: startup mirror

Examined `mirror_existing` and `offer_to_ipfs`.

Learned: `--ipfs-api` offers every stored item that lacks a CID, within 30 seconds, without per-item confirmation. Failures are recorded and do not stop startup. The printed count is attempts, not successes.

Unknown: whether failed mirrors are durable.

Next: trace `persist_cid` and the mirror log lifetime.

## 2026-11-22 — finding 0109: mirror durability

Examined CID sidecars and the mirror log.

Learned: only successful CIDs are persisted. Failures live in a 64-entry memory log and are retried after restart. A lost sidecar can also cause a successful item to be offered again.

Unknown: collisions eviction order.

Next: trace collisions index replacement and eviction.

## 2026-11-22 — finding 0110: collisions eviction

Examined `insert_units` and `enforce_capacity`.

Learned: eviction is oldest-first. Re-indexing moves an item to the newest end. Zero capacity disables eviction rather than rejecting inserts. Rank is not used.

Unknown: imagination source-failure behavior.

Next: trace imagination node and source failure handling.

## 2026-11-22 — finding 0111: imagination failure handling

Examined randomness sources and `observe_hop`.

Learned: sources always return 32 bytes. Hardware and missing real data fall back to software randomness. A failed hop multiplies one weight by `exp(-0.1)` and does not abort the engine.

Unknown: whether a real byte-device source reports short reads.

Next: trace `DeviceRandom`.

## 2026-11-22 — finding 0112: device randomness fallback

Examined `DeviceRandom::next`.

Learned: only an exact 32-byte device read is returned. Missing, unreadable, and short reads fall back to software randomness with no status bit or log, despite the comment calling the fallback documented.

Unknown: whether mesh senders can observe a dropped in-memory message.

Next: trace mesh transport delivery acknowledgements.

## 2026-11-22 — finding 0113: mesh drop visibility

Examined broadcast, direct push, and receive handlers.

Learned: broadcast returns unit and only logs per-peer failures. Direct push returns an address and status or request error. A 204 is local memory acceptance. Restart loss and cross-check drops are not reported to the original sender.

Unknown: whether a receiver relays an accepted message.

Next: trace receive handlers for rebroadcast.

## 2026-11-22 — finding 0114: mesh relay

Compared receive handlers, broadcast call sites, and `spec/04-transport.md`.

Learned: receivers do not relay. Broadcast reaches only the sender's configured peers. The specification agrees there is no anti-entropy pull. Its test count was not executed.

Unknown: whether bridge submission has any authentication beyond the signature.

Next: trace bridge-declaration admission.

## 2026-11-22 — finding 0115: bridge admission

Examined the bridge route, `verify`, and `build_and_sign`.

Learned: admission checks key pairing, signature, and a 300-second clock window. It does not authenticate the caller or rate-limit submissions. The self-reference check exists only in the signing helper, not in verification.

Unknown: whether one signer can grow the in-memory tree without a bound.

Next: trace `MeshTree` growth.

## 2026-11-22 — finding 0116: bridge tree growth

Examined `MeshTree` keys and the bridge route.

Learned: identical edges deduplicate the signer. Distinct group or member strings add unbounded keys. No application string or edge cap was found. The framework body limit was not inspected.

Unknown: whether the anonymous-event log has a retention cap.

Next: trace anonymous-event recording and escalation.

## 2026-11-22 — finding 0117: anonymous-event retention

Examined `AnonymousEventLog::record` and the difficulty formula.

Learned: proof of work starts at 16 bits and grows by 4 bits per stored report on the same nonce. A new nonce resets the cost. Nothing caps retained events. Overflow behavior of the `u32` formula was not inspected.

Unknown: whether claim-report storage has a retention cap.

Next: trace claim corroboration storage.

## 2026-11-22 — finding 0118: claim-report retention

Examined `ClaimCorroboration::add` and its difficulty function.

Learned: a new cluster pays escalating proof of work. A repeat cluster name pays zero bits and is still appended. Query deduplication does not shrink the vector. No claim or cluster cap was found.

Unknown: which duplicates the best-value query hides.

Next: trace `best_corroborated_value`.

## 2026-11-22 — finding 0119: claim query dedup

Examined `best_corroborated_value`.

Learned: the query counts distinct clusters and peers and does not report stored duplicates. Equal counts have no stable tie break because the map iteration order is arbitrary.

Unknown: how the HTTP response represents a missing claim versus a tie.

Next: trace the best-value HTTP response.

## 2026-11-22 — finding 0120: best-value null versus tie

Examined both best-value handlers and `ClaimAgreement`.

Learned: a missing claim is HTTP 200 with `best: null`. A present claim returns one winner. Ties have no flag or alternate list. The route is unauthenticated and node-local.

Unknown: how `min_bridge_corroboration` treats zero and a missing query value.

Next: trace the cross-check threshold.

## 2026-11-22 — finding 0121: cross-check threshold

Examined the query default and `is_attested_base_cluster`.

Learned: a missing threshold is 1. Zero accepts any existing base-cluster edge but not an unknown name. The caller selects the threshold on an unauthenticated route.

Unknown: whether a claim report's observed value hash is format-checked.

Next: trace claim-report verification.

## 2026-11-22 — finding 0122: claim value string

Examined `UnsignedClaimReport` and `verify`.

Learned: the signature and 300-second clock check do not validate `observed_value_hash` as a hash. Agreement is exact string equality. The hash example in the comment is intent, not a check.

Unknown: whether any mesh caller computes a content hash before signing.

Next: search for `blake3_content_hash` in the mesh crate.

## 2026-11-22 — finding 0123: absent content-hash caller

Searched mesh call sites and compared them with the inspected core hash helper.

Learned: mesh never calls `blake3_content_hash`. Tests sign literal `blake3:` strings. Core defines the helper, but mesh locks a different core git revision that was not re-read.

Unknown: how core remote ingest treats a missing sequence number.

Next: trace ingest gap handling.

## 2026-11-22 — finding 0124: sequence gaps

Examined `ingest_remote_event` and `validate_chain`.

Learned: a missing next sequence is rejected and not queued. An exact duplicate at an occupied sequence is `AlreadyKnown`. A different event at that sequence is a recorded fork and does not advance the head.

Unknown: whether the sync client can still offer a gapped sequence.

Next: trace the sync client's range fetch.

## 2026-11-22 — finding 0125: sync range contiguity

Examined the client range request, server query, and ingest loop.

Learned: the server returns existing rows in the requested window. It does not prove the first row is the requested start. A hole becomes a sequence-gap error and stops that origin's batch. An empty window is not an error.

Unknown: whether a failed range is retried forever or the next tick advances.

Next: trace the 1000-event clamp and resume behavior.

## 2026-11-22 — finding 0126: gap retry

Compared the fetch start with origin advancement.

Learned: a gap does not advance the contiguous head, so the next tick repeats it. A successful page of at most 1000 events resumes after the new head. There is no quarantine.

Unknown: whether a forked origin is skipped on later fetches.

Next: trace `local_heads` and fork flags during sync.

## 2026-11-22 — finding 0127: forked origins stay eligible

Examined fork marking, `local_heads`, and `federation_allows`.

Learned: a fork flag does not remove the advertised head. Non-ephemeral sync does not consult it. Ephemeral mode rejects a forked peer unless a same-cluster claim bypasses the check first.

Unknown: whether the conflicting event is served to later pullers.

Next: trace `record_fork` against the events range query.

## 2026-11-22 — finding 0128: fork evidence is not pulled

Compared `peer_forks` with the events range query and the CLI reader.

Learned: the conflicting signed JSON stays in `peer_forks`. Range fetch serves only the first event. A second conflict at the same sequence is ignored. The CLI can print the stored JSON locally.

Unknown: whether a projection rebuild preserves `peer_forks`.

Next: trace rebuild table handling.

## 2026-11-22 — finding 0129: rebuild and forks

Examined the projection wipe list and replay loop.

Learned: `peer_forks` is excluded from the wipe and is not replayed into `events`. Fork evidence survives rebuild but does not become a projected assertion.

Unknown: whether a revoked actor key rejects a remote event at ingest.

Next: trace actor-key revocation against ingest.

## 2026-11-22 — finding 0130: revocation versus ingest

Compared assertion projection with `find_active_key`.

Learned: remote ingest does not consult actor-key revocation. Local bearer authentication does. A revocation event sets a timestamp; it does not reject later peer-signed assertions.

Unknown: whether projection uses event time or arrival order when a revocation and an assertion race.

Next: trace projection ordering against `created_at`.

## 2026-11-22 — finding 0131: projection ordering

All six source branches fetched successfully; heads were unchanged from
specs/revisions.md. Examined core event signing, chain validation, commit,
ingest, projector timestamp writes, and rebuild replay.

Learned: projection applies events in SQLite insertion order, not `created_at`
order. Rebuild replays `ORDER BY rowid`, preserving the original order. Chain
validation checks sequence and previous head only. Compared the relevant files
between 87f9e8c and fb54e43: only `BEGIN IMMEDIATE` transaction changes; the
ordering behavior is unchanged and finding 0130 still holds.

Unknown: what an ingested event leaves behind when `project_add_evidence` cannot
find its target assertion.

Next: trace `oag_events::projector::project_add_evidence`.

## 2026-11-22 — finding 0132: missing evidence target

Re-read the checked-out source through `git show origin/main:<path>`; no
working tree or test run was used. Examined `project_add_evidence`, ingest and
commit transaction order, `EventsError::NotFound`, and both sync ingest
callers.

Learned: a valid AddEvidence event whose assertion is absent fails projection.
The raw event row and origin head are not committed. Push counts it skipped;
pull records an error string, breaks that origin's page, and retries the same
unconsumed sequence on a later tick. Compared with 87f9e8c: service.rs added
rate-limit backoff only; the ingest error arm is unchanged.

Unknown: whether a late status event can overwrite an assertion status already
set by an event with a later `created_at`.

Next: trace `oag_storage::repo::assertions::set_status`.

## 2026-11-22 — finding 0133: overwritable assertion status

Examined the core status enum, `assertions::set_status`, the three status
projectors, and local API entry checks.

Learned: `assertions.status` is a derived cache overwritten by the last
projected dispute, retraction, or supersede event. `set_status` has no current
status or time predicate. History tables retain the individual events, but the
column keeps only the last write in insertion order. Compared with 87f9e8c:
the core enum, storage update, projector, and status API methods are unchanged;
assert.rs gained only pinned-CID and verification-count code.

Unknown: whether history/UI surfaces show both status events and their order or
only the final cached status.

Next: trace `oag_graph::history::GraphService::get_history` and
`oag-api/src/human.rs::HistoryEntryView`.

## 2026-11-22 — finding 0134: history ordering

Examined `get_history`, the `history_for` join, REST/MCP exposure, and the two
human pages. All six source branches were fetched at the start of this session;
heads remain as listed in specs/revisions.md.

Learned: history entries carry payload and signed `created_at`, but SQL orders
by origin peer bytes then sequence. REST and MCP expose the full entries; the
human node page drops payload. The human assertion page picks the first
supersede event in that origin/sequence order for its link. Dispute and
retraction detail lists have no ORDER BY. Compared with 87f9e8c: history code
is unchanged; other changes in the same files are search paging, pins, and
aliases.

Unknown: which observation wins when `max_by_key(observed_at)` ties.

Next: trace `oag_storage::repo::assertions::list_observations` and
`oag-api/src/human.rs::observation_view`.

## 2026-11-22 — finding 0135: observation time in display versus score

Examined the verify API timestamp path, observation storage, human views, and
corroboration inputs.

Learned: `max_by_key(observed_at)` chooses the node page's single displayed
observation, with no target-defined tie-break over an unordered SQL query. The
human views drop observer identity and event ID. Corroboration averages result
weights from all observations on active assertions and never reads their
`observed_at`; freshness reads assertion timestamps instead. Compared with
87f9e8c: observation storage is unchanged; human changes are search paging and
corroboration changes are evidence grouping, not these lines.

Unknown: which clock drives freshness and what a future timestamp can alter.

Next: trace `oag_graph::service::chrono_now` and
`oag_graph::corroboration::freshness_from_age`.

## 2026-11-22 — finding 0136: gateway time is not graph time

Examined `GraphService::now`, freshness, gateway request clock, NTP resolver,
quorum, UDP front-end, and upstream wire exchange.

Learned: graph clocks and freshness use local `SystemTime`. Gateway NTP answers
are verified for outside clients but are not consumed by `oag-graph`; exact
grep for `ntp` in the graph crate found no matches. A failed NTP resolution
sends no UDP reply rather than falling back to the local clock. Compared with
87f9e8c: NTP code and cited graph clock lines are unchanged; gateway changes
are HTTP-only IPv4 pinning moved to the crawler.

Unknown: what a cached NTP answer returns during its TTL and after expiry.

Next: trace `oag_api::gateway::compute_cache_ttl` and `adjust_for_elapsed`.

## 2026-11-22 — finding 0137: gateway cache reconstruction

Examined the gateway cache map, TTL selection, resolver precedence, and
front-end startup guard.

Learned: only quorum results populate the cache. An NTP cache hit adds local
elapsed time to the stored estimate instead of querying again. Zero TTLs are
not stored; expired entries are not evicted. Direct and relay results are not
cached. Compared with 87f9e8c: these cache lines are unchanged; the gateway
diff is HTTP-only IPv4 pinning moved to the crawler.

Unknown: which SSRF checks and address choice the gateway's HTTP upstream path
reuses from the crawler.

Next: trace `oag_crawler::fetch::resolve_and_validate`,
`build_pinned_client`, and `prefer_ipv4`.

## 2026-11-22 — finding 0138: DNS validation and single-address pinning

Examined crawler resolve/validate/pin helpers, the SSRF predicate, and the
gateway HTTP upstream path. Compared 87f9e8c with fb54e43 for this mechanism.

Learned: every resolved address is validated, then `prefer_ipv4` reduces the
set and `build_pinned_client` pins only the first address, with no fallback.
Gateway reuses the crawler guard without the crawler content-type allowlist.
Changed since 87f9e8c: pinning moved from last-address-wins to first-address;
`prefer_ipv4` was added and called by both paths. Tests were inspected only.

Unknown: which transitional IPv6 ranges the explicit predicate does not name.

Next: trace `oag_crawler::ssrf::is_blocked_v6`.

## 2026-11-22 — finding 0139: IPv6 blocklist coverage

Examined `is_blocked_ip`/`is_blocked_v6`, its caller, and its printed tests.
Compared `ssrf.rs` with 87f9e8c: unchanged.

Learned: IPv6 blocking is a named predicate set: mapped, loopback, unspecified,
multicast, ULA, link-local. Documentation, 6to4, Teredo, discard-only, and
IPv4-compatible forms have no explicit branch. Reachability of those forms is
Unknown; no request was made. Finding 0046's caveat still holds.

Unknown: what `safe_fetch` accepts and stores after the network guard.

Next: trace `oag_crawler::fetch::safe_fetch` content-type normalization, body
cap, and BLAKE3 hash destination.

## 2026-11-22 — finding 0140: crawler body acceptance and hash

Examined `safe_fetch` after the network guard, the crawler's evidence handoff,
and corroboration's content grouping.

Learned: six normalized content types are accepted. Declared and streamed size
caps are enforced before a page is returned. BLAKE3 is computed over the exact
accepted bytes and stored as evidence content_hash, which corroboration groups
by `content:<hash>`. Gateway HTTP upstreams skip the content-type allowlist.
Compared with 87f9e8c: these acceptance and hash lines are unchanged; nearby
changes are address pinning and best-effort pin recording.

Unknown: which JSON-LD fields become assertions and what evidence they carry.

Next: trace `oag_crawler::extract::json_ld::extract_from_html` and
`extract_from_json`.

## 2026-11-22 — finding 0141: narrow JSON-LD extraction

Examined JSON-LD parsing, extractor data types, and crawler assertion of
extracted facts. Compared 87f9e8c: extractor unchanged; crawler change is pin
CIDs only.

Learned: only software, organization URL, name, and sameAs shapes are
recognized. Malformed JSON and unknown types are silently ignored. Facts become
StructuredExtraction assertions with page evidence at confidence 0.7; failed
facts and unresolved aliases are skipped, not fatal. Tests were read only.

Unknown: which HTML tags and attributes html_meta extracts.

Next: trace `oag_crawler::extract::html_meta::extract`.

## 2026-11-22 — finding 0142: HTML meta aliases

Examined `html_meta::extract` and its orchestration. Compared 87f9e8c:
extractor unchanged.

Learned: only the first `<title>` and first `og:title` are read, trimmed, and
locally deduplicated as `Name` aliases for the page URL. No facts, no meta
description, no cross-extractor deduplication. Failed alias declarations only
reduce the summary count. Tests were read only.

Unknown: what Markdown extraction turns into candidate facts and aliases.

Next: trace `oag_crawler::extract::markdown::extract`.

## 2026-11-22 — finding 0143: Markdown first-H1 alias

Examined `markdown::extract`, its dispatch, and its tests. Compared 87f9e8c:
unchanged.

Learned: only the first line with a left-trimmed `"# "` prefix becomes a `Name`
alias; empty first H1 does not stop the scan. No facts or links are extracted.
`text/plain` passes the fetch allowlist but gets no deterministic extraction.
Tests were read only.

Unknown: how `llms.txt` facts choose their site-level subject.

Next: trace `oag_crawler::extract::llms_txt::extract`.

## 2026-11-22 — finding 0144: llms.txt site-level links

Examined the `llms.txt` parser, site-origin helper, side fetch, and evidence
handoff. Compared 87f9e8c: parser unchanged; crawler adds pin CID only.

Learned: link bullets become `links_to` facts from `scheme://host[:port]`, with
URLs resolved against the actual llms.txt URL. The first title becomes a site
Name alias. Evidence is `documentation` with the side-fetch hash and pin;
confidence is 0.5. Tests were read only.

Unknown: how ARD responses choose their subjects.

Next: trace `oag_crawler::extract::ard::parse`.

## 2026-11-22 — finding 0145: per-resource ARD extraction

Examined the ARD parser, side fetch, and assertion loop. Compared 87f9e8c:
parser unchanged; crawler adds pin CID only.

Learned: each `resources[]` entry is its own subject using the raw `url` or
site-origin fallback. `mcp_server`/`mcp-server` selects that node type, all
others become `agent`. Name aliases, operator, and capabilities are per
resource; all facts share the ARD response evidence at confidence 0.7. Tests
were read only.

Unknown: how the A2A agent-card parser chooses subjects and predicates.

Next: trace `oag_crawler::extract::a2a::parse`.

## 2026-11-22 — finding 0146: A2A card subject is the page

Examined the A2A parser and card side fetch. Compared 87f9e8c: parser
unchanged; crawler adds pin CID only.

Learned: a valid card always gives the original crawled page `instance_of
concept:a2a-agent`. Name/provider/skills become aliases and facts; provider URL
beats organization name, skill name beats id. Evidence URI is the card URL,
subject is the page URL. Tests were read only.

Unknown: when the LLM fallback calls an external model and how it fails.

Next: trace `oag_crawler::llm_extract::LlmExtractor::extract` and its
OpenAI-compatible implementation.

## 2026-11-22 — finding 0147: optional bounded LLM extraction

Examined provider selection, the extractor trait, disabled default,
OpenAI-compatible request/parse path, and crawler orchestration.

Learned: LLM extraction defaults off; enabled mode posts once per HTML page
with 10s connect and 120s total timeouts, over an 8000-character text cap.
Malformed model JSON yields no candidates; confidence is clamped; individual
assertion failures only count as skipped. Compared with 87f9e8c: timeouts are
the change; prompt and parsing are unchanged. Tests were read only.

Unknown: which candidate strings graph assert validation accepts or rejects.

Next: trace `oag_graph::assert::GraphService::assert` and `AssertInput::validate`.

## 2026-11-22 — finding 0149: collisions tokenizers

Fetched collisions master b19fc44d; compared with explained dfc8ca95. Library
is unchanged; only scripts changed. Examined Tokenizer variants and their unit
generation.

Learned: Words, Characters, stride WordsBudget, shuffled deterministic
WordsBudget, and window sampling are pure deterministic generators. Budget
variants cap units before SimHash; trade-offs are documented experiment intent,
not reproduced here. Default remains unigram words with bigrams off.

Unknown: how a second hash domain interacts with the prefix index.

Next: trace `oag_collisions::simhash_with_domain` and the multi-hash index path.

## 2026-11-22 — finding 0150: collisions multi-probe

Examined `collide_multi_probe`, its text wrapper, and the ordinary prefix
ladder. Library unchanged from dfc8ca95; only scripts changed upstream.

Learned: multi-probe adds flipped 8-bit prefix buckets, clamps probe bits and
flips, unions candidates, and sorts by Hamming without reapplying the 8-bit
threshold. It is read-only; recall comes with false positives. Cited experiment
figures were not reproduced.

Unknown: whether caller-chosen hash domains are used by any index.

Next: trace `oag_collisions::simhash_with_domain` and its call sites.

## 2026-11-22 — finding 0151: domain helper is not an index feature

Examined `simhash_with_domain`, its call sites, the index's single-hash state,
and EXP-026's recorded result. Library and EXPERIMENTS.md unchanged from
dfc8ca95.

Learned: domain-separated hashing is a public primitive used by examples only.
`CollisionIndex` stores one hash via the empty-domain wrapper. Dual-hash recall
is a recorded experiment that concluded against doubling index memory, not an
implemented feature. The example was not run.

Unknown: what in oag-listend changed or remains undocumented at b87dcac9.

Next: compare listend b87dcac9 with aad2d9b2 and document one admission or
persistence mechanism.

## 2026-11-22 — finding 0152: listend dual bound and storage timeout

Compared listend aad2d9b2 with b87dcac9 and examined the current accept path.

Learned: accept now checks audio against the frame-derived servable bound and
audio-plus-declared-media-type footprint against the store bound. Media types
are trimmed and capped at 4096 bytes. Duplicate stats, writes, and unlinks use
a 60-second timeout. Finding 0030's old single-bound description is corrected
by this finding, not rewritten.

Unknown: what the new load deadline and read-only check mode report.

Next: trace `with_directory`, `check_directory`, and `load_dir_impl`.

## 2026-11-22 — finding 0153: bounded listend directory load

Examined with_directory, check_directory, load_dir_impl, sidecar readers, and
publish eviction. Compared aad2d9b2 with b87dcac9.

Learned: startup load creates and prunes; check creates and unlinks nothing.
Both use a 100,000-audio-entry cap and a 300-second deadline, reporting
truncated/timed_out. Entry names, bytes, audio sniff, sidecar type/size, and
BLAKE3 identity are rechecked. A stalled syscall can still exceed the deadline.

Unknown: how the shared startup mirror pass avoids holding the store lock.

Next: trace `mirror_existing_shared` and `offer_shared`.

## 2026-11-22 — finding 0154: shared listend startup mirror

Examined main startup ordering, mirror_existing_shared, offer_shared, CID sidecar
persistence, and the change from aad2d9b2.

Learned: mirroring starts after carriers serve, snapshots Arc handles briefly,
releases the lock during network calls, uses a 30s whole-pass deadline, and
persists .cid only on success. Failures stay in a 64-entry in-memory log.
Finding 0108's ordering and finding 0109's success behavior are corrected, not
rewritten. No daemon or IPFS node was run.

Unknown: what changed in the imagination repository at 73fadb3c.

Next: compare imagination 73fadb3c with 7b7dcb8e and document one mechanism.

## 2026-11-22 — finding 0155: imagination URL resolver

Compared imagination 7b7dcb8e with 73fadb3c: library unchanged, scripts only.
Examined target inference, composite resolution, UrlResolver, example wiring,
and transport frame bound.

Learned: a plain reqwest GET answers http(s) targets with status and full text.
No explicit SSRF guard, timeout, redirect policy, content-type check, or fetch
body cap appears in the resolver. Imagination does not depend on the crawler
guard. No request was made.

Unknown: how the Reticulum carrier differs from the TCP socket carrier.

Next: inspect `oag-imagination-reticulum` at 73fadb3c for admission or routing
differences.

## 2026-11-22 — finding 0156: imagination Reticulum carrier

Examined the separate imagination-reticulum crate at 73fadb3c. Imagination
library unchanged from 7b7dcb8e.

Learned: seed-derived identity, 1400-byte chunks over a 4-byte length-prefixed
JSON frame, 8 MiB cap, 30s announce/15s link/15s reply waits. Send errors become
None then io TimedOut. Server announces every 5s, answers only Request messages,
and discards engine.handle's result. No shared framing code with core; wire
compatibility is documented intent. No target test was run.

Unknown: which data-roads requirement is still only a proposal.

Next: inspect data-roads b5cd2f4e and record the largest unresolved requirement.

## 2026-11-22 — finding 0157: Data Roads unanswered redundancy model

Read the full data-roads RFC at b5cd2f4e; head unchanged from explained commit.

Learned: the proposed lifecycle is generation, OAG ownership assertion,
encrypted mesh distribution, access request, time-bounded agreement, renewal or
lapse, and separate custodian compensation. Effective redundancy, event types,
payment, renewal mechanics, and security remain explicitly unspecified. The RFC
denies that mesh already supplies pull anti-entropy or durable cross-cluster
storage. Paper is four lines and unstarted.

Unknown: which new oag-mesh runtime module needs audit at 45f9fa8a.

Next: compare mesh 45f9fa8a with 9f5d89e9 and document one new runtime module.

## 2026-11-22 — finding 0158: mesh snapshot persistence

Compared mesh 9f5d89e9 with 45f9fa8a and examined the new persistence module
and MeshState save/load.

Learned: seven JSON snapshots are written with unique temp names and renames,
then a BLAKE3 commit marker is written last. Load refuses a mismatched set but
accepts a legacy directory with no marker. Identity, peers, limiters, instance
ID, and link quality are reconstructed fresh. No crash or save was executed.

Unknown: which limiter governs which new mesh route.

Next: trace `oag_mesh::rate_limit::RateLimiter` and `TokenBucket`.

## 2026-11-22 — finding 0159: mesh route limiters

Examined the new rate_limit module, constants, router, and four call sites.

Learned: route-search (8 tokens, 2/s) and onion (16 tokens, 0.5/s) are node-wide
buckets for unauthenticated amplification endpoints. Membership attestations
(30/60s) and responder acks (60/60s) are per verified peer ID in fixed windows.
Limits are in-memory, bounded to 10,000 live fixed-window keys, and reset on
restart. No request or test was run.

Unknown: how responder subscriptions and inbox store and deliver events.

Next: trace `ResponderInbox` and `ResponderSubscriptionRegistry`.

## 2026-11-22 — finding 0160: blinded responder dispatch

Examined the new dispatch module and subscription/inbox routes. Compared with
9f5d89e9: new module and routes.

Learned: a self-chosen subscription id is a bearer capability. Matching accepted
anonymous events are cloned into inboxes before the 204; polling drains them.
Registration needs no identity; unregister does not clear inbox; filter
replacement does not clear prior events. MeshState can save/load both maps, so
the module's "not durable" comment is stale for callers that save. No request
was made.

Unknown: how onion layers are built and peeled.

Next: trace `OnionPayload` and `receive_onion_layer`.

## 2026-11-22 — finding 0161: mesh onion relay behavior

Examined onion construction, key derivation, key fetch, relay handler, and
forwarding helpers. Module is new since 9f5d89e9.

Learned: relays derive X25519 keys from Ed25519 identity, peel one
ChaCha20-Poly1305 layer, and POST to the `next_hop` recovered from plaintext.
Peer ID in the fetched key response is unused; no path-length cap appears.
Failures are 400/429/502; no onion state is stored. No request was made.

Unknown: whether link-quality scores affect any route choice.

Next: trace `oag_mesh::link_quality::LinkQualityLedger`.

## 2026-11-22 — finding 0162: link quality orders but never drops

Examined the new link_quality module and its route-search and sync call sites.

Learned: a 0.1 EMA per peer address records delivery, not honesty. Unknown peers
score 0.5; stable descending sort preserves config order on ties. Route search
orders before spending its fan-out budget; periodic pulls order peers and may
defer later ones to the next tick. No peer is excluded, and the ledger is not in
the seven-store snapshot. No sync was run.

Unknown: what membership attestations add and how they expire.

Next: trace `oag_mesh::membership::MembershipRegistry`.

## 2026-11-22 — finding 0163: membership attestations without expiry

Examined the new membership module, fully-cross-checked route, and broadcast
helper. Compared with 9f5d89e9: new module and routes.

Learned: distinct attesters per (cluster, subject) are stored in a HashSet. New
attesters need 16+4*n proof-of-work bits; repeats are free and do not bump
sequence. Verification checks signature/key/skew/self only, not attester
standing. Snapshots union sets without re-verifying; no expiry or revocation
path appears. No request was made.

Unknown: how responder acknowledgments are admitted and exposed.

Next: trace `oag_mesh::responder::ResponderAcknowledgmentLog`.

## 2026-11-22 — finding 0164: responder acks as latest signed state

Examined the new responder module and its transport routes. Compared with
9f5d89e9: new module and routes.

Learned: acks are signed per nonce with active true/false; no PoW and no nonce
existence check. One record per (nonce, responder); strictly older arrivals are
ignored, equal timestamps replace and bump sequence. Active responders are an
unordered advisory list. Snapshot persists if caller saves. No request was made.

Unknown: what route-search fan-out budget actually bounds.

Next: trace `oag_mesh::transport::search_for_route`.

## 2026-11-22 — finding 0165: mesh route-search fan-out budget

Examined recursive search, entry points, defaults, inbound gate, and result
selection. New since 9f5d89e9.

Learned: each node checks local tree first, orders peers by link quality, spends
one budget unit per outbound request, and divides the remainder among children.
`already_asked` is per branch. Result is shortest found, not globally shortest;
a direct path aborts other tasks. Inbound token bucket is separate and
node-wide. No search was run.

Unknown: how sync decides a store is stale and merges snapshots.

Next: trace `pull_and_merge` and `heads_changed`.

## 2026-11-22 — finding 0166: per-store mesh pull heads

Examined pull_and_merge, heads_changed, merge_heads, pull_changed_stores, and
periodic ordering. New since 9f5d89e9.

Learned: five version stamps decide which snapshots are fetched. Instance ID
change or no prior heads forces all five; instance ID is always copied from
remote. Successful stores advance their heads independently; failed stores keep
old heads and retry. Unreachable peers skip the full-pull fallback; HTTP
rejection of heads uses it. No sync was run.

Unknown: how the periodic sync scheduling and jitter actually work.

Next: trace `spawn_periodic_sync_with_jitter`.

## 2026-11-22 — finding 0167: explicit jittered mesh sync loop

Examined periodic sync helpers, jitter generation, budget variant, and
cancellation notes. New since 9f5d89e9.

Learned: no loop starts from MeshState construction. Callers spawn a task that
syncs immediately then sleeps interval+jitter after each tick; jitter is a
hashed clock phase, not crypto. Budget variant caps the tick and skips jitter.
State is not durable; abort cancels at an await point. No task was run.

Unknown: what a caller must provide to run a mesh node.

Next: inspect `oag_mesh::node::NodeAdapter`.

## 2026-11-22 — finding 0168: implemented base-to-mesh adapter

Examined the new node adapter, locked core storage reads, and the connection
register. Mesh 45f9fa8a locks core 59ccf3de in Cargo.lock.

Learned: MeshNodeAdapter loads the base identity, first address per peer, and
mesh snapshots under <data-dir>/mesh/, then saves only mesh state. It is the
first implemented base-to-mesh connection. Load can still generate an absent
identity file and create/migrate the base SQLite database. C-005 added to the
connection register. No service was run.

Unknown: re-fetch on the next invocation and choose the largest remaining gap.

Next: re-fetch all branches, then trace `oag_graph::service::GraphService::record_verification` and its counters.

## 2026-11-22 — finding 0169: verification counter boundary

All six source branches fetched successfully; heads remain as listed in
specs/revisions.md. Examined the new verification counters, service method,
metrics snapshot, API rendering, and REST/MCP parsing order.

Learned: jobs/failures count calls that reach GraphService::verify_assertion,
including missing graph:verify and failed commits. Bad IDs/results/timestamps
and bad API keys are rejected before the service and are not counted, though
the metric help text names them. Counters are process-lifetime only.

Unknown: what the latency histograms sample and clamp.

Next: trace `oag_graph::latency::LatencyHistogram` and
`oag_api::latency::api_latency_middleware`.

## 2026-11-22 — finding 0170: latency histogram boundaries

Examined the shared histogram implementation, API middleware, search observation
points, metrics snapshot, and renderer. These are new since 87f9e8c1.

Learned: fixed cumulative buckets and microsecond integer sums are shared. API
latency records every middleware response including errors; search latency
records only successful searches after pool acquisition, so failed searches and
pool waits are missing. Both reset on restart. No endpoint or search was run.

Unknown: what events_pending_chain counts and whether forks alter it.

Next: trace `oag_storage::repo::stats::events_pending_chain`.

## 2026-11-22 — finding 0171: dangling predecessor gauge

Examined the new events_pending_chain query, snapshot/rendering, event schema,
ingest handling, and direct-insertion test. New since 87f9e8c1.

Learned: the gauge counts events with a non-null predecessor ID absent from the
local events table. Genesis and present predecessors do not count. Rejected gaps
and fork evidence do not create such rows; tests insert them directly. No scrape
or ingest was run.

Unknown: what pin discovery records and what "holds" means.

Next: trace `oag_graph::pins::GraphService` pin helpers.

## 2026-11-22 — finding 0172: pin discovery record

Examined pin service helpers, storage queries, migration backfill, REST route,
and tests. New since 87f9e8c1.

Learned: pinned_cids is one durable row per CID with timestamp and descriptive
source. Re-pins refresh time and keep first source. holds is a row lookup, not a
live IPFS check; list is newest-first and clamped to 1000. Migration backfills
evidence metadata with INSERT OR IGNORE. No route or migration was run.

Unknown: what evidence redaction removes and what rebuild reapplies.

Next: trace `oag_graph::redaction::GraphService::redact_evidence`.

## 2026-11-22 — finding 0173: keyset search cursor

Examined search_page, search_after, SearchCursor, keyset SQL, REST DTO, and
handler. New since 87f9e8c1.

Learned: cursor wins over offset; the token is a node ID whose current FTS5
rank is recomputed. Malformed or stale cursors restart the walk. Page fetches
limit+1 rows to decide next_cursor; no server state is stored. No search was
run.

Unknown: how REST/MCP semantic search diverges from cursor pagination.

Next: trace `graph_search` in oag-mcp and the REST search handler.

## 2026-11-22 — finding 0174: unpaged semantic search

Examined REST/MCP semantic branches, semantic_search, provider errors, and
embedding rebuild. Compared with 87f9e8c1.

Learned: semantic=true bypasses search_page; response has no next_cursor and
offset/cursor are ignored. Ranking is cosine over all stored embeddings with a
1000 cap; disabled provider maps to 400, other provider errors to 502. Search
suppression is still not applied. No provider or request was run.

Unknown: exact cosine formula and invalid-vector handling.

Next: trace `oag_embeddings::rank` and `oag_embeddings::similarity`.

## 2026-11-22 — finding 0175: cosine rank primitive

Examined embedding similarity, rank, storage codec, caller, and tests. Files
unchanged from 87f9e8c1.

Learned: cosine is dot/product of L2 norms with zero guards for empty,
mismatched, and zero vectors; no NaN/Infinity filter. Rank uses stable
descending total_cmp and truncates. Tie order follows unordered list_all rows;
suppression is not applied here. Tests were read only.

Unknown: how authority batch ranking stores its output and survives rebuild.

Next: re-fetch, then trace `oag_graph::authority::recompute_authority`.

## 2026-11-22 — finding 0176: deterministic subgraph arrays

Examined get_subgraph at fb54e43 and compared with 87f9e8c1.

Learned: returned nodes now sort by (distance, canonical_identifier) and edges
by id. Assertions are collected from visited_edges.keys() before the sort, so
their order remains unspecified despite the source comment. Soft node cap and
both-direction traversal from finding 0063 still hold. No request was run.

Unknown: whether resolve candidates gained deterministic ordering.

Next: trace `oag_graph::resolve` at fb54e43.

## 2026-11-22 — finding 0177: partial embedding recompute

Examined recompute_embeddings and embedding storage. Files unchanged from
87f9e8c1.

Learned: recompute clears node_embeddings before the provider loop. Each upsert
is independent; a provider error leaves only a successful prefix, and semantic
search reads whatever rows exist. Empty text is skipped; provider names and
models are stored per row. No provider was run.

Also checked `oag_graph::resolve` at fb54e43: only the nodes::search signature
changed to add offset 0; finding 0065 still holds.

Unknown: what ordering and duplicates appear in a node's assertion list.

Next: trace `list_assertions_for_node` and `edges::list_touching`.

## 2026-11-22 — finding 0178: unordered node assertion list

Examined list_assertions_for_node, list_touching, list_by_edge, and the scoped
diff from 87f9e8c1.

Learned: assertions from all touching edges are appended with no ordering at
either SQL level and no status filter. Unknown node yields empty list; SQL
errors abort. Behavior unchanged at the newer commit; only a search signature
call site changed. No request was run.

Unknown: which transfer mechanism remains undocumented at fb54e43.

Next: re-fetch, then inspect `oag_api::transfer` at the newer core commit.

## 2026-11-22 — transfer recheck

Compared `oag_api::transfer` from 87f9e8c1 with fb54e431. The only change is a
new test asserting that `relay_fetch` skips a peer already in the relay path;
the tested behavior itself is unchanged and finding 0020 still holds. No relay
request was run.

Next: re-fetch, then re-audit `oag_listend::wav::AudioFormat::sniff` at
b87dcac9 against finding 0030.

## 2026-11-22 — finding 0179: listend sniff re-audit

All six source branches fetched successfully; heads unchanged. Compared the
sniff block from aad2d9b2 with b87dcac9: unchanged.

Learned: finding 0030 still holds. The sniff is a closed signature set: WAV,
AIFF, FLAC, Ogg BOS codec prefixes, ID3 or checked raw MPEG frames, and ftyp
audio brands. It decodes nothing. The omitted raw-frame and M4A branches are
now documented. Tests were read only.

Unknown: how generated startup audio is bounded and hashed.

Next: trace `oag_listend::wav::generate_n`, `sounds`, and `twinkle`.

## 2026-11-22 — finding 0180: deterministic generated audio

Examined WAV generation, sample cap, fixed ping, seed set, and startup
publication. wav.rs unchanged from aad2d9b2.

Learned: generated audio is 8 kHz mono 16-bit WAV, each item capped at 40,000
samples. sounds() cycles kinds with derived seeds; twinkle() is fixed and shares
one hash across daemons. publish_generated seeds only an empty store and sends
every item through the normal accept rule. No daemon was run.

Unknown: what the ping handlers return and disclose.

Next: trace `oag_listend::http::ping`, UDP ping, and server ping handling.

## 2026-11-22 — finding 0181: generated ping responses

Examined HTTP, native, and UDP ping paths, Hello fields, and scoped diff from
aad2d9b2. Ping blocks unchanged.

Learned: every carrier generates twinkle() on demand and hashes it; no store
lookup, CID, seed, or peer identity is used. HTTP adds fixed ETag, immutable
cache, hash.wav filename, audio/wav, and range support. Hello, not ping,
discloses item count. No carrier was run.

Unknown: re-fetch next invocation and choose the largest remaining gap.

Next: re-fetch, then trace `oag_listend::server::serve_session` connection and timeout handling.

## 2026-11-22 — finding 0182: bounded panic-safe listend sessions

Examined native server limits, accept loop, ActiveGuard, per-session timeout,
decode handling, and shutdown signal.

Learned: at most 64 sessions wait on a semaphore, each with 10s read/write and
1800s total timeout. ActiveGuard releases the counter on panic unwind, replacing
a manual decrement that could leak it. BadHash gets a Rejected response; other
malformed frames close the stream. No listener or test was run.

Unknown: re-fetch next invocation and choose the largest remaining gap.

Next: re-fetch, then trace `oag_listend::protocol::read_frame` and `decode_request` length rules.

## 2026-11-22 — finding 0183: length-first frame decoding

Examined native frame reading, buffered frame validation, checked Reader,
request opcodes, and hash normalization. Unchanged from aad2d9b2.

Learned: declared length is rejected before body allocation; reads are bounded.
decode_request consumes opcode-specific fields, treats empty declared type as
None, and normalizes 64-hex fetch hashes to lowercase. BadHash is the one decode
error answered while keeping the session open. No socket was used.

Unknown: re-fetch next invocation and choose the largest remaining gap.

Next: re-fetch, then trace `oag_listend::udp::UdpCarrier::run` frame-size and peer handling.

## 2026-11-22 — finding 0184: concurrent bounded UDP handling

All six source branches fetched successfully; heads unchanged. Examined UDP
run loop, size constants, request handling, oversized-reply rejection, and the
change from aad2d9b2.

Learned: each datagram is copied and handled in a task under a 64-permit
semaphore with ActiveGuard accounting. Replies over 65,507 bytes become
Rejected instead of truncation; IO timeout is 10s; list page caps at 900. Prior
inline handling could block other peers. No socket was run.

Unknown: how HTTP carrier concurrency and shutdown work.

Next: trace `oag_listend::http::HttpCarrier::run`.

## 2026-11-22 — finding 0185: bounded one-request HTTP carrier

Examined HTTP bind/run, per-connection timeout, generic stream handlers,
ActiveGuard use, CORS preflight, unread-body drain, and scoped diff.

Learned: HTTP is one request per connection, 64 concurrent permits, 1800s total
and 10s IO timeouts, 16KiB head and frame-derived body caps. ActiveGuard makes
active-session accounting panic-safe. OPTIONS returns wildcard CORS; unread
bodies are drained to avoid TCP reset. No listener was run.

Unknown: how read_request distinguishes 413 from malformed heads.

Next: trace `oag_listend::http::read_request`.

## 2026-11-22 — finding 0186: HTTP framing rules

Examined read_request head/body parsing, boundary cap, Content-Length and
Transfer-Encoding rules, Expect handling, and ERROR mapping.

Learned: head cap is checked exactly at the blank-line boundary; oversized
bodies become 413, while malformed heads, multiple Content-Length headers, and
any Transfer-Encoding become 400 with reasons. 100-continue is sent only after
framing passes. Short bodies are drained after the response. No HTTP client was
run.

Unknown: how the IPFS CID fetch route admits and verifies remote bytes.

Next: re-fetch, then trace `oag_listend::ipfs` and `GET /ipfs/{cid}`.

## 2026-11-22 — finding 0187: bounded IPFS audio GET

Examined GET /ipfs/{cid}, IpfsPublisher::cat, CID validation, reply bounds,
chunk decoding change, and response headers.

Learned: held CID mappings are served before network fetch. Unknown CIDs go via
plain HTTP cat with 10s reads, capped replies, and checked chunk arithmetic.
Bytes are sniffed as audio but not checked against the IPFS multihash; ETag is
the CID and X-Content-Hash is BLAKE3 of returned bytes. No IPFS node was run.

Unknown: how CID text and operator API addresses are parsed into requests.

Next: trace `oag_listend::ipfs::validate_cid` and `split_api`.

## 2026-11-22 — finding 0188: IPFS input syntax gates

Examined validate_cid, split_api, parse_add_response, call sites, and diff.
Rules unchanged from aad2d9b2.

Learned: CIDs accept only 128 bytes of ASCII alphanumeric/-/_ before request
lines or headers. HTTPS API addresses are refused, optional http:// stripped,
host taken before the first slash, and path forced to /api/v0/add. Add replies
are scanned for Hash then CID-checked; no multihash verification. No node was
run.

Unknown: what Unix-socket admission and path handling add.

Next: re-fetch, then trace `oag_listend::unix::UnixCarrier`.

## 2026-11-22 — finding 0189: Unix carrier shares TCP sessions

All six source branches fetched successfully; heads unchanged. Examined Unix
bind policy, accept loop, shared serve_session call, and scoped diff.

Learned: only path binding and stale-socket handling are Unix-specific. A
non-socket path is never deleted, a live socket is not stolen, and a stale
socket is removed. Sessions use the same 64 permits, 10s IO, 1800s total
timeout, frame cap, protocol, and audio rule as TCP. No socket was run.

Unknown: how main starts carriers and drains active sessions on shutdown.

Next: trace `oag_listend::main` startup and shutdown ordering.

## 2026-11-22 — finding 0190: listend process lifecycle

All six source branches fetched successfully; heads unchanged. Examined main
argument handling, early signals, store opening, carrier binds, startup seed,
post-bind mirror, and two-phase shutdown.

Learned: signals are registered before observable startup. --check exits before
binds/mirror. Carriers all bind before spawns; mirror starts after serving. Stop
signals all handles, waits 5s per run task, then polls active counters for 2s.
No daemon or signal was run.

Unknown: re-fetch next invocation and choose the largest remaining gap.

Next: re-fetch, then trace `oag_listend::reticulum::ReticulumCarrier::bind` and `run`.

## 2026-11-22 — finding 0191: per-link Reticulum workers

All six source branches fetched successfully; heads unchanged. Examined the
feature-gated Reticulum bind path, reassembly buffers, event loop, workers,
reply chunking, and scoped diff.

Learned: a stable seed gives a stable destination address. Shared event loop
reassembles bounded frames and feeds one worker per link, capped at 64 links and
queued frames. Overfull links are dropped; packet sends are bounded to 10s.
Audio handling is the shared handle path. No Reticulum interface was run.

Unknown: re-fetch next invocation and choose the largest remaining gap.

## 2026-11-22 — finding 0192: imagination data pads

All six source branches fetched successfully; heads unchanged. Examined
datapad split, manifest, attach, gather, reconstruct, tests, and scoped diff.

Learned: files split into ordered shards with BLAKE3 whole-file manifest IDs;
small files get empty tail shards. Reconstruction checks exact count, contiguous
indices, and hash. No erasure coding, replication, consensus, or transport is in
this module. Tests were read only.

Unknown: whether the TCP socket carries PadRequest/PadResponse and wires gathering.

Next: trace `oag_imagination::socket::serve` PadRequest/PadResponse handling.

## 2026-11-22 — finding 0193: pad gathering ignores requested pad ID

All six source branches fetched successfully; heads unchanged. Examined TCP
serving limits, PadRequest branch, Engine::data_pad, gather fan-out, and pad
matching.

Learned: every PadRequest returns the node's own pad; the request's pad_id is
ignored. gather_file_with fans out to supplied node addresses, at most 32 in
flight, then maps returned pads by their real IDs to the manifest. No retries;
duplicates collapse in gather's map. No carrier was run.

Unknown: how the proxied HTTP and IPFS publisher seams fail.

Next: trace `oag_imagination::socket::ProxiedTransport` and `HttpIpfsPublisher`.

## 2026-11-22 — finding 0194: transport seams reinterpret addresses

All six source branches fetched successfully; heads unchanged. Examined TCP,
CONNECT proxy, IPFS publish/read, and HTTP transport seams.

Learned: address means host:port, CONNECT target, CID, or base URL depending on
the carrier; IPFS write ignores it. Success requires coarse status/JSON checks,
and failures collapse into io::Error or None. Proxy CONNECT read is a single
1024-byte buffer with no shown timeout. No network carrier was run.

Unknown: re-fetch next invocation and choose the largest remaining gap.

## 2026-11-22 — finding 0195: separated aberration experiment

All six source branches fetched successfully; heads unchanged. Examined the
collisions aberration module, example, tests, call sites, and scoped diff.

Learned: pure physics experiment computes v²/r drift, CMB speed, classical
aberration, and light-speed scenario. Tests assert measured ranges. It is
exported and example-runnable but has no production collision-index caller;
unchanged from dfc8ca95. No example or test was run.

Unknown: re-fetch next invocation and choose the largest remaining gap.

## 2026-11-22 — finding 0196: unfiltered node sources

All six source branches fetched successfully; heads unchanged. Examined the
node sources helper, REST/MCP surfaces, route registration, and storage queries.

Learned: find_sources returns all evidence on all assertions whose edges touch
the node, with no status filter, dedup, cap, or ordering. REST was added at the
newer commit with the same response shape as MCP. No endpoint was run.

Unknown: re-fetch next invocation and choose the largest remaining gap.

## 2026-11-22 — finding 0197: redaction API wrappers

All six source branches fetched successfully; heads unchanged. Examined REST
redaction handlers/routes, MCP tools, reason DTO, status mapping, and diff.

Learned: REST and MCP only authenticate, parse IDs, and delegate to the service.
The service enforces Admin; list views combine evidence, suppression, and actor
tombstones. Repeated evidence/actor redaction is a 409; node suppression is
idempotent. No endpoint was run.

Unknown: re-fetch next invocation and choose the largest remaining gap.

## 2026-11-22 — finding 0198: NTP wire codec

All six source branches fetched successfully; heads unchanged. Examined NTP
timestamp conversion, client/server packet builders, upstream query, error
types, and diff.

Learned: 48-byte NTPv4 subset uses mode 3/4, echoes transmit as origin, and
reports caller-supplied verified time in reference/receive/transmit. Upstream
queries use T1-T4 with 5s bounds and reject wrong sender/mode/length. No UDP
packet was sent.

Unknown: what API span logging records beyond duration.

Next: trace `oag_api::logging::ApiMakeSpan` and `on_response`.

## 2026-11-22 — finding 0199: REST span logging

All six source branches fetched successfully; heads unchanged. Examined span
creation, actor recording, response completion, router layers, and diff.

Learned: REST requests get pid-counter request IDs, peer/path/method span
fields, actor_id from auth, and a separate completion event with duration_ms and
ok/error status. Query strings and MCP spans remain deferred. No request or log
sink was run.

Unknown: re-fetch next invocation and choose the largest remaining gap.

## 2026-11-22 — finding 0200: open normalized predicates

All six source branches fetched successfully; heads unchanged. Examined the
predicate newtype, v0 vocabulary, projection normalization, and input checks.

Learned: predicates are open strings trimmed, lowercased, and whitespace-joined
with underscores at projection time. KNOWN_PREDICATES documents but does not
enforce; unknown and empty predicates are accepted subject to byte-length
validation. Nothing was asserted.

Unknown: how EdgeId derivation makes normalized edges reusable.

Next: trace `oag_core::edge::EdgeId`.

## 2026-11-22 — finding 0201: deterministic edge identity

All six source branches fetched successfully; heads unchanged. Examined Edge,
EdgeId::from_triple, domain-separated Hash32, and edge insert-if-missing.

Learned: edge ID hashes subject_hex:predicate:object_hex under OAG:EDGE:v1:,
using normalized predicates. Actor/status/confidence/time are excluded.
Direction matters; repeated triples reuse the first edge row and timestamp. No
edge was inserted.

Unknown: which canonical identifiers converge on one node and what repeat
inserts preserve.

Next: trace `oag_core::NodeId::from_canonical_identifier` and node insertion.

## 2026-11-22 — finding 0202: first node metadata wins

All six source branches fetched successfully; heads unchanged. Examined NodeId
derivation, canonicalization, projector resolution, and insert-if-missing.

Learned: NodeId hashes canonical identifier bytes under OAG:NODE:v1:. The
projector inserts only when absent; later assertions reuse the row without
updating node type/name/description/metadata/created_at. No string validation
occurs at ID derivation. No node was inserted.

Unknown: how aliases accumulate separately from the canonical node row.

Next: trace `oag_storage::repo::nodes` alias insertion and listing.

## 2026-11-22 — finding 0203: separate accumulating aliases

All six source branches fetched successfully; heads unchanged. Examined alias
declaration, projection, storage key, listing, and diff.

Learned: aliases are separate rows keyed by (node_id, alias); first row's alias
type survives repeats. Declaration requires graph:assert and an existing node;
projection rejects unknown types. source_assertion is currently None and listing
has no ORDER BY. No event was committed.

Unknown: how the human UI renders alias type/source.

Next: trace alias rendering in `oag-api/src/human.rs`.

## 2026-11-22 — finding 0204: alias rendering omits provenance

All six source branches fetched successfully; heads unchanged. Examined node
page alias mapping, Askama template, storage order, and diff.

Learned: the UI renders alias text and type only, beneath the frozen primary
node name. No source assertion or timestamp is shown, and alias order is
unspecified. Askama escapes the displayed text. No page was rendered.

Unknown: re-fetch next invocation and choose the largest remaining gap.

## 2026-11-22 — finding 0205: closed evidence vocabulary and weights

All six source branches fetched successfully; heads unchanged. Examined
EvidenceType parsing, projection rejection, evidence record, and corroboration
weight constants.

Learned: 13 exact snake_case evidence labels are accepted; unknown strings fail
projection. Each label has a fixed corroboration weight, with service_receipt at
0.85 and other at 0.15. Evidence hash syntax is still unchecked. No event or
score was run.

Unknown: how URI control groups combine source identity with these weights.

Next: trace `oag_graph::corroboration::control_group_for_uri`.

## 2026-11-22 — finding 0206: heuristic control groups

All six source branches fetched successfully; heads unchanged. Examined URI
control-group parsing, multi-tenant and suffix lists, actor fallback, and
union-find component scoring.

Learned: known multi-tenant hosts group by host/first path segment; other hosts
use an approximate registrable domain; bad URIs fall back to actor keys. Content
and source keys are now unioned into connected components, correcting the older
one-key grouping description. No score was run.

Unknown: how verification result weights combine into agreement.

Next: trace `oag_graph::corroboration::verify_result_weight`.

## 2026-11-22 — finding 0207: fixed verification weights

All six source branches fetched successfully; heads unchanged. Examined result
weights, observation collection, and agreement combination.

Learned: confirmed/changed/unknown/unreachable/not_confirmed/contradicted map to
1/0.3/0/0/-0.5/-1; unparseable is 0. Only active assertions' observations count.
Their mean is rescaled and averaged equally with active-vs-disputed ratio. No
time or actor weighting. No score was run.

Unknown: which result strings are parsed into typed observations at write time.

Next: trace `oag_core::assertion::VerifyResult` and REST/MCP verify handlers.

## 2026-11-22 — finding 0208: verify result boundary

All six source branches fetched successfully; heads unchanged. Examined the
VerifyResult vocabulary, REST/MCP parsing order, service payload, and defensive
score parse.

Learned: six exact snake_case result strings are accepted. REST and MCP parse
before GraphService, so unknown strings create no event and no verification
counter. REST accepts optional observed_at; MCP uses current time. Scoring
still treats unparseable stored strings as neutral. No request was run.

Unknown: which timestamp strings parse and how MCP differs.

Next: trace `oag_api::dto::parse_timestamp` and `now_or`.

## 2026-11-22 — finding 0209: RFC3339 timestamp boundary

All six source branches fetched successfully; heads unchanged. Examined the
REST timestamp parser, evidence/assert DTOs, verify default, MCP clock, and
diff.

Learned: REST parses RFC3339 to Unix seconds, discarding subsecond precision.
Missing evidence/assert timestamps stay absent; missing verify timestamp uses
the server clock. MCP always uses its current time. Invalid strings fail before
service and counters. No request was run.

Unknown: re-fetch next invocation and choose the largest remaining gap.

## 2026-11-22 — finding 0210: re-verified event provenance

All six source branches fetched successfully; heads unchanged. Examined the
provenance service, signature re-derivation, human caller, and diff.

Learned: provenance reopens the raw event by assertion ID, picks local or peer
key, and re-verifies full envelope plus derived ID. Missing key is reported as
unknown, not valid; malformed stored origin/key is InvalidInput. No check was
run.

Unknown: what the human assertion page displays from provenance.

Next: trace `oag-api/src/human.rs` assertion-page provenance rendering.

## 2026-11-22 — finding 0211: assertion-page signature states

All six source branches fetched successfully; heads unchanged. Examined the
assertion handler, provenance template branches, and scoped diff.

Learned: the page shows origin peer and a three-state signature result: valid,
INVALID against a known key, or unverifiable without a key. Missing provenance
is unknown. Actor and origin are displayed separately, and raw signed payload
is not shown. No page was rendered.

Unknown: which evidence fields the assertion page exposes.

Next: trace `oag_api::human::evidence_view` and the assertion evidence template.

## 2026-11-22 — finding 0212: assertion-page evidence subset

All six source branches fetched successfully; heads unchanged. Examined the
evidence view, assertion handler, template, storage query, and diff.

Learned: the page shows type/title/excerpt/URI/hash only. Evidence ID,
timestamps, and metadata are omitted from the view; redaction removes displayed
text. URI is escaped but not scheme-checked. No page was rendered.

Unknown: what verification, dispute, and retraction state the page exposes.

Next: trace `observation_view`, `dispute_view`, `retraction_view`, and their
assertion-template sections.

## 2026-11-22 — finding 0213: reduced audit display

All six source branches fetched successfully; heads unchanged. Examined audit
view structs, handler collection, template sections, storage queries, and diff.

Learned: the page shows observation result/time and dispute/retraction reason/time
but drops actor IDs and event IDs. Lists are unordered; only the first supersede
history event is linked; final status is shown separately. No page was rendered.

Unknown: re-fetch next invocation and choose the largest remaining gap.

## 2026-11-22 — finding 0214: durable operator interventions

All six source branches fetched successfully; heads unchanged. Examined the
three local operator-state repositories and rebuild reapplication.

Learned: evidence/actor redaction tombstones and search suppressions are stored
outside the wipe list. Redactions are one-way locally; suppression is idempotent
and reversible. Rebuild reapplies redactions after event replay; suppression is
a live query filter. No rebuild was run.

Unknown: re-fetch next invocation and choose the largest remaining gap.

## 2026-11-22 — finding 0215: authority cache lifecycle

All six source branches fetched successfully; heads unchanged. Examined
authority recompute, score storage, rebuild exclusion, and scoped diff.

Learned: recompute clears all authority rows before per-node upserts without one
transaction, so a partial failure leaves partial scores. Rebuild deliberately
preserves node_authority because edges replay byte-identically. No recompute or
rebuild was run.

Unknown: full projection-wipe boundary across every schema table.

Next: audit `clear_projection_tables` against the schema.

## 2026-11-22 — finding 0216: exact rebuild wipe boundary

All six source branches fetched successfully; heads unchanged. Audited the
hardcoded delete list, rebuild transaction, schema inventory, and scoped diff.

Learned: rebuild deletes exactly eleven derived graph tables child-first. Event
tables, peer tables, operator-state tables, and several caches/indexes survive.
Only evidence and actor redactions are reapplied; suppression remains a live
filter. Cache survival outside the documented exclusions is an observed
consequence, not a stated policy. No rebuild was run.

Unknown: re-fetch next invocation and choose the largest remaining gap.

## 2026-11-22 — finding 0217: peer ID derivation

All six source branches fetched successfully; heads unchanged. Examined peer-ID
derivation, Base32 encoding/parsing, identity storage, and scoped diff.

Learned: PeerId hashes the Ed25519 verifying key with plain BLAKE3 and renders
as oagp_ plus lowercase unpadded Base32. Parsing accepts uppercase suffix but
requires 32 bytes. from_bytes does not prove key derivation. No key was used.

Unknown: exact signed message and cross-domain failure guarantee.

Next: trace `oag_crypto::sign_with_domain` and `verify_with_domain`.

## 2026-11-22 — finding 0218: domain-separated signing message

All six source branches fetched successfully; heads unchanged. Examined the
sign/verify helpers, canonical JSON wrapper, domain constants, tests, and diff.

Learned: signatures cover raw `domain_prefix || canonical_json_bytes`, with no
added delimiter except the constants' trailing colon. Wrong bytes or wrong
domain fail verification. Helpers do not validate JSON or domain shape. Tests
were read only.

Unknown: how event IDs derive from signed canonical envelopes.

Next: trace `oag_events::envelope::SignedEvent` and `verify_and_derive_id`.

## 2026-11-22 — finding 0219: derived event IDs

All six source branches fetched successfully; heads unchanged. Examined event
envelopes, build pipeline, verification, EventId domain, and scoped diff.

Learned: event IDs are BLAKE3 of the canonical signed envelope under
OAG:EVENT:v1:, while signatures cover only canonical unsigned bytes. No event
ID field exists; verification recomputes it. Signature text participates in the
ID. No signature operation was run.

Unknown: which EventPayload variants and type strings can be signed.

Next: trace `oag_events::payload::EventPayload`.

## 2026-11-22 — finding 0220: closed event payload vocabulary

All six source branches fetched successfully; heads unchanged. Examined the
EventPayload enum, serde tag, payload structs, legacy defaults, and diff.

Learned: exactly ten variants are accepted under SCREAMING_SNAKE_CASE
event_type tags flattened into signed events. NODE_DECLARE is excluded;
NODE_ALIAS included. AddEvidence's newer fields default for legacy events, but
unknown variants cannot deserialize. No event was built.

Unknown: re-fetch next invocation and choose the largest remaining gap.

## 2026-11-22 — finding 0221: node and alias type vocabularies

All six source branches fetched successfully; heads unchanged. Examined node
type newtype, known values, node construction, alias enum, and projection.

Learned: NodeType trims/lowercases arbitrary strings with no validator;
AliasType accepts exactly six snake_case values and unknown aliases fail
projection. peer node type is distinct from ActorType::Peer. No node was
written.

Unknown: actor kinds and permission strings.

Next: trace `oag_core::actor::ActorType` and `Permission`.

## 2026-11-22 — finding 0222: actor and permission vocabularies

All six source branches fetched successfully; heads unchanged. Examined actor
types, actor fields, permission strings, auth-time parsing, and diff.

Learned: ActorType has nine exact snake_case values; Permission has six fixed
strings including graph:crawl. Unknown stored permission strings are silently
dropped at auth, leaving empty permissions. Actors are submitter roles, not
network peers. No actor or key was created.

Unknown: re-fetch next invocation and choose the largest remaining gap.

## 2026-11-22 — finding 0223: cheap canonical identifiers

All six source branches fetched successfully; heads unchanged. Examined
canonical_identifier, UUID helper, service callers, NodeId hashing, and diff.

Learned: canonical_identifier lowercases/trims kind and trims value with no
validation. generate_uuid_identifier exists without a production caller in this
checkout. NodeId hashes the exact string. No node or UUID was generated.

Unknown: what roadmap proposals are and how they are anchored.

Next: trace `oag_graph::roadmap`.

## 2026-11-22 — finding 0224: roadmap proposals as assertions

All six source branches fetched successfully; heads unchanged. Examined the
roadmap hub, predicate, listing sort, REST/human callers, and diff.

Learned: proposals are ordinary instance_of assertions against a lazily created
hub, ranked by active assertions, source independence, evidence strength.
Listing is read-only and has no acceptance threshold or vote. No proposal was
submitted.

Unknown: re-fetch next invocation and choose the largest remaining gap.

## 2026-11-22 — finding 0225: node JSON composition

All six source branches fetched successfully; heads unchanged. Examined the
node handler, alias/authority services, suppression boundary, and diff.

Learned: GET /api/v1/nodes/{id} requires graph:read and returns node, aliases,
and optionally null authority. It is a direct lookup, so suppression does not
hide it. Edges/assertions/provenance are separate endpoints. No request was run.

Unknown: re-fetch next invocation and choose the largest remaining gap.

## 2026-11-22 — finding 0226: full REST assertion audit rows

All six source branches fetched successfully; heads unchanged. Examined the
REST assertion handler, storage structs, human-view contrast, and separate
provenance/history surfaces.

Learned: GET /api/v1/assertions/{id} returns full assertion, evidence,
observations, disputes, and retractions with IDs and timestamps. No status or
redaction filtering; provenance/history are separate. No request was run.

Unknown: re-fetch next invocation and choose the largest remaining gap.

## 2026-11-22 — finding 0227: REST write DTO boundary

All six source branches fetched successfully; heads unchanged. Examined
EvidenceRequest, AssertRequest, DeclareAliasRequest, service validation, and
diff.

Learned: JSON `type` maps to evidence_type; REST assertions cannot set
extraction_method and become Direct. Timestamps and alias types parse at DTO;
field lengths, evidence count, evidence type, and permissions are checked later.
pinned_cid is unverified. No request was run.

Unknown: re-fetch next invocation and choose the largest remaining gap.

## 2026-11-22 — finding 0228: MCP service and auth boundary

All six source branches fetched successfully; heads unchanged. Examined MCP
streamable HTTP service, bearer auth, error mapping, and tool tracing.

Learned: MCP session factory clones the same GraphService/embedding/crawler as
REST. Tools require Authorization: Bearer, record actor in an mcp_tool span, and
log duration/result. No MCP server or tool was run.

Unknown: re-fetch next invocation and choose the largest remaining gap.

## 2026-11-22 — finding 0229: local commit serialization

All six source branches fetched successfully; heads unchanged. Examined the
GraphService commit lock, commit_local_event transaction, and scoped diff.

Learned: commit_event holds a process-local mutex, but BEGIN IMMEDIATE in
commit_local_event is now the primary protection for same-peer concurrency.
Event insert, projection, refs, and origin advance share one transaction. No
event was committed.

Unknown: re-fetch next invocation and choose the largest remaining gap.
