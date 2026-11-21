# 0004 — Discovery stores derived peer keys; cluster membership bypasses federation

Claim `B-004`: at `open-agent-graph` `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
peer discovery rejects an advertised peer ID that does not derive from its
advertised public key before storing the pair. Federation admission has a
separate override: a same-cluster peer is allowed before normal federation and
trust checks.

## Discovery behavior

`discover_peers` fetches a peer list and returns immediately on fetch failure.
It also returns without adding peers when the local table already contains at
least 10,000 peers. Otherwise it processes at most 200 advertised peers and
five addresses each.

For each candidate it:

1. parses the peer ID and 32-byte public key;
2. skips its own peer ID;
3. rejects a key that does not derive to that peer ID;
4. upserts the verified pair and addresses.

The implementation comment distinguishes denial of replication from
impersonation. Storing an attacker key under a victim peer ID could make the
victim's legitimate events fail verification, but `OriginKeyMismatch` still
prevents that attacker key from authenticating events claiming the victim ID.
This is a code-backed explanation of the intended effect, not a live attack
reproduction.

Discovery failure is silent to its caller. A full table, malformed entry, or
upsert error skips or stops discovery rather than failing the surrounding sync.

## Federation behavior

`federation_allows` returns true immediately for a same-cluster peer. The code
comment explicitly calls this a security tradeoff. Non-cluster peers must pass
`FederationPolicy`. When `minimum_trust` is zero or below, no additional trust
score is required. In ephemeral mode, a computed score must meet the threshold;
a trust-computation error returns false.

Thus “federation denied” and “cluster member” are different outcomes. Cluster
membership was not traced into its storage or administrative source.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-004a | Implemented | `crates/oag-sync/src/service.rs:254-286` |
| B-004b | Implemented | `crates/oag-sync/src/service.rs:494-565` |

Verification: source inspection only.

## Next investigation

Trace `same_cluster` and `FederationPolicy::allows`, then determine who can
change cluster membership and what that implies for event admission.
