#!/usr/bin/env python3
"""Command-driven Helium extension choices, exchanged through the dotfiles remote."""
import argparse
import fcntl
import importlib.util
import json
import os
from pathlib import Path
import plistlib
import re
import subprocess
import sys
import tempfile
import time
import uuid

HOME = Path.home()
ROOT = HOME / 'Library/Application Support/mac-sync/helium-extensions'
PROFILE = HOME / 'Library/Application Support/net.imput.helium/Default'
POLICY = Path('/Library/Managed Preferences/net.imput.helium.plist')
ID = re.compile(r'[a-p]{32}')
MANUAL_EXTENSIONS = {'gdlphpggholdmoloilbmcamlgbgcmngm': 'TwitchNoSub'}
SPEC = importlib.util.spec_from_file_location('app_shortcuts', Path(__file__).with_name('app-shortcuts.py'))
shared = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(shared)


def extension_id(value):
    match = re.fullmatch(r'https://chromewebstore\.google\.com/detail/(?:[^/?#]+/)?([a-p]{32})/?(?:\?[^#]*)?', value)
    identifier = match[1] if match else value
    if not ID.fullmatch(identifier):
        raise ValueError('Use a 32-letter extension ID or its chromewebstore.google.com listing URL')
    return identifier


def validate(document):
    if not isinstance(document, dict) or set(document) - {'extensions'}:
        raise ValueError('Invalid extension document')
    for identifier, event in document.get('extensions', {}).items():
        if not ID.fullmatch(identifier) or not isinstance(event, dict) or set(event) != {'value', 'version'}:
            raise ValueError('Invalid extension event')
        if identifier in MANUAL_EXTENSIONS:
            raise ValueError(f'{MANUAL_EXTENSIONS[identifier]} is a manual-install exception; use Helium directly')
        value, version = event['value'], event['version']
        if value is not None and (not isinstance(value, str) or not 1 <= len(value) <= 200
                                  or any(ord(c) < 32 for c in value)):
            raise ValueError('Invalid extension name')
        if (not isinstance(version, list) or len(version) != 2 or type(version[0]) is not int
                or version[0] < 0 or not isinstance(version[1], str) or len(version[1]) > 100):
            raise ValueError('Invalid extension revision')
    return document


class Transport(shared.Transport):
    def __init__(self, root, url):
        super().__init__(root, url, branch='helium-extensions', filename='extensions.json',
                         label='Helium extensions')

    def read(self):
        parent, document = super().read()
        return parent, validate(document)


def inventory(profile=PROFILE):
    """Read installed metadata only; component extensions, themes and PWAs stay local."""
    if not (profile / 'Secure Preferences').exists():
        raise ValueError('Helium Default profile is unavailable; open Helium once before enrolling')
    prefs = json.loads((profile / 'Secure Preferences').read_text())
    settings = prefs.get('extensions', {}).get('settings')
    if not isinstance(settings, dict):
        raise ValueError('Cannot read Helium extension inventory; refusing an empty import')
    installed, unsupported = {}, []
    for identifier, entry in settings.items():
        if not ID.fullmatch(identifier) or not isinstance(entry, dict):
            continue
        manifest = entry.get('manifest', {})
        if entry.get('location') == 4:
            unsupported.append(identifier)
        elif (entry.get('location') in (1, 6, 7, 9)
              and (entry.get('from_webstore') or entry.get('location') in (7, 9)
                   and manifest.get('update_url') == 'https://clients2.google.com/service/update2/crx')
              and manifest.get('name') and not {'theme', 'app'}.intersection(manifest)):
            name = manifest['name']
            installed[identifier] = name if len(name) <= 200 and all(ord(c) >= 32 for c in name) else identifier
    return installed, unsupported


def load_state(root):
    path = root / 'state.json'
    state = json.loads(path.read_text()) if path.exists() else {'device': str(uuid.uuid4())}
    validate(state.get('pending', {}))
    validate(state.get('shared', {}))
    return state


def record(state, identifier, value, now=None):
    revision = max(time.time_ns() if now is None else now, state.get('clock', 0) + 1)
    state.setdefault('pending', {}).setdefault('extensions', {})[identifier] = {
        'value': value, 'version': [revision, state['device']]}
    state['clock'] = revision


def enroll(state, installed):
    if state.get('enrolled'):
        return
    # Initial imports fill gaps but cannot override a previous choice/deletion.
    entries = state.setdefault('pending', {}).setdefault('extensions', {})
    for identifier, name in installed.items():
        entries.setdefault(identifier, {'value': name, 'version': [0, state['device']]})
    state['enrolled'] = True


def exchange(root, state, transport=None):
    if transport is None:
        url = subprocess.run(['git', f'--git-dir={HOME}/.config/git/dotfiles',
                              'remote', 'get-url', 'origin'], check=True, text=True,
                             capture_output=True).stdout.strip()
        transport = Transport(root, url)
    document = validate(transport.exchange(state.get('pending', {}), {}))
    state['shared'] = document
    state['clock'] = max(state.get('clock', 0), max(
        (e['version'][0] for e in document.get('extensions', {}).values()), default=0))
    state['pending'] = {}
    shared.save(root / 'state.json', state)
    return document


