#!/usr/bin/env python3
"""Insert missing Health Notes rows from a local Supabase dump into home-server Postgres."""

from __future__ import annotations

import csv
import io
import json
import os
import subprocess
import sys
from pathlib import Path

APP_ROOT = Path(__file__).resolve().parents[1]
INFRA_ROOT = APP_ROOT.parents[1] / "infra"
LOCAL_USER_ID = "local"
DEFAULT_BACKUP = (
    Path.home() / "Documents" / "health_notes_supabase_backup_2026-09-20"
)

_TABLES = {
    "health_notes": {
        "file": "health_notes.json",
        "columns": [
            "id",
            "user_id",
            "date_time",
            "symptoms_list",
            "drug_doses",
            "notes",
            "applied_tools",
            "created_at",
            "updated_at",
            "is_deleted",
        ],
        "not_null": ["date_time", "symptoms_list", "drug_doses", "notes", "applied_tools", "created_at", "updated_at"],
    },
    "check_ins": {
        "file": "check_ins.json",
        "columns": [
            "id",
            "user_id",
            "metric_name",
            "rating",
            "date_time",
            "created_at",
            "updated_at",
            "is_deleted",
        ],
        "not_null": ["metric_name", "date_time", "created_at", "updated_at"],
    },
    "check_in_metrics": {
        "file": "check_in_metrics.json",
        "columns": [
            "id",
            "user_id",
            "name",
            "type",
            "color_value",
            "icon_code_point",
            "sort_order",
            "created_at",
            "updated_at",
            "is_deleted",
        ],
        "not_null": ["name", "type", "created_at", "updated_at"],
    },
    "conditions": {
        "file": "conditions.json",
        "columns": [
            "id",
            "user_id",
            "name",
            "start_date",
            "end_date",
            "condition_status",
            "color_value",
            "icon_code_point",
            "notes",
            "created_at",
            "updated_at",
            "is_deleted",
        ],
        "not_null": ["name", "start_date", "condition_status", "notes", "created_at", "updated_at"],
    },
    "condition_entries": {
        "file": "condition_entries.json",
        "columns": [
            "id",
            "condition_id",
            "entry_date",
            "severity",
            "phase",
            "notes",
            "linked_check_in_id",
            "created_at",
            "updated_at",
            "is_deleted",
        ],
        "not_null": [
            "condition_id",
            "entry_date",
            "phase",
            "notes",
            "linked_check_in_id",
            "created_at",
            "updated_at",
        ],
    },
    "medication_schedules": {
        "file": "medication_schedules.json",
        "columns": [
            "id",
            "user_id",
            "medication_name",
            "unit",
            "start_date",
            "end_date",
            "steps",
            "notes",
            "created_at",
            "updated_at",
            "is_deleted",
        ],
        "not_null": [
            "medication_name",
            "unit",
            "start_date",
            "steps",
            "notes",
            "created_at",
            "updated_at",
        ],
    },
    "health_tool_categories": {
        "file": "health_tool_categories.json",
        "columns": [
            "id",
            "name",
            "description",
            "icon_name",
            "color_hex",
            "sort_order",
            "is_active",
            "created_at",
            "updated_at",
        ],
        "not_null": ["name", "description", "icon_name", "color_hex", "created_at", "updated_at"],
    },
    "health_tools": {
        "file": "health_tools.json",
        "columns": [
            "id",
            "name",
            "description",
            "category_id",
            "sort_order",
            "is_active",
            "created_at",
            "updated_at",
        ],
        "not_null": ["name", "description", "category_id", "created_at", "updated_at"],
    },
}


