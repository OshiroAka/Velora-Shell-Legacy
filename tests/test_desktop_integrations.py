import configparser
import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
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


class NotificationOwnershipTests(unittest.TestCase):
    def test_clean_session_without_a_server_does_not_activate_another_daemon(self):
        m = load('velora-notifications')
        with patch.object(m, 'call', return_value=SimpleNamespace(stdout='b false')) as call:
            state = m.status()
            self.assertFalse(state['conflict']); self.assertFalse(state['ready'])
            self.assertEqual(call.call_count, 1)
            self.assertIn('NameHasOwner', call.call_args.args[0])

    def test_no_consent_never_stops_a_personal_service(self):
        m = load('velora-notifications')
        with tempfile.TemporaryDirectory() as temporary, patch.dict(os.environ, XDG_CONFIG_HOME=temporary), patch.object(m, 'status') as status:
            m.claim(); status.assert_not_called()

    def test_approved_known_service_requires_matching_owner_pid(self):
        m = load('velora-notifications')
        with tempfile.TemporaryDirectory() as temporary, patch.dict(os.environ, XDG_CONFIG_HOME=temporary):
            preference = m.preference(); preference.parent.mkdir(); preference.write_text('velora\n')
            with patch.object(m, 'status', return_value=dict(conflict=True, daemon='dunst', unit='dunst.service', pid=55)), \
                 patch.object(m, 'call', return_value=SimpleNamespace(stdout='56')) as call:
                with self.assertRaisesRegex(RuntimeError, 'preservado'): m.claim()
                self.assertEqual(call.call_count, 1)
            with patch.object(m, 'status', return_value=dict(conflict=True, daemon='dunst', unit='dunst.service', pid=55)), \
                 patch.object(m, 'call', return_value=SimpleNamespace(stdout='55')) as call:
                m.claim()
                self.assertEqual(call.call_args.args[0], ['systemctl', '--user', 'stop', 'dunst.service'])

    def test_unknown_daemon_is_preserved_even_with_consent(self):
        m = load('velora-notifications')
        with tempfile.TemporaryDirectory() as temporary, patch.dict(os.environ, XDG_CONFIG_HOME=temporary):
            preference = m.preference(); preference.parent.mkdir(); preference.write_text('velora\n')
            with patch.object(m, 'status', return_value=dict(conflict=True, daemon='personal', unit=None)), patch.object(m, 'call') as call:
                with self.assertRaisesRegex(RuntimeError, 'preservado'): m.claim()
                call.assert_not_called()


class ScreenshotClipboardTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(); self.addCleanup(self.temporary.cleanup)
        self.home = Path(self.temporary.name); self.bin = self.home / 'bin'; self.bin.mkdir()
        self.env = dict(os.environ, HOME=str(self.home), PATH=str(self.bin) + ':/usr/bin',
                        VELORA_FIXTURE_DIR=str(self.home), XDG_CONFIG_HOME=str(self.home / 'config'))
        self.tool('grim', '#!/bin/sh\nfor target; do :; done\nprintf "complete-png-fixture" > "$target"\n')
        self.tool('wl-copy', '#!/bin/sh\n[ "${VELORA_FIXTURE_COPY_FAIL:-0}" = 0 ] || exit 1\ncat > "$VELORA_FIXTURE_DIR/clipboard"\n')
        self.tool('notify-send', '#!/bin/sh\nprintf "%s\\n" "$*" >> "$VELORA_FIXTURE_DIR/notifications"\n')
        self.tool('slurp', '#!/bin/sh\nexit 1\n')

    def tool(self, name, source):
        path = self.bin / name; path.write_text(source); path.chmod(0o755)

    def capture(self, mode='full'):
        return subprocess.run(['/bin/bash', str(ROOT / 'scripts/velora-screenshot-select'), mode], env=self.env,
                              capture_output=True, text=True, timeout=5)

    def test_full_capture_saves_and_copies_identical_image(self):
        result = self.capture(); self.assertEqual(result.returncode, 0, result.stderr)
        files = list((self.home / 'Pictures/Screenshots').glob('*.png'))
        self.assertEqual(len(files), 1)
        self.assertEqual(files[0].read_bytes(), (self.home / 'clipboard').read_bytes())

    def test_copy_failure_cannot_announce_success(self):
        self.env['VELORA_FIXTURE_COPY_FAIL'] = '1'
        result = self.capture(); self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('Salvo e copiado', (self.home / 'notifications').read_text())
        self.assertEqual(len(list((self.home / 'Pictures/Screenshots').glob('*.png'))), 1)

    def test_cancelled_selection_preserves_previous_clipboard(self):
        (self.home / 'clipboard').write_bytes(b'previous')
        self.assertEqual(self.capture('select').returncode, 0)
        self.assertEqual((self.home / 'clipboard').read_bytes(), b'previous')
        self.assertFalse(list((self.home / 'Pictures/Screenshots').glob('*.png')))

    def test_missing_clipboard_dependency_is_reported_before_capture(self):
        (self.bin / 'wl-copy').unlink(); self.env['PATH'] = str(self.bin)
        result = self.capture(); self.assertNotEqual(result.returncode, 0)
        self.assertIn('wl-copy', result.stderr)
        self.assertFalse((self.home / 'Pictures').exists())


