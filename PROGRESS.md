# Progress

## State

Repository cloned to this directory at `321c68d` plus the loop spec. Findings
`0001`–`0130` exist. Coverage manifest does not exist yet. No target tests have
been run. Latest journal Next is projection ordering against `created_at`.

## Decisions

- Evidence must come from the README pins, not newer working trees.
- Mission completion is `scripts/goal-check.sh` exit 0, not a prose claim.
- One mechanism, one finding, one commit.

## Next three steps

1. Generate `specs/inventory/*.txt` and `specs/coverage.md` (`unreviewed` only).
2. Write finding `0131` from `crates/oag-events/src/projector.rs` at
   `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` (revocation versus assertion order).
3. Run `bash scripts/goal-check.sh` and append the new Unknown as the next
   journal target.
