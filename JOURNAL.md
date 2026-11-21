# Research journal

## 2026-11-22 — pass 0: pin inputs and plan the first slice

Examined the destination repository and recorded local or shallow-clone heads
for all six targets. No target source was modified. No tests or services were
run.

Pinned:

- `open-agent-graph` `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`
- `oag-mesh` `9f5d89e9fcf944dc16eff61f17543e83fc6ad20c`
- `oag-listend` `aad2d9b2cc763239764fa8ba11ec7e871be00e11`
- `oag-collisions` `dfc8ca95ce9641c29dec6bebe1586936b113c883`
- `oag-imagination-random-data-compute` `7b7dcb8eae70b2df2fa1329fdb7b2dd928e76d29`
- `data-roads` `b5cd2f4e8618f955eb06dd1c4d3edc7234041a7e`

Learned: the destination began with only `README.md` and `LICENSE`. The local
core and mesh checkouts each have an untracked `TESTING_ROADMAP.md`; those files
are outside this analysis and will not be published or treated as upstream
source.

Unknown: the actual local assertion path, its authorization boundary, transaction
behavior, and remote-ingestion differences.

Next: trace one local assertion/event operation in `open-agent-graph` from its
public entry point through signing, storage, projection, and response. Then
compare it with remote ingestion.
