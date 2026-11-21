# 0038 — Claim cross-checks attest cluster names, not reporter membership

Claim `B-038`: at mesh `9f5d89e9fcf944dc16eff61f17543e83fc6ad20c`, claim reports
are ranked by distinct self-asserted cluster names and then distinct peer IDs.
The cross-checked query drops reports whose cluster name lacks enough bridge
attestations, but it cannot prove that the reporting peer belongs to that cluster.

## Ranking behavior

`add` verifies the report, checks proof of work, and appends a recorded report.
Repeat reports from a cluster that has already reported the claim require zero
additional proof bits. New cluster names pay escalating difficulty.

`best_corroborated_value` groups by observed-value hash. Repeated reports from
the same peer or same cluster count once within a value. The highest distinct
cluster count wins, with distinct peer count breaking ties. This deduplication
does not validate that the cluster name corresponds to a real cluster.

`best_corroborated_value_cross_checked` first calls
`is_attested_base_cluster`. The transport default threshold is one attestation.
If all reports for a known claim are dropped, it returns a result with `best:
None` and a nonzero dropped count, distinguishing that case from a claim that
was never reported.

The implementation comment states the remaining gap directly: a peer may claim
an attested cluster name without any signed fact establishing its standing in
that cluster. No such membership fact exists in the inspected crate.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-038a | Implemented | `oag-mesh/src/corroboration.rs:275-384` |
| B-038b | Implemented default | `oag-mesh/src/transport.rs:233-248` |

Verification: source inspection only. Corroboration tests were not executed.

## Next investigation

Return to core and trace the SQLite transaction and crash boundary around `BEGIN IMMEDIATE`, rollback, and what a caller can infer after a commit error.