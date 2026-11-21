# 0095 — Reticulum hello is not bound back to the dialed address

Claim `B-095`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, the Reticulum
client waits for an announcement whose `address_hash` equals the requested
target, activates that link, and then accepts a hello whose peer ID derives
from the hello's own public key. It does not recompute the OAG-to-Reticulum
address from that hello key and compare it with the target.

## What is checked

`wait_for_announce` returns the first destination description with the target
hash. `wait_for_activation` waits for that link ID. The hello check is the same
internal consistency check used by HTTP sync. The accepted peer ID and key are
then stored, and the address recorded is `reticulum:{target}`, not a value
taken from the hello.

`local_address_hash` shows that an OAG peer identity deterministically derives
a Reticulum address. The client does not use that function on the hello key.
Whether the Reticulum library prevents a different identity from announcing the
target hash was not inspected. In this OAG function, destination-address
matching and OAG peer identity are separate checks.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-095a | Implemented | `crates/oag-reticulum/src/client.rs:78-108` and `210-228` |
| B-095b | Implemented derivation not used on hello | `crates/oag-reticulum/src/listener.rs:39-44` and `crates/oag-reticulum/src/identity.rs:19-21` |

Verification: source inspection only. No Reticulum link was opened.

## Next investigation

Compare Reticulum `discover_peers` with the HTTP discovery guard and determine whether a peer-list entry can store a peer ID that does not derive from its advertised key.