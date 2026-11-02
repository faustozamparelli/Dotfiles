#!/usr/bin/env python3
"""Exercise bcp with temporary Git history; never push or run real maintenance."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

CONFIG = Path.home() / '.config/fish/config.fish'
FUNCTION = 'function bcp' + CONFIG.read_text().split('function bcp', 1)[1].split(
    '# Added by OrbStack:', 1)[0]


class BcpTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='bcp-test-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.env = dict(os.environ, BCP_TEST_ROOT=str(self.root),
                        GIT_CONFIG_GLOBAL='/dev/null', GIT_CONFIG_NOSYSTEM='1')
        self.git('init', '-q')
        self.git('config', 'user.name', 'Fixture')
        self.git('config', 'user.email', 'fixture@example.invalid')
        (self.root / 'tracked').write_text('before')
        self.git('add', 'tracked')
        self.git('commit', '-qm', 'baseline')
        (self.root / 'tracked').write_text('after')

    def git(self, *args):
        return subprocess.run(['git', '-C', str(self.root), *args], env=self.env,
                              check=True, capture_output=True, text=True).stdout.strip()

    def run_bcp(self, **env):
        script = r'''function sync-maintain
    echo maintain >> "$BCP_TEST_ROOT/calls"
    return $BCP_TEST_MAINTAIN
end
function bare
    echo $argv[1] >> "$BCP_TEST_ROOT/calls"
    switch $argv[1]
        case add
            if test $BCP_TEST_ADD -ne 0
                return $BCP_TEST_ADD
            end
        case diff
            if test $BCP_TEST_DIFF -ne 0
                return $BCP_TEST_DIFF
            end
        case commit
            if test $BCP_TEST_COMMIT -ne 0
                return $BCP_TEST_COMMIT
            end
        case push
            return $BCP_TEST_PUSH
    end
    command git -C "$BCP_TEST_ROOT" $argv
end
function python3
    echo report >> "$BCP_TEST_ROOT/calls"
    return $BCP_TEST_REPORT
end
''' + FUNCTION + '\nbcp\n'
        values = {f'BCP_TEST_{name}': '0' for name in
                  ('MAINTAIN', 'ADD', 'DIFF', 'COMMIT', 'PUSH', 'REPORT')}
        values.update({f'BCP_TEST_{key}': str(value) for key, value in env.items()})
        result = subprocess.run([shutil.which('fish'), '--no-config', '-c', script],
                                input='Fixture change\nDetails\n', text=True,
                                capture_output=True, env=dict(self.env, **values))
        calls = (self.root / 'calls').read_text().splitlines()
        return result.returncode, calls

    def test_commit_and_push(self):
        code, calls = self.run_bcp()
        self.assertEqual((code, calls), (0, ['maintain', 'add', 'diff', 'commit', 'push', 'report']))
        self.assertEqual(self.git('log', '-1', '--format=%B'), 'Fixture change\n\nDetails')

    def test_failure_stops_before_push(self):
        for stage in ('MAINTAIN', 'ADD', 'DIFF', 'COMMIT'):
            with self.subTest(stage=stage):
                code, calls = self.run_bcp(**{stage: 7})
                self.assertEqual(code, 7)
                self.assertNotIn('push', calls)
                (self.root / 'calls').unlink()

    def test_clean_tree_retries_push_without_commit(self):
        (self.root / 'tracked').write_text('before')
        self.assertEqual(self.run_bcp(), (0, ['maintain', 'add', 'diff', 'push', 'report']))

    def test_push_failure_is_reported(self):
        code, calls = self.run_bcp(PUSH=8)
        self.assertEqual(code, 8)
        self.assertEqual(calls[-1], 'report')

    def test_report_failure_is_reported(self):
        self.assertEqual(self.run_bcp(REPORT=9)[0], 9)


if __name__ == '__main__':
    unittest.main()
