# 0195 — The collisions aberration module is an experiment, not an index path

Claim `B-0195`: at collisions `b19fc44d76c975f22cdd07cfa3bc2e4f60cc4c0b`,
`aberration` is an executable physics experiment exposed by the crate and run
through an example. It computes secular aberration drift from circular orbital
speed and compares measured solar motion with the operator's "sun at light
speed" claim. No collision index, query, or ranking function calls it.

## Order of behavior

1. `drift(speed, radius)` computes centripetal acceleration `v²/r`, converts it
   to angular drift `a/c` radians per second, multiplies by a Julian year, and
   returns radians/year, microarcseconds/year, and degrees/year.
2. `cmb_dipole_speed()` uses the CMB dipole amplitude and temperature as an
   independent speed estimate: `C * (dipole / temperature)`.
3. `aberration_constant(speed)` computes the classical annual aberration angle
   `(v/c)` in arcseconds. `measured_drift()` uses 230 km/s at 8.2 kpc;
   `lightspeed_drift()` substitutes `C` at the same radius.
4. The example prints the two scenarios and the classical constant. Tests
   inspect ranges: CMB speed 360–380 km/s, measured speeds below `C/100`,
   Earth's classical constant within 0.01 arcsec of the IAU value, Earth's
   annual drift around 120–140 arcsec/year, and the galactic measured drift
   around 4–6 microarcsec/year.
5. The hypothesis test checks that light-speed orbital motion would produce
   more than one arcsecond of drift per year, a visible displacement over 80
   years, and a drift ratio to measured motion within 1% of `(C / 230 km/s)²`.
   A separate test checks the `v²` scaling and a zero-acceleration case.

## What is durable, rejected, and left behind

Durable state is none: these are constants, pure functions, and tests. The
module is `pub mod aberration` in the library and has an example entry point,
but `git grep` found no production caller in the collision index. It is
therefore an experiment inside the crate, not an integrated inference step.

Rejected by the tests are inconsistent constants or formulas, not candidate
index items. The source says SPEC.md records the operator claim; that is
documented intent, not evidence that the physics module powers Data Roads or
collision ranking. No example, test, or numeric output was executed here.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0195a | Implemented experiment module | `crates/oag-collisions/src/aberration.rs:1-123` |
| B-0195b | Test inspection, not executed | `crates/oag-collisions/src/aberration.rs:125-265` |
| B-0195c | Example entry point and module export | `crates/oag-collisions/examples/aberration.rs:1-15`; `crates/oag-collisions/src/lib.rs:25` |
| B-0195d | Confirmed non-integration | `git grep aberration origin/master -- crates/oag-collisions/src` (only module and tests) |
| B-0195e | Unchanged since explained commit | `git diff dfc8ca95..b19fc44d -- crates/oag-collisions/src/aberration.rs` (no output) |

Verification: source and test inspection via `git show origin/master:<path>` and
scoped greps/diffs. No example or target test was executed.

## Change since the previously explained commit

The aberration module is unchanged between
`dfc8ca95ce9641c29dec6bebe1586936b113c883` and
`b19fc44d76c975f22cdd07cfa3bc2e4f60cc4c0b`. Findings 0149–0151 describe the
actual collision tokenizer, multi-probe query, and domain helper; this finding
records the separate experiment that shares the crate.

## Next investigation

Re-fetch on the next invocation, then choose the largest remaining gap from
the journal and revision table.
