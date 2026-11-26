# 0160 — Mesh responder inboxes are blinded, poll-only capabilities

Claim `B-0160`: at mesh `45f9fa8a16f65fc4a2e2fe5238bbbc2a5e462574`, a
responder registers a self-chosen random-looking `subscription_id` and an
`EventFilter`. Every accepted anonymous event is synchronously cloned into each
matching inbox; polling the id drains that inbox. The node learns the polling
network address but records no peer identity. The module's "not durable" comment
is stale at this commit: `MeshState` can save and restore both maps, though only
when a caller invokes save/load.

## Order of behavior

1. `POST /oag-mesh/v1/responder-subscriptions` accepts any string id plus a
   flattened `EventFilter` and calls `upsert`. There is no signature, identity
   field, randomness check, or collision refusal. Reusing an id replaces the
   filter and returns 204.
2. `record_anonymous_event` first records the verified event in the anonymous
   log. On success it reads the subscription map, takes the inbox write lock,
   and calls `push_matching`, which appends a clone of the event to every inbox
   whose filter matches. This happens before the 204 response. A configured
   one-hop relay is attempted afterward and cannot reject the submission.
3. `GET /oag-mesh/v1/responder-inbox/{subscription_id}` calls `drain`, which
   removes that id's whole vector and returns it under `{"events": [...]}`.
   An unknown id returns an empty list with 200, not 404.
4. `DELETE /oag-mesh/v1/responder-subscriptions/{id}` removes only the
   subscription; it does not clear that id's queued inbox. Replacing a filter
   likewise leaves already-queued events in place.
5. `save_to_dir` snapshots `responder_subscriptions.json` and
   `responder_inbox.json`; `load_from_dir` rebuilds both maps through
   `from_subscriptions`/`from_inbox`. There is no automatic save on registration,
   dispatch, or drain.

## What is durable, rejected, and left behind

The capability is possession of the id: anyone who knows it can replace the
filter or drain the inbox, because neither route authenticates the holder. The
node stores no `PeerIdentity`, but it does observe the polling connection's
network address; the source calls that out as a limit of blinding.

Rejected: unregistering an unknown id returns 404; an event failing anonymous
admission is never dispatched. Accepted: duplicate events are appended again to
each matching inbox, and no subscription or inbox size cap appears in these
types. A drained vector is gone from memory; a saved snapshot taken before the
drain would restore it on load. The `dispatch.rs` comment saying a restart loses
both maps reflects the pre-persistence design and no longer describes a caller
that uses `MeshState::save_to_dir`/`load_from_dir`. No HTTP request or save was
executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0160a | Implemented registry and inbox | `crates/oag-mesh/src/dispatch.rs:22-88` |
| B-0160b | Implemented dispatch on event admission | `crates/oag-mesh/src/transport.rs:566-595` |
| B-0160c | Implemented HTTP routes | `crates/oag-mesh/src/transport.rs:454-471`, `713-753` |
| B-0160d | Implemented save/load and stale comment | `crates/oag-mesh/src/transport.rs:321-377`, `379-450`; `crates/oag-mesh/src/dispatch.rs:11-16` |
| B-0160e | New since explained commit | `git diff 9f5d89e9..45f9fa8a -- crates/oag-mesh/src/dispatch.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No request, poll, or target test was executed.

## Change since the previously explained commit

`dispatch.rs`, these routes, and the snapshot fields are new at `45f9fa8a...`
relative to explained `9f5d89e9...`. Findings 0115-0123 about anonymous events
and claim reports still describe admission and retention, but not this dispatch
layer. Finding 0158 describes the snapshot mechanism that makes the module's
old "not durable" comment inaccurate for callers that save.

## Next investigation

Trace `oag_mesh::onion::OnionPayload` and `receive_onion_layer` to document how
layering is constructed, peeled, and rejected.
