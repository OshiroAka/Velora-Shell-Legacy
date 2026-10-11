# Velora Shell

A desktop shell for Hyprland built with Quickshell and Qt Quick. One process
provides the sidebar, top bar, notifications, application search, system
controls, wallpaper library, desktop widgets, visual lock scene and editor.

## Install

Keep this checkout at its permanent location. The installer links commands
to it; it does not maintain a second source copy.

```sh
./install.sh
./scripts/velora start
```

Use `./install.sh --skip-hypr` to leave compositor configuration untouched, or
`--without-infinite-desktop` to disable the optional floating-window canvas.
The default installation adds a managed include to the user's Hyprland
configuration. Review `config/hyprland.conf.in` for its rules and bindings.

```sh
velora status
velora restart
velora stop
velora ipc composition status
```

Super+K opens wallpapers, Super+W opens search, Super+R opens settings, and
Super+L toggles the visual lock scene. Print and Shift+Print capture the
screen and a selected area. **The visual lock scene does not authenticate
users or secure the session.** Use an authenticated locker when needed.

## Desktop controls

- The top bar hosts display settings and a compact palette brush. The brush
  remixes wallpaper colors for the bars and pywal, preserves the choice, and
  adjusts text contrast for light and dark surfaces.
- Wi-Fi, Bluetooth, notification history, volume and brightness live in the
  sidebar with connected animated panels. The sidebar clock is display-only.
- Super+W opens animated application search ordered by recorded usage.
- Display changes include confirmation and automatic rollback. Volume and
  brightness keys reveal the corresponding compact sidebar control.
- Desktop settings control widgets, wallpaper effects, visualizer and blur.

## Dependencies

The validated combination is Qt 6.11.2, Hyprland 0.56.2 and upstream
[Quickshell revision 7d1c9a9](https://github.com/quickshell-mirror/quickshell/commit/7d1c9a9c6721606b129829134d6f614f015621e2).
Quickshell must be compiled against compatible Qt libraries. The compositor
plugin must be rebuilt when the installed Hyprland ABI changes.

Build tools: a C++23 compiler, CMake, pkg-config, Qt 6 development packages,
Hyprland development headers, libpulse and fftw3. Python 3, Bash, jq and
ripgrep are needed for helpers. Qt Quick Controls, Qt Multimedia,
Qt5Compat GraphicalEffects and Qt Shader Tools must be available.

If the system Quickshell package cannot run with the installed Qt version:

```sh
./scripts/build-quickshell
```

This optional command downloads pinned upstream Quickshell and CLI11 sources,
builds outside the checkout and installs under the user's XDG data directory.
It requires Quickshell's development dependencies, including Wayland,
wayland-protocols, PipeWire, jemalloc, libdrm, libxcb, PAM and polkit.
The launcher automatically selects this installation when present.

Feature dependencies include `playerctl`, `wpctl`, NetworkManager (`nmcli`),
BlueZ (`bluetoothctl`), `brightnessctl`, `powerprofilesctl`, `xdg-open`,
`notify-send`, `ffmpeg`, ImageMagick, Pillow, `wal` (pywal16), `zenity`,
`grim` and `slurp`. Wallpapers use `awww`/`swww`, `mpvpaper`, or
`linux-wallpaperengine` built against the installed FFmpeg libraries.
Optional integrations include cava/glava,
EasyEffects, Kitty, terminal themes and application themes.

Spotify catalogue search requires Spotify with Spicetify. Add the extension
`integrations/spotify/velora-spotify-bridge.js` to your Spicetify extensions,
enable it in Spicetify, and run `python3 ./scripts/velora-spotify-bridge` while
Spotify is open. This optional helper listens on `127.0.0.1:8765`; credentials
stay in the Spotify client and bridge state goes to the user's XDG cache.
Playback controls use MPRIS and work without this helper. Lyrics use LRCLIB.

## Source layout

| Directory or file | Responsibility |
| --- | --- |
| `shell.qml` | Single Quickshell entrypoint |
| `ShellController.qml` | Sidebar, notifications, search, system controls and wallpaper UI |
| `CompositionController.qml` | Widgets, visual lock, editor, profiles and appearance |
| `components/` | Shared shell controls and popup views |
| `core/`, `services/`, `platform/` | Configuration, state, media and compositor services |
| `features/`, `surfaces/` | Scene contents and Wayland surfaces |
| `scripts/` | Shared runtime helpers and installation tools |
| `native/spectrum/`, `native/visualizer/` | Native audio rendering modules |
| `native/hyprland/` | Compositor refraction and surface geometry |
| `assets/`, `shaders/`, `themes/` | Interface resources and public defaults |
| `config/` | Public configuration, schema and compositor template |

## User data

Configuration lives in `$XDG_CONFIG_HOME/velora-shell`, profiles and imported
images in `$XDG_DATA_HOME/velora-shell`, and persistent settings in
`$XDG_STATE_HOME/velora-shell`. The defaults follow the XDG conventions when
these variables are unset. Build products and palettes go to
`$XDG_CACHE_HOME/velora-shell`; wallpaper helpers also retain the existing
`~/.cache/velora-shell` state convention.

Personal wallpapers, gallery images, avatars, presets and account credentials
are not bundled. Choose them in settings. A new installation works with a
neutral avatar and empty personal image slots. Set `VELORA_NOTIFICATION_SOUND`
or a `notification-sound` file inside the user configuration directory to use
a custom sound; otherwise the freedesktop message sound is used.

An existing isolated installation can be imported once, with the shell stopped:

```sh
./scripts/migrate-state /path/to/previous-state --assets /path/to/previous-runtime
```

This explicit importer preserves user data outside the checkout. Normal
startup reads only the current configuration and public defaults.
`.helixpack` packages and the `helix-asset://` package URI remain supported
as stable interchange formats for existing composition exports.

## Validation

```sh
./scripts/build
./scripts/runtime-check --parse
./scripts/runtime-check
```

Parsing requires a Wayland session but does not create the shell surfaces.
The last command checks an already running instance and omits personal data.
Compiled `.qsb` shaders are runtime assets; regenerate them with Qt's `qsb`
after changing the corresponding shader sources.

Licensed under GPL-3.0; see `LICENSE`. Font licenses are included in
`assets/fonts/`.
