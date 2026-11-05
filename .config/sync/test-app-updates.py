#!/usr/bin/python3
"""Isolated scheduler and interruption safeguards; no installed apps change."""
import datetime
import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import plistlib
import tempfile
import unittest
from unittest.mock import patch

loader = importlib.machinery.SourceFileLoader('mac_update', str(Path.home() / '.local/bin/mac-update'))
spec = importlib.util.spec_from_loader(loader.name, loader)
updater = importlib.util.module_from_spec(spec)
loader.exec_module(updater)


class UpdatesTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.state = Path(self.temp.name)
        self.patch = patch.object(updater, 'STATE', self.state)
        self.patch.start()
        self.addCleanup(self.patch.stop)

    def test_active_session_needs_unlocked_console_and_recent_input(self):
        session = dict(kCGSSessionOnConsoleKey=True, kCGSSessionUserIDKey=os.getuid())
        for locked, idle, expected in ((False, 1, True), (True, 1, False), (False, 601, False)):
            registry = plistlib.dumps(dict(IOConsoleLocked=locked, IOConsoleUsers=[session]))
            with self.subTest(locked=locked, idle=idle):
                with patch.object(updater.Path, 'stat') as console_stat, patch.object(
                        updater.subprocess, 'check_output',
                        side_effect=[registry, f'"HIDIdleTime" = {idle * 10**9}']):
                    console_stat.return_value.st_uid = os.getuid()
                    self.assertEqual(updater.active_session(), expected)

    def test_other_console_user_is_inactive(self):
        with patch.object(updater.Path, 'stat') as console_stat:
            console_stat.return_value.st_uid = os.getuid() + 1
            with patch.object(updater.subprocess, 'check_output') as check_output:
                self.assertFalse(updater.active_session())
                check_output.assert_not_called()

    def test_running_app_and_binary_are_deferred(self):
        for artifact, process in (({'app': ['Example.app']}, '/Applications/Example.app/Contents/MacOS/Example'),
                                  ({'binary': ['bin/copilot']}, '/opt/homebrew/bin/copilot')):
            self.assertIsNotNone(updater.cask_deferral({'artifacts': [artifact]}, process))
            self.assertIsNone(updater.cask_deferral({'artifacts': [artifact]}, '/bin/fish'))

    def test_installer_and_service_hooks_are_deferred(self):
        for artifact in ({'pkg': ['Example.pkg']}, {'installer': ['x']}, {'preflight': None},
                         {'uninstall': [{'launchctl': ['service']}]},
                         {'uninstall': [{'script': 'uninstall.sh'}]}):
            self.assertIsNotNone(updater.cask_deferral({'artifacts': [artifact]}, ''))

    def test_daily_stamp_and_inactive_desktop_prevent_work(self):
        stamp = self.state / 'last-run.json'
        stamp.write_text(json.dumps(dict(date=datetime.date.today().isoformat())))
        with patch.object(updater, 'command') as command:
            updater.update()
            command.assert_not_called()
            stamp.unlink()
            with patch.object(updater, 'active_session', return_value=False):
                updater.update()
                command.assert_not_called()

    def fake_command(self, args, **kwargs):
        if 'outdated' in args:
            return json.dumps(dict(formulae=[], casks=[dict(name='example', pinned=False)]))
        if 'info' in args:
            return json.dumps(dict(casks=[dict(token='example', artifacts=[dict(app=['Example.app'])])]))
        if 'ps' in args[0]:
            return '/bin/fish'
        return ''

    def test_dry_run_never_upgrades_refreshes_or_writes_stamp(self):
        with patch.object(updater, 'command', side_effect=self.fake_command) as command:
            updater.update(dry_run=True)
        self.assertFalse((self.state / 'last-run.json').exists())
        self.assertFalse(any('update' in c.args[0] or 'upgrade' in c.args[0] for c in command.call_args_list))

    def test_failure_does_not_prevent_other_casks_and_is_recorded(self):
        def fail_upgrade(args, **kwargs):
            if 'upgrade' in args:
                raise RuntimeError('fixture download failure')
            return self.fake_command(args, **kwargs)
        with patch.object(updater, 'command', side_effect=fail_upgrade), patch.object(updater, 'active_session', return_value=True):
            self.assertTrue(updater.update())
        result = json.loads((self.state / 'last-run.json').read_text())
        self.assertEqual(result['status'], 'finished')
        self.assertEqual(result['failures'], ['fixture download failure'])

    def test_offline_refresh_remains_eligible_for_retry(self):
        with patch.object(updater, 'command', side_effect=RuntimeError('offline')), patch.object(updater, 'active_session', return_value=True):
            with self.assertRaises(RuntimeError):
                updater.update()
        self.assertFalse((self.state / 'last-run.json').exists())


if __name__ == '__main__':
    unittest.main()
