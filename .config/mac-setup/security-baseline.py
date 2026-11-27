#!/usr/bin/python3
"""Apply the reviewed Mac security baseline, without installing a resident job."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess


def run(args):
    return subprocess.run(args, check=True, text=True, capture_output=True,
                          env={'PATH': '/usr/bin:/bin:/usr/sbin:/sbin'})


def private(path, mode):
    if not path.exists():
        return
    if path.is_symlink() or path.stat().st_uid != os.getuid():
        raise RuntimeError('Refusing unexpected ownership/symlink: ' + str(path))
    path.chmod(mode)
    print(f'Private permissions: {path} {mode:04o}')


def user():
    if os.getuid() == 0:
        raise RuntimeError('Run user mode without sudo')
    home = Path.home()
    private(home / '.t3/userdata', 0o700)
    private(home / '.t3/userdata/secrets', 0o700)
    for relative in ('.t3/userdata/clerk-tokens.json', '.config/fish/secrets.fish',
                     '.codex/auth.json', '.config/gh/hosts.yml',
                     '.gemini/oauth_creds.json', '.claude/.credentials.json'):
        private(home / relative, 0o600)


def system():
    if os.getuid() != 0:
        raise RuntimeError('System mode requires administrator authentication')
    # Protect the loaded daemon's existing executable path without restarting
    # Tailscale or changing any other CLI files' ownership.
    daemon = Path('/Library/LaunchDaemons/com.tailscale.tailscaled.plist')
    if daemon.exists():
        import plistlib
        # Older Tailscale installers wrote OpenStep plists; normalize in memory.
        encoded = run(['/usr/bin/plutil', '-convert', 'xml1', '-o', '-', str(daemon)]).stdout
        config = plistlib.loads(encoded.encode())
        executable = config.get('Program') or config.get('ProgramArguments', [''])[0]
        if executable == '/usr/local/bin/tailscaled':
            path = Path(executable)
            if path.is_symlink() or path.stat().st_uid != 0:
                raise RuntimeError('Unexpected Tailscale executable; refusing automatic hardening')
            parent = path.parent
            if parent.is_symlink():
                raise RuntimeError('Unexpected /usr/local/bin symlink')
            os.chown(parent, 0, 0)
            parent.chmod(0o755)
            print('Protected /usr/local/bin; running Tailscale was preserved')
    archive = Path('/var/db/com.fausto.mac-security')
    archive.mkdir(mode=0o700, exist_ok=True)
    if archive.is_symlink() or archive.stat().st_uid != 0:
        raise RuntimeError('Unexpected security archive ownership')
    archive.chmod(0o700)
    rule = Path('/etc/sudoers.d/vorssaint-clamshell')
    if rule.exists():
        run(['/usr/sbin/visudo', '-c'])
        backup = archive / 'vorssaint-clamshell'
        if backup.exists():
            raise RuntimeError('An earlier sudo-rule backup already exists; review before overwriting')
        shutil.copy2(rule, backup)
        backup.chmod(0o400)
        rule.unlink()
        try:
            run(['/usr/sbin/visudo', '-c'])
        except subprocess.CalledProcessError:
            shutil.copy2(backup, rule)
            raise
        print('Retired obsolete Vorssaint passwordless pmset rule; sudoers validated')
    firewall = '/usr/libexec/ApplicationFirewall/socketfilterfw'
    for executable in ('/usr/sbin/sshd', '/usr/libexec/sshd-keygen-wrapper',
                       '/Applications/Tailscale.app/Contents/MacOS/Tailscale',
                       '/Applications/T3 Code (Nightly).app/Contents/MacOS/T3 Code (Nightly)'):
        if Path(executable).exists():
            run([firewall, '--add', executable])
            run([firewall, '--unblockapp', executable])
    run([firewall, '--setglobalstate', 'on'])
    print(run([firewall, '--getglobalstate']).stdout.strip())
    # Remove only the current user's dormant Public Folder share, not other
    # shares or SSH/Screen Sharing. Retain filesystem contents.
    shares = run(['/usr/sbin/sharing', '-l']).stdout
    import re
    for block in re.split(r'(?m)(?=^name:\s)', shares):
        name = re.search(r'^name:\s*(.+)$', block, re.M)
        path = re.search(r'^path:\s*(.+)$', block, re.M)
        if name and path and path[1].strip() == '/Users/faustozamparelli/Public':
            run(['/usr/sbin/sharing', '-r', name[1].strip()])
            print('Removed dormant Public Folder SMB share')
    run(['/usr/sbin/sysadminctl', '-smbGuestAccess', 'off'])
    print('SMB guest access disabled')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=('user', 'system'))
    args = parser.parse_args()
    try:
        (user if args.mode == 'user' else system)()
    except (OSError, RuntimeError, ValueError, subprocess.SubprocessError) as error:
        parser.exit(1, 'security-baseline: ' + str(error) + '\n')
