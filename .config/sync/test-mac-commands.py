#!/usr/bin/env python3
"""Verify bundle boundaries without pulling, installing, publishing or updating."""
import importlib.machinery
import importlib.util
import io
from pathlib import Path
import tempfile
import unittest
from contextlib import redirect_stdout
from unittest.mock import patch

LOADER = importlib.machinery.SourceFileLoader('mac_commands', str(Path.home() / '.local/bin/mac'))
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
mac = importlib.util.module_from_spec(SPEC)
LOADER.exec_module(mac)


class MacCommandsTests(unittest.TestCase):
    def action(self, action, results):
        with patch.object(mac.sys, 'argv', ['mac', action]), patch.object(mac, 'run', side_effect=results) as run:
            result = mac.main()
        return result, [call.args[0] for call in run.call_args_list]

    def test_sync_refuses_dirty_or_staged_dotfiles_before_pulling(self):
        for results in ([1], [0, 1]):
            code, calls = self.action('sync', results)
            self.assertEqual(code, 1)
            self.assertFalse(any('pull' in call for call in calls))

    def test_failed_pull_never_applies_checkout(self):
        code, calls = self.action('sync', [0, 0, 7])
        self.assertEqual(code, 1)
        self.assertEqual(calls[-1][-2:], ['pull', '--ff-only'])

    def test_sync_pulls_once_then_applies_and_propagates_failure(self):
        code, calls = self.action('sync', [0, 0, 0, 9])
        self.assertEqual(code, 9)
        self.assertEqual(calls[-1], [mac.BIN / 'mac-sync', '--no-pull'])

    def test_save_reuses_bcp_and_update_reuses_existing_safeguards(self):
        self.assertEqual(self.action('save', [5]), (5, [['/opt/homebrew/bin/fish', '-c', 'bcp']]))
        self.assertEqual(self.action('update', [6]), (6, [[mac.BIN / 'mac-update', '--now']]))

    def test_unknown_command_does_not_run_anything(self):
        code, calls = self.action('unknown', [])
        self.assertEqual((code, calls), (2, []))

    def test_failed_bundle_logs_progress_partial_prompt_and_final_actions(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            config = home / '.config/sync'
            config.mkdir(parents=True)
            (config / 'manual-actions.py').write_text(
                "def report(failed=False, log=None):\n    print('ACTION REQUIRED', failed, log)\n")
            child = home / 'fixture.py'
            child.write_text("import sys\nprint('progress')\nprint('prompt',end='',flush=True)\nsys.exit(7)\n")
            output = io.BytesIO()
            stream = io.TextIOWrapper(output)
            with patch.object(mac, 'HOME', home), patch.object(mac, '__file__', str(child)), \
                    patch.object(mac.sys, 'argv', ['mac', 'save']), redirect_stdout(stream):
                self.assertEqual(mac.bundle(), 7)
            stream.flush()
            result = output.getvalue().decode()
            self.assertIn('prompt', result)
            self.assertIn('ACTION REQUIRED True', result)
            self.assertEqual((home / 'Library/Logs/mac-routines/save.log').read_text(), result)


if __name__ == '__main__':
    unittest.main()
