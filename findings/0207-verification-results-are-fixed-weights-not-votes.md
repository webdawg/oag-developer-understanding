# 0207 — Verification results are fixed weights, not equal votes

Claim `B-0207`: at core `fb54e431332a030a566099c76fb2558084765422`,
corroboration maps each verification observation to a fixed number from -1 to
+1, averages those numbers across observations on active assertions, rescales
the mean, and gives it half the final agreement score. The other half is the
active-versus-disputed assertion ratio.

## Order of behavior

1. `verify_result_weight` maps `confirmed` to 1.0, `changed` to 0.3,
   `unknown`/`unreachable` to 0.0, `not_confirmed` to -0.5,
   `contradicted` to -1.0, and an unparseable stored value to 0.0.
2. The corroboration query loads observations only for assertions whose status
   is active. Observations attached to disputed, retracted, or superseded
   assertions are not collected here.
3. All collected scores are summed and divided by their count, so every
   observation has equal weight regardless of observer, time, or evidence.
4. `obs_agreement = (mean + 1) / 2`, clamped to `[0,1]`. Thus a mean of -1 maps
   to 0, 0 maps to 0.5, and +1 maps to 1.
5. `base_agreement = active / (active + disputed)`. Retracted and superseded
   assertions are deliberately excluded as lifecycle states.
6. If no observation scores exist, `agreement` is just `base_agreement`.
   Otherwise `agreement = (base_agreement + obs_agreement) / 2`.

## What is durable, rejected, and left behind

Durable: nothing is stored by this scoring path. Rejected: no observation is
dropped for being old, duplicate, or from the same actor; only non-active
parent assertions are outside the collection loop. An unparseable result is
treated as neutral 0 rather than an error, because replicated data may come
from a different software version.

The score is a compromise between assertion-status evidence and verification
results, not a count of confirming peers. A single contradicted observation
can move the observation half fully downward, and a later confirmed one can
move it fully upward; there is no time decay at this step. No score was
computed in this pass.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0207a | Implemented result weights | `crates/oag-graph/src/corroboration.rs:128-142` |
| B-0207b | Implemented observation collection | `crates/oag-graph/src/corroboration.rs:239-265` |
| B-0207c | Implemented agreement combination | `crates/oag-graph/src/corroboration.rs:328-342` |
| B-0207d | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-graph/src/corroboration.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No query or score was executed.

## Change since the previously explained commit

The verification weight table and agreement combination are unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Finding 0012 summarized the
corroboration formula; this finding records the exact observation weights and
combination still used at the newer commit.

## Next investigation

Trace `oag_core::assertion::VerifyResult` parsing and the REST/MCP write paths
to document which result strings become typed observations and which are
rejected before an event exists.
