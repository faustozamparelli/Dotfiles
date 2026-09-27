#!/usr/bin/env python3
"""Sync shareable Codex plugin choices and remote MCP endpoints."""

import argparse
import json
import os
import re
import subprocess
import tomllib
from pathlib import Path
from urllib.parse import urlsplit

HOME = Path.home()
CONFIG = HOME / ".codex/config.toml"
SNAPSHOT = HOME / ".config/sync/codex-technical.json"
OLD_PREFERENCE_MARKER = HOME / ".codex/chatgpt-settings-applied.sha256"
ASSIGNMENT = re.compile(r'^\s*("(?:[^"\\]|\\.)*"|[A-Za-z0-9_-]+)\s*=')
BARE_NAME = re.compile(r'^[A-Za-z0-9_-]+$')


def safe_url(value):
    if not isinstance(value, str):
        return False
    parts = urlsplit(value)
    return (parts.scheme == "https" and bool(parts.hostname)
            and not parts.username and not parts.password
            and not parts.query and not parts.fragment)


def snapshot_from_config():
    with CONFIG.open("rb") as stream:
        config = tomllib.load(stream)
    # The CLI inventory can omit remote integrations even when their enabled
    # choices remain in config.toml. Preserve those explicit choices too.
    plugins = {
        name: settings["enabled"]
        for name, settings in config.get("plugins", {}).items()
        if isinstance(settings, dict) and isinstance(settings.get("enabled"), bool)
    }
    plugins.update(installed_plugins())
    plugins = dict(sorted(plugins.items()))
    servers = {
        name: {"url": settings["url"]}
        for name, settings in sorted(config.get("mcp_servers", {}).items())
        if isinstance(settings, dict) and safe_url(settings.get("url"))
    }
    return {"plugins": plugins, "mcp_servers": servers}


def installed_plugins():
    result = subprocess.run(
        ["codex", "plugin", "list", "--json"],
        capture_output=True, text=True, check=True, timeout=30,
    )
    inventory = json.loads(result.stdout)
    installed = inventory.get("installed", [])
    if not isinstance(installed, list):
        raise ValueError("invalid Codex plugin inventory")
    plugins = {}
    for entry in installed:
        name, enabled = entry.get("pluginId"), entry.get("enabled")
        if not isinstance(name, str) or not isinstance(enabled, bool) or name in plugins:
            raise ValueError("invalid Codex plugin entry")
        plugins[name] = enabled
    return dict(sorted(plugins.items()))


def validate(snapshot):
    if set(snapshot) != {"plugins", "mcp_servers"}:
        raise ValueError("unexpected technical snapshot fields")
    if not isinstance(snapshot["plugins"], dict) or not isinstance(snapshot["mcp_servers"], dict):
        raise ValueError("invalid technical snapshot")
    if not all(isinstance(k, str) and isinstance(v, bool)
               for k, v in snapshot["plugins"].items()):
        raise ValueError("invalid plugin choice")
    if not all(BARE_NAME.fullmatch(k) and isinstance(v, dict)
               and set(v) == {"url"} and safe_url(v["url"])
               for k, v in snapshot["mcp_servers"].items()):
        raise ValueError("invalid MCP endpoint")


def section_line(section):
    return f"[{section}]"


def update_section(lines, section, changes):
    header = section_line(section)
    start = next((i + 1 for i, line in enumerate(lines) if line.strip() == header), None)
    if start is None:
        if lines and lines[-1].strip():
            lines.append("\n")
        lines.append(header + "\n")
        start = len(lines)
    end = next((i for i in range(start, len(lines)) if lines[i].lstrip().startswith("[")), len(lines))
    existing = {}
    for i in range(start, end):
        match = ASSIGNMENT.match(lines[i])
        if match:
            key = match.group(1).strip('"')
            if key in changes:
                existing[key] = i
    for key, value in changes.items():
        new_line = f"{key} = {json.dumps(value, ensure_ascii=False)}\n"
        if key in existing:
            lines[existing[key]] = new_line
        else:
            lines.insert(end, new_line)
            end += 1


def capture():
    snapshot = snapshot_from_config()
    validate(snapshot)
    content = json.dumps(snapshot, indent=2, sort_keys=True) + "\n"
    if SNAPSHOT.exists() and SNAPSHOT.read_text() == content:
        print("Codex technical setup has no new local changes")
        return
    SNAPSHOT.parent.mkdir(parents=True, exist_ok=True)
    temporary = SNAPSHOT.with_name(SNAPSHOT.name + ".new")
    temporary.write_text(content)
    os.chmod(temporary, 0o644)
    temporary.replace(SNAPSHOT)
    print(f"Captured Codex technical setup in {SNAPSHOT}")


def apply():
    if not SNAPSHOT.exists():
        return
    snapshot = json.loads(SNAPSHOT.read_text())
    validate(snapshot)
    lines = CONFIG.read_text().splitlines(keepends=True)
    for name, enabled in snapshot["plugins"].items():
        update_section(lines, f"plugins.{json.dumps(name)}", {"enabled": enabled})
    for name, settings in snapshot["mcp_servers"].items():
        update_section(lines, f"mcp_servers.{name}", settings)
    candidate = "".join(lines)
    tomllib.loads(candidate)
    if candidate != CONFIG.read_text():
        temporary = CONFIG.with_name(CONFIG.name + ".new")
        temporary.write_text(candidate)
        os.chmod(temporary, 0o600)
        temporary.replace(CONFIG)
        print("Applied Codex plugin choices and remote MCP endpoints")
    OLD_PREFERENCE_MARKER.unlink(missing_ok=True)


def restore_plugins():
    apply()
    snapshot = json.loads(SNAPSHOT.read_text())
    validate(snapshot)
    installed = installed_plugins()
    failures = []
    for name in snapshot["plugins"]:
        if name in installed:
            continue
        try:
            subprocess.run(
                ["codex", "plugin", "add", "--json", name],
                capture_output=True, text=True, check=True, timeout=180,
            )
            print(f"Installed {name}")
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as error:
            failures.append(name)
            print(f"Could not install {name}: {type(error).__name__}")
    apply()
    if failures:
        raise SystemExit(f"Plugin setup needs attention: {', '.join(failures)}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("capture", "apply", "restore-plugins"))
    args = parser.parse_args()
    if args.action == "capture":
        capture()
    elif args.action == "apply":
        apply()
    else:
        restore_plugins()


if __name__ == "__main__":
    main()
