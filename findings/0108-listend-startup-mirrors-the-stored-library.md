# 0108 — Enabling the IPFS flag offers the stored library at startup

Claim `B-108`: at listend `aad2d9b2cc763239764fa8ba11ec7e871be00e11`, starting
with `--ipfs-api` calls `mirror_existing` with a 30-second budget before the
daemon continues. The pass walks every stored item. Items that already have a
recorded CID are skipped. Others are offered to the configured node without a
separate per-item confirmation.

## Failure behavior

A successful add records the CID and persists it when a store directory exists.
A failed add records an in-memory failure reason and the loop continues. A
timeout or exhausted budget stops the pass and leaves remaining items for a
later change. Neither failure nor timeout makes startup return an error in the
inspected caller. The printed count is the number of offers attempted, not the
number that succeeded. The daemon then keeps running with the publisher
configured, so later accepted audio can also be offered.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-108a | Implemented | `oag-listend/src/lib.rs:394` and `701-723` |
| B-108b | Implemented offer result | `oag-listend/src/lib.rs:655-679` |
| B-108c | Implemented caller | `oag-listend/src/main.rs:276-288` |

Verification: source inspection only. No daemon was started.

## Next investigation

Trace `persist_cid` and determine whether a failed mirror is durable or only visible until process exit.