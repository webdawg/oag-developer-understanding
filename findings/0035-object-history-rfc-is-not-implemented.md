# 0035 — Mesh object history is a proposed workflow, not an API

Claim `B-035`: at mesh `9f5d89e9fcf944dc16eff61f17543e83fc6ad20c`,
`spec/07-object-history-and-ownership-rfc.md` declares itself “proposed, not
implemented.” A search of `crates/` finds no `object_history`, `ownership_epoch`,
or `ObjectId` implementation. The document defines requirements for a future
protocol; it does not create one.

## Proposed behavior

The RFC separates object identity, owner identity, storage location, encryption
keys, legal identifiers, authorship, custody, and access rights. Finding an
object ID must not unlock restricted records. A proposed exchange requires a
fresh challenge, proof of key control, current ownership or delegation evidence,
rights-holder authorization, and a short-lived audience-bound grant.

It also states limits that matter to any later implementation:

- a tag, signature, or object ID is not legal title;
- buying an object does not transfer every associated data right;
- key rotation cannot erase plaintext already disclosed;
- disputed transfers must not be settled by the last signature or a simple vote;
- audit access is bounded and cannot be self-granted;
- movement claims are signed assertions, not proof that the physical object moved.

The proposed event names are explicitly “design vocabulary, not implemented API
variants.” Wire formats, proof profiles, storage interfaces, dispute governance,
and auditor trust profiles remain open.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-035a | Documented intent | `oag-mesh/spec/07-object-history-and-ownership-rfc.md:1-4` and `43-116` |
| B-035b | Absence in searched implementation | `rg object_history|ownership_epoch|ObjectId crates/` returned no matches |

Verification: document inspection and source search only. No mesh service was run.

## Next investigation

Trace mesh transport's actual push path and determine what it persists, acknowledges, and retries. The object-history RFC must not be mistaken for that path.
