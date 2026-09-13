# health_notes database

Source of truth for the health_notes Postgres schema and PowerSync sync rules.

| Path | Purpose |
|---|---|
| `init.sql` | Full current schema (fresh DB bootstrap) |
| `migrations/` | Incremental numbered SQL migrations |
| `powersync.yaml` | PowerSync service config + sync rules |
| `bootstrap.sql` | Role setup (`health_notes` login + replication) |
| `infra.yaml` | Compose ports (PowerSync 8086, PostgREST 3009) |

## Migrations

From this app repo:

```bash
./scripts/migrate.sh migrations/001_initial.sql
./scripts/migrate.sh --full migrations/001_initial.sql
```
