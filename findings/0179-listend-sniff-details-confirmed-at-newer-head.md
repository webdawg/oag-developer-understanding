# 0179 — Listend's closed audio-signature sniff is unchanged

Claim `B-0179`: at listend `b87dcac9a3c9e0059d90e698e2ec40fb2769ec41`,
`AudioFormat::sniff` still recognizes only a closed set of leading signatures.
It does not decode audio, and a matching signature is not proof of playable
content. Finding 0030's claim at `aad2d9b2...` still holds; this finding fills
in the raw MPEG and ISO-BMFF branches that finding left unexamined.

## Order of behavior

1. WAV requires at least 12 bytes with `RIFF` at offset 0 and `WAVE` at offset
   8. AIFF requires `FORM` plus `AIFF` or `AIFC` at those offsets. FLAC only
   requires the `fLaC` prefix.
2. An `OggS` prefix goes to `sniff_ogg_codec`, which requires byte 5 to mark a
   beginning-of-stream page, reads `segments` from byte 26, sets payload to
   `27 + segments`, and accepts only codec prefixes `\x01vorbis`, `OpusHead`,
   `\x7fFLAC`, `Speex   `, and `PCM     `. Theora is rejected. The test helper
   constructs one segment with one lacing byte, so the inspected code skips one
   byte to reach the codec; a multi-segment page whose lacing values sum to more
   than the segment count would not be read from its true payload start
   (Inferred from the helper and the arithmetic).
3. `ID3` is accepted as MP3. A raw MPEG frame additionally needs `0xFF`, the
   top three bits of the next byte set, a non-reserved version, a non-zero
   layer, and a bitrate field that is neither zero nor the reserved value.
4. ISO BMFF requires `ftyp` at bytes 4..8. Size `0` scans to the end of the
   supplied bytes; size `1` with at least 24 bytes reads a 64-bit largesize and
   starts brands at bytes 16/24; otherwise brands start at 8/16 and the scan
   ends at `size.min(bytes.len())`. The major brand and every compatible brand
   are checked for `M4A `, `M4B `, or `M4P `.
5. `media_type()` derives the served type from the recognized format, not from
   a publisher's declared media type. `accept` still calls `sniff` before any
   storage, so a non-match becomes `NotAudio` (finding 0152).

## What is durable, rejected, and left behind

Nothing is stored by the sniff itself: it returns an enum or `None` from the
supplied bytes. Rejection leaves no audio row, and the error deliberately
carries no rejected content. Acceptance means only "the leading bytes matched a
closed signature"; it does not mean the file decodes, is safe, or is what a
declared type claimed.

Neither the hash identity check nor any sniff branch changed between
`aad2d9b2...` and `b87dcac9...`. The accept path around it did change with dual
byte bounds and storage timeouts, recorded in finding 0152. No fixture, codec
decoder, or target test was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0179a | Implemented sniff branches | `crates/oag-listend/src/lib.rs:155-285` |
| B-0179b | Implemented derived media type | `crates/oag-listend/src/lib.rs:287-300` |
| B-0179c | Implemented accept call site | `crates/oag-listend/src/lib.rs:626-662` |
| B-0179d | Test inspection, not executed | `crates/oag-listend/src/lib.rs:1275-1319`, `1525-1539` |
| B-0179e | Unchanged sniff code | `diff <(git show aad2d9b2:...lib.rs | sed -n '115,280p') <(git show origin/master:...lib.rs | sed -n '155,320p')` (no output) |

Verification: source and test inspection via `git show origin/master:<path>` and
the scoped comparison above. No audio fixture or target test was executed.

## Change since the previously explained commit

Finding 0030 described the same identity-versus-signature distinction at
`aad2d9b2...` and explicitly left the later raw-frame checks unexamined. The
sniff block is byte-for-byte unchanged at `b87dcac9...`; this finding is a
confirmation plus the missing branch detail, not a rewrite of 0030.

## Next investigation

Trace `oag_listend::wav::generate_n`, `sounds`, and `twinkle` at the same head
to document what generated startup audio is bounded and what its stable hash
means.
