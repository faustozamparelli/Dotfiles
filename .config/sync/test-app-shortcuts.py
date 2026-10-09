"""Exercise two Macs against a real temporary Git remote, without live settings."""
import copy
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('shortcuts', Path(__file__).with_name('app-shortcuts.py'))
shortcuts = importlib.util.module_from_spec(spec)
spec.loader.exec_module(shortcuts)
DOMAIN = 'org.example.test'


class Preferences:
    def __init__(self, entries=None):
        self.entries = copy.deepcopy(entries or {})
        self.during_apply = None

    def scan(self, known):
        return copy.deepcopy(self.entries)

    def apply(self, desired, scanned, baseline, checkpoint):
        for domain in set(desired) | set(scanned):
            self.entries[domain] = copy.deepcopy(desired.get(domain, {}))
            baseline[domain] = copy.deepcopy(self.entries[domain])
            checkpoint()


class SyncTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.remote = self.root / 'remote.git'
        subprocess.run(['git', 'init', '--quiet', '--bare', str(self.remote)], check=True)
        self.a, self.b = Preferences({DOMAIN: {'First': '@a'}}), Preferences()

    def transport(self, mac):
        root = self.root / mac
        root.mkdir(exist_ok=True)
        return shortcuts.Transport(root, str(self.remote))

    def run_mac(self, mac, prefs, transport=None):
        shortcuts.sync(self.root / mac, prefs, transport or self.transport(mac))

    def enroll(self):
        self.run_mac('a', self.a)
        self.run_mac('b', self.b)

    def test_add_change_delete_both_directions(self):
        self.enroll()
        self.assertEqual(self.b.entries[DOMAIN], {'First': '@a'})
        self.b.entries[DOMAIN]['Second'] = '@b'
        self.run_mac('b', self.b)
        self.run_mac('a', self.a)
        self.assertEqual(self.a.entries[DOMAIN]['Second'], '@b')
        self.a.entries[DOMAIN]['First'] = '@z'
        self.run_mac('a', self.a)
        self.run_mac('b', self.b)
        self.assertEqual(self.b.entries[DOMAIN]['First'], '@z')
        self.b.entries[DOMAIN] = {}
        self.run_mac('b', self.b)
        self.run_mac('a', self.a)
        self.assertEqual(self.a.entries[DOMAIN], {})
        self.run_mac('b', self.b)
        self.assertEqual(self.b.entries[DOMAIN], {})

    def test_independent_offline_edits_merge_and_deletion_survives(self):
        self.enroll()
        del self.a.entries[DOMAIN]['First']
        self.a.entries[DOMAIN]['From A'] = '@a'
        self.b.entries[DOMAIN]['From B'] = '@b'
        self.run_mac('a', self.a)
        self.run_mac('b', self.b)
        self.run_mac('a', self.a)
        self.assertEqual(self.a.entries[DOMAIN], {'From A': '@a', 'From B': '@b'})
        self.assertEqual(self.a.entries, self.b.entries)

    def test_new_mac_does_not_resurrect_deletions(self):
        self.enroll()
        self.a.entries[DOMAIN] = {}
        self.run_mac('a', self.a)
        stale = Preferences({DOMAIN: {'First': '@a', 'Unique': '@u'}})
        self.run_mac('c', stale)
        self.assertEqual(stale.entries[DOMAIN], {'Unique': '@u'})

    def test_first_import_respects_existing_shared_choice(self):
        self.enroll()
        other = Preferences({DOMAIN: {'First': '@z'}})
        self.run_mac('c', other)
        self.assertEqual(other.entries[DOMAIN]['First'], '@a')

    def test_network_failure_retains_edits_and_preferences(self):
        self.enroll()
        self.b.entries[DOMAIN] = {'Offline': '@o'}
        before = copy.deepcopy(self.b.entries)

        class Offline:
            def exchange(self, *args):
                raise RuntimeError('offline')

        with self.assertRaisesRegex(RuntimeError, 'offline'):
            self.run_mac('b', self.b, Offline())
        self.assertEqual(self.b.entries, before)
        self.assertTrue(json.loads((self.root / 'b/state.json').read_text())['pending'])
        self.run_mac('b', self.b)
        self.run_mac('a', self.a)
        self.assertEqual(self.a.entries[DOMAIN], {'Offline': '@o'})

    def test_concurrent_push_retries_and_only_shortcut_file_is_published(self):
        self.enroll()
        transport = self.transport('a')
        original = transport.read
        raced = False

        def read():
            nonlocal raced
            result = original()
            if not raced:
                raced = True
                self.b.entries[DOMAIN]['Race B'] = '@b'
                self.run_mac('b', self.b)
            return result

        transport.read = read
        self.a.entries[DOMAIN]['Race A'] = '@a'
        self.run_mac('a', self.a, transport)
        self.assertIn('Race A', self.a.entries[DOMAIN])
        self.assertIn('Race B', self.a.entries[DOMAIN])
        files = subprocess.run(['git', f'--git-dir={self.remote}', 'ls-tree', '--name-only',
                                shortcuts.BRANCH], check=True, text=True, capture_output=True).stdout
        self.assertEqual(files.strip(), 'shortcuts.json')

    def test_later_edit_wins_same_menu(self):
        self.enroll()
        self.a.entries[DOMAIN]['First'] = '@x'
        self.b.entries[DOMAIN]['First'] = '@y'
        self.run_mac('a', self.a)
        self.run_mac('b', self.b)
        self.run_mac('a', self.a)
        self.assertEqual(self.a.entries[DOMAIN]['First'], '@y')

    def test_native_apply_preserves_other_keys_and_defers_mid_sync_edit(self):
        class NativeFake(shortcuts.Preferences):
            def __init__(self):
                self.data = {DOMAIN: {shortcuts.KEY: {'First': '@a'}, 'unrelated': 42}}

            def access(self, domain, key, value=None, write=False):
                if write:
                    self.data.setdefault(domain, {})[key] = copy.deepcopy(value)
                return self.data.get(domain, {}).get(key)

        prefs = NativeFake()
        baseline = {}
        prefs.apply({DOMAIN: {'Changed': '@z'}}, {DOMAIN: {'First': '@a'}}, baseline, lambda: None)
        self.assertEqual(prefs.data[DOMAIN]['unrelated'], 42)
        self.assertEqual(prefs.shortcuts(DOMAIN), {'Changed': '@z'})
        prefs.data[DOMAIN][shortcuts.KEY] = {'During sync': '@d'}
        prefs.apply({DOMAIN: {}}, {DOMAIN: {'Changed': '@z'}}, baseline, lambda: None)
        self.assertEqual(prefs.shortcuts(DOMAIN), {'During sync': '@d'})


if __name__ == '__main__':
    unittest.main()
