# 0003 — Sync chooses the trusted key before ingestion

Claim `B-003`: at `open-agent-graph` `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
the normal pull loop does not let an event envelope choose its verifying key.
It selects a key from the contacted peer or the local peer table, fetches the
next contiguous sequence range, and stops processing that origin when ingestion
forks or returns an error.

## Pull-path behavior

For each origin advertised by a remote hello:

1. The origin is skipped when federation policy rejects it.
2. If the advertised remote sequence is not ahead of the local head, no fetch
   occurs.
3. If the advertised origin is the peer being contacted, its remote public key
   is used. Otherwise the loop loads that origin's key from the local peers
   table. A missing or malformed key skips the origin.
4. The client requests events from `local_sequence + 1` through the advertised
   remote sequence.
5. Events are ingested in returned order with the selected key.
6. Applied and already-known outcomes continue. A fork or ingestion error is
   counted and stops the remaining events for that origin.

This explains the gap policy in finding 0002: the pull loop asks for a
contiguous range beginning at the next local sequence. It does not by itself
prove that the remote server returns an uninterrupted range; a gap still fails
during ingestion.

## Push-path difference

`post_events` also resolves each origin key from the local peers table and
skips events whose origin is unknown, malformed, or federation-rejected. Unlike
the pull loop, an ingestion error increments `skipped` and continues with the
next event. A batch over 1,000 events is rejected before processing.

The handler comment says these sync endpoints are unauthenticated at the
transport layer. Application of an event still depends on possession of a
previously known origin key and successful signature verification. Transport
authentication and peer-key distribution were not fully traced.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-003a | Implemented | `crates/oag-sync/src/service.rs:336-395` |
| B-003b | Implemented | `crates/oag-sync/src/server.rs:110-176` |

Verification: source inspection only. No sync peers or network tests were run.

## Limits

- The earlier `discover_peers` call may populate keys, but its protocol was not
  inspected in this finding.
- `observe_sync_outcome` updates a tensor pad after the loop. That update is not
  part of event durability and was not traced into a consumer.
- Reticulum's separate `ingest_remote_event` caller remains unread.

## Next investigation

Trace `discover_peers` and federation admission, then determine how a previously
unknown origin becomes eligible for key selection.
