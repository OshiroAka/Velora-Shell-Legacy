import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from hardware.fan.lenovo_ideapad_15irh10 import LenovoIdeaPad15IRH10Provider


def load_helper():
    path = ROOT / "hardware/fan/privileged_helper.py"
    spec = importlib.util.spec_from_file_location("fanplus_privileged_test", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class FanPlusTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="velora-fanplus-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.dmi = self.root / "dmi"
        self.dmi.mkdir()
        for name, value in LenovoIdeaPad15IRH10Provider.DMI.items():
            (self.dmi / name).write_text(value + "\n")

    def test_exact_supported_dmi_and_other_hardware(self):
        provider = LenovoIdeaPad15IRH10Provider(self.dmi)
        self.assertTrue(provider.supported)
        for key in provider.DMI:
            original = (self.dmi / key).read_text()
            (self.dmi / key).write_text("other\n")
            self.assertFalse(provider.supported, key)
            (self.dmi / key).write_text(original)

    def test_old_service_and_missing_dependencies_block_activation(self):
        provider = LenovoIdeaPad15IRH10Provider(self.dmi)
        old = self.root / "ideapad-fan-max.service"
        with mock.patch.object(provider, "OLD_SERVICE_LINK", old), \
             mock.patch.object(provider, "OLD_SERVICE", old), \
             mock.patch.object(provider, "OLD_BINARIES", (self.root / "old-max", self.root / "old-auto")), \
             mock.patch.object(provider, "HELPER", self.root / "helper"), \
             mock.patch.object(provider, "POLICY", self.root / "policy"):
            old.write_text("")
            self.assertIn("serviço antigo", provider.availability()[1])
            old.unlink()
            with mock.patch.object(Path, "is_file", return_value=False):
                self.assertIn("ec_probe", provider.availability()[1])
            with mock.patch("shutil.which", return_value="/usr/bin/test"), \
                 mock.patch.object(Path, "exists", return_value=False), \
                 mock.patch("subprocess.run", return_value=subprocess.CompletedProcess([], 1)):
                self.assertIn("acpi_call", provider.availability()[1])
            (self.root / "helper").write_text("")
            (self.root / "policy").write_text("")
            with mock.patch("shutil.which", return_value="/usr/bin/test"):
                self.assertTrue(provider.availability()[0])

    def run_privileged(self, action, responses):
        helper = load_helper()
        helper.DMI_ROOT = self.dmi
        helper.STATE = self.root / "state"
        helper.OLD_SERVICE = self.root / "old-service"
        helper.OLD_BINARIES = (self.root / "old-max", self.root / "old-auto")
        calls = []

        def invoke(command, **kwargs):
            calls.append(command)
            return responses.pop(0)

        output = io.StringIO()
        with mock.patch.object(helper.subprocess, "run", side_effect=invoke), \
             contextlib.redirect_stdout(output):
            code = helper.main([action])
        return code, output.getvalue(), calls

    def test_on_off_use_only_validated_commands_and_keep_power_profile(self):
        expected_on = ["/usr/bin/ec_probe", "acpi_call", r"\_SB.PC00.LPCB.EC0.MBEY",
                       "0xEF", "0x61", "0x3F"]
        expected_off = ["/usr/bin/ec_probe", "acpi_call", r"\_SB.PC00.LPCB.EC0.MBEY",
                        "0xEF", "0x63", "0x03"]
        success = lambda: subprocess.CompletedProcess([], 0, "0xac\n", "")
        for action, expected, state in (("on", expected_on, "active"),
                                        ("off", expected_off, "off")):
            code, output, calls = self.run_privileged(action, [success()])
            self.assertEqual(code, 0, output)
            self.assertEqual(calls, [expected])
            self.assertEqual(self.root.joinpath("state").read_text().strip(), state)
            self.assertNotIn("powerprofilesctl", output + str(calls))

    def test_ec_rejection_and_missing_module_do_not_claim_active(self):
        failure = subprocess.CompletedProcess([], 0, "0x00\n", "")
        code, output, _ = self.run_privileged("on", [failure])
        self.assertEqual(code, 1)
        self.assertIn('"state": "error"', output)
        self.assertFalse((self.root / "state").exists())
        helper = load_helper()
        helper.DMI_ROOT = self.dmi
        helper.STATE = self.root / "state"
        helper.OLD_SERVICE = self.root / "old-service"
        helper.OLD_BINARIES = (self.root / "old-max", self.root / "old-auto")
        exists = Path.exists
        with mock.patch.object(Path, "exists", autospec=True,
                               side_effect=lambda path: False if str(path) == "/proc/acpi/call" else exists(path)), \
             mock.patch.object(helper.subprocess, "run", return_value=subprocess.CompletedProcess([], 1, "", "failed")):
            output = io.StringIO()
            with contextlib.redirect_stdout(output):
                code = helper.main(["on"])
        self.assertEqual(code, 1)
        self.assertIn("carregar acpi_call", output.getvalue())

    def test_privileged_helper_rejects_old_service_and_unknown_operations(self):
        helper = load_helper()
        helper.DMI_ROOT = self.dmi
        helper.STATE = self.root / "state"
        helper.OLD_SERVICE = self.root / "old-service"
        helper.OLD_BINARIES = (self.root / "old-max", self.root / "old-auto")
        helper.OLD_SERVICE.write_text("")
        output = io.StringIO()
        with mock.patch.object(helper.subprocess, "run") as execute, contextlib.redirect_stdout(output):
            self.assertEqual(helper.main(["on"]), 1)
            self.assertEqual(helper.main(["write", "0x50"]), 1)
        execute.assert_not_called()
        self.assertIn("serviço antigo", json.loads(output.getvalue().splitlines()[0])["error"])
        self.assertFalse(helper.STATE.exists())

    def test_cold_boot_state_and_resume_reapply_contract(self):
        helper = load_helper()
        helper.DMI_ROOT = self.dmi
        helper.STATE = self.root / "state"
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            self.assertEqual(helper.main(["status"]), 0)
        self.assertIn('"state": "off"', output.getvalue())
        # During a session, status survives QML reload; /run vanishes on reboot.
        helper.STATE.write_text("active\n")
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            self.assertEqual(helper.main(["status"]), 0)
        self.assertIn('"state": "active"', output.getvalue())

    def test_qml_transitions_indicator_and_resume(self):
        executable = shutil.which("qs")
        if not executable:
            self.skipTest("Quickshell is required")
        checkout = self.root / "shell"
        checkout.mkdir()
        for name in ("services", "components"):
            (checkout / name).mkdir()
        shutil.copy2(ROOT / "services/FanPlusService.qml", checkout / "services")
        shutil.copy2(ROOT / "components/VeloraFanPlusIndicator.qml", checkout / "components")
        shutil.copy2(ROOT / "tests/fixtures/fanplus-state.qml", checkout / "shell.qml")
        helper = self.root / "fake-fanplus.py"
        helper.write_text('''import json, os, sys
command = sys.argv[1]
with open(os.environ["VELORA_FANPLUS_TEST_LOG"], "a") as log: log.write(command + "\\n")
state = "error" if command == "on" and os.environ["VELORA_FANPLUS_TEST_MODE"] == "error" else {"status": "off", "on": "active", "off": "off"}[command]
print(json.dumps({"state": state, "error": "backend failure" if state == "error" else ""}))
sys.exit(1 if state == "error" else 0)
''')
        runtime = self.root / "runtime"
        runtime.mkdir(mode=0o700)
        for mode in ("success", "error"):
            log = self.root / (mode + ".log")
            env = dict(os.environ, QT_QPA_PLATFORM="offscreen", XDG_RUNTIME_DIR=str(runtime),
                       VELORA_FANPLUS_TEST_HELPER=str(helper), VELORA_FANPLUS_TEST_MODE=mode,
                       VELORA_FANPLUS_TEST_LOG=str(log))
            env.pop("WAYLAND_DISPLAY", None)
            result = subprocess.run([executable, "-p", str(checkout)], env=env,
                                    capture_output=True, text=True, timeout=10)
            output = result.stdout + result.stderr
            self.assertIn("VELORA_FANPLUS_TEST_OK " + mode, output)
            self.assertNotIn("VELORA_FANPLUS_TEST_FAILED", output)
            self.assertEqual(log.read_text().splitlines(),
                             ["status", "on", "on", "off"] if mode == "success" else ["status", "on"])


if __name__ == "__main__":
    unittest.main()
