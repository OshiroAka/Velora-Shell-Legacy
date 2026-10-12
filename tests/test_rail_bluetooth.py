import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class RailBluetoothTests(unittest.TestCase):
    def test_hover_management_and_pairing_process_with_isolated_devices(self):
        executable = shutil.which("qs")
        if not executable:
            self.skipTest("Quickshell is required")
        with tempfile.TemporaryDirectory(prefix="velora-rail-bluetooth-") as temporary:
            base = Path(temporary)
            for directory in ("components", "features", "services", "assets", "core"):
                shutil.copytree(ROOT / directory, base / directory)
            shutil.copy2(ROOT / "tests/fixtures/rail-bluetooth.qml", base / "shell.qml")
            helper = base / "mock-bluetooth"
            helper.write_text('''#!/usr/bin/env python3
import sys
if sys.argv[2] == "failure":
    print("Failed to pair: org.bluez.Error.AuthenticationFailed", flush=True)
else:
    print("[agent] Confirm passkey 123456 (yes/no): ", end="", flush=True)
    answer = sys.stdin.readline().strip()
    print("Pairing successful" if answer == "yes" else "Failed to pair", flush=True)
''')
            helper.chmod(0o700)
            (base / "runtime").mkdir(mode=0o700)
            env = dict(os.environ, QT_QPA_PLATFORM="offscreen", XDG_RUNTIME_DIR=str(base / "runtime"),
                       HOME=str(base), XDG_CONFIG_HOME=str(base / "config"),
                       XDG_CACHE_HOME=str(base / "cache"), XDG_DATA_HOME=str(base / "data"))
            env.pop("WAYLAND_DISPLAY", None)
            result = subprocess.run([executable, "-p", str(base)], env=env,
                                    capture_output=True, text=True, timeout=25)
            output = result.stdout + result.stderr
            self.assertIn("RAIL_BLUETOOTH_OK", output, output)
            self.assertNotIn("RAIL_BLUETOOTH_FAILED", output, output)
            self.assertNotIn("TypeError", output, output)
            self.assertNotIn("ReferenceError", output, output)