class ZenPaletteTests(unittest.TestCase):
    def test_shell_neutral_palette_wins_over_tinted_raw_wal(self):
        m = load('velora-zen-theme.py')
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            def palette(background):
                return dict(colors={f'color{i}': '#777777' for i in range(16)}, special={'background': background, 'foreground': '#f6f4f1'})
            raw = base / 'raw.json'; raw.write_text(json.dumps(palette('#130808')))
            final = base / 'shell.json'; data = palette('#222222'); data.update(tone='dark', velora={'exactSurface': True, 'muted': '#bbbbbb'})
            final.write_text(json.dumps(data))
            with patch.object(m, 'WAL_PATH', raw), patch.object(m, 'SHELL_PALETTE_PATH', final):
                result = m.build_palette()
                self.assertEqual(result['background'], (34, 34, 34)); self.assertEqual(result['surface'], (34, 34, 34))
                self.assertEqual(result['source'], str(final)); self.assertEqual(result['mode'], 'dark')
                self.assertNotIn('#130808', m.generate_chrome_css(result))


class SpicetifyConfigurationTests(unittest.TestCase):
    def test_extension_is_added_idempotently_without_corrupting_empty_value_or_next_section(self):
        m = load('install-spotify-bridge')
        for existing in ['', 'personal.js|other.js']:
            original = '[Setting]\ncurrent_theme = marketplace\n[AdditionalOptions]\ncustom_apps = marketplace\nextensions            = ' + existing + '\n\n[Patch]\n\n[Backup]\nversion = 1.2\n'
            result = m.configuration(original)
            self.assertEqual(m.configuration(result), result)
            p = configparser.RawConfigParser(); p.read_string(result)
            self.assertEqual(p['Setting']['current_theme'], 'marketplace'); self.assertEqual(p['Backup']['version'], '1.2')
            self.assertEqual(p['AdditionalOptions']['custom_apps'], 'marketplace')
            self.assertEqual(p['AdditionalOptions']['extensions'].split('|'), [x for x in existing.split('|') if x] + [m.EXTENSION])

    def test_apply_failure_rolls_back_only_our_configuration_and_extension(self):
        m = load('install-spotify-bridge')
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary); config = base / 'config.ini'; config.write_text('personal')
            extension = base / 'Extensions/velora-spotify-bridge.js'; extension.parent.mkdir(); extension.write_text('previous')
            plan = dict(config=config, original='personal', proposed='modified', extension=extension, cli='/fixture/spicetify')
            with patch.object(m.subprocess, 'run', side_effect=subprocess.CalledProcessError(1, 'spicetify')):
                with self.assertRaises(subprocess.CalledProcessError): m.apply(plan)
            self.assertEqual(config.read_text(), 'personal'); self.assertEqual(extension.read_text(), 'previous')

    def test_catalogue_uses_current_bundle_when_search_route_is_not_loaded(self):
        if not shutil.which('node'): self.skipTest('Node unavailable')
        source = (ROOT / 'integrations/spotify/velora-spotify-bridge.js').read_text().split('(function veloraCatalogue() {', 1)[1]
        source = '(function veloraCatalogue() {' + source.replace('    async function listen() {', '    globalThis.testCatalogue = catalogue;\n    async function listen() {', 1)
        setup = '''const assert=require('assert/strict');global.window=global;global.document={baseURI:'https://xpui.app.spotify.com/index.html'};
global.setTimeout=()=>{}; const hash='a'.repeat(64);let called;
global.Spicetify={CosmosAsync:{get:()=>{throw new Error('Web API must not run')}},GraphQL:{Definitions:{},Request:async(def,variables)=>{
called={def,variables};return {data:{searchV2:{tracksV2:{items:[{item:{data:{uri:'spotify:track:1',name:'Track',artists:{items:[{profile:{name:'Artist'}}]},albumOfTrack:{name:'Album',coverArt:{sources:[{url:'cover'}]}},duration:{totalMilliseconds:123}}}}]}}}};
}}};global.fetch=async(url)=>String(url).endsWith('/requests')?new Promise(()=>{}):{ok:true,text:async()=>`new Q("searchTracks","query","${hash}",null)`};
'''
        check = "\n(async()=>{const tracks=await testCatalogue('test');assert.equal(called.def.name,'searchTracks');assert.equal(called.def.sha256Hash,hash);assert.equal(called.variables.includeAuthors,false);assert.equal(tracks[0].artist,'Artist');assert.equal(tracks.length,1);})().catch(e=>{console.error(e);process.exitCode=1});"
        result = subprocess.run(['node', '-e', setup + source + check], capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
