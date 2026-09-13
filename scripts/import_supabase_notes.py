#!/usr/bin/env python3
"""Copy health_notes rows from the old Supabase project into home-server Postgres."""

from __future__ import annotations

import csv
import io
import json
import os
import subprocess
import sys
import urllib.request
from pathlib import Path

APP_ROOT = Path(__file__).resolve().parents[1]
INFRA_ROOT = APP_ROOT.parents[1] / "infra"
LOCAL_USER_ID = "local"
PAGE_SIZE = 1000


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
        tools_env = _env_file_values(INFRA_ROOT / "tools" / ".env")
        host = tools_env.get("HOME_SERVER")
    if not host:
        sys.exit("HOME_SERVER is not set")
    return f"ethan@{host}"


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


def _fetch_notes(supabase_url: str, anon_key: str) -> list[dict]:
    notes: list[dict] = []
    offset = 0
    while True:
        request = urllib.request.Request(
            f"{supabase_url}/rest/v1/health_notes?select=*&order=created_at.asc",
            headers={
                "apikey": anon_key,
                "Authorization": f"Bearer {anon_key}",
                "Range": f"{offset}-{offset + PAGE_SIZE - 1}",
                "Prefer": "count=exact",
            },
        )
        with urllib.request.urlopen(request) as response:
            page = json.load(response)
        if not isinstance(page, list) or not page:
            break
        notes.extend(page)
        if len(page) < PAGE_SIZE:
            break
        offset += PAGE_SIZE
    return notes


def _notes_csv(notes: list[dict]) -> str:
    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow(
        [
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
        ]
    )
    for note in notes:
        created = note.get("created_at") or note.get("date_time") or ""
        writer.writerow(
            [
                note["id"],
                LOCAL_USER_ID,
                note.get("date_time") or created,
                _as_json_text(note.get("symptoms_list") or note.get("symptoms")),
                _as_json_text(note.get("drug_doses")),
                note.get("notes") or "",
                _as_json_text(note.get("applied_tools")),
                created,
                note.get("updated_at") or created,
                0,
            ]
        )
    return buffer.getvalue()


def main() -> None:
    app_env = _env_file_values(APP_ROOT / ".env")
    supabase_url = app_env.get("URL")
    anon_key = app_env.get("ANON_KEY")
    if not supabase_url or not anon_key:
        sys.exit("health_notes/.env needs URL and ANON_KEY")

    notes = _fetch_notes(supabase_url.rstrip("/"), anon_key)
    print(f"Fetched {len(notes)} notes from Supabase")
    if not notes:
        return

    csv_text = _notes_csv(notes)
    copy_sql = (
        "COPY health_notes (id, user_id, date_time, symptoms_list, drug_doses, "
        "notes, applied_tools, created_at, updated_at, is_deleted) "
        "FROM STDIN WITH (FORMAT csv, HEADER true, FORCE_NOT_NULL (notes))"
    )
    remote = [
        "ssh",
        "-o",
        "BatchMode=yes",
        "-i",
        str(Path.home() / ".ssh" / "id_ed25519"),
        _remote_host(),
        "cd /home/ethan/infra && docker compose --env-file .env.prod exec -T "
        "postgres psql -U health_notes -d health_notes "
        f"-c {json.dumps(copy_sql)}",
    ]
    completed = subprocess.run(remote, input=csv_text, text=True, check=False)
    if completed.returncode != 0:
        sys.exit(completed.returncode)
    print(f"Copied {len(notes)} notes into Postgres (user_id={LOCAL_USER_ID})")


if __name__ == "__main__":
    main()
