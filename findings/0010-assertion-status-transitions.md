# 0010 — Status changes append history and replace the current label

Claim `B-010`: at `open-agent-graph` `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`,
dispute, retraction, and supersession do not delete the original assertion.
Each operation commits another event, inserts a history row, and updates the
current status label. Missing referenced assertions fail projection before
commit.

## Service guards

- Dispute requires `graph:assert` and bounds an optional reason at 2,048 bytes.
  It does not require the caller to own the disputed assertion.
- Retraction requires `graph:retract-own`, checks that the assertion exists, and
  requires the caller to be its original actor unless the caller has `admin`.
  This ownership check occurs before the retraction event is committed.
- Supersession requires `graph:assert` but the service method does not itself
  check that either assertion exists or that the caller owns the old assertion.
  Existence of both is checked later by projection.

## Projection results

| Operation | History retained | Status change |
| --- | --- | --- |
| Dispute | Dispute row with actor, reason, and event ID | Target becomes `Disputed` |
| Retract | Retraction row with actor, reason, and event ID | Target becomes `Retracted` |
| Supersede | Supersession row linking old and new IDs | Old becomes `Superseded`; new status is unchanged |

All three reject an unknown target. Supersession rejects when either side is
absent. Because these writes occur in the local event transaction, a projection
error prevents that status event from committing. This atomicity is implemented,
not crash-tested.

Repeated disputes are not deduplicated by the inspected projector. Each new
event can insert another dispute row and set the same disputed status again.
Interaction with a later retraction or supersession depends on event order;
there is no inspected priority resolver that prevents a later dispute from
replacing another status.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-010a | Implemented | `crates/oag-graph/src/assert.rs:265-333` |
| B-010b | Implemented | `crates/oag-events/src/projector.rs:205-302` |

Verification: source inspection only.

## Next investigation

Trace read behavior for status-filtered assertions and determine whether disputed,
retracted, or superseded assertions remain visible through public read APIs.
