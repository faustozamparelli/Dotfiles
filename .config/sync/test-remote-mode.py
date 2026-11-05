#!/usr/bin/python3
"""Run: /usr/bin/python3 ~/.config/sync/test-remote-mode.py (no sudo/network)."""
import contextlib
import importlib.machinery
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch, Mock

source = Path.home() / ".local/bin/remote"
loader = importlib.machinery.SourceFileLoader("remote_mode", str(source))
spec = importlib.util.spec_from_loader(loader.name, loader)
mode = importlib.util.module_from_spec(spec)
loader.exec_module(mode)


class RemoteModeTests(unittest.TestCase):
    def state(self, **changes):
        state = dict(uid=501, gui=True, cli=mode.APP, boot="boot-A", sleep_before=0,
                     deadline=1000, phase="active", connected_by_mode=True,
                     opened_by_mode=True, sleep_on_expiry=True)
        state.update(changes)
        return state

    def test_end_conditions(self):
        cases = [({}, 100, True, "boot-A", 501, None),
                 ({"stop": True}, 100, True, "boot-A", 501, "stopped by user"),
                 ({}, 100, True, "boot-B", 501, "reboot"),
                 ({"phase": "starting"}, 100, True, "boot-A", 501, "interrupted start"),
                 ({}, 1000, True, "boot-A", 501, "session expired"),
                 ({}, 100, False, "boot-A", 501, "power disconnected"),
                 ({}, 100, True, "boot-A", 0, "user logged out or switched"),
                 ({"gui": False}, 100, True, "boot-A", 0, None)]
        for changes, now, ac, boot, uid, expected in cases:
            with self.subTest(changes=changes, ac=ac, boot=boot, uid=uid):
                self.assertEqual(mode.end_reason(self.state(**changes), now, ac, boot, uid), expected)

    def test_restores_owned_vpn_and_gui(self):
        state = self.state()
        with patch.object(mode, "as_user") as command, patch.object(mode, "save"), \
             patch.object(mode, "vpn_state", return_value="Stopped"), \
             patch.object(mode, "app_running", side_effect=[True, False]), \
             patch.object(mode, "set_sleep") as power, patch.object(mode, "STATE") as file:
            mode.restore(state)
            self.assertEqual(command.call_args_list[0].args[1], [mode.APP, "down"])
            self.assertEqual(command.call_count, 2)
            power.assert_called_once_with(0)
            file.unlink.assert_called_once()

    def test_preserves_user_vpn_and_studio_sleep_baseline(self):
        with patch.object(mode, "as_user") as command, patch.object(mode, "save"), \
             patch.object(mode, "set_sleep") as power, patch.object(mode, "STATE") as file:
            mode.restore(self.state(connected_by_mode=False, opened_by_mode=False, sleep_before=1))
            command.assert_not_called()
            power.assert_called_once_with(1)
            file.unlink.assert_called_once()

    def test_failed_disconnect_restores_sleep_and_retains_recovery(self):
        with patch.object(mode, "as_user", side_effect=mode.ModeError("timeout")), \
             patch.object(mode, "set_sleep") as power, patch.object(mode, "STATE") as file:
            with self.assertRaisesRegex(mode.ModeError, "timeout"):
                mode.restore(self.state())
            power.assert_called_once_with(0)
            file.unlink.assert_not_called()

    def test_failed_quit_does_not_repeat_disconnect(self):
        state = self.state()
        with patch.object(mode, "as_user") as command, patch.object(mode, "save"), \
             patch.object(mode, "vpn_state", return_value="Stopped"), \
             patch.object(mode, "app_running", return_value=True), \
             patch.object(mode, "set_sleep"), patch.object(mode, "STATE"):
            with self.assertRaisesRegex(mode.ModeError, "did not quit"):
                mode.restore(state)
            self.assertFalse(state["connected_by_mode"])
            command.reset_mock()
            with self.assertRaises(mode.ModeError):
                mode.restore(state)
            self.assertEqual(command.call_count, 1)
            self.assertIn("osascript", command.call_args.args[1][0])

    def test_power_restore_failure_retains_recovery(self):
        with patch.object(mode, "set_sleep", side_effect=mode.ModeError("pmset failed")), \
             patch.object(mode, "STATE") as file, patch.object(mode, "save"):
            with self.assertRaisesRegex(mode.ModeError, "pmset failed"):
                mode.restore(self.state(connected_by_mode=False, opened_by_mode=False))
            file.unlink.assert_not_called()

    def start_patches(self, stack, ac=True):
        stack.enter_context(patch("builtins.print"))
        stack.enter_context(patch.object(mode, "result"))
        mocks = {}
        values = {"locked": contextlib.nullcontext(), "load": None, "on_ac": ac,
                  "select_cli": (mode.APP, True), "boot_id": "boot-A", "sleep_disabled": 0,
                  "vpn_state": "Stopped", "app_running": False}
        for name, value in values.items():
            mocks[name] = stack.enter_context(patch.object(mode, name, return_value=value))
        stack.enter_context(patch.object(mode.pwd, "getpwuid"))
        stack.enter_context(patch.object(mode.os, "stat", return_value=Mock(st_uid=501)))
        for name in ("save", "install_watchdog", "as_user", "set_sleep", "restore"):
            mocks[name] = stack.enter_context(patch.object(mode, name))
        return mocks

    def test_start_requires_ac_without_mutation(self):
        with contextlib.ExitStack() as stack:
            mocks = self.start_patches(stack, ac=False)
            with self.assertRaisesRegex(mode.ModeError, "power adapter"):
                mode.root_start(501, 12)
            mocks["save"].assert_not_called()
            mocks["install_watchdog"].assert_not_called()
            mocks["as_user"].assert_not_called()
            mocks["set_sleep"].assert_not_called()

    def test_recovery_is_installed_before_vpn_or_power_changes(self):
        with contextlib.ExitStack() as stack:
            mocks = self.start_patches(stack)
            mocks["vpn_state"].side_effect = ["Stopped", "Running"]
            events = []
            for name in ("install_watchdog", "as_user", "set_sleep"):
                mocks[name].side_effect = lambda *a, name=name, **k: events.append(name)
            mode.root_start(501, 12)
            self.assertEqual(events[0], "install_watchdog")
            self.assertEqual(events[-1], "set_sleep")
            up = mocks["as_user"].call_args_list[1].args[1]
            self.assertEqual(up, [mode.APP, "up"])  # Preserve non-default VPN preferences.

    def test_failed_start_rolls_back(self):
        with contextlib.ExitStack() as stack:
            mocks = self.start_patches(stack)
            mocks["as_user"].side_effect = mode.ModeError("cannot connect")
            with self.assertRaisesRegex(mode.ModeError, "cannot connect"):
                mode.root_start(501, 12)
            mocks["restore"].assert_called_once()
            self.assertEqual(mocks["restore"].call_args.args[0]["phase"], "restoring")
            mocks["set_sleep"].assert_not_called()

    def test_unplug_during_start_rolls_back_before_sleep_override(self):
        with contextlib.ExitStack() as stack:
            mocks = self.start_patches(stack)
            mocks["vpn_state"].side_effect = ["Stopped", "Running"]
            mocks["on_ac"].side_effect = [True, False]
            with self.assertRaisesRegex(mode.ModeError, "disconnected during startup"):
                mode.root_start(501, 12)
            mocks["restore"].assert_called_once()
            mocks["set_sleep"].assert_not_called()

    def test_atomic_state_roundtrip(self):
        with tempfile.TemporaryDirectory() as directory:
            with patch.object(mode, "STATE", Path(directory) / "state.json"):
                state = self.state()
                mode.save(state)
                self.assertEqual(mode.load(), state)
                self.assertEqual(mode.STATE.stat().st_mode & 0o777, 0o644)

    def test_duration_units_and_invalid_input(self):
        for value, expected in (("30m", 1800), ("2h", 7200), ("1h30m", 5400),
                                ("1s", 1), ("7d", 604800), ("2", 7200)):
            self.assertEqual(mode.duration(value), expected)
        for value in ("", "0", "0s", "8d", "-1h", "2hours", "5m garbage", "1.5h"):
            with self.subTest(value=value), self.assertRaises(mode.ModeError):
                mode.duration(value)

    def test_expiry_requests_system_sleep_without_hibernation_changes(self):
        state = self.state()
        with patch.object(mode, "sleep_count", return_value=9), \
             patch.object(mode, "save") as save, patch.object(mode, "set_sleep") as power, \
             patch.object(mode, "result"), patch.object(mode, "run") as command:
            mode.begin_sleep(state)
            self.assertEqual(state["phase"], "sleeping")
            self.assertEqual(state["sleep_count_before"], 9)
            save.assert_called_once()
            power.assert_called_once_with(0)
            command.assert_called_once_with(["/usr/bin/pmset", "sleepnow"])

    def test_sleep_observation_restores_desktop_baseline_and_finishes(self):
        state = self.state(phase="sleeping", sleep_before=1, sleep_count_before=9, sleep_requested_at=100)
        with patch.object(mode, "sleep_count", return_value=10), \
             patch.object(mode, "boot_id", return_value="boot-A"), \
             patch.object(mode, "set_sleep") as power, patch.object(mode, "STATE") as file, \
             patch.object(mode, "result") as result:
            self.assertTrue(mode.complete_sleep(state))
            power.assert_called_once_with(1)
            file.unlink.assert_called_once()
            self.assertTrue(result.call_args.args[0])

    def test_sleep_failure_is_visible_and_leaves_no_recovery_loop(self):
        state = self.state(phase="sleeping", sleep_count_before=9, sleep_requested_at=100)
        with patch.object(mode, "sleep_count", return_value=9), \
             patch.object(mode, "boot_id", return_value="boot-A"), \
             patch.object(mode.time, "time", return_value=131), patch.object(mode, "set_sleep") as power, \
             patch.object(mode, "STATE") as file, patch.object(mode, "result") as result, \
             patch.object(mode, "as_user"), patch("builtins.print"):
            self.assertTrue(mode.complete_sleep(state))
            power.assert_called_once_with(0)
            file.unlink.assert_called_once()
            self.assertFalse(result.call_args.args[0])
            self.assertIn("did not enter sleep", result.call_args.args[1])

    def test_reboot_restores_baseline_without_claiming_sleep_was_observed(self):
        state = self.state(phase="sleeping", sleep_count_before=9, sleep_requested_at=100)
        with patch.object(mode, "boot_id", return_value="boot-B"), \
             patch.object(mode, "sleep_count") as counter, patch.object(mode, "set_sleep"), \
             patch.object(mode, "STATE"), patch.object(mode, "result") as result:
            self.assertTrue(mode.complete_sleep(state))
            counter.assert_not_called()
            self.assertIn("reboot interrupted sleep verification", result.call_args.args[1])

    def test_renew_keeps_original_vpn_and_power_snapshot(self):
        state = self.state(sleep_before=0, connected_by_mode=True)
        with contextlib.ExitStack() as stack:
            mocks = self.start_patches(stack)
            mocks["load"].return_value = state
            mocks["vpn_state"].return_value = "Running"
            stack.enter_context(patch.object(mode.time, "time", return_value=100))
            mode.root_start(501, 1800)
            self.assertEqual(state["deadline"], 1900)
            self.assertEqual(state["sleep_before"], 0)
            self.assertTrue(state["connected_by_mode"])
            self.assertTrue(state["sleep_on_expiry"])
            mocks["as_user"].assert_not_called()

    def test_status_exposes_dead_watchdog_vpn_and_sleep_override(self):
        state = self.state(deadline=10**15)
        with patch.object(mode, "load", return_value=state), \
             patch.object(mode, "run", return_value=Mock(returncode=0, stdout="{}")), \
             patch.object(mode, "on_ac", return_value=True), \
             patch.object(mode, "sleep_disabled", return_value=0), \
             patch.object(mode, "vpn_state", return_value="Stopped"), \
             patch.object(mode.os, "getuid", return_value=0), \
             patch.object(mode.socket, "create_connection"), patch("builtins.print") as output:
            self.assertEqual(mode.status(), 1)
            messages = " ".join(str(call.args[0]) for call in output.call_args_list)
            self.assertIn("watchdog is not running", messages)
            self.assertIn("Sleep override is missing", messages)
            self.assertIn("Tailscale is Stopped", messages)

    def test_watchdog_exits_immediately_when_off(self):
        with patch.object(mode, "locked", return_value=contextlib.nullcontext()), \
             patch.object(mode, "load", return_value=None), patch.object(mode.time, "sleep") as sleep, \
             patch.object(mode, "on_ac") as power:
            mode.watch()
            sleep.assert_not_called()
            power.assert_not_called()

    def test_failed_renewal_restores_original_state(self):
        state = self.state()
        with contextlib.ExitStack() as stack:
            mocks = self.start_patches(stack)
            mocks["load"].return_value = state
            mocks["vpn_state"].return_value = "Running"
            mocks["install_watchdog"].side_effect = mode.ModeError("cannot bootstrap")
            with self.assertRaisesRegex(mode.ModeError, "cannot bootstrap"):
                mode.root_start(501, 1800)
            mocks["restore"].assert_called_once_with(state)

    def test_watchdog_retains_expiry_action_across_cleanup_retry(self):
        state = self.state(phase="restoring", end_reason="session expired")
        with patch.object(mode, "locked", side_effect=lambda: contextlib.nullcontext()), \
             patch.object(mode, "load", side_effect=[state, state, None]), \
             patch.object(mode, "on_ac", return_value=True), \
             patch.object(mode, "boot_id", return_value="boot-A"), \
             patch.object(mode, "restore", side_effect=[mode.ModeError("VPN timeout"), None]) as restore, \
             patch.object(mode, "begin_sleep") as sleep, patch.object(mode, "save"), \
             patch.object(mode, "failure"), patch.object(mode.time, "sleep"), \
             patch("builtins.print"):
            mode.watch()
            self.assertEqual(restore.call_count, 2)
            sleep.assert_called_once_with(state)


if __name__ == "__main__":
    unittest.main()
