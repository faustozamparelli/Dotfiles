#!/usr/bin/env python3
"""Apply/capture reviewed portable settings for shared apps, never full plists."""
import getpass
import json
import plistlib
import re
import subprocess
import sys
import uuid
from pathlib import Path

HOME = Path.home()
PROFILE = Path(__file__).with_name('app-preferences.json')
APPLICATIONS = (Path('/Applications'), HOME / 'Applications')
CLAUDE_APP = 'Claude.app'
# The Claude app keeps these files in memory and rewrites them when it quits,
# so they are changed only while it is closed.
CLAUDE_SUPPORT = HOME / 'Library/Application Support/Claude'
CLAUDE_PROCESS = re.compile(r'/Claude\.app/Contents/MacOS/Claude$', re.M)


def shared_applications():
    manifest = HOME / '.config/mac-setup/apps.tsv'
    applications = set()
    for line in manifest.read_text().splitlines():
        if not line or line.startswith('#'):
            continue
        _, _, name = line.split('\t')
        applications.add((name + '.app').casefold())
    return applications


def shared_installed(application, shared):
    return application.casefold() in shared and any(
        (root / application).is_dir() for root in APPLICATIONS)


def write_json(path, value):
    updated = json.dumps(value, indent=2) + '\n'
    if path.exists() and path.read_text() == updated:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + '.dotfiles-new')
    temporary.write_text(updated)
    temporary.chmod(0o600)
    temporary.replace(path)
    return True


def machine_name():
    result = subprocess.run(['/usr/sbin/scutil', '--get', 'ComputerName'],
                            capture_output=True, text=True)
    name = result.stdout.lower()
    for label, needle in (('air', 'macbook air'), ('pro', 'macbook pro'),
                          ('studio', 'mac studio')):
        if needle in name:
            return label
    return None


def read_json(path, default):
    """Return the file's object, default when missing, or None when unreadable."""
    try:
        value = json.loads(path.read_text())
    except FileNotFoundError:
        return default
    except (OSError, ValueError):
        return None
    return value if isinstance(value, dict) else None


def claude_running():
    processes = subprocess.run(['/bin/ps', '-ax', '-o', 'comm='], capture_output=True, text=True)
    return processes.returncode != 0 or bool(CLAUDE_PROCESS.search(processes.stdout))


def sync_claude(profile, action):
    """Share reviewed Claude app preferences and SSH connections to the other Macs.

    Only the reviewed keys of claude_desktop_config.json's "preferences" are
    shared; sessions, accounts, window state and folder grants stay local.
    Missing SSH connections are added to ssh_configs.json, never removed.
    """
    settings = profile.get('claudeDesktopPreferences', {})
    config_path = CLAUDE_SUPPORT / 'claude_desktop_config.json'
    config = read_json(config_path, {})
    if config is None:
        print(f'Claude app settings skipped: {config_path} is not readable JSON')
        return
    preferences = config.get('preferences')
    preferences = preferences if isinstance(preferences, dict) else {}
    if action == 'capture':
        # While the app is open a shared value may not be applied yet; capturing
        # then would publish this Mac's stale value back to every Mac.
        if claude_running():
            return
        for setting, wanted in list(settings.items()):
            if setting in preferences and type(preferences[setting]) is type(wanted):
                settings[setting] = preferences[setting]
        return
    ssh_path = CLAUDE_SUPPORT / 'ssh_configs.json'
    ssh = read_json(ssh_path, {})
    configs, trusted = (ssh or {}).get('configs', []), (ssh or {}).get('trustedHosts', [])
    this_mac = machine_name()
    added, trust = [], []
    if ssh is not None and this_mac and isinstance(configs, list) and isinstance(trusted, list):
        known = {entry.get('sshHost') for entry in configs if isinstance(entry, dict)}
        user = getpass.getuser()
        for connection in profile.get('claudeSshConnections', []):
            if connection['mac'] == this_mac:
                continue
            host = f"{user}@{connection['mac']}"
            if host not in known:
                added.append({'name': connection['label'], 'sshHost': host, 'id': str(uuid.uuid4())})
            if host not in trusted:
                trust.append(host)
    elif profile.get('claudeSshConnections'):
        print('Claude SSH connections skipped: unknown Mac or unreadable ssh_configs.json')
    prefs_changed = any(preferences.get(key) != value for key, value in settings.items())
    if not (added or trust or prefs_changed):
        return
    if claude_running():
        print('Claude app settings deferred: quit the Claude app before the next mac-sync.')
        return
    if prefs_changed:
        preferences.update(settings)
        config['preferences'] = preferences
        write_json(config_path, config)
        print('Applied portable Claude app settings; local values retained')
    if added or trust:
        ssh.update({'configs': configs + added, 'trustedHosts': trusted + trust})
        write_json(ssh_path, ssh)
        if added:
            print(f'Added Claude SSH connections: {", ".join(entry["name"] for entry in added)}')


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else 'apply'
    if action not in {'apply', 'capture', 'list', 'enable', 'disable'}:
        raise SystemExit('usage: app-preferences.py [apply|capture|list|enable APP|disable APP]')
    profile = json.loads(PROFILE.read_text())
    shared = shared_applications()
    applications = {entry['application'] for entry in profile['preferences'].values()}
    if any(profile.get(key) for key in ('claudeDesktopPreferences', 'claudeSshConnections')):
        applications.add(CLAUDE_APP)
    disabled = set(profile.get('disabledApplications', []))
    if action == 'list':
        for application in sorted(applications):
            status = 'local app' if application.casefold() not in shared else (
                'off' if application in disabled else 'on')
            print(f'{status:9} {application}')
        return
    if action in {'enable', 'disable'}:
        if len(sys.argv) != 3:
            raise SystemExit('Pass one application name; quote names containing spaces.')
        name = sys.argv[2] if sys.argv[2].endswith('.app') else sys.argv[2] + '.app'
        application = next((app for app in applications if app.casefold() == name.casefold()), None)
        if application is None:
            raise SystemExit('No reviewed portable settings for this app; use list to see supported apps.')
        if action == 'disable':
            disabled.add(application)
        else:
            disabled.discard(application)
        profile['disabledApplications'] = sorted(disabled)
        write_json(PROFILE, profile)
        print(f'{application} settings sync is {"off" if action == "disable" else "on"}. Publish with bcp.')
        return
    shared -= {application.casefold() for application in disabled}
    for domain, entry in profile['preferences'].items():
        if not shared_installed(entry['application'], shared):
            continue
        prefs = HOME / 'Library/Preferences' / f'{domain}.plist'
        current = plistlib.loads(prefs.read_bytes()) if prefs.exists() else {}
        for key, wanted in entry['settings'].items():
            if action == 'capture':
                if key in current and type(current[key]) is type(wanted):
                    entry['settings'][key] = current[key]
                continue
            if current.get(key) == wanted:
                continue
            if type(wanted) is bool:
                args = ['-bool', 'true' if wanted else 'false']
            elif type(wanted) is int:
                args = ['-int', str(wanted)]
            elif type(wanted) is str:
                args = ['-string', wanted]
            else:
                raise ValueError(f'Unsupported preference type: {domain}/{key}')
            subprocess.run(['defaults', 'write', domain, key, *args], check=True)
            print(f'Applied {domain}: {key} = {wanted}')
    if shared_installed(CLAUDE_APP, shared):
        sync_claude(profile, action)
    if action == 'capture':
        updated = json.dumps(profile, indent=2) + '\n'
        if updated != PROFILE.read_text():
            PROFILE.write_text(updated)


if __name__ == '__main__':
    main()
