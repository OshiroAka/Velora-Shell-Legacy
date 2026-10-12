import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class RailSystemTests(unittest.TestCase):
    def test_continuous_panel_handoff_and_notification_clear(self):
        self.run_fixture("rail-system.qml", "RAIL_SYSTEM")

    def test_level_panels_spam_handoff_and_reduced_motion(self):
        self.run_fixture("rail-levels.qml", "RAIL_LEVELS")

    def run_fixture(self, fixture, marker):
        executable = shutil.which("qs")
        if not executable:
            self.skipTest("Quickshell is required")
        with tempfile.TemporaryDirectory(prefix="velora-rail-system-") as temporary:
            base = Path(temporary)
            for directory in ("components", "features", "services", "assets", "core"):
                shutil.copytree(ROOT / directory, base / directory)
            shutil.copy2(ROOT / "tests/fixtures" / fixture, base / "shell.qml")
            (base / "runtime").mkdir(mode=0o700)
            env = dict(os.environ, QT_QPA_PLATFORM="offscreen", XDG_RUNTIME_DIR=str(base / "runtime"),
                       HOME=str(base), XDG_CONFIG_HOME=str(base / "config"),
                       XDG_CACHE_HOME=str(base / "cache"), XDG_DATA_HOME=str(base / "data"))
            env.pop("WAYLAND_DISPLAY", None)
            result = subprocess.run([executable, "-p", str(base)], env=env,
                                    capture_output=True, text=True, timeout=25)
            output = result.stdout + result.stderr
            self.assertIn(marker + "_OK", output, output)
            self.assertNotIn(marker + "_FAILED", output, output)
            self.assertNotIn("TypeError", output, output)
            self.assertNotIn("ReferenceError", output, output)


if __name__ == "__main__":
    unittest.main()
