# 0198 — The NTP wire codec is a narrow verified-time subset

Claim `B-0198`: at core `fb54e431332a030a566099c76fb2558084765422`,
`oag_api::ntp_wire` implements just enough NTPv4 to query one upstream server
and answer one real NTP client. Server replies echo the client's transmit
timestamp and report a caller-supplied verified time in the reference, receive,
and transmit fields; they do not report the host's raw clock.

## Order of behavior

1. Timestamps are 64-bit NTP values: 32 seconds since 1900 plus 32 fraction
   bits. Conversions clamp negative Unix milliseconds to zero and use
   big-endian bytes.
2. `build_client_request` writes a 48-byte mode-3 packet (LI 0, VN 4, Mode 3,
   first byte `0x23`) with the client's current time in the transmit field at
   byte 40. Other fields remain zero.
3. `parse_client_request` accepts packets of at least 48 bytes whose low three
   mode bits are 3 and extracts that transmit timestamp as the value to echo.
4. `build_server_response` writes a mode-4 packet (`0x24`), stratum 2, poll
   interval 4, precision `0xEC`, and reference ID `OAGG`. Reference, receive,
   and transmit timestamps all receive `verified_unix_ms`; the origin timestamp
   receives the client's value.
5. `query_upstream` binds an ephemeral UDP socket, uses the first resolved
   address, sends a mode-3 request and waits five seconds for reply, then
   rejects a packet from a different sender, a short packet, or a non-mode-4
   response.
6. It reads T2 and T3 from the reply and computes `t4 + ((T2-T1)+(T3-T4))/2`,
   the standard NTP offset estimate. The returned value is an estimate, not a
   local clock substitution.

## What is durable, rejected, and left behind

Durable: no state is stored by the codec. Rejected: undersized packets, wrong
mode, unexpected sender, DNS/socket failures, and 5-second timeouts. A failed
upstream query returns a typed `NtpUpstreamError` to the gateway resolver; it
does not fabricate time from the local clock.

The module explicitly omits extension fields, authentication, leap-second
tables, and clock-filter precision refinement. Stratum 2 and the `OAGG`
reference ID advertise derived time rather than a reference clock. The server
uses one verified estimate for receive and transmit instead of measuring the
gap between them. No UDP packet or test was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0198a | Implemented timestamp conversion and packet builders | `crates/oag-api/src/ntp_wire.rs:17-104` |
| B-0198b | Implemented upstream client | `crates/oag-api/src/ntp_wire.rs:120-161` |
| B-0198c | Implemented scope limits | `crates/oag-api/src/ntp_wire.rs:1-9` |
| B-0198d | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-api/src/ntp_wire.rs` (no output) |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No NTP client, server, or target test was executed.

## Change since the previously explained commit

The NTP wire module is unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Finding 0136 describes the gateway
resolver that supplies `verified_unix_ms`; this finding documents the wire
format and offset computation beneath it.

## Next investigation

Trace `oag_api::logging::ApiMakeSpan` and `on_response` to document which
request fields become span fields and what a `duration_ms` log line can prove.
