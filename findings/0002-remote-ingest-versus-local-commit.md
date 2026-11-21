# 0002 — Remote ingestion verifies trust and contiguity before projection

Claim `B-002`: at `open-agent-graph` `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
remote ingestion does not create or sign an event. It verifies a caller-trusted
key, derives the event ID, rejects gaps and predecessor mismatches, and records
same-sequence conflicts as forks. Only a new contiguous event reaches the same
insert-project-advance transaction used by local commit.

## Why it matters

Local acceptance means “this peer signed and committed its next event.” Remote
acceptance means “an already signed event survived trust, identity, chain, and
conflict checks.” Conflating them hides who chooses keys and how partitions or
conflicting histories are handled.

## What the caller must already trust

`ingest_remote_event` takes a `VerifyingKey` from its caller. It checks that the
key derives to the event's claimed origin peer, but the function comment states
that selecting which key is trusted remains the caller's responsibility. This
finding does not establish the peer-discovery or hello protocol.

Signature verification canonicalizes the unsigned event, requires a 64-byte
signature, verifies it in the event-ID domain, and derives the event ID from the
canonical signed envelope. A caller-supplied ID is not accepted.

## Outcomes

| Condition | Result | Projection |
| --- | --- | --- |
| Signature, key, or chain check fails | Error | No |
| Same origin sequence already stores this event ID | `AlreadyKnown` | No |
| Same origin sequence stores a different event ID | `Forked` | No |
| Sequence is not the next contiguous sequence | `SequenceGap` | No |
| Predecessor differs from the current head | `PreviousEventMismatch` | No |
| All checks pass and insertion is new | `Applied` | Yes, before commit |

The duplicate and fork paths commit their transaction too, but they commit
bookkeeping rather than a new projected event. A fork upserts peer information,
records both event IDs and the incoming signed JSON, and marks the peer forked.
Neither conflicting event is projected or allowed to advance the head by this
path.

## Shared and different persistence

After validation, remote ingestion inserts the event, calls the same `project`
function, advances the origin, and commits. That shared tail is **implemented**.
It was not crash-tested.

Important differences:

- Local commit generates the next sequence and signs with the local identity.
  Remote ingestion uses the sequence and signature inside the offered envelope.
- Local duplicate insertion returns an unexpected-existence error. Remote
  same-event delivery returns a successful idempotent `AlreadyKnown`.
- Remote gaps are rejected, not buffered. The comment says this choice depends
  on the sync client fetching contiguous ranges; that client was not traced here.
- Remote ingestion has no equivalent of `GraphService::commit_lock` in this
  function. Concurrent remote ingestion behavior is **unknown**.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-002a | Implemented | `crates/oag-events/src/ingest.rs:46-174` |
| B-002b | Implemented | `crates/oag-events/src/validate.rs:10-50` |
| B-002c | Implemented comparison | `crates/oag-events/src/commit.rs:27-104` |

Verification: source inspection only. Embedded tests were not executed.

## Next investigation

Find the actual caller that selects `verifying_key` and invokes
`ingest_remote_event`, then determine whether sync fetches ranges, retries
gaps, or advances any peer cursor before ingestion succeeds.
