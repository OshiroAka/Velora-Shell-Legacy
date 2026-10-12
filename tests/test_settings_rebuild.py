"""Exercise the real page controls and lifecycle with isolated persistent state."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]

class SettingsRebuildTests(unittest.TestCase):
    def test_pages_controls_and_lifecycle(self):
        executable = shutil.which("qs")
        if not executable:
            self.skipTest("Quickshell unavailable")
        with tempfile.TemporaryDirectory(prefix="velora-settings-rebuild-") as temporary:
            base = Path(temporary)
            for name in ("core", "features", "components", "services", "platform", "assets", "config"):
                (base/name).symlink_to(ROOT/name, target_is_directory=True)
            scripts = base/"scripts"
            scripts.mkdir()
            for path in (ROOT/"scripts").iterdir():
                if not path.is_file():
                    continue
                if path.name == "velora-theme-state":
                    (scripts/path.name).symlink_to(path)
                else:
                    (scripts/path.name).write_text('#!/usr/bin/env python3\nimport sys\nprint("on" if sys.argv[0].endswith("hyprland-blur") else "{}")\n')
                    (scripts/path.name).chmod(0o755)
            (base/"shell.qml").write_text((ROOT/"tests/fixtures/settings-rebuild.qml").read_text().replace('"../../','"./'))
            (base/"runtime").mkdir(mode=0o700)
            env = dict(os.environ, HOME=str(base), QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software", VELORA_VALIDATE="1",
                XDG_CONFIG_HOME=str(base/"user-config"), XDG_DATA_HOME=str(base/"data"), XDG_STATE_HOME=str(base/"state"),
                XDG_CACHE_HOME=str(base/"cache"), XDG_RUNTIME_DIR=str(base/"runtime"))
            env.pop("WAYLAND_DISPLAY",None)
            result = subprocess.run([executable,"-p",str(base)],env=env,text=True,capture_output=True,timeout=25)
            output = result.stdout+result.stderr
            if os.environ.get("VELORA_SETTINGS_TEST_LOG"):
                Path(os.environ["VELORA_SETTINGS_TEST_LOG"]).write_text(output)
            self.assertEqual(result.returncode,0,output)
            self.assertIn("SETTINGS_REBUILD_OK",output)
            self.assertNotIn("SETTINGS_REBUILD_FAILED",output)
            for error in ("TypeError:","ReferenceError:","Binding loop", "is not a function", "Cannot assign"):
                self.assertNotIn(error,output)
            env["VELORA_SETTINGS_RELOAD"] = "1"
            restarted = subprocess.run([executable,"-p",str(base)],env=env,text=True,capture_output=True,timeout=12)
            self.assertEqual(restarted.returncode,0,restarted.stdout+restarted.stderr)
            self.assertIn("SETTINGS_REBUILD_OK reload",restarted.stdout+restarted.stderr)

    def test_backend_transactions_migration_and_demand(self):
        import json
        import re
        executable = shutil.which("qs")
        if not executable:
            self.skipTest("Quickshell unavailable")
        def block(source, marker):
            start=source.index(marker)
            opening=source.index("{",start)
            depth=1; end=opening+1
            while depth:
                depth+=(source[end]=="{")-(source[end]=="}")
                end+=1
            return source[start:end]
        with tempfile.TemporaryDirectory(prefix="velora-settings-backend-") as temporary:
            base=Path(temporary)
            for name in ("core","features","components","services","platform","assets","config"):
                (base/name).symlink_to(ROOT/name,target_is_directory=True)
            scripts=base/"scripts";scripts.mkdir()
            (scripts/"velora-theme-state").symlink_to(ROOT/"scripts/velora-theme-state")
            for name in ("velora-zen-live-apply","velora-zen-theme.py","velora-code-transparency","velora-world-clock-state"):
                (scripts/name).write_text('#!/usr/bin/env python3\nprint("{}")\n')
                (scripts/name).chmod(0o755)
            (scripts/"hyprland-blur").write_text('''import pathlib,sys,time,os
if "set" in sys.argv:
    if sys.argv[-1]=="off":
        print("fixture failure",file=sys.stderr);sys.exit(3)
    time.sleep(.65)
    pathlib.Path(os.environ["XDG_STATE_HOME"]).mkdir(parents=True,exist_ok=True)
    pathlib.Path(os.environ["XDG_STATE_HOME"],"completed-write").write_text("on")
print("on")
''')
            configdir=base/"user-config/velora-shell";configdir.mkdir(parents=True)
            (configdir/"config.json").write_text(json.dumps({"schemaVersion":1,"customAuditKey":"keep","lockPreview":{"character":{"path":"","scale":1.15},"gallery":[{"path":""}]*3}}))
            source=(ROOT/"CompositionController.qml").read_text()
            sync=block(source,'    Timer {\n        id: nativeAppearanceDebounce')+"\n"+block(source,'    Connections {\n        target: config')
            fixture=(ROOT/"tests/fixtures/settings-backend.qml").read_text().replace('"../../','"./').replace('// APPEARANCE_SYNC',sync)
            (base/"shell.qml").write_text(fixture)
            (base/"runtime").mkdir(mode=0o700)
            env=dict(os.environ,HOME=str(base),QT_QPA_PLATFORM="offscreen",QT_QUICK_BACKEND="software",VELORA_VALIDATE="1",XDG_CONFIG_HOME=str(base/"user-config"),XDG_DATA_HOME=str(base/"data"),XDG_STATE_HOME=str(base/"state"),XDG_CACHE_HOME=str(base/"cache"),XDG_RUNTIME_DIR=str(base/"runtime"))
            env.pop("WAYLAND_DISPLAY",None)
            result=subprocess.run([executable,"-p",str(base)],env=env,text=True,capture_output=True,timeout=18)
            output=result.stdout+result.stderr
            self.assertEqual(result.returncode,0,output)
            self.assertIn("SETTINGS_BACKEND_OK",output)
            self.assertNotIn("SETTINGS_BACKEND_FAILED",output)
            for error in ("TypeError:","ReferenceError:","Binding loop","Cannot assign"):
                self.assertNotIn(error,output)
            self.assertEqual((base/"state/completed-write").read_text(),"on")
            persisted=json.loads((configdir/"config.json").read_text())
            self.assertEqual(persisted["customAuditKey"],"keep")

    def test_compact_controls_preview_and_reduced_motion(self):
        executable = shutil.which("qs")
        if not executable:
            self.skipTest("Quickshell unavailable")
        with tempfile.TemporaryDirectory(prefix="velora-settings-controls-") as temporary:
            base = Path(temporary)
            for name in ("core", "components", "features", "platform", "services", "assets", "shaders"):
                (base/name).symlink_to(ROOT/name,target_is_directory=True)
            (base/"shell.qml").write_text((ROOT/"tests/fixtures/settings-controls.qml").read_text().replace('"../../','"./'))
            (base/"runtime").mkdir(mode=0o700)
            env=dict(os.environ,QT_QPA_PLATFORM="offscreen",QT_QUICK_BACKEND="software",VELORA_VALIDATE="1",XDG_RUNTIME_DIR=str(base/"runtime"),XDG_CONFIG_HOME=str(base/"config"),XDG_STATE_HOME=str(base/"state"),XDG_CACHE_HOME=str(base/"cache"))
            env.pop("WAYLAND_DISPLAY",None)
            result=subprocess.run([executable,"-p",str(base)],env=env,text=True,capture_output=True,timeout=10)
            output=result.stdout+result.stderr
            self.assertEqual(result.returncode,0,output)
            self.assertIn("SETTINGS_CONTROLS_OK",output)
            self.assertNotIn("SETTINGS_CONTROLS_FAILED",output)
            for error in ("TypeError:","ReferenceError:","Binding loop","Cannot assign"):
                self.assertNotIn(error,output)

    def test_widget_pointer_keyboard_and_context(self):
        executable = shutil.which("qs")
        if not executable:
            self.skipTest("Quickshell unavailable")
        with tempfile.TemporaryDirectory(prefix="velora-settings-widgets-") as temporary:
            base = Path(temporary)
            for name in ("core", "components", "features", "platform", "services", "assets", "config"):
                (base/name).symlink_to(ROOT/name, target_is_directory=True)
            (base/"scripts").mkdir()
            (base/"scripts/velora-theme-state").symlink_to(ROOT/"scripts/velora-theme-state")
            (base/"shell.qml").write_text((ROOT/"tests/fixtures/settings-widgets.qml").read_text().replace('"../../', '"./'))
            (base/"runtime").mkdir(mode=0o700)
            env = dict(os.environ, HOME=str(base), QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software", VELORA_VALIDATE="1", XDG_RUNTIME_DIR=str(base/"runtime"), XDG_CONFIG_HOME=str(base/"user-config"), XDG_STATE_HOME=str(base/"state"), XDG_CACHE_HOME=str(base/"cache"), XDG_DATA_HOME=str(base/"data"))
            env.pop("WAYLAND_DISPLAY", None)
            result = subprocess.run([executable, "-p", str(base)], env=env, text=True, capture_output=True, timeout=12)
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("SETTINGS_WIDGETS_OK", output)
            for error in ("SETTINGS_WIDGETS_FAILED", "FAIL!", "TypeError:", "ReferenceError:", "Binding loop", "Cannot assign"):
                self.assertNotIn(error, output)
