import importlib.machinery
import importlib.util
import random
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


if __name__ == '__main__':
    unittest.main()
