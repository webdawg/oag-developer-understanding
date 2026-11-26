# Improvements

Concrete backlog. Take the top open item. Do not mass-close.

- [ ] `specs/inventory/*.txt`, `specs/coverage.md` — generate from the six pins in `GOAL.md`. Acceptance: `bash scripts/goal-check.sh` no longer reports missing inventory or coverage.
- [ ] `findings/0131-*.md`, `JOURNAL.md` — projection order of revocation versus assertion against `created_at` in `crates/oag-events/src/projector.rs` at `87f9e8c1`. Acceptance: finding cites that file and journal Next names one unreviewed symbol.
- [ ] `crates/oag-graph/src/history.rs` at `87f9e8c1` — explain history reads versus event-log residue. Acceptance: one finding cites `history.rs` and a coverage row leaves `unreviewed`.
- [ ] `crates/oag-graph/src/provenance.rs` at `87f9e8c1` — explain provenance assembly and what it does not prove. Acceptance: one finding cites `provenance.rs`.
- [ ] `crates/oag-graph/src/pins.rs` at `87f9e8c1` — explain pin storage versus transfer admission. Acceptance: one finding cites `pins.rs`.
- [ ] `crates/oag-sync/src/gravity.rs` at `87f9e8c1` — explain gravity scoring and whether sync uses it as a gate. Acceptance: one finding cites `gravity.rs`.
- [ ] `crates/oag-sync/src/trust.rs` and `crates/oag-sync/src/presence.rs` at `87f9e8c1` — explain trust updates versus presence writes. Acceptance: one finding cites both files or two findings if the mechanisms differ.
- [ ] `crates/oag-api/src/ntp_wire.rs` at `87f9e8c1` — explain NTP wire use and clock-skew limits. Acceptance: one finding cites `ntp_wire.rs`.
