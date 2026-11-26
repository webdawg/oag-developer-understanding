# 0157 — Data Roads' central redundancy model is still unspecified

Claim `B-0157`: at data-roads `b5cd2f4e8618f955eb06dd1c4d3edc7234041a7e`,
the RFC proposes a seven-step ownership/distribution lifecycle but leaves its
most technically important mechanism — how to compute effective redundancy from
a real Custodian population — unanswered. It also explicitly says the interface
to OAG and mesh event types, payment, renewal mechanics, and security
considerations are not specified. None of this is implemented in the tracked
repository.

## Proposed lifecycle, in the RFC's order

1. **Generation:** an Actor creates data and becomes Owner by default.
2. **Ownership claim:** the claim is to be an evidence-backed OAG Assertion,
   not a bare declaration. This is documented intent; no event type or
   predicate is named.
3. **Distribution:** encrypted data is to be sent to multiple persistent and/or
   ephemeral Custodians through `oag-mesh`.
4. **Access request:** another party requests access from Owner or delegate.
5. **Agreement:** a time-bounded access agreement specifies consideration.
6. **Renewal or lapse:** access ends when active renewal lapses.
7. **Custodian compensation:** storage/relay payment runs independently of the
   access agreement.

The RFC distinguishes Owner from Custodian, defines Access Agreements as
renewable rather than permanent, and treats storage-medium choice as
unconstrained. It explicitly rejects a fixed global replication factor: one
reliable custodian and 50,000 unreliable desktops could both satisfy a
requirement depending on count, independence, and observed reliability. The
formula, inputs, measurement/corroboration path, and re-evaluation frequency
for that effective-redundancy model are all listed as open.

## What is rejected, durable, and unknown

Rejected by the proposal's own wording: permanent access grants, ownership by
custody, fixed named media, a universal replication count, and the idea that an
object ID is an access credential. Proposed but not implemented: object-linked
histories, renewable data partnerships, gated audits, retention receipts, and
the data lifecycle above. There is no executable implementation in this
repository, so nothing is durable at runtime and no failure path can be
Observed.

The RFC also states that mesh provides a push-only HTTP transport and that
durable cross-cluster storage, pull-based anti-entropy, ownership-gated
retrieval, and audit evidence exchange are **not** existing guarantees. This is
a documented non-connection, not a claim derived from reading mesh code here.
The companion paper is four lines and says it is not started.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0157a | Documented intent and principles | `rfc/0001-data-roads.md:5-66` |
| B-0157b | Documented non-connection and lifecycle | `rfc/0001-data-roads.md:211-247` |
| B-0157c | Documented open questions | `rfc/0001-data-roads.md:89-93`, `115-146`, `249-281` |
| B-0157d | Proposed object/audit requirements | `rfc/0001-data-roads.md:148-209` |
| B-0157e | Unstarted paper | `paper/data-roads.md:1-4` |

Verification: source-document inspection via `git show origin/main:<path>` at
the stated commit. No implementation, test, service, or experiment was run.

## Change since the previously explained commit

Data-roads `latest` and `explained` are the same commit
`b5cd2f4e8618f955eb06dd1c4d3edc7234041a7e`; the branch did not move in this
session. Finding 0033's file-inventory claim still holds. This finding completes
the RFC review it left open without converting proposed requirements into
current behavior.

## Next investigation

Compare `oag-mesh` `45f9fa8a16f65fc4a2e2fe5238bbbc2a5e462574` with explained
`9f5d89e9fcf944dc16eff61f17543e83fc6ad20c` and document one of the new runtime
modules rather than relying on the old bridge/corroboration findings alone.
