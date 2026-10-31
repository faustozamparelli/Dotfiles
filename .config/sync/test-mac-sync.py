#!/usr/bin/env python3
"""Exercise sync installation decisions with isolated Homebrew/app fixtures."""
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path.home() / '.local/bin/mac-sync'
SOURCE = SCRIPT.read_text()
PACKAGES = SOURCE[SOURCE.index('formula_inventory='):SOURCE.index('# Homebrew isolates JupyterLab')]
NUKE = SOURCE[SOURCE.index('if $prune_packages; then'):SOURCE.index('next_stage "Toolchain and container configuration"')]
APPS = SOURCE[SOURCE.index('install_manifest() {'):SOURCE.index('install_manifest "$shared"')]
DESKTOP_CLEANUP = SOURCE[SOURCE.index('cleanup_retired_desktop_tool() {'):SOURCE.index('retire_manifest() {')]


def formula(name, *, aliases=(), requested=True):
    return {'name': name, 'full_name': name, 'aliases': list(aliases),
            'installed': [{'version': '1.0', 'installed_on_request': requested}]}


class SyncTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='mac-sync-test-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.fixture = self.root / 'brew-fixture.json'
        self.fixture.write_text(json.dumps({'formulae': []}))
        self.calls = self.root / 'calls.jsonl'
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        brew = self.bin / 'brew'
        brew.write_text(f'#!{sys.executable}\n' + '''
import json
import os
from pathlib import Path
import sys
root = Path(os.environ['SYNC_TEST_ROOT'])
args = sys.argv[1:]
with (root / 'calls.jsonl').open('a') as stream:
    stream.write(json.dumps(args) + '\\n')
fixture = root / 'brew-fixture.json'
if args[0] == 'info':
    if (root / 'fail-info').exists():
        sys.exit(1)
    print(fixture.read_text())
elif args[:2] == ['install', '--formula']:
    data = json.loads(fixture.read_text())
    for name in args[2:]:
        data['formulae'].append({'name': name, 'full_name': name, 'aliases': [],
            'installed': [{'installed_on_request': True}]})
    fixture.write_text(json.dumps(data))
elif args[0] == 'tab' and '--no-installed-on-request' in args and (root / 'fail-tab').exists():
    sys.exit(1)
elif args[0] == 'autoremove' and (root / 'fail-autoremove').exists():
    sys.exit(1)
elif args[:2] == ['install', '--cask'] and (root / 'fail-install').exists():
    sys.exit(1)
''')
        brew.chmod(0o755)

    def run_shell(self, code, setup=''):
        environment = dict(os.environ, SYNC_TEST_ROOT=str(self.root),
                           PATH=f'{self.bin}:' + os.environ['PATH'])
        prelude = f'''set -uo pipefail
lock={shlex.quote(str(self.root))}
test_home="$lock/home"
quiet=true
failed=0
log() {{ :; }}
{setup}
'''
        # App lookup stays inside the fixture; no real apps or user files change.
        code = code.replace('"/Applications/', '"$lock/applications/')
        code = code.replace('"/Library/', '"$lock/library/')
        code = code.replace('$HOME', '$test_home')
        return subprocess.run(['/bin/bash', '-c', prelude + code], env=environment,
                              text=True, capture_output=True)

    def brew_calls(self):
        return [json.loads(line) for line in self.calls.read_text().splitlines()] if self.calls.exists() else []

    def test_existing_aliases_need_no_install_or_receipt_changes(self):
        self.fixture.write_text(json.dumps({'formulae': [
            formula('python@3.15', aliases=['python']), formula('fish')]}))
        result = self.run_shell(PACKAGES, 'wanted_packages=(python fish)')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.brew_calls(), [['info', '--json=v2', '--formula', '--installed']])

    def test_install_only_missing_packages_and_refresh_inventory(self):
        self.fixture.write_text(json.dumps({'formulae': [formula('fish')]}))
        result = self.run_shell(PACKAGES, 'wanted_packages=(fish ripgrep)')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([call for call in self.brew_calls() if call[0] == 'install'],
                         [['install', '--formula', 'ripgrep']])
        self.assertIn('ripgrep', (self.root / 'formula-inventory').read_text().splitlines())

    def test_protect_only_packages_installed_as_dependencies(self):
        self.fixture.write_text(json.dumps({'formulae': [
            formula('fish'), formula('ripgrep', requested=False)]}))
        result = self.run_shell(PACKAGES, 'wanted_packages=(fish ripgrep)')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([call for call in self.brew_calls() if call[0] == 'tab'],
                         [['tab', '--formula', '--installed-on-request', 'ripgrep']])
        self.assertFalse(any(call[0] == 'install' for call in self.brew_calls()))

    def test_inventory_failure_cannot_trigger_installation(self):
        (self.root / 'fail-info').touch()
        result = self.run_shell(PACKAGES, 'wanted_packages=(fish)')
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(any(call[0] in {'install', 'tab'} for call in self.brew_calls()))

    def prune(self, wanted='fish', *, setup=''):
        return self.run_shell(PACKAGES + NUKE + '\nexit "$failed"\n',
                              f'wanted_packages=({wanted})\nprune_packages=true\n' + setup)

    def test_nuke_resolves_shared_aliases_and_keeps_dependencies(self):
        self.fixture.write_text(json.dumps({'formulae': [
            formula('python@3.15', aliases=['python']),
            formula('temporary'), formula('dependency', requested=False)]}))
        result = self.prune('python')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([call for call in self.brew_calls() if call[0] == 'tab'],
                         [['tab', '--formula', '--no-installed-on-request', 'temporary']])
        self.assertIn(['autoremove'], self.brew_calls())

    def test_nuke_cleans_orphans_even_without_top_level_extras(self):
        self.fixture.write_text(json.dumps({'formulae': [formula('fish')]}))
        result = self.prune()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(['autoremove'], self.brew_calls())
        self.assertFalse(any(call[0] == 'tab' for call in self.brew_calls()))

    def test_nuke_refuses_removal_after_package_setup_failure(self):
        self.fixture.write_text(json.dumps({'formulae': [formula('fish'), formula('temporary')]}))
        result = self.prune(setup='failed=1')
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(any(call[0] in {'tab', 'autoremove'} for call in self.brew_calls()))

    def test_nuke_restores_protection_when_receipt_change_fails(self):
        self.fixture.write_text(json.dumps({'formulae': [formula('fish'), formula('temporary')]}))
        (self.root / 'fail-tab').touch()
        result = self.prune()
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn(['autoremove'], self.brew_calls())
        self.assertIn(['tab', '--formula', '--installed-on-request', 'temporary'], self.brew_calls())

    def test_nuke_restores_protection_when_autoremove_fails(self):
        self.fixture.write_text(json.dumps({'formulae': [formula('fish'), formula('temporary')]}))
        (self.root / 'fail-autoremove').touch()
        result = self.prune()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(['tab', '--formula', '--installed-on-request', 'temporary'], self.brew_calls())

    def apps(self, rows, *, installed=''):
        manifest = self.root / 'apps.tsv'
        manifest.write_text(rows)
        setup = f'''shared={shlex.quote(str(manifest))}
installed_casks={shlex.quote(installed)}
host=test-mac
setup="$lock"
is_skipped() {{ return 1; }}
'''
        return self.run_shell(APPS + '\ninstall_manifest "$shared"\nexit "$failed"\n', setup)

    def test_existing_unregistered_apps_in_both_locations_are_preserved(self):
        for location in ('applications', 'home/Applications'):
            with self.subTest(location=location):
                app = self.root / location / 'T3 Fixture.app'
                app.mkdir(parents=True)
                result = self.apps('cask\tt3-fixture@nightly\tT3 Fixture\n')
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(self.brew_calls(), [])
                app.rmdir()

    def test_non_app_cask_receipt_is_enough(self):
        result = self.apps('cask\tfont-fixture\tFixture Font\n', installed='font-fixture')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.brew_calls(), [])

    def test_missing_cask_is_installed_without_adoption(self):
        result = self.apps('cask\tfixture-app\tMissing Fixture\n')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.brew_calls(), [['install', '--cask', 'fixture-app']])

    def test_failed_cask_install_is_reported(self):
        (self.root / 'fail-install').touch()
        result = self.apps('cask\tfixture-app\tMissing Fixture\n')
        self.assertNotEqual(result.returncode, 0)

    def test_obsidian_cleanup_preserves_vaults_and_other_app_data(self):
        state = self.root / 'home/Library/Application Support/obsidian'
        vault = self.root / 'home/Documents/Vault/notes.md'
        other = self.root / 'home/Library/Application Support/Other/notes.md'
        state.mkdir(parents=True)
        for path in (vault, other):
            path.parent.mkdir(parents=True)
            path.write_text('keep my notes')
        result = self.run_shell(DESKTOP_CLEANUP + '\ncleanup_retired_desktop_tool obsidian\n')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(state.exists())
        self.assertEqual(vault.read_text(), 'keep my notes')
        self.assertEqual(other.read_text(), 'keep my notes')

    def test_spotify_cleanup_is_idempotent_and_preserves_browser_data(self):
        cache = self.root / 'home/Library/Caches/com.spotify.client'
        browser = self.root / 'home/Library/Application Support/Helium/profile'
        cache.mkdir(parents=True)
        browser.parent.mkdir(parents=True)
        browser.write_text('keep signed-in browser')
        result = self.run_shell(DESKTOP_CLEANUP + '''
cleanup_retired_desktop_tool spotify || exit 1
cleanup_retired_desktop_tool spotify
''')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(cache.exists())
        self.assertEqual(browser.read_text(), 'keep signed-in browser')

    def test_helper_authorization_failure_preserves_data_and_reports_failure(self):
        helper = self.root / 'library/LaunchDaemons/com.kamenlevi.maghue.helper.plist'
        helper.parent.mkdir(parents=True)
        helper.write_text('system helper')
        prefs = self.root / 'home/Library/Preferences/com.kamenlevi.MagHue.plist'
        prefs.parent.mkdir(parents=True)
        prefs.write_text('keep until helper can be stopped')
        for name in ('sudo', 'launchctl'):
            command = self.bin / name
            command.write_text('#!/bin/sh\nexit 1\n')
            command.chmod(0o755)
        result = self.run_shell(DESKTOP_CLEANUP + '\ncleanup_retired_desktop_tool maghue\n')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('sudo -v', result.stderr)
        self.assertTrue(helper.exists())
        self.assertTrue(prefs.exists())


if __name__ == '__main__':
    unittest.main()
