#!/usr/bin/env python3
"""Exercise sync installation decisions with isolated Homebrew/app fixtures."""
import importlib.util
import json
import os
from pathlib import Path
import plistlib
import shlex
import subprocess
import sys
import tempfile
import tomllib
import unittest
from unittest.mock import patch

SCRIPT = Path.home() / '.local/bin/mac-sync'
SOURCE = SCRIPT.read_text()
PACKAGES = SOURCE[SOURCE.index('formula_inventory='):SOURCE.index('# Homebrew isolates JupyterLab')]
NUKE = SOURCE[SOURCE.index('if $prune_packages; then'):SOURCE.index('next_stage "Toolchain and container configuration"')]
APPS = SOURCE[SOURCE.index('install_manifest() {'):SOURCE.index('install_manifest "$shared"')]
DESKTOP_CLEANUP = SOURCE[SOURCE.index('cleanup_retired_desktop_tool() {'):SOURCE.index('retire_manifest() {')]
RETIRE = SOURCE[SOURCE.index('retire_manifest() {'):SOURCE.index('# Permanent, idempotent PDF retirement.')]


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

    def test_installer_keeps_sync_enabled_after_partial_setup_in_either_session(self):
        installer = Path.home() / '.config/sync/install-agent.sh'
        template = (Path.home() / '.config/mac-setup/com.fausto.mac-sync.plist').read_text()
        launchctl = self.bin / 'launchctl'
        launchctl.write_text(f'#!{sys.executable}\n' + '''
import json, os, sys
from pathlib import Path
args = sys.argv[1:]
with Path(os.environ['INSTALL_TEST_CALLS']).open('a') as stream:
    stream.write(json.dumps(args) + '\\n')
if args[0] == 'print' and os.environ['INSTALL_TEST_GUI'] == '0':
    sys.exit(1)
''')
        launchctl.chmod(0o755)
        for gui in (False, True):
            for sync_status in (0, 1):
                with self.subTest(gui=gui, sync_status=sync_status):
                    home = self.root / f'install-{gui}-{sync_status}'
                    (home / '.config/git/dotfiles').mkdir(parents=True)
                    files = {
                        '.local/bin/mac-app': '',
                        '.local/bin/mac-sync': f'#!/bin/sh\nexit {sync_status}\n',
                        '.config/mac-setup/apps.tsv': '',
                        '.config/mac-setup/direct/fixture.sh': '',
                        '.config/mac-setup/com.fausto.mac-sync.plist': template,
                        '.config/keymaps/keymap-docs': '',
                        '.config/sync/maintain.sh': '',
                    }
                    for name, content in files.items():
                        path = home / name
                        path.parent.mkdir(parents=True, exist_ok=True)
                        path.write_text(content)
                    calls_path = home / 'launchctl-calls.jsonl'
                    environment = dict(os.environ, HOME=str(home),
                                       PATH=f'{self.bin}:' + os.environ['PATH'],
                                       INSTALL_TEST_CALLS=str(calls_path),
                                       INSTALL_TEST_GUI=str(int(gui)))
                    result = subprocess.run(['/bin/bash', str(installer)], env=environment,
                                            text=True, capture_output=True)
                    self.assertEqual(result.returncode, sync_status, result.stderr)
                    domain = f'{"gui" if gui else "user"}/{os.getuid()}'
                    agent = home / 'Library/LaunchAgents/com.fausto.mac-sync.plist'
                    calls = [json.loads(line) for line in calls_path.read_text().splitlines()]
                    self.assertIn(['bootstrap', domain, str(agent)], calls)
                    self.assertIn(['enable', domain + '/com.fausto.mac-sync'], calls)
                    configuration = plistlib.loads(agent.read_bytes())
                    self.assertEqual(configuration['ProgramArguments'][0], str(home / '.local/bin/mac-sync'))
                    self.assertIn('Background' if not gui else 'Aqua', configuration['LimitLoadToSessionType'])

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


    def test_chatgpt_retirement_preserves_codex_and_computer_use_data(self):
        paths = ['Library/Application Support/com.openai.chat',
                 'Library/Application Support/com.openai.codex',
                 'Library/HTTPStorages/com.openai.sky.CUAService']
        for relative in paths:
            path = self.root / 'home' / relative
            path.mkdir(parents=True)
            (path / 'local-state').write_text('keep local state')
        (self.root / 'retired.tsv').write_text('cask\tchatgpt\tChatGPT\n')
        result = self.run_shell(RETIRE + '\nretire_manifest\nexit "$failed"',
                                'retired="$lock/retired.tsv"\ninstalled_casks=chatgpt\nbrew_prefix="$lock/brew"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(['uninstall', '--cask', 'chatgpt'], self.brew_calls())
        self.assertFalse(any('--zap' in call for call in self.brew_calls()))
        self.assertFalse((self.root / 'home' / paths[0]).exists())
        for relative in paths[1:]:
            self.assertEqual((self.root / 'home' / relative / 'local-state').read_text(), 'keep local state')


class CodexTechnicalTests(unittest.TestCase):
    def test_remote_snapshot_preserves_local_stdio_servers_and_repairs_old_overlay(self):
        source = Path.home() / '.config/sync/codex-technical.py'
        spec = importlib.util.spec_from_file_location('codex_technical_test', source)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory(prefix='codex-technical-test-') as directory:
            root = Path(directory)
            module.CONFIG = root / 'config.toml'
            module.SNAPSHOT = root / 'snapshot.json'
            module.OLD_PREFERENCE_MARKER = root / 'old-marker'
            module.SNAPSHOT.write_text(json.dumps({'plugins': {}, 'mcp_servers': {
                'context7': {'url': 'https://mcp.context7.com/mcp'},
                'remote': {'url': 'https://example.test/mcp'}}}))
            for overlay in ('', 'url = "https://mcp.context7.com/mcp"\n'):
                module.CONFIG.write_text('[mcp_servers.context7]\ncommand = "npx"\n'
                                         'args = ["local-server"]\n' + overlay +
                                         '[mcp_servers.context7.env]\nTOKEN = "local-only"\n'
                                         '[mcp_servers.remote.http_headers]\nAuthorization = "local-only"\n')
                module.apply()
                servers = tomllib.loads(module.CONFIG.read_text())['mcp_servers']
                self.assertNotIn('url', servers['context7'])
                self.assertEqual(servers['context7']['command'], 'npx')
                self.assertEqual(servers['context7']['env'], {'TOKEN': 'local-only'})
                self.assertEqual(servers['remote']['url'], 'https://example.test/mcp')
                self.assertEqual(servers['remote']['http_headers'], {'Authorization': 'local-only'})
                with patch.object(module, 'installed_plugins', return_value={}):
                    captured = module.snapshot_from_config()
                self.assertEqual(captured['mcp_servers']['context7'], {'url': 'https://mcp.context7.com/mcp'})
                self.assertNotIn('env', captured['mcp_servers']['context7'])


class MacAppTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='mac-app-test-')
        self.addCleanup(temporary.cleanup)
        self.home = Path(temporary.name)
        self.setup = self.home / '.config/mac-setup'
        (self.setup / 'machines').mkdir(parents=True)
        (self.setup / 'apps.tsv').write_text('# shared apps\n')
        self.bin = self.home / 'bin'
        self.bin.mkdir()
        (self.bin / 'scutil').write_text('#!/bin/sh\nprintf "%s\\n" "$MAC_APP_TEST_COMPUTER"\n')
        (self.bin / 'git').write_text(f'#!{sys.executable}\n' + '''
import sys
sys.exit(1 if 'diff' in sys.argv else 0)
''')
        sync = self.home / '.local/bin/mac-sync'
        sync.parent.mkdir(parents=True)
        sync.write_text('#!/bin/sh\nexit 0\n')
        for path in [self.bin / 'scutil', self.bin / 'git', sync]:
            path.chmod(0o755)

    def run_app(self, *arguments, computer='Mac Studio'):
        environment = dict(os.environ, HOME=str(self.home),
                           PATH=f'{self.bin}:' + os.environ['PATH'],
                           MAC_APP_TEST_COMPUTER=computer)
        return subprocess.run(['/bin/bash', str(Path.home() / '.local/bin/mac-app'), *arguments],
                              env=environment, text=True, capture_output=True)

    def test_air_local_installs_join_the_common_set(self):
        result = self.run_app('local', 'firefox', computer="Fausto's MacBook Air")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('cask\tfirefox\tfirefox', (self.setup / 'apps.tsv').read_text())
        self.assertFalse((self.setup / 'machines/fausto-s-macbook-air.tsv').exists())

    def test_sharing_a_local_app_preserves_other_apps_and_removes_duplicates(self):
        for host in ('fausto-s-macbook-pro', 'mac-studio'):
            (self.setup / f'machines/{host}.tsv').write_text('cask\tqgis\tQGIS\ncask\tblender\tBlender\n')
        result = self.run_app('share', 'qgis', 'QGIS')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('cask\tqgis\tQGIS', (self.setup / 'apps.tsv').read_text())
        for host in ('fausto-s-macbook-pro', 'mac-studio'):
            self.assertEqual((self.setup / f'machines/{host}.tsv').read_text(), 'cask\tblender\tBlender\n')

    def test_local_refuses_an_app_already_in_the_common_set(self):
        (self.setup / 'apps.tsv').write_text('cask\traycast\tRaycast\n')
        result = self.run_app('local', 'raycast')
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn('already shared', result.stderr)
        self.assertFalse((self.setup / 'machines/mac-studio.tsv').exists())


class AppPreferencesTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='app-preferences-test-')
        self.addCleanup(temporary.cleanup)
        self.home = Path(temporary.name)
        source = Path.home() / '.config/sync/app-preferences.py'
        spec = importlib.util.spec_from_file_location('app_preferences_test', source)
        self.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.module)
        self.module.HOME = self.home
        self.module.APPLICATIONS = (self.home / 'Applications',)
        self.module.PROFILE = self.home / 'profile.json'
        self.manifest = self.home / '.config/mac-setup/apps.tsv'
        self.manifest.parent.mkdir(parents=True)
        self.manifest.write_text('cask\tdemo\tDemo\n')
        (self.home / 'Applications/Demo.app').mkdir(parents=True)
        self.preferences = self.home / 'Library/Preferences/example.demo.plist'
        self.preferences.parent.mkdir(parents=True)
        self.profile = {'preferences': {'example.demo': {
            'application': 'Demo.app', 'settings': {'showMenubar': True}}}}

    def run_profile(self, action, *, process_running=False, application=None):
        self.module.PROFILE.write_text(json.dumps(self.profile))
        arguments = ['app-preferences.py', action] + ([application] if application else [])
        with patch.object(sys, 'argv', arguments), \
             patch.object(self.module.subprocess, 'run') as run:
            run.return_value.returncode = 0 if process_running else 1
            self.module.main()
        return run

    def test_per_app_disable_keeps_local_settings_and_stops_application(self):
        self.preferences.write_bytes(plistlib.dumps({'showMenubar': False}))
        original = self.preferences.read_bytes()
        self.run_profile('disable', application='Demo').assert_not_called()
        self.profile = json.loads(self.module.PROFILE.read_text())
        self.assertEqual(self.profile['disabledApplications'], ['Demo.app'])
        self.run_profile('apply').assert_not_called()
        self.assertEqual(self.preferences.read_bytes(), original)
        self.run_profile('enable', application='Demo.app').assert_not_called()
        self.assertEqual(json.loads(self.module.PROFILE.read_text())['disabledApplications'], [])

    def test_unshared_or_uninstalled_apps_are_untouched(self):
        self.preferences.write_bytes(plistlib.dumps({'showMenubar': False, 'apiKey': 'local-only'}))
        for shared, installed in [(False, True), (True, False)]:
            self.manifest.write_text('cask\tdemo\tDemo\n' if shared else 'cask\tother\tOther\n')
            app = self.home / 'Applications/Demo.app'
            if not installed:
                app.rmdir()
            for action in ('apply', 'capture'):
                with self.subTest(shared=shared, installed=installed, action=action):
                    run = self.run_profile(action)
                    run.assert_not_called()
                    self.assertEqual(json.loads(self.module.PROFILE.read_text()), self.profile)

    def test_apply_writes_only_the_allowlisted_key(self):
        self.preferences.write_bytes(plistlib.dumps({'showMenubar': False, 'apiKey': 'local-only'}))
        run = self.run_profile('apply')
        run.assert_called_once_with(['defaults', 'write', 'example.demo', 'showMenubar', '-bool', 'true'], check=True)

    def test_capture_excludes_credentials_and_wrong_types(self):
        for value in (False, 'wrong-type'):
            self.preferences.write_bytes(plistlib.dumps({'showMenubar': value, 'apiKey': 'local-only'}))
            run = self.run_profile('capture')
            run.assert_not_called()
            captured = json.loads(self.module.PROFILE.read_text())
            expected = value if type(value) is bool else True
            self.assertEqual(captured['preferences']['example.demo']['settings'], {'showMenubar': expected})

    def test_codexbar_merges_local_credentials_without_exporting_them(self):
        (self.home / 'Applications/CodexBar.app').mkdir()
        self.manifest.write_text('cask\tcodexbar\tCodexBar\n')
        config = self.home / '.config/codexbar/config.json'
        config.parent.mkdir(parents=True)
        config.write_text(json.dumps({'version': 1, 'providers': [
            {'id': 'codex', 'enabled': False, 'apiKey': 'local-only'},
            {'id': 'unreviewed-local-provider', 'enabled': True}]}))
        self.profile = {'preferences': {}, 'codexbarProviders': [{'id': 'codex', 'enabled': True}]}
        self.run_profile('apply').assert_not_called()
        self.assertEqual(json.loads(config.read_text())['providers'], [
            {'id': 'codex', 'enabled': True, 'apiKey': 'local-only'},
            {'id': 'unreviewed-local-provider', 'enabled': True}])
        self.run_profile('capture').assert_not_called()
        self.assertEqual(json.loads(self.module.PROFILE.read_text())['codexbarProviders'], [
            {'id': 'codex', 'enabled': True}])

    def test_t3_settings_preserve_local_connections_and_wait_while_running(self):
        (self.home / 'Applications/T3 Code (Nightly).app').mkdir()
        self.manifest.write_text('cask\tt3-code@nightly\tT3 Code (Nightly)\n')
        config = self.home / '.t3/userdata/client-settings.json'
        config.parent.mkdir(parents=True)
        local = {'wordWrap': False, 'browserProfiles': [{'id': 'device-only'}]}
        config.write_text(json.dumps(local))
        self.profile = {'preferences': {}, 't3ClientSettings': {'wordWrap': True}}
        self.run_profile('apply', process_running=True)
        self.assertEqual(json.loads(config.read_text()), local)
        self.run_profile('apply')
        self.assertEqual(json.loads(config.read_text()), dict(local, wordWrap=True))
        local['wordWrap'] = False
        config.write_text(json.dumps(local))
        self.run_profile('capture').assert_not_called()
        self.assertEqual(json.loads(self.module.PROFILE.read_text())['t3ClientSettings'], {'wordWrap': False})


if __name__ == '__main__':
    unittest.main()
