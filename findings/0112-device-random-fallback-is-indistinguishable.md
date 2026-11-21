# 0112 — Device randomness fallback is not distinguishable from a device read

Claim `B-112`: at imagination `7b7dcb8eae70b2df2fa1329fdb7b2dd928e76d29`,
`DeviceRandom` defaults to `/dev/hwrng`. `next` opens the path and returns the
device bytes only when `read_exact` fills 32 bytes. A missing file, open error,
or short read falls through to `oag_crypto::random_bytes_32`.

## Contradiction

The comment says the fallback is documented rather than silent. The function
returns the same `[u8; 32]` in both cases and contains no log, error, or flag.
A caller cannot tell whether the contribution came from the device. A short
read is not returned partially; `read_exact` failure discards it and uses
software randomness. No device was opened.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-112 | Implemented and documented intent | `oag-imagination/src/source.rs:90-126` |

Verification: source inspection only.

## Next investigation

Trace mesh transport delivery and determine whether a dropped in-memory message is observable to the sender.