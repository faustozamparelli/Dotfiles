#!/usr/bin/env python3
"""Install Herdr login startup without competing with an existing manual server."""
import os
from pathlib import Path
import plistlib
import subprocess


def install(home=None):
    home = home or Path.home()
    if not Path('/opt/homebrew/bin/herdr').exists():
        return
    agent = home / 'Library/LaunchAgents/sh.brew.herdr.plist'
    config = dict(Label='sh.brew.herdr', RunAtLoad=True,
                  KeepAlive={'SuccessfulExit': False},
                  ProgramArguments=[str(home / '.config/herdr/start-server')],
                  LimitLoadToSessionType=['Aqua', 'Background'],
                  StandardOutPath=str(home / 'Library/Logs/herdr-startup.log'),
                  StandardErrorPath=str(home / 'Library/Logs/herdr-startup.log'))
    raw = plistlib.dumps(config)
    if agent.exists() and agent.read_bytes() == raw:
        return
    (home / 'Library/Logs').mkdir(parents=True, exist_ok=True)
    agent.parent.mkdir(parents=True, exist_ok=True)
    domain = f'gui/{os.getuid()}'
    if subprocess.run(['launchctl', 'print', domain], capture_output=True).returncode:
        domain = f'user/{os.getuid()}'
    for previous in (f'gui/{os.getuid()}', f'user/{os.getuid()}'):
        subprocess.run(['launchctl', 'bootout', previous + '/sh.brew.herdr'], capture_output=True)
    agent.write_bytes(raw)
    subprocess.run(['launchctl', 'enable', domain + '/sh.brew.herdr'], check=True)
    subprocess.run(['launchctl', 'bootstrap', domain, str(agent)], check=True)
    print('Herdr login startup reconciled; an existing server is preserved.')


if __name__ == '__main__':
    install()
