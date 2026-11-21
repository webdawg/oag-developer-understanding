# 0030 — Listend identity proves bytes, while sniffing only recognizes signatures

Claim `B-030`: at listend `aad2d9b2cc763239764fa8ba11ec7e871be00e11`,
`AudioItem::verify` recomputes BLAKE3 over the supplied bytes and compares the
hex digest. `AudioFormat::sniff` separately recognizes a closed set of leading
signatures. Neither operation decodes audio or proves that it is safe,
meaningful, or authorized.

## Two different checks

The hash check proves exact byte identity and nothing about format. Any byte
string has a hash. The sniff check accepts selected WAV, AIFF, FLAC, Ogg, MP3,
and M4A signatures. Its own comment says it checks magic bytes only and is not a
decoder.

The Ogg branch is narrower than a container prefix: it requires a
beginning-of-stream page and one of the recognized audio codec headers. An Ogg
container with another codec returns `None`. The MP3 branch accepts an `ID3`
prefix, so a recognized tag is not proof of a playable frame. The later raw-frame
checks were not fully included in this finding.

The error type explicitly says rejected content must not be echoed. That is an
implemented API choice, not a claim about every log or carrier outside this
function.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-030a | Implemented | `oag-listend/crates/oag-listend/src/lib.rs:50-74` |
| B-030b | Implemented and documented intent | `oag-listend/crates/oag-listend/src/lib.rs:121-190` |

Verification: source inspection only. Audio fixtures and tests were not run.

## Next investigation

Trace `AudioStore::accept` ordering: signature check, size limit, persistence,
duplicate restoration, and eviction.
