import json
import datetime as dt
import os
import pathlib
import subprocess
import tempfile
import unittest
import zipfile
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[1]

class CompositionStorageTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.assets = pathlib.Path(temporary.name)
        for index, name in enumerate(("avatar.png", "character.png", "gallery-main.png", "gallery-top.png", "gallery-bottom.png")):
            Image.new("RGB", (64, 64), (70 + index * 20, 110, 150)).save(self.assets / name)

    def test_wallpaper_accent_rejects_a_small_neon_outlier(self):
        from PIL import Image

        with tempfile.TemporaryDirectory() as temporary:
            temporary_path = pathlib.Path(temporary)
            image_path = temporary_path / "wallpaper.png"
            palette_path = temporary_path / "colors.json"
            image = Image.new("RGB", (100, 100), "#a66f67")
            for x in range(90, 100):
                for y in range(100):
                    image.putpixel((x, y), (45, 255, 95))
            image.save(image_path)
            palette_path.write_text(json.dumps({"colors": {
                "color9": "#63d594",
                "color10": "#d6bb68",
                "color11": "#d98d80",
                "color12": "#e0a68a",
                "color13": "#e0c18c",
                "color14": "#e9ade9",
            }}))
            result = subprocess.run(
                [ROOT / "scripts/select-velora-accents", image_path, palette_path],
                check=True, text=True, capture_output=True,
            )
            accents = json.loads(result.stdout)
            self.assertNotEqual(accents["secondary"], "#63d594")
            self.assertNotEqual(accents["secondary"], "#00ff00")
        self.assertRegex(accents["secondary"], r"^#[0-9a-f]{6}$")

    def test_profile_helper_copies_assets_and_preserves_manifest(self):
        default = json.loads((ROOT / "config/default.json").read_text())
        snapshot = {
            "schemaVersion": 6,
            "character": dict(default["lockPreview"]["character"]),
            "gallery": [dict(entry) for entry in default["lockPreview"]["gallery"]],
            "galleryOrder": [2, 0, 1],
            "topbarLayout": [dict(item) for item in default["topbar"]["layout"]],
            "wallpaper": {
                "path": (self.assets / "gallery-main.png").as_uri(),
            },
        }
        snapshot["character"]["path"] = (self.assets / "character.png").as_uri()
        for index, name in enumerate(("gallery-main.png", "gallery-top.png",
                                      "gallery-bottom.png")):
            snapshot["gallery"][index]["path"] = (self.assets / name).as_uri()

        with tempfile.TemporaryDirectory() as temporary:
            base = pathlib.Path(temporary)
            command = [
                str(ROOT / "scripts/velora-composition-profiles"), "ensure",
                "--index", str(base / "profiles.json"),
                "--data-root", str(base / "data"),
                "--snapshot-json", json.dumps(snapshot),
            ]
            result = subprocess.run(command, check=True, capture_output=True, text=True)
            self.assertTrue(json.loads(result.stdout)["ok"])
            index = json.loads((base / "profiles.json").read_text())
            self.assertEqual(index["profiles"][0]["name"], "Atual")
            self.assertEqual(index["profiles"][0]["composition"]["galleryOrder"], [2, 0, 1])
            self.assertEqual(index["profiles"][0]["composition"]["schemaVersion"], 8)
            self.assertEqual(index["profiles"][0]["composition"]["topbarLayout"][0]["id"],
                             "bar-brand")
            directory = base / "data" / index["activeProfileId"]
            self.assertTrue((directory / "profile.json").is_file())
            self.assertTrue((directory / "character.png").is_file())
            self.assertEqual(len(list(directory.glob("gallery-*"))), 3)
            self.assertTrue((directory / "wallpaper.png").is_file())
            self.assertRegex(index["profiles"][0]["accent"], r"^#[0-9a-f]{6}$")

    def test_profile_update_replaces_old_wallpaper_with_live_draft(self):
        default = json.loads((ROOT / "config/default.json").read_text())
        snapshot = {
            "character": dict(default["lockPreview"]["character"]),
            "gallery": [dict(entry) for entry in default["lockPreview"]["gallery"]],
            "galleryOrder": [0, 1, 2],
            "wallpaper": {"path": (self.assets / "gallery-main.png").as_uri()},
        }
        snapshot["character"]["path"] = (self.assets / "character.png").as_uri()
        for index, name in enumerate(("gallery-main.png", "gallery-top.png",
                                      "gallery-bottom.png")):
            snapshot["gallery"][index]["path"] = (self.assets / name).as_uri()

        with tempfile.TemporaryDirectory() as temporary:
            base = pathlib.Path(temporary)
            index_path = base / "profiles.json"
            data_root = base / "data"
            helper = str(ROOT / "scripts/velora-composition-profiles")
            ensured = subprocess.run([
                helper, "ensure", "--index", str(index_path),
                "--data-root", str(data_root), "--snapshot-json",
                json.dumps(snapshot),
            ], check=True, capture_output=True, text=True)
            profile_id = json.loads(ensured.stdout)["activeProfileId"]

            live_draft = base / "selected-wallpaper.mp4"
            live_draft.write_bytes(b"velora-live-wallpaper-draft")
            updated_snapshot = dict(snapshot)
            updated_snapshot["wallpaper"] = {"path": live_draft.as_uri()}
            subprocess.run([
                helper, "update", "--index", str(index_path),
                "--data-root", str(data_root), "--id", profile_id,
                "--name", "Atual", "--snapshot-json",
                json.dumps(updated_snapshot),
            ], check=True, capture_output=True, text=True)

            index = json.loads(index_path.read_text())
            stored_url = index["profiles"][0]["composition"]["wallpaper"]["path"]
            self.assertTrue(stored_url.endswith("/wallpaper.mp4"))
            self.assertEqual((data_root / profile_id / "wallpaper.mp4").read_bytes(),
                             b"velora-live-wallpaper-draft")

    def test_topbar_order_and_visibility_are_isolated_per_profile(self):
        default = json.loads((ROOT / "config/default.json").read_text())

        def snapshot(layout):
            value = {
                "schemaVersion": 6,
                "character": dict(default["lockPreview"]["character"]),
                "gallery": [dict(entry) for entry in default["lockPreview"]["gallery"]],
                "galleryOrder": [0, 1, 2],
                "topbarLayout": [dict(item) for item in layout],
            }
            value["character"]["path"] = (self.assets / "character.png").as_uri()
            for index, name in enumerate(("gallery-main.png", "gallery-top.png",
                                          "gallery-bottom.png")):
                value["gallery"][index]["path"] = (self.assets / name).as_uri()
            return value

        layout_a = [dict(item) for item in default["topbar"]["layout"]]
        layout_b = [dict(item) for item in default["topbar"]["layout"]]
        next(item for item in layout_a
             if item["id"] == "bar-brand")["enabled"] = True
        brand_b = next(item for item in layout_b if item["id"] == "bar-brand")
        brand_b.update({"section": "center", "order": 1, "enabled": False})

        with tempfile.TemporaryDirectory() as temporary:
            base = pathlib.Path(temporary)
            index_path = base / "profiles.json"
            data_root = base / "profiles"
            helper = str(ROOT / "scripts/velora-composition-profiles")
            subprocess.run([
                helper, "ensure", "--index", str(index_path),
                "--data-root", str(data_root), "--snapshot-json",
                json.dumps(snapshot(layout_a)),
            ], check=True, capture_output=True, text=True)
            subprocess.run([
                helper, "create", "--index", str(index_path),
                "--data-root", str(data_root), "--name", "Perfil B",
                "--snapshot-json", json.dumps(snapshot(layout_b)),
            ], check=True, capture_output=True, text=True)

            profiles = json.loads(index_path.read_text())["profiles"]
            stored_a = profiles[0]["composition"]["topbarLayout"]
            stored_b = profiles[1]["composition"]["topbarLayout"]
            self.assertTrue(next(item for item in stored_a
                                 if item["id"] == "bar-brand")["enabled"])
            brand = next(item for item in stored_b if item["id"] == "bar-brand")
            self.assertFalse(brand["enabled"])
            self.assertEqual(brand["section"], "center")

    def test_profile_ensure_migrates_legacy_topbar_layout_to_v8(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = pathlib.Path(temporary)
            index_path = base / "profiles.json"
            data_root = base / "profiles"
            profile_dir = data_root / "shell-profile"
            profile_dir.mkdir(parents=True)
            shell = {
                "schemaVersion": 5,
                "id": "shell-profile",
                "name": "Legacy",
                "accent": "#445566",
                "createdAt": "2026-08-23T00:00:00+00:00",
                "updatedAt": "2026-08-23T00:00:00+00:00",
                "composition": {"schemaVersion": 5},
                "directory": "shell-profile",
                "preview": "",
            }
            index_path.write_text(json.dumps({
                "schemaVersion": 1,
                "activeProfileId": "shell-profile",
                "profiles": [shell],
            }))
            manifest = dict(shell)
            manifest.pop("directory")
            manifest.pop("preview")
            (profile_dir / "profile.json").write_text(json.dumps(manifest))

            subprocess.run([
                str(ROOT / "scripts/velora-composition-profiles"), "ensure",
                "--index", str(index_path), "--data-root", str(data_root),
            ], check=True, capture_output=True, text=True)

            migrated = json.loads(index_path.read_text())["profiles"][0]
            self.assertEqual(migrated["schemaVersion"], 8)
            self.assertEqual(migrated["composition"]["schemaVersion"], 8)
            self.assertEqual(
                migrated["composition"]["appearance"]["visualStyle"],
                "classic")
            self.assertEqual(migrated["composition"]["topbar"]["margin"], 8)
            self.assertNotIn("variant", migrated["composition"]["topbar"])
            self.assertEqual(len(migrated["composition"]["topbarLayout"]), 13)
            stored = json.loads((profile_dir / "profile.json").read_text())
            self.assertEqual(stored["composition"]["topbarLayout"][5]["section"],
                             "center")

    def test_helixpack_round_trip_preserves_custom_layers_and_is_inactive(self):
        default = json.loads((ROOT / "config/default.json").read_text())
        snapshot = {
            "schemaVersion": 6,
            "character": dict(default["lockPreview"]["character"]),
            "gallery": [dict(entry) for entry in default["lockPreview"]["gallery"]],
            "galleryOrder": [0, 1, 2],
            "topbarLayout": [dict(item) for item in default["topbar"]["layout"]],
            "topbar": {"toolsOrder": [
                "timer", "thing", "clock", "caffeine", "wifi", "battery",
                "controls", "search", "notes",
            ]},
            "sharedWidgets": dict(default["lockPreview"]["sharedWidgets"],
                                  surfaceMode="bar", blurEnabled=False),
            "profile": {
                "displayName": "Teste",
                "greeting": "Olá",
                "verticalLabel": "VELORA",
                "avatar": (self.assets / "avatar.png").as_uri(),
            },
            "appearance": {
                "characterPywal": True,
                "waterCausticsEnabled": True,
                "waterCausticsIntensity": 0.57,
                "waterCausticsLines": False,
                "waterCausticsModules": True,
                "lockDimmingMode": "both",
                "lockDimmingAmount": 0.41,
            },
            "wallpaper": {"path": (self.assets / "gallery-main.png").as_uri()},
            "scene": {"layers": [{
                "id": "custom-art",
                "type": "image",
                "name": "Arte extra",
                "plane": "belowPanel",
                "order": 3,
                "visible": True,
                "locked": False,
                "source": (self.assets / "gallery-bottom.png").as_uri(),
                "baseWidth": 320,
                "baseHeight": 240,
                "transform": {"x": 90, "y": 140, "scale": 1.25,
                              "rotation": 12, "opacity": 0.8, "flipX": False},
            }]},
        }
        snapshot["character"]["path"] = (self.assets / "character.png").as_uri()
        for index, name in enumerate(("gallery-main.png", "gallery-top.png",
                                      "gallery-bottom.png")):
            snapshot["gallery"][index]["path"] = (self.assets / name).as_uri()

        with tempfile.TemporaryDirectory() as temporary:
            base = pathlib.Path(temporary)
            index_path = base / "profiles.json"
            data_root = base / "profiles"
            profile_result = subprocess.run([
                str(ROOT / "scripts/velora-composition-profiles"), "ensure",
                "--index", str(index_path), "--data-root", str(data_root),
                "--snapshot-json", json.dumps(snapshot),
            ], check=True, capture_output=True, text=True)
            active_id = json.loads(profile_result.stdout)["activeProfileId"]
            package_path = base / "composition.helixpack"
            subprocess.run([
                str(ROOT / "scripts/velora-composition-package"), "export",
                "--index", str(index_path), "--data-root", str(data_root),
                "--id", active_id, "--package", str(package_path),
            ], check=True, capture_output=True, text=True)
            with zipfile.ZipFile(package_path) as archive:
                manifest = json.loads(archive.read("manifest.json"))
                wallpaper_url = manifest["composition"]["wallpaper"]["path"]
                self.assertTrue(wallpaper_url.startswith("helix-asset://"))
                wallpaper_id = wallpaper_url.removeprefix("helix-asset://")
                wallpaper_asset = next(asset for asset in manifest["assets"]
                                       if asset["id"] == wallpaper_id)
                self.assertEqual(
                    archive.read(wallpaper_asset["path"]),
                    (self.assets / "gallery-main.png").read_bytes(),
                )
            imported = subprocess.run([
                str(ROOT / "scripts/velora-composition-package"), "import",
                "--index", str(index_path), "--data-root", str(data_root),
                "--package", str(package_path),
            ], check=True, capture_output=True, text=True)
            imported_id = json.loads(imported.stdout)["profileId"]
            index = json.loads(index_path.read_text())
            self.assertEqual(index["activeProfileId"], active_id)
            self.assertEqual(len(index["profiles"]), 2)
            profile = next(item for item in index["profiles"] if item["id"] == imported_id)
            custom = profile["composition"]["scene"]["layers"][0]
            self.assertEqual(custom["id"], "custom-art")
            self.assertEqual(custom["plane"], "belowPanel")
            self.assertEqual(custom["transform"]["rotation"], 12)
            self.assertEqual(profile["composition"]["topbarLayout"][5]["section"],
                             "center")
            self.assertEqual(profile["composition"]["topbar"]["toolsOrder"],
                             [item for tool in snapshot["topbar"]["toolsOrder"]
                              for item in (["paint", "monitor"] if tool == "wifi" else [tool])])
            self.assertEqual(profile["composition"]["sharedWidgets"]["surfaceMode"],
                             "bar")
            self.assertIs(profile["composition"]["sharedWidgets"]["blurEnabled"], False)
            self.assertEqual(profile["composition"]["appearance"]["lockDimmingMode"],
                             "both")
            self.assertEqual(profile["composition"]["appearance"]["lockDimmingAmount"],
                             0.41)
            self.assertTrue(
                profile["composition"]["appearance"]["waterCausticsEnabled"])
            self.assertEqual(
                profile["composition"]["appearance"]["waterCausticsIntensity"],
                0.57)
            self.assertFalse(
                profile["composition"]["appearance"]["waterCausticsLines"])
            self.assertTrue(
                profile["composition"]["appearance"]["waterCausticsModules"])
            self.assertTrue(pathlib.Path(custom["source"].removeprefix("file://")).is_file())
            imported_wallpaper = pathlib.Path(
                profile["composition"]["wallpaper"]["path"].removeprefix("file://"))
            self.assertTrue(imported_wallpaper.is_file())
            self.assertEqual(imported_wallpaper.read_bytes(),
                             (self.assets / "gallery-main.png").read_bytes())

    def test_calendar_reader_discovers_local_ics_without_network(self):
        service = (ROOT / "services/CalendarService.qml").read_text()
        self.assertIn(
            'Quickshell.shellDir + "/scripts/velora-calendar-state"',
            service,
        )
        self.assertNotIn("config.projectRoot", service)

        with tempfile.TemporaryDirectory() as temporary:
            home = pathlib.Path(temporary)
            data = home / ".local/share/calendar"
            data.mkdir(parents=True)
            today = dt.date.today()
            stamp = today.strftime("%Y%m%d")
            (data / "events.ics").write_text(
                "BEGIN:VCALENDAR\nBEGIN:VEVENT\nUID:calendar-test\n"
                f"DTSTART;VALUE=DATE:{stamp}\nDTEND;VALUE=DATE:{stamp}\n"
                "SUMMARY:Teste Velora\nEND:VEVENT\nEND:VCALENDAR\n",
                encoding="utf-8",
            )
            environment = dict(os.environ)
            environment.update({
                "HOME": str(home),
                "XDG_DATA_HOME": str(home / ".local/share"),
                "XDG_CONFIG_HOME": str(home / ".config"),
            })
            result = subprocess.run(
                [str(ROOT / "scripts/velora-calendar-state"), "--days", "31"],
                check=True, capture_output=True, text=True, env=environment,
            )
            document = json.loads(result.stdout)
            self.assertEqual(document["events"][0]["title"], "Teste Velora")
            self.assertTrue(document["events"][0]["readOnly"])
            self.assertEqual(len(document["sources"]), 1)
