# 0026 — No inspected production caller selects a mesh threshold

Claim `B-026`: at mesh `9f5d89e9fcf944dc16eff61f17543e83fc6ad20c`, a search of
`crates/oag-mesh/src` finds `members_of`, `is_attested_base_cluster`, and
`base_clusters_under` defined but finds no production caller passing
`min_corroboration`. Tests and transport code call `corroboration_for` to read
the count, not to enforce a threshold.

## Consequence

The available production behavior is “record distinct verified declarations and
report their count.” Any policy such as requiring two or three peers is not
implemented at an inspected call site. Tests that assert a count equals one or
two demonstrate the counting behavior only; they were not executed and do not
establish a deployed acceptance rule.

This is an absence finding within the searched Rust source. Dynamic callers,
external applications, or uncommitted local files were not considered.

## Evidence

Search command:

```text
rg -n 'corroboration_for\(|members_of\(|min_corroboration' crates/oag-mesh/src
```

The only production threshold parameters were their definitions in
`bridge.rs:177-211`. Call sites in `transport.rs` read counts. Other matches
belong to different corroboration mechanisms or tests.

## Next investigation

Return to cross-repository coverage: pin imagination's locked core revision and
determine whether it imports current core storage or only an older source
surface.
