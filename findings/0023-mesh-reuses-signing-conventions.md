# 0023 — Mesh reuses core canonical JSON and crypto signing primitives

Claim `B-023`: at mesh `9f5d89e9fcf944dc16eff61f17543e83fc6ad20c`, the inspected
production imports from core are limited to `oag_core::canonical_json_bytes`
and `oag_crypto` signing, verification, peer identity, and signature types.
No inspected mesh source imports graph events, storage, projection, or sync
services.

## Connection established

Bridge and corroboration code canonicalizes unsigned structs with core's JSON
function and signs or verifies them through `oag_crypto`. Because finding 0022
showed those crate sources match the inspected core revision, this connection
uses the same canonicalization and signature primitives described in core.

The mesh manifest comment states an intent to avoid drifting from core's
canonical JSON and domain-separated signing conventions. The imports agree with
that intent. They do not show mesh reading or writing the core event log, and
they do not establish a network bridge to an `open-agent-graph` peer.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-023a | Implemented imports | `oag-mesh/crates/oag-mesh/src/bridge.rs:21`, `corroboration.rs:25` |
| B-023b | Implemented calls | `bridge.rs:109-128`, `corroboration.rs:190-208` |
| B-023c | Documented intent | `oag-mesh/Cargo.toml:14-18` |

Verification: source search and inspection only. Mesh tests and services were
not run.

## Next investigation

Trace one mesh bridge declaration from signing through verification and state
change, including its failure and replay behavior.
