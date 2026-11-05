#!/usr/bin/env python3
"""Capture/apply portable OmniWM preferences; retain local display/workspace state."""

import argparse
import hashlib
from pathlib import Path
import re
import shutil
import tomllib

# Routing arrangements, workspace identities and monitor overrides stay local.
PORTABLE = {
    "appearance", "appRules", "borders", "clipboard", "dwindle", "focus",
    "gaps", "general", "gestures", "hiddenBar", "hotkeys", "mouseWarp",
    "niri", "overview", "quakeTerminal", "scratchpads", "statusBar", "workspaceBar",
}


def config_blocks(text):
    """Split OmniWM's canonical TOML into top-level assignments and table blocks."""
    headers = list(re.finditer(r"(?m)^\[\[?([A-Za-z]\w*)[^\n]*\n", text))
    first = headers[0].start() if headers else len(text)
    assignments = list(re.finditer(r"(?m)^([A-Za-z]\w*)\s*=", text[:first]))
    blocks = []
    for index, match in enumerate(assignments):
        end = assignments[index + 1].start() if index + 1 < len(assignments) else first
        blocks.append((match[1], False, text[match.start():end]))
    for index, match in enumerate(headers):
        end = headers[index + 1].start() if index + 1 < len(headers) else len(text)
        blocks.append((match[1], True, text[match.start():end]))
    return blocks


def merge_settings(current, shared):
    local = tomllib.loads(current)
    wanted = tomllib.loads(shared)
    if local.get("schemaVersion") != wanted["schemaVersion"]:
        raise ValueError("OmniWM schema differs from the shared profile; open/update OmniWM before syncing")
    if not PORTABLE <= wanted.keys():
        raise ValueError("OmniWM profile is missing portable settings sections")
    changed = {key for key in PORTABLE if local.get(key) != wanted[key]}
    if not changed:
        return current
    local_blocks = config_blocks(current)
    incoming = [block for block in config_blocks(shared) if block[0] in changed]
    # Root assignments (including empty arrays) must precede every table.
    assignments = [b for b in local_blocks if not b[1] and b[0] not in changed]
    assignments += [b for b in incoming if not b[1]]
    tables = []
    emitted = set()
    for key, table, block in local_blocks:
        if not table:
            continue
        if key not in changed:
            tables.append(block)
        elif key not in emitted:
            tables.extend(b[2] for b in incoming if b[1] and b[0] == key)
            emitted.add(key)
    tables.extend(b[2] for b in incoming if b[1] and b[0] not in emitted)
    updated = "".join(b[2].rstrip() + "\n" for b in assignments) + "\n"
    updated += "\n\n".join(block.rstrip() for block in tables) + "\n"
    expected = dict(local, **{key: wanted[key] for key in PORTABLE})
    if tomllib.loads(updated) != expected:
        raise ValueError("Cannot safely merge this OmniWM TOML layout")
    return updated


def revision(text):
    return hashlib.sha256(text.encode()).hexdigest()


def write_atomic(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".sync-new")
    temporary.write_text(text)
    temporary.replace(path)


def capture_settings(profile, target, stamp):
    if not target.exists() or not stamp.exists():
        return False  # Enroll/apply the published profile before capturing local edits.
    shared = profile.read_text()
    if stamp.read_text().strip() != revision(shared):
        raise ValueError("Apply the pending OmniWM profile with omniwm-settings.py apply before capture")
    updated = merge_settings(shared, target.read_text())
    if tomllib.loads(updated) == tomllib.loads(shared):
        return False
    write_atomic(profile, updated)
    # This Mac already has the captured values; do not reapply over live state.
    write_atomic(stamp, revision(updated) + "\n")
    return True


def apply_settings(profile, target, stamp):
    shared = profile.read_text()
    digest = revision(shared)
    if target.exists() and stamp.exists() and stamp.read_text().strip() == digest:
        return False
    tomllib.loads(shared)
    updated = merge_settings(target.read_text(), shared) if target.exists() else shared
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        shutil.copy2(target, target.with_suffix(".toml.before-sync"))
    write_atomic(target, updated)
    write_atomic(stamp, digest + "\n")
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", nargs="?", default="apply", choices=("apply", "capture"))
    action = parser.parse_args().action
    home = Path.home()
    directory = home / ".config/omniwm"
    operation = capture_settings if action == "capture" else apply_settings
    changed = operation(
        directory / "shared-settings.toml", directory / "settings.toml",
        home / ".local/state/omniwm/shared-settings.sha256",
    )
    if changed:
        print("Captured portable OmniWM settings" if action == "capture" else "Applied shared OmniWM settings")


if __name__ == "__main__":
    main()
