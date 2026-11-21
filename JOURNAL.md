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
