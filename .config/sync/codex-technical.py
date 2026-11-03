#!/usr/bin/env python3
"""Sync shareable Codex plugin choices and remote MCP endpoints."""

import argparse
import copy
import json
import os
import re
import shutil
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


def machine_name():
    result = subprocess.run(["/usr/sbin/scutil", "--get", "ComputerName"],
                            capture_output=True, text=True, check=True)
    name = result.stdout.lower()
    for label, needle in (("air", "macbook air"), ("pro", "macbook pro"),
                          ("studio", "mac studio")):
        if needle in name:
            return label
    raise ValueError("unknown Mac; configure its canonical machine name first")


def effective_snapshot(snapshot):
    effective = {key: copy.deepcopy(snapshot.get(key, {}))
                 for key in ("plugins", "mcp_servers", "settings", "apps")}
    profile = snapshot.get("machines", {}).get(machine_name(), {})
    effective["plugins"].update(profile.get("plugins", {}))
    derived_apps = {}
    for plugin, app_ids in snapshot.get("plugin_apps", {}).items():
        for app_id in app_ids:
            derived_apps[app_id] = derived_apps.get(app_id, False) or effective["plugins"].get(plugin, False)
    for app_id, enabled in derived_apps.items():
        effective["apps"].setdefault(app_id, enabled)
    effective["apps"].update(profile.get("apps", {}))
    for name, settings in profile.get("mcp_servers", {}).items():
        effective["mcp_servers"].setdefault(name, {}).update(settings)
    return effective


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
    if SNAPSHOT.exists():
        previous = json.loads(SNAPSHOT.read_text())
        validate(previous)
        if "machines" in previous:
            # Local toggles belong to this Mac, never to the shared defaults.
            snapshot = copy.deepcopy(previous)
            profile = snapshot["machines"].setdefault(machine_name(), {})
            choices = profile.setdefault("plugins", {})
            for name, settings in config.get("plugins", {}).items():
                enabled = settings.get("enabled")
                if not isinstance(enabled, bool):
                    continue
                snapshot["plugins"].setdefault(name, False)
                if enabled == snapshot["plugins"][name]:
                    choices.pop(name, None)
                else:
                    choices[name] = enabled
            choices = profile.setdefault("mcp_servers", {})
            retired = snapshot.get("remove_mcp_servers", [])
            for name, settings in config.get("mcp_servers", {}).items():
                if name in retired:
                    continue
                if name not in snapshot["mcp_servers"] and name not in choices:
                    if not safe_url(settings.get("url")):
                        continue  # Local commands/arguments require deliberate review.
                    snapshot["mcp_servers"][name] = {"url": settings["url"], "enabled": False}
                enabled = settings.get("enabled", True)
                shared_enabled = snapshot["mcp_servers"].get(name, {}).get("enabled", False)
                entry = choices.setdefault(name, {})
                if name in snapshot["mcp_servers"] and enabled == shared_enabled:
                    entry.pop("enabled", None)
                else:
                    entry["enabled"] = enabled
                if not entry:
                    choices.pop(name, None)
            baseline = copy.deepcopy(snapshot)
            baseline["machines"][machine_name()].pop("apps", None)
            expected_apps = effective_snapshot(baseline)["apps"]
            choices = profile.setdefault("apps", {})
            for app_id, settings in config.get("apps", {}).items():
                enabled = settings.get("enabled")
                if app_id not in expected_apps or not isinstance(enabled, bool):
                    continue
                if enabled == expected_apps[app_id]:
                    choices.pop(app_id, None)
                else:
                    choices[app_id] = enabled
            return snapshot
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
    # A machine-local stdio override is not a request to remove the shared
    # endpoint when this Mac next publishes its other technical choices.
    if SNAPSHOT.exists():
        previous = json.loads(SNAPSHOT.read_text())
        for name, settings in previous.get("mcp_servers", {}).items():
            if config.get("mcp_servers", {}).get(name, {}).get("command"):
                servers.setdefault(name, settings)
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
    required = {"plugins", "mcp_servers"}
    if not required <= set(snapshot) or set(snapshot) - required - {"settings", "machines", "remove_mcp_servers", "apps", "plugin_apps"}:
        raise ValueError("unexpected technical snapshot fields")
    if not isinstance(snapshot["plugins"], dict) or not isinstance(snapshot["mcp_servers"], dict):
        raise ValueError("invalid technical snapshot")
    if not all(isinstance(k, str) and isinstance(v, bool)
               for k, v in snapshot["plugins"].items()):
        raise ValueError("invalid plugin choice")
    if not all(BARE_NAME.fullmatch(k) and isinstance(v, dict)
               and set(v) <= {"url", "enabled"} and safe_url(v.get("url"))
               and ("enabled" not in v or isinstance(v["enabled"], bool))
               for k, v in snapshot["mcp_servers"].items()):
        raise ValueError("invalid MCP endpoint")
    settings = snapshot.get("settings", {})
    if set(settings) - {"model_reasoning_effort"} or (
            "model_reasoning_effort" in settings and
            settings["model_reasoning_effort"] not in {"low", "medium", "high", "xhigh"}):
        raise ValueError("invalid shared Codex setting")
    retired = snapshot.get("remove_mcp_servers", [])
    if not isinstance(retired, list) or not all(isinstance(n, str) and BARE_NAME.fullmatch(n) for n in retired):
        raise ValueError("invalid retired MCP list")
    if not all(isinstance(n, str) and isinstance(v, bool) for n, v in snapshot.get("apps", {}).items()):
        raise ValueError("invalid app choices")
    for plugin, ids in snapshot.get("plugin_apps", {}).items():
        if plugin not in snapshot["plugins"] or not isinstance(ids, list) or not all(isinstance(i, str) and BARE_NAME.fullmatch(i) for i in ids):
            raise ValueError("invalid plugin app mapping")
    for machine, profile in snapshot.get("machines", {}).items():
        if machine not in {"air", "pro", "studio"} or set(profile) - {"plugins", "mcp_servers", "apps"}:
            raise ValueError("invalid machine profile")
        if not all(isinstance(n, str) and isinstance(v, bool) for n, v in profile.get("apps", {}).items()):
            raise ValueError("invalid local app choice")
        if not all(isinstance(n, str) and isinstance(v, bool) for n, v in profile.get("plugins", {}).items()):
            raise ValueError("invalid local plugin choice")
        for name, entry in profile.get("mcp_servers", {}).items():
            if not BARE_NAME.fullmatch(name) or not isinstance(entry, dict) or set(entry) - {"enabled", "url", "command", "args"}:
                raise ValueError("invalid local MCP choice")
            if "enabled" in entry and not isinstance(entry["enabled"], bool):
                raise ValueError("invalid local MCP state")
            if "url" in entry and not safe_url(entry["url"]):
                raise ValueError("invalid local MCP URL")
            if "command" in entry and (not isinstance(entry["command"], str) or not entry["command"].startswith("/")):
                raise ValueError("local MCP command must be an absolute path")
            if "args" in entry and (not isinstance(entry["args"], list) or not all(isinstance(a, str) for a in entry["args"])):
                raise ValueError("invalid local MCP arguments")
            if "url" in entry and "command" in entry:
                raise ValueError("mixed MCP transports")


