#!/usr/bin/env python3
"""Share Helium web-app names and URLs; report apps missing on this Mac."""
import argparse
import fcntl
import json
import plistlib
import sys
from pathlib import Path
from urllib.parse import parse_qsl, urlsplit

HOME = Path.home()
CONFIG = HOME / '.config/sync'
MANIFEST = CONFIG / 'helium-apps.json'
ROOT = HOME / 'Library/Application Support/mac-sync/helium-apps'
DOMAIN = 'net.imput.helium'


def validate(apps):
    if not isinstance(apps, list):
        raise TypeError('Helium apps must be a list')
    seen = set()
    for app in apps:
        if not isinstance(app, dict) or set(app) != {'name', 'url'}:
            raise ValueError('Each Helium app needs only name and url')
        name, url = app['name'], app['url']
        if not isinstance(name, str) or not name.strip() or any(ord(c) < 32 for c in name):
            raise ValueError('Invalid Helium app name')
        if not isinstance(url, str):
            raise TypeError('Invalid Helium app URL')
        parsed = urlsplit(url)
        if (parsed.scheme != 'https' or not parsed.hostname or parsed.username
                or parsed.password or parsed.fragment or any(c.isspace() for c in url)):
            raise ValueError(f'{name}: expected a public HTTPS launch URL without credentials or fragments')
        # Do not accidentally capture common authentication/callback URLs.
        if any(any(secret in key.lower() for secret in ('token', 'secret', 'password', 'code', 'auth'))
               for key, _ in parse_qsl(parsed.query)):
            raise ValueError(f'{name}: remove authentication parameters from the launch URL')
        if url in seen:
            raise ValueError(f'Duplicate Helium app URL: {name}')
        seen.add(url)
    return sorted(apps, key=lambda app: (app['name'].casefold(), app['url']))


def load_manifest(path=None):
    path = path if path is not None else MANIFEST
    document = json.loads(path.read_text())
    if not isinstance(document, dict) or set(document) != {'apps'}:
        raise ValueError('Expected a Helium manifest containing only apps')
    return validate(document['apps'])


def scan(directories=None):
    directories = directories if directories is not None else [
        HOME / 'Applications/Chromium Apps.localized',
        HOME / 'Applications/Chrome Apps.localized',
        HOME / 'Applications/Helium Apps.localized',
        HOME / 'Applications', Path('/Applications'),
    ]
    apps = {}
    for directory in directories:
        for bundle in sorted(directory.glob('*.app')):
            info = bundle / 'Contents/Info.plist'
            if not info.is_file():
                continue
            data = plistlib.loads(info.read_bytes())
            if data.get('CrBundleIdentifier') != DOMAIN:
                continue
            app = {'name': data['CrAppModeShortcutName'], 'url': data['CrAppModeShortcutURL']}
            validate([app])
            apps.setdefault(app['url'], app)
    return validate(list(apps.values()))


def write_if_changed(path, raw):
    if path.exists() and path.read_bytes() == raw:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + '.tmp')
    temporary.write_bytes(raw)
    temporary.replace(path)
    return True


def capture():
    # Absence on this Mac is never an instruction to delete an app elsewhere.
    apps = {app['url']: app for app in load_manifest()} if MANIFEST.exists() else {}
    apps.update({app['url']: app for app in scan()})
    document = {'apps': validate(list(apps.values()))}
    raw = (json.dumps(document, ensure_ascii=False, indent=2) + '\n').encode()
    if write_if_changed(MANIFEST, raw):
        print(f'Captured {len(apps)} shared Helium apps (review, commit and push with dotfiles).')


def report():
    installed = {app['url'] for app in scan()}
    for app in load_manifest():
        if app['url'] not in installed:
            print(f"INSTALL {app['name']} WEB APP")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['capture', 'report', 'check'])
    args = parser.parse_args()
    if args.command == 'check':
        print(f'{len(load_manifest())} shared Helium apps validated.')
    elif args.command == 'report':
        report()
    else:
        ROOT.mkdir(parents=True, exist_ok=True)
        with (ROOT / 'lock').open('w') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            capture()


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, TypeError, KeyError) as error:
        print(f'Helium app sync failed: {error}', file=sys.stderr)
        sys.exit(1)
