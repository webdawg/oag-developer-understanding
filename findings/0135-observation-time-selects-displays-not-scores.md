# 0135 — Observation time selects a display, not a corroboration weight

Claim `B-135`: at core `fb54e431332a030a566099c76fb2558084765422`,
`observed_at` on a verification observation decides which observation the node
page labels "last", but it does not weight or filter that observation in
corroboration. Corroboration averages the result weights of every observation
on active assertions. There is no repository-defined tie-break in the human
selection, and the observation list itself has no `ORDER BY`.

## Order of behavior

1. REST `verify_assertion` accepts an optional `observed_at` string through
   `now_or`; a supplied value is parsed, and an omitted value becomes the
   server's current Unix seconds. The value is passed into
   `GraphService::verify_assertion`, which commits a signed
   `VerifyAssertion` event.
2. `project_verify_assertion` stores the observation row with both
   `observed_at` (payload value) and `created_at` (event timestamp), then
   `list_observations` selects rows by assertion ID with no `ORDER BY`.
3. On the human node page, each assertion's `last_observation` is
   `list_observations(...).iter().max_by_key(|o| o.observed_at)`. The target
   source supplies no secondary key. When two rows have the same maximum
   `observed_at`, the winner is determined by Rust's `max_by_key` behavior over
   an unordered SQL result; this repository's code makes no stable promise
   (Unknown).
4. `ObservationView` keeps only `result` and `observed_at`. It drops the
   observation's event ID, observer actor ID, and `created_at`. The assertion
   page renders all observations through the same reduced view.
5. `corroboration_for_edge` separately loads the same observations for active
   assertions and extends `observation_scores` with `verify_result_weight(o.result)`
   for each one. `observed_at` is never read there. The mean of those weights
   is averaged with the active/disputed ratio to form `agreement`. The separate
   `freshness` signal reads each active assertion's `observed_at` or
   `asserted_at`, not observation rows.

## What this means

A future-dated observation can become the displayed "last" observation without
increasing corroboration freshness or agreement. An old observation still
contributes its result weight equally with a recent one. A result that is
unparseable contributes `0.0` rather than panicking; on the REST write path the
result vocabulary is validated before the event is committed, so that branch is
defensive against replicated data from other software.

Durable state contains the full observation row: event ID, assertion ID,
observer actor ID, result, `observed_at`, and `created_at`. The human views and
the agreement score consume different projections of it. No observation is
rejected for being old or future-dated; the only documented clamp is in
`freshness_from_age`, which clamps negative age to zero for the assertion-level
freshness signal. No test or endpoint was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-135a | Implemented caller-supplied time | `oag-api/src/dto.rs:179-187`; `oag-api/src/handlers.rs:213-230` |
| B-135b | Implemented storage and unordered query | `oag-events/src/projector.rs:178-203`; `oag-storage/src/repo/assertions.rs:399-453` |
| B-135c | Implemented display selection | `oag-api/src/human.rs:132-139`, `344-350`, `443-445` |
| B-135d | Implemented scoring input | `oag-graph/src/corroboration.rs:128-142`, `221-265`, `336-349` |
| B-135e | Documented intent for clamping | `oag-graph/src/corroboration.rs:169-176` |

Verification: source inspection via `git show origin/main:<path>` at the stated
commit. No observation was created and no score was computed.

## Change since the previously explained commit

Comparing `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` with
`fb54e431332a030a566099c76fb2558084765422`, `repo/assertions.rs` is unchanged.
The changes in `human.rs` are search pagination, and the changes in
`corroboration.rs` replace evidence source grouping with union-find; the
observation collection, result weights, and freshness lines cited above are
unchanged. Findings 0131-0134 still hold at the newer commit.

## Next investigation

Trace `oag_graph::service::chrono_now` and `oag_graph::corroboration::freshness_from_age`
to document which clock produces freshness and what a caller-supplied future
timestamp can and cannot change.
