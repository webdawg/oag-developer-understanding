# 0115 — Bridge admission checks a signature, not the caller

Claim `B-115`: at mesh `9f5d89e9fcf944dc16eff61f17543e83fc6ad20c`,
`POST /oag-mesh/v1/bridge-declaration` has no authentication header, peer
allowlist, or rate limit. `MeshTree::add` verifies that the peer ID derives
from the public key, that the signature matches the canonical declaration, and
that the timestamp is within 300 seconds of the receiver's clock. It then
inserts the declaring peer into the edge set.

## What is not checked

Verification does not decide whether the signer is allowed to speak for the
named mesh group or member. A newly generated identity can sign a declaration
and be recorded. `SelfReference` is returned by `build_and_sign` when a group
names itself, but `verify` does not repeat that check. A declaration constructed
outside that helper can therefore be admitted if it is otherwise signed and
fresh. Corroboration is a later count of distinct peer IDs, not an admission
gate. No request was sent.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-115a | Implemented route | `oag-mesh/src/transport.rs:87-96` and `109-118` |
| B-115b | Implemented checks | `oag-mesh/src/bridge.rs:29`, `90-98`, and `113-168` |

Verification: source inspection only.

## Next investigation

Trace `MeshTree` growth and determine whether distinct group or member strings from one signer are bounded.