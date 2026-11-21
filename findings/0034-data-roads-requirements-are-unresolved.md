# 0034 — Data Roads states requirements but leaves its integration unresolved

Claim `B-034`: at Data Roads `b5cd2f4e8618f955eb06dd1c4d3edc7234041a7e`, the RFC
defines owner, custodian, access agreement, and custodian compensation as
distinct concepts. It also states that the event types, redundancy model,
renewal mechanics, dispute handling, and security considerations needed to
implement those concepts are unresolved.

## Proposed requirements

- The generator is the default owner; custody does not transfer ownership.
- Data should be encrypted at rest and in transit and redundantly distributed.
- Non-owner access is a bounded, renewable agreement rather than a permanent
  grant.
- Custodian compensation is separate from what an access requester gives the
  owner.
- An object ID identifies history and is not itself an access credential or
  ownership proof.

The architecture section proposes using OAG assertions for ownership and mesh
for distribution. It explicitly says the interface is not yet specified and that
durable cross-cluster storage, ownership-gated retrieval, and audit exchange are
not existing guarantees. The security section is explicitly unwritten.

These are proposed requirements, not behaviors observed in core or mesh. No
implementation mapping should be inferred from shared terminology.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-034a | Documented intent | `rfc/0001-data-roads.md:23-68` |
| B-034b | Documented unresolved integration | `rfc/0001-data-roads.md:148-184` and `211-283` |

Verification: RFC inspection only. The companion paper and linked mesh RFC were
not reviewed.

## Next investigation

Update the destination README with current coverage and the highest-value
remaining gaps, then continue with the unresolved mesh object-history RFC only
if its repository pin can be established.
