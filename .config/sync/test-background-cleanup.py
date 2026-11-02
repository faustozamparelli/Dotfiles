#!/usr/bin/env python3
"""Verify that closed-app cleanup cannot select active or unrelated processes."""
import importlib.util
import os
from pathlib import Path
import signal
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('cleanup',
    Path.home() / '.config/mac-setup/cleanup-orphan-app-data.py')
cleanup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cleanup)
BUNDLE = '/Applications/Beeper Desktop.app/Contents/'
HELPER = BUNDLE + 'Resources/app.asar.unpacked/build/ContactsServer'
CRASH = BUNDLE + 'Frameworks/Electron Framework.framework/Helpers/chrome_crashpad_handler'
UID = os.getuid()


def row(pid, parent, path, uid=UID):
    return f'{pid} {parent} {uid} {path}\n'


class CleanupTests(unittest.TestCase):
    def test_only_closed_owned_reparented_helpers_are_stopped(self):
        processes = row(10, 1, HELPER) + row(11, 1, CRASH)
        processes += row(12, 8, HELPER) + row(13, 1, HELPER, UID + 1)
        processes += row(14, 1, '/Applications/Other.app/Contents/MacOS/ContactsServer')
        with patch.object(cleanup.subprocess, 'check_output', return_value=processes), \
             patch.object(cleanup.os, 'kill') as kill:
            cleanup.cleanup_closed_app_helpers()
            self.assertEqual(kill.call_args_list, [unittest.mock.call(10, signal.SIGTERM),
                                                  unittest.mock.call(11, signal.SIGTERM)])

    def test_open_app_preserves_helpers(self):
        processes = row(10, 1, HELPER) + row(11, 1, BUNDLE + 'MacOS/Beeper Desktop')
        with patch.object(cleanup.subprocess, 'check_output', return_value=processes), \
             patch.object(cleanup.os, 'kill') as kill:
            cleanup.cleanup_closed_app_helpers()
            kill.assert_not_called()

    def test_relaunch_or_pid_reuse_preserves_process(self):
        for current in [row(10, 1, '/unrelated'),
                        row(10, 1, HELPER) + row(11, 1, BUNDLE + 'MacOS/Beeper Desktop')]:
            with self.subTest(current=current), \
                 patch.object(cleanup.subprocess, 'check_output', side_effect=[row(10, 1, HELPER), current]), \
                 patch.object(cleanup.os, 'kill') as kill:
                cleanup.cleanup_closed_app_helpers()
                kill.assert_not_called()

    def test_other_open_apps_are_preserved_and_do_not_protect_beeper(self):
        wispr = '/Applications/Wispr Flow.app/Contents/'
        processes = row(10, 1, HELPER)
        processes += row(11, 1, wispr + 'MacOS/Wispr Flow')
        processes += row(12, 1, wispr + 'Resources/swift-helper-app-dist/Wispr Flow.app/Contents/MacOS/Wispr Flow')
        processes += row(13, 1, '/Applications/CodexBar.app/Contents/MacOS/CodexBar')
        with patch.object(cleanup.subprocess, 'check_output', return_value=processes), \
             patch.object(cleanup.os, 'kill') as kill:
            cleanup.cleanup_closed_app_helpers()
            kill.assert_called_once_with(10, signal.SIGTERM)

    def test_dry_run_and_inspection_failure_cannot_signal(self):
        with patch.object(cleanup.subprocess, 'check_output', return_value=row(10, 1, HELPER)), \
             patch.object(cleanup.os, 'kill') as kill:
            cleanup.cleanup_closed_app_helpers(dry_run=True)
            kill.assert_not_called()
        with patch.object(cleanup.subprocess, 'check_output', side_effect=OSError('inspection unavailable')), \
             patch.object(cleanup.os, 'kill') as kill:
            with self.assertRaises(OSError):
                cleanup.cleanup_closed_app_helpers()
            kill.assert_not_called()


if __name__ == '__main__':
    unittest.main()
