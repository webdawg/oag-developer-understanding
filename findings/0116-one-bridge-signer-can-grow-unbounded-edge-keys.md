# 0116 — One bridge signer can add unbounded distinct edges

Claim `B-116`: at mesh `9f5d89e9fcf944dc16eff61f17543e83fc6ad20c`, `MeshTree`
stores edges in a `HashMap` keyed by `(mesh_group, member)`. The value is a set
of declaring peer IDs. Repeating the same signed edge inserts the same peer
once. Changing either string creates a new key. No maximum group length, member
length, or edge count was found in `add` or `verify`.

## State

Before a new distinct declaration, the map has no entry for that pair. After
verification, it owns copies of both strings and the peer ID. There is no
eviction, expiry, or persistence. Process exit drops the map. The HTTP route
does not set an application body limit in the inspected router. The framework's
default limit was not inspected, so this finding does not claim a particular
request-size ceiling. A signer can therefore grow process memory by submitting
distinct fresh declarations until an uninspected lower layer rejects the body.
No declaration was submitted.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-116a | Implemented | `oag-mesh/src/bridge.rs:34-39` and `145-168` |
| B-116b | Implemented route | `oag-mesh/src/transport.rs:87-96` |

Verification: source inspection only.

## Next investigation

Trace the anonymous-event log and determine whether its proof-of-work escalation also caps retained events.