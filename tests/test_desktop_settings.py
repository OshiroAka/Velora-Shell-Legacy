import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class DesktopSettingsTests(unittest.TestCase):
    def test_master_switches_and_wallpaper_controls_persist_without_changing_widget_choices(self):
        runtime = Path.home() / ".local/share/velora-shell/runtime/quickshell/bin/qs"
        executable = str(runtime) if runtime.is_file() else shutil.which("qs")
        if not executable:
            self.skipTest("Quickshell is required")
        with tempfile.TemporaryDirectory(prefix="velora-desktop-settings-") as temporary:
            base = Path(temporary)
            for directory in ("core", "config"):
                shutil.copytree(ROOT / directory, base / directory)
            shutil.copy2(ROOT / "tests/fixtures/desktop-settings.qml", base / "shell.qml")
            (base / "user-config/velora-shell").mkdir(parents=True)
            (base / "runtime").mkdir(mode=0o700)
            env = dict(os.environ, HOME=str(base), XDG_CONFIG_HOME=str(base / "user-config"),
                       XDG_DATA_HOME=str(base / "data"), XDG_CACHE_HOME=str(base / "cache"),
                       XDG_RUNTIME_DIR=str(base / "runtime"), QT_QPA_PLATFORM="offscreen")
            env.pop("WAYLAND_DISPLAY", None)
            for reload in ("0", "1"):
                env["VELORA_SETTINGS_RELOAD"] = reload
                result = subprocess.run([executable, "-p", str(base)], env=env,
                                        capture_output=True, text=True, timeout=12)
                output = result.stdout + result.stderr
                self.assertEqual(result.returncode, 0, output)
                self.assertIn("DESKTOP_SETTINGS_OK", output)
                self.assertNotIn("DESKTOP_SETTINGS_FAILED", output)
