# Superseded

Paste [ENGINE.md](ENGINE.md). Do not follow anything below this line.

# Goal — keep explaining OAG, forever, at latest HEAD

Reverse-build evidence-backed explanations of the Open Agent Graph family so a
developer can understand real mechanisms without opening source. Continue from
findings `0001`–`0130`. Do not restart. Do not modify target working trees.

This goal does not finish. Never write `LOOP_DONE`. Never use `--until-done` or
`--max`. `scripts/goal-check.sh` always exits 1 after printing `SCORE:`. Raise
the score. A high score is not a stop.

## Live targets

`specs/revisions.md` is the source of truth. Each row has `latest` (fetched
`origin/<branch>`) and `explained` (commit the findings currently cover).

| Repository | Branch | Git dir |
| --- | --- | --- |
| open-agent-graph | main | `/home/webdawg/DATA/CODE/rust-ai` |
| oag-mesh | main | `/home/webdawg/DATA/CODE/oag-mesh` |
| oag-listend | master | `/home/webdawg/DATA/CODE/oag-listend` |
| oag-collisions | master | `/home/webdawg/DATA/CODE/oag-collisions` |
| oag-imagination-random-data-compute | master | `/home/webdawg/DATA/CODE/oag-imagination-random-data-compute` |
| data-roads | main | `/tmp/oag-pins/data-roads` |

If `data-roads` is missing, `git clone https://github.com/webdawg/data-roads.git /tmp/oag-pins/data-roads`. Allowed target git command: `git fetch origin <branch>` only. Never checkout, reset, merge, commit, or push a target. Evidence is `git show origin/<branch>:<path>` or `git diff <explained>..origin/<branch>`. Ignore dirty working trees.

Baseline findings `0001`–`0130` cite the `explained` SHAs already in `specs/revisions.md`. Those SHAs stay valid history. New claims cite `latest`.

## Every turn, in order

1. Fetch all six `origin/<branch>` refs. If a fetch fails, record it in `ASSUMPTIONS.md` and continue with the last fetched SHA. Do not invent a SHA.
2. If any `latest` cell differs from `git rev-parse origin/<branch>`, this turn is a sync turn for the first drifted repo only. Update that `latest` cell, append a journal line naming old and new SHA, and stop after the commit below.
3. If any repo has `explained` behind `latest`, this turn catches that repo up. Do not start an unrelated mechanism.
   - `git diff --stat <explained>..<latest>` and `git log --oneline <explained>..<latest>`.
   - Paths with an empty diff stay covered. Mark only changed inventory paths `stale` in `specs/coverage.md` (at most one repo per turn).
   - If stale paths remain, re-audit one stale path at `latest`. Add the next finding. It must say what changed or that the old claim still holds, and cite the new SHA plus lines from `git show`.
   - When that repo has no stale paths, set its `explained` cell to `latest` and name the new SHA in `JOURNAL.md`.
4. If every repo is caught up, continue the mission: last journal `Next:`, else the first open `IMPROVEMENTS.md` item. One mechanism. One new finding at the current `latest` SHA.
5. If caught up and the journal Next is empty, deepen the oldest finding whose `Next investigation` is still open. Re-read that symbol at `latest`. Write a new finding. Do not idle.
6. If open `IMPROVEMENTS.md` items are fewer than 3, add three, each with a repo-relative path at the current `latest` and a one-line acceptance check.
7. Update `PROGRESS.md`. Commit only this repo: `Document <mechanism>` or `Track <repo> <shortsha>`. Then run `bash scripts/goal-check.sh`.

## Finding shape

`findings/NNNN-kebab-title.md`, `NNNN` = max+1, four digits.

```markdown
# NNNN — <one claim a developer can use>
Claim `B-NNNN`: at `<repo>` `<full latest sha>`, <what the code does>.
## Why it matters
## Ordered behavior
## State and failure boundaries
## Evidence
## Next investigation
```

Evidence basis: Observed, Implemented, Documented intent, Inferred, Proposed, or Unknown. Location is `path:start-end` from `git show` of that SHA. End with `Verification: source inspection only.` Do not rewrite findings `0001`–`0130`. A false citation gets a new correction finding.

Flip at most three coverage rows per finding, and only paths the finding cites. Status values: `unreviewed`, `stale`, `explained`, `partial`, `out-of-scope`, `unknown-blocked`. `unknown-blocked` needs a reason of at least 40 characters. Do not mass-classify except the one-time inventory commit and the one-repo stale marking above.

Update `flows/connection-register.md` only when a cross-repo call, lock, or explicit non-connection is newly shown. Shared names are not integration.

Add a mermaid diagram only for a path of at least six steps with no diagram yet.

## Non-goals

- No target-repo edits except `git fetch`.
- No vendored source, large code copies, tests, servers, migrations, or network clients against target software.
- Do not push this repo unless the operator asks.
- This directory is nested inside `open-agent-graph`. Never commit these files to the parent repo.

## Score

`bash scripts/goal-check.sh` prints `SCORE:` and always exits 1. The score rises when `latest` matches `origin/<branch>`, when `explained` catches `latest`, and when findings stay contiguous. It falls when a fetch moves a branch and `specs/revisions.md` is left behind. After a score drop, fix that drift before any new mechanism.

## Command

```text
/loop start --file GOAL.md --check "bash scripts/goal-check.sh" --check-timeout 180
```

No `--until-done`. No `--max`. Stop only if the operator runs `/loop stop` or `/loop finish`.