def merged_policy(document, current):
    result = dict(current)
    settings = dict(result.get('ExtensionSettings', {}))
    events = validate(document).get('extensions', {})
    # Bare IDs select Helium's own store/proxy URL. Explicit Chrome URLs are
    # rejected by Helium's inherited unmanaged-Mac policy filter.
    forced = [item for item in result.get('ExtensionInstallForcelist', [])
              if isinstance(item, str) and item.split(';', 1)[0] not in events]
    for identifier, event in events.items():
        entry = dict(settings.get(identifier, {}))
        entry.pop('installation_mode', None)
        entry.pop('update_url', None)
        if event['value'] is None:
            entry['installation_mode'] = 'removed'
        else:
            forced.append(identifier)
        if entry:
            settings[identifier] = entry
        else:
            settings.pop(identifier, None)
    if events:
        result['ExtensionInstallForcelist'] = sorted(forced)
    if settings:
        result['ExtensionSettings'] = settings
    else:
        result.pop('ExtensionSettings', None)
    return result


def read_policy(path=POLICY):
    if path.is_symlink():
        raise ValueError('Refusing a symlink for Helium managed preferences')
    return plistlib.loads(path.read_bytes()) if path.exists() else {}


def write_policy(document, path=POLICY):
    current = read_policy(path)
    wanted = merged_policy(document, current)
    if wanted == current:
        return False
    # A root-owned, one-time backup is separate from browser data and Git.
    backup = path.with_name(path.name + '.before-extension-sync')
    if not backup.exists():
        with backup.open('xb') as stream:
            stream.write(path.read_bytes() if path.exists() else plistlib.dumps({}))
        backup.chmod(0o600)
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as stream:
        temporary = Path(stream.name)
        try:
            stream.write(plistlib.dumps(wanted))
            stream.flush()
            os.fchmod(stream.fileno(), 0o644)
            temporary.replace(path)
        finally:
            temporary.unlink(missing_ok=True)
    return True


def apply(document):
    current = read_policy()
    if merged_policy(document, current) == current:
        return
    # No daemon or passwordless sudo: only an explicit manual sync can write policy.
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json') as stream:
        json.dump(document, stream)
        stream.flush()
        subprocess.run(['sudo', '/usr/bin/python3', '-I', str(Path(__file__).resolve()),
                        '_policy', stream.name], check=True)
    print('Helium extension policy updated; Helium applies it on policy refresh or next launch.')


def report(state, installed, unsupported):
    desired = shared.values(state.get('shared', {})).get('extensions', {})
    events = state.get('shared', {}).get('extensions', {})
    for identifier, name in sorted(desired.items()):
        print(f'{identifier}  {name}' + ('  [awaiting Helium]' if identifier not in installed else ''))
    for identifier in sorted(set(installed) & set(events) - set(desired)):
        print(f'REMOVAL PENDING {identifier}: reload Helium policies or relaunch')
    for identifier in sorted(set(installed) - set(events)):
        print(f'UNSHARED {identifier}  {installed[identifier]} (use helium-extension add ID)')
    for identifier in unsupported:
        print(f'UNPACKED {identifier}: manual installation required on each Mac')
    if state.get('pending', {}).get('extensions'):
        print('Local extension changes are pending publication; run mac sync or mac save.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['add', 'remove', 'sync', 'list', '_policy'])
    parser.add_argument('extension', nargs='?')
    parser.add_argument('--name', help='optional display name for add')
    args = parser.parse_args()
    if args.command == '_policy':
        if os.geteuid() != 0:
            raise ValueError('Policy application needs administrator authorization')
        write_policy(validate(json.loads(Path(args.extension).read_text())))
        return
    if args.command in ('add', 'remove') and args.extension is None:
        parser.error('add/remove requires an extension ID or Chrome Web Store URL')
    if args.command in ('sync', 'list') and args.extension is not None:
        parser.error('sync/list takes no extension argument')
    installed, unsupported = inventory()
    if args.command == 'list':
        report(load_state(ROOT), installed, unsupported)
        return
    ROOT.mkdir(parents=True, exist_ok=True)
    with (ROOT / 'lock').open('w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        state = load_state(ROOT)
        enroll(state, installed)
        if args.command in ('add', 'remove'):
            identifier = extension_id(args.extension)
            name = args.name or installed.get(identifier, identifier)
            record(state, identifier, name if args.command == 'add' else None)
        validate(state['pending'])
        shared.save(ROOT / 'state.json', state)  # Retain edits before any network operation.
        document = exchange(ROOT, state)
        apply(document)
        report(state, installed, unsupported)


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, TypeError, KeyError, RuntimeError, subprocess.SubprocessError) as error:
        print(f'Helium extension sync failed (local choices retained): {error}', file=sys.stderr)
        sys.exit(1)