def _env_file_values(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    if not path.exists():
        return values
    for line in path.read_text().splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        values[key.strip()] = value.strip()
    return values


def _remote_host() -> str:
    host = os.environ.get("HOME_SERVER")
    if not host:
        host = _env_file_values(INFRA_ROOT / "tools" / ".env").get("HOME_SERVER")
    if not host:
        sys.exit("HOME_SERVER is not set")
    return f"ethan@{host}"


def _psql(sql: str, stdin: str | None = None) -> str:
    remote = [
        "ssh",
        "-o",
        "BatchMode=yes",
        "-i",
        str(Path.home() / ".ssh" / "id_ed25519"),
        _remote_host(),
        "cd /home/ethan/infra && docker compose --env-file .env.prod exec -T "
        "postgres psql -U health_notes -d health_notes "
        f"-c {json.dumps(sql)}",
    ]
    completed = subprocess.run(remote, input=stdin, text=True, check=False, capture_output=True)
    if completed.returncode != 0:
        sys.stderr.write(completed.stderr)
        sys.exit(completed.returncode)
    return completed.stdout


def _existing_ids(table: str) -> set[str]:
    stdout = _psql(f"COPY (SELECT id FROM {table}) TO STDOUT")
    return {line.strip() for line in stdout.splitlines() if line.strip()}


def _as_json_text(value: object) -> str:
    if value is None:
        return "[]"
    if isinstance(value, str):
        stripped = value.strip()
        if not stripped:
            return "[]"
        try:
            json.loads(stripped)
            return stripped
        except json.JSONDecodeError:
            return json.dumps(value)
    return json.dumps(value)


def _as_int(value: object, default: int = 0) -> int:
    if isinstance(value, bool):
        return 1 if value else 0
    if value is None or value == "":
        return default
    return int(value)


def _timestamp(*values: object) -> str:
    for value in values:
        if isinstance(value, str) and value.strip():
            return value
    return ""


def _map_row(table: str, row: dict) -> dict:
    created = _timestamp(row.get("created_at"), row.get("date_time"), row.get("updated_at"))
    updated = _timestamp(row.get("updated_at"), created)
    if table == "health_notes":
        return {
            "id": row["id"],
            "user_id": LOCAL_USER_ID,
            "date_time": _timestamp(row.get("date_time"), created),
            "symptoms_list": _as_json_text(row.get("symptoms_list") or row.get("symptoms")),
            "drug_doses": _as_json_text(row.get("drug_doses")),
            "notes": row.get("notes") or "",
            "applied_tools": _as_json_text(row.get("applied_tools")),
            "created_at": created,
            "updated_at": updated,
            "is_deleted": _as_int(row.get("is_deleted")),
        }
    if table == "check_ins":
        return {
            "id": row["id"],
            "user_id": LOCAL_USER_ID,
            "metric_name": row.get("metric_name") or "",
            "rating": _as_int(row.get("rating")),
            "date_time": _timestamp(row.get("date_time"), created),
            "created_at": created,
            "updated_at": updated,
            "is_deleted": _as_int(row.get("is_deleted")),
        }
    if table == "check_in_metrics":
        return {
            "id": row["id"],
            "user_id": LOCAL_USER_ID,
            "name": row.get("name") or "",
            "type": row.get("type") or "",
            "color_value": _as_int(row.get("color_value")),
            "icon_code_point": _as_int(row.get("icon_code_point")),
            "sort_order": _as_int(row.get("sort_order")),
            "created_at": created,
            "updated_at": updated,
            "is_deleted": _as_int(row.get("is_deleted")),
        }
    if table == "conditions":
        return {
            "id": row["id"],
            "user_id": LOCAL_USER_ID,
            "name": row.get("name") or "",
            "start_date": row.get("start_date") or "",
            "end_date": row.get("end_date"),
            "condition_status": row.get("condition_status") or "active",
            "color_value": _as_int(row.get("color_value"), 4293467747),
            "icon_code_point": _as_int(row.get("icon_code_point"), 62318),
            "notes": row.get("notes") or "",
            "created_at": created,
            "updated_at": updated,
            "is_deleted": _as_int(row.get("is_deleted")),
        }
    if table == "condition_entries":
        return {
            "id": row["id"],
            "condition_id": row.get("condition_id") or "",
            "entry_date": row.get("entry_date") or "",
            "severity": _as_int(row.get("severity")),
            "phase": row.get("phase") or "onset",
            "notes": row.get("notes") or "",
            "linked_check_in_id": row.get("linked_check_in_id") or "",
            "created_at": created,
            "updated_at": updated,
            "is_deleted": _as_int(row.get("is_deleted")),
        }
    if table == "medication_schedules":
        return {
            "id": row["id"],
            "user_id": LOCAL_USER_ID,
            "medication_name": row.get("medication_name") or "",
            "unit": row.get("unit") or "mg",
            "start_date": row.get("start_date") or "",
            "end_date": row.get("end_date"),
            "steps": _as_json_text(row.get("steps")),
            "notes": row.get("notes") or "",
            "created_at": created,
            "updated_at": updated,
            "is_deleted": _as_int(row.get("is_deleted")),
        }
    if table == "health_tool_categories":
        return {
            "id": row["id"],
            "name": row.get("name") or "",
            "description": row.get("description") or "",
            "icon_name": row.get("icon_name") or "",
            "color_hex": row.get("color_hex") or "#007AFF",
            "sort_order": _as_int(row.get("sort_order")),
            "is_active": _as_int(row.get("is_active"), 1),
            "created_at": created,
            "updated_at": updated,
        }
    if table == "health_tools":
        return {
            "id": row["id"],
            "name": row.get("name") or "",
            "description": row.get("description") or "",
            "category_id": row.get("category_id") or "",
            "sort_order": _as_int(row.get("sort_order")),
            "is_active": _as_int(row.get("is_active"), 1),
            "created_at": created,
            "updated_at": updated,
        }
    raise ValueError(table)


def _csv(columns: list[str], mapped_rows: list[dict]) -> str:
    buffer = io.StringIO()
    writer = csv.DictWriter(buffer, fieldnames=columns, extrasaction="ignore")
    writer.writeheader()
    for mapped in mapped_rows:
        writer.writerow({column: mapped.get(column) for column in columns})
    return buffer.getvalue()


def _copy(table: str, columns: list[str], not_null: list[str], csv_text: str) -> None:
    force = f", FORCE_NOT_NULL ({', '.join(not_null)})" if not_null else ""
    copy_sql = (
        f"COPY {table} ({', '.join(columns)}) FROM STDIN WITH "
        f"(FORMAT csv, HEADER true, NULL ''{force})"
    )
    _psql(copy_sql, stdin=csv_text)


def main() -> None:
    backup_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_BACKUP
    tables_dir = backup_dir / "tables"
    if not tables_dir.is_dir():
        sys.exit(f"backup tables not found: {tables_dir}")

    for table, spec in _TABLES.items():
        path = tables_dir / spec["file"]
        if not path.exists():
            print(f"skip {table} (no {spec['file']})")
            continue
        rows = json.loads(path.read_text())
        if not isinstance(rows, list):
            sys.exit(f"{path} is not a JSON array")
        existing = _existing_ids(table)
        missing = [row for row in rows if str(row.get("id")) not in existing]
        print(f"{table}: backup={len(rows)} postgres={len(existing)} missing={len(missing)}")
        if not missing:
            continue
        mapped = [_map_row(table, row) for row in missing]
        _copy(table, spec["columns"], spec["not_null"], _csv(spec["columns"], mapped))
        print(f"  inserted {len(missing)}")


if __name__ == "__main__":
    main()
