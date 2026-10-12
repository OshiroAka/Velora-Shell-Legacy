import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class InstallationTests(unittest.TestCase):
    def environment(self, home):
        return dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home / "config"),
                    XDG_DATA_HOME=str(home / "data"), XDG_STATE_HOME=str(home / "state"),
                    XDG_CACHE_HOME=str(home / "cache"), PYTHONDONTWRITEBYTECODE="1")

    def test_clean_install_is_repeatable_and_keeps_user_settings(self):
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary)
            env = self.environment(home)
            command = [str(ROOT / "install.sh"), "--skip-hypr", "--without-fanplus"]
            subprocess.run(command, env=env, check=True, capture_output=True)
            config = home / "config/velora-shell/config.json"
            document = json.loads(config.read_text())
            document["profile"]["displayName"] = "Test user"
            config.write_text(json.dumps(document))
            subprocess.run(command, env=env, check=True, capture_output=True)
            self.assertEqual(json.loads(config.read_text())["profile"]["displayName"], "Test user")
            self.assertEqual((home / ".local/bin/velora").resolve(), ROOT / "scripts/velora")
            self.assertFalse((home / "config/hypr/hyprland.conf").exists())

    def test_migration_preserves_profile_assets_and_rewrites_paths(self):
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary)
            source = home / "previous"
            config = source / "config/project-helix"
            data = source / "data/project-helix/composition-profiles/example"
            config.mkdir(parents=True)
            data.mkdir(parents=True)
            (data / "image.png").write_bytes(b"fixture")
            profile = {"source": (data / "image.png").as_uri(), "variant": "helix"}
            (config / "config.json").write_text(json.dumps(profile))
            (config / "profiles.json").write_text(json.dumps({"profiles": [profile]}))
            (data / "profile.json").write_text(json.dumps(profile))
            result = subprocess.run([str(ROOT / "scripts/migrate-state"), str(source)], env=self.environment(home), capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            copied = home / "data/velora-shell/composition-profiles/example/image.png"
            document = json.loads((home / "config/velora-shell/config.json").read_text())
            self.assertEqual(document["source"], copied.as_uri())
            self.assertEqual(document["variant"], "velora")
            self.assertEqual(copied.read_bytes(), b"fixture")
            self.assertTrue((data / "image.png").exists())

    def test_local_qml_imports_and_static_helpers_exist(self):
        for path in ROOT.rglob("*.qml"):
            if "fixtures" in path.parts:
                continue
            text = path.read_text()
            for relative in re.findall(r'^import\s+"([^"]+)"', text, re.M):
                self.assertTrue((path.parent / relative).exists(), f"{path}: {relative}")
            for helper in re.findall(r'"/scripts/([^"\s]+)"', text):
                self.assertTrue((ROOT / "scripts" / helper).is_file(), f"{path}: {helper}")
            for asset in re.findall(r'Qt.resolvedUrl\("([^"\s]+)"\)', text):
                self.assertTrue((path.parent / asset).is_file(), f"{path}: {asset}")

    def test_source_scripts_parse_without_writing_bytecode(self):
        for path in (ROOT / "scripts").iterdir():
            if not path.is_file():
                continue
            text = path.read_text()
            if text.startswith("#!/usr/bin/env python3"):
                compile(text, str(path), "exec")
            elif text.startswith("#!/usr/bin/env bash"):
                result = subprocess.run(["bash", "-n", str(path)], capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)

    def test_public_defaults_contain_no_personal_images(self):
        document = json.loads((ROOT / "config/default.json").read_text())
        self.assertEqual(document["lockPreview"]["character"]["path"], "")
        self.assertTrue(all(item["path"] == "" for item in document["lockPreview"]["gallery"]))
        avatar = document["profile"]["avatar"].removeprefix("project:")
        self.assertTrue((ROOT / avatar).is_file())

    def test_empty_personal_image_slots_can_be_saved_and_exported(self):
        defaults = json.loads((ROOT / "config/default.json").read_text())
        snapshot = dict(defaults["lockPreview"])
        snapshot["profile"] = dict(defaults["profile"])
        snapshot["profile"]["avatar"] = (ROOT / snapshot["profile"]["avatar"].removeprefix("project:")).as_uri()
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            index = base / "profiles.json"
            storage = base / "profiles"
            command = [str(ROOT / "scripts/velora-composition-profiles"), "ensure",
                       "--index", str(index), "--data-root", str(storage),
                       "--snapshot-json", json.dumps(snapshot)]
            result = subprocess.run(command, check=True, capture_output=True, text=True)
            profile_id = json.loads(result.stdout)["activeProfileId"]
            composition = json.loads(index.read_text())["profiles"][0]["composition"]
            self.assertEqual(composition["character"]["path"], "")
            self.assertEqual([item["path"] for item in composition["gallery"]], ["", "", ""])
            package = base / "default.helixpack"
            subprocess.run([str(ROOT / "scripts/velora-composition-package"), "export",
                            "--index", str(index), "--id", profile_id,
                            "--data-root", str(storage), "--package", str(package)],
                           check=True, capture_output=True, text=True)
            self.assertTrue(package.is_file())
