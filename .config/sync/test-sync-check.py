#!/usr/bin/python3
"""Exercise the scheduled job's no-apply boundary using isolated fixtures."""
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location('check', Path.home() / '.config/sync/mac-sync-check.py')
CHECK = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECK)


class CheckTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name) / 'home'
        self.setup = self.home / '.config/mac-setup'
        (self.setup / 'machines').mkdir(parents=True)
        (self.setup / 'apps.tsv').write_text('cask\tfixture\tFixture\nmas\t123\tStore App\n')
        (self.setup / 'packages.txt').write_text('python\n')
        self.prefix = Path(self.tmp.name) / 'brew'
        self.apps = Path(self.tmp.name) / 'applications'

    def inspect(self):
        return CHECK.inspect(self.home, self.prefix, 'test', self.apps)

    def test_reports_missing_without_creating_apps_or_brew_directories(self):
        self.assertEqual(len(self.inspect()), 3)
        self.assertFalse(self.prefix.exists())
        self.assertFalse(self.apps.exists())

    def test_respects_machine_skip_and_formula_alias_opt_path(self):
        (self.setup / 'machines/test.skip').write_text('mas:123\n')
        (self.prefix / 'Caskroom/fixture').mkdir(parents=True)
        (self.prefix / 'opt/python').mkdir(parents=True)
        self.assertEqual(self.inspect(), [])

    def test_missing_shared_manifest_fails_closed(self):
        (self.setup / 'apps.tsv').unlink()
        with self.assertRaises(ValueError):
            self.inspect()

    def test_scheduled_drift_is_reported_without_failing_the_job(self):
        with patch.object(CHECK.Path, 'home', return_value=self.home), \
             patch.object(CHECK.subprocess, 'check_output', return_value='Test'), \
             patch.object(CHECK, 'inspect', return_value=['Missing Store App']), \
             patch.object(CHECK.sys, 'argv', ['check', '--scheduled', '--quiet']):
            self.assertEqual(CHECK.main(), 0)
            record = self.home / '.local/state/mac-sync/check.json'
            self.assertIn('Missing Store App', record.read_text())
            self.assertEqual(record.stat().st_mode & 0o777, 0o600)

    def test_check_rejects_mutating_options_before_execution(self):
        script = Path.home() / '.local/bin/mac-sync'
        for mode in ('--check', '--scheduled'):
            for option in ('--pull', '--nuke'):
                result = subprocess.run(['/bin/bash', str(script), mode, option], capture_output=True, text=True)
                self.assertEqual(result.returncode, 2)
                self.assertIn('cannot be combined', result.stderr)


if __name__ == '__main__':
    unittest.main()
