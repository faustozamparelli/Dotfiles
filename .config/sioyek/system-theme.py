#!/usr/bin/python3
"""Apply macOS appearance once, when Sioyek opens. No background listener."""
import argparse
import datetime
from pathlib import Path
import subprocess

APP = '/Applications/Sioyek.app/Contents/MacOS/sioyek'
LOG = Path.home() / 'Library/Logs/sioyek-system-theme.log'


def system_theme():
    result = subprocess.run(['/usr/bin/defaults', 'read', '-g', 'AppleInterfaceStyle'],
                            capture_output=True, text=True, timeout=10)
    if result.returncode:
        # Light Mode removes this preference. macOS versions phrase this differently.
        if 'does not exist' not in result.stderr and 'Could not find key' not in result.stderr:
            raise RuntimeError(result.stderr.strip())
        return 'light'
    return 'dark' if result.stdout.strip().lower() == 'dark' else 'light'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--once', action='store_true')
    parser.add_argument('document', nargs='?')
    args = parser.parse_args()
    theme = system_theme()
    # Sioyek starts dark (default_dark_mode 1); only toggle for light mode.
    commands = 'toggle_dark_mode' if theme == 'light' else 'noop'
    command = [APP, '--nofocus', '--reuse-window', '--execute-command', commands]
    if args.document:
        command.append(args.document)
    result = subprocess.run(command, capture_output=True, text=True, timeout=10)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or 'Sioyek theme command failed')
    LOG.parent.mkdir(parents=True, exist_ok=True)
    with LOG.open('a') as log:
        log.write(f'{datetime.datetime.now().isoformat(timespec="seconds")}: startup applied {theme}\n')


if __name__ == '__main__':
    main()
