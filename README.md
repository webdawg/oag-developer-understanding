# OAG developer understanding

Reverse-built, evidence-backed explanations of the Open Agent Graph family. The
goal is that a developer can understand real mechanisms without opening source.
Source references are an audit trail, not a substitute for explanation.

License: [AGPL-3.0-or-later](LICENSE).

## Start here

1. [JOURNAL.md](JOURNAL.md) — what has been investigated and what comes next.
2. [flows/0001-local-assertion-commit.md](flows/0001-local-assertion-commit.md) — first vertical slice, once published.
3. [specs/](specs/) — revision-scoped repository explanations.
4. [findings/](findings/) — short, high-value mechanism findings.

This repository explains pinned revisions. It is not a promise about later
upstream commits, and it does not modify the target repositories.

## Pinned inputs for the current pass

| Repository | Branch | Commit |
| --- | --- | --- |
| [open-agent-graph](https://github.com/webdawg/open-agent-graph) | main | `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` |
| [oag-mesh](https://github.com/webdawg/oag-mesh) | main | `9f5d89e9fcf944dc16eff61f17543e83fc6ad20c` |
| [oag-listend](https://github.com/webdawg/oag-listend) | master | `aad2d9b2cc763239764fa8ba11ec7e871be00e11` |
| [oag-collisions](https://github.com/webdawg/oag-collisions) | master | `dfc8ca95ce9641c29dec6bebe1586936b113c883` |
| [oag-imagination-random-data-compute](https://github.com/webdawg/oag-imagination-random-data-compute) | master | `7b7dcb8eae70b2df2fa1329fdb7b2dd928e76d29` |
| [data-roads](https://github.com/webdawg/data-roads) | main | `b5cd2f4e8618f955eb06dd1c4d3edc7234041a7e` |

Mesh and imagination lockfile revisions are not yet rechecked against these
heads. Shared names are not evidence of runtime integration.

## Evidence labels

- **Observed:** exercised under recorded conditions. None yet.
- **Implemented:** supported by inspected code.
- **Documented intent:** stated by docs or comments.
- **Inferred:** reasoned interpretation with uncertainty.
- **Proposed:** future behavior, not current behavior.
- **Unknown:** insufficient evidence.

No target tests, services, migrations, or deployments have been run.
