#!/usr/bin/env python3
"""Exercise extension choices against a real temporary Git remote, never a live browser."""
import importlib.util
import json
from pathlib import Path
import plistlib
import subprocess
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location('helium', Path(__file__).with_name('helium-extensions.py'))
helium = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(helium)
ONE, TWO = 'a' * 32, 'b' * 32


class ExtensionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.remote = self.root / 'remote.git'
        subprocess.run(['git', 'init', '--quiet', '--bare', str(self.remote)], check=True)

    def exchange(self, device, state):
        root = self.root / device
        root.mkdir(exist_ok=True)
        return helium.exchange(root, state, helium.Transport(root, str(self.remote)))

    def test_commands_win_by_time_even_when_published_in_reverse_order(self):
        a, b = {'device': 'a'}, {'device': 'b'}
        helium.record(a, ONE, 'Added', now=100)
        helium.record(b, ONE, None, now=200)
        self.exchange('b', b)
        self.exchange('a', a)
        self.assertIsNone(a['shared']['extensions'][ONE]['value'])
        self.assertFalse(a['pending'])

    def test_offline_edits_persist_and_merge_independent_extensions(self):
        a, b = {'device': 'a'}, {'device': 'b'}
        helium.record(a, ONE, 'First', now=100)
        helium.record(b, TWO, 'Second', now=110)
        helium.shared.save(self.root / 'offline.json', b)
        b = json.loads((self.root / 'offline.json').read_text())
        self.exchange('a', a)
        self.exchange('b', b)
        self.exchange('a', a)
        self.assertEqual(a['shared'], b['shared'])
        self.assertEqual(set(helium.shared.values(a['shared'])['extensions']), {ONE, TWO})

    def test_new_mac_cannot_resurrect_a_deleted_extension(self):
        a, b = {'device': 'a'}, {'device': 'b'}
        helium.record(a, ONE, None, now=100)
        self.exchange('a', a)
        helium.enroll(b, {ONE: 'Stale', TWO: 'New'})
        self.exchange('b', b)
        self.assertIsNone(b['shared']['extensions'][ONE]['value'])
        self.assertEqual(b['shared']['extensions'][TWO]['value'], 'New')

    def test_repeat_enrollment_does_not_undo_command_or_import_ui_changes(self):
        state = {'device': 'a'}
        helium.enroll(state, {ONE: 'First'})
        helium.record(state, ONE, None, now=100)
        helium.enroll(state, {ONE: 'First', TWO: 'Unmanaged'})
        self.assertIsNone(state['pending']['extensions'][ONE]['value'])
        self.assertNotIn(TWO, state['pending']['extensions'])

    def test_local_clock_is_monotonic_and_equal_times_break_ties_by_device(self):
        state = {'device': 'a', 'clock': 200}
        helium.record(state, ONE, 'First', now=100)
        self.assertEqual(state['pending']['extensions'][ONE]['version'][0], 201)
        a, b = {'device': 'a'}, {'device': 'b'}
        helium.record(a, ONE, 'First', now=100)
        helium.record(b, ONE, None, now=100)
        self.exchange('a', a)
        self.exchange('b', b)
        self.assertIsNone(b['shared']['extensions'][ONE]['value'])

    def test_transport_does_not_touch_working_dotfiles_index_or_head(self):
        self.exchange('a', {'device': 'a', 'pending': {'extensions': {ONE: {
            'value': 'One', 'version': [10, 'a']}}}})
        refs = subprocess.check_output(['git', f'--git-dir={self.remote}', 'show-ref'], text=True)
        self.assertIn('refs/heads/helium-extensions', refs)
        names = subprocess.check_output(['git', f'--git-dir={self.remote}', 'ls-tree',
                                         '--name-only', 'helium-extensions'], text=True)
        self.assertEqual(names, 'extensions.json\n')
        self.assertFalse((self.root / 'a/transport.git/index').exists())

    def test_inventory_excludes_components_apps_themes_and_stale_entries(self):
        profile = self.root / 'profile'
        profile.mkdir()
        def entry(**fields):
            return dict(location=1, from_webstore=True, manifest=dict(name='One'), **fields)
        rows = {ONE: entry(), TWO: dict(location=5, manifest=dict(name='Built-in')),
                'c'*32: dict(location=4), 'd'*32: {},
                'e'*32: dict(location=1, from_webstore=True, manifest=dict(name='Theme', theme={})),
                'f'*32: dict(location=1, from_webstore=True, manifest=dict(name='App', app={}))}
        (profile / 'Secure Preferences').write_text(json.dumps({'extensions': {'settings': rows}}))
        self.assertEqual(helium.inventory(profile), ({ONE: 'One'}, ['c'*32]))
        rows[ONE] = dict(location=7, from_webstore=False, manifest=dict(
            name='Policy installed', update_url='https://clients2.google.com/service/update2/crx'))
        (profile / 'Secure Preferences').write_text(json.dumps({'extensions': {'settings': rows}}))
        self.assertEqual(helium.inventory(profile)[0], {ONE: 'Policy installed'})
        (profile / 'Secure Preferences').write_text('{}')
        with self.assertRaises(ValueError):
            helium.inventory(profile)

    def test_policy_preserves_other_preferences_and_removes_explicitly(self):
        path = self.root / 'policy.plist'
        original = {'OtherSetting': True, 'ExtensionSettings': {
            TWO: {'installation_mode': 'allowed'}, ONE: {'toolbar_pin': 'default_pinned'}}}
        path.write_bytes(plistlib.dumps(original))
        state = {'device': 'a'}
        helium.record(state, ONE, 'One', now=100)
        self.assertTrue(helium.write_policy(state['pending'], path))
        wanted = plistlib.loads(path.read_bytes())
        self.assertTrue(wanted['OtherSetting'])
        self.assertEqual(wanted['ExtensionSettings'][TWO], original['ExtensionSettings'][TWO])
        self.assertEqual(wanted['ExtensionInstallForcelist'], [ONE])
        self.assertEqual(wanted['ExtensionSettings'][ONE]['toolbar_pin'], 'default_pinned')
        self.assertFalse(helium.write_policy(state['pending'], path))
        helium.record(state, ONE, None, now=200)
        helium.write_policy(state['pending'], path)
        self.assertEqual(plistlib.loads(path.read_bytes())['ExtensionSettings'][ONE],
                         {'toolbar_pin': 'default_pinned', 'installation_mode': 'removed'})
        backup = path.with_name(path.name + '.before-extension-sync')
        self.assertEqual(plistlib.loads(backup.read_bytes()), original)

    def test_rejects_invalid_ids_names_and_documents(self):
        self.assertEqual(helium.extension_id(f'https://chromewebstore.google.com/detail/name/{ONE}'), ONE)
        for value in ('bad', 'https://evil.test/' + ONE, ONE + '/../../file'):
            with self.assertRaises(ValueError):
                helium.extension_id(value)
        for doc in ({'other': {}}, {'extensions': {ONE: {'value': 'bad\nname', 'version': [1, 'a']}}},
                    {'extensions': {ONE: {'value': 'One', 'version': [-1, 'a']}}},
                    {'extensions': {next(iter(helium.MANUAL_EXTENSIONS)): {
                        'value': 'Manual', 'version': [1, 'a']}}}):
            with self.assertRaises(ValueError):
                helium.validate(doc)

    def test_schedule_never_exchanges_or_applies_extensions(self):
        source = (Path.home() / '.local/bin/mac-sync').read_text()
        scheduled = source[source.index('if $check; then'):source.index('\nlog()')]
        self.assertNotIn('helium-extensions', scheduled)
        self.assertNotIn('sudo', scheduled)


if __name__ == '__main__':
    unittest.main()
