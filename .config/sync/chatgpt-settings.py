#!/usr/bin/env python3
"""Capture and apply portable ChatGPT/Codex desktop preferences."""

import argparse
import hashlib
import json
import os
import plistlib
import re
import subprocess
import sys
from pathlib import Path

import tomllib

HOME = Path.home()
CONFIG = HOME / ".codex/config.toml"
SNAPSHOT = HOME / ".config/sync/chatgpt-settings.json"
MARKER = HOME / ".codex/chatgpt-settings-applied.sha256"
MACOS_KEYS = ("DockIconPreference", "SUAutomaticallyUpdate", "SUEnableAutomaticChecks")

FIELDS = {
    "": ("model", "model_reasoning_effort", "approvals_reviewer"),
    "tui": ("theme", "status_line_use_colors"),
    "desktop": (
        "followUpQueueMode", "conversationDetailMode", "sansFontSize",
        "codeFontSize", "ambient-suggestions-enabled", "mac-menu-bar-enabled",
    ),
    "desktop.open-in-target-preferences": ("global",),
}
HEADER = re.compile(r"^\s*\[([^\]]+)\]\s*(?:#.*)?$")
ASSIGNMENT = re.compile(r'^\s*("(?:[^"\\]|\\.)*"|[A-Za-z0-9_-]+)\s*=')


def get_path(data, section):
    for part in section.split(".") if section else []:
        data = data.get(part, {})
    return data


def portable(data):
    result = {}
    for section, keys in FIELDS.items():
        values = get_path(data, section)
        if isinstance(values, dict):
            chosen = {key: values[key] for key in keys if key in values}
            if chosen:
                result[section] = chosen
    plugins = data.get("plugins", {})
    result["plugins"] = {
        name: entry["enabled"] for name, entry in sorted(plugins.items())
        if isinstance(entry, dict) and isinstance(entry.get("enabled"), bool)
    }
    return result


def read_config():
    with CONFIG.open("rb") as stream:
        return tomllib.load(stream)


def current_settings():
    result = portable(read_config())
    exported = subprocess.run(
        ["defaults", "export", "com.openai.codex", "-"], capture_output=True, check=False
    )
    macos = plistlib.loads(exported.stdout) if exported.returncode == 0 else {}
    result["macos"] = {key: macos[key] for key in MACOS_KEYS if key in macos}
    return result


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def atom(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (str, int, float)) and not isinstance(value, complex):
        return json.dumps(value, ensure_ascii=False)
    raise ValueError("unsupported portable setting value")


def update_section(lines, section, changes):
    header = f"[{section}]" if section else None
    start = 0 if not header else next(
        (i + 1 for i, line in enumerate(lines) if line.strip() == header), None
    )
    if start is None:
        assert header is not None
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
        line = f"{key} = {atom(value)}\n"
        if key in existing:
            lines[existing[key]] = line
        else:
            lines.insert(end, line)
            end += 1


def write_atomic(path, content, mode=0o600):
    temp = path.with_name(path.name + ".new")
    temp.write_text(content)
    os.chmod(temp, mode)
    temp.replace(path)


def capture():
    settings = current_settings()
    current_digest = digest(settings)
    previous = MARKER.read_text().strip() if MARKER.exists() else None
    shared = digest(json.loads(SNAPSHOT.read_text())) if SNAPSHOT.exists() else None
    if previous == current_digest:
        print("ChatGPT settings have no new local changes")
        return
    if previous and shared != previous and shared != current_digest:
        print("ChatGPT settings changed both locally and in dotfiles; reconcile before capturing.", file=sys.stderr)
        return 1
    write_atomic(SNAPSHOT, json.dumps(settings, indent=2, sort_keys=True) + "\n", 0o644)
    write_atomic(MARKER, current_digest + "\n")
    print(f"Captured shareable ChatGPT settings in {SNAPSHOT}")


def apply(force=False):
    if not SNAPSHOT.exists():
        return
    settings = json.loads(SNAPSHOT.read_text())
    expected_sections = set(FIELDS) | {"plugins", "macos"}
    if set(settings) != expected_sections or not all(isinstance(v, dict) for v in settings.values()):
        raise ValueError("snapshot has an unexpected shape")
    for section, values in settings.items():
        if section == "macos":
            if not set(values).issubset(MACOS_KEYS) or not all(isinstance(v, (str, bool)) for v in values.values()):
                raise ValueError("invalid macOS preferences")
        elif section == "plugins":
            if not all(isinstance(name, str) and isinstance(value, bool) for name, value in values.items()):
                raise ValueError("invalid plugin settings")
        elif not set(values).issubset(FIELDS[section]):
            raise ValueError(f"invalid settings in {section}")
    target_digest = digest(settings)
    if MARKER.exists() and MARKER.read_text().strip() == target_digest:
        return
    current = current_settings()
    if current != settings and not force and (not MARKER.exists() or MARKER.read_text().strip() != digest(current)):
        print("ChatGPT settings differ locally; run chatgpt-settings capture to keep them, or apply --force to use dotfiles.", file=sys.stderr)
        return 1
    lines = CONFIG.read_text().splitlines(keepends=True)
    for section in FIELDS:
        if settings[section]:
            update_section(lines, section, settings[section])
    for name, enabled in settings["plugins"].items():
        update_section(lines, f'plugins.{json.dumps(name)}', {"enabled": enabled})
    candidate = "".join(lines)
    tomllib.loads(candidate)
    if candidate != CONFIG.read_text():
        write_atomic(CONFIG, candidate)
    for key, value in settings["macos"].items():
        subprocess.run(
            ["defaults", "write", "com.openai.codex", key,
             "-bool" if isinstance(value, bool) else "-string",
             "true" if value is True else "false" if value is False else value],
            check=True,
        )
    write_atomic(MARKER, target_digest + "\n")
    print("Applied shareable ChatGPT settings from dotfiles")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("capture", "apply"))
    parser.add_argument("--force", action="store_true", help="overwrite differing local preferences during apply")
    args = parser.parse_args()
    if args.force and args.action != "apply":
        parser.error("--force only works with apply")
    return capture() if args.action == "capture" else apply(args.force)


if __name__ == "__main__":
    sys.exit(main())
