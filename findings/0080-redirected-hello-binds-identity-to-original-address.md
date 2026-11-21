# 0080 — A redirected hello binds the response identity to the original address

Claim `B-080`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
`sync_with_peer` stores the address it was given, not the URL of the final
response. `SyncClient::hello` returns only the decoded hello body. After a
redirect, the peer ID and public key from that body are upserted and associated
with the pre-redirect address.

## Consequence

The key check proves that the final body is internally consistent: its peer ID
derives from its public key. It does not prove that the body came from the
address stored for later retries. A redirecting address can therefore cause this
peer to record a different peer's identity at the redirector's address. Later
gossip uses that stored address again, so the redirector remains on the path.

This was inferred by connecting finding 0079's default redirect behavior to the
inspected storage call. No redirect was executed. The client API discards the
response URL, so the application cannot currently distinguish the original and
final hosts.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-080a | Implemented | `crates/oag-sync/src/service.rs:297-310` |
| B-080b | Implemented | `crates/oag-sync/src/client.rs:56-62` |

Verification: source inspection only.

## Next investigation

Trace the hello response fields that are trusted after this binding, especially origin heads used for replication status, and determine whether a redirected peer can falsify caught-up state.