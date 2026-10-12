import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class TopbarTests(unittest.TestCase):
    def test_detail_motion_inputs_and_animation_lifecycle(self):
        runner = Path("/usr/lib/qt6/bin/qmltestrunner")
        if not runner.is_file():
            self.skipTest("Qt Quick Test is required")
        with tempfile.TemporaryDirectory(prefix="velora-detail-test-") as directory:
            env = dict(os.environ, QT_QPA_PLATFORM="offscreen", XDG_RUNTIME_DIR=directory)
            env.pop("WAYLAND_DISPLAY", None)
            result = subprocess.run([str(runner), "-input", str(ROOT / "tests/fixtures/tst_topbar_details.qml")],
                                    capture_output=True, text=True, env=env, timeout=25)
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("7 passed, 0 failed", output)
            self.assertNotIn("QWARN", output)

    def test_execution_events_and_expiration(self):
        executable = shutil.which("qs")
        if not executable:
            self.skipTest("Quickshell is required")
        with tempfile.TemporaryDirectory(prefix="velora-execution-test-") as directory:
            root = Path(directory)
            (root / "services").mkdir()
            shutil.copy2(ROOT / "services/ExecutionStatusService.qml", root / "services")
            shutil.copy2(ROOT / "tests/fixtures/execution-state.qml", root / "shell.qml")
            runtime = root / "runtime"
            runtime.mkdir(mode=0o700)
            env = dict(os.environ, QT_QPA_PLATFORM="offscreen", XDG_RUNTIME_DIR=str(runtime))
            env.pop("WAYLAND_DISPLAY", None)
            result = subprocess.run([executable, "-p", str(root)], env=env,
                                    capture_output=True, text=True, timeout=10)
            output = result.stdout + result.stderr
            self.assertIn("EXECUTION_TEST_OK", output, output)
            self.assertNotIn("EXECUTION_TEST_FAILED", output, output)

    def test_timer_defaults_invalid_state_and_panel_bounds(self):
        node = shutil.which("node")
        if not node:
            self.skipTest("Node is required to exercise the pure QML JavaScript functions")
        script = r"""
const fs = require('fs'), vm = require('vm'), assert = require('assert/strict');
function library(path) {
    const context = vm.createContext({});
    vm.runInContext(fs.readFileSync(path, 'utf8').replace('.pragma library', ''), context);
    return context;
}
const timer = library('features/topbar/TimerState.js');
for (const document of [null, {}, {timer: {}}, {duration: Infinity, timer: {remaining: NaN}}]) {
    const state = timer.normalize(document, 10000);
    assert.equal(state.duration, 1500000);
    assert.equal(timer.remaining(state.timer, 10000), 1500000);
}
const completed = timer.normalize({timer: {remaining: 0}, finished: true}, 10000);
assert.equal(completed.timer.remaining, 0);
assert.equal(completed.finished, true);
const running = timer.normalize({timer: {running: true, deadline: 14000, remaining: 7000}}, 10000);
assert.equal(timer.remaining(running.timer, 11000), 3000);
assert.equal(timer.remaining(running.timer, 16000), 0);
assert.equal(timer.normalize({timer: {running: true, deadline: 'invalid'}}, 10000).timer.running, false);
assert.equal(timer.format(59999), '01:00');
assert.equal(timer.format(3600000), '1:00:00');
const order = library('core/TopBarOrder.js');
assert.equal(order.normalize(null).length, 10);
assert.equal(new Set(order.normalize(['timer', 'timer', 'usb', 'clock'])).size, 10);
assert.equal(order.normalize(['timer', 'timer', 'usb', 'clock']).slice(0, 2).join(','), 'timer,clock');
assert.equal(order.normalize(['clock', 'wifi', 'battery']).slice(0, 4).join(','), 'clock,paint,monitor,battery');
assert.equal(order.normalize(['paint', 'monitor', 'wifi']).filter(v => v === 'monitor').length, 1);
const before = order.defaults();
const moved = order.move(before, 'timer', 'clock');
assert.equal(moved[moved.length - 1], 'timer');
assert.equal(before[1], 'timer');
assert.equal(order.move(moved, 'timer', 'caffeine')[0], 'timer');
assert.equal(order.move(before, 'usb', 'clock').join(','), before.join(','));
const geometry = library('features/topbar/TopBarGeometry.js');
for (const width of [320, 800, 1280, 1920, 2560])
for (const height of [300, 720, 1200])
for (const anchor of [0, 12, width / 2, width - 12, width])
for (const progress of [0, .1, .5, 1])
for (const type of ['timer', 'clock', 'usb', 'notes', 'battery', 'monitor', 'paint']) {
    const [w, h] = geometry.size(type);
    const p = geometry.panel(width, height, 40, anchor, w, h, progress);
    assert(p.x >= 8 && p.x + p.width <= width - 8 + 1e-6);
    assert(p.y >= 40 && p.y + p.height <= height);
}
"""
        subprocess.run([node, "-e", script], cwd=ROOT, check=True, capture_output=True, text=True)

    def test_notes_editing_timer_and_persistence_with_fresh_xdg_state(self):
        runtime = Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share") / "velora-shell/runtime/quickshell/bin/qs"
        executable = str(runtime) if runtime.is_file() else shutil.which("qs")
        if not executable:
            self.skipTest("Quickshell is required")
        with tempfile.TemporaryDirectory(prefix="velora-topbar-test-") as temporary:
            home = Path(temporary)
            checkout = home / "source"
            checkout.mkdir()
            for directory in ("services", "features/topbar", "scripts", "core"):
                shutil.copytree(ROOT / directory, checkout / directory)
            shutil.copy2(ROOT / "tests/fixtures/topbar-state.qml", checkout / "shell.qml")
            runtime_dir = home / "runtime"
            runtime_dir.mkdir(mode=0o700)
            bin_dir = home / "bin"
            bin_dir.mkdir()
            # Notifications are counted locally; no desktop notification is sent.
            notification = bin_dir / "notify-send"
            notification.write_text('#!/bin/sh\nprintf "notification\\n" >> "$HOME/notifications"\n')
            notification.chmod(0o755)
            env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home / "config"),
                       XDG_DATA_HOME=str(home / "data"), XDG_STATE_HOME=str(home / "state"),
                       XDG_CACHE_HOME=str(home / "cache"), XDG_RUNTIME_DIR=str(runtime_dir),
                       QT_QPA_PLATFORM="offscreen", PATH=str(bin_dir) + os.pathsep + os.environ["PATH"])
            env.pop("WAYLAND_DISPLAY", None)
            env.pop("QML_IMPORT_PATH", None)
            for mode in ("write", "reload", "finished"):
                result = subprocess.run([executable, "-p", str(checkout)], env=dict(env, VELORA_TEST_MODE=mode),
                                        capture_output=True, text=True, timeout=20)
                output = result.stdout + result.stderr
                self.assertIn("VELORA_TOPBAR_TEST_OK " + mode, output, output)
                self.assertNotIn("VELORA_TOPBAR_TEST_FAILED", output)
            state = json.loads((home / "state/velora-shell/topbar-tools.json").read_text())
            self.assertEqual([note["text"] for note in state["notes"]], ["Ação", "Second"])
            self.assertEqual((home / "notifications").read_text().splitlines(), ["notification"])
