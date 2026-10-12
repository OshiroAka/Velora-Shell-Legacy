#!/usr/bin/env python3
import importlib.util
import pathlib
import subprocess
import tempfile
import unittest
from unittest import mock


ROOT = pathlib.Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "velora-pywal-theme.py"


def load_module():
    spec = importlib.util.spec_from_file_location("velora_pywal_theme", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class PywalVideoHistogramTests(unittest.TestCase):
    def setUp(self):
        self.module = load_module()

    def test_video_histogram_uses_current_static_preview(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            video = root / "wallpaper.mp4"
            preview = root / "preview.jpg"
            state = root / "current_wallpaper"
            video.touch()
            preview.touch()
            state.write_text(f"live|{video}|{preview}\n", encoding="utf-8")

            self.module.CURRENT_WALLPAPER_PATH = state
            self.module.LIVE_PREVIEW_DIR = root / "fallback-previews"
            completed = subprocess.CompletedProcess(
                [], 0, stdout="  2: (10,20,30) #0A141E srgb(10,20,30)\n"
            )
            with mock.patch.object(
                self.module.subprocess, "run", return_value=completed
            ) as run:
                colors = self.module.wallpaper_histogram_colors(str(video))

            self.assertEqual(colors, [(2, (10.0, 20.0, 30.0))])
            self.assertEqual(run.call_args.args[0][1], str(preview))
            self.assertNotIn(str(video), run.call_args.args[0])

    def test_video_without_preview_never_starts_imagemagick(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            video = root / "wallpaper.webm"
            video.touch()
            self.module.CURRENT_WALLPAPER_PATH = root / "missing-state"
            self.module.LIVE_PREVIEW_DIR = root / "missing-previews"

            with mock.patch.object(self.module.subprocess, "run") as run:
                colors = self.module.wallpaper_histogram_colors(str(video))

            self.assertEqual(colors, [])
            run.assert_not_called()


if __name__ == "__main__":
    unittest.main()
