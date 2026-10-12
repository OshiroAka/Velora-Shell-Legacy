import contextlib
import importlib.machinery
import importlib.util
import io
import json
import os
from pathlib import Path
import re
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


class PreflightTests(unittest.TestCase):
    def setUp(self): self.module = load('preflight')

    def test_missing_commands_and_qs_are_aggregated(self):
        m = self.module
        with patch.object(m.shutil, 'which', return_value=None), patch.object(m, 'quickshell_candidates', return_value=[]), \
             patch.object(m.browser, 'select_browser', return_value=({}, ['Zen Browser não encontrado'])):
            with patch.object(m.wal, 'select_wal', return_value=({}, ['pywal16 não encontrado'])):
                state = m.inspect()
        self.assertFalse(state['ready'])
        self.assertIn('cmake', state['missing'])
        self.assertIn('qs não encontrado; pacote Arch: quickshell', state['missing'])
        self.assertTrue({'gcc', 'pkgconf', 'qt6-multimedia', 'qt6-shadertools', 'quickshell'}.issubset(state['packages']))
        self.assertFalse(any('cachyos' in x for x in state['packages']))
        self.assertIn('imagemagick', state['packages'])
        self.assertIn('zenity', state['packages'])
        self.assertEqual(state['sourceFeatures'], ['pywal16', 'zen-browser'])
        self.assertFalse(any('pywal' in x for x in state['packages']))

    def test_present_dependencies_and_compiler_probe(self):
        m = self.module
        with patch.object(m.shutil, 'which', side_effect=lambda c: '/usr/bin/' + c), \
             patch.object(m, 'select_quickshell', return_value=({'path': '/usr/bin/qs', 'importsVerified': True}, [])), \
             patch.object(m.wal, 'select_wal', return_value=({'path': '/usr/bin/wal'}, [])), \
             patch.object(m.browser, 'select_browser', return_value=({'path': '/usr/bin/zen-browser'}, [])), \
             patch.object(m, 'run', return_value=SimpleNamespace(returncode=0, stdout='6.12.0', stderr='')) as run:
            state = m.inspect()
        self.assertTrue(state['ready']); self.assertEqual(state['packages'], [])
        self.assertTrue(any('-std=c++23' in call.args[0] for call in run.call_args_list))

    def test_bluetooth_packages_are_required_only_when_hardware_exists(self):
        m = self.module
        for present in (False, True):
            with self.subTest(hardware=present), patch.object(m.bluetooth, 'hardware_present', return_value=present), \
                 patch.object(m.shutil, 'which', return_value=None), patch.object(m, 'quickshell_candidates', return_value=[]):
                state = m.inspect(build=False)
                self.assertEqual('bluez' in state['packages'], present)
                self.assertEqual('blueman' in state['packages'], present)

    def test_qs_probe_rejects_missing_imports_crashes_and_silent_timeouts(self):
        m = self.module
        version = SimpleNamespace(returncode=0, stdout='Quickshell 0.3.2', stderr='')
        for result in [SimpleNamespace(returncode=1, stdout='ERROR missing import', stderr=''),
                       subprocess.TimeoutExpired('qs', 8, output=b'no ready marker'),
                       SimpleNamespace(returncode=-11, stdout='VELORA_IMPORTS_READY', stderr='')]:
            with self.subTest(result=result), patch.object(m, 'quickshell_candidates', return_value=['/fixture/qs']), \
                 patch.object(m, 'run', return_value=version), patch.object(m.subprocess, 'run', side_effect=[result] if isinstance(result, Exception) else None, return_value=result):
                value, errors = m.select_quickshell()
                self.assertFalse(value); self.assertTrue(errors)

    def test_probe_timeout_with_explicit_loaded_marker_is_bounded(self):
        m = self.module
        with patch.object(m, 'quickshell_candidates', return_value=['/fixture/qs']), \
             patch.object(m, 'run', return_value=SimpleNamespace(returncode=0, stdout='Quickshell 0.3.2', stderr='')), \
             patch.object(m.subprocess, 'run', side_effect=subprocess.TimeoutExpired('qs', 8, output=b'VELORA_IMPORTS_READY')):
            self.assertTrue(m.select_quickshell()[0]['importsVerified'])

    def test_system_qs_wins_and_private_build_is_only_a_fallback(self):
        m = self.module
        with patch.object(m, 'quickshell_candidates', return_value=['/system/qs', '/private/qs']), \
             patch.object(m, 'run', return_value=SimpleNamespace(returncode=0, stdout='Quickshell 0.3.2', stderr='')) as run:
            self.assertEqual(m.select_quickshell(probe=False)[0]['path'], '/system/qs')
            self.assertEqual(run.call_count, 1)
        with patch.object(m, 'quickshell_candidates', return_value=['/system/qs', '/private/qs']), \
             patch.object(m, 'run', side_effect=[SimpleNamespace(returncode=1, stdout='', stderr='Qt ABI failure'),
                                               SimpleNamespace(returncode=0, stdout='Quickshell 0.3.2', stderr='')]):
            self.assertEqual(m.select_quickshell(probe=False)[0]['path'], '/private/qs')

    def test_path_is_checked_by_complete_entries(self):
        m = self.module
        self.assertFalse(m.path_present(Path('/tmp/velora-bin'), '/usr/bin:/tmp/velora-bin-other'))
        self.assertTrue(m.path_present(Path('/tmp/velora-bin'), '/usr/bin:/tmp/velora-bin'))


