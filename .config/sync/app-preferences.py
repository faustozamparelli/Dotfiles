#!/usr/bin/env python3
"""Apply/capture only reviewed portable performance settings, never full plists."""
import json
import plistlib
import subprocess
import sys
from pathlib import Path

HOME = Path.home()
PROFILE = Path(__file__).with_name('app-preferences.json')
PROVIDER_KEYS = {'id', 'enabled', 'codexActiveSource', 'region'}


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else 'apply'
    if action not in {'apply', 'capture'}:
        raise SystemExit('usage: app-preferences.py [apply|capture]')
    profile = json.loads(PROFILE.read_text())
    for domain, entry in profile['preferences'].items():
        if not any((root / entry['application']).is_dir()
                   for root in (Path('/Applications'), HOME / 'Applications')):
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
    if (Path('/Applications/CodexBar.app')).is_dir():
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
            updated = json.dumps(runtime, indent=2) + '\n'
            if not target.exists() or updated != target.read_text():
                target.parent.mkdir(parents=True, exist_ok=True)
                temporary = target.with_name('config.json.dotfiles-new')
                temporary.write_text(updated)
                temporary.chmod(0o600)
                temporary.replace(target)
                print('Applied portable CodexBar provider choices; local credentials retained')
    if action == 'capture':
        updated = json.dumps(profile, indent=2) + '\n'
        if updated != PROFILE.read_text():
            PROFILE.write_text(updated)


if __name__ == '__main__':
    main()
