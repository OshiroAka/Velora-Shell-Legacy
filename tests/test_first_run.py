import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class FirstRunTests(unittest.TestCase):
    def test_configuration_and_profiles_initialize_with_only_public_assets(self):
        runtime = Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share") / "velora-shell/runtime/quickshell/bin/qs"
        executable = str(runtime) if runtime.is_file() else shutil.which("qs")
        if not executable:
            self.skipTest("Quickshell is required for the first-run integration test")
        with tempfile.TemporaryDirectory(prefix="velora-first-run-") as temporary:
            home = Path(temporary)
            checkout = home / "source"
            checkout.mkdir()
            for directory in ("core", "services", "scripts", "config", "assets", "features"):
                shutil.copytree(ROOT / directory, checkout / directory)
            shutil.copy2(ROOT / "tests/fixtures/first-run.qml", checkout / "shell.qml")
            runtime_dir = home / "runtime"
            runtime_dir.mkdir(mode=0o700)
            env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home / "config"),
                       XDG_DATA_HOME=str(home / "data"), XDG_STATE_HOME=str(home / "state"),
                       XDG_CACHE_HOME=str(home / "cache"), XDG_RUNTIME_DIR=str(runtime_dir),
                       QT_QPA_PLATFORM="offscreen", PYTHONDONTWRITEBYTECODE="1")
            env.pop("WAYLAND_DISPLAY", None)
            env.pop("QML_IMPORT_PATH", None)
            subprocess.run([str(checkout / "scripts/init-config")], env=env, check=True)
            result = subprocess.run([executable, "-p", str(checkout)], env=env,
                                    capture_output=True, text=True, timeout=15)
            self.assertIn("VELORA_FIRST_RUN_READY", result.stdout + result.stderr)
            self.assertNotIn("TypeError", result.stdout + result.stderr)
            self.assertNotIn("Unable to assign [undefined]", result.stdout + result.stderr)
            index = json.loads((home / "config/velora-shell/profiles.json").read_text())
            self.assertEqual(len(index["profiles"]), 1)
            self.assertEqual(index["profiles"][0]["composition"]["character"]["path"], "")
