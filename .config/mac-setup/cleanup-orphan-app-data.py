#!/usr/bin/env python3
"""Archive reviewed app data only when the corresponding app/tool is absent."""
import datetime
import json
import shutil
import subprocess
import sys
from pathlib import Path

HOME = Path.home()
RETIRED = HOME / '.config/mac-setup/retired-apps.tsv'
ARCHIVE = HOME / 'Cleanup Review' / 'orphan-app-data'

# App bundles are never removed here. Existing installations keep their data.
TARGETS = [
    ('Discord', 'Discord.app', None, 'discord', [
        'Library/Application Support/discord', 'Library/Caches/com.hnc.Discord',
        'Library/Caches/com.hnc.Discord.ShipIt', 'Library/Preferences/com.hnc.Discord.plist',
        'Library/HTTPStorages/com.hnc.Discord', 'Library/Logs/Discord']),
    ('GitButler', 'GitButler.app', None, 'gitbutler', [
        'Library/Application Support/gitbutler', 'Library/Caches/com.gitbutler.app',
        'Library/Preferences/com.gitbutler.app.plist', 'Library/HTTPStorages/com.gitbutler.app']),
    ('Tor Browser', 'Tor Browser.app', None, 'tor-browser', [
        'Library/Application Support/TorBrowser-Data', 'Library/Caches/org.torproject.torbrowser',
        'Library/Preferences/org.torproject.torbrowser.plist',
        'Library/Saved Application State/org.torproject.torbrowser.savedState']),
    ('SourceGit', 'SourceGit.app', 'sourcegit', None, [
        'Library/Application Support/SourceGit', '.config/SourceGit', '.cache/SourceGit']),
    ('Stats', 'Stats.app', 'stats', None, [
        'Library/Application Support/Stats', 'Library/Caches/eu.exelban.Stats',
        'Library/Preferences/eu.exelban.Stats.plist']),
    ('LazyGit', None, 'lazygit', None, [
        'Library/Application Support/lazygit', '.config/lazygit', '.local/share/lazygit']),
    ('tmux', None, 'tmux', None, ['.config/tmux']),
    ('Octave', 'Octave.app', 'octave', None, ['.config/octave']),
    ('OpenCode', 'OpenCode.app', 'opencode', None, [
        '.config/opencode', '.local/share/opencode', '.cache/opencode']),
    ('Billion Context', None, 'billion-context', None, ['.config/billion-context']),
]


def main():
    dry_run = '--dry-run' in sys.argv[1:]
    delete = '--delete' in sys.argv[1:]
    retired = {row.split('\t')[1] for row in RETIRED.read_text().splitlines()
               if row and not row.startswith('#')}
    # Fail closed if process inspection is unavailable.
    processes = subprocess.check_output(['ps', '-axo', 'comm='], text=True).splitlines()
    installed_apps = {app.name.casefold() for root in (Path('/Applications'), HOME / 'Applications')
                      if root.exists() for app in root.rglob('*.app')}
    failures = []
    removed = 0
    eligible_paths = set()
    for name, app, binary, retirement, paths in TARGETS:
        if retirement and retirement not in retired:
            continue
        if app and app.casefold() in installed_apps:
            continue
        if binary:
            roots = (HOME / '.local/bin', HOME / 'bin', HOME / '.bun/bin',
                     HOME / '.cargo/bin', HOME / '.nix-profile/bin', HOME / '.opencode/bin')
            if shutil.which(binary) or any((root / binary).exists() for root in roots):
                continue
        if any((app and f'/{app}/' in proc) or
               (binary and Path(proc.strip()).name == binary) for proc in processes):
            continue
        for relative in paths:
            path = HOME / relative
            eligible_paths.add(path)
            if not path.exists() and not path.is_symlink():
                continue
            verb = 'Would delete' if dry_run and delete else 'Would archive' if dry_run else 'Deleting' if delete else 'Archiving'
            print(f'{verb} {name} leftover: {path}')
            if dry_run:
                continue
            try:
                if delete:
                    if path.is_symlink() or not path.is_dir():
                        path.unlink()
                    else:
                        shutil.rmtree(path)
                    removed += 1
                    continue
                target = ARCHIVE / relative
                if target.exists() or target.is_symlink():
                    target = target.with_name(target.name + '-' + datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f'))
                target.parent.mkdir(parents=True, exist_ok=True)
                target.parent.chmod(0o700)
                # A rename on the home volume retains data and permissions.
                path.rename(target)
                manifest = ARCHIVE / 'manifest.jsonl'
                with manifest.open('a') as stream:
                    stream.write(json.dumps({'source': str(path), 'archive': str(target)}) + '\n')
                manifest.chmod(0o600)
                removed += 1
            except OSError as exc:
                failures.append(f'{path}: {exc}')
    # Purge only previously reviewed, approved archive entries; unrelated files stay.
    manifest = ARCHIVE / 'manifest.jsonl'
    if delete and manifest.exists():
        remaining = []
        for line in manifest.read_text().splitlines():
            record = json.loads(line)
            source, target = Path(record['source']), Path(record['archive'])
            if source not in eligible_paths or not target.is_relative_to(ARCHIVE):
                remaining.append(line)
                continue
            print(f'{"Would delete" if dry_run else "Deleting"} approved archived leftover: {target}')
            if dry_run:
                continue
            try:
                if target.is_symlink():
                    target.unlink()
                elif target.is_dir():
                    shutil.rmtree(target)
                elif target.exists():
                    target.unlink()
                removed += 1
            except OSError as exc:
                failures.append(f'{target}: {exc}')
                remaining.append(line)
        if not dry_run:
            if remaining:
                manifest.write_text('\n'.join(remaining) + '\n')
            else:
                manifest.unlink()
            for directory in sorted(ARCHIVE.rglob('*'), key=lambda p: len(p.parts), reverse=True):
                if directory.is_dir() and not directory.is_symlink():
                    try:
                        directory.rmdir()
                    except OSError:
                        pass
            for directory in (ARCHIVE, ARCHIVE.parent):
                try:
                    directory.rmdir()
                except OSError:
                    pass
    for failure in failures:
        print(f'Cleanup blocked: {failure}', file=sys.stderr)
    print(f'{removed} leftover paths {"deleted" if delete else "archived"}; {len(failures)} blocked')
    return bool(failures)


if __name__ == '__main__':
    raise SystemExit(main())
