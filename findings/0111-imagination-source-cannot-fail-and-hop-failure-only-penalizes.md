# 0111 — Imagination sources always return bytes; hop failure only changes a weight

Claim `B-111`: at imagination `7b7dcb8eae70b2df2fa1329fdb7b2dd928e76d29`,
`RandomSource::next` returns 32 bytes and has no error type. `HardwareRandom`
ignores its label and returns software randomness. `MixedSource` falls back to
that same software value when the real-data provider returns `None`. A source
therefore cannot abort a request by failing.

## Hop failure

`handle` appends the contribution and either answers, returns `TooManyHops`,
routes, or returns `NoRoute`. It does not change routing weights. A later
`observe_hop(Failed)` multiplies that neighbor's weight by `exp(-0.1)` and
normalizes. An unknown neighbor is ignored. The engine continues; failure is a
weight update, not a process or request abort. Whether a carrier calls
`observe_hop` after every transport error was not traced in this finding.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-111a | Implemented sources | `oag-imagination/src/source.rs:15-16` and `54-88` |
| B-111b | Implemented handling | `oag-imagination/src/engine.rs:328-337` and `518-588` |

Verification: source inspection only. No node was run.

## Next investigation

Trace `DeviceRandom` and determine whether a short or unreadable device read is distinguishable from software fallback.