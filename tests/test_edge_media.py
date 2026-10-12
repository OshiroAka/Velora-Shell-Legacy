import os
from pathlib import Path
import subprocess
import shutil
import re
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class EdgeMediaTests(unittest.TestCase):
    def run_fixture(self, command):
        with tempfile.TemporaryDirectory(prefix="velora-edge-media-") as temporary:
            env = dict(os.environ, HOME=temporary, XDG_RUNTIME_DIR=temporary,
                       XDG_CONFIG_HOME=temporary + "/config", XDG_CACHE_HOME=temporary + "/cache",
                       XDG_STATE_HOME=temporary + "/state", XDG_DATA_HOME=temporary + "/data",
                       QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software")
            env.pop("WAYLAND_DISPLAY", None)
            result = subprocess.run(command, env=env, capture_output=True, text=True, timeout=30)
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            for error in ("TypeError", "ReferenceError", "Binding loop", "QWARN", "FAILED"):
                self.assertNotIn(error, output, output)
            return output

    def test_transport_search_curved_lyrics_and_icons(self):
        self.run_fixture(["/usr/lib/qt6/bin/qmltestrunner", "-input",
                          str(ROOT / "tests/fixtures/tst_edge_media.qml")])

    def test_audio_waves_lyric_timing_and_capture_demand(self):
        self.run_fixture(["/usr/lib/qt6/bin/qmltestrunner", "-input",
                          str(ROOT / "tests/fixtures/tst_edge_waves.qml")])

    def test_hover_extension_full_height_and_demand_lifecycle(self):
        with tempfile.TemporaryDirectory(prefix="velora-edge-config-") as temporary:
            base = Path(temporary)
            for name in ("components", "core", "features", "services", "assets", "platform"):
                shutil.copytree(ROOT / name, base / name)
            source = (ROOT / "tests/fixtures/edge-media-popover.qml").read_text().replace('"../../', '"./')
            shell = (ROOT / "ShellController.qml").read_text()
            handlers = []
            for name in ("onActiveRailControlChanged", "onQuickPopupTypeChanged"):
                match = re.search(r"function " + name + r"\(\)\s*\{", shell)
                self.assertIsNotNone(match)
                end, depth = match.end(), 1
                while depth:
                    depth += (shell[end] == "{") - (shell[end] == "}")
                    end += 1
                handler = shell[match.start():end].replace("root.", "fixture.").replace("edgePopover.", "edge.")
                for other in ("coffee", "notes", "bluetooth", "notifications", "wifi", "media"):
                    handler = handler.replace(other + "Popover.", "otherPopover.")
                # Avoid colliding with property change signal names.
                handler = handler.replace("function on", "function handle")
                handlers.append(handler)
            source = source.replace("// SHELL_CONTROL_HANDLERS", "\n".join(handlers))
            source = source.replace("fixture.onActiveRailControlChanged()", "fixture.handleActiveRailControlChanged()")
            source = source.replace("fixture.onQuickPopupTypeChanged()", "fixture.handleQuickPopupTypeChanged()")
            (base / "shell.qml").write_text(source)
            output = self.run_fixture(["qs", "-p", str(base)])
            self.assertIn("EDGE_POPOVER_OK", output, output)


if __name__ == "__main__":
    unittest.main()
