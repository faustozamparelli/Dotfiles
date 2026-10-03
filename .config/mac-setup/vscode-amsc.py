#!/usr/bin/env python3
"""Apply the portable named-container profile without tracking remote state."""
import json
from pathlib import Path
import shutil
import subprocess


def main():
    home = Path.home()
    setup = Path(__file__).parent
    if not any((home / '.vscode/extensions').glob('ms-vscode-remote.remote-containers-*')):
        return
    target = home / ('Library/Application Support/Code/User/globalStorage/'
                     'ms-vscode-remote.remote-containers/nameConfigs/amsc.json')
    desired = json.loads((setup / 'vscode-amsc.json').read_text())
    # VS Code writes strict JSON here. Leave an unexpected/custom JSONC file
    # untouched rather than replacing a configuration we cannot safely merge.
    try:
        current = json.loads(target.read_text()) if target.exists() else {}
    except json.JSONDecodeError:
        print(f'Custom AMSC profile needs manual merge: {target}')
        return
    for key, value in desired.items():
        if key == 'settings':
            current.setdefault(key, {}).update(value)
        elif key == 'extensions':
            current[key] = list(dict.fromkeys(current.get(key, []) + value))
        else:
            current[key] = value
    updated = json.dumps(current, indent=2) + '\n'
    if not target.exists() or target.read_text() != updated:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(updated)
        print('Applied VS Code named AMSC container profile')
    docker = shutil.which('docker') or str(home / '.orbstack/bin/docker')
    if not Path(docker).exists():
        return
    state = subprocess.run([docker, 'inspect', '--format', '{{.State.Running}}', 'amsc'],
                           text=True, capture_output=True)
    if state.returncode or state.stdout.strip() != 'true':
        return
    # Only the known course image/user gets this helper. Never mutate another
    # unrelated container which happens to reuse the name.
    image = subprocess.check_output([docker, 'inspect', '--format', '{{.Config.Image}}',
                                     'amsc'], text=True).strip()
    if not image.startswith('quay.io/pjbaioni/amsc_mk:'):
        print('AMSC helper skipped: container uses a different image')
        return
    subprocess.run([docker, 'exec', '-i', '-u', 'ubuntu', 'amsc', '/bin/bash', '-c',
                    'set -e; mkdir -p /home/ubuntu/.local/bin; '
                    'cat > /home/ubuntu/.local/bin/vscode-amsc-clangd; '
                    'chmod 755 /home/ubuntu/.local/bin/vscode-amsc-clangd'],
                   input=(setup / 'vscode-amsc-clangd.sh').read_bytes(), check=True)


if __name__ == '__main__':
    main()
