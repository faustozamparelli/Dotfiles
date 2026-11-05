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
        self.root = root
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

    def test_existing_display_workspace_and_routing_survive(self):
        custom = SEED.replace('name = "1"', 'name = "Local project"')
        custom = custom.replace('mode = "automatic"', 'mode = "dark"')
        custom = custom.replace('monitorNiriOverrides = []', '')
        custom += '\n[[monitorNiriOverrides]]\nmonitorName = "Local display"\nvisibleContainerCount = 3\n'
        custom = custom.replace('Control+Option+Command+H', 'Control+Option+Command+Z')
        custom = custom.replace('mode = "macOS"', 'mode = "custom"')
        self.target.parent.mkdir()
        self.target.write_text(custom)
        before = tomllib.loads(custom)
        self.assertTrue(self.apply())
        after = tomllib.loads(self.target.read_text())
        for key in ("workspaces", "routing", "monitorNiriOverrides"):
            self.assertEqual(after[key], before[key])
        for key in SYNC["PORTABLE"]:
            self.assertEqual(after[key], tomllib.loads(SEED)[key], key)
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

    def test_capture_shares_current_preferences_without_workspace_or_display_data(self):
        self.apply()
        custom = self.target.read_text().replace('name = "1"', 'name = "Private project"')
        custom = custom.replace('mode = "automatic"', 'mode = "dark"')
        custom = custom.replace('width = 2.0', 'width = 3.0')
        custom = custom.replace('visibleContainerCount = 1', 'visibleContainerCount = 2')
        custom = custom.replace('monitorNiriOverrides = []', '')
        custom += '\n[[monitorNiriOverrides]]\nmonitorName = "Private display"\nvisibleContainerCount = 3\n'
        self.target.write_text(custom)
        self.assertTrue(SYNC["capture_settings"](self.profile, self.target, self.stamp))
        shared = tomllib.loads(self.profile.read_text())
        live = tomllib.loads(custom)
        for key in SYNC["PORTABLE"]:
            self.assertEqual(shared[key], live[key], key)
        self.assertEqual(shared["workspaces"], tomllib.loads(SEED)["workspaces"])
        self.assertEqual(shared["monitorNiriOverrides"], [])
        self.assertFalse(self.apply())
        self.assertEqual(self.target.read_text(), custom)
        self.assertFalse(SYNC["capture_settings"](self.profile, self.target, self.stamp))
        other = self.root / "other/settings.toml"
        other.parent.mkdir()
        other.write_text(SEED)
        self.assertTrue(SYNC["apply_settings"](self.profile, other, self.root / "other/stamp"))
        self.assertEqual(tomllib.loads(other.read_text()), shared)

    def test_capture_does_not_overwrite_unapplied_profile(self):
        self.apply()
        incoming = SEED.replace('mode = "automatic"', 'mode = "dark"')
        self.profile.write_text(incoming)
        with self.assertRaisesRegex(ValueError, "pending"):
            SYNC["capture_settings"](self.profile, self.target, self.stamp)
        self.assertEqual(self.profile.read_text(), incoming)

    def test_capture_waits_for_initial_enrollment(self):
        self.target.parent.mkdir()
        self.target.write_text(SEED.replace('mode = "automatic"', 'mode = "dark"'))
        self.assertFalse(SYNC["capture_settings"](self.profile, self.target, self.stamp))
        self.assertEqual(self.profile.read_text(), SEED)

    def test_empty_rule_array_and_nested_tables_round_trip(self):
        blocks = SYNC["config_blocks"](SEED)
        no_rules = "appRules = []\n" + "\n".join(b[2] for b in blocks if b[0] != "appRules")
        merged = SYNC["merge_settings"](SEED, no_rules)
        self.assertEqual(tomllib.loads(merged)["appRules"], [])
        restored = SYNC["merge_settings"](merged, SEED)
        self.assertEqual(tomllib.loads(restored), tomllib.loads(SEED))

    def test_malformed_live_config_is_not_captured(self):
        self.apply()
        self.target.write_text('[invalid')
        with self.assertRaises(tomllib.TOMLDecodeError):
            SYNC["capture_settings"](self.profile, self.target, self.stamp)
        self.assertEqual(self.profile.read_text(), SEED)

    def test_removed_hotkey_is_not_retained_from_other_mac(self):
        local = SEED + '\n[[hotkeys]]\nbinding = "Option+Z"\nid = "local.old.action"\n'
        self.assertEqual(tomllib.loads(SYNC["merge_settings"](local, SEED))["hotkeys"],
                         tomllib.loads(SEED)["hotkeys"])


if __name__ == "__main__":
    unittest.main()