class IntegrationTests(unittest.TestCase):
    def setUp(self): self.module = load('hyprland-integration')

    def test_inventory_exhausts_both_templates_and_checks_commands(self):
        m = self.module
        all_binds = m.inventory()
        self.assertEqual(len(all_binds), 28)
        self.assertEqual(len(m.inventory(infinite=False)), 12)
        text = (ROOT / 'config/hyprland.conf.in').read_text() + (ROOT / 'scripts/infinite-desktop.conf').read_text()
        self.assertEqual(len(all_binds), len(re.findall(r'^bind[a-z]*\s*=', text, re.M)))
        self.assertEqual(sum('e' in x['flags'] and 'l' in x['flags'] for x in all_binds), 4)

    def test_backend_comes_from_running_provider_not_file_presence(self):
        m = self.module
        with patch.object(m, 'call', return_value='configProvider: lua\n'):
            self.assertEqual(m.runtime_backend(), 'lua')
        with patch.object(m, 'call', return_value='configProvider: hyprlang\n'):
            self.assertEqual(m.runtime_backend(), 'legacy')
        with patch.object(m, 'call', side_effect=['configProvider: unknown', '{"version":"0.56.2"}']):
            with self.assertRaises(RuntimeError): m.runtime_backend()

    def test_managed_include_is_idempotent_and_preserves_personal_text(self):
        m = self.module
        for backend in ['lua', 'legacy']:
            original = '-- personal\nhl.bind("SUPER + Q", function() end)\n' if backend == 'lua' else '# personal\nbind = SUPER,Q,exec,kitty\n'
            include = Path('/tmp/velora managed.' + ('lua' if backend == 'lua' else 'conf'))
            result = m.main_text(original, include, backend)
            self.assertTrue(result.startswith(original))
            self.assertEqual(m.main_text(result, include, backend), result)
            self.assertEqual(result.count('BEGIN VELORA MANAGED'), 1)

    def test_conflicts_use_exact_modifiers_key_and_default_submap(self):
        m = self.module
        bind = m.inventory()[2]
        registered = [{'modmask': 64, 'key': 'r', 'submap': '', 'arg': 'personal'},
                      {'modmask': 65, 'key': 'r', 'arg': 'personal'},
                      {'modmask': 64, 'key': 'r', 'submap': 'custom', 'arg': 'personal'}]
        self.assertEqual(len(m.conflicts([bind], registered)), 1)
        registered[0]['description'] = m.description(bind)
        self.assertEqual(m.conflicts([bind], registered), [])

    def test_registry_rejects_missing_duplicate_and_wrong_commands(self):
        m = self.module
        bind = m.inventory()[0]
        actual = {'modmask': bind['mask'], 'key': bind['key'], 'description': m.description(bind),
                  'dispatcher': 'exec', 'arg': bind['command'], 'repeat': False, 'locked': False}
        self.assertEqual(m.check_registered([bind], [actual], 'legacy'), [])
        self.assertTrue(m.check_registered([bind], [], 'legacy'))
        self.assertTrue(m.check_registered([bind], [actual, actual], 'legacy'))
        self.assertTrue(m.check_registered([bind], [dict(actual, arg='wrong')], 'legacy'))

    def test_both_config_backends_pass_real_hyprland_verify_without_session_mutation(self):
        m = self.module
        for backend in ['lua', 'legacy']:
            with self.subTest(backend=backend):
                snippet = m.generate_lua(m.inventory()) if backend == 'lua' else m.generate_legacy(m.inventory(), '0.56.2')
                m.validate(snippet, backend)
                self.assertNotIn('source =', snippet) if backend == 'lua' else self.assertNotIn('hl.bind', snippet)

    def test_layer_rules_do_not_blur_unknown_fullscreen_namespaces(self):
        m = self.module
        patterns = [re.compile(namespace) for namespace, spec in m.layer_specs().items() if spec.get('blur') == 'on']
        for namespace in ['velora-shell-frame-unknown', 'velora-shell-wallpaper-effects', 'velora-wallpaper-selector', 'personal']:
            self.assertFalse(any(p.fullmatch(namespace) for p in patterns))
        for namespace in ['velora-shell-topbar', 'velora-shell-unified-bar', 'velora-shell-editor', 'velora-shell-shared-widgets']:
            self.assertTrue(any(p.fullmatch(namespace) for p in patterns))

    def test_failed_registration_rolls_back_only_managed_changes(self):
        m = self.module
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp); main = base / 'hyprland.lua'; include = base / 'velora-hyprland.lua'
            main.write_text('personal\n'); include.write_text('-- Velora Shell: previous\n')
            plan = dict(main=main, include=include, original=main.read_text(), proposed='new main', snippet='new snippet', binds=[], backend='lua')
            with patch.object(m, 'call', return_value=''), patch.object(m, 'check_active', return_value=['missing bind']):
                with self.assertRaisesRegex(RuntimeError, 'missing bind'): m.apply(plan)
            self.assertEqual(main.read_text(), 'personal\n')
            self.assertEqual(include.read_text(), '-- Velora Shell: previous\n')


