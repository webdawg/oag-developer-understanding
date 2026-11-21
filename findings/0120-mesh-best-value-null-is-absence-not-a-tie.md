# 0120 — A null best-value response means absence, not a tie

Claim `B-120`: at mesh `9f5d89e9fcf944dc16eff61f17543e83fc6ad20c`,
`GET /oag-mesh/v1/claim-report/{claim_id}/best` returns HTTP 200 with
`{"best": null}` when this node has no reports for that claim. When reports
exist, it returns one `ClaimAgreement` object: value hash, distinct cluster
count, and distinct peer count. A tie is not represented.

## What the caller cannot see

`best_corroborated_value` uses `max_by_key` and returns a single winner. Equal
cluster and peer counts do not produce a list, a tie flag, or the losing
hashes. The HTTP caller therefore cannot distinguish a unique winner from an
arbitrary tie. The response is this node's memory, not a mesh-wide query. The
handler has no authentication check. The unknown-claim test asserts `best` is
null and status 200. That test was not executed here.

The cross-checked route is different and is not this claim. Its comment says a
never-reported claim is a null `result`, while every report being dropped is a
present result with a null `best` and a drop count.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-120a | Implemented | `oag-mesh/src/transport.rs:207-214` and `610-617` |
| B-120b | Implemented selection | `oag-mesh/src/corroboration.rs:234-240` and `308-331` |

Verification: source inspection only. No HTTP request was sent.

## Next investigation

Trace `min_bridge_corroboration` and determine whether zero or a missing query value changes which cluster names survive the cross-check.