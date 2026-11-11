#!/usr/bin/env python3
"""Verify actionable end-of-run summaries without reading live browser state."""
from contextlib import redirect_stdout
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location('actions', Path(__file__).with_name('manual-actions.py'))
actions = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(actions)


class ManualActionsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        config = self.home / '.config/sync'
        config.mkdir(parents=True)
        (config / 'helium-apps.json').write_text(json.dumps({'apps': [
            {'name': 'Mail', 'url': 'https://mail.example.test/'}]}))
        with patch.object(Path, 'home', return_value=self.home):
            self.extensions = actions.load('helium-extensions')
            self.apps = actions.load('helium-apps')
        self.profile = self.home / 'Library/Application Support/net.imput.helium/Default'
        self.profile.mkdir(parents=True)
        self.prefs = self.profile / 'Secure Preferences'
        self.prefs.write_text(json.dumps({'extensions': {'settings': {}}}))
        self.apps.scan = lambda: []
        self.extensions.read_policy = lambda: {}
        self.modules = {'helium-extensions': self.extensions, 'helium-apps': self.apps}
        self.patches = [patch.object(actions, 'HOME', self.home),
                        patch.object(actions, 'load', side_effect=self.modules.__getitem__)]
        for item in self.patches:
            item.start()
            self.addCleanup(item.stop)

    def test_missing_manual_extension_and_web_apps_are_highlighted(self):
        result = actions.collect()
        self.assertTrue(any('INSTALL TwitchNoSub MANUALLY' in item for item in result))
        self.assertEqual(result[-1], 'INSTALL Mail WEB APP')

    def test_existing_unpacked_extension_is_not_repeated_as_a_task(self):
        folder = self.home / 'custom-extension'
        folder.mkdir()
        (folder / 'manifest.json').write_text('{}')
        identifier = next(iter(self.extensions.MANUAL_EXTENSIONS))
        self.prefs.write_text(json.dumps({'extensions': {'settings': {
            identifier: {'location': 4, 'path': str(folder)}}}}))
        self.assertFalse(any('TwitchNoSub' in item for item in actions.collect()))

    def test_installer_updates_and_failures_persist_until_state_changes(self):
        path = self.home / '.local/state/app-updates/last-run.json'
        path.parent.mkdir(parents=True)
        path.write_text(json.dumps({'date': '2026-11-11', 'failures': ['offline'],
                                   'deferred': ['example: installer/helper needs its own updater or approval',
                                                'other: application or executable is running']}))
        first = actions.collect()
        self.assertEqual(first, actions.collect())
        self.assertTrue(any('mac update' in item for item in first))
        self.assertTrue(any('brew upgrade --cask example' in item for item in first))
        self.assertFalse(any('UPDATE other' in item for item in first))
        path.unlink()
        self.assertFalse(any('UPDATE example' in item for item in actions.collect()))

    def test_failure_summary_has_distinct_heading_and_shareable_log(self):
        output = io.StringIO()
        with redirect_stdout(output):
            actions.report(failed=True, log='/tmp/routine.log')
        self.assertIn('========== ACTION REQUIRED ==========', output.getvalue())
        self.assertIn('/tmp/routine.log', output.getvalue())
        self.assertIn('unresolved check', output.getvalue())


if __name__ == '__main__':
    unittest.main()
