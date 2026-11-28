# 0231 — Transfer receipts are local assertions by a peer actor

Claim `B-0231`: at core `fb54e431332a030a566099c76fb2558084765422`,
`record_transfer` does not use a bearer token. It declares an idempotent local
`ActorType::Peer` actor from the peer's own signing key, synthesizes a
`GraphAssert` auth context, and writes a `sent_to` assertion plus a
`service_receipt` evidence row into the local graph.

## Order of behavior

1. `record_transfer` calls `sign_actor_key_proof` with `local_identity`'s
   signing key, actor type `peer`, and no name/identity URI, then
   `declare_actor` with that proof. The key-derived actor ID deduplicates
   repeated transfers (finding 0230).
2. It builds `AuthContext { actor_id, permissions: [GraphAssert] }` directly in
   process. No API key or HTTP authorization header is involved.
3. It asserts `peer:<server_peer_id> sent_to peer:<client_peer_id>` with node
   type `peer`, `observed_at = served_at`, and the caller's extraction method.
4. It adds `service_receipt` evidence with the content hash, pinned CID,
   retrieval time, and metadata carrying protocol, byte size, peer role,
   counterparty, both nonces, receipt hash, and optional `relayed_via`.
5. The server calls this after serving; the CLI client calls it after verifying
   the receipt. Each writes to its own local graph. `oag-sync` later lets a
   third peer see both sides' records on the same edge.

## What is durable, rejected, and left behind

Durable: two local graphs may each hold one side's signed assertion and receipt
evidence; sync can later corroborate them. Rejected: proof/key errors, assertion
validation failures, and evidence write failures propagate as `TransferError`.
The peer actor row is created once and reused.

The assertion records the local perspective of a transfer, not a global
delivery guarantee or a multi-party signature chain. `relayed_via` is metadata
on one record, not a newly signed relay chain. No transfer was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0231a | Implemented actor/auth setup | `crates/oag-api/src/transfer.rs:303-341` |
| B-0231b | Implemented assertion and evidence | `crates/oag-api/src/transfer.rs:342-392` |
| B-0231c | Implemented server call site | `crates/oag-api/src/transfer.rs:560-628` |
| B-0231d | Implemented actor proof and identity | `crates/oag-graph/src/service.rs:45-69`, `245-283`; `crates/oag-events/src/projector.rs:308-349` |
| B-0231e | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-api/src/transfer.rs` (only a new test) |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No transfer or graph write was executed.

## Change since the previously explained commit

`record_transfer` is unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`; the only added transfer code is a
test for relay path refusal. Finding 0230 records the actor identity used here.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining gap from
the journal and revision table.
