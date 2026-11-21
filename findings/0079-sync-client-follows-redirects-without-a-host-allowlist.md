# 0079 — The sync client follows redirects and has no scheme allowlist

Claim `B-079`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, `SyncClient`
uses `reqwest::Client::new()` and joins the stored address directly to
`/oag/sync/v1`. OAG does not validate the scheme, host, or redirect target.
The locked `reqwest 0.13.5` default follows up to 10 redirects to whatever URL
the response supplies.

## What that means

`ClientBuilder::new` in reqwest 0.13.5 sets `redirect_policy` to
`Policy::limited(10)` and `timeout` to `None`. `Policy::limited` follows when
the prior-redirect count does not exceed the maximum; the inspected policy has
no host restriction. A synced peer can therefore return a redirect, and this
peer will request the redirected URL before parsing the hello body. The
peer-key check validates the final response body, not that the connection
remained on the original address.

OAG tests construct `http://` addresses and do not test non-HTTP schemes or
cross-host redirects. A non-HTTP string may fail inside reqwest, but that
rejection is not an OAG allowlist and was not executed. The 4 MiB response cap
still applies after a successful response begins streaming. It does not prevent
the redirected connection.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-079a | Implemented | `crates/oag-sync/src/client.rs:46-62` |
| B-079b | Locked dependency | `Cargo.lock` reqwest `0.13.5`; `ClientBuilder::new` and `Policy::limited` in that crate |

Verification: source inspection of OAG and the locked reqwest crate. No redirect experiment was run.

## Next investigation

Trace whether the sync client's stored address remains the pre-redirect address after a redirected hello, and how that affects later retries and peer identity binding.