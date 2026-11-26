PROJECT OAG — PERPETUAL ENGINE
DEVELOPER UNDERSTANDING

You will receive this exact text repeatedly, for a long time. Every invocation is a continuation. Do not restart. Do not summarize the repository instead of writing a finding. Do not ask what to do next. Leave this directory measurably closer to a developer being able to understand the Open Agent Graph family without opening source.

Working directory, every time:

`/home/webdawg/DATA/CODE/rust-ai/oag-developer-understanding`

This file is the procedure. Do not run `/loop`. Do not follow `GOAL.md`.

---

THE ONLY GOAL

Explain the six repositories below at their current branch heads, then keep those explanations true when the heads move.

A developer who reads only this repository must be able to follow a real mechanism: what runs, in what order, what is persisted, what fails, and what is still unknown. A source citation is an audit trail, not a substitute for that explanation. Shared names are not integration.

License of this repository and of every OAG repository: GNU Affero General Public License, version 3 or any later version (AGPL-3.0-or-later). Do not relicense.

---

WHAT "DONE THIS TURN" MEANS

Minimum bar, in this order. Do not skip ahead. Do not stop after planning.

1. Fetched. All six `origin/<branch>` refs were fetched this invocation, or the fetch failure is written in `JOURNAL.md` with the command and the error.
2. `specs/revisions.md` `latest` cells match those fetched SHAs.
3. One committed slice. Either a catch-up finding, a new mechanism finding, or the first catch-up file list if `specs/catchup/<repo>.txt` does not exist yet for the furthest-behind repository.
4. `JOURNAL.md` has a new entry whose `Next:` names the exact file or symbol the following invocation must open.
5. The commit is in this repository only. Push `main` to `origin` if the remote is `webdawg/oag-developer-understanding`. Never push a target repository.

Then do another slice if the context budget can hold it. Continue until stopped or the budget is tight. At least one slice is required. An invocation that only fetches is a failed invocation.

---

THE SIX REPOSITORIES

Evidence is `git show origin/<branch>:<path>` or `git diff <explained>..origin/<branch>`. Never read a target working tree as evidence. Working trees are dirty or newer. Allowed write in a target git dir: `git fetch origin <branch>` only. Never checkout, reset, merge, commit, or push a target.

| Repository | Branch | Git dir | Remote |
| --- | --- | --- | --- |
| open-agent-graph | main | `/home/webdawg/DATA/CODE/rust-ai` | https://github.com/webdawg/open-agent-graph |
| oag-mesh | main | `/home/webdawg/DATA/CODE/oag-mesh` | https://github.com/webdawg/oag-mesh |
| oag-listend | master | `/home/webdawg/DATA/CODE/oag-listend` | https://github.com/webdawg/oag-listend |
| oag-collisions | master | `/home/webdawg/DATA/CODE/oag-collisions` | https://github.com/webdawg/oag-collisions |
| oag-imagination-random-data-compute | master | `/home/webdawg/DATA/CODE/oag-imagination-random-data-compute` | https://github.com/webdawg/oag-imagination-random-data-compute |
| data-roads | main | `/tmp/oag-pins/data-roads` | https://github.com/webdawg/data-roads |

If the data-roads clone is missing: `git clone https://github.com/webdawg/data-roads.git /tmp/oag-pins/data-roads`. Do not vendor it here.

`specs/revisions.md` holds `latest` (fetched head) and `explained` (commit findings currently cover). Findings `0001`–`0130` cover the `explained` SHAs already written there. Do not rewrite them. A false citation gets a new correction finding.

---

HOW TO WORK

Start of every invocation:

1. `cd` to this directory. Confirm `git remote -v` is `webdawg/oag-developer-understanding`. If it is not, stop and say so. Do not commit to the parent `open-agent-graph` repository.
2. `git status`, branch, last five commits.
3. Read the tail of `JOURNAL.md` and the table in `specs/revisions.md`.
4. Fetch all six branches. Update any stale `latest` cell.
5. Choose the repository with the largest `git rev-list --count <explained>..origin/<branch>`. That is the catch-up target. On a tie, use the table order above.

Catch-up, when that count is greater than zero:

