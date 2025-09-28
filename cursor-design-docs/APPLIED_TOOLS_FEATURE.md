## Applied Tools on Health Notes — Design & Rollout Plan

### Summary
- Add the ability to attach one or more existing user tools to a health note, each with an optional per-tool note.
- Support full offline-first behavior with seamless local schema migration and safe server sync.
- Preserve backward compatibility for existing installs, databases, and clients.

### Goals
- Allow users to select tools from their existing My Tools list when creating or editing a health note.
- Allow adding a free-text note per applied tool.
- Work fully offline; changes sync when online.
- Avoid breaking existing users; migrate local DB safely and interoperate with servers and older clients.

### Non-Goals
- Changing the existing My Tools data model.
- Advanced tool analytics or cross-note reporting.

### Data Model Changes

#### Local SQLite (offline)
- Table: `health_notes`
- Add column: `applied_tools TEXT NOT NULL DEFAULT '[]'`
- Format: JSON array of objects

Applied tool JSON schema stored in `health_notes.applied_tools`:
```json
[
  {
    "tool_id": "uuid",
    "tool_name": "string",
    "note": "string"
  }
]
```
- `tool_id` references `health_tools.id` (already in app).
- `tool_name` is stored denormally for resilience and easier rendering offline; source of truth remains `tool_id`.

Rationale: Existing `health_notes` stores `symptoms_list` and `drug_doses` as JSON in `TEXT`; this mirrors that design for consistency and a simple migration.

#### Server (Supabase Postgres)
- Table: `health_notes`
- Add column: `applied_tools JSONB NOT NULL DEFAULT '[]'`
- Same JSON shape as local.

Backward compatibility:
- Column defaults to empty array; older clients ignore it safely.
- New clients treat missing or null as `[]`.

### App Models (Freezed)
- Add `AppliedTool` Freezed model with `toolId`, `toolName`, `note` and JSON serialization.
- Update `HealthNote` Freezed model to include `List<AppliedTool> appliedTools` with default `[]`.
- Update `toJsonForUpdate` to include `applied_tools` mapping to server/local payloads.

Codegen commands:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
Or watch mode during development:
```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### DAO/Repository Updates
- `HealthNotesDao`:
  - Map `applied_tools` column to `List<AppliedTool>`.
  - Ensure default to `[]` when column is missing or null during migration window.
- `OfflineRepository`:
  - Include `appliedTools` in add/update operations.
  - When merging server data, treat missing field as `[]`.
- `SyncService`:
  - Include `applied_tools` in push payloads.
  - On pull, upsert with `applied_tools` → local column.
  - Conflict resolution remains server-wins on updates; local insertions preserved until pushed.

### Migration Strategy (Offline-First)

#### Local DB Migration
- Add column with default:
```sql
ALTER TABLE health_notes ADD COLUMN IF NOT EXISTS applied_tools TEXT NOT NULL DEFAULT '[]';
```
- Backfill existing rows implicitly via DEFAULT.
- Migration runs on app startup with the local DB migration system.
- Idempotent: guarded by `IF NOT EXISTS`.

#### Server Migration
- Run before enabling the client UI:
```sql
ALTER TABLE health_notes ADD COLUMN IF NOT EXISTS applied_tools JSONB NOT NULL DEFAULT '[]';
```
- Deployed as a forward-compatible change; safe for old clients.

Supabase CLI commands (optional, recommended for versioned rollout):
```bash
# 1) Login and link your project
supabase login
supabase link --project-ref <YOUR_PROJECT_REF>

# 2) Create a new migration
supabase migration new add_applied_tools_to_health_notes

# 3) Edit the generated SQL file (under supabase/migrations/<timestamp>_add_applied_tools_to_health_notes.sql)
#    and add:
#    ALTER TABLE public.health_notes
#      ADD COLUMN IF NOT EXISTS applied_tools JSONB NOT NULL DEFAULT '[]';

# 4) Push the migration to your project
supabase db push
```

Direct SQL (via Supabase SQL Editor):
```sql
ALTER TABLE public.health_notes
  ADD COLUMN IF NOT EXISTS applied_tools JSONB NOT NULL DEFAULT '[]';
