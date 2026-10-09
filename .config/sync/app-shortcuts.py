#!/usr/bin/env python3
"""Bidirectional App Shortcuts sync; no other preferences leave this Mac."""
import ctypes as C
import fcntl
import json
import os
from pathlib import Path
import plistlib
import subprocess
import sys
import time
import uuid

HOME = Path.home()
ROOT = HOME / 'Library/Application Support/mac-sync/app-shortcuts'
BRANCH = 'app-shortcuts'
KEY = 'NSUserKeyEquivalents'
REGISTRY = 'com.apple.custommenu.apps'


def dump(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2) + '\n'


def save(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix('.tmp')
    temporary.write_text(dump(value))
    temporary.replace(path)


class Preferences:
    """Use cfprefsd, rather than editing live plist files or inherited defaults."""
    def __init__(self):
        self.cf = C.CDLL('/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation')
        signatures = {
            'CFPropertyListCreateWithData': ([C.c_void_p, C.c_void_p, C.c_ulong, C.c_void_p, C.c_void_p], C.c_void_p),
            'CFPropertyListCreateData': ([C.c_void_p, C.c_void_p, C.c_long, C.c_ulong, C.c_void_p], C.c_void_p),
            'CFDataCreate': ([C.c_void_p, C.c_char_p, C.c_long], C.c_void_p),
            'CFDataGetLength': ([C.c_void_p], C.c_long),
            'CFDataGetBytePtr': ([C.c_void_p], C.c_void_p),
            'CFRelease': ([C.c_void_p], None),
            'CFPreferencesCopyValue': ([C.c_void_p] * 4, C.c_void_p),
            'CFPreferencesSetValue': ([C.c_void_p] * 5, None),
            'CFPreferencesSynchronize': ([C.c_void_p] * 3, C.c_bool),
        }
        for name, (args, result) in signatures.items():
            fn = getattr(self.cf, name)
            fn.argtypes, fn.restype = args, result
        self.user = C.c_void_p.in_dll(self.cf, 'kCFPreferencesCurrentUser').value
        self.host = C.c_void_p.in_dll(self.cf, 'kCFPreferencesAnyHost').value
        self.global_domain = C.c_void_p.in_dll(self.cf, 'kCFPreferencesAnyApplication').value

    def encode(self, value):
        raw = plistlib.dumps(value)
        data = self.cf.CFDataCreate(None, raw, len(raw))
        try:
            result = self.cf.CFPropertyListCreateWithData(None, data, 0, None, None)
            if not result:
                raise ValueError('Cannot encode preference')
            return result
        finally:
            self.cf.CFRelease(data)

    def decode(self, value):
        data = self.cf.CFPropertyListCreateData(None, value, 100, 0, None)
        if not data:
            raise ValueError('Cannot decode preference')
        try:
            return plistlib.loads(C.string_at(self.cf.CFDataGetBytePtr(data), self.cf.CFDataGetLength(data)))
        finally:
            self.cf.CFRelease(data)

    def access(self, domain, key, value=None, write=False):
        app = self.global_domain if domain == 'NSGlobalDomain' else self.encode(domain)
        prop = self.encode(key)
        encoded = None
        try:
            if not self.cf.CFPreferencesSynchronize(app, self.user, self.host):
                raise RuntimeError(f'Cannot synchronize preferences for {domain}')
            if write:
                encoded = self.encode(value)
                self.cf.CFPreferencesSetValue(prop, encoded, app, self.user, self.host)
                if not self.cf.CFPreferencesSynchronize(app, self.user, self.host):
                    raise RuntimeError(f'macOS refused preference changes for {domain}')
            result = self.cf.CFPreferencesCopyValue(prop, app, self.user, self.host)
            if not result:
                return None
            try:
                return self.decode(result)
            finally:
                self.cf.CFRelease(result)
        finally:
            for pointer in (prop, encoded, app if domain != 'NSGlobalDomain' else None):
                if pointer:
                    self.cf.CFRelease(pointer)

    def shortcuts(self, domain):
        value = self.access(domain, KEY) or {}
        if not isinstance(value, dict) or not all(isinstance(k, str) and isinstance(v, str) for k, v in value.items()):
            raise ValueError(f'Unexpected App Shortcuts format in {domain}; leaving it unchanged')
        return value

    def scan(self, known):
        domains = set(known) | {'NSGlobalDomain'}
        domains.update(p.stem for p in (HOME / 'Library/Preferences').glob('*.plist') if not p.name.startswith('.'))
        domains.update(self.access('com.apple.universalaccess', REGISTRY) or [])
        return {domain: value for domain in sorted(domains)
                if (value := self.shortcuts(domain)) or domain in known}

    def apply(self, desired, scanned, baseline, checkpoint):
        edited_during_sync = False
        for domain in sorted(set(desired) | set(scanned)):
            current = self.shortcuts(domain)
            # A settings edit made during network I/O belongs to the next sync.
            if current != scanned.get(domain, {}):
                edited_during_sync = True
                continue
            wanted = desired.get(domain, {})
            if current != wanted:
                if self.access(domain, KEY, wanted, write=True) != wanted:
                    raise RuntimeError(f'Could not verify App Shortcuts for {domain}')
            baseline[domain] = wanted
            checkpoint()
        if edited_during_sync:
            return
        registry = sorted({'NSGlobalDomain'} | {domain for domain, entries in desired.items() if entries})
        if self.access('com.apple.universalaccess', REGISTRY) != registry:
            if self.access('com.apple.universalaccess', REGISTRY, registry, write=True) != registry:
                raise RuntimeError('macOS refused the App Shortcuts list; terminal permissions may be needed')


def merge(*documents):
    result = {}
    for document in documents:
        for domain, entries in document.items():
            for menu, event in entries.items():
                if not isinstance(domain, str) or not isinstance(menu, str):
                    raise ValueError('Invalid shortcut domain or menu')
                version = event['version']
                if (event['value'] is not None and not isinstance(event['value'], str)) or (
                    not isinstance(version, list) or len(version) != 2
                    or not isinstance(version[0], int) or not isinstance(version[1], str)
                ):
                    raise ValueError('Invalid shortcut event')
                old = result.setdefault(domain, {}).get(menu)
                if old is None or version > old['version']:
                    result[domain][menu] = event
    return result


def values(events):
    return {domain: {menu: event['value'] for menu, event in entries.items()
                     if event['value'] is not None} for domain, entries in events.items()}


def capture(state, current):
    first = 'baseline' not in state
    baseline = state.get('baseline', {})
    pending = state.setdefault('pending', {})
    # First-time imports cannot resurrect remotely deleted shortcuts.
    revision = [0 if first else max(time.time_ns(), state.get('clock', 0) + 1), state['device']]
    for domain in set(baseline) | set(current):
        before, after = baseline.get(domain, {}), current.get(domain, {})
        for menu in set(before) | set(after):
            if before.get(menu) != after.get(menu):
                pending.setdefault(domain, {})[menu] = {'value': after.get(menu), 'version': revision}
    state['baseline'] = current


class Transport:
    """An independent bare repository keeps the dotfiles index/HEAD untouched."""
    def __init__(self, root, url):
        self.repo = root / 'transport.git'
        self.env = {k: v for k, v in os.environ.items() if not k.startswith('GIT_')}
        self.env.update(GIT_TERMINAL_PROMPT='0', GIT_AUTHOR_NAME='Mac App Shortcuts',
                        GIT_AUTHOR_EMAIL='mac-sync@localhost', GIT_COMMITTER_NAME='Mac App Shortcuts',
                        GIT_COMMITTER_EMAIL='mac-sync@localhost')
        if not self.repo.exists():
            self.git('init', '--bare', str(self.repo), external=True)
            self.git('remote', 'add', 'origin', url)
        else:
            self.git('remote', 'set-url', 'origin', url)

    def git(self, *args, input=None, check=True, external=False):
        command = ['git'] + ([] if external else [f'--git-dir={self.repo}']) + list(args)
        result = subprocess.run(command, input=input, text=True, capture_output=True,
                                env=self.env, timeout=90)
        if check and result.returncode:
            raise RuntimeError(result.stderr.strip() or 'App Shortcuts Git operation failed')
        return result

    def read(self):
        result = self.git('ls-remote', '--exit-code', 'origin', f'refs/heads/{BRANCH}', check=False)
        if result.returncode == 2:
            return None, {}
        if result.returncode:
            raise RuntimeError(result.stderr.strip() or 'Cannot reach shortcut remote')
        self.git('fetch', '--quiet', 'origin', f'refs/heads/{BRANCH}')
        parent = self.git('rev-parse', 'FETCH_HEAD').stdout.strip()
        return parent, merge(json.loads(self.git('show', f'{parent}:shortcuts.json').stdout))

    def exchange(self, pending, seed):
        for _ in range(3):
            parent, remote = self.read()
            # A first-time import fills gaps, but never replaces an existing
            # shared choice, including an initial import from the other Mac.
            incoming = {domain: {menu: event for menu, event in entries.items()
                                 if not (parent and event['version'][0] == 0
                                         and menu in remote.get(domain, {}))}
                        for domain, entries in pending.items()}
            combined = merge(remote if parent else seed, incoming)
            if parent and combined == remote:
                return combined
            blob = self.git('hash-object', '-w', '--stdin', input=dump(combined)).stdout.strip()
            tree = self.git('mktree', input=f'100644 blob {blob}\tshortcuts.json\n').stdout.strip()
            commit = self.git('commit-tree', tree, *(['-p', parent] if parent else []),
                              input='Sync macOS App Shortcuts\n').stdout.strip()
            pushed = self.git('push', '--quiet', 'origin', f'{commit}:refs/heads/{BRANCH}', check=False)
            if pushed.returncode == 0:
                return combined
            # Concurrent edits are merged against the new remote and retried.
        raise RuntimeError('Cannot publish App Shortcuts; local changes retained. ' + pushed.stderr.strip())


def sync(root=ROOT, preferences=None, transport=None):
    root.mkdir(parents=True, exist_ok=True)
    with (root / 'lock').open('w') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return
        path = root / 'state.json'
        state = json.loads(path.read_text()) if path.exists() else {'device': str(uuid.uuid4())}
        prefs = preferences or Preferences()
        current = prefs.scan(set(state.get('baseline', {})) | set(state.get('pending', {})))
        capture(state, current)
        save(path, state)  # Persist offline edits before trying the network.
        seed_values = json.loads(Path(__file__).with_name('app-shortcuts-seed.json').read_text())
        seed = {domain: {menu: {'value': value, 'version': [0, '']} for menu, value in entries.items()}
                for domain, entries in seed_values.items()}
        if transport is None:
            url = subprocess.run(['git', f'--git-dir={HOME}/.config/git/dotfiles',
                                  'remote', 'get-url', 'origin'], check=True, text=True,
                                 capture_output=True).stdout.strip()
            transport = Transport(root, url)
        shared = transport.exchange(state['pending'], seed)
        state['clock'] = max((event['version'][0] for entries in shared.values()
                              for event in entries.values()), default=0)
        state['pending'] = {}
        save(path, state)
        prefs.apply(values(shared), current, state['baseline'], lambda: save(path, state))


if __name__ == '__main__':
    if (ROOT / 'paused').exists():
        print('App Shortcuts sync is paused locally.', file=sys.stderr)
        sys.exit(0)
    try:
        sync()
    except Exception as error:
        print(f'App Shortcuts sync failed (local edits retained): {error}', file=sys.stderr)
        sys.exit(1)
