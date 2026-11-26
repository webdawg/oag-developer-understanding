# OAG developer understanding

Reverse-built, evidence-backed explanations of the Open Agent Graph family. The
goal is that a developer can understand real mechanisms without opening source.
Source references are an audit trail, not a substitute for explanation.

License: [AGPL-3.0-or-later](LICENSE).

## Start here

1. [JOURNAL.md](JOURNAL.md) — what has been investigated and what comes next.
2. [findings/](findings/) — mechanism findings `0001` through `0151`.
3. [flows/connection-register.md](flows/connection-register.md) — established and proposed cross-repository connections.
4. [diagrams/0001-local-assertion-commit.md](diagrams/0001-local-assertion-commit.md) — local assertion sequence.

Findings cite the commit they inspected. Live tracking lives in
[specs/revisions.md](specs/revisions.md): `latest` is the fetched branch head,
`explained` is how far the write-up has caught up. The loop keeps fetching and
never treats a catch-up as finished. This repository does not modify the target
repositories.

## Baseline inputs already explained

| Repository | Branch | Commit |
| --- | --- | --- |
| [open-agent-graph](https://github.com/webdawg/open-agent-graph) | main | `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` |
| [oag-mesh](https://github.com/webdawg/oag-mesh) | main | `9f5d89e9fcf944dc16eff61f17543e83fc6ad20c` |
| [oag-listend](https://github.com/webdawg/oag-listend) | master | `aad2d9b2cc763239764fa8ba11ec7e871be00e11` |
| [oag-collisions](https://github.com/webdawg/oag-collisions) | master | `dfc8ca95ce9641c29dec6bebe1586936b113c883` |
| [oag-imagination-random-data-compute](https://github.com/webdawg/oag-imagination-random-data-compute) | master | `7b7dcb8eae70b2df2fa1329fdb7b2dd928e76d29` |
| [data-roads](https://github.com/webdawg/data-roads) | main | `b5cd2f4e8618f955eb06dd1c4d3edc7234041a7e` |

Mesh locks core `ce1122589909c151056de33325b14d7022efe2f0`; its inspected
`oag-core` and `oag-crypto` source matches the inspected core checkout.
Imagination locks core `4bdef2d00b706b9d210b9f2b1678978f94a2b4f1`; its inspected
core, crypto, and storage source also matches, and it reads core storage.
Data Roads has no executable implementation. Shared names alone are not
integration.

## Current coverage

- Core local assertion commit, remote ingestion, sync, discovery, federation,
  cluster admission, event identity, schema constraints, actor keys, crawl,
  search, embeddings, authority, rebuild and its insertion-order replay,
  projection-time target checks, crawler body acceptance, content hashing,
  narrow extraction, and optional LLM fallback, redaction, subgraph limits,
  and resolution.
- Assertion identity, last-write status cache, origin-ordered history, human
  views, observation display versus scoring, visibility, and corroboration
  scoring.
- REST and MCP authorization, human-UI query keys, unauthenticated status and
  metrics, gateway signature, fanout, nonce, relay bounds, NTP answers kept
  separate from graph clocks, and crawler-shared DNS validation and pinning.
- Mesh signing reuse, self-certified bridge declarations, and caller-selected
  corroboration thresholds.
- Imagination's one-shot storage read and seed-dependent routing.
- Listend hash and signature admission, plus collisions prefix behavior,
  bounded tokenization, multi-probe recall, and multi-strategy experiments.
- Data Roads proposal boundaries and unresolved requirements.

No target tests or services were executed. Coverage is not complete.

## Evidence labels

- **Observed:** exercised under recorded conditions. None yet.
- **Implemented:** supported by inspected code.
- **Documented intent:** stated by docs or comments.
- **Inferred:** reasoned interpretation with uncertainty.
- **Proposed:** future behavior, not current behavior.
- **Unknown:** insufficient evidence.

No target tests, services, migrations, or deployments have been run.
