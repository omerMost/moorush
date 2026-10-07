#!/usr/bin/env python3
"""Functional CLI tests using fake ADB and clock; no phone changes."""
import contextlib
import io
import json
from pathlib import Path
import runpy
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "android_soak.py"

class Clock:
    def __init__(self):
        self.elapsed = 0.0
    def time(self):
        return 1000.0 + self.elapsed
    def monotonic(self):
        return self.elapsed
    def sleep(self, seconds):
        self.elapsed += seconds

class SoakCLITest(unittest.TestCase):
    def collect(self, scenario):
        clock = Clock()
        failures = 0
        calls = []
        def fake_run(argv, **kwargs):
            nonlocal failures
            command = argv[3:]
            calls.append(command)
            if command[:2] == ["shell", "pidof"]:
                payload = "99\n" if scenario == "pid_changed" and clock.elapsed >= 30 else "42\n"
            elif command[0] == "logcat":
                if scenario == "reconnect" and failures == 0:
                    failures += 1
                    raise subprocess.CalledProcessError(1, argv, stderr=b"device offline")
                lines = [
                    f"   {1000 + second:.3f} 42 42 I godot : MOO_PERF fps=60.0 frame_p95_ms=16.67 draw_cpu_ms=8.0"
                    for second in range(5, 31, 5) if second <= clock.elapsed
                ]
                if scenario == "paused" and clock.elapsed >= 18:
                    lines += [
                        "   1015.000 42 42 I godot : MOO_LIFECYCLE suspended=true menu_paused=false slot=1",
                        "   1018.000 42 42 I godot : MOO_LIFECYCLE suspended=false menu_paused=false slot=1",
                    ]
                payload = "\n".join(lines) + "\n"
            elif command == ["shell", "dumpsys", "battery"]:
                payload = "  level: 82\n  temperature: 315\n"
            elif command == ["shell", "dumpsys", "window"]:
                payload = "  mCurrentFocus=Window{123 u0 com.omer.moorush/com.godot.game.GodotAppLauncher}\n"
            else:
                raise AssertionError(f"Unexpected device command: {command}")
            return subprocess.CompletedProcess(argv, 0, stdout=payload.encode(), stderr=b"")
        with tempfile.TemporaryDirectory(prefix="soak-cli-fixture-", dir=ROOT / "build") as directory:
            output = io.StringIO()
            argv = [str(SCRIPT), "--adb", "fake-adb", "--serial", "TEST", "--seconds", "30", "--output", directory]
            error = None
            with patch.object(sys, "argv", argv), patch("subprocess.run", side_effect=fake_run), patch("time.time", clock.time), patch("time.monotonic", clock.monotonic), patch("time.sleep", clock.sleep), contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
                try:
                    runpy.run_path(str(SCRIPT), run_name="__main__")
                except SystemExit as exc:
                    error = str(exc)
            summary = json.loads((Path(directory) / "summary.json").read_text())
            return summary, error, calls, output.getvalue()

    def test_complete_gameplay_parses_indented_actual_perf_lines(self):
        summary, error, calls, output = self.collect("complete")
        self.assertIsNone(error, output)
        self.assertTrue(summary["completed"])
        self.assertTrue(summary["valid_gameplay"])
        self.assertEqual(summary["sample_count"], 6)
        self.assertEqual(summary["elapsed_s"], 30.0)
        self.assertEqual(summary["overall"]["fps"], 60.0)
        self.assertEqual(summary["overall"]["frame_p95_ms"], 16.67)
        self.assertEqual(summary["overall"]["draw_cpu_ms"], 8.0)
        self.assertTrue(all(row["game_focused"] for row in summary["checkpoints"]))
        self.assertEqual(summary["checkpoints"][-1]["battery_temp_c"], 31.5)

    def test_midrun_lifecycle_pause_rejects_even_focused_checkpoints(self):
        summary, error, calls, output = self.collect("paused")
        self.assertTrue(summary["completed"])
        self.assertTrue(all(row["game_focused"] for row in summary["checkpoints"]))
        self.assertEqual(summary["sample_count"], 6)
        self.assertFalse(summary["valid_gameplay"], "Transient lifecycle pause cannot count as continuous gameplay")
        self.assertEqual(len(summary["app_pauses"]), 1)
        self.assertIsNotNone(error)

    def test_transient_adb_failure_is_retried_and_recorded(self):
        summary, error, calls, output = self.collect("reconnect")
        self.assertIsNone(error, output)
        self.assertTrue(summary["completed"])
        self.assertTrue(summary["valid_gameplay"])
        self.assertEqual(summary["sample_count"], 6)
        self.assertEqual(len(summary["reconnects"]), 1)
        self.assertEqual(summary["reconnects"][0]["attempt"], 1)
        self.assertEqual(summary["reconnects"][0]["command"][0], "logcat")
        self.assertGreaterEqual(sum(cmd[0] == "logcat" for cmd in calls), 3)

    def test_changed_process_aborts_collection(self):
        summary, error, calls, output = self.collect("pid_changed")
        self.assertFalse(summary["completed"])
        self.assertFalse(summary["valid_gameplay"])
        self.assertIn("process changed", summary["failure"])
        self.assertIsNotNone(error)
        self.assertEqual(summary["pid"], "42")

if __name__ == "__main__":
    unittest.main(verbosity=2)
