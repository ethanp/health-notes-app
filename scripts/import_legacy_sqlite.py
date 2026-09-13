#!/usr/bin/env python3
"""Copy leftover local sqlite product tables into home-server Postgres."""

from __future__ import annotations

import csv
import io
import json
import os
import sqlite3
import subprocess
import sys
from pathlib import Path

APP_ROOT = Path(__file__).resolve().parents[1]
INFRA_ROOT = APP_ROOT.parents[1] / "infra"
LOCAL_USER_ID = "local"


def _default_sqlite() -> Path:
    from_env = os.environ.get("HEALTH_NOTES_LEGACY_SQLITE")
    if from_env:
        return Path(from_env)
    simulator_root = Path.home() / "Library/Developer/CoreSimulator/Devices"
    matches = sorted(
        simulator_root.glob("*/data/Containers/Data/Application/*/Documents/health_notes.db"),
        key=lambda path: path.stat().st_mtime,
        reverse=True,
    )
    if matches:
        return matches[0]
    sys.exit(
        "Pass the legacy sqlite path, or set HEALTH_NOTES_LEGACY_SQLITE"
    )

# Postgres columns in COPY order. sqlite extras (synced_at, sync_status) are dropped.
_TABLES = {
    "user_profiles": [
        "id",
        "email",
        "full_name",
        "avatar_url",
        "updated_at",
    ],
    "conditions": [
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
    "condition_entries": [
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
    "check_in_metrics": [
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
    "check_ins": [
        "id",
        "user_id",
        "metric_name",
        "rating",
        "date_time",
        "created_at",
        "updated_at",
        "is_deleted",
    ],
    "medication_schedules": [
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
}

_NOT_NULL_TEXT = {
    "user_profiles": ["email", "full_name", "updated_at"],
    "conditions": ["name", "start_date", "condition_status", "notes", "created_at", "updated_at"],
    "condition_entries": [
        "condition_id",
        "entry_date",
        "phase",
        "notes",
        "linked_check_in_id",
        "created_at",
        "updated_at",
    ],
    "check_in_metrics": ["name", "type", "created_at", "updated_at"],
    "check_ins": ["metric_name", "date_time", "created_at", "updated_at"],
    "medication_schedules": [
        "medication_name",
        "unit",
        "start_date",
        "steps",
        "notes",
        "created_at",
        "updated_at",
    ],
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


def _cell(table: str, column: str, value: object) -> object:
    if column == "user_id" or (table == "user_profiles" and column == "id"):
        return LOCAL_USER_ID
    if value is None:
        return "" if column in _NOT_NULL_TEXT.get(table, []) else None
    if isinstance(value, (dict, list)):
        return json.dumps(value)
    return value


def _table_csv(connection: sqlite3.Connection, table: str, columns: list[str]) -> str:
    present = {
        row[1] for row in connection.execute(f"PRAGMA table_info({table})")
    }
    selected = [column for column in columns if column in present]
    if not selected:
        return ""
    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow(columns)
    query = f"SELECT {', '.join(selected)} FROM {table}"
    for row in connection.execute(query):
        by_name = dict(zip(selected, row))
        writer.writerow([_cell(table, column, by_name.get(column)) for column in columns])
    return buffer.getvalue()


def _psql(sql: str, stdin: str | None = None) -> None:
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
    completed = subprocess.run(remote, input=stdin, text=True, check=False)
    if completed.returncode != 0:
        sys.exit(completed.returncode)


def _copy(table: str, columns: list[str], csv_text: str) -> int:
    not_null = _NOT_NULL_TEXT.get(table, [])
    force = ""
    if not_null:
        force = f", FORCE_NOT_NULL ({', '.join(not_null)})"
    copy_sql = (
        f"COPY {table} ({', '.join(columns)}) FROM STDIN WITH "
        f"(FORMAT csv, HEADER true{force})"
    )
    _psql(copy_sql, stdin=csv_text)
    return csv_text.count("\n") - 1


def main() -> None:
    sqlite_path = Path(sys.argv[1]) if len(sys.argv) > 1 else _default_sqlite()
    if not sqlite_path.exists():
        sys.exit(f"sqlite file not found: {sqlite_path}")

    connection = sqlite3.connect(sqlite_path)
    try:
        _psql(
            "TRUNCATE condition_entries, conditions, check_in_metrics, "
            "check_ins, medication_schedules, user_profiles"
        )
        for table, columns in _TABLES.items():
            names = {
                row[0]
                for row in connection.execute(
                    "SELECT name FROM sqlite_master WHERE type='table'"
                )
            }
            if table not in names:
                print(f"skip {table} (not in sqlite)")
                continue
            csv_text = _table_csv(connection, table, columns)
            count = _copy(table, columns, csv_text)
            print(f"copied {count} {table} rows")
    finally:
        connection.close()


if __name__ == "__main__":
    main()
