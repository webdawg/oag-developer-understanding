# 0125 — The sync client requests a range but does not prove it is contiguous

Claim `B-125`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, after hello
the client asks for events from its local sequence plus one through the remote
head. The server selects rows with `sequence BETWEEN from AND to`, ordered by
sequence, and clamps the upper bound to 999 above `from`. It returns those
rows. It does not error when the first row is not `from` or when numbers are
missing.

## What reaches ingest

The client feeds the returned events to `ingest_remote_event` in response
order. It does not check that the first sequence equals the requested start or
that each sequence is one greater than the previous. A hole therefore becomes
the `SequenceGap` rejection from finding 0124, the error is recorded, and the
loop stops. Later events in that response are not applied. An empty response is
not an error, so a hello head ahead of stored rows can leave the local sequence
unchanged. The ingest comment's assumption that the client always fetches a
contiguous range is true only when the server's stored rows have no holes. No
sync request was sent.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-125a | Implemented client | `oag-sync/src/service.rs:351-389` |
| B-125b | Implemented fetch | `oag-sync/src/client.rs:71-78` and `server.rs:74-106` |
| B-125c | Implemented query | `oag-storage/src/repo/events.rs:187-198` |

Verification: source inspection only.

## Next investigation

Trace the 1000-event clamp and determine whether the next gossip tick resumes at the new local head or repeats a failed range forever.