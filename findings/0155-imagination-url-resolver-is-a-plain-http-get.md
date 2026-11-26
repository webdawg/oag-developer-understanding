# 0155 — Imagination's URL resolver is a plain HTTP GET

Claim `B-0155`: at imagination `73fadb3ccdc6249fb21d0410e1b5a794be70fe40`,
`UrlResolver` answers a `Target::Url` with `reqwest::Client::new().get(url)` and
returns the response status plus the full text body. The resolver code contains
no explicit private-address check, redirect policy, timeout, content-type check,
or body cap. It is a public type wired into the example node's composite
resolver; it does not reuse the core crawler's SSRF guard.

## Order of behavior

1. `Target::infer` classifies a JSON string beginning with `http://` or
   `https://` as `Target::Url`. This is a prefix test, not URL validation. The
   source calls inference a convenience rather than validation.
2. `CompositeResolver::resolve` calls its resolvers in insertion order and
   returns the first `Some` answer. The example node adds Local, Store, Url,
   Cid, then Peer resolvers, so a URL target normally reaches `UrlResolver`.
3. `UrlResolver::resolve` returns `None` for any target other than `Url`.
   For a `Url`, it calls `get(url).send().await`; a transport error becomes
   `None`, letting the engine route onward rather than returning an error.
4. A non-success status becomes `Some({"status": code, "body": null})`. A
   success status becomes `Some({"status": code, "body": <entire response text>})`.
   The body is accumulated by `response.text().await` before it is inserted into
   the answer JSON.
5. The TCP carrier later refuses messages over `MAX_MESSAGE_BYTES` (16 MiB),
   but that is a transport frame bound, not a resolver fetch bound; the shown
   resolver does not stop a large upstream body while reading it.

## What is durable, rejected, and left behind

The resolver itself is stateless: no request, URL, response body, or outcome is
persisted by this type. Rejected here only means a non-URL target or a transport
error, both represented by `None`. HTTP error statuses are answers, not
resolver failures. A large or slow upstream response is not bounded in this
code; what happens after it is serialized into a frame is outside this finding.

Non-connection evidence: imagination's manifest depends on `oag-core`,
`oag-crypto`, `oag-storage`, `serde`, `serde_json`, `thiserror`, `hex`, `blake3`,
`tokio`, and `reqwest`, not on `oag-crawler` or `oag-api`. No call to
`resolve_and_validate` or `is_blocked_ip` appears in the imagination crate. The
crawler/gateway guard described in finding 0138 is therefore not on this path.
No HTTP request, node example, or target test was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0155a | Implemented target inference and resolver chain | `crates/oag-imagination/src/target.rs:1-55`, `99-136` |
| B-0155b | Implemented plain GET | `crates/oag-imagination/src/target.rs:138-180` |
| B-0155c | Implemented example composition | `crates/oag-imagination/examples/node.rs:38-53` |
| B-0155d | Implemented later frame bound | `crates/oag-imagination/src/socket.rs:25-34` |
| B-0155e | Confirmed non-connection | `crates/oag-imagination/Cargo.toml:7-17`; `git grep resolve_and_validate origin/master -- crates` (no imagination match) |

Verification: source inspection via `git show origin/master:<path>` at the
stated commit. No network call or target test was executed.

## Change since the previously explained commit

The imagination library is unchanged between
`7b7dcb8eae70b2df2fa1329fdb7b2dd928e76d29` and
`73fadb3ccdc6249fb21d0410e1b5a794be70fe40`; only scripts changed. Findings
0028, 0029, 0111, and 0112 therefore still describe the same library code at
the newer commit.

## Next investigation

Check the `oag-imagination-reticulum` crate at the same head for a transport
that carries these same resolver answers, and document one admission or routing
difference from the TCP socket carrier.
