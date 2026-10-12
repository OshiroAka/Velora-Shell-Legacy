#!/usr/bin/env python3
import argparse
import colorsys
import configparser
import datetime
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path


BASE = Path(__file__).resolve().parents[1]
WAL_PATH = Path(os.path.expanduser("~/.cache/wal/colors.json"))
SHELL_PALETTE_PATH = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") / "velora-shell/pywal/colors.json"
STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "velora-shell"
STATE_PATH = STATE_DIR / "zen-theme.json"
WEB_MODE_PATH = STATE_DIR / "zen-web-mode"
WEB_MODE_DEFAULT = "balance"
WEB_MODES = {"balance", "clean"}
CHROME_CSS_NAME = "velora-pywal.css"
CONTENT_CSS_NAME = "velora-content.css"
USER_CHROME_MARKER = "Velora Shell wallpaper sync userChrome"
USER_CONTENT_MARKER = "Velora Shell wallpaper sync userContent"
ZEN_THEMES_MARKER = "Velora Shell wallpaper sync zen-themes"
USER_JS_MARKER = "Velora Shell wallpaper sync prefs"
LEGACY_PREF = "toolkit.legacyUserProfileCustomizations.stylesheets"
TRANSPARENT_BROWSER_PREF = "browser.tabs.allow_transparent_browser"
ZEN_LINUX_TRANSPARENCY_PREF = "zen.widget.linux.transparency"
ZEN_REPLACE_NEWTAB_PREF = "zen.urlbar.replace-newtab"
NEW_TAB_NOVA_PREF = "browser.newtabpage.activity-stream.nova.enabled"
NEW_TAB_WIDGETS_PREF = "browser.newtabpage.activity-stream.widgets.enabled"
NEW_TAB_WIDGETS_SYSTEM_PREF = "browser.newtabpage.activity-stream.widgets.system.enabled"
NEW_TAB_CLOCK_PREF = "browser.newtabpage.activity-stream.widgets.clocks.enabled"
NEW_TAB_CLOCK_SYSTEM_PREF = "browser.newtabpage.activity-stream.widgets.system.clocks.enabled"
NEW_TAB_CLOCK_SIZE_PREF = "browser.newtabpage.activity-stream.widgets.clocks.size"
NEW_TAB_CLOCK_FORMAT_PREF = "browser.newtabpage.activity-stream.widgets.clocks.hourFormat"
NEW_TAB_CLOCK_ZONES_PREF = "browser.newtabpage.activity-stream.widgets.clocks.zones"
NEW_TAB_SEARCH_PREF = "browser.newtabpage.activity-stream.showSearch"
NEW_TAB_TOP_SITES_PREF = "browser.newtabpage.activity-stream.feeds.topsites"
NEW_TAB_STORIES_PREF = "browser.newtabpage.activity-stream.feeds.section.topstories"
NEW_TAB_WALLPAPERS_PREF = "browser.newtabpage.activity-stream.newtabWallpapers.enabled"
NEW_TAB_CLOCK_ZONE = json.dumps([
    {
        "timeZone": "America/Sao_Paulo",
        "city": "São Paulo",
        "label": None,
        "labelColor": None,
    }
], separators=(",", ":"))
MANAGED_PREFS = [
    (LEGACY_PREF, True),
    (TRANSPARENT_BROWSER_PREF, True),
    (ZEN_LINUX_TRANSPARENCY_PREF, True),
    (ZEN_REPLACE_NEWTAB_PREF, False),
    (NEW_TAB_NOVA_PREF, True),
    (NEW_TAB_WIDGETS_PREF, True),
    (NEW_TAB_WIDGETS_SYSTEM_PREF, True),
    (NEW_TAB_CLOCK_PREF, True),
    (NEW_TAB_CLOCK_SYSTEM_PREF, True),
    (NEW_TAB_CLOCK_SIZE_PREF, "small"),
    (NEW_TAB_CLOCK_FORMAT_PREF, "24"),
    (NEW_TAB_CLOCK_ZONES_PREF, NEW_TAB_CLOCK_ZONE),
    (NEW_TAB_SEARCH_PREF, False),
    (NEW_TAB_TOP_SITES_PREF, False),
    (NEW_TAB_STORIES_PREF, False),
    (NEW_TAB_WALLPAPERS_PREF, False),
]

PORTUGUESE_MONTHS = (
    "janeiro",
    "fevereiro",
    "março",
    "abril",
    "maio",
    "junho",
    "julho",
    "agosto",
    "setembro",
    "outubro",
    "novembro",
    "dezembro",
)


def clamp(value, low=0, high=255):
    return max(low, min(high, int(round(value))))


def hex_to_rgb(value):
    value = str(value or "").strip().lstrip("#")
    if len(value) != 6:
        raise ValueError("invalid hex color")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def rgb_to_hex(rgb):
    return "#{:02x}{:02x}{:02x}".format(*(clamp(v) for v in rgb))


def rgba(rgb, alpha):
    r, g, b = (clamp(v) for v in rgb)
    return f"rgba({r}, {g}, {b}, {alpha:.2f})"


def mix(a, b, amount):
    return tuple(a[i] + (b[i] - a[i]) * amount for i in range(3))


