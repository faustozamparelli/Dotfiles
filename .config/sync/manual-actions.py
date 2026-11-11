#!/usr/bin/env python3
"""One visible, repeatable action list after routine commands; never applies changes."""
import importlib.util
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys

HOME = Path.home()
CONFIG = Path(__file__).parent


def load(name):
    spec = importlib.util.spec_from_file_location(name.replace('-', '_'), CONFIG / (name + '.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def collect():
    actions = []
    keymaps = HOME / '.config/keymaps/keymap-docs'
    if keymaps.is_file():
        result = subprocess.run([str(keymaps), '--check'], text=True, capture_output=True)
        if result.returncode:
            actions.append('Keymap validation needs attention: run keymap-docs --check. '
                           'Finish/review any shortcut edits, then mac save regenerates and publishes the table.')
    profile = HOME / 'Library/Application Support/net.imput.helium/Default/Secure Preferences'
    if (CONFIG / 'helium-extensions.py').exists():
        extensions = load('helium-extensions')
        if not profile.exists():
            actions.append('Open Helium once, then run mac sync to enroll its extensions.')
        else:
            settings = json.loads(profile.read_text()).get('extensions', {}).get('settings', {})
            for identifier, name in extensions.MANUAL_EXTENSIONS.items():
                entry = settings.get(identifier, {})
                path = Path(entry.get('path', '/nonexistent'))
                if entry.get('location') != 4 or not (path / 'manifest.json').exists():
                    actions.append(f'INSTALL {name} MANUALLY: helium://extensions > Developer mode > '
                                   'Load unpacked; select TwitchNoSub in iCloud Drive/Downloads.')
            state_path = extensions.ROOT / 'state.json'
            if state_path.exists():
                state = extensions.load_state(extensions.ROOT)
                if state.get('pending', {}).get('extensions'):
                    actions.append('Extension changes are unpublished: reconnect to the internet and run mac sync.')
                current = extensions.read_policy()
                if extensions.merged_policy(state.get('shared', {}), current) != current:
                    actions.append('Extension choices are not applied locally: run helium-extension sync '
                                   'and approve its normal administrator prompt.')
                installed, _ = extensions.inventory()
                events = state.get('shared', {}).get('extensions', {})
                additions = sum(e['value'] is not None and identifier not in installed
                                for identifier, e in events.items())
                removals = sum(e['value'] is None and identifier in installed
                               for identifier, e in events.items())
                if additions or removals:
                    actions.append(f'Helium has {additions} installs and {removals} removals pending. '
                                   'Reload policies at helium://policy or relaunch Helium; '
                                   'downloads may take time. Recheck with mac status.')
    stamp = HOME / '.local/state/app-updates/last-run.json'
    if stamp.exists():
        updates = json.loads(stamp.read_text())
        if updates.get('failures'):
            actions.append(f'The last update pass ({updates.get("date", "unknown")}) had failures. '
                           'Retry with mac update; details: ~/Library/Logs/mac-update.log.')
        for item in updates.get('deferred', []):
            if 'installer/helper needs' in item:
                name = item.split(':', 1)[0]
                actions.append(f'UPDATE {name} MANUALLY with its native updater or an interactive '
                               f'brew upgrade --cask {name}.')
    # Preserve the established web-app reminders verbatim, at the end.
    apps = load('helium-apps')
    for app in apps.missing_apps(apps.load_manifest(), apps.scan()):
        actions.append(f'INSTALL {app["name"]} WEB APP')
    if any(action.endswith(' WEB APP') for action in actions):
        actions.insert(0, 'Missing web apps: open their URLs from ~/.config/sync/helium-apps.json '
                       'in Helium and install each as a web app.')
    return actions


def report(failed=False, log=None):
    actions = collect()
    heading = 'ACTION REQUIRED' if actions or failed else 'ROUTINE COMPLETE'
    if sys.stdout.isatty():
        color = '\033[1;33m' if actions or failed else '\033[1;32m'
        print(f'\n{color}========== {heading} ==========\033[0m')
    else:
        print(f'\n========== {heading} ==========')
    if failed:
        print('The routine reported a failure or an unresolved check. Review the error above.')
    if log:
        print(f'Full log to share with an agent: {log}')
        if failed:
            print(f'Copy log: pbcopy < {shlex.quote(str(log))}')
    if not actions and not failed:
        print('No manual steps pending.')
    for action in actions:
        print(action)
    return bool(actions)


if __name__ == '__main__' and os.environ.get('MAC_ROUTINE_DEFER_ACTIONS') != '1':
    try:
        report()
    except (OSError, ValueError, TypeError, KeyError) as error:
        print(f'\n========== ACTION REQUIRED ==========\nCould not build the manual action list: {error}',
              file=sys.stderr)
        sys.exit(1)
