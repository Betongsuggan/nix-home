# postgresql

Keeps a PostgreSQL cluster usable across NixOS release upgrades. No new service: one oneshot that runs before NixOS's own `postgresql-setup` and only acts when something is wrong.

## Why

PostgreSQL sorts text with the C library's collations and records the glibc version each database was created with. Every NixOS release ships a newer glibc. After the upgrade PostgreSQL warns on every connection (`database "x" has a collation version mismatch`) and, worse, refuses `CREATE DATABASE` from the now-stale `template1`, so `services.postgresql.ensureDatabases` silently stops working and every service waiting on a new database fails. On controller this surfaced on 2026-10-18 when the `blocky` database could not be created after the 26.05 upgrade (glibc 2.40 → 2.42).

The fix is the documented one: rebuild the text indexes (`REINDEX DATABASE`, since the old sort order may have left them inconsistent) and stamp the new version (`ALTER DATABASE … REFRESH COLLATION VERSION`). Doing it by hand once is fine; doing it by hand at every release is not.

## Usage

Nothing to set: on by default wherever `services.postgresql.enable` is true.

```nix
my.postgresql.refreshCollations = false;   # opt out
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| refreshCollations | bool | `services.postgresql.enable` | Run `postgresql-collation-refresh.service` before `postgresql-setup.service` |

## Notes

- **When it acts.** Only for databases whose `pg_database.datcollversion` differs from `pg_database_collation_actual_version()`, i.e. right after a glibc change. On every other boot the catalog query returns nothing and the unit exits in milliseconds. `template0` is skipped (connections to it are not allowed, and it has no stored version).
- **Cost when it acts.** A full `REINDEX DATABASE` per affected database, once, during the first boot after the upgrade and before any dependent service is told the database is ready. Seconds for the databases on controller; minutes on a large one. The log line names each database it touches: `journalctl -u postgresql-collation-refresh`.
- **Ordering.** `postgresql-setup` wants this unit and runs after it, so `ensureDatabases` sees a healthy `template1`. It is wanted, not required: if the refresh itself failed, setup would fail on its own with the original error, which is the right signal.
- **ICU collations** are not handled; this repo uses libc collations only (nixpkgs' default `initdb`).
