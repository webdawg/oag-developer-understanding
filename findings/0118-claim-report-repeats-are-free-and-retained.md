# 0118 — Repeat claim reports from a known cluster are free and still stored

Claim `B-118`: at mesh `9f5d89e9fcf944dc16eff61f17543e83fc6ad20c`,
`ClaimCorroboration` keeps a vector of reports per claim ID. The first report
for a new claim needs 16 proof-of-work bits. A new cluster name on that claim
costs 16 bits plus 4 bits for each distinct cluster already stored. A report
whose cluster string already appears for that claim requires 0 bits.

## Storage

`add` still appends a `RecordedReport` after a zero-bit check passes. Query-time
counting deduplicates peers and clusters, but the vector itself does not. One
signer and one cluster name can therefore append repeated reports without
further proof of work. Distinct claim IDs and cluster strings have no inspected
length or count cap. The structure is process memory and disappears on exit.
No report was submitted.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-118 | Implemented | `oag-mesh/src/corroboration.rs:41-55` and `258-306` |

Verification: source inspection only.

## Next investigation

Trace `best_corroborated_value` and record exactly which stored duplicates it hides from the caller.