"""Run the actual Settings picker lifecycle with isolated dialogs and data."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class SettingsPickerTests(unittest.TestCase):
    def test_missing_cancelled_selected_and_invalid_avatar_restore_settings(self):
        executable = shutil.which('qs')
        if not executable:
            self.skipTest('Quickshell required')
        for mode in ('missing', 'cancel', 'selected', 'invalid'):
            with self.subTest(mode=mode), tempfile.TemporaryDirectory(prefix='velora-picker-test-') as temporary:
                base = Path(temporary)
                for directory in ('core', 'features', 'components', 'services', 'platform', 'assets', 'config'):
                    (base / directory).symlink_to(ROOT / directory, target_is_directory=True)
                (base / 'scripts').mkdir()
                (base / 'scripts/import-bar-avatar').symlink_to(ROOT / 'scripts/import-bar-avatar')
                (base / 'bin').mkdir()
                (base / 'bin/python3').symlink_to(shutil.which('python3'))
                if mode != 'missing':
                    picker = base / 'bin/zenity'
                    picker.write_text('#!/bin/sh\n' + ('exit 1\n' if mode == 'cancel' else
                        'printf "%s\\n" "$HOME/' + ('avatar.png' if mode == 'selected' else 'missing.png') + '"\n'))
                    picker.chmod(0o755)
                from PIL import Image
                Image.new('RGB', (16, 16), '#567890').save(base / 'avatar.png')
                prefix = (ROOT / 'tests/fixtures/settings-rebuild.qml').read_text().split('    Window {')[0]
                prefix = prefix.replace('"../../', '"./').replace('property string activeProfileId:',
                    'property bool ready: true\n        property bool busy: false\n        property string activeProfileId:')
                (base / 'shell.qml').write_text(prefix + '''
    property int step: 0
    property int ticks: 0
    function check(ok, message) { if (!ok) throw new Error(message) }
    Timer { interval: 60; running: true; repeat: true
        onTriggered: {
            try {
                if (++test.ticks > 100) throw new Error("picker stuck")
                if (!config.ready) return
                if (test.step === 0) {
                    config.setValue("appearance.reducedMotion", true)
                    controller.show("desktop")
                    controller.integrationsMounted = false
                    controller.chooseBarAvatar()
                    check(controller.picking, "selection started")
                    test.step = 1; return
                }
                if (test.step === 1 && !controller.picking && controller.shown) {
                    const mode = Quickshell.env("PICKER_MODE")
                    check(controller.mounted, "Settings restored")
                    if (mode === "missing") check(controller.pickerError.length > 0, "missing selector reported")
                    if (mode === "cancel") check(!controller.pickerError && !controller.profileAvatarError, "cancel is not an error")
                    if (mode === "selected") check(config.avatarPath.indexOf("/avatars/bar-") !== -1, "avatar imported")
                    if (mode === "invalid") check(controller.profileAvatarError.length > 0, "invalid avatar reported")
                    controller.hide(); test.step = 2; return
                }
                if (test.step === 2 && !controller.mounted) {
                    check(controller.show("desktop"), "Settings can reopen")
                    controller.integrationsMounted = false
                    test.step = 3; return
                }
                if (test.step === 3 && controller.shown) {
                    console.info("PICKER_LIFECYCLE_OK"); Qt.quit()
                }
            } catch (error) { console.error("PICKER_LIFECYCLE_FAILED", error.message); Qt.quit() }
        }
    }
}
''')
                (base / 'runtime').mkdir(mode=0o700)
                env = dict(os.environ, HOME=str(base), PATH=str(base / 'bin'), PICKER_MODE=mode,
                    QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software', VELORA_VALIDATE='1',
                    XDG_CONFIG_HOME=str(base / 'user-config'), XDG_DATA_HOME=str(base / 'data'),
                    XDG_CACHE_HOME=str(base / 'cache'), XDG_RUNTIME_DIR=str(base / 'runtime'))
                env.pop('WAYLAND_DISPLAY', None)
                result = subprocess.run([executable, '-p', str(base)], env=env, capture_output=True, text=True, timeout=12)
                output = result.stdout + result.stderr
                self.assertEqual(result.returncode, 0, output)
                self.assertIn('PICKER_LIFECYCLE_OK', output)
                self.assertNotIn('PICKER_LIFECYCLE_FAILED', output)
                for error in ('TypeError:', 'ReferenceError:', 'Binding loop', 'Cannot assign'):
                    self.assertNotIn(error, output)
