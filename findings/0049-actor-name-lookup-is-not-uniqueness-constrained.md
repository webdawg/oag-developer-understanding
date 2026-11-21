# 0049 — Actor name lookup does not prove one stable actor

Claim `B-049`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, the `actors`
table has no unique constraint on `(name, actor_type)`. `find_by_name_and_type`
selects one matching row with `fetch_optional`, so duplicate matches do not
produce a deterministic, explicit selection or an error.

## Consequence

The crawler uses this lookup to reuse its actor named `crawler`. If only one
such row exists, reuse works. If two rows share that name and type, SQLite may
return either row unless an `ORDER BY` is present; this query has none. The
lookup can therefore attach later crawl assertions to an arbitrary matching
actor. That behavior was not executed, but the missing constraint and ordering
make it possible.

Actor insertion is `INSERT OR IGNORE` by primary actor ID. It does not reject
another actor ID carrying the same name and type. A key-derived actor and an
event-derived actor can consequently share a display name. Name lookup is not a
safe identity key.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-049a | Implemented schema | `crates/oag-storage/migrations/0001_init.sql:74-82` |
| B-049b | Implemented lookup and insert | `crates/oag-storage/src/repo/actors.rs:38-50` and `112-123` |

Verification: source inspection only. No duplicate-name database test was run.

## Next investigation

Trace node alias insertion and determine whether repeated aliases overwrite, duplicate, or become ambiguous in reads.