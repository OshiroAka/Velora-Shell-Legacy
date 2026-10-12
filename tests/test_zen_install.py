import hashlib
import importlib.machinery
import importlib.util
import io
import os
from pathlib import Path
import tarfile
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


def load(name):
    loader = importlib.machinery.SourceFileLoader(name.replace('-', '_'), str(ROOT / 'scripts' / name))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec); loader.exec_module(module)
    return module


class ZenInstallationTests(unittest.TestCase):
    def test_existing_zen_is_reused_without_download(self):
        m = load('install-zen')
        with patch.object(m.browser, 'select_browser', return_value=({'path': '/usr/bin/zen-browser', 'version': 'Mozilla Zen 1.23.2b'}, [])), \
             patch.object(m, 'release_asset') as release:
            m.install()
        release.assert_not_called()

    def test_resolver_rejects_non_zen_and_uses_private_fallback(self):
        m = load('velora-browser')
        with patch.object(m.shutil, 'which', side_effect=lambda name: '/system/zen' if name == 'zen' else None), \
             patch.object(m.Path, 'is_file', return_value=True), \
             patch.object(m.subprocess, 'run', side_effect=[SimpleNamespace(returncode=0, stdout='Other program 1.0', stderr=''),
                                                         SimpleNamespace(returncode=0, stdout='Mozilla Zen 1.23.2b', stderr='')]):
            self.assertEqual(m.select_browser()[0]['path'], str(m.runtime_directory() / 'zen-bin'))

    def archive(self, base, name='zen/zen-bin'):
        archive = base / 'zen.tar.xz'
        with tarfile.open(archive, 'w:xz') as bundle:
            data = b'#!/bin/sh\necho "Mozilla Zen 1.23.2b"\n'
            info = tarfile.TarInfo(name); info.mode = 0o755; info.size = len(data)
            bundle.addfile(info, io.BytesIO(data))
        return archive, 'sha256:' + hashlib.sha256(archive.read_bytes()).hexdigest()

    def test_bad_hash_is_rejected_before_extraction(self):
        m = load('install-zen')
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary); archive, _ = self.archive(base)
            with self.assertRaisesRegex(RuntimeError, 'SHA256'):
                m.extract_verified(archive, 'sha256:' + '0' * 64, base / 'extract')
            self.assertFalse((base / 'extract').exists())

    def test_archive_paths_cannot_escape_staging_directory(self):
        m = load('install-zen')
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary); archive, digest = self.archive(base, '../escape')
            with self.assertRaises(tarfile.FilterError):
                m.extract_verified(archive, digest, base / 'extract')
            self.assertFalse((base / 'escape').exists())

    def test_verified_install_registers_launcher_without_touching_personal_browser(self):
        m = load('install-zen')
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary); archive, digest = self.archive(base)
            target = base / 'data/velora-shell/runtime/zen'
            with patch.dict(os.environ, HOME=str(base), XDG_DATA_HOME=str(base / 'data')), \
                 patch.object(m.browser, 'select_browser', side_effect=[({}, []), ({'path': str(target / 'zen-bin'), 'version': 'Mozilla Zen 1.23.2b'}, [])]), \
                 patch.object(m, 'release_asset', return_value=('1.23.2b', {'digest': digest, 'browser_download_url': 'https://github.com/zen-browser/desktop/releases/download/1.23.2b/zen.linux-x86_64.tar.xz'})), \
                 patch.object(m.urllib.request, 'urlopen', side_effect=lambda *a, **kw: archive.open('rb')):
                m.install()
            self.assertTrue((target / 'zen-bin').is_file())
            desktop = (base / 'data/applications/velora-zen.desktop').read_text()
            self.assertIn(str(ROOT / 'scripts/velora-browser'), desktop)
            self.assertFalse((base / '.config').exists())
            self.assertFalse((base / '.local/bin').exists())
