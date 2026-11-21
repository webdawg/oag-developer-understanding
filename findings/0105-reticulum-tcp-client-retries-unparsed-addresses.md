# 0105 — The Reticulum TCP client stores an unparsed address and retries forever

Claim `B-105`: core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` locks `reticulum`
0.1.0. `TcpClient::new` stores the supplied string and does not parse a host or
port. Connection happens later in `spawn`. A failed `TcpStream::connect` is
logged and retried every five seconds for as long as the interface runs.

## Effect

OAG can pass `via_tcp` from `peer add-reticulum` or `uplink_tcp` configuration
without a local port check. A missing port, non-numeric port, or unreachable
host is not rejected by this constructor. The failure appears only when the
spawned task connects, and the task continues after the error. There is no
inspected maximum retry count or backoff. The exact error returned by Tokio for
each malformed form was not executed, so this finding does not assign a
specific operating-system error to each input.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-105 | Locked dependency | `reticulum-0.1.0/src/iface/tcp_client.rs:29-71` |
| B-105-caller | OAG caller | `crates/oag-reticulum/src/client.rs:81` |

Verification: source inspection only. No TCP client was spawned.

## Next investigation

Trace listend's `GET /ipfs/{cid}` route and determine whether it fetches and serves arbitrary content-addressed data without authentication.