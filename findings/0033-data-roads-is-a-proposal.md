# 0033 — Data Roads is a proposal, not an executable implementation

Claim `B-033`: at Data Roads `b5cd2f4e8618f955eb06dd1c4d3edc7234041a7e`, the
tracked repository contains only `LICENSE`, `README.md`, `rfc/0001-data-roads.md`,
and `paper/data-roads.md`. There is no Cargo manifest, source directory, test,
or service implementation in the tracked file inventory.

## Proposed connection versus evidence

The README proposes encrypted, redundantly distributed storage with renewable
access agreements. It says the design is intended to sit on Open Agent Graph for
ownership events and on mesh for distribution. Those statements are documented
intent. They do not show a caller, protocol message, dependency, or runtime path
in this repository.

No finding in this research pass establishes that core or mesh implements Data
Roads ownership, access agreements, payment, renewal, or revocation. The
connection register must keep this proposal separate from mesh's signing-primitive
dependency and imagination's storage read path.

The companion paper was not read. The RFC was not fully reviewed in this finding,
so its detailed requirements remain open even though its non-executable status is
established by the repository inventory.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-033a | Implemented inventory | `git ls-files` at `b5cd2f4e` |
| B-033b | Documented intent | `data-roads/README.md:1-24` |

Verification: file inventory and README inspection only.

## Next investigation

Read the Data Roads RFC's ownership and access-agreement sections and extract
proposed requirements without turning them into current behavior.