1. If `specs/catchup/<repo>.txt` is missing or does not name the current `latest` SHA on line 1, this slice writes that file and stops after the commit. Line 1 is the `latest` SHA. Remaining lines are `git diff --name-only <explained>..origin/<branch>` for `*.rs`, `*.sql`, `*.md`, and `Cargo.toml`, excluding `Cargo.lock`, `LICENSE`, and `target/`. Do not read all of those files in this slice.
2. Otherwise take the first path in that list that no finding cites together with the current `latest` SHA. `git show origin/<branch>:<path>`. `git log --oneline <explained>..origin/<branch> -- <path>`. Write the next finding.
3. The finding says either what changed since `explained`, or that the earlier claim still holds, and adds one new mechanism detail from the current file. Cite `path:start-end` from the `git show` output you just printed. If you cannot show the line, write Unknown. Never invent lines.
4. Remove that path from `specs/catchup/<repo>.txt`.
5. Do not set `explained` equal to `latest` until the catch-up list is empty. When it is empty, set it, and name the SHA in the journal.

New ground, when every repository is caught up:

1. Open the file or symbol named by the last journal `Next:`.
2. If that Next is missing, take the first `*.rs` path at `origin/<branch>` that no finding cites, in table order.
3. Write one finding at the current `latest` SHA.
4. If this invocation still has budget, do one more such finding. Do not widen into a survey.

Finding shape. `NNNN` is max+1, four digits. Filename `findings/NNNN-kebab-title.md`.

```markdown
# NNNN — <one claim a developer can use>

Claim `B-NNNN`: at `<repo>` `<full latest sha>`, <what the code does>.

## Why it matters
## Ordered behavior
## State and failure boundaries
## Evidence
## Next investigation
```

Evidence basis is one of: Observed, Implemented, Documented intent, Inferred, Proposed, Unknown. This engine does not run target tests, servers, migrations, or clients. Do not label anything Observed. End with `Verification: source inspection only.`

Journal entry, after every finding:

```markdown
## YYYY-MM-DD — finding NNNN: <short title>

Examined <files at sha>.
Learned: <what a developer can now rely on>.
Unknown: <one concrete gap>.
Next: <file or symbol the next invocation opens>.
```

Update `flows/connection-register.md` only when this slice shows a cross-repository call, lockfile pin, or a confirmed non-connection. Update `README.md` only in the commit that advances an `explained` cell, and only the tracked SHA. Add a diagram only when the ordered path has at least six steps and no diagram cites this finding.

Commit only files in this repository. Message: `Document <mechanism>` or `List <repo> changes through <shortsha>`. Do not commit `target/`. Never force-push. Never rewrite history. Never overwrite uncommitted changes you did not make. If push fails, write the error in the journal and keep going locally.

---

RULES THAT ARE ALREADY SETTLED

- Explain behavior. Do not paste large source blocks.
- Do not treat a comment as a check unless the code performs that check.
- Do not claim two repositories are integrated because they share a word.
- Do not invent measurements, line numbers, or test results.
- Do not modify target source, and do not "fix" a bug you find. Record it.
- A sequence gap, a fork, a missing cap, or a self-certified claim is a finding, not a suggestion list.
- One mechanism per finding. A file with two mechanisms gets two findings across two invocations.
- Old findings stay. History is the audit trail.

When choosing the slice: a repository behind `origin` before a new subsystem; a journal `Next:` before a random file; a changed path on the catch-up list before a file that did not change.

---

OUT OF SCOPE

- Implementing features in the six target repositories.
- Running their tests or booting their services to manufacture an Observed label.
- Rewriting findings `0001`–`0130`.
- Vendoring source into this repository.
- Architecture essays, coverage percentages without a file list, and plans that are not a finding.
- Pushing, resetting, or merging any repository except a fast-forward push of this one.

---

BEGIN

Fetch. Read the journal tail and `specs/revisions.md`. Take the furthest-behind repository. If its catch-up list is missing, write `specs/catchup/<repo>.txt` and commit it. If the list exists, explain its first remaining path at `origin/<branch>` as the next finding, commit, and push this repository. If nothing is behind, open the journal's `Next:` and do that finding the same way. Continue until stopped.
