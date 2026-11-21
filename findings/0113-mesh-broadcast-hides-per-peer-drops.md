# 0113 — A mesh broadcast caller cannot see which peer dropped a message

Claim `B-113`: at mesh `9f5d89e9fcf944dc16eff61f17543e83fc6ad20c`, the three
broadcast functions return `()`. Each per-peer failure is written as a warning
and the loop continues. The caller receives no count, no failed addresses, and
no distinction between a connection error and an HTTP rejection.

## What a sender can observe

The direct `push_*` functions do return `PushError::Request` or
`PushError::Rejected` with the address and, for rejection, the status code.
Broadcast does not expose that result. A receiver returns HTTP 204 only after
inserting the payload into its process-local tree, event log, or corroboration
map. That 204 does not mean the payload was relayed, persisted, or retained
after restart. Nothing in the receive handlers notifies the original sender if
the process later exits and loses the memory.

A later cross-check query can report `reports_dropped_unattested_cluster` to
whoever asks. That count is not sent back to the peer that submitted the
report. The HTTP client is `reqwest::Client::new()` with no OAG-configured
timeout in `MeshState::new`. The dependency's default timeout was not inspected
here.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-113a | Implemented | `oag-mesh/src/transport.rs:75-82` and `246-353` |
| B-113b | Implemented local receipt | `oag-mesh/src/transport.rs:109-190` |

Verification: source inspection only. No mesh peer was started.

## Next investigation

Trace the receive handlers for any relay or rebroadcast, and determine whether a message stops at the directly configured peers.