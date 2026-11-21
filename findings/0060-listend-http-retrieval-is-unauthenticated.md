# 0060 — Listend HTTP retrieval and publication have no authentication gate

Claim `B-060`: at listend `aad2d9b2cc763239764fa8ba11ec7e871be00e11`, the HTTP
carrier documents itself as a small HTTP/1.1 server with no TLS. Its inspected
routes do not check an authorization header. `GET /audio` lists content hashes,
`GET /audio/{hash}` returns stored bytes, and `POST /audio` passes the body to
the shared accept path.

## Retrieval behavior

`AudioStore::serve` returns the item stored under the lowercase 64-hex hash or
`NotFound`. The HTTP route validates hash shape, looks up the item, sniffs the
stored bytes for a response content type, and supports ranges and ETag
conditional requests. Knowing or discovering a hash is sufficient to retrieve
the bytes from this carrier. `GET /audio` paginates the hash list, so a caller
need not already know a hash.

`POST /audio` calls `accept_and_mirror` with the request body and content type.
Admission still requires a recognized audio signature and size limit, but the
route adds no publisher identity or permission check. The root and ping routes
are also public, with ping serving a built-in WAV.

This is the HTTP carrier's boundary. Native or other carriers may differ and
were not fully traced. No network exposure or deployment firewall is implied.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-060a | Documented intent and implemented routes | `oag-listend/src/http.rs:1-16`, `395-449`, `552-563`, and `758-767` |
| B-060b | Implemented lookup | `oag-listend/src/lib.rs:792-797` |

Verification: source inspection only. No listend server was started.

## Next investigation

Trace collisions query ranking and the minimum shared-prefix cutoff, including whether one-level indexes can return useful collisions.