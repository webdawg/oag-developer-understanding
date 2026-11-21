# 0006 — A cluster claim is self-certified, not centrally authorized

Claim `B-006`: at `open-agent-graph` `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
a cluster declaration proves that the signing peer claimed a cluster name. It
does not prove that any cluster authority admitted that peer. After signature,
peer-key, and five-minute freshness checks, the server stores the claimed name
as that peer's latest cluster claim.

## Verification

`cluster::verify`:

1. parses the declared peer ID and public key;
2. rejects a peer ID not derived from that key;
3. verifies the signature over canonical JSON using domain `OAG:CLUSTER:v1:`;
4. rejects timestamps more than 300 seconds from the verifier's current time;
5. returns the verified peer ID.

`post_cluster` maps every verification failure to HTTP 400 and every storage
failure to HTTP 500. On success it upserts `(peer_id, cluster, timestamp)` and
returns 204. There is no comparison against an allowlist, invitation, or
existing membership authority in this handler.

The module comment states the consequence directly: a cluster name is a shared
unauthenticated label, and anyone who knows or guesses it can claim it. That
comment agrees with the inspected control flow. It remains a documented design
claim plus implementation inspection, not a live exploitation test.

## Consequence for finding 0005

Once stored, only the cluster string is consulted by `same_cluster`. Therefore
the federation bypass depends on a self-certified label. Learning the configured
cluster name is sufficient to construct a claim that passes this handler,
provided the claimant signs with its own matching keypair. Whether additional
routing, rate limits, or deployment controls reduce exposure was not traced.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-006a | Implemented | `crates/oag-sync/src/cluster.rs:32-116` |
| B-006b | Implemented | `crates/oag-sync/src/server.rs:221-242` |

Verification: source inspection only. Embedded cluster tests were not executed.

## Next investigation

Trace who configures `[cluster].name`, how declarations are broadcast, and
whether any later check constrains a self-certified cluster claim before the
federation bypass.