class InstallerPipelineTests(unittest.TestCase):
    def setUp(self):
        self.installer = load('install-session')
        self.tmp = tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.enterContext(patch.dict(os.environ, HOME=str(self.home), XDG_CONFIG_HOME=str(self.home / 'config'),
                                     XDG_DATA_HOME=str(self.home / 'data'), XDG_CACHE_HOME=str(self.home / 'cache')))
        self.preflight = load('preflight')
        self.ready = dict(ready=True, missing=[], packages=[], optionalPending=[], qt='6.12.0', quickshell={'path': '/fixture/qs'})
        self.enterContext(patch.object(self.preflight, 'inspect', return_value=self.ready))
        self.integration = SimpleNamespace(runtime_backend=lambda: 'lua', active_config=lambda *args: self.home / 'hyprland.lua',
            prepare=lambda *args, **kw: {'snippet': 'safe', 'binds': [], 'conflicts': [], 'backend': 'lua'},
            validate=lambda *args: None, diff=lambda *args: 'reviewed diff', apply=lambda *args: None)
        self.notifications = SimpleNamespace(status=lambda: dict(ready=True, conflict=False), claim=lambda: None)
        self.spotify = SimpleNamespace(executable=lambda: None)
        self.bluetooth = SimpleNamespace(status=lambda: dict(hardware=False, active=False, enabled=False, blocked=False))
        self.enterContext(patch.object(self.installer, 'helper', side_effect=lambda name: self.preflight if name == 'preflight'
            else self.notifications if name == 'velora-notifications' else self.spotify if name == 'install-spotify-bridge'
            else self.bluetooth if name == 'velora-bluetooth-setup' else self.integration))
        self.output = io.StringIO(); self.enterContext(contextlib.redirect_stdout(self.output))
        self.fail = None
        def commands(args, **kw):
            if args[0].endswith('/init-config'):
                return subprocess.run(args, **kw)
            if args[0].endswith('/build'):
                return SimpleNamespace(returncode=int(self.fail == 'build'), stdout='/tmp/build\n', stderr='build failed' if self.fail == 'build' else '')
            if args[0].endswith('/runtime-check'):
                return SimpleNamespace(returncode=int(self.fail == 'runtime'), stdout='{}', stderr='runtime failed')
            if len(args) > 1 and 'native-blur' in args[1]:
                return SimpleNamespace(returncode=0, stdout='{"available":true}', stderr='')
            return SimpleNamespace(returncode=0, stdout='', stderr='')
        self.commands = self.enterContext(patch.object(self.installer, 'command', side_effect=commands))

    def test_missing_dependencies_non_interactive_does_not_write_or_install(self):
        self.ready.update(ready=False, missing=['qs', 'cmake'], packages=['quickshell', 'cmake'])
        self.assertEqual(self.installer.main(['--non-interactive', '--without-fanplus']), 1)
        self.assertIn('BLOCKED_MISSING_DEPENDENCIES', self.output.getvalue())
        self.assertFalse((self.home / '.local/bin').exists()); self.commands.assert_not_called()

    def test_non_interactive_config_changes_require_explicit_authorization(self):
        self.assertEqual(self.installer.main(['--non-interactive', '--without-fanplus']), 1)
        self.assertIn('aguardam autorização', self.output.getvalue())
        self.assertFalse((self.home / '.local/bin').exists())

    def test_build_and_runtime_failures_are_distinct_and_not_success(self):
        for failure, state in [('build', 'BUILD_FAILED'), ('runtime', 'RUNTIME_VALIDATION_FAILED')]:
            self.fail = failure
            self.assertEqual(self.installer.main(['--non-interactive', '--without-fanplus', '--accept-hypr-config']), 1)
            self.assertIn(state, self.output.getvalue())
            self.assertFalse((self.home / '.local/bin').exists())

    def test_authorized_install_is_idempotent_and_creates_wallpaper_library(self):
        args = ['--non-interactive', '--without-fanplus', '--accept-hypr-config']
        self.assertEqual(self.installer.main(args), 0)
        config = self.home / 'config/velora-shell/config.json'
        config.write_text('{"personal":true}')
        image = self.home / 'Pictures/Wallpapers/static/existing.png'; image.write_bytes(b'personal')
        self.assertEqual(self.installer.main(args), 0)
        self.assertEqual(config.read_text(), '{"personal":true}'); self.assertEqual(image.read_bytes(), b'personal')
        self.assertTrue((self.home / 'Pictures/Wallpapers/live').is_dir())
        self.assertTrue((self.home / 'Pictures/Wallpapers/WallpaperSelector').is_dir())
        self.assertEqual((self.home / '.local/bin/velora').resolve(), ROOT / 'scripts/velora')

    def test_skip_hypr_and_no_start_cannot_declare_ready(self):
        for flag in ['--skip-hypr', '--no-start']:
            self.assertEqual(self.installer.main(['--non-interactive', '--without-fanplus', '--accept-hypr-config', flag]), 1)
            self.assertIn('RUNTIME_VALIDATION_FAILED', self.output.getvalue())

    def test_private_pywal_requires_explicit_consent_in_non_interactive_install(self):
        self.ready.update(ready=False, missing=['pywal16'], sourceFeatures=['pywal16'])
        self.assertEqual(self.installer.main(['--non-interactive', '--without-fanplus']), 1)
        self.assertIn('--install-pywal', self.output.getvalue())
        self.commands.assert_not_called()
        self.assertFalse((self.home / '.local/bin').exists())

    def test_missing_zen_blocks_unattended_install_without_consent(self):
        self.ready.update(ready=False, missing=['Zen Browser'], sourceFeatures=['zen-browser'])
        self.assertEqual(self.installer.main(['--non-interactive', '--without-fanplus']), 1)
        self.assertIn('BLOCKED_MISSING_DEPENDENCIES', self.output.getvalue())
        self.assertIn('--install-zen', self.output.getvalue())
        self.commands.assert_not_called()

    def test_authorized_zen_install_is_rechecked_before_build(self):
        missing = dict(self.ready, ready=False, missing=['Zen Browser'], sourceFeatures=['zen-browser'])
        self.preflight.inspect.side_effect = [missing, self.ready]
        self.assertEqual(self.installer.main(['--non-interactive', '--without-fanplus', '--accept-hypr-config', '--install-zen']), 0)
        calls = [call.args[0][0] for call in self.commands.call_args_list]
        self.assertLess(calls.index(str(ROOT / 'scripts/install-zen')), calls.index(str(ROOT / 'scripts/build')))
        self.assertEqual(self.preflight.inspect.call_count, 2)

    def test_bluetooth_service_requires_consent_before_mutation(self):
        self.bluetooth.status = lambda: dict(hardware=True, active=False, enabled=False, blocked=True)
        self.assertEqual(self.installer.main(['--non-interactive', '--without-fanplus', '--accept-hypr-config']), 1)
        self.assertIn('--enable-bluetooth', self.output.getvalue())
        self.assertFalse(any("--enable-service" in call.args[0] for call in self.commands.call_args_list))
        self.assertFalse((self.home / ".local/bin").exists())

    def test_bluetooth_enable_is_verified_and_radio_block_reported(self):
        from unittest.mock import Mock
        self.bluetooth.status = Mock(side_effect=[dict(hardware=True, active=False, enabled=False, blocked=True),
            dict(hardware=True, active=True, enabled=True, blocked=True)])
        self.assertEqual(self.installer.main(['--non-interactive', '--without-fanplus', '--accept-hypr-config', '--enable-bluetooth']), 0)
        self.assertIn('READY_WITH_OPTIONAL_FEATURES_PENDING', self.output.getvalue())
        self.assertIn('rfkill', self.output.getvalue())
        self.assertTrue(any('--enable-service' in call.args[0] for call in self.commands.call_args_list))
        self.assertTrue(any(call.args[0] == [str(ROOT / 'scripts/velora'), 'restart'] for call in self.commands.call_args_list))


