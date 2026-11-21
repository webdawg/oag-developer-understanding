# 0036 — Mesh transport accepts locally and pushes best-effort

Claim `B-036`: at mesh `9f5d89e9fcf944dc16eff61f17543e83fc6ad20c`, mesh transport
keeps its bridge tree, anonymous-event log, and claim corroboration in process
memory. A successful push means one configured peer accepted the HTTP request;
broadcast does not retry, persist, or reconcile missed peers.

## State and receipt

`MeshState::new` creates empty in-memory structures and stores a static,
operator-configured peer list. `receive_bridge_declaration` verifies and inserts
the declaration under a write lock, then returns HTTP 204. Invalid declarations
return HTTP 400. No database or restart recovery is visible in this path.

`push_bridge_declaration` posts to `/oag-mesh/v1/bridge-declaration` and returns
success only for an HTTP success status. Broadcast iterates every configured peer,
logs individual failures, and continues. It does not record which peers accepted
the declaration or retry a rejected peer.

Anonymous events and claim reports follow the same shape. Their broadcast solves
proof of work using the sender's current view and sends that same proof
everywhere. The comments state that a receiver with a higher difficulty
requirement rejects it and that the sender does not recompute a harder proof.
Query handlers explicitly describe their result as this node's current view, not
a network-wide fanout.

## Consequence

A 204 is local acceptance, not durable replication or mesh-wide corroboration.
Process restart loses the inspected state unless some untraced caller persists it.
No such persistence was found in this transport module.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-036a | Implemented | `oag-mesh/src/transport.rs:62-82` and `109-127` |
| B-036b | Implemented | `oag-mesh/src/transport.rs:253-261` and `284-307` |
| B-036c | Implemented and documented intent | `oag-mesh/src/transport.rs:301-307` and `337-353` |

Verification: source inspection only. Transport tests were not executed.

## Next investigation

Trace anonymous-event proof-of-work difficulty and determine whether repeated submissions from one party can inflate corroboration or are deduplicated.