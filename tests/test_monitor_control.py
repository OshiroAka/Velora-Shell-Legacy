import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/velora-monitor-control"


class MonitorControlTests(unittest.TestCase):
    def test_mirror_confirm_and_revert_with_fake_hyprland(self):
        with tempfile.TemporaryDirectory(prefix="velora-monitor-") as temporary:
            base = Path(temporary)
            fake = base / "hyprctl"
            fake.write_text('''#!/usr/bin/env python3
import json,os,sys
from pathlib import Path
if sys.argv[1:4] == ["-j", "monitors", "all"]:
    print(json.dumps([
        {"name":"eDP-1","width":1920,"height":1200,"refreshRate":60,"x":0,"y":0,"scale":1,"availableModes":["1920x1200@60.00Hz"],"mirrorOf":"none"},
        {"name":"HDMI-A-1","width":1920,"height":1080,"refreshRate":60,"x":1920,"y":0,"scale":1,"availableModes":["1920x1080@60.00Hz"],"mirrorOf":"none"}]))
elif sys.argv[1:3] == ["keyword", "monitor"]:
    with open(os.environ["MONITOR_LOG"], "a") as stream: stream.write(sys.argv[3] + "\\n")
    print("ok")
else: sys.exit(2)
''')
            fake.chmod(0o700)
            log = base / "commands.log"
            env = dict(os.environ, PATH=str(base) + os.pathsep + os.environ["PATH"],
                       XDG_RUNTIME_DIR=str(base), MONITOR_LOG=str(log))

            def run(*args):
                return subprocess.run([str(SCRIPT), *args], env=env, text=True,
                                      capture_output=True, timeout=8, check=True).stdout.strip()

            token = run("apply", "mirror", "eDP-1", "1920x1200@60.00", "1.25")
            self.assertTrue(token.startswith("monitor-"))
            self.assertIn("HDMI-A-1,preferred,auto,1,mirror,eDP-1", log.read_text())
            run("revert", token)
            self.assertIn("HDMI-A-1,1920x1080@60.00,1920x0,1", log.read_text())
            token = run("apply", "extend", "eDP-1", "1920x1200@60.00", "1.00")
            run("confirm", token)
            self.assertFalse((base / "velora-shell/monitor-pending" / token).exists())


if __name__ == "__main__":
    unittest.main()