def luminance(rgb):
    def channel(value):
        value = value / 255
        return value / 12.92 if value <= 0.03928 else ((value + 0.055) / 1.055) ** 2.4

    r, g, b = (channel(v) for v in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def hsv(rgb):
    r, g, b = (max(0, min(255, v)) / 255 for v in rgb)
    return colorsys.rgb_to_hsv(r, g, b)


def hue_distance(a, b):
    diff = abs(a - b) % 1.0
    return min(diff, 1.0 - diff)


def rgb_distance(a, b):
    return sum((a[i] - b[i]) ** 2 for i in range(3)) ** 0.5


def readable_text(background):
    return (250, 245, 252) if luminance(background) < 0.42 else (58, 49, 68)


def text_on(color):
    return (255, 255, 255) if luminance(color) < 0.42 else (60, 50, 70)


def palette_candidates(palette):
    preferred = [9, 10, 11, 12, 13, 14, 1, 2, 3, 4, 5, 6, 8]
    result = []
    seen = set()
    for index in preferred:
        if index < len(palette) and palette[index] not in seen:
            result.append(palette[index])
            seen.add(palette[index])
    for index, color in enumerate(palette):
        if index in (0, 7, 15):
            continue
        if color not in seen:
            result.append(color)
            seen.add(color)
    return result


def palette_score(color, background):
    _, saturation, value = hsv(color)
    contrast = abs(luminance(color) - luminance(background))
    distance = min(1.0, rgb_distance(color, background) / 255)
    neutral_penalty = 0.35 if saturation < 0.10 else 0.0
    return saturation * 0.48 + value * 0.20 + contrast * 0.20 + distance * 0.12 - neutral_penalty


def pick_accent(palette, background, used=None, fallback=(232, 166, 200)):
    used = used or []
    ranked = sorted(palette_candidates(palette), key=lambda color: palette_score(color, background), reverse=True)
    for color in ranked:
        if rgb_distance(color, background) < 28:
            continue
        if all(hue_distance(hsv(color)[0], hsv(other)[0]) >= 0.10 or rgb_distance(color, other) >= 46 for other in used):
            return color
    for color in ranked:
        if rgb_distance(color, background) >= 28:
            return color
    return ranked[0] if ranked else fallback


def normalize_web_mode(mode):
    mode = str(mode or "").strip().lower()
    return mode if mode in WEB_MODES else WEB_MODE_DEFAULT


def read_web_mode():
    try:
        return normalize_web_mode(WEB_MODE_PATH.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return WEB_MODE_DEFAULT
    except Exception:
        return WEB_MODE_DEFAULT


def write_web_mode(mode):
    mode = normalize_web_mode(mode)
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    WEB_MODE_PATH.write_text(mode + "\n", encoding="utf-8")
    return mode


def load_wal_palette():
    # The shell palette includes the chosen surface/tone and neutral wallpaper
    # correction. Raw wal may still contain a tinted preview/background.
    path = SHELL_PALETTE_PATH if SHELL_PALETTE_PATH.is_file() else WAL_PATH
    raw = json.loads(path.read_text(encoding="utf-8"))
    raw['veloraSource'] = str(path)
    colors = raw.get("colors", {})
    special = raw.get("special", {})
    background = hex_to_rgb(special.get("background") or colors.get("color0"))
    foreground = hex_to_rgb(special.get("foreground") or colors.get("color7"))
    palette = [hex_to_rgb(colors[f"color{i}"]) for i in range(16) if f"color{i}" in colors]
    if len(palette) < 8:
        raise ValueError("pywal palette is incomplete")
    return raw, background, foreground, palette


def build_palette():
    raw, background, foreground, palette = load_wal_palette()
    avg_luma = sum(luminance(color) for color in [background] + palette) / (len(palette) + 1)
    dark = raw.get('tone') == 'dark' if raw.get('tone') in ('dark', 'light') else luminance(background) < 0.30 and avg_luma < 0.44
    accent = pick_accent(palette, background, fallback=(232, 166, 200))
    accent_two = pick_accent(palette, background, [accent], fallback=(196, 148, 242))
    accent_three = pick_accent(palette, background, [accent, accent_two], fallback=(168, 216, 255))

    if dark:
        base = mix(background, (0, 0, 0), 0.16)
        surface = mix(base, accent, 0.16)
        surface_two = mix(base, accent_two, 0.20)
        surface_three = mix(base, accent_three, 0.15)
        field = mix(base, (255, 255, 255), 0.08)
        text = mix(foreground, (255, 255, 255), 0.28)
        text_muted = mix(text, background, 0.38)
        border = mix(accent, (255, 255, 255), 0.12)
        shadow = (0, 0, 0)
        mode = "dark"
    else:
        base = mix(background, (255, 255, 255), 0.78)
        surface = mix(base, accent_two, 0.15)
        surface_two = mix(base, accent, 0.18)
        surface_three = mix((255, 255, 255), accent, 0.08)
        field = mix((255, 255, 255), accent_two, 0.09)
        text = readable_text(surface)
        text_muted = mix(text, (255, 255, 255), 0.34)
        border = mix(accent, (255, 255, 255), 0.44)
        shadow = mix(accent_two, background, 0.62)
        mode = "light" if luminance(background) > 0.55 and avg_luma > 0.50 else "balanced"

    if raw.get('velora', {}).get('exactSurface'):
        base = surface = surface_two = surface_three = background
        field = mix(background, foreground, .08)
        text = foreground
        text_muted = hex_to_rgb(raw['velora'].get('muted') or rgb_to_hex(mix(foreground, background, .28)))
    return {
        "source": raw['veloraSource'],
        "mode": mode,
        "wallpaper": raw.get("wallpaper", ""),
        "checksum": raw.get("checksum", ""),
        "background": background,
        "foreground": foreground,
        "base": base,
        "surface": surface,
        "surface_two": surface_two,
        "surface_three": surface_three,
        "field": field,
        "text": text,
        "text_muted": text_muted,
        "accent": accent,
        "accent_two": accent_two,
        "accent_three": accent_three,
        "border": border,
        "shadow": shadow,
        "button_text": text_on(accent),
    }


def css_header(palette):
    generated = datetime.datetime.now().astimezone().isoformat(timespec="seconds")
    return (
        "/*\n"
        " * Velora Shell generated Zen Browser theme.\n"
        f" * Generated: {generated}\n"
        f" * Wallpaper: {palette.get('wallpaper') or 'unknown'}\n"
        f" * Source: {palette.get('source', str(WAL_PATH))}\n"
        " * Do not edit this file directly; edit velora-zen-theme.py instead.\n"
        " */\n\n"
    )


def pref_value(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    return json.dumps(value)


def managed_pref_lines():
    return "\n".join(f'user_pref("{name}", {pref_value(value)});' for name, value in MANAGED_PREFS)


def strip_managed_pref_lines(lines):
    names = tuple(name for name, _ in MANAGED_PREFS)
    return [line for line in lines if not any(f'user_pref("{name}"' in line for name in names)]


def clock_date_rules():
    """Map the native clock datetime attribute to a pt-BR day/month label."""
    rules = []
    for month, month_name in enumerate(PORTUGUESE_MONTHS, start=1):
        for day in range(1, 32):
            rules.append(
                f'.clocks-row:has(.clocks-time[datetime*="-{month:02d}-{day:02d}T"])::after '
                f'{{ content: "{day} de {month_name}"; }}'
            )
    return "\n  ".join(rules)


def generate_chrome_css(palette):
    dark = palette["mode"] == "dark"
    return css_header(palette) + f""":root {{
  color-scheme: {"dark" if dark else "light"} !important;
  --velora-wallpaper-bg: {rgb_to_hex(palette["background"])};
  --velora-wallpaper-fg: {rgb_to_hex(palette["foreground"])};
  --velora-bg: {rgb_to_hex(palette["base"])};
  --velora-clear: transparent;
  --velora-surface: {rgba(palette["surface"], 0.78 if dark else 0.72)};
  --velora-surface-strong: {rgba(palette["surface_two"], 0.90 if dark else 0.84)};
  --velora-surface-soft: {rgba(palette["surface_three"], 0.58 if dark else 0.66)};
  --velora-field: {rgba(palette["field"], 0.76 if dark else 0.70)};
  --velora-text: {rgb_to_hex(palette["text"])};
  --velora-text-muted: {rgb_to_hex(palette["text_muted"])};
  --velora-accent: {rgb_to_hex(palette["accent"])};
  --velora-accent-2: {rgb_to_hex(palette["accent_two"])};
  --velora-accent-3: {rgb_to_hex(palette["accent_three"])};
  --velora-accent-text: {rgb_to_hex(palette["button_text"])};
  --velora-border: {rgba(palette["border"], 0.46 if dark else 0.62)};
  --velora-shadow: {rgba(palette["shadow"], 0.34 if dark else 0.16)};

  --zen-primary-color: var(--velora-surface-strong) !important;
  --zen-colors-primary: var(--velora-accent) !important;
  --zen-colors-secondary: var(--velora-surface) !important;
  --zen-colors-tertiary: var(--velora-bg) !important;
  --zen-colors-border: var(--velora-border) !important;
  --zen-main-browser-background: transparent !important;
  --zen-navigator-toolbox-background: var(--velora-surface) !important;
  --zen-themed-toolbar-bg: var(--velora-surface) !important;
  --zen-branding-bg: transparent !important;

  --toolbar-bgcolor: var(--velora-surface) !important;
  --toolbar-color: var(--velora-text) !important;
  --toolbar-field-background-color: var(--velora-field) !important;
  --toolbar-field-focus-background-color: var(--velora-surface-strong) !important;
  --toolbar-field-color: var(--velora-text) !important;
  --toolbar-field-focus-color: var(--velora-text) !important;
  --toolbarbutton-icon-fill: var(--velora-text-muted) !important;
  --toolbarbutton-icon-fill-attention: var(--velora-accent) !important;
  --toolbarbutton-hover-background: color-mix(in srgb, var(--velora-accent), transparent 82%) !important;
  --toolbarbutton-active-background: color-mix(in srgb, var(--velora-accent), transparent 70%) !important;

  --browser-bg: transparent !important;
  --lwt-accent-color: transparent !important;
  --lwt-text-color: var(--velora-text) !important;
  --lwt-sidebar-background-color: var(--velora-surface) !important;
  --lwt-sidebar-text-color: var(--velora-text) !important;
  --tabpanel-background-color: transparent !important;
  --in-content-page-background: var(--velora-bg) !important;
  --in-content-page-color: var(--velora-text) !important;
  --in-content-box-background: var(--velora-surface-strong) !important;
  --in-content-box-background-odd: var(--velora-surface) !important;
  --in-content-border-color: var(--velora-border) !important;
  --in-content-accent-color: var(--velora-accent) !important;
  --in-content-primary-button-background: var(--velora-accent) !important;
  --in-content-primary-button-text-color: var(--velora-accent-text) !important;
  --tab-selected-bgcolor: color-mix(in srgb, var(--velora-accent), transparent 74%) !important;
  --tab-hover-background-color: color-mix(in srgb, var(--velora-accent-2), transparent 84%) !important;
  --arrowpanel-background: var(--velora-surface-strong) !important;
  --arrowpanel-color: var(--velora-text) !important;
  --arrowpanel-border-color: var(--velora-border) !important;
  --urlbarView-highlight-background: color-mix(in srgb, var(--velora-accent), transparent 72%) !important;
  --urlbarView-highlight-color: var(--velora-text) !important;
  --newtab-background-color: transparent !important;
}}

#main-window,
#browser,
#appcontent,
#tabbrowser-tabbox,
#tabbrowser-tabpanels,
#tabbrowser-tabpanels > hbox,
#tabbrowser-tabpanels > vbox,
#tabbrowser-tabpanels browser,
#tabbrowser-tabpanels .browserStack,
#tabbrowser-tabpanels .browserStack browser,
#appcontent .browserStack,
#appcontent .browserContainer,
#appcontent .browserSidebarContainer,
#appcontent browser,
#appcontent browser[blank],
#appcontent browser[primary],
.browserStack,
.browserContainer,
.browserSidebarContainer,
#zen-main-app-wrapper,
#zen-appcontent-wrapper,
#zen-tabbox-wrapper,
#zen-appcontent-navbar-container,
#zen-appcontent-navbar-wrapper {{
  background: transparent !important;
  background-color: transparent !important;
}}

browser[transparent="true"],
#tabbrowser-tabpanels browser[transparent="true"],
#tabbrowser-tabpanels .browserStack > browser[transparent="true"] {{
  background: transparent !important;
  background-color: transparent !important;
}}

#navigator-toolbox,
#navigator-toolbox-background,
#nav-bar,
#TabsToolbar,
#PersonalToolbar,
#titlebar,
#tabbrowser-tabs,
#tabbrowser-arrowscrollbox,
#vertical-tabs,
#zen-sidebar-icons-wrapper,
#zen-sidebar-splitter,
#zen-sidebar-web-panel,
#zen-sidebar-web-panel-wrapper,
#zen-sidebar-top-buttons-wrapper,
#zen-sidebar-top-buttons,
#zen-sidebar-foot-buttons,
#zen-sidebar-foot-buttons-wrapper,
#zen-browser-sidebar-wrapper,
#zen-tabs-wrapper,
#zen-essentials-container,
#zen-workspaces-button,
#sidebar-box,
#sidebar-header,
#sidebar {{
  background: var(--velora-surface) !important;
  background-color: var(--velora-surface) !important;
  color: var(--velora-text) !important;
  border-color: var(--velora-border) !important;
  backdrop-filter: blur(18px) saturate(1.22) !important;
}}

#main-window[zen-compact-mode="true"] #browser,
#main-window[zen-compact-mode="true"] #tabbrowser-tabpanels {{
  background: transparent !important;
}}

#main-window :is(
  #navigator-toolbox,
  #navigator-toolbox-background,
  #nav-bar,
  #TabsToolbar,
  #titlebar,
  #vertical-tabs,
  #zen-sidebar-icons-wrapper,
  #zen-sidebar-top-buttons-wrapper,
  #zen-sidebar-top-buttons,
  #zen-sidebar-foot-buttons,
  #zen-sidebar-foot-buttons-wrapper,
  #zen-appcontent-navbar-container,
  #zen-appcontent-navbar-wrapper,
  #zen-browser-sidebar-wrapper
) {{
  border: 0 !important;
  outline: 0 !important;
}}

#navigator-toolbox,
#nav-bar,
#zen-appcontent-navbar-container,
#zen-appcontent-navbar-wrapper {{
  border-block: 0 !important;
}}

#zen-sidebar-icons-wrapper,
#zen-sidebar-top-buttons-wrapper,
#zen-sidebar-top-buttons {{
  border-block-start: 0 !important;
}}

#main-window :is(#nav-bar, #TabsToolbar, #PersonalToolbar, #vertical-tabs, #zen-sidebar-icons-wrapper, #zen-sidebar-top-buttons, #zen-sidebar-foot-buttons, #zen-appcontent-navbar-wrapper, #zen-browser-sidebar-wrapper) {{
  box-shadow: none !important;
}}

.tab-background,
toolbarbutton,
.bookmark-item,
.PanelUI-zen-profiles-item,
.download-state,
.urlbarView-row,
.searchbar-engine-one-off-item {{
  transition: background-color 160ms ease, border-color 160ms ease, color 160ms ease, fill 160ms ease !important;
}}

.tabbrowser-tab[selected] .tab-background {{
  background: linear-gradient(135deg,
    color-mix(in srgb, var(--velora-accent), transparent 70%),
    color-mix(in srgb, var(--velora-accent-2), transparent 78%)) !important;
  border: 1px solid color-mix(in srgb, var(--velora-accent), transparent 50%) !important;
  box-shadow: 0 8px 26px var(--velora-shadow) !important;
}}

.tabbrowser-tab:hover .tab-background,
toolbarbutton:hover,
.bookmark-item:hover {{
  background-color: color-mix(in srgb, var(--velora-accent-2), transparent 84%) !important;
}}

#urlbar-background,
#searchbar,
.urlbarView,
panel,
menupopup > .popup-internal-box,
.panel-subview-body {{
  background: var(--velora-surface-strong) !important;
  color: var(--velora-text) !important;
  border-color: var(--velora-border) !important;
}}

#urlbar[breakout-extend="true"] #urlbar-background,
#urlbar[breakout-extend="true"] .urlbar-background {{
  background: color-mix(in srgb, var(--velora-surface-strong), transparent 8%) !important;
  border: 1px solid color-mix(in srgb, var(--velora-accent), transparent 48%) !important;
  box-shadow: 0 18px 46px var(--velora-shadow) !important;
  backdrop-filter: blur(24px) saturate(1.35) !important;
}}

.urlbarView-row[selected],
.searchbar-engine-one-off-item[selected],
menuitem[_moz-menuactive="true"] {{
  background-color: color-mix(in srgb, var(--velora-accent), transparent 72%) !important;
  color: var(--velora-text) !important;
}}

#identity-icon,
#tracking-protection-icon,
.urlbarView-favicon,
toolbarbutton[open] .toolbarbutton-icon,
toolbarbutton[checked] .toolbarbutton-icon {{
  fill: var(--velora-accent) !important;
  color: var(--velora-accent) !important;
}}

tooltip {{
  appearance: none !important;
  background: var(--velora-surface-strong) !important;
  color: var(--velora-text) !important;
  border: 1px solid var(--velora-border) !important;
  border-radius: 9px !important;
  box-shadow: 0 12px 32px var(--velora-shadow) !important;
}}
"""


def generate_content_css(palette, web_mode=None):
    dark = palette["mode"] == "dark"
    web_mode = normalize_web_mode(web_mode)
    if web_mode == "clean":
        site_bg = "transparent"
        site_bg_color = "transparent"
        site_backdrop = "none"
    else:
        site_a = mix(palette["surface"], palette["background"], 0.18 if dark else 0.28)
        site_b = mix(palette["surface_two"], palette["background"], 0.24 if dark else 0.34)
        site_bg = (
            "linear-gradient(135deg, "
            f"{rgba(site_a, 0.70 if dark else 0.78)}, "
            f"{rgba(site_b, 0.74 if dark else 0.82)})"
        )
        site_bg_color = rgba(site_a, 0.72 if dark else 0.80)
        site_backdrop = "blur(18px) saturate(1.14)"
    return css_header(palette) + f""":root {{
  --velora-page-bg: {rgb_to_hex(palette["base"])};
  --velora-page-surface: {rgba(palette["surface_two"], 0.88 if dark else 0.82)};
  --velora-page-surface-soft: {rgba(palette["surface"], 0.58 if dark else 0.62)};
  --velora-site-bg: {site_bg};
  --velora-site-bg-color: {site_bg_color};
  --velora-site-backdrop: {site_backdrop};
  --velora-page-text: {rgb_to_hex(palette["text"])};
  --velora-page-muted: {rgb_to_hex(palette["text_muted"])};
  --velora-page-accent: {rgb_to_hex(palette["accent"])};
  --velora-page-accent-2: {rgb_to_hex(palette["accent_two"])};
  --velora-page-accent-3: {rgb_to_hex(palette["accent_three"])};
  --velora-page-accent-text: {rgb_to_hex(palette["button_text"])};
  --velora-page-border: {rgba(palette["border"], 0.46 if dark else 0.62)};
  --velora-page-shadow: {rgba(palette["shadow"], 0.34 if dark else 0.16)};
}}

@-moz-document regexp(".*") {{
  :root {{
    color-scheme: {"dark" if dark else "light"} !important;
    --in-content-page-background: var(--velora-page-bg) !important;
    --in-content-page-color: var(--velora-page-text) !important;
    --in-content-text-color: var(--velora-page-text) !important;
    --in-content-deemphasized-text: var(--velora-page-muted) !important;
    --in-content-box-background: var(--velora-page-surface) !important;
    --in-content-box-background-odd: var(--velora-page-surface-soft) !important;
    --in-content-box-info-background: var(--velora-page-surface) !important;
    --in-content-button-background: var(--velora-page-surface) !important;
    --in-content-button-background-hover: color-mix(in srgb, var(--velora-page-accent), transparent 76%) !important;
    --in-content-button-text-color: var(--velora-page-text) !important;
    --in-content-border-color: color-mix(in srgb, var(--velora-page-accent), transparent 58%) !important;
    --card-outline-color: color-mix(in srgb, var(--velora-page-accent), transparent 62%) !important;
  }}

  ::selection {{
    background-color: color-mix(in srgb, var(--velora-page-accent), transparent 54%) !important;
    color: var(--velora-page-text) !important;
  }}
}}

@-moz-document url-prefix("about:preferences"), url-prefix("about:addons"), url-prefix("about:config"), url-prefix("about:profiles"), url-prefix("about:logins") {{
  :root,
  html,
  body,
  .main-content,
  .pane-container,
  .sticky-container,
  #mainPrefPane,
  #preferences-body,
  #contentAreaDownloadsView {{
    background-color: var(--velora-page-bg) !important;
    color: var(--velora-page-text) !important;
  }}

  #categories,
  #categories > scrollbox,
  .navigation,
  .sidebar-footer-list,
  .sidebar-footer-link {{
    background-color: color-mix(in srgb, var(--velora-page-bg), var(--velora-page-surface) 26%) !important;
    color: var(--velora-page-text) !important;
  }}

  .category,
  richlistitem,
  treechildren::-moz-tree-row {{
    color: var(--velora-page-text) !important;
    background-color: transparent !important;
  }}

  .category[selected],
  .category:hover,
  richlistitem[selected],
  richlistitem:hover {{
    color: var(--velora-page-text) !important;
    background-color: color-mix(in srgb, var(--velora-page-accent), transparent 78%) !important;
    border-color: color-mix(in srgb, var(--velora-page-accent), transparent 54%) !important;
  }}

  groupbox,
  groupbox > .groupbox-body,
  .info-box-container,
  .content-blocking-category,
  .setting-group,
  .container,
  .dialogBox,
  .card,
  .card-contents,
  richlistbox,
  tree,
  menulist,
  search-textbox {{
    background-color: var(--velora-page-surface) !important;
    color: var(--velora-page-text) !important;
    border-color: color-mix(in srgb, var(--velora-page-accent), transparent 58%) !important;
  }}

  #mainPrefPane :is(h1, h2, h3, h4, label, description, span, div, button, checkbox, radio, a),
  #categories :is(label, span, div),
  .card :is(label, description, span, div, button, a) {{
    color: var(--velora-page-text) !important;
    opacity: 1 !important;
    text-shadow: none !important;
  }}

  #mainPrefPane :is(label[disabled], description[disabled], button[disabled], checkbox[disabled], radio[disabled], [aria-disabled="true"], [disabled="true"]),
  .card :is(label[disabled], description[disabled], button[disabled], [aria-disabled="true"], [disabled="true"]) {{
    color: color-mix(in srgb, var(--velora-page-text), transparent 30%) !important;
    opacity: 1 !important;
  }}

  input,
  textarea,
  search-textbox,
  menulist,
  button {{
    background-color: color-mix(in srgb, var(--velora-page-surface), var(--velora-page-bg) 18%) !important;
    color: var(--velora-page-text) !important;
    border-color: color-mix(in srgb, var(--velora-page-accent), transparent 54%) !important;
  }}
}}

@-moz-document url("about:blank"), url("about:newtab"), url("about:home"), url("about:privatebrowsing") {{
  @font-face {{
    font-family: "Velora Lyrics Serif";
    src: url("velora-clock.ttf") format("truetype");
    font-weight: 400;
    font-style: normal;
  }}
  :root,
  html,
  body,
  body.activity-stream,
  #root,
  .nova-outer-wrapper,
  .nova-enabled,
  .nova-enabled .content,
  .nova-enabled .discovery-stream,
  .nova-enabled .ds-layout,
  .classic-enabled,
  .classic-enabled .outer-wrapper,
  .classic-enabled .newtab-main,
  .classic-enabled .body-wrapper {{
    color-scheme: {"dark" if dark else "light"} !important;
    --newtab-background-color: transparent !important;
    --newtab-background-card: transparent !important;
    --background-color-canvas: transparent !important;
    background: transparent !important;
    background-color: transparent !important;
    color: var(--velora-page-text) !important;
  }}

  body::before,
  body::after,
  .nova-outer-wrapper::before,
  .nova-outer-wrapper::after {{
    background: none !important;
    background-image: none !important;
  }}

  .search-wrapper input,
  .tile,
  .top-site-outer .tile,
  .card {{
    background-color: var(--velora-page-surface) !important;
    color: var(--velora-page-text) !important;
    border-color: color-mix(in srgb, var(--velora-page-accent), transparent 58%) !important;
  }}

  .nova-enabled .logo-and-wordmark-wrapper,
  .nova-enabled .sidebar-inline-start,
  .nova-enabled .sidebar-inline-end,
  .nova-enabled .top-sites,
  .nova-enabled .search-wrapper,
  .nova-enabled .widgets-title-container,
  .nova-enabled .personalizeButtonWrapper,
  .classic-enabled .logo-and-wordmark-wrapper,
  .classic-enabled .top-sites,
  .classic-enabled .search-wrapper,
  .classic-enabled .personalizeButtonWrapper {{
    display: none !important;
  }}

  .nova-enabled .widget-wrapper:not(:has(.clocks-widget)) {{
    display: none !important;
  }}

  .nova-enabled .clocks-widget {{
    position: fixed !important;
    inset: 50% auto auto 50% !important;
    width: max-content !important;
    min-width: 0 !important;
    height: auto !important;
    min-height: 0 !important;
    padding: 0 !important;
    border: 0 !important;
    border-radius: 0 !important;
    outline: 0 !important;
    background: transparent !important;
    background-color: transparent !important;
    box-shadow: none !important;
    color: var(--velora-page-text) !important;
    transform: translate(-50%, -50%) !important;
    pointer-events: none !important;
    z-index: 10 !important;
  }}

  .nova-enabled .clocks-widget:hover,
  .nova-enabled .clocks-widget:focus-within {{
    outline: 0 !important;
    box-shadow: none !important;
  }}

  .nova-enabled .clocks-widget .widget-toolbar,
  .nova-enabled .clocks-widget .clocks-meta,
  .nova-enabled .clocks-widget .clocks-row-actions {{
    display: none !important;
  }}

  .nova-enabled .clocks-widget .clocks-list,
  .nova-enabled .clocks-widget .clocks-row {{
    display: block !important;
    width: max-content !important;
    height: auto !important;
    margin: 0 !important;
    padding: 0 !important;
    border: 0 !important;
    background: transparent !important;
    list-style: none !important;
  }}

  .nova-enabled .clocks-widget .clocks-time {{
    display: block !important;
    color: var(--velora-page-text) !important;
    font-family: "Velora Lyrics Serif", "Liberation Serif", "FreeSerif", serif !important;
    font-size: clamp(7.2rem, 12vw, 13rem) !important;
    font-weight: 400 !important;
    font-style: italic !important;
    font-synthesis: style !important;
    font-variant-numeric: tabular-nums !important;
    letter-spacing: -0.025em !important;
    line-height: 0.92 !important;
    text-align: center !important;
    text-shadow: none !important;
  }}

  .nova-enabled .clocks-widget .clocks-row::after {{
    content: "";
    display: block !important;
    margin-block-start: 0.62rem !important;
    color: color-mix(in srgb, var(--velora-page-text), transparent 18%) !important;
    font-family: "Velora Lyrics Serif", "Liberation Serif", "FreeSerif", serif !important;
    font-size: clamp(1.05rem, 1.7vw, 1.46rem) !important;
    font-weight: 400 !important;
    font-style: italic !important;
    letter-spacing: 0.025em !important;
    line-height: 1.25 !important;
    text-align: center !important;
    text-shadow: none !important;
  }}

  {clock_date_rules()}

  a,
  .wordmark,
  .icon {{
    color: var(--velora-page-accent) !important;
    fill: var(--velora-page-accent) !important;
  }}
}}

@-moz-document domain("google.com"), domain("google.com.br") {{
  :root,
  html {{
    color-scheme: {"dark" if dark else "light"} !important;
    background: var(--velora-site-bg-color) !important;
    background-color: var(--velora-site-bg-color) !important;
    color: var(--velora-page-text) !important;
  }}

  body {{
    min-height: 100vh !important;
    background: transparent !important;
    background-color: transparent !important;
    color: var(--velora-page-text) !important;
  }}

  #viewport,
  #main,
  #cnt,
  #rcnt,
  .L3eUgb,
  .o3j99,
  .FPdoLc,
  .sfbg,
  .minidiv .sfbg,
  .appbar,
  .fbar,
  #fbar {{
    background: transparent !important;
    background-color: transparent !important;
    background-image: none !important;
    color: var(--velora-page-text) !important;
    box-shadow: none !important;
    backdrop-filter: none !important;
  }}

  center,
  form,
  #searchform,
  .A8SBwf,
  .RNNXgb:hover,
  .RNNXgb:focus-within {{
    background: transparent !important;
    background-color: transparent !important;
  }}

  .RNNXgb,
  .aajZCb,
  .UUbT9,
  .erkvQe,
  textarea.gLFyf,
  input.gLFyf,
  input[type="text"],
  input[type="search"] {{
    background: color-mix(in srgb, var(--velora-page-surface), transparent 6%) !important;
    background-color: color-mix(in srgb, var(--velora-page-surface), transparent 6%) !important;
    color: var(--velora-page-text) !important;
    border-color: color-mix(in srgb, var(--velora-page-accent), transparent 54%) !important;
    box-shadow: 0 18px 52px var(--velora-page-shadow) !important;
  }}

  .G43f7e,
  .sbct,
  .xtSCL,
  .mkHrUc,
  .OBMEnb,
  g-card,
  .kp-wholepage {{
    background: var(--velora-page-surface-soft) !important;
    background-color: var(--velora-page-surface-soft) !important;
    color: var(--velora-page-text) !important;
    border-color: var(--velora-page-border) !important;
  }}

  h1,
  h2,
  h3,
  p,
  cite,
  em,
  input,
  textarea,
  button {{
    color: var(--velora-page-text) !important;
  }}

  a,
  a:visited,
  .LC20lb,
  .yuRUbf a {{
    color: var(--velora-page-accent-3) !important;
  }}

  .VuuXrf,
  .MUxGbd,
  .IsZvec,
  .BNeawe,
  .fl,
  .gb_E,
  .gb_F,
  .gb_Xa {{
    color: var(--velora-page-muted) !important;
  }}
}}


"""


def likely_zen_roots():
    env_root = os.environ.get("VELORA_ZEN_ROOT")
    roots = []
    if env_root:
        roots.append(Path(env_root).expanduser())
    roots.extend([
        Path.home() / ".config/zen",
        Path.home() / ".zen",
        Path.home() / ".var/app/app.zen_browser.zen/.config/zen",
        Path.home() / ".var/app/io.github.zen_browser.zen/.config/zen",
    ])
    return [root for root in roots if root.exists()]


def profile_path(root, value, relative):
    path = Path(value)
    return root / path if relative and not path.is_absolute() else path.expanduser()


def profiles_from_ini(root):
    profiles_ini = root / "profiles.ini"
    if not profiles_ini.exists():
        return []

    parser = configparser.RawConfigParser()
    parser.read(profiles_ini, encoding="utf-8")
    by_path = {}
    ordered_paths = []

    for section in parser.sections():
        if not section.startswith("Profile") or not parser.has_option(section, "Path"):
            continue
        raw_path = parser.get(section, "Path")
        relative = parser.get(section, "IsRelative", fallback="1") == "1"
        path = profile_path(root, raw_path, relative)
        by_path[raw_path] = path
        ordered_paths.append(path)

    result = []
    for section in parser.sections():
        if section.startswith("Install") and parser.has_option(section, "Default"):
            raw_path = parser.get(section, "Default")
            if raw_path in by_path:
                result.append(by_path[raw_path])
            else:
                result.append(profile_path(root, raw_path, True))

    for section in parser.sections():
        if section.startswith("Profile") and parser.get(section, "Default", fallback="0") == "1":
            raw_path = parser.get(section, "Path")
            result.append(by_path.get(raw_path, profile_path(root, raw_path, parser.get(section, "IsRelative", fallback="1") == "1")))

    result.extend(ordered_paths)
    return unique_existing_profiles(result)


def unique_existing_profiles(paths):
    result = []
    seen = set()
    for path in paths:
        path = path.expanduser()
        key = str(path)
        if key in seen:
            continue
        seen.add(key)
        if (path / "prefs.js").exists() or (path / "chrome").exists():
            result.append(path)
    return result


def discover_profiles(all_profiles=False):
    env_profile = os.environ.get("VELORA_ZEN_PROFILE")
    if env_profile:
        return unique_existing_profiles([Path(env_profile)])

    profiles = []
    for root in likely_zen_roots():
        found = profiles_from_ini(root)
        if found:
            profiles.extend(found if all_profiles else found[:1])
            continue
        direct = [path for path in root.iterdir() if path.is_dir() and ((path / "prefs.js").exists() or (path / "chrome").exists())]
        profiles.extend(sorted(direct) if all_profiles else sorted(direct)[:1])
    return unique_existing_profiles(profiles)


def backup_once(path):
    if not path.exists():
        return
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    backup = path.with_name(path.name + f".velora-bak-{stamp}")
    backup.write_bytes(path.read_bytes())


def managed_block(marker, body):
    return f"/* {marker}: begin */\n{body.rstrip()}\n/* {marker}: end */\n"


def remove_managed_block(text, marker):
    pattern = re.compile(
        r"/\* " + re.escape(marker) + r": begin \*/\n.*?/\* " + re.escape(marker) + r": end \*/\n*",
        re.DOTALL,
    )
    return pattern.sub("", text)


def import_insert_position(text):
    position = 0
    if text.startswith("@charset"):
        semicolon = text.find(";")
        if semicolon >= 0:
            position = semicolon + 1
            while position < len(text) and text[position] in "\r\n\t ":
                position += 1
    if text[position:].startswith("/*"):
        end = text.find("*/", position)
        if end >= 0:
            position = end + 2
            while position < len(text) and text[position] in "\r\n\t ":
                position += 1
    return position


def ensure_import(path, css_name, marker):
    path.parent.mkdir(parents=True, exist_ok=True)
    block = managed_block(marker, f'@import url("{css_name}");')
    text = path.read_text(encoding="utf-8") if path.exists() else ""
    had_marker = marker in text
    if path.exists() and not had_marker:
        backup_once(path)
    text = remove_managed_block(text, marker)
    position = import_insert_position(text)
    next_text = text[:position] + block + "\n" + text[position:]
    if next_text != text:
        path.write_text(next_text, encoding="utf-8")


def ensure_user_js(profile):
    path = profile / "user.js"
    text = path.read_text(encoding="utf-8") if path.exists() else ""
    had_marker = USER_JS_MARKER in text
    if path.exists() and not had_marker:
        backup_once(path)
    text = remove_managed_block(text, USER_JS_MARKER)
    lines = strip_managed_pref_lines(text.splitlines())
    base_text = "\n".join(lines).rstrip()
    if base_text:
        base_text += "\n\n"
    block = managed_block(USER_JS_MARKER, managed_pref_lines())
    path.write_text(base_text + block + "\n", encoding="utf-8")


def zen_browser_running():
    try:
        result = subprocess.run(
            ["pgrep", "-af", "zen-browser|zen-bin"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=0.8,
            check=False,
        )
    except Exception:
        return False
    own_pid = str(os.getpid())
    for line in result.stdout.splitlines():
        parts = line.split(maxsplit=1)
        if not parts or parts[0] == own_pid:
            continue
        command = parts[1] if len(parts) > 1 else ""
        if "zen-browser" in command or "zen-bin" in command:
            return True
    return False


def ensure_prefs_js(profile, browser_running):
    if browser_running:
        return False

    path = profile / "prefs.js"
    if not path.exists():
        return False

    text = path.read_text(encoding="utf-8")
    had_marker = USER_JS_MARKER in text
    if not had_marker:
        backup_once(path)
    text = remove_managed_block(text, USER_JS_MARKER)
    lines = strip_managed_pref_lines(text.splitlines())
    base_text = "\n".join(lines).rstrip()
    if base_text:
        base_text += "\n\n"
    block = managed_block(USER_JS_MARKER, managed_pref_lines())
    path.write_text(base_text + block + "\n", encoding="utf-8")
    return True


def install_profile(profile, chrome_css, content_css, browser_running):
    chrome = profile / "chrome"
    chrome.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(BASE / 'assets/fonts/LiberationSerif-Regular.ttf', chrome / 'velora-clock.ttf')
    shutil.copyfile(BASE / 'assets/fonts/OFL-Liberation.txt', chrome / 'velora-clock-license.txt')
    (chrome / CHROME_CSS_NAME).write_text(chrome_css, encoding="utf-8")
    (chrome / CONTENT_CSS_NAME).write_text(content_css, encoding="utf-8")
    ensure_import(chrome / "userChrome.css", CHROME_CSS_NAME, USER_CHROME_MARKER)
    ensure_import(chrome / "userContent.css", CONTENT_CSS_NAME, USER_CONTENT_MARKER)
    if (chrome / "zen-themes.css").exists():
        ensure_import(chrome / "zen-themes.css", CHROME_CSS_NAME, ZEN_THEMES_MARKER)
    ensure_user_js(profile)
    return ensure_prefs_js(profile, browser_running)


def write_state(palette, profiles, browser_running, prefs_written, web_mode):
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    STATE_PATH.write_text(json.dumps({
        "generatedAt": datetime.datetime.now().astimezone().isoformat(timespec="seconds"),
        "source": palette.get('source', str(WAL_PATH)),
        "wallpaper": palette.get("wallpaper", ""),
        "mode": palette["mode"],
        "accent": rgb_to_hex(palette["accent"]),
        "accentSecondary": rgb_to_hex(palette["accent_two"]),
        "profiles": [str(profile) for profile in profiles],
        "chromeCss": CHROME_CSS_NAME,
        "contentCss": CONTENT_CSS_NAME,
        "webMode": web_mode,
        "zenRunning": browser_running,
        "prefsWritten": prefs_written,
        "transparentBrowser": True,
        "zenLinuxTransparency": True,
        "newTab": {
            "transparent": True,
            "clock": True,
            "nativePage": True,
            "clockZone": "America/Sao_Paulo",
            "clockFormat": "24",
            "dateLocale": "pt-BR",
        },
        "restartRequired": browser_running,
    }, indent=2) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description="Sync Velora Shell wallpaper colors into Zen Browser chrome CSS.")
    parser.add_argument("--all-profiles", action="store_true", help="sync every detected Zen profile instead of only the default profile")
    parser.add_argument("--status", action="store_true", help="print the last sync state")
    parser.add_argument("--quiet", action="store_true", help="suppress normal output")
    parser.add_argument("--managed-only", action="store_true", help="refresh only existing Velora CSS; preserve imports and personal preferences")
    parser.add_argument("command", nargs="?", help="optional command: mode")
    parser.add_argument("subcommand", nargs="?", help="mode action: get or set")
    parser.add_argument("value", nargs="?", help="mode value: balance or clean")
    args = parser.parse_args()

    if args.command == "mode":
        action = args.subcommand or "get"
        if action == "get":
            print(read_web_mode())
            return 0
        if action != "set":
            parser.error("mode action must be 'get' or 'set'")
        web_mode = write_web_mode(args.value or WEB_MODE_DEFAULT)
    elif args.command:
        parser.error("unknown command; expected 'mode'")
    else:
        web_mode = read_web_mode()

    if args.status:
        if STATE_PATH.exists():
            print(STATE_PATH.read_text(encoding="utf-8").strip())
        else:
            print("missing")
        return 0

    try:
        palette = build_palette()
    except Exception as exc:
        if not args.quiet:
            print(f"velora-zen-theme: {exc}", file=sys.stderr)
        return 0

    profiles = discover_profiles(all_profiles=args.all_profiles or os.environ.get("VELORA_ZEN_ALL_PROFILES") == "1")
    if not profiles:
        if not args.quiet:
            print("velora-zen-theme: no Zen Browser profile found", file=sys.stderr)
        return 0

    chrome_css = generate_chrome_css(palette)
    content_css = generate_content_css(palette, web_mode)
    browser_running = zen_browser_running()
    prefs_written = False
    for profile in profiles:
        if args.managed_only:
            chrome = profile / 'chrome'
            if not (chrome / CHROME_CSS_NAME).is_file(): continue
            shutil.copyfile(BASE / 'assets/fonts/LiberationSerif-Regular.ttf', chrome / 'velora-clock.ttf')
            shutil.copyfile(BASE / 'assets/fonts/OFL-Liberation.txt', chrome / 'velora-clock-license.txt')
            (chrome / CHROME_CSS_NAME).write_text(chrome_css, encoding='utf-8')
            if (chrome / CONTENT_CSS_NAME).is_file():
                (chrome / CONTENT_CSS_NAME).write_text(content_css, encoding='utf-8')
        else:
            prefs_written = install_profile(profile, chrome_css, content_css, browser_running) or prefs_written
    write_state(palette, profiles, browser_running, prefs_written, web_mode)

    if not args.quiet:
        print(f"synced {len(profiles)} Zen profile(s):")
        for profile in profiles:
            print(f"  {profile}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
