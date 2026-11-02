#!/usr/bin/env python3
"""Check local extension packaging, idempotency and installation failures."""
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET
import zipfile

spec = importlib.util.spec_from_file_location(
    'installer', Path(__file__).with_name('install-vscode-local.py'))
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='vscode-local-test-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = Path(__file__).with_name('vscode-markdown-preview-wrap')
        self.package = json.loads((self.source / 'package.json').read_text())
        self.home = patch.object(installer.Path, 'home', return_value=self.root)
        self.home.start()
        self.addCleanup(self.home.stop)

    def test_package_has_css_and_correct_identity(self):
        def inspect(args, **kwargs):
            with zipfile.ZipFile(args[2]) as archive:
                self.assertEqual(archive.read('extension/preview.css'),
                                 (self.source / 'preview.css').read_bytes())
                tree = ET.fromstring(archive.read('extension.vsixmanifest'))
                ns = {'v': 'http://schemas.microsoft.com/developer/vsx-schema/2011'}
                identity = tree.find('v:Metadata/v:Identity', ns)
                self.assertEqual(identity.attrib['Id'], self.package['name'])
                ET.fromstring(archive.read('[Content_Types].xml'))
        with patch.object(installer.subprocess, 'run', side_effect=inspect) as run:
            installer.install(self.source, Path('/fixture/code'))
            run.assert_called_once()

    def test_installed_metadata_is_local_and_css_changes_trigger_reinstall(self):
        entry = self.root / '.vscode/extensions/fausto.markdown-preview-wrap-1.0.0'
        entry.mkdir(parents=True)
        package = dict(self.package, __metadata={'installedTimestamp': 123})
        (entry / 'package.json').write_text(json.dumps(package))
        (entry / 'preview.css').write_bytes((self.source / 'preview.css').read_bytes())
        with patch.object(installer.subprocess, 'run') as run:
            installer.install(self.source, Path('/fixture/code'))
            run.assert_not_called()
            (entry / 'preview.css').write_text('outdated')
            installer.install(self.source, Path('/fixture/code'))
            run.assert_called_once()

    def test_install_failure_propagates(self):
        error = subprocess.CalledProcessError(1, 'code')
        with patch.object(installer.subprocess, 'run', side_effect=error):
            with self.assertRaises(subprocess.CalledProcessError):
                installer.install(self.source, Path('/fixture/code'))


if __name__ == '__main__':
    unittest.main()
