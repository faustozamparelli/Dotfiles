#!/usr/bin/env python3
"""Verify the Claude app profile: reviewed keys only, additive SSH connections."""
import importlib.util
import io
import json
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

SCRIPT = Path(__file__).with_name('app-preferences.py')
spec = importlib.util.spec_from_file_location('app_preferences', SCRIPT)
prefs = importlib.util.module_from_spec(spec)
spec.loader.exec_module(prefs)

PROFILE = {
    'claudeDesktopPreferences': {'ccRemoteControlDefaultEnabled': True,
                                 'remoteControlExcludedFolders': []},
    'claudeSshConnections': [{'mac': 'air', 'label': 'Air'}, {'mac': 'pro', 'label': 'Pro'},
                             {'mac': 'studio', 'label': 'Studio'}],
}


class ClaudeProfileTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='app-preferences-test-')
        self.addCleanup(temporary.cleanup)
        self.support = Path(temporary.name)
        self.config = self.support / 'claude_desktop_config.json'
        self.ssh = self.support / 'ssh_configs.json'
        self.config.write_text(json.dumps({'coworkUserFilesPath': '/x', 'preferences': {
            'sidebarMode': 'epitaxy', 'remoteControlExcludedFolders': ['/Users/me/Developer']}}))
        self.ssh.write_text(json.dumps({'configs': [
            {'name': 'Mine', 'sshHost': 'me@studio', 'id': 'keep'}], 'trustedHosts': []}))
        for target, value in (('CLAUDE_SUPPORT', self.support), ('machine_name', lambda: 'pro'),
                              ('getpass', SimpleNamespace(getuser=lambda: 'me'))):
            patcher = patch.object(prefs, target, value)
            patcher.start()
            self.addCleanup(patcher.stop)

    def run_sync(self, profile, action='apply', processes=''):
        result = SimpleNamespace(returncode=0, stdout=processes)
        with patch.object(prefs.subprocess, 'run', return_value=result), redirect_stdout(io.StringIO()) as out:
            prefs.sync_claude(profile, action)
        return out.getvalue()

    def test_apply_sets_reviewed_keys_and_adds_missing_connections(self):
        self.run_sync(PROFILE)
        config = json.loads(self.config.read_text())
        self.assertEqual(config['coworkUserFilesPath'], '/x')
        self.assertEqual(config['preferences'], {'sidebarMode': 'epitaxy',
                                                 'remoteControlExcludedFolders': [],
                                                 'ccRemoteControlDefaultEnabled': True})
        ssh = json.loads(self.ssh.read_text())
        self.assertEqual([(c['name'], c['sshHost']) for c in ssh['configs']],
                         [('Mine', 'me@studio'), ('Air', 'me@air')])
        self.assertEqual(ssh['configs'][0]['id'], 'keep')
        self.assertEqual(ssh['trustedHosts'], ['me@air', 'me@studio'])
        self.assertEqual(self.run_sync(PROFILE), '')

    def test_running_app_defers_without_writing(self):
        before = self.config.read_text(), self.ssh.read_text()
        out = self.run_sync(PROFILE, processes='/Applications/Claude.app/Contents/MacOS/Claude\n')
        self.assertIn('deferred', out)
        self.assertEqual((self.config.read_text(), self.ssh.read_text()), before)

    def test_capture_skips_while_app_runs(self):
        profile = json.loads(json.dumps(PROFILE))
        self.run_sync(profile, action='capture',
                      processes='/Applications/Claude.app/Contents/MacOS/Claude\n')
        self.assertEqual(profile, PROFILE)

    def test_unreadable_files_are_never_replaced(self):
        self.config.write_text('{"preferences": {},}')
        self.ssh.write_text('{"configs": {"odd": 1}, "trustedHosts": []}')
        before = self.config.read_text(), self.ssh.read_text()
        self.assertIn('skipped', self.run_sync(PROFILE))
        self.assertEqual((self.config.read_text(), self.ssh.read_text()), before)

    def test_unknown_mac_does_not_seed_connections(self):
        with patch.object(prefs, 'machine_name', lambda: None):
            self.run_sync(PROFILE)
        self.assertEqual(len(json.loads(self.ssh.read_text())['configs']), 1)

    def test_capture_reads_only_reviewed_keys(self):
        profile = json.loads(json.dumps(PROFILE))
        self.run_sync(profile, action='capture')
        self.assertEqual(profile['claudeDesktopPreferences'],
                         {'ccRemoteControlDefaultEnabled': True,
                          'remoteControlExcludedFolders': ['/Users/me/Developer']})


if __name__ == '__main__':
    unittest.main()