def section_line(section):
    return f"[{section}]"


def update_section(lines, section, changes):
    header = section_line(section)
    start = 0 if not section else next((i + 1 for i, line in enumerate(lines)
                                       if line.strip().replace('"', '') == header.replace('"', '')), None)
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
        if value is None:
            if key in existing:
                lines[existing[key]] = ""
            continue
        new_line = f"{key} = {json.dumps(value, ensure_ascii=False)}\n"
        if key in existing:
            lines[existing[key]] = new_line
        else:
            lines.insert(end, new_line)
            end += 1


def remove_server_sections(lines, names):
    result = []
    skip = False
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("["):
            section = stripped.strip("[]").replace('"', '')
            skip = any(section == f"mcp_servers.{name}" or
                       section.startswith(f"mcp_servers.{name}.") for name in names)
        if not skip:
            result.append(line)
    return result


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
    effective = effective_snapshot(snapshot)
    original = CONFIG.read_text()
    current = tomllib.loads(original)
    lines = remove_server_sections(original.splitlines(keepends=True), snapshot.get("remove_mcp_servers", []))
    notify = current.get("notify")
    if isinstance(notify, list) and notify and "SkyComputerUseClient" in notify[0]:
        update_section(lines, "", {"notify": None})
    update_section(lines, "", effective["settings"])
    for app_id, enabled in effective["apps"].items():
        update_section(lines, f"apps.{json.dumps(app_id)}", {"enabled": enabled})
    for name, enabled in effective["plugins"].items():
        update_section(lines, f"plugins.{json.dumps(name)}", {"enabled": enabled})
    for name, settings in effective["mcp_servers"].items():
        local = current.get("mcp_servers", {}).get(name, {})
        if not local and not settings.get("url") and not settings.get("command"):
            continue  # A toggle never installs an app-specific server.
        settings = dict(settings)
        if settings.get("command") and not Path(settings["command"]).is_file():
            settings["enabled"] = False
            print(f"Disabled unavailable local MCP server: {name}")
        if (local.get("command") or local.get("type") == "stdio") and settings.get("url"):
            # Repair only the URL added by the older merge; keep local commands,
            # arguments and credentials instead of mixing MCP transports.
            if local.get("url") == settings["url"]:
                update_section(lines, f"mcp_servers.{name}", {"url": None})
            if "enabled" in settings:
                update_section(lines, f"mcp_servers.{name}", {"enabled": settings["enabled"]})
            print(f"Kept local stdio MCP server: {name}")
            continue
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
    # Retire the custom handoff skill on each Mac.
    handoff = HOME / ".codex/skills/research-handoff"
    if handoff.is_symlink():
        handoff.unlink()
    elif handoff.exists():
        shutil.rmtree(handoff)



