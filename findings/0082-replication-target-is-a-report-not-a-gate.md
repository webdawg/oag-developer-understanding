# 0082 — The replication target is reported, not enforced

Claim `B-082`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, a search of
`crates/` finds `meets_target` used to build a status value and to print or
serialize it. No inspected caller refuses a write, backup, shutdown, or sync
because the target is unmet.

## Callers

`oag status` prints `OK` or `BELOW TARGET` and continues successfully either
way. `oag replication status` prints the JSON status and returns. The HTTP
route and metrics renderer report the same status. Tests assert the value but
do not make it a production gate.

A false caught-up report can therefore change what an operator sees and what an
unauthenticated scraper reads. It does not, in the inspected code, authorize
data destruction or suppress replication. Callers outside `crates/` were not
searched.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-082a | Implemented | `crates/oag-cli/src/commands.rs:283-305` |
| B-082b | Search | `rg meets_target crates` returned status, metrics, HTTP, and tests only |

Verification: source inspection and search only. No command was run.

## Next investigation

Trace the backup command and determine what it copies, whether it includes secrets, and what it reports as success.