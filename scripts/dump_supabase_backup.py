#!/usr/bin/env python3
"""Dump the old hosted Supabase project (tables, auth user, storage) to a local folder."""

from __future__ import annotations

import json
import os
import plistlib
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

APP_ROOT = Path(__file__).resolve().parents[1]
SIMULATOR_ROOT = Path.home() / "Library/Developer/CoreSimulator/Devices"
PREFS_FILE_NAME = "na.ethanp.healthNotes.plist"
PAGE_SIZE = 1000
KNOWN_TABLES = [
    "health_notes",
    "health_tool_categories",
    "health_tools",
    "check_ins",
    "check_in_metrics",
    "conditions",
    "condition_entries",
    "medication_schedules",
    "profiles",
    "user_profiles",
    "sync_queue",
]


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


def _headers(anon_key: str, access_token: str | None = None) -> dict[str, str]:
    headers = {
        "apikey": anon_key,
        "Accept": "application/json",
    }
    if access_token:
        headers["Authorization"] = f"Bearer {access_token}"
    return headers


def _request_json(
    url: str,
    headers: dict[str, str],
    data: bytes | None = None,
    method: str = "GET",
) -> tuple[object, dict[str, str], int]:
    request = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request) as response:
            raw = response.read()
            payload: object = json.loads(raw) if raw else None
            return payload, dict(response.headers.items()), response.status
    except urllib.error.HTTPError as error:
        body = error.read()
        raise RuntimeError(f"{method} {url} -> {error.code}: {body[:400]!r}") from error


def _access_token(supabase_url: str, anon_key: str) -> str:
    refresh_token = os.environ.get("SUPABASE_REFRESH_TOKEN") or _simulator_refresh_token()
    if not refresh_token:
        sys.exit(
            "Need SUPABASE_REFRESH_TOKEN, or a Health Notes simulator auth session"
        )
    payload, _, _ = _request_json(
        f"{supabase_url}/auth/v1/token?grant_type=refresh_token",
        headers={**_headers(anon_key), "Content-Type": "application/json"},
        data=json.dumps({"refresh_token": refresh_token}).encode(),
        method="POST",
    )
    if not isinstance(payload, dict):
        sys.exit("Supabase refresh did not return a JSON object")
    access_token = payload.get("access_token")
    if not isinstance(access_token, str) or not access_token:
        sys.exit("Supabase refresh did not return an access token")
    return access_token


def _write_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, default=str) + "\n")


def _openapi_tables(openapi: object) -> list[str]:
    if not isinstance(openapi, dict):
        return []
    paths = openapi.get("paths")
    if not isinstance(paths, dict):
        return []
    tables: list[str] = []
    for path in paths:
        if not isinstance(path, str) or not path.startswith("/") or path.count("/") != 1:
            continue
        name = path[1:]
        if name.startswith("rpc/") or not name:
            continue
        tables.append(name)
    return sorted(set(tables))


def _fetch_table_rows(
    supabase_url: str, headers: dict[str, str], table: str
) -> list[object]:
    rows: list[object] = []
    offset = 0
    while True:
        query = urllib.parse.urlencode({"select": "*", "order": "id.asc"})
        url = f"{supabase_url}/rest/v1/{table}?{query}"
        request_headers = {
            **headers,
            "Range": f"{offset}-{offset + PAGE_SIZE - 1}",
            "Prefer": "count=exact",
        }
        try:
            payload, response_headers, _status = _request_json(url, request_headers)
        except RuntimeError as error:
            if "order" in str(error) or b"42703" in str(error).encode():
                payload, response_headers, _status = _request_json(
                    f"{supabase_url}/rest/v1/{table}?select=*",
                    {
                        **headers,
                        "Range": f"{offset}-{offset + PAGE_SIZE - 1}",
                        "Prefer": "count=exact",
                    },
                )
            else:
                raise
        if not isinstance(payload, list):
            raise RuntimeError(f"{table} did not return a JSON array")
        rows.extend(payload)
        if len(payload) < PAGE_SIZE:
            content_range = response_headers.get("Content-Range") or response_headers.get(
                "content-range"
            )
            if content_range:
                print(f"  {table}: {len(rows)} rows ({content_range})")
            else:
                print(f"  {table}: {len(rows)} rows")
            return rows
        offset += PAGE_SIZE


def _download(url: str, headers: dict[str, str], dest: Path) -> None:
    request = urllib.request.Request(url, headers=headers)
    dest.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(request) as response, dest.open("wb") as out:
        while True:
            chunk = response.read(1024 * 256)
            if not chunk:
                break
            out.write(chunk)


