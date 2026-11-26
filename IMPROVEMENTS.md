# Improvements

Top item first. Keep at least three open. Add file paths when the list thins.

- [ ] `specs/inventory/open-agent-graph.txt`, `specs/coverage.md` — inventory `origin/main` and mark paths changed since `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` as `stale`. Acceptance: coverage names every changed `*.rs` path from `git diff --name-only`.
- [ ] `crates/oag-events/src/projector.rs` at `origin/main` — re-check revocation versus assertion ordering against `created_at`. Acceptance: finding `0131` cites that file and the current `latest` SHA.
- [ ] `specs/revisions.md` — after core stale rows are cleared, set open-agent-graph `explained` to `latest`. Acceptance: `git rev-list --count <explained>..origin/main` is 0 and `JOURNAL.md` names the SHA.
- [ ] `crates/oag-mesh` at `45f9fa8a16f65fc4a2e2fe5238bbbc2a5e462574` — diff against `9f5d89e9` and re-audit one changed file. Acceptance: one finding cites the mesh `latest` SHA.
- [ ] `crates/oag-listend` at `b87dcac9a3c9e0059d90e698e2ec40fb2769ec41` — diff against `aad2d9b2` and re-audit one changed file. Acceptance: one finding cites the listend `latest` SHA.
- [ ] `flows/connection-register.md` — re-check each row against current `latest` imports. Acceptance: every row names the SHA it was last confirmed against.
