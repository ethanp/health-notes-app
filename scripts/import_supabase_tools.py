#!/usr/bin/env python3
"""Copy health tool catalog rows from the old Supabase project into home-server Postgres.

Tools were RLS-scoped to the signed-in user, so this uses a Supabase user
session (refresh token) rather than the anon key alone.
"""

from __future__ import annotations

import csv
import io
import json
import os
import plistlib
import subprocess
import sys
import urllib.request
from pathlib import Path

APP_ROOT = Path(__file__).resolve().parents[1]
INFRA_ROOT = APP_ROOT.parents[1] / "infra"
SIMULATOR_ROOT = Path.home() / "Library/Developer/CoreSimulator/Devices"
PREFS_FILE_NAME = "na.ethanp.healthNotes.plist"


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


def _simulator_refresh_token() -> str | None:
    matches = sorted(
        SIMULATOR_ROOT.glob(
            f"*/data/Containers/Data/Application/*/Library/Preferences/{PREFS_FILE_NAME}"
        ),
        key=lambda path: path.stat().st_mtime,
        reverse=True,
    )
    for prefs_path in matches:
        plist = plistlib.loads(prefs_path.read_bytes())
        for key, raw in plist.items():
            if not (
                isinstance(key, str)
                and key.startswith("flutter.sb-")
                and key.endswith("-auth-token")
            ):
                continue
            session = json.loads(raw)
            refresh_token = session.get("refresh_token")
            if isinstance(refresh_token, str) and refresh_token:
                return refresh_token
    return None


def _access_token(supabase_url: str, anon_key: str) -> str:
    refresh_token = os.environ.get("SUPABASE_REFRESH_TOKEN") or _simulator_refresh_token()
    if not refresh_token:
        sys.exit(
            "Need SUPABASE_REFRESH_TOKEN, or a Health Notes simulator auth session"
        )
    request = urllib.request.Request(
        f"{supabase_url}/auth/v1/token?grant_type=refresh_token",
        data=json.dumps({"refresh_token": refresh_token}).encode(),
        headers={
            "apikey": anon_key,
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(request) as response:
        body = json.load(response)
    access_token = body.get("access_token")
    if not isinstance(access_token, str) or not access_token:
        sys.exit("Supabase refresh did not return an access token")
    return access_token


def _fetch_table(
    supabase_url: str, anon_key: str, access_token: str, table: str
) -> list[dict]:
    request = urllib.request.Request(
        f"{supabase_url}/rest/v1/{table}?select=*&order=sort_order.asc",
        headers={
            "apikey": anon_key,
            "Authorization": f"Bearer {access_token}",
        },
    )
    with urllib.request.urlopen(request) as response:
        rows = json.load(response)
    if not isinstance(rows, list):
        sys.exit(f"Unexpected {table} response from Supabase")
    return rows


def _as_int(value: object) -> int:
    if isinstance(value, bool):
        return 1 if value else 0
    if value is None:
        return 0
    return int(value)


def _table_csv(rows: list[dict], columns: list[str]) -> str:
    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow(columns)
    for row in rows:
        writer.writerow(
            [
                _as_int(row.get(column)) if column in {"sort_order", "is_active"}
                else (row.get(column) or "")
                for column in columns
            ]
        )
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


def _copy(table: str, columns: list[str], csv_text: str) -> None:
    not_null = [
        column
        for column in columns
        if column not in {"sort_order", "is_active"}
    ]
    copy_sql = (
        f"COPY {table} ({', '.join(columns)}) FROM STDIN WITH "
        f"(FORMAT csv, HEADER true, FORCE_NOT_NULL ({', '.join(not_null)}))"
    )
    _psql(copy_sql, stdin=csv_text)


def main() -> None:
    app_env = _env_file_values(APP_ROOT / ".env")
    supabase_url = app_env.get("URL")
    anon_key = app_env.get("ANON_KEY")
    if not supabase_url or not anon_key:
        sys.exit("health_notes/.env needs URL and ANON_KEY")

    supabase_url = supabase_url.rstrip("/")
    access_token = _access_token(supabase_url, anon_key)
    categories = _fetch_table(
        supabase_url, anon_key, access_token, "health_tool_categories"
    )
    tools = _fetch_table(supabase_url, anon_key, access_token, "health_tools")
    print(f"Fetched {len(categories)} categories and {len(tools)} tools from Supabase")
    if not categories and not tools:
        return

    _psql("TRUNCATE health_tools, health_tool_categories")
    _copy(
        "health_tool_categories",
        [
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
        _table_csv(
            categories,
            [
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
        ),
    )
    _copy(
        "health_tools",
        [
            "id",
            "name",
            "description",
            "category_id",
            "sort_order",
            "is_active",
            "created_at",
            "updated_at",
        ],
        _table_csv(
            tools,
            [
                "id",
                "name",
                "description",
                "category_id",
                "sort_order",
                "is_active",
                "created_at",
                "updated_at",
            ],
        ),
    )
    print(f"Copied {len(categories)} categories and {len(tools)} tools into Postgres")


if __name__ == "__main__":
    main()
