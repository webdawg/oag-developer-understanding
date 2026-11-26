# Assumptions

- The mission never completes. Upstream commits keep arriving. A green-looking
  score is a cue to fetch again, not a cue to stop.
- `specs/revisions.md` `explained` values are the historical pass that findings
  `0001`–`0130` inspected. `latest` values were fetched on 2026-11-26 and are
  already ahead for every repo except data-roads.
- Local working trees may be dirty or newer than `origin/<branch>`. They are not
  evidence. `git fetch` is the only allowed write to a target git dir.
- `/tmp/oag-pins/data-roads` is disposable. Re-clone it if the pin directory
  disappears. Do not vendor it into this repo.
- Inspection-only remains the method. Do not start target tests or servers to
  raise the score.
- This directory is a nested git repo. Commits belong only here, not in the
  parent `open-agent-graph` checkout.
