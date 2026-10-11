import QtQuick

QtObject {
    id: root

    required property var config
    required property var palette

    readonly property string style: String(config.visualStyle || "classic")
    readonly property bool editorial: style === "editorial"
    readonly property bool minimal: style === "minimal"
    readonly property bool characterPaletteActive: config.characterPywal && !!palette && !!palette.ready
    readonly property bool wallpaperAccent: String(config.accentMode || "wallpaper")
        === "wallpaper" && !!palette && !!palette.ready
    readonly property bool manualPalette: String(config.accentMode || "wallpaper")
        === "custom"
    readonly property string effectivePywalTone: {
        const requested = String(config.pywalTone || "auto")
        return requested === "dark" || requested === "light"
            ? requested : String(config.colorScheme || "dark")
    }
    readonly property bool light: wallpaperAccent
        ? (palette.exactSurface ? colorLuminance(palette.foreground) < 0.5 : effectivePywalTone === "light")
        : String(config.colorScheme || "dark") === "light"
    readonly property int paletteTransitionDuration: config.reducedMotion ? 0 : 420
    readonly property string bodyFont: "Poppins"
    readonly property string displayFont: "Poppins"
    readonly property real requestedOpacity: config.reduceTransparency
        ? 0.96 : Math.max(0.45, Math.min(1,
            Number(config.surfaceOpacity || 0.82)
            + (0.55 - Number(config.blurStrength || 0.55)) * 0.10))
    readonly property real styleOpacity: minimal ? requestedOpacity * 0.58
        : requestedOpacity
    readonly property real contrastLevel: config.intelligentContrast
        ? Number(config.appearanceContrast || 1.08) : 1
    readonly property real darkSurfaceLevel: Math.max(0.025,
        Math.min(0.11, 0.068 / contrastLevel))

    property color accent: validColor(wallpaperAccent ? palette.accent
        : (manualPalette ? config.customColor("accent") : config.accentColor))
    property color accentAlt: wallpaperAccent
        ? validColor(palette.accentAlt) : Qt.lighter(accent, 1.16)
    property color accentSoft: wallpaperAccent
        ? validColor(palette.accentSoft) : Qt.lighter(accent, 1.24)
    property color accentMuted: withAlpha(accent, light ? 0.20 : 0.34)
    property color textPrimary: wallpaperAccent
        ? paletteText(true) : (manualPalette
            ? config.customColor("text") : (light ? "#17191f" : "#edf1ff"))
    property color textSecondary: wallpaperAccent
        ? paletteText(false) : (manualPalette
            ? mixColor(textPrimary, config.customColor("panels"), 0.34)
            : (light ? "#555b66" : "#c4cede"))
    property color textMuted: withAlpha(textSecondary, 0.82)
    readonly property color wallpaperSurfaceTone: wallpaperAccent
        ? paletteSurface(light)
        : (manualPalette ? config.customColor("panels")
            : Qt.rgba(darkSurfaceLevel, darkSurfaceLevel * 1.08,
                      darkSurfaceLevel * 1.30, 1))
    property color surface: withAlpha(wallpaperSurfaceTone, styleOpacity)
    property color surfaceRaised: withAlpha(mixColor(
        wallpaperSurfaceTone, light ? Qt.rgba(1, 1, 1, 1)
                                    : Qt.rgba(0.10, 0.115, 0.145, 1),
        light ? 0.20 : 0.22), Math.min(1, styleOpacity + 0.05))
    // Both legs consume the same tint and the bar-specific opacity. This is
    // deliberately separate from widget opacity so "Translúcido" is real.
    property color barSurface: withAlpha(
        manualPalette ? config.customColor("bar")
            : wallpaperSurfaceTone,
        config.barMaterial === "solid" ? 1
            : (config.barMaterial === "liquid"
                ? Math.min(Number(config.barOpacity) * 0.30, 0.24)
                : Number(config.barOpacity)))
    property color surfaceSoft: withAlpha(mixColor(
        wallpaperSurfaceTone, light ? Qt.rgba(0.72, 0.75, 0.80, 1)
                                    : Qt.rgba(0.30, 0.32, 0.38, 1),
        light ? 0.26 : 0.34), minimal ? 0.18 : 0.32)
    property color surfaceHover: withAlpha(light ? Qt.darker(surfaceRaised, 1.06)
        : Qt.lighter(surfaceRaised, 1.20), light ? 0.82 : 0.74)
    property color borderSubtle: light
        ? Qt.rgba(0.16, 0.18, 0.22, minimal ? 0.10 : 0.16)
        : Qt.rgba(0.86, 0.88, 0.94, minimal ? 0.08 : 0.14)
    property color borderStrong: light
        ? Qt.rgba(0.10, 0.12, 0.16, 0.28)
        : Qt.rgba(0.96, 0.95, 1.0, 0.26)
    property color rim: light
        ? Qt.rgba(1, 1, 1, 0.76)
        : Qt.rgba(1, 1, 1, 0.24
            + Number(config.reflectionStrength || 0.35) * 0.34)
    property color shadow: light
        ? Qt.rgba(0.02, 0.025, 0.04, 0.24)
        : Qt.rgba(0.006, 0.009, 0.018, 0.58)
    property color danger: "#e07282"
    property color success: "#79cda7"
    property color warning: "#e7bd76"

    // Compatibility tokens for the existing scene components.
    property color ink: textPrimary
    property color mutedInk: textSecondary
    property color inverseInk: textPrimary
    property color heroInk: textPrimary
    property color glass: surface
    property color glassStrong: surfaceRaised
    property color glassSoft: surfaceSoft
    property color border: borderStrong
    property color highlight: rim
    property color darkCard: surfaceRaised
    property color widgetSolidSurface: light
        ? (manualPalette ? config.customColor("widgets")
            : withAlpha(surfaceRaised, 1))
        : (manualPalette ? config.customColor("widgets")
            : withAlpha(wallpaperSurfaceTone, 1))
    property color moduleSurface: config.widgetSurfaceMode === "bar"
        ? barSurface : widgetSolidSurface
    property color moduleInk: textPrimary
    property color iconInk: manualPalette
        ? config.customColor("icons") : textPrimary
    property color moduleBorder: config.widgetSurfaceMode === "bar"
        ? borderSubtle : borderStrong
    property color calendarWeekday: config.referenceAppearance ? textSecondary : accentSoft
    property color profileDark: surfaceRaised
    property color profileSurface: surfaceSoft
    property color profileSurfaceBorder: borderStrong
    property color profileGlyph: withAlpha(accent, 0.76)
    property color profileGlyphInk: accentSoft
    property color mediaSurface: surfaceRaised
    property color mediaBorder: borderStrong
    property color visualizerStart: accent
    property color visualizerMiddle: wallpaperAccent ? validColor(palette.accentAlt)
        : Qt.lighter(accent, 1.18)
    property color visualizerEnd: accentSoft

    readonly property real panelRadius: editorial ? 32 : (minimal ? 16 : 54)
    readonly property real cardRadius: editorial ? 24 : (minimal ? 14 : 28)
    readonly property real smallRadius: editorial ? 16 : (minimal ? 10 : 18)

    Behavior on accent { ColorAnimation { duration: paletteTransitionDuration; easing.type: Easing.InOutCubic } }
    Behavior on accentAlt { ColorAnimation { duration: paletteTransitionDuration; easing.type: Easing.InOutCubic } }
    Behavior on accentSoft { ColorAnimation { duration: paletteTransitionDuration; easing.type: Easing.InOutCubic } }
    Behavior on barSurface { ColorAnimation { duration: paletteTransitionDuration; easing.type: Easing.InOutCubic } }
    Behavior on surface { ColorAnimation { duration: paletteTransitionDuration; easing.type: Easing.InOutCubic } }
    Behavior on surfaceRaised { ColorAnimation { duration: paletteTransitionDuration; easing.type: Easing.InOutCubic } }
    Behavior on textPrimary { ColorAnimation { duration: paletteTransitionDuration; easing.type: Easing.InOutCubic } }
    Behavior on textSecondary { ColorAnimation { duration: paletteTransitionDuration; easing.type: Easing.InOutCubic } }
    Behavior on moduleSurface { ColorAnimation { duration: paletteTransitionDuration; easing.type: Easing.InOutCubic } }
    Behavior on moduleBorder { ColorAnimation { duration: paletteTransitionDuration; easing.type: Easing.InOutCubic } }

    function withAlpha(source, alpha) {
        source = validColor(source)
        return Qt.rgba(source.r, source.g, source.b, alpha)
    }

    // Palette consumers can run before the first file load.
    function validColor(source) {
        if (source === undefined || source === null || source === "")
            return Qt.rgba(0.068, 0.073, 0.09, 1)
        if (typeof source === "string")
            return Qt.color(source)
        return source
    }

    function mixColor(first, second, amount) {
        first = validColor(first)
        second = validColor(second)
        const t = Math.max(0, Math.min(1, Number(amount)))
        return Qt.rgba(first.r + (second.r - first.r) * t,
                       first.g + (second.g - first.g) * t,
                       first.b + (second.b - first.b) * t, 1)
    }

    function colorLuminance(source) {
        source = validColor(source)
        return source.r * 0.2126 + source.g * 0.7152
            + source.b * 0.0722
    }

    function paletteSurface(lightTone) {
        if (palette.exactSurface) return validColor(palette.background)
        const raw = palette.background
        const target = lightTone ? Qt.rgba(0.965, 0.97, 0.98, 1)
                                 : Qt.rgba(0.018, 0.022, 0.03, 1)
        let result = mixColor(target, raw, lightTone ? 0.30 : 0.78)
        const luminance = colorLuminance(result)
        if (lightTone && luminance < 0.74)
            result = mixColor(result, target, Math.min(0.72,
                (0.74 - luminance) * 1.55))
        else if (!lightTone && luminance > 0.24)
            result = mixColor(result, target, Math.min(0.68,
                (luminance - 0.24) * 1.30))
        return mixColor(result, accent, lightTone ? 0.065 : 0.13)
    }

    function paletteText(primary) {
        if (palette.exactSurface) return validColor(primary ? palette.foreground : palette.muted)
        if (light) {
            const base = mixColor(Qt.rgba(0.045, 0.055, 0.075, 1),
                                  palette.background, primary ? 0.18 : 0.30)
            return primary ? base : mixColor(base, Qt.rgba(0.40, 0.43, 0.49, 1), 0.42)
        }
        const base = mixColor(Qt.rgba(0.96, 0.97, 0.995, 1),
                              palette.foreground, primary ? 0.34 : 0.52)
        return primary ? base : mixColor(base, Qt.rgba(0.54, 0.59, 0.68, 1), 0.46)
    }

    function resolvedMaterial(itemStyle) {
        const requested = String(itemStyle && itemStyle.material || "inherit")
        if (requested !== "inherit")
            return requested
        if (config.reduceTransparency)
            return "solid"
        if (String(config.materialMode || "glass") === "solid")
            return "solid"
        if (String(config.materialMode || "glass") === "adaptive"
                && Number(config.blurStrength || 0.55) < 0.18)
            return "solid"
        return "liquid"
    }

    function resolvedVariant(itemVariant) {
        const requested = String(itemVariant || "inherit")
        return requested === "inherit" ? style : requested
    }
}