def restore_plugins():
    apply()
    snapshot = json.loads(SNAPSHOT.read_text())
    validate(snapshot)
    installed = installed_plugins()
    failures = []
    for name, enabled in effective_snapshot(snapshot)["plugins"].items():
        if not enabled:
            continue
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
    parser.add_argument("action", choices=("capture", "apply", "restore-plugins", "set-mcp", "set-plugin"))
    parser.add_argument("name", nargs="?")
    parser.add_argument("state", nargs="?", choices=("on", "off"))
    args = parser.parse_args()
    if args.action.startswith("set-"):
        if not args.name or not args.state:
            parser.error("set-mcp/set-plugin require a name and on/off")
        snapshot = json.loads(SNAPSHOT.read_text())
        validate(snapshot)
        profile = snapshot.setdefault("machines", {}).setdefault(machine_name(), {})
        enabled = args.state == "on"
        if args.action == "set-plugin":
            if args.name not in snapshot["plugins"]:
                parser.error("unknown shared plugin")
            profile.setdefault("plugins", {})[args.name] = enabled
        else:
            if args.name not in snapshot["mcp_servers"] and args.name not in profile.get("mcp_servers", {}):
                parser.error("unknown managed MCP server")
            profile.setdefault("mcp_servers", {}).setdefault(args.name, {})["enabled"] = enabled
        validate(snapshot)
        SNAPSHOT.write_text(json.dumps(snapshot, indent=2, sort_keys=True) + "\n")
        apply()
    elif args.action == "capture":
        capture()
    elif args.action == "apply":
        apply()
    else:
        restore_plugins()


if __name__ == "__main__":
    main()
