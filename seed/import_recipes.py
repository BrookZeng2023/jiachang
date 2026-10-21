#!/usr/bin/env python3
"""Idempotently seed bilingual recipes and optional photos into Mealie."""

from __future__ import annotations

import argparse
import getpass
import json
import mimetypes
import os
import urllib.parse
import urllib.request
import uuid
from pathlib import Path
from typing import Optional


class Mealie:
    def __init__(self, base: str, username: str, password: str) -> None:
        self.base = base.rstrip("/")
        form = urllib.parse.urlencode({"username": username, "password": password}).encode()
        payload = self.request("POST", "/api/auth/token", form, "application/x-www-form-urlencoded", auth=False)
        self.token = json.loads(payload)["access_token"]

    def request(self, method: str, path: str, data: Optional[bytes] = None,
                content_type: Optional[str] = None, auth: bool = True) -> bytes:
        headers = {"Accept": "application/json"}
        if content_type:
            headers["Content-Type"] = content_type
        if auth:
            headers["Authorization"] = f"Bearer {self.token}"
        request = urllib.request.Request(self.base + path, data=data, headers=headers, method=method)
        with urllib.request.urlopen(request, timeout=60) as response:
            return response.read()

    def json_request(self, method: str, path: str, body: Optional[dict] = None):
        data = json.dumps(body, ensure_ascii=False).encode() if body is not None else None
        payload = self.request(method, path, data, "application/json" if data else None)
        return json.loads(payload) if payload else None

    def recipes(self) -> list[dict]:
        return self.json_request("GET", "/api/recipes?page=1&perPage=500")["items"]

    def upsert(self, recipe: dict, existing: Optional[dict]) -> str:
        if existing:
            slug = existing["slug"]
        else:
            slug = self.json_request("POST", "/api/recipes", {"name": recipe["name"]})
        body = {
            "name": recipe["name"],
            "description": recipe["description"],
            "recipeServings": recipe["servings"],
            "totalTime": recipe["total_minutes"],
            "recipeIngredient": [{"note": value} for value in recipe["ingredients"]],
            "recipeInstructions": [{"text": value} for value in recipe["steps"]],
        }
        self.json_request("PATCH", f"/api/recipes/{slug}", body)
        return slug

    def upload(self, slug: str, image: Path) -> None:
        boundary = f"jiachang-{uuid.uuid4().hex}"
        content_type = mimetypes.guess_type(image.name)[0] or "image/jpeg"
        extension = image.suffix.lstrip(".") or "jpg"
        chunks = [
            f"--{boundary}\r\nContent-Disposition: form-data; name=\"extension\"\r\n\r\n{extension}\r\n".encode(),
            f"--{boundary}\r\nContent-Disposition: form-data; name=\"image\"; filename=\"{image.name}\"\r\nContent-Type: {content_type}\r\n\r\n".encode(),
            image.read_bytes(),
            f"\r\n--{boundary}--\r\n".encode(),
        ]
        self.request("PUT", f"/api/recipes/{slug}/image", b"".join(chunks), f"multipart/form-data; boundary={boundary}")

    def delete(self, slug: str) -> None:
        self.request("DELETE", f"/api/recipes/{slug}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--server", required=True)
    parser.add_argument("--username", required=True)
    parser.add_argument("--password", help="defaults to MEALIE_PASSWORD or a hidden prompt")
    parser.add_argument("--update", action="store_true")
    parser.add_argument("--remove-demo", action="store_true")
    parser.add_argument("--data", type=Path, default=Path(__file__).with_name("recipes.json"))
    parser.add_argument("--images", type=Path, default=Path(__file__).with_name("images"))
    args = parser.parse_args()

    password = args.password or os.environ.get("MEALIE_PASSWORD") or getpass.getpass("Mealie password: ")
    client = Mealie(args.server, args.username, password)
    source = json.loads(args.data.read_text(encoding="utf-8"))
    existing = client.recipes()
    by_name = {item["name"]: item for item in existing}

    for recipe in source:
        current = by_name.get(recipe["name"])
        if current and not args.update:
            slug = current["slug"]
            action = "kept"
        else:
            slug = client.upsert(recipe, current)
            action = "updated" if current else "created"
        image = args.images / f"{recipe['key']}.jpg"
        if image.exists():
            client.upload(slug, image)
            action += "+image"
        print(f"{action:14} {slug}")

    if args.remove_demo:
        for item in client.recipes():
            if item["slug"].startswith("ce-shi-fan-qie-chao-dan") or item["name"] == "测试-番茄炒蛋":
                client.delete(item["slug"])
                print(f"removed-demo   {item['slug']}")


if __name__ == "__main__":
    main()
