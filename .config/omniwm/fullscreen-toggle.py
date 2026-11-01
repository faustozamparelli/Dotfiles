#!/opt/homebrew/bin/python3
"""Toggle all Niri workspaces between full-width and half-width windows."""

import fcntl
import json
from pathlib import Path
import re
import subprocess
import time
import tomllib

CTL = "/Applications/OmniWM.app/Contents/MacOS/omniwmctl"
CONFIG = Path.home() / ".config/omniwm/settings.toml"


def run(*args):
    return subprocess.check_output([CTL, *args], text=True, timeout=5)


def query(kind, *args):
    return json.loads(run("query", kind, *args, "--format", "json"))["result"]["payload"]


def focus_window(window_id):
    focused = query("windows", "--focused", "--fields", "id")["windows"]
    if focused and focused[0]["id"] == window_id:
        return
    run("window", "focus", window_id)
    for _ in range(30):
        focused = query("windows", "--focused", "--fields", "id")["windows"]
        if focused and focused[0]["id"] == window_id:
            return
        time.sleep(0.05)
    raise RuntimeError("OmniWM did not focus the target window")


def set_layout_mode():
    text = CONFIG.read_text()
    count = 2 if tomllib.loads(text)["niri"]["visibleContainerCount"] == 1 else 1
    section = re.search(r"(?ms)^\[niri\]\n.*?(?=^\[|\Z)", text)
    if section is None:
        raise RuntimeError("Missing Niri configuration")
    updated = section[0]
    for key, value in {
        "visibleContainerCount": str(count),
        "defaultContainerPrimarySpan": str(1 / count),
        "singleWindowFit": '"container_primary_span"',
    }.items():
        line = f"{key} = {value}"
        pattern = rf"(?m)^{key} = .*?$"
        updated = re.sub(pattern, line, updated) if re.search(pattern, updated) else updated + line + "\n"
    text = text[:section.start()] + updated + text[section.end():]
    tomllib.loads(text)
    temporary = CONFIG.with_suffix(".toml.tmp")
    temporary.write_text(text)
    temporary.replace(CONFIG)
    # The app watches this file and reloads it on its main event loop.
    time.sleep(0.1)


def main():
    # Serialize quick repeated presses so each observes the previous result.
    state = Path.home() / ".local/state/omniwm"
    state.mkdir(parents=True, exist_ok=True)
    with (state / "fullscreen-toggle.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        workspaces = query("workspaces")["workspaces"]
        windows = query("windows", "--fields", "id,workspace,mode,is-fullscreen,is-focused")["windows"]
        original_workspace = query("active-workspace")["workspace"]
        original_window = next((w["id"] for w in windows if w["isFocused"]), None)
        current_workspace = original_workspace["id"]
        set_layout_mode()
        try:
            for workspace in workspaces:
                if workspace["layout"] != "niri" or not workspace["counts"]["tiled"]:
                    continue
                if current_workspace != workspace["id"]:
                    run("command", "switch-workspace", str(workspace["number"]))
                    current_workspace = workspace["id"]
                workspace_windows = [w for w in windows
                                     if w["workspace"]["id"] == workspace["id"] and w["mode"] == "tiling"]
                if workspace_windows:
                    focus_window(workspace.get("focusedWindowId") or workspace_windows[0]["id"])
                # Remove any old per-window fullscreen state before sizing the layout.
                for window in workspace_windows:
                    if window["isFullscreen"]:
                        focus_window(window["id"])
                        run("command", "toggle-fullscreen")
                run("command", "balance-sizes")
        finally:
            if current_workspace != original_workspace["id"]:
                run("command", "switch-workspace", str(original_workspace["number"]))
            if original_window:
                focus_window(original_window)


if __name__ == "__main__":
    main()
