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

The installer checks dependencies and QML imports, builds native modules,
detects the running Hyprland configuration backend (Lua or hyprlang), and
shows the managed include and any exact shortcut conflicts for approval.
It preserves personal configuration and verifies all 28 official shortcuts
after reloading the configuration. Reinstallation keeps one managed include.
Use `--without-infinite-desktop` to omit the canvas's 16 shortcuts.

Missing repository packages can be installed with explicit approval. pywal16
is offered separately from PyPI, pinned and hash-verified in a private venv;
an existing compatible installation is reused. For unattended installation,
review the diff first with `./install.sh --dry-run`, then use:

```sh
./install.sh --non-interactive --install-deps --install-pywal --install-zen \
  --accept-hypr-config --replace-conflicts
```

These flags authorize package installation and taking over only the official
key combinations shown in the preview. `--skip-hypr` preserves compositor
configuration but leaves installation incomplete, as does `--no-start`.
The final state is `READY`, `READY_WITH_OPTIONAL_FEATURES_PENDING`,
`BLOCKED_MISSING_DEPENDENCIES`, `BUILD_FAILED`, or `RUNTIME_VALIDATION_FAILED`.
Fan+ remains optional and the normal installer only inspects its readiness.

Velora must own the notification service. When Dunst, Mako or SwayNC already
owns it, installation reports the exact conflict and asks before stopping that
user service. `--replace-notification-server` grants this consent explicitly.
The preference is retained for later starts; the competing service is neither
uninstalled nor disabled. An unknown daemon is preserved. Runtime validation
checks that the active Velora process actually owns the D-Bus service.

Commands are linked into `~/.local/bin`. If it is absent from PATH, the
installer prints the command for the current shell and an absolute launcher;
it does not edit shell startup files. It creates `~/Pictures/Wallpapers` with
`static`, `WallpaperSelector`, and `live` directories, preserving existing images.

```sh
velora status
velora restart
velora stop
velora ipc composition status
```

Super+K opens wallpapers, Super+W opens search, Super+R opens settings, and
Super+F opens Zen Browser, and Super+L toggles the visual
lock scene. Print and Shift+Print capture the
screen and a selected area. **The visual lock scene does not authenticate
users or secure the session.** Use an authenticated locker when needed.

Captures are saved in `~/Pictures/Screenshots` and copied as PNG to the Wayland
clipboard. `wl-clipboard` is required; a failed copy is reported as a failure,
and cancelling selection keeps the previous clipboard unchanged.

Workspace changes use a smooth 900 ms vertical slide, with the shell bars
fixed: moving to a higher workspace slides up; returning slides down.
Both the shortcut and animation are installed by default for Lua and hyprlang.
The installer reuses a working Zen installation or offers the official Linux
release, verifies its SHA256, and installs under the user's XDG data directory.
It does not change the default browser or install AUR packages.
`--install-zen` authorizes this download in unattended mode; without consent,
a missing Zen leaves installation blocked rather than reporting success.

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

The Arch runtime was validated with Qt 6.12.0, Hyprland 0.56.2 and the
distribution's Quickshell 0.3.2. The preflight tests QML imports rather than
accepting an executable merely because it exists.
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
The launcher prefers a compatible system package and uses this installation
only when the system executable is absent or incompatible.

On Arch/CachyOS, mandatory packages include `quickshell`, `cmake`, `make`,
`gcc`, `pkgconf`, `qt6-base`, `qt6-declarative`, `qt6-multimedia`,
`qt6-shadertools`, `qt6-5compat`, `qt6-wayland`, `qt6-svg`, `libpulse`,
`fftw`, `python`, `python-pillow`, `imagemagick`, `bash`, `jq`, `ripgrep`,
`networkmanager`, `wireplumber`, `brightnessctl`, `grim`, `slurp`,
`wl-clipboard`, and `libnotify`, plus
standard `coreutils`, `util-linux`, and `systemd` tools. Static wallpapers
require `awww` with its daemon, or an existing `swww` with its daemon.
Adaptive palettes require pywal16; `--install-pywal` installs it without
modifying system Python. `./scripts/preflight --json` reports exact missing
requirements and package names. Hyprland headers are checked separately for
the optional native plugin; a mismatched ABI is rejected with a safe fallback.

The image picker requires `zenity`; preflight checks it before startup. Failed
or cancelled selections restore Settings without blocking subsequent openings.
On computers with Bluetooth hardware, preflight also requires `bluez`,
`bluez-utils` and `blueman`. Installation offers to enable `bluetooth.service`
with explicit consent (`--enable-bluetooth` for unattended installs); it preserves
radio blocks and paired devices. A blocked radio is reported with an actionable
pending state. When installation starts BlueZ, it reopens Velora to refresh its
Bluetooth connection; runtime verification checks that the shell sees the
adapter as well as checking the service. Optional feature dependencies include `playerctl`,
`powerprofilesctl`, `xdg-open`, and `ffmpeg`.
Animated wallpapers use `mpvpaper`, or
`linux-wallpaperengine` built against the installed FFmpeg libraries.
Optional integrations include cava/glava,
EasyEffects, Kitty, terminal themes and application themes.

Spotify catalogue search requires Spotify with Spicetify. The installer offers
the existing extension when it detects Spicetify, including a private CLI in
`~/.spicetify`. Review `./scripts/install-spotify-bridge`, then use
`./scripts/install-spotify-bridge --apply`, or `./install.sh --install-spotify-bridge`.
It preserves personal extensions and Marketplace, injects Velora's JS, and
enables the user's `velora-spotify-bridge.service`. Spotify needs restarting to
load newly injected code; installation does not interrupt playback itself.
Subsequent reinstalls retain the approved integration. This optional helper
listens on `127.0.0.1:8765`; credentials stay in the Spotify client and bridge
state goes to the user's XDG cache. Search definitions come from the installed
client's own search bundle, including when Spotify is on Home.
Playback controls use MPRIS and work without this helper. Lyrics use LRCLIB.

Zen uses the shell's final palette, including selected surface/tone and neutral
wallpaper correction, instead of independently tinting the raw wal palette.
Palette generation refreshes existing managed browser CSS without changing
personal imports or preferences. The sidebar clock uses the same bundled
Liberation Serif face as the edge Lyrics panel, with a thin weight and no glow.
Zen's new-tab clock uses this bundled serif face in italic, at normal weight
without shadows, so a clean installation does not depend on system fonts.

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
