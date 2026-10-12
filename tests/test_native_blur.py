import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
from types import SimpleNamespace

ROOT = Path(__file__).resolve().parents[1]


def helper():
    loader = importlib.machinery.SourceFileLoader("native_blur", str(ROOT / "scripts/native-blur"))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


class NativeBlurTests(unittest.TestCase):
    def setUp(self):
        self.module = helper()
        self.temporary = tempfile.TemporaryDirectory(prefix="velora-native-test-")
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.environment = patch.dict(os.environ, {"XDG_CACHE_HOME": str(self.directory / "cache")})
        self.environment.start()
        self.addCleanup(self.environment.stop)

    def test_versions_and_exact_abi(self):
        m = self.module
        self.assertEqual(m.version("Hyprland v0.56.2"), (0, 56, 2))
        self.assertIsNone(m.version("unknown"))
        self.assertTrue(m.abi_matches({"abi": "commit_aq_0.15"}, {"abiHash": "commit_aq_0.15"}))
        self.assertFalse(m.abi_matches({"abi": "commit_aq_0.14"}, {"abiHash": "commit_aq_0.15"}))
        self.assertFalse(m.abi_matches({"abi": "different"}, {"commit": "commit"}))
        with patch.object(m, "run", side_effect=[ValueError("legacy"), "Hyprland v0.52.0 at commit abcdef012345\nTag: v0.52.0"]):
            self.assertEqual(m.running_version()["abiHash"], "abcdef012345")

    def test_header_probe_invalidates_when_dependency_hash_function_changes(self):
        m = self.module
        include = self.directory / "include"
        api = include / "hyprland/src/plugins/PluginAPI.hpp"
        api.parent.mkdir(parents=True)
        api.write_text("fixture API")
        (include / "hyprland/src/version.h").write_text("fixture version")
        dependency = {"abi": "commit_aq_0.15"}
        compiled = []
        def command(args, **kwargs):
            if args[:2] == ["pkg-config", "--modversion"]: return "0.56.2"
            if args[:2] == ["pkg-config", "--cflags"]: return "-I" + str(include)
            if "--version" in args: return "fixture compiler"
            if "-E" in args: return 'const char* __hyprland_api_get_client_hash() { return "' + dependency["abi"] + '"; }'
            if "-o" in args:
                compiled.append(kwargs["input"])
                return ""
            return dependency["abi"]
        with patch.object(m, "run", side_effect=command):
            first = m.header_identity()
            self.assertEqual(first["abi"], dependency["abi"])
            self.assertEqual(m.header_identity(), first)
            self.assertEqual(len(compiled), 1)
            dependency["abi"] = "commit_aq_0.16"
            self.assertNotEqual(m.header_identity()["headerKey"], first["headerKey"])
            self.assertEqual(len(compiled), 2)

    def test_build_reuses_only_verified_matching_artifact(self):
        m = self.module
        source = self.directory / "source/native/hyprland"
        source.mkdir(parents=True)
        (source / "plugin.cpp").write_text("fixture")
        identity = {"abi": "one", "headersVersion": "0.56.2"}
        def compile_fixture(command, **kwargs):
            if command[1] == "--build":
                (Path(command[2]) / "velora-blur.so").write_bytes(identity["abi"].encode())
            else:
                Path(command[command.index("-B") + 1]).mkdir(parents=True, exist_ok=True)
            return SimpleNamespace(stdout="")
        with patch.object(m, "ROOT", self.directory / "source"), patch.object(m, "header_identity", side_effect=lambda: dict(identity)), patch.object(m.subprocess, "run", side_effect=compile_fixture) as commands:
            directory = self.directory / "build"
            plugin = m.build(directory, 2)
            self.assertEqual(commands.call_count, 2)
            m.build(directory, 2)
            self.assertEqual(commands.call_count, 2)
            identity["abi"] = "two"
            m.build(directory, 2)
            self.assertEqual(plugin.read_bytes(), b"two")
            self.assertEqual(commands.call_count, 4)
            self.assertNotEqual(commands.call_args_list[0].args[0][4], commands.call_args_list[2].args[0][4])
            plugin.write_bytes(b"corrupt")
            m.build(directory, 2)
            self.assertEqual(commands.call_count, 6)
            (source / "plugin.cpp").write_text("changed")
            m.build(directory, 2)
            self.assertEqual(commands.call_count, 8)

    def test_failed_headers_or_compile_invalidates_public_artifact(self):
        m = self.module
        directory = self.directory / "build"
        directory.mkdir()
        (directory / "velora-blur.so").write_bytes(b"stale")
        (directory / "velora-blur.json").write_text("{}")
        with patch.object(m, "header_identity", side_effect=RuntimeError("headers absent")):
            with self.assertRaisesRegex(RuntimeError, "headers absent"):
                m.build(directory, 2)
        self.assertFalse((directory / "velora-blur.so").exists())
        self.assertFalse((directory / "velora-blur.json").exists())
        self.assertEqual(m.read_json(m.cache_dir() / "diagnostic.json")["state"], "build-failed")
        with patch.object(m, "header_identity", return_value={"abi": "one"}), patch.object(m.subprocess, "run", side_effect=subprocess.CalledProcessError(1, "cmake", output="missing render API")):
            with self.assertRaises(RuntimeError): m.build(directory, 2)
        self.assertFalse((directory / "velora-blur.so").exists())
        self.assertIn("missing render API", m.read_json(m.cache_dir() / "diagnostic.json")["diagnostic"])

    def test_absent_incompatible_and_loaded_status(self):
        m = self.module
        running = {"commit": "commit", "abiHash": "abi"}
        with patch.object(m, "running_version", return_value=running):
            with patch.object(m, "run", return_value="[]"):
                self.assertEqual(m.inspect()["state"], "absent")
            for native, ready in [({"active": True}, False), ({"active": True, "abi": "other"}, False),
                                  ({"active": False, "abi": "abi"}, False),
                                  ({"active": True, "abi": "abi", "capabilities": ["bar-blur"]}, True)]:
                with patch.object(m, "run", side_effect=[json.dumps([{"name": "velora-blur"}]), json.dumps(native)]):
                    self.assertEqual(m.inspect()["available"], ready)
            with patch.object(m, "run", side_effect=subprocess.TimeoutExpired("hyprctl", 10)):
                self.assertFalse(m.inspect()["available"])

    def artifact(self):
        m = self.module
        plugin = self.directory / "velora-blur.so"
        plugin.write_bytes(b"library")
        m.write_json(plugin.with_suffix(".json"), {"abi": "abi", "sha256": m.digest(plugin)})
        return plugin

    def test_reject_mismatch_before_loading(self):
        m = self.module
        plugin = self.artifact()
        with patch.object(m, "running_version", return_value={"abiHash": "other"}), patch.object(m, "run") as commands:
            with self.assertRaisesRegex(RuntimeError, "ABI"): m.load(plugin)
            commands.assert_not_called()

    def test_load_requires_runtime_confirmation_and_all_capabilities(self):
        m = self.module
        plugin = self.artifact()
        absent = {"loaded": False, "available": False, "capabilities": []}
        good = {"loaded": True, "available": True, "capabilities": m.CAPABILITIES}
        with patch.object(m, "running_version", return_value={"abiHash": "abi"}), patch.object(m, "run", return_value="ok") as commands, patch.object(m, "shell_ipc") as lifecycle:
            with patch.object(m, "inspect", side_effect=[absent, good]):
                self.assertTrue(m.load(plugin)["available"])
            destination = Path(commands.call_args.args[0][-1])
            self.assertIn(m.digest(plugin)[:24], destination.name)
            self.assertEqual(m.read_json(m.cache_dir() / "loaded.json")["path"], str(destination))
            self.assertEqual([call.args[0] for call in lifecycle.call_args_list], ["nativeBlurSuspend", "nativeBlurResume"])
            commands.reset_mock()
            lifecycle.reset_mock()
            with patch.object(m, "inspect", return_value=good): m.load(plugin)
            commands.assert_not_called()
            lifecycle.assert_called_once_with("nativeBlurResume")
            for bad in [absent, dict(good, capabilities=["bar-blur"])]:
                lifecycle.reset_mock()
                with patch.object(m, "inspect", side_effect=[absent, bad]):
                    with self.assertRaises(RuntimeError): m.load(plugin)
                self.assertEqual(commands.call_args.args[0][2], "unload")
                self.assertEqual([call.args[0] for call in lifecycle.call_args_list], ["nativeBlurSuspend", "nativeBlurResume"])

    def test_legacy_unload_is_verified_before_new_load(self):
        m = self.module
        plugin = self.artifact()
        old = {"loaded": True, "available": False, "capabilities": []}
        with patch.object(m, "running_version", return_value={"abiHash": "abi"}), patch.object(m, "inspect", return_value=old), patch.object(m, "run") as commands, patch.object(m, "shell_ipc") as lifecycle:
            with self.assertRaisesRegex(RuntimeError, "ainda carregado"): m.load(plugin)
            self.assertEqual(commands.call_count, 1)
            self.assertEqual(commands.call_args.args[0][2], "unload")
            self.assertEqual([call.args[0] for call in lifecycle.call_args_list], ["nativeBlurSuspend", "nativeBlurResume"])

    def test_loading_before_shell_start_does_not_require_qml_ipc(self):
        m = self.module
        with patch.object(m, "run", side_effect=subprocess.TimeoutExpired("qs", 2)):
            m.shell_ipc("nativeBlurSuspend")

    def test_namespace_rules_follow_release_and_preserve_selector(self):
        m = self.module
        text = (ROOT / "config/hyprland.conf.in").read_text()
        self.assertEqual(m.layer_rules(text, "0.56.2"), text)
        legacy = m.layer_rules(text, "0.52.0")
        self.assertIn("layerrule = blur, ^velora-shell($|-.*)", legacy)
        self.assertIn("layerrule = blurpopups, ^velora-shell($|-.*)", legacy)
        self.assertIn("layerrule = ignorealpha 0.02,", legacy)
        self.assertNotIn("match:namespace", legacy)
        self.assertNotIn("layerrule = noblur", legacy)
        self.assertNotIn("layerrule = blur, ^velora-wallpaper-selector", legacy)
        with self.assertRaises(RuntimeError): m.layer_rules(text, "unknown")

    def test_every_native_qml_dispatch_is_capability_gated(self):
        for path in ROOT.rglob("*.qml"):
            if path.name == "NativeBlur.qml": continue
            text = path.read_text()
            self.assertNotIn('Hyprland.dispatch("velora-blur:', text, str(path))
        self.assertIn('supports(name)', (ROOT / "platform/NativeBlur.qml").read_text())
        self.assertIn('||', (ROOT / "scripts/run").read_text().split('load-native-blur')[1])
