import contextlib
import io
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from hardware.fan import installation as installer


class FanPlusInstallationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.provider = SimpleNamespace(
            supported=True, OLD_SERVICE=self.root / "old.service",
            OLD_SERVICE_LINK=self.root / "enabled.service",
            OLD_BINARIES=[self.root / "old-on", self.root / "old-off"],
            HELPER=self.root / "installed-helper", POLICY=self.root / "installed-policy")
        self.output = io.StringIO()
        self.enterContext(contextlib.redirect_stdout(self.output))
        self.deps = self.enterContext(patch.object(installer, "dependency_plan", return_value=([], [], False)))
        self.privileged = self.enterContext(patch.object(installer, "privileged", return_value=True))
        self.copied = self.enterContext(patch.object(installer, "installed_copy", return_value=True))

    def setup(self, **kwargs):
        return installer.setup(self.root, provider=self.provider, **kwargs)

    def test_unsupported_hardware_never_provisions(self):
        self.provider.supported = False
        self.assertTrue(self.setup(install_dependencies=True))
        self.deps.assert_not_called()
        self.privileged.assert_not_called()

    def test_legacy_files_including_dangling_enable_link_block_provisioning(self):
        for path in [self.provider.OLD_SERVICE, self.provider.OLD_SERVICE_LINK,
                     *self.provider.OLD_BINARIES]:
            with self.subTest(path=path):
                path.symlink_to(self.root / "missing")
                self.assertFalse(self.setup())
                path.unlink()
        self.deps.assert_not_called()
        self.privileged.assert_not_called()

    def test_missing_dependencies_are_reported_without_installing_by_default(self):
        self.deps.return_value = (["acpi_call ausente"], ["dkms", "acpi_call-dkms", "linux-cachyos-headers"], False)
        with patch.object(installer, "arch_system", return_value=True):
            self.assertFalse(self.setup())
        self.assertIn("pacman -S --needed dkms acpi_call-dkms linux-cachyos-headers", self.output.getvalue())
        self.privileged.assert_not_called()
        self.copied.assert_not_called()

    def test_opt_in_installs_repository_packages_then_rechecks(self):
        self.deps.side_effect = [(["acpi_call ausente"], ["dkms", "acpi_call-dkms", "linux-cachyos-headers"], False), ([], [], False)]
        with patch.object(installer, "arch_system", return_value=True):
            self.assertTrue(self.setup(install_dependencies=True))
        self.privileged.assert_called_once_with([
            "/usr/bin/pacman", "-S", "--needed", "dkms", "acpi_call-dkms", "linux-cachyos-headers"])
        self.assertEqual(self.deps.call_count, 2)

    def test_absent_ec_probe_has_manual_instruction_and_stays_pending(self):
        self.deps.return_value = (["ec_probe ausente"], [], True)
        with patch.object(installer, "arch_system", return_value=True), patch.object(installer.shutil, "which", return_value="/usr/bin/paru"):
            self.assertFalse(self.setup(install_dependencies=True))
        self.assertIn("/usr/bin/paru -S --needed nbfc-linux-git", self.output.getvalue())
        self.privileged.assert_not_called()
        self.copied.assert_not_called()

    def test_check_mode_never_installs_even_with_dependency_opt_in(self):
        self.deps.return_value = (["polkit ausente"], ["polkit"], False)
        with patch.object(installer, "arch_system", return_value=True):
            self.assertFalse(self.setup(check_only=True, install_dependencies=True))
        self.deps.return_value = ([], [], False)
        self.copied.return_value = False
        self.assertFalse(self.setup(check_only=True))
        self.privileged.assert_not_called()

    def test_fixed_helper_and_policy_installation_then_idempotent(self):
        self.copied.side_effect = [False, True, False, True, True, True]
        self.assertTrue(self.setup())
        commands = [call.args[0] for call in self.privileged.call_args_list]
        self.assertEqual(commands, [
            ["/usr/bin/install", "-D", "-o", "root", "-g", "root", "-m", "0755",
             str(self.root / "hardware/fan/privileged_helper.py"), str(self.provider.HELPER)],
            ["/usr/bin/install", "-D", "-o", "root", "-g", "root", "-m", "0644",
             str(self.root / "hardware/fan/org.velora.fanplus.policy"), str(self.provider.POLICY)]])
        self.assertTrue(self.setup())
        self.assertEqual(self.privileged.call_count, 2)

    def test_sudo_failure_and_incorrect_copy_remain_pending(self):
        self.copied.return_value = False
        self.privileged.return_value = False
        self.assertFalse(self.setup())
        self.privileged.return_value = True
        self.assertFalse(self.setup())
        self.assertNotIn("dependências, helper e política conferidos", self.output.getvalue())


class FanPlusDependencyTests(unittest.TestCase):
    def test_missing_module_uses_running_kernel_pkgbase(self):
        with patch.object(installer.os, "access", return_value=True), patch.object(installer, "run", return_value=subprocess.CompletedProcess([], 1)), patch.object(installer.platform, "release", return_value="test-kernel"), patch.object(Path, "read_text", return_value="linux-cachyos\n"):
            issues, packages, ec_missing = installer.dependency_plan()
        self.assertTrue(issues)
        self.assertEqual(packages, ["dkms", "acpi_call-dkms", "linux-cachyos-headers"])
        self.assertFalse(ec_missing)

    def test_unknown_headers_are_not_guessed_and_missing_tools_are_reported(self):
        with patch.object(installer.os, "access", return_value=False), patch.object(installer, "run", return_value=subprocess.CompletedProcess([], 1)), patch.object(Path, "read_text", side_effect=FileNotFoundError):
            issues, packages, ec_missing = installer.dependency_plan()
        self.assertEqual(packages, ["polkit", "kmod", "dkms", "acpi_call-dkms"])
        self.assertTrue(ec_missing)
        self.assertTrue(any("pkgbase não identificado" in issue for issue in issues))

    def test_installed_copy_requires_root_ownership_mode_and_content(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "source"
            target = Path(directory) / "target"
            source.write_bytes(b"helper")
            target.write_bytes(b"helper")
            for uid, gid, mode, expected in [(0, 0, 0o755, True), (1000, 0, 0o755, False), (0, 1000, 0o755, False), (0, 0, 0o777, False)]:
                with self.subTest(uid=uid, gid=gid, mode=mode), patch.object(Path, "lstat", return_value=SimpleNamespace(st_uid=uid, st_gid=gid, st_mode=mode)), patch.object(Path, "is_symlink", return_value=False):
                    self.assertEqual(installer.installed_copy(source, target, 0o755), expected)
            target.unlink()
            target.symlink_to(source)
            self.assertFalse(installer.installed_copy(source, target, 0o755))