def _list_storage_objects(
    supabase_url: str, headers: dict[str, str], bucket: str, prefix: str = ""
) -> list[dict]:
    payload, _, _ = _request_json(
        f"{supabase_url}/storage/v1/object/list/{urllib.parse.quote(bucket)}",
        {**headers, "Content-Type": "application/json"},
        data=json.dumps(
            {
                "prefix": prefix,
                "limit": 1000,
                "offset": 0,
            }
        ).encode(),
        method="POST",
    )
    if payload is None:
        return []
    if not isinstance(payload, list):
        raise RuntimeError(f"storage list {bucket} did not return an array")
    objects: list[dict] = []
    for item in payload:
        if not isinstance(item, dict):
            continue
        name = item.get("name")
        if not isinstance(name, str) or not name:
            continue
        relative = f"{prefix}{name}" if not prefix else f"{prefix}{name}"
        metadata = item.get("metadata")
        is_folder = metadata is None and item.get("id") is None
        if is_folder:
            nested_prefix = f"{relative}/"
            objects.extend(
                _list_storage_objects(supabase_url, headers, bucket, nested_prefix)
            )
            continue
        objects.append({**item, "path": relative})
    return objects


def _default_backup_dir() -> Path:
    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    return Path.home() / "Documents" / f"health_notes_supabase_backup_{stamp}"


def main() -> None:
    app_env = _env_file_values(APP_ROOT / ".env")
    supabase_url = (app_env.get("URL") or "").rstrip("/")
    anon_key = app_env.get("ANON_KEY")
    if not supabase_url or not anon_key:
        sys.exit("health_notes/.env needs URL and ANON_KEY")

    backup_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else _default_backup_dir()
    backup_dir.mkdir(parents=True, exist_ok=True)
    tables_dir = backup_dir / "tables"
    storage_dir = backup_dir / "storage"
    tables_dir.mkdir(parents=True, exist_ok=True)

    access_token = _access_token(supabase_url, anon_key)
    headers = _headers(anon_key, access_token)

    auth_user, _, _ = _request_json(f"{supabase_url}/auth/v1/user", headers)
    _write_json(backup_dir / "auth_user.json", auth_user)

    openapi_headers = {
        **headers,
        "Accept": "application/openapi+json",
    }
    try:
        openapi, _, _ = _request_json(f"{supabase_url}/rest/v1/", openapi_headers)
        _write_json(backup_dir / "openapi.json", openapi)
        discovered = _openapi_tables(openapi)
    except Exception as error:
        print(f"OpenAPI unavailable: {error}")
        openapi = None
        discovered = []

    tables = list(dict.fromkeys([*discovered, *KNOWN_TABLES]))
    table_counts: dict[str, int | str] = {}
    for table in tables:
        try:
            rows = _fetch_table_rows(supabase_url, headers, table)
        except RuntimeError as error:
            message = str(error)
            if "404" in message:
                print(f"  {table}: missing")
                table_counts[table] = "missing"
                continue
            print(f"  {table}: error")
            _write_json(tables_dir / f"{table}.error.json", {"error": message})
            table_counts[table] = "error"
            continue
        _write_json(tables_dir / f"{table}.json", rows)
        table_counts[table] = len(rows)

    storage_manifest: dict[str, object] = {"buckets": [], "objects": {}}
    try:
        buckets, _, _ = _request_json(f"{supabase_url}/storage/v1/bucket", headers)
        _write_json(backup_dir / "storage_buckets.json", buckets)
        storage_manifest["buckets"] = buckets
        if isinstance(buckets, list):
            for bucket in buckets:
                if not isinstance(bucket, dict):
                    continue
                bucket_id = bucket.get("id") or bucket.get("name")
                if not isinstance(bucket_id, str):
                    continue
                objects = _list_storage_objects(supabase_url, headers, bucket_id)
                storage_manifest["objects"][bucket_id] = objects
                for obj in objects:
                    path = obj.get("path")
                    if not isinstance(path, str):
                        continue
                    dest = storage_dir / bucket_id / path
                    encoded = "/".join(
                        urllib.parse.quote(part) for part in path.split("/")
                    )
                    _download(
                        f"{supabase_url}/storage/v1/object/authenticated/{urllib.parse.quote(bucket_id)}/{encoded}",
                        headers,
                        dest,
                    )
                    print(f"  storage {bucket_id}/{path}")
    except Exception as error:
        print(f"Storage unavailable: {error}")
        _write_json(backup_dir / "storage.error.json", {"error": str(error)})

    _write_json(backup_dir / "storage_manifest.json", storage_manifest)

    host = urllib.parse.urlparse(supabase_url).netloc
    user_id = None
    if isinstance(auth_user, dict):
        user_id = auth_user.get("id")
    manifest = {
        "dumped_at": datetime.now(timezone.utc).isoformat(),
        "supabase_host": host,
        "user_id": user_id,
        "table_counts": table_counts,
        "backup_dir": str(backup_dir),
    }
    _write_json(backup_dir / "manifest.json", manifest)
    print(f"Wrote backup to {backup_dir}")
    print(json.dumps(table_counts, indent=2))


if __name__ == "__main__":
    main()
