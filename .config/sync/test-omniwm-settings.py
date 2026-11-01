#!/usr/bin/env python3
"""Check portable OmniWM deployment without touching live app settings."""

from pathlib import Path
import runpy
import tempfile
import tomllib
import unittest

SYNC = runpy.run_path(str(Path(__file__).with_name("omniwm-settings.py")))
SEED = (Path.home() / ".config/omniwm/shared-settings.toml").read_text()


class OmniWMSettingsTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        self.profile = root / "shared.toml"
        self.profile.write_text(SEED)
        self.target = root / "local/settings.toml"
        self.stamp = root / "state/revision"

    def apply(self):
        return SYNC["apply_settings"](self.profile, self.target, self.stamp)

    def test_first_install_seeds_complete_config(self):
        self.assertTrue(self.apply())
        self.assertEqual(tomllib.loads(self.target.read_text()), tomllib.loads(SEED))
        self.assertFalse(self.apply())

    def test_existing_display_workspace_and_unrelated_preferences_survive(self):
        custom = SEED.replace('name = "1"', 'name = "Local project"')
        custom = custom.replace('mode = "automatic"', 'mode = "dark"')
        custom = custom.replace('monitorNiriOverrides = []', '')
        custom += '\n[[monitorNiriOverrides]]\nmonitorName = "Local display"\nvisibleContainerCount = 3\n'
        custom = custom.replace('Control+Option+Command+H', 'Control+Option+Command+Z')
        self.target.parent.mkdir()
        self.target.write_text(custom)
        before = tomllib.loads(custom)
        self.assertTrue(self.apply())
        after = tomllib.loads(self.target.read_text())
        for key in ("workspaces", "appearance", "monitorNiriOverrides"):
            self.assertEqual(after[key], before[key])
        self.assertEqual(after["hotkeys"], tomllib.loads(SEED)["hotkeys"])
        self.assertEqual(self.target.with_suffix(".toml.before-sync").read_text(), custom)

    def test_local_mode_change_is_not_reset_by_hourly_sync(self):
        self.apply()
        changed = self.target.read_text().replace('visibleContainerCount = 1', 'visibleContainerCount = 2')
        self.target.write_text(changed)
        self.assertFalse(self.apply())
        self.assertEqual(self.target.read_text(), changed)

    def test_new_profile_revision_updates_hotkeys(self):
        self.apply()
        self.profile.write_text(SEED.replace('Control+Option+Command+H', 'Control+Option+Command+Z'))
        self.assertTrue(self.apply())
        bindings = {h["id"]: h["binding"] for h in tomllib.loads(self.target.read_text())["hotkeys"]}
        self.assertEqual(bindings["focus.left"], "Control+Option+Command+Z")

    def test_invalid_existing_config_is_not_overwritten(self):
        self.target.parent.mkdir()
        self.target.write_text('[invalid')
        with self.assertRaises(tomllib.TOMLDecodeError):
            self.apply()
        self.assertEqual(self.target.read_text(), '[invalid')
        self.assertFalse(self.stamp.exists())

    def test_other_schema_is_not_downgraded(self):
        self.target.parent.mkdir()
        custom = SEED.replace('schemaVersion = 4', 'schemaVersion = 5')
        self.target.write_text(custom)
        with self.assertRaises(ValueError):
            self.apply()
        self.assertEqual(self.target.read_text(), custom)


if __name__ == "__main__":
    unittest.main()
