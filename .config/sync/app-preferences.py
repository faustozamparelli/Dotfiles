#!/usr/bin/env python3
"""Apply/capture reviewed portable settings for shared apps, never full plists."""
import json
import plistlib
import subprocess
import sys
from pathlib import Path

HOME = Path.home()
PROFILE = Path(__file__).with_name('app-preferences.json')
APPLICATIONS = (Path('/Applications'), HOME / 'Applications')
PROVIDER_KEYS = {'id', 'enabled', 'codexActiveSource', 'region'}


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


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else 'apply'
    if action not in {'apply', 'capture', 'list', 'enable', 'disable'}:
        raise SystemExit('usage: app-preferences.py [apply|capture|list|enable APP|disable APP]')
    profile = json.loads(PROFILE.read_text())
    shared = shared_applications()
    applications = {entry['application'] for entry in profile['preferences'].values()}
    if profile.get('t3ClientSettings'):
        applications.add('T3 Code (Nightly).app')
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
    if shared_installed('CodexBar.app', shared):
        target = HOME / '.config/codexbar/config.json'
        legacy = HOME / '.codexbar/config.json'
        source = target if target.exists() else legacy
        runtime = json.loads(source.read_text()) if source.exists() else {'version': 1, 'providers': []}
        if action == 'capture':
            profile['codexbarProviders'] = [
                {key: value for key, value in provider.items() if key in PROVIDER_KEYS}
                for provider in runtime.get('providers', [])
            ]
        else:
            providers = {provider['id']: provider for provider in runtime.get('providers', [])}
            for provider in profile.get('codexbarProviders', []):
                if not set(provider) <= PROVIDER_KEYS:
                    raise ValueError('Unreviewed CodexBar provider fields in portable profile')
                providers.setdefault(provider['id'], {'id': provider['id']}).update(provider)
            runtime['providers'] = list(providers.values())
            if write_json(target, runtime):
                print('Applied portable CodexBar provider choices; local credentials retained')
    if shared_installed('T3 Code (Nightly).app', shared):
        target = HOME / '.t3/userdata/client-settings.json'
        runtime = json.loads(target.read_text()) if target.exists() else {}
        settings = profile.get('t3ClientSettings', {})
        if action == 'capture':
            for key, wanted in settings.items():
                if key in runtime and type(runtime[key]) is type(wanted):
                    settings[key] = runtime[key]
        elif any(runtime.get(key) != wanted for key, wanted in settings.items()):
            running = subprocess.run(
                ['pgrep', '-f', r'/T3 Code( \((Alpha|Nightly)\))?\.app/Contents/MacOS/'],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if running.returncode != 1:
                print('T3 interface settings deferred: close T3 before the next mac-sync.')
            else:
                runtime.update(settings)
                write_json(target, runtime)
                print('Applied portable T3 interface settings; local connections retained')
    if action == 'capture':
        updated = json.dumps(profile, indent=2) + '\n'
        if updated != PROFILE.read_text():
            PROFILE.write_text(updated)


if __name__ == '__main__':
    main()
