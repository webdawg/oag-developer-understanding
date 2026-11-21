# 0022 — Mesh's locked core and crypto source matches the inspected checkout

Claim `B-022`: the source directories `crates/oag-core/src` and
`crates/oag-crypto/src` are identical between mesh's locked core commit
`ce1122589909c151056de33325b14d7022efe2f0` and inspected core
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`. The repository diff between those
commits changes only documentation and future-work files.

## What this permits

Mesh can be described as building against the same inspected `oag-core` and
`oag-crypto` source for this pair of revisions. This removes the source-level
uncertainty from finding 0021 for those two crates only.

It does not make all findings 0001–0020 applicable to mesh. Those findings cover
events, graph, storage, API, sync, and gateway code. Mesh does not lock those
crates, and this comparison did not inspect mesh's use of the shared types.
Identical dependency source is not a runtime integration.

## Evidence

Command, read-only:

```text
git diff --name-only ce1122589909c151056de33325b14d7022efe2f0 \
  87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe -- crates/oag-core/src crates/oag-crypto/src
```

The command produced no file names and exit status 0. A full diff between the
same commits listed:

- `README.md`
- `docs/architecture.md`
- `spec/22-future-work.md`
- `spec/README.md`

No tests or builds were run.

## Next investigation

Read mesh's public exports and identify which `oag-core` or `oag-crypto` types
it actually imports. Record each import as a build-level connection, not as
evidence of a network protocol.
