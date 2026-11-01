#!/usr/bin/env python3
"""Apply published OmniWM settings once per revision; retain local layout state."""

import hashlib
import json
from pathlib import Path
import re
import shutil
import tomllib


def merge_settings(current, shared):
    local = tomllib.loads(current)
    wanted = tomllib.loads(shared)
    if local.get("schemaVersion") != wanted["schemaVersion"]:
        raise ValueError("OmniWM schema differs from the shared profile; open/update OmniWM before syncing")
    sections = {
        "general": {k: wanted["general"][k] for k in
                    ("defaultLayoutType", "hotkeysEnabled", "ipcEnabled")},
        "niri": wanted["niri"],
        "workspaceBar": {k: wanted["workspaceBar"][k] for k in
                         ("enabled", "position", "showLabels", "systemStatsButton")},
    }
    for name, values in sections.items():
        pattern = rf"(?ms)^\[{name}\]\n.*?(?=^\[|\Z)"
        match = re.search(pattern, current)
        if match is None:
            raise ValueError(f"OmniWM config is missing [{name}]")
        block = match[0]
        for key, value in values.items():
            line = f"{key} = {json.dumps(value)}"
            key_pattern = rf"(?m)^{re.escape(key)}\s*=.*$"
            block = (re.sub(key_pattern, lambda _: line, block)
                     if re.search(key_pattern, block) else block + line + "\n")
        current = current[:match.start()] + block + current[match.end():]

    bindings = {hotkey["id"]: hotkey["binding"] for hotkey in wanted["hotkeys"]}

    def update_hotkey(match):
        hotkey = tomllib.loads(match[0])["hotkeys"][0]
        binding = bindings.pop(hotkey["id"], None)
        if binding is None:
            return match[0]
        return re.sub(r'(?m)^binding\s*=.*$', lambda _: "binding = " + json.dumps(binding), match[0])

    current = re.sub(r"(?ms)^\[\[hotkeys\]\]\n.*?(?=^\[|\Z)", update_hotkey, current)
    for action, binding in bindings.items():
        current += f"\n[[hotkeys]]\nbinding = {json.dumps(binding)}\nid = {json.dumps(action)}\n"
    tomllib.loads(current)
    return current


def apply_settings(profile, target, stamp):
    shared = profile.read_text()
    digest = hashlib.sha256(shared.encode()).hexdigest()
    if target.exists() and stamp.exists() and stamp.read_text().strip() == digest:
        return False
    tomllib.loads(shared)
    updated = merge_settings(target.read_text(), shared) if target.exists() else shared
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        shutil.copy2(target, target.with_suffix(".toml.before-sync"))
    temporary = target.with_suffix(".toml.sync-new")
    temporary.write_text(updated)
    temporary.replace(target)
    stamp.parent.mkdir(parents=True, exist_ok=True)
    stamp.write_text(digest + "\n")
    return True


def main():
    home = Path.home()
    directory = home / ".config/omniwm"
    changed = apply_settings(
        directory / "shared-settings.toml", directory / "settings.toml",
        home / ".local/state/omniwm/shared-settings.sha256",
    )
    if changed:
        print("Applied shared OmniWM shortcuts and Niri layout settings")


if __name__ == "__main__":
    main()
