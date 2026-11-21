# 0114 — A mesh receiver stores a message and does not relay it

Claim `B-114`: at mesh `9f5d89e9fcf944dc16eff61f17543e83fc6ad20c`, the three
receive handlers insert a valid payload into local memory and return. They do
not call `broadcast_bridge_declaration`, `broadcast_anonymous_event`, or
`broadcast_claim_report`. A repository search finds those broadcast functions
only at their definitions and in tests.

## Reach

A message therefore reaches the peers listed on the sender, not the peers of
those peers. An offline or rejected peer is not repaired by a later pull. The
transport specification states the same gap: there is no pull-based
anti-entropy, and an offline peer never receives the message unless something
else pushes it again. That agreement is documented intent plus implemented
behavior, not a test result. The specification's claim that 12 integration
tests exist was not executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-114a | Implemented | `oag-mesh/src/transport.rs:109-190` |
| B-114b | Search | `broadcast_` occurs only in `transport.rs` definitions and tests |
| B-114c | Documented intent | `spec/04-transport.md:52-58` and `89-94` |

Verification: source and specification inspection only.

## Next investigation

Trace bridge-declaration admission and determine whether any caller authentication or rate limit exists beyond signature checks.