# Progress

## State

Loop spec now tracks `origin/<branch>` instead of frozen pins. Findings
`0001`–`0130` still describe the `explained` SHAs in `specs/revisions.md`.
Fetched `latest` is ahead for core (424), mesh (44), listend (39), collisions
(3), and imagination (3). Data Roads matches.

## Decisions

- Never `LOOP_DONE`. The check always exits 1.
- A drifted `latest` cell is fixed before any new mechanism.
- Catch-up re-audits `explained..latest` one repo, then one stale file, per turn.

## Next three steps

1. Fetch. If `specs/revisions.md` matches `origin`, begin the core catch-up:
   `git -C /home/webdawg/DATA/CODE/rust-ai diff --stat 87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe..origin/main`.
2. Write `specs/inventory/open-agent-graph.txt` from that `origin/main` tree and
   mark changed paths `stale` in `specs/coverage.md`.
3. Re-audit one stale path, or if none exist yet, `crates/oag-events/src/projector.rs` at `origin/main`, as finding `0131`.
