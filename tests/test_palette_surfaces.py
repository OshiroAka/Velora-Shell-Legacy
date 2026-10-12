import importlib.machinery
import importlib.util
import json
import os
import random
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
loader = importlib.machinery.SourceFileLoader('surfaces', str(ROOT / 'scripts/velora-palette-surfaces'))
spec = importlib.util.spec_from_loader(loader.name, loader)
surfaces = importlib.util.module_from_spec(spec)
loader.exec_module(surfaces)


class PaletteSurfaceTests(unittest.TestCase):
    def palette(self):
        return {'special': {}, 'colors': {f'color{i}': ['#966a51', '#548695', '#927480'][i % 3] for i in range(16)}}

    def test_wallpaper_surfaces_contrast_shuffle_and_restore(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'wallpaper.png'
            image = Image.new('RGB', (160, 80))
            colors = ['#ad9a8b', '#7aa0b8', '#dcab8e', '#ddd1a5', '#40302a', '#183647', '#4d4d4d', '#000000']
            for i, value in enumerate(colors):
                image.paste(value, (i*20, 0, (i+1)*20, 80))
            image.save(path)
            for tone in ('light', 'dark'):
                first = surfaces.build(self.palette(), path, tone)
                background = first['special']['background']
                self.assertIn(background, colors)
                self.assertGreaterEqual(surfaces.contrast(surfaces.rgb(background), surfaces.rgb(first['special']['foreground'])), 4.5)
                self.assertGreaterEqual(surfaces.contrast(surfaces.rgb(background), surfaces.rgb(first['velora']['muted'])), 4.5)
                second = surfaces.build(self.palette(), path, tone, background, True, random.Random(7))
                self.assertNotEqual(second['special']['background'], background)
                restored = surfaces.build(self.palette(), path, tone, second['special']['background'])
                self.assertEqual(restored['special']['background'], second['special']['background'])
            black = surfaces.build(self.palette(), path, 'dark', '#000000')
            self.assertEqual(black['special']['background'], '#000000')
            self.assertIn('#000000', black['velora']['surfaces'])

    def test_monochrome_wallpaper_has_valid_palette(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'mono.png'
            for value in ('#000000', '#ffffff'):
                Image.new('RGB', (40, 40), value).save(path)
                for tone in ('light', 'dark'):
                    doc = surfaces.build(self.palette(), path, tone)
                    self.assertGreaterEqual(surfaces.contrast(surfaces.rgb(doc['special']['background']), surfaces.rgb(doc['special']['foreground'])), 4.5)

    def test_real_generator_changes_palette_without_external_theme_writes(self):
        loader = importlib.machinery.SourceFileLoader('wal_fixture', str(ROOT / 'scripts/velora-wal'))
        spec = importlib.util.spec_from_loader(loader.name, loader)
        wal = importlib.util.module_from_spec(spec); loader.exec_module(wal)
        selected, _ = wal.select_wal()
        if not selected or not shutil.which('magick') or not shutil.which('jq'):
            self.skipTest('pywal16/ImageMagick/jq unavailable')
        with tempfile.TemporaryDirectory(prefix='velora-palette-validation-') as directory:
            home = Path(directory)
            (home / 'bin').mkdir()
            # Expose only wal: adding a venv's entire bin would also shadow
            # system Python, which provides Pillow for Velora's image helpers.
            (home / 'bin/wal').symlink_to(selected['path'])
            env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home / 'config'),
                       XDG_DATA_HOME=str(home / 'data'), XDG_CACHE_HOME=str(home / 'cache'),
                       XDG_STATE_HOME=str(home / 'state'), PATH=str(home / 'bin') + os.pathsep + os.environ['PATH'])
            palettes = []
            for name, channels in [('red', (1, .25, .1)), ('blue', (.1, .3, 1))]:
                image = Image.new('RGB', (128, 128))
                image.putdata([tuple(int((40 + 180 * (x+y) / 254) * v) for v in channels)
                               for y in range(128) for x in range(128)])
                path = home / (name + '.png'); image.save(path)
                result = subprocess.run([str(ROOT / 'scripts/generate-pywal-palette'), str(path), 'dark'],
                                        env=env, capture_output=True, text=True, timeout=40)
                self.assertEqual(result.returncode, 0, result.stderr)
                data = json.loads((home / 'cache/velora-shell/pywal/colors.json').read_text())
                self.assertEqual(data['wallpaper'], str(path))
                self.assertGreaterEqual(len(data['colors']), 16)
                palettes.append(data['colors'])
            self.assertNotEqual(*palettes)
            self.assertFalse((home / 'config').exists())


if __name__ == '__main__':
    unittest.main()
