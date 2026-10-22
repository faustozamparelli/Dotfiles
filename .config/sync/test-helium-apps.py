#!/usr/bin/env python3
"""Verify shared web-app capture and reminders at the end of sync/commit."""
import importlib.util
import io
import json
import os
import plistlib
import shutil
import subprocess
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

SCRIPT = Path(__file__).with_name('helium-apps.py')
spec = importlib.util.spec_from_file_location('helium_apps', SCRIPT)
helium = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helium)
ONE = {'name': 'Mail', 'url': 'https://mail.example.test/'}
TWO = {'name': 'Courses', 'url': 'https://courses.example.test/my/courses.php'}


class HeliumAppsTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='helium-apps-test-')
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.config = self.root / '.config/sync'
        self.config.mkdir(parents=True)
        shutil.copyfile(SCRIPT, self.config / 'helium-apps.py')
        self.manifest = self.config / 'helium-apps.json'
        self.manifest.write_text(json.dumps({'apps': [ONE, TWO]}))
        self.bundles = self.root / 'Applications/Chromium Apps.localized'
        self.env = dict(os.environ, HOME=str(self.root))

    def app(self, app=ONE, *, name=None, domain=helium.DOMAIN):
        name = name or app['name']
        contents = self.bundles / f'{name}.app/Contents'
        contents.mkdir(parents=True)
        (contents / 'Info.plist').write_bytes(plistlib.dumps({
            'CrBundleIdentifier': domain, 'CrAppModeShortcutName': name,
            'CrAppModeShortcutURL': app['url'],
            'CrAppModeUserDataDir': '/must/not/read/browser/profile',
        }))

    def report(self):
        output = io.StringIO()
        with patch.object(helium, 'HOME', self.root), \
                patch.object(helium, 'MANIFEST', self.manifest), redirect_stdout(output):
            helium.report()
        return output.getvalue()

    def test_scan_only_reads_helium_bundle_metadata(self):
        self.app()
        self.app(TWO, domain='com.google.Chrome')
        self.assertEqual(helium.scan([self.bundles]), [ONE])

    def test_reports_only_missing_app_in_exact_format(self):
        self.app()
        self.assertEqual(self.report(), 'INSTALL Courses WEB APP\n')
        self.app(TWO)
        self.assertEqual(self.report(), '')

    def test_renamed_local_app_counts_as_installed_by_url(self):
        self.app(name='My mail')
        self.assertEqual(self.report(), 'INSTALL Courses WEB APP\n')

    def test_multiple_launchers_for_same_url_do_not_cause_false_reminders(self):
        self.app()
        self.app(name='Another Mail')
        self.assertEqual(self.report(), 'INSTALL Courses WEB APP\n')

    def test_same_app_in_another_browser_does_not_count(self):
        self.app(domain='com.google.Chrome')
        self.assertEqual(self.report(), 'INSTALL Courses WEB APP\nINSTALL Mail WEB APP\n')

    def test_capture_preserves_apps_missing_on_this_mac(self):
        self.app()
        with patch.object(helium, 'HOME', self.root), \
                patch.object(helium, 'MANIFEST', self.manifest), redirect_stdout(io.StringIO()):
            helium.capture()
        self.assertEqual(json.loads(self.manifest.read_text()), {'apps': [TWO, ONE]})

    def test_report_is_read_only_and_repeats_until_app_is_installed(self):
        before = self.manifest.read_bytes()
        self.assertEqual(self.report(), self.report())
        self.assertEqual(self.manifest.read_bytes(), before)
        self.assertFalse((self.root / 'Library').exists())

    def test_rejects_credentials_callback_parameters_duplicates_and_non_https(self):
        for url in ['http://example.test/', 'https://user:password@example.test/',
                    'https://example.test/#token', 'https://example.test/?access_token=private',
                    'https://example.test/?code=private', 'file:///tmp/app',
                    'https://example.test/\nprivate']:
            with self.subTest(url=url), self.assertRaises(ValueError):
                helium.validate([dict(ONE, url=url)])
        with self.assertRaises(ValueError):
            helium.validate([ONE, ONE])

    def sync_finish(self, *, deferred=False, quiet=False, failed=0):
        source = (Path.home() / '.local/bin/mac-sync').read_text()
        finish = source[source.index('next_stage "Finished"'):]
        prelude = f'''set -uo pipefail
failed={failed}
timing=false
quiet={'true' if quiet else 'false'}
host=fixture
next_stage() {{ :; }}
log() {{ $quiet || echo "$*"; }}
'''
        env = dict(self.env, MAC_SYNC_DEFER_WEB_APP_REPORT='1' if deferred else '0')
        return subprocess.run(['/bin/bash', '-c', prelude + finish], check=False, env=env,
                              text=True, capture_output=True)

    def test_mac_sync_reminders_are_last_even_with_quiet_or_failed_sync(self):
        self.app()
        for quiet, failed in [(False, 0), (True, 0), (False, 1)]:
            with self.subTest(quiet=quiet, failed=failed):
                result = self.sync_finish(quiet=quiet, failed=failed)
                self.assertEqual(result.returncode, failed, result.stderr)
                self.assertEqual(result.stdout.splitlines()[-1], 'INSTALL Courses WEB APP')
                self.assertEqual(result.stdout.count('INSTALL Courses WEB APP'), 1)

    def test_mac_sync_defers_nested_reminders(self):
        result = self.sync_finish(deferred=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn('INSTALL ', result.stdout)

    @unittest.skipUnless(shutil.which('fish'), 'Fish is not installed')
    def test_bcp_reports_once_after_push_and_preserves_push_failures(self):
        self.app()
        source = (Path.home() / '.config/fish/config.fish').read_text()
        bcp = source[source.index('function bcp '):source.index('# Added by OrbStack')]
        for push_status in (0, 7):
            with self.subTest(push_status=push_status):
                stubs = f'''
function sync-maintain
    test "$MAC_SYNC_DEFER_WEB_APP_REPORT" = 1; or return 1
    echo maintenance
end
function bare
    echo "bare $argv"
    if test "$argv[1]" = push
        return {push_status}
    end
end
'''
                result = subprocess.run(['fish', '--no-config', '-c', stubs + bcp + '\nbcp'],
                                        check=False, env=self.env, input='\n\n', text=True, capture_output=True)
                self.assertEqual(result.returncode, push_status, result.stderr)
                self.assertEqual(result.stdout.splitlines()[-2:],
                                 ['bare push', 'INSTALL Courses WEB APP'])
                self.assertEqual(result.stdout.count('INSTALL Courses WEB APP'), 1)


if __name__ == '__main__':
    unittest.main()