class PywalResolverTests(unittest.TestCase):
    def test_rejects_legacy_pywal_without_16_color_support(self):
        m = load('velora-wal')
        with patch.object(m.shutil, 'which', return_value='/fixture/wal'), patch.object(m.Path, 'is_file', return_value=False), \
             patch.object(m.subprocess, 'run', return_value=SimpleNamespace(returncode=0, stdout='--backend', stderr='')):
            self.assertFalse(m.select_wal()[0])

    def test_compatible_system_wal_wins_without_creating_private_install(self):
        m = load('velora-wal')
        with patch.object(m.shutil, 'which', return_value='/system/wal'), patch.object(m.Path, 'is_file', return_value=True), \
             patch.object(m.subprocess, 'run', side_effect=[SimpleNamespace(returncode=0, stdout='--cols16 --out-dir', stderr=''),
                                                        SimpleNamespace(returncode=0, stdout='', stderr='wal 3.8.15')]) as run:
            self.assertEqual(m.select_wal()[0]['path'], '/system/wal')
            self.assertEqual(run.call_count, 2)


class InfiniteDesktopTransportTests(unittest.TestCase):
    def test_existing_actions_map_to_lua_including_disabled_canvas_fallback(self):
        m = load('infinite-desktop')
        actions = ['movefocus l', 'workspace e-1', 'setfloating address:0xabc', 'settiled address:0xabc',
                   'movewindowpixel exact -80 120,address:0xabc', 'resizewindowpixel exact 800 600,address:0xabc',
                   'focuswindow address:0xabc', 'movecursor 300 400']
        for action in actions:
            expression = m.lua_dispatch('dispatch ' + action)
            self.assertIn('hl.dsp.', expression)
        self.assertIn('direction="left"', m.lua_dispatch('dispatch movefocus l'))
        self.assertIn('relative=false', m.lua_dispatch('dispatch movewindowpixel exact -80 120,address:0xabc'))
        with self.assertRaises(m.HyprlandError): m.lua_dispatch('dispatch exec dangerous')
        with patch.object(m, '_hyprland_backend', 'lua'), patch.object(m.subprocess, 'run', return_value=SimpleNamespace(returncode=0, stdout='ok', stderr='')) as run:
            m.hyprctl_batch(['dispatch movefocus l'])
            self.assertEqual(run.call_args.args[0][1], 'eval')
        with patch.object(m, '_hyprland_backend', 'legacy'), patch.object(m.subprocess, 'run', return_value=SimpleNamespace(returncode=0, stdout='ok', stderr='')) as run:
            m.hyprctl_batch(['dispatch movefocus l'])
            self.assertEqual(run.call_args.args[0][1], '--batch')
