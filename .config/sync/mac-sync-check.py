#!/usr/bin/python3
"""Inspect local manifests; never pull Git, install software, or delete app data."""
import json
import os
from pathlib import Path
import re
import subprocess
import sys


def inspect(home, prefix, host, applications=Path('/Applications')):
    setup = home / '.config/mac-setup'
    skip = setup / 'machines' / (host + '.skip')
    skipped = set(skip.read_text().splitlines()) if skip.exists() else set()
    findings = []
    for name in (setup / 'apps.tsv', setup / 'machines' / (host + '.tsv')):
        if not name.exists():
            if name.name == 'apps.tsv':
                raise ValueError('Shared application manifest is missing')
            continue
        for row in name.read_text().splitlines():
            if not row.strip() or row.startswith('#'):
                continue
            parts = row.split('\t')
            if len(parts) != 3 or not all(parts):
                raise ValueError('Malformed application manifest: ' + str(name))
            source, token, app = parts
            if source not in ('cask', 'mas', 'direct') or '/' in app or app in ('.', '..'):
                raise ValueError('Invalid application manifest: ' + str(name))
            if name.name == 'apps.tsv' and source + ':' + token in skipped:
                continue
            # Some casks install fonts or command-line tools, without app bundles.
            installed = (any((root / (app + '.app')).is_dir()
                             for root in (applications, home / 'Applications'))
                         or source == 'cask' and (prefix / 'Caskroom' / token.rsplit('/', 1)[-1]).is_dir()
                         or source == 'direct' and token == 'openfoam2306'
                         and (home / '.local/bin/openfoam2306').is_file())
            if not installed:
                findings.append(f'Missing {app} ({source}:{token}); run mac-sync to apply')
    for row in (setup / 'packages.txt').read_text().splitlines():
        token = row.strip()
        if token and not token.startswith('#'):
            if not re.fullmatch(r'[a-zA-Z0-9@+_.-]+(?:/[a-zA-Z0-9@+_.-]+)*', token):
                raise ValueError('Invalid formula name')
            if not (prefix / 'opt' / token.rsplit('/', 1)[-1]).exists():
                findings.append(f'Missing formula {token}; run mac-sync to apply')
    return sorted(set(findings))


def main():
    home = Path.home()
    name = subprocess.check_output(['/usr/sbin/scutil', '--get', 'ComputerName'], text=True)
    host = re.sub(r'[^a-z0-9]+', '-', name.lower()).strip('-')
    findings = inspect(home, Path('/opt/homebrew'), host)
    # Only diagnostic state changes; no network requests or setup helpers run.
    state = home / '.local/state/mac-sync'
    state.mkdir(parents=True, exist_ok=True, mode=0o700)
    state.chmod(0o700)
    record = state / 'check.json'
    previous = json.loads(record.read_text()) if record.exists() else None
    if '--quiet' not in sys.argv[1:] or previous != findings:
        print('\n'.join(findings) if findings else 'mac-sync check: local application/package manifests satisfied')
    temporary = record.with_suffix('.tmp')
    with temporary.open('w') as stream:
        os.fchmod(stream.fileno(), 0o600)
        json.dump(findings, stream, indent=2)
        stream.write('\n')
    temporary.replace(record)
    # Expected drift is diagnostic for the hourly job, not an execution error.
    return bool(findings) and '--scheduled' not in sys.argv[1:]


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print('mac-sync check: ' + str(error), file=sys.stderr)
        sys.exit(2)