```

#### Versioning & Compatibility
- New app versions read/write `applied_tools`.
- Old app versions continue to function; they ignore the new data.
- If a user creates/edits notes offline on the old version, then upgrades:
  - Local queued operations remain valid and unaffected by the new column.
  - After upgrade, the DB migration adds `applied_tools` with `[]` for those rows.
  - Subsequent edits can include applied tools; sync proceeds normally.

### UI/UX Updates
- Health Note Form (`lib/widgets/health_note_form_fields.dart`):
  - Add a section to select tools from My Tools (multi-select), matching existing patterns used for symptoms/medications.
  - For each selected tool, allow an optional per-tool note (inline text field).
  - Follow existing app styling conventions (unselected options white text on grey background).
- Health Note Detail (`lib/screens/health_note_detail...` if present):
  - Display applied tools and their notes.
- Do not extract trivial build methods; prefer inlining constructors.
- Prefer Dart getters and new switch expressions per code style preferences.

### Sync Semantics
- Push: send `applied_tools` array with each note create/update.
- Pull: interpret missing as `[]`.
- Conflict resolution: server-wins for updates; inserts preserved. If both sides changed the same note, the newer `updated_at` determines the winner; `applied_tools` is part of the updated record.

### Implementation Steps

1) Backend
- Add `applied_tools` JSONB column to `health_notes`.
- Update Row Level Security and validation as needed.

2) Local Database
- Add migration to create `applied_tools` TEXT column with default `[]`.
- Update `LocalDatabase` schema version and migration runner.

3) Models
- Create `AppliedTool` Freezed model with JSON serializable.
- Update `HealthNote` Freezed model to include `appliedTools` with default `[]`.
- Run codegen.

4) DAO/Repository
- Map `applied_tools` column to/from JSON.
- Include `appliedTools` in create/update operations.

5) Sync
- Include `applied_tools` in push payloads and parse on pull.
- Ensure conflict resolution uses `updated_at` as already implemented.

6) UI
- Update form fields to support selecting tools and entering per-tool notes.
- Update detail views to render applied tools.

7) Providers
- Ensure providers expose `appliedTools` and persist changes via `OfflineRepository`.

8) Tests
- Serialization tests for `AppliedTool` and `HealthNote` with `appliedTools`.
- DB migration test on a pre-change DB to ensure column added and data preserved.
- DAO round-trip tests for the new column.
- Sync tests: push and pull including `applied_tools`.
- Widget tests for form and detail rendering.

9) Feature Flag
- Gate UI surface behind a remote-config or simple local feature flag until server migration is live.

10) Documentation
- Update `OFFLINE_STORAGE_GUIDE.md` with the new column and examples.

### Test Plan
- Unit: model serialization, DAO mapping, migration idempotence.
- Integration: end-to-end offline create/edit with applied tools, then sync to server.
- Upgrade Scenarios:
  - Old version creates/edits notes offline, then upgrade and sync.
  - New version installed fresh with no prior DB.
  - Downgrade tolerance: data remains present; older app ignores the new column.
- UI: form interaction, validation, accessibility, and persistence.

### Deployment & Rollback

Deployment Order
1. Deploy server migration adding `applied_tools` JSONB with default `[]`.
2. Release client update with local DB migration and hidden UI behind a feature flag.
3. Enable the feature flag gradually.

Rollback
- Client: disable the feature flag to hide UI. Data remains stored and synced but not shown.
- Server: keep column; harmless due to default `[]`.

### Edge Cases
- Large number of applied tools: pagination not needed; ensure UI remains performant.
- Tool renamed/deleted: render using stored `tool_name` if lookup fails; still keep `tool_id` for integrity.
- Mixed-version sync: older clients ignore `applied_tools`; no conflicts arise because server defaults to `[]`.

### Acceptance Criteria
- Users can add zero or more tools to a health note, each with an optional note.
- Works offline; syncs when online.
- Existing users’ data is safe and remains accessible.
- Migrations are idempotent and backward compatible.

### Plan Updates / Implementation Log
- 2025-09-28: Confirmed using Freezed + codegen; added explicit codegen commands.
- 2025-09-28: Local DB version bumped to 4; migration adds `applied_tools TEXT NOT NULL DEFAULT '[]'` to `health_notes` with `IF NOT EXISTS` semantics.
- 2025-09-28: Implemented `AppliedTool` Freezed model and updated `HealthNote` to include `appliedTools` with default `[]`.
- 2025-09-28: Updated `HealthNotesDao` to read/write `applied_tools`, including server upsert handling and safe parsing defaults.
- 2025-09-28: Sync leverages existing flow; push uses `toJsonForUpdate()` which includes `applied_tools`; pull upserts now map `applied_tools` — no additional sync changes required.
- 2025-09-28: Dropped feature flag for POC; UI is always enabled in this build.
- Next: Update providers to accept `appliedTools` and wire UI for selection + per-tool notes. Feature flag to be added before UI is exposed.
