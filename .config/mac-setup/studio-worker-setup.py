#!/usr/bin/python3
"""Keep Studio's existing Tailscale daemon available; run explicitly with sudo."""
import os
from pathlib import Path
import plistlib
import subprocess


def run(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout


def main():
    if os.getuid() != 0 or run('/usr/sbin/scutil', '--get', 'ComputerName').strip() != 'Mac Studio':
        raise RuntimeError('Run with sudo on Mac Studio only')
    path = Path('/Library/LaunchDaemons/com.tailscale.tailscaled.plist')
    config = plistlib.loads(run('/usr/bin/plutil', '-convert', 'xml1', '-o', '-', str(path)).encode())
    if config.get('ProgramArguments') != ['/usr/local/bin/tailscaled']:
        raise RuntimeError('Unexpected Tailscale daemon; review before changing it')
    run('/bin/launchctl', 'enable', 'system/com.tailscale.tailscaled')
    changed = config.get('KeepAlive') is not True or config.get('ThrottleInterval') != 10
    if changed:
        archive = Path('/var/db/com.fausto.mac-security')
        archive.mkdir(mode=0o700, exist_ok=True)
        backup = archive / 'tailscaled-before-worker.plist'
        if not backup.exists():
            backup.write_bytes(path.read_bytes())
            backup.chmod(0o600)
        config.update(KeepAlive=True, RunAtLoad=True, ThrottleInterval=10)
        temporary = path.with_suffix('.worker.tmp')
        temporary.write_bytes(plistlib.dumps(config))
        temporary.chmod(0o644)
        temporary.replace(path)
        run('/bin/launchctl', 'bootout', 'system/com.tailscale.tailscaled')
        run('/bin/launchctl', 'bootstrap', 'system', str(path))
    run('/bin/launchctl', 'enable', 'system/com.tailscale.tailscaled')
    run('/usr/bin/pmset', '-a', 'sleep', '0', 'autorestart', '1')
    print('Studio: Tailscale launchd recovery enabled; AC sleep off; power-loss restart on')


if __name__ == '__main__':
    main()
