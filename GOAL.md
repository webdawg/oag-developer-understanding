# Goal — finish OAG developer understanding

Reverse-build evidence-backed explanations of the Open Agent Graph family so a
developer can understand real mechanisms without opening source. Continue from
findings `0001`–`0130`. Do not restart. Do not modify any target repository.

Done when `bash scripts/goal-check.sh` prints `SCORE:` and exits 0. Do not
write `LOOP_DONE` before that. The check, not a prose claim, decides completion.

## Scope

Explain pinned revisions only. Source citations are an audit trail. Shared names
are not integration. Record non-connections in `flows/connection-register.md`.

| Repository | Local git dir | Pin |
| --- | --- | --- |
| open-agent-graph | `/home/webdawg/DATA/CODE/rust-ai` | `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` |
| oag-mesh | `/home/webdawg/DATA/CODE/oag-mesh` | `9f5d89e9fcf944dc16eff61f17543e83fc6ad20c` |
| oag-listend | `/home/webdawg/DATA/CODE/oag-listend` | `aad2d9b2cc763239764fa8ba11ec7e871be00e11` |
| oag-collisions | `/home/webdawg/DATA/CODE/oag-collisions` | `dfc8ca95ce9641c29dec6bebe1586936b113c883` |
| oag-imagination-random-data-compute | `/home/webdawg/DATA/CODE/oag-imagination-random-data-compute` | `7b7dcb8eae70b2df2fa1329fdb7b2dd928e76d29` |
| data-roads | `/tmp/oag-pins/data-roads` (clone if missing) | `b5cd2f4e8618f955eb06dd1c4d3edc7234041a7e` |

Working trees are newer than these pins. Never `read` a target working tree as
evidence. Use `git -C <dir> show <pin>:<path>` or a detached worktree under
`/tmp/oag-pins/`. Do not checkout, reset, commit, or push in a target repo.

## Non-goals

- No edits under target repos, including their `target/` or git config.
- Do not rewrite findings `0001`–`0130` unless a citation is false. Then add a
  correction finding; do not silently replace history.
- Do not vendor source, copy large code blocks, or run target tests, servers,
  migrations, or network clients.
- Do not treat this nested repo as part of `open-agent-graph`. Commit only here.
- Do not push unless the operator asks.

## Each iteration

One mechanism. One finding. One commit. Then stop the turn.

1. Read the last `Next:` in `JOURNAL.md` and the first open item in
   `IMPROVEMENTS.md`. Follow that unless `PROGRESS.md` names a narrower step.
2. Inspect only the pinned files named by that item. Quote path and line from
   `git show`, not memory.
3. Add `findings/NNNN-kebab-title.md` where `NNNN` is max+1, four digits.
4. Append a journal entry: Examined / Learned / Unknown / Next. The Next must
   name the following file or symbol.
5. If the mechanism crosses repositories, add or revise one connection-register
   row. State `no integration` when that is the evidence.
6. Add a mermaid diagram only when the ordered path has at least six steps and
   no diagram cites this finding.
7. Flip at most three `specs/coverage.md` rows that this finding actually cites.
   A row may become `explained` or `partial` only if the finding contains that
   repo-relative path. Use `unknown-blocked` only when the pin lacks the
   evidence; name the missing file. Never mass-classify.
8. Update `PROGRESS.md` (state, decision, next three file paths) and
   `ASSUMPTIONS.md` if a guess was required.
9. Commit only this repo: `Document <mechanism>`. Do not commit unrelated files.

If `specs/coverage.md` or `specs/inventory/` is missing, the iteration is
inventory, not a finding. Generate inventories with `git ls-tree -r --name-only
<pin>` and keep `*.rs`, `*.sql`, `*.md`, and `Cargo.toml`. Drop `Cargo.lock`,
`LICENSE`, and `target/`. Write `specs/coverage.md` with every path `unreviewed`.
That inventory commit is the only allowed batch classification.

## Finding shape

```markdown
# NNNN — <one claim a developer can use>

Claim `B-NNNN`: at `<repo>` `<full pin>`, <what the code does>.

## Why it matters
## Ordered behavior
## State and failure boundaries
## Evidence
## Next investigation
```

Evidence table columns: ID, basis, location. Basis is one of Observed,
Implemented, Documented intent, Inferred, Proposed, Unknown. Location is
`path:start-end` at the pin. End with: `Verification: source inspection only.`
Label uncertainty in the claim. Do not upgrade Implemented to Observed.

## Completion criteria

`scripts/goal-check.sh` exits 0 only when all are true:

- Six pin inventories match `git ls-tree` of the pins above.
- Every inventory path has one coverage row: `explained`, `partial`,
  `out-of-scope`, or `unknown-blocked`. No `unreviewed`.
- `explained` / `partial` rows are cited by the named finding file.
- `unknown-blocked` is at most 8 rows, each with a distinct reason.
- Identical `out-of-scope` reasons are not reused more than 5 times.
- Findings stay contiguous from `0001`. New findings have the sections above.
- `JOURNAL.md` mentions the highest finding number.
- `README.md` still names the same six pins.
- `flows/connection-register.md` exists.

## Milestone order

1. Build inventories and `specs/coverage.md` (`unreviewed`).
2. Finish the open journal Next: projection ordering versus `created_at` in
   `crates/oag-events/src/projector.rs` at core pin `87f9e8c1`.
3. Walk remaining core `unreviewed` `*.rs` files, one mechanism per turn.
   Prefer call paths already named in a finding's Next over alphabetical order.
4. Then mesh, listend, collisions, imagination, data-roads, in that order.
5. Re-audit the connection register against import and spawn sites.
6. Refresh `README.md` coverage from the manifest. Do not claim tests were run.

## Quality

- Cite lines you just printed from `git show` / `git blame -L` style output.
- If a line range cannot be shown, write Unknown. Never invent lines.
- Keep commits reviewable. No drive-by reformatting of old findings.
- After every finding, run `bash scripts/goal-check.sh` and raise `SCORE`.
- If the score drops, fix that regression before any new mechanism.

## Assumptions

See `ASSUMPTIONS.md`. Missing facts are assumed and recorded there. Do not wait.
