# Assumptions

- The mission is the README goal: evidence-backed mechanism explanations for the
  six pinned revisions, not implementation work and not a promise about later
  commits.
- Local checkouts are newer than the pins. `rust-ai` HEAD was `fb54e43` at spec
  time. Reading those working trees would contaminate findings.
- `data-roads` is not checked out beside the others. Clone it read-only to
  `/tmp/oag-pins/data-roads` if `git cat-file` cannot see
  `b5cd2f4e8618f955eb06dd1c4d3edc7234041a7e`.
- Inspection-only remains the method until the operator explicitly asks for
  Observed runs. Do not start servers or tests to raise the score.
- `unknown-blocked` is allowed for at most eight inventory paths. That cap is a
  loop guard, not a claim that only eight unknowns exist in the code. Unresolved
  behavior inside a reviewed file belongs in the finding and journal.
- This directory is a nested git repo inside `open-agent-graph`. Commits belong
  only to `oag-developer-understanding`.
