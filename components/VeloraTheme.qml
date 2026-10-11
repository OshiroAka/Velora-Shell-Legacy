import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool referencePalette: true
    onReferencePaletteChanged: applyTheme(referencePalette ? "reference" : "pywal16", false)

    readonly property string stateScript: Quickshell.shellDir + "/scripts/velora-theme-state"
    readonly property string pywalScript: Quickshell.shellDir + "/scripts/velora-pywal-theme.py"
    readonly property string pywalGeneratedPath: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/velora-shell/themes/pywal16.json"

    property string themeId: "default"
    property string themeName: "Velora Default"
    property string themeMode: "light"
    property string themeNotice: ""
    property bool pywalAvailable: false
    property bool opacityOverrideActive: false
    property bool barOpacityOverrideActive: false
    property bool glowOverrideActive: false
    property bool borderOverrideActive: false
    property bool borderAdaptEnabled: true
    property bool paletteApplying: false
    property bool paletteAnimatedApply: false
    property bool stagedPaletteActive: false
    property var stagedThemeData: ({})
    property int stagedPaletteStep: 0
    readonly property bool paletteBehaviorEnabled: !paletteApplying || paletteAnimatedApply
    readonly property int paletteTransitionDuration: paletteAnimatedApply ? (stagedPaletteActive ? 220 : 360) : 180
    readonly property int stagedPaletteStepDelay: 420
    property bool motionEnabled: true
    readonly property int motionFast: motionEnabled ? 100 : 1
    readonly property int motionNormal: motionEnabled ? 170 : 1
    readonly property int motionSlow: motionEnabled ? 340 : 1
    readonly property int motionPanelIn: motionEnabled ? 220 : 1
    readonly property int motionPanelOut: motionEnabled ? 180 : 1
    readonly property int motionPanelGeometry: motionEnabled ? 240 : 1
    readonly property int motionMenuIn: motionEnabled ? 280 : 1
    readonly property int motionMenuOut: motionEnabled ? 210 : 1
    readonly property int motionHover: motionEnabled ? 100 : 1
    readonly property int motionUnmountDelay: motionEnabled ? motionPanelOut + 80 : 1
    readonly property int motionPanelOffset: motionEnabled ? 26 : 0
    readonly property int motionLayersIn: motionEnabled ? 220 : 1
    readonly property int motionLayersOut: motionEnabled ? 160 : 1
    readonly property int motionFadeLayers: motionEnabled ? 180 : 1
    readonly property int motionEaseEnter: Easing.OutCubic
    readonly property int motionEaseExit: Easing.InCubic
    readonly property int motionEaseHover: Easing.OutCubic
    readonly property int motionEaseEmphasized: Easing.BezierSpline
    readonly property var motionCurveSpecialWorkSwitch: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property var motionCurveEmphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property var motionCurveEmphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property var motionCurveStandard: [0.2, 0, 0, 1, 1, 1]
    readonly property var motionEmphasizedCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
    property string barPosition: "left"
    property bool desktopFrameEnabled: true
    property bool topBarFrameLineEnabled: true
    property real topBarOpacity: 0.18
    property bool topBarGradientEnabled: true
    property real topBarGradientStrength: 0.82
    property bool topBarBubbleGradientEnabled: true
    property real topBarBubbleGradientStrength: 0.82
    property real topBarCategoryGap: 8
    property bool popupAttachedToBar: true
    property bool popupBubblesSolid: false
    property bool barLabelsVisible: true
    property bool barBlurEnabled: true
    property bool frameBlurEnabled: true
    property real barIconSize: 48
    property real barIconOpacity: 0.80
    property real barIconSpacing: 16
    property bool barAutoHideEnabled: false
    property real barCornerRadius: 16
    property real barWidth: 112
    property string wallpaperSelectorPosition: "center"
    property real wallpaperSelectorBlur: 0.55
    property string controlCenterPosition: "bottom"
    property string profileImagePath: ""
    property string language: "pt-BR"
    property string fontFamilyId: "noto"
    readonly property string uiFont: referencePalette ? "Poppins" : language === "ja" ? "Noto Sans CJK JP" : fontFamilyForId(fontFamilyId)
    readonly property string monoFont: uiFont
    readonly property bool fontSelectionActive: language !== "ja"
    property real sidebarOpacity: 0.88
    property real barOpacity: 0.88
    property real popupOpacity: 0.90
    property real cardOpacity: 0.76
    property real generalGlow: 0.50
    property real sidebarBorderGlowLevel: 0.50
    property real popupBorderGlowLevel: 0.50
    property real iconGlowLevel: 0.50
    property real textGlowLevel: 0.78
    property real borderHue: 0.55
    property real visualizerStrength: 0.46
    property string visualizerMode: "wave"
    property real visualizerPixelSize: 7
    property bool visualizerGradientEnabled: true
    property bool screenVisualizerEnabled: false
    property bool lyricsEnabled: false
    property real lyricsPositionX: 18
    property real lyricsPositionY: 44
    property real lyricsSecondPositionX: 74
    property real lyricsSecondPositionY: 18
    property real lyricsThirdPositionX: 8
    property real lyricsThirdPositionY: 58
    property real lyricsFourthPositionX: 72
    property real lyricsFourthPositionY: 58
    property string lyricsColorMode: "pywal"
    property string lyricsManualColor: "#f5f7ff"
    property color lyricsPywalColor: "#e8a6c8"
    property var lyricsPalette: ["#e8a6c8", "#c894f2", "#a8d8ff"]
    property real lyricsFontSize: 86
    property real lyricsOpacity: 0.86
    property real lyricsWordSpacing: 8
    property bool lyricsShadowEnabled: true
    property bool lyricsUppercase: true
    property string lyricsLayoutMode: "vertical"
    property string lyricsAnimationMode: "instant"
    property bool lyricsActiveWordEnabled: true
    property string lyricsRevealMode: "progressive"
    property real lyricsSyncOffsetMs: 460
    property bool lyricsFloatEnabled: true
    property real lyricsFloatIntensity: 5
    property bool lyricsGlowEnabled: true
    property real lyricsGlowIntensity: 0.45
    property bool lyricsCinematicEnabled: true
    property real lyricsScale: 1
    property real lyricsRotation: 0
    property real lyricsTiltX: 0
    property real lyricsTiltY: 0
    property string lyricsMaterialMode: "off"
    property real lyricsMaterialIntensity: 0.55
    property bool lyricsDepthEnabled: false
    property real lyricsDepthIntensity: 0.45
    property bool lyricsFogEnabled: false
    property real lyricsFogIntensity: 0.35
    property real lyricsMaskFeather: 0
    property bool lyricsMaskEnabled: false
    property real lyricsMaskBrushSize: 56
    property string lyricsMaskData: "[]"
    property var lyricsMaskStrokes: []
    property bool lyricsMaskHasStrokes: false
    property int lyricsMaskRevision: 0
    property string lyricsBlockStyleData: "[]"
    property var lyricsBlockStyles: []
    property int lyricsBlockStyleRevision: 0

    property color surfaceBase: Qt.rgba(255 / 255, 250 / 255, 254 / 255, 0.86)
    property color surfaceSidebar: Qt.rgba(255 / 255, 247 / 255, 253 / 255, 0.88)
    property color surfacePopup: Qt.rgba(255 / 255, 250 / 255, 254 / 255, 0.90)
    property color surfaceCard: Qt.rgba(1, 1, 1, 0.76)
    property color surfaceInput: Qt.rgba(1, 1, 1, 0.64)
    property color surfaceButton: Qt.rgba(1, 1, 1, 0.66)
    property color paletteSurfaceBase: Qt.rgba(255 / 255, 250 / 255, 254 / 255, 0.86)
    property color paletteSurfaceSidebar: Qt.rgba(255 / 255, 247 / 255, 253 / 255, 0.88)
    property color paletteSurfacePopup: Qt.rgba(255 / 255, 250 / 255, 254 / 255, 0.90)
    property color paletteSurfaceCard: Qt.rgba(1, 1, 1, 0.76)
    property color paletteSurfaceInput: Qt.rgba(1, 1, 1, 0.64)
    property color paletteSurfaceButton: Qt.rgba(1, 1, 1, 0.66)
    property color textPrimary: "#4d3f63"
    property color textSecondary: "#8d7ca3"
    property color textMuted: "#b7a9c7"
    property color accentPrimary: "#e8a6c8"
    property color accentSecondary: "#c894f2"
    property color accentTertiary: "#a8d8ff"
    property color borderSoft: Qt.rgba(1, 1, 1, 0.78)
    property color borderActive: Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.78)
    property color borderGlow: Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.18)
    property color sidebarBorderGlow: Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.18)
    property color popupBorderGlow: Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.18)
    property color buttonPrimaryBg: "#e8a6c8"
    property color buttonPrimaryText: "#ffffff"
    property color buttonPrimaryGlow: Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.22)
    property color buttonSecondaryBg: Qt.rgba(1, 1, 1, 0.58)
    property color buttonSecondaryText: "#6d5a82"
    property color activeBg: Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.35)
    property color activeText: "#ffffff"
    property color hoverBg: Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.16)
    property color shadowColor: Qt.rgba(95 / 255, 70 / 255, 130 / 255, 0.10)
    property color sidebarGlow: Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.10)
    property color popupGlow: Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.10)
    property color textGlow: Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.12)
    property color iconGlow: Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.18)
    property int glassBlur: 18

    readonly property var themeOptions: [
        { id: "default", title: "Light", subtitle: "Velora Default", mode: "light", preview: "default" },
        { id: "dark", title: "Dark", subtitle: "Manual", mode: "dark", preview: "dark" },
        { id: "pink", title: "Pink", subtitle: "Soft rose", mode: "light", preview: "pink" },
        { id: "lavender", title: "Lavender", subtitle: "Lilac glass", mode: "light", preview: "lavender" },
        { id: "pywal16", title: "pywal16", subtitle: "auto", mode: "dynamic", preview: "pywal16" }
    ]
    readonly property var languageOptions: [
        { id: "ja", label: "日本語", shortLabel: "JP" },
        { id: "en", label: "English", shortLabel: "EN" },
        { id: "pt-BR", label: "Português Brasil", shortLabel: "BR" }
    ]
    readonly property var fontOptions: [
        { id: "noto", label: "Noto Sans", family: "Noto Sans" },
        { id: "adwaita", label: "Adwaita Sans", family: "Adwaita Sans" },
        { id: "cantarell", label: "Cantarell", family: "Cantarell" },
        { id: "dejavu", label: "DejaVu Sans", family: "DejaVu Sans" },
        { id: "liberation", label: "Liberation Sans", family: "Liberation Sans" },
        { id: "fantasque", label: "FantasqueSansM", family: "FantasqueSansM Nerd Font" }
    ]

    Behavior on surfaceBase { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on surfaceSidebar { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on surfacePopup { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on surfaceCard { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on surfaceInput { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on surfaceButton { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on textPrimary { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on textSecondary { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on textMuted { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on accentPrimary { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on accentSecondary { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on accentTertiary { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on lyricsPywalColor { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on borderSoft { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on borderActive { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on borderGlow { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on sidebarBorderGlow { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on popupBorderGlow { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on buttonPrimaryBg { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on buttonPrimaryText { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on buttonPrimaryGlow { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on buttonSecondaryBg { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on buttonSecondaryText { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on activeBg { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on activeText { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on hoverBg { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on shadowColor { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on sidebarGlow { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on popupGlow { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on textGlow { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }
    Behavior on iconGlow { enabled: root.paletteBehaviorEnabled; ColorAnimation { duration: root.paletteTransitionDuration; easing.type: Easing.OutCubic } }

    function alpha(colorValue, opacity) {
        return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, opacity)
    }

    function setPaletteSurfaces(base, sidebar, popup, card, input, button) {
        paletteSurfaceBase = base
        paletteSurfaceSidebar = sidebar
        paletteSurfacePopup = popup
        paletteSurfaceCard = card
        paletteSurfaceInput = input
        paletteSurfaceButton = button
        surfaceBase = base
        surfaceSidebar = sidebar
        surfacePopup = popup
        surfaceCard = card
        surfaceInput = input
        surfaceButton = button
    }

    function minOpacityForRole(role) {
        if (themeId === "pywal16" && themeMode === "dark") {
            if (role === "sidebar")
                return 0.54
            if (role === "popup")
                return 0.58
            if (role === "card")
                return 0.42
        }

        return 0.25
    }

    function minPanelOpacity() {
        // The frame and the bar must share the same lower bound.  Different
        // hidden clamps made equal slider values render as different layers.
        return minOpacityForRole("sidebar")
    }

    function clampOpacity(value, fallback, role) {
        const n = Number(value)
        if (isNaN(n))
            return fallback
        return Math.max(minOpacityForRole(role), Math.min(0.96, n))
    }

    function clampPanelOpacity(value, fallback) {
        const n = Number(value)
        const base = isNaN(n) ? fallback : n
        return Math.max(minPanelOpacity(), Math.min(0.98, base))
    }

    function clampBarOpacity(value, fallback) {
        const n = Number(value)
        const base = isNaN(n) ? fallback : n
        return Math.max(minOpacityForRole("sidebar"), Math.min(0.98, base))
    }

    function beginPaletteApply(animate) {
        stagedThemeTimer.stop()
        stagedPaletteActive = false
        stagedThemeData = ({})
        paletteAnimatedApply = animate === true
        paletteApplying = true
    }

    function endPaletteApply() {
        paletteApplying = false
    }

    function loadPywal16(animate) {
        if (pywalLoadProc.running) {
            pywalLoadProc.pendingReload = true
            pywalLoadProc.animateTheme = pywalLoadProc.animateTheme || animate === true
            return
        }

        pywalLoadProc.animateTheme = animate === true
        pywalLoadProc.command = [root.pywalScript, "--emit-or-generate"]
        pywalLoadProc.running = true
    }

    function panelOpacitySource(sidebar, popup) {
        const sidebarValue = Number(sidebar)
        const popupValue = Number(popup)
        const sidebarChanged = !isNaN(sidebarValue) && Math.abs(sidebarValue - sidebarOpacity) > 0.001
        const popupChanged = !isNaN(popupValue) && Math.abs(popupValue - popupOpacity) > 0.001

        if (popupChanged && !sidebarChanged)
            return popupValue
        if (!isNaN(sidebarValue))
            return sidebarValue
        if (!isNaN(popupValue))
            return popupValue
        return Math.max(surfaceSidebar.a, surfacePopup.a)
    }

    function syncPanelMaterial(opacity) {
        const sharedOpacity = clampPanelOpacity(opacity, Math.max(surfaceSidebar.a, surfacePopup.a))
        surfaceSidebar = withAlpha(paletteSurfaceSidebar, sharedOpacity)
        surfacePopup = withAlpha(paletteSurfacePopup, sharedOpacity)
        sidebarOpacity = sharedOpacity
        popupOpacity = sharedOpacity
    }

    function syncBarOpacityFromSurface() {
        if (!barOpacityOverrideActive)
            barOpacity = clampBarOpacity(surfaceSidebar.a, surfaceSidebar.a)
    }

    function clampLevel(value, fallback) {
        const n = Number(value)
        if (isNaN(n))
            return fallback
        return Math.max(0, Math.min(1, n))
    }

    function clampVisualizerStrength(value) {
        const n = Number(value)
        if (isNaN(n))
            return visualizerStrength
        return Math.max(0, Math.min(0.90, n))
    }

    function normalizeVisualizerMode(value) {
        const mode = String(value || "wave").toLowerCase()
        return mode === "pixels" || mode === "pixel" || mode === "grid" || mode === "squares" || mode === "square" ? "pixels" : "wave"
    }

    function truthyEnabled(value) {
        return value === true || String(value) === "1" || String(value) === "true" || String(value) === "on" || String(value) === "enabled"
    }

    function clampVisualizerPixelSize(value) {
        const n = Number(value)
        if (isNaN(n))
            return visualizerPixelSize
        return Math.max(3, Math.min(12, n))
    }

    function clampLyricsPercent(value, fallback) {
        const n = Number(value)
        if (isNaN(n))
            return fallback
        return Math.max(0, Math.min(100, n))
    }

    function clampLyricsFontSize(value) {
        const n = Number(value)
        if (isNaN(n))
            return lyricsFontSize
        return Math.max(24, Math.min(180, n))
    }

    function clampLyricsOpacity(value) {
        const n = Number(value)
        if (isNaN(n))
            return lyricsOpacity
        return Math.max(0.15, Math.min(1.0, n))
    }

    function clampLyricsWordSpacing(value) {
        const n = Number(value)
        if (isNaN(n))
            return lyricsWordSpacing
        return Math.max(0, Math.min(48, n))
    }

    function clampLyricsSyncOffset(value) {
        const n = Number(value)
        if (isNaN(n))
            return lyricsSyncOffsetMs
        return Math.max(-3000, Math.min(3000, n))
    }

    function clampLyricsFloatIntensity(value) {
        const n = Number(value)
        if (isNaN(n))
            return lyricsFloatIntensity
        return Math.max(0, Math.min(24, n))
    }

    function clampLyricsGlowIntensity(value) {
        const n = Number(value)
        if (isNaN(n))
            return lyricsGlowIntensity
        return Math.max(0, Math.min(1, n))
    }

    function clampLyricsScale(value) {
        const n = Number(value)
        if (isNaN(n))
            return lyricsScale
        return Math.max(0.35, Math.min(2.50, n))
    }

    function clampLyricsRotation(value) {
        const n = Number(value)
        if (isNaN(n))
            return lyricsRotation
        return Math.max(-60, Math.min(60, n))
    }

    function clampLyricsTransformAngle(value, fallback) {
        const n = Number(value)
        if (isNaN(n))
            return fallback
        return Math.max(-70, Math.min(70, n))
    }

    function clampLyricsMaskBrushSize(value) {
        const n = Number(value)
        if (isNaN(n))
            return lyricsMaskBrushSize
        return Math.max(6, Math.min(180, n))
    }

    function clampLyricsMaterialIntensity(value, fallback) {
        const n = Number(value)
        if (isNaN(n))
            return fallback
        return Math.max(0, Math.min(1, n))
    }

    function clampLyricsMaskFeather(value) {
        const n = Number(value)
        if (isNaN(n))
            return lyricsMaskFeather
        return Math.max(0, Math.min(80, n))
    }

    function sanitizedLyricsMaskPayload(value) {
        const maxStrokes = 14
        const maxPointsPerStroke = 140
        let raw = value
        if (raw === undefined || raw === null || raw === "")
            raw = []
        let parsed = []
        try {
            parsed = typeof raw === "string" ? JSON.parse(raw) : raw
        } catch (e) {
            parsed = []
        }
        if (!Array.isArray(parsed))
            parsed = []

        const result = []
        const firstStroke = Math.max(0, parsed.length - maxStrokes)
        for (let i = firstStroke; i < parsed.length; i += 1) {
            const stroke = parsed[i] || {}
            const sourcePoints = Array.isArray(stroke.points) ? stroke.points : []
            const points = []
            const step = Math.max(1, Math.ceil(sourcePoints.length / maxPointsPerStroke))
            for (let p = 0; p < sourcePoints.length; p += step) {
                const point = sourcePoints[p] || {}
                const px = Array.isArray(point) ? point[0] : point.x
                const py = Array.isArray(point) ? point[1] : point.y
                const x = Math.max(0, Math.min(1, Number(px)))
                const y = Math.max(0, Math.min(1, Number(py)))
                if (!isNaN(x) && !isNaN(y))
                    points.push({ x: x, y: y })
            }
            if (sourcePoints.length > 1 && points.length > 0) {
                const point = sourcePoints[sourcePoints.length - 1] || {}
                const px = Array.isArray(point) ? point[0] : point.x
                const py = Array.isArray(point) ? point[1] : point.y
                const x = Math.max(0, Math.min(1, Number(px)))
                const y = Math.max(0, Math.min(1, Number(py)))
                const previous = points[points.length - 1]
                if (!isNaN(x) && !isNaN(y) && (Math.abs(previous.x - x) > 0.000001 || Math.abs(previous.y - y) > 0.000001))
                    points.push({ x: x, y: y })
            }
            if (points.length > 1)
                result.push({ brush: clampLyricsMaskBrushSize(stroke.brush), points: points })
        }

        return JSON.stringify(result)
    }

    function sanitizedLyricsBlockStylePayload(value) {
        let parsed = []
        try {
            parsed = typeof value === "string" ? JSON.parse(value || "[]") : value
        } catch (e) {
            parsed = []
        }
        if (!Array.isArray(parsed))
            parsed = []

        const result = []
        for (let i = 0; i < Math.min(4, parsed.length); i += 1) {
            const item = parsed[i] || {}
            result.push({
                colorMode: normalizeLyricsBlockColorMode(item.colorMode),
                manualColor: normalizeLyricsManualColor(item.manualColor || lyricsManualColor),
                glowMode: normalizeLyricsBlockGlowMode(item.glowMode),
                glowIntensity: clampLyricsGlowIntensity(item.glowIntensity === undefined ? lyricsGlowIntensity : item.glowIntensity)
            })
        }
        return JSON.stringify(result)
    }

    function lyricsBlockStyle(blockIndex) {
        const index = Math.max(0, Math.min(3, Number(blockIndex) || 0))
        const style = Array.isArray(lyricsBlockStyles) && lyricsBlockStyles.length > index ? lyricsBlockStyles[index] : null
        return style && typeof style === "object" ? style : ({})
    }

    function lyricsBlockColorMode(blockIndex) {
        return normalizeLyricsBlockColorMode(lyricsBlockStyle(blockIndex).colorMode)
    }

    function lyricsBlockManualColor(blockIndex) {
        return normalizeLyricsManualColor(lyricsBlockStyle(blockIndex).manualColor || lyricsManualColor)
    }

    function lyricsBlockGlowMode(blockIndex) {
        return normalizeLyricsBlockGlowMode(lyricsBlockStyle(blockIndex).glowMode)
    }

    function lyricsBlockGlowEnabled(blockIndex) {
        const mode = lyricsBlockGlowMode(blockIndex)
        if (mode === "on")
            return true
        if (mode === "off")
            return false
        return lyricsGlowEnabled
    }

    function lyricsBlockGlowIntensity(blockIndex) {
        const value = Number(lyricsBlockStyle(blockIndex).glowIntensity)
        return isNaN(value) ? lyricsGlowIntensity : Math.max(0, Math.min(1, value))
    }

    function normalizeLyricsColorMode(value) {
        const mode = String(value || "pywal").toLowerCase()
        if (mode === "palette" || mode === "wallpaper" || mode === "dynamic" || mode === "colors")
            return "palette"
        return mode === "manual" || mode === "custom" || mode === "color" ? "manual" : "pywal"
    }

    function normalizeLyricsLayoutMode(value) {
        const mode = String(value || "vertical").toLowerCase()
        if (mode === "simple" || mode === "single" || mode === "plain")
            return "simple"
        if (mode === "cascade" || mode === "stack" || mode === "centered")
            return mode
        if (mode === "two" || mode === "twolyrics" || mode === "two-lyrics" || mode === "split" || mode === "double" || mode === "duo")
            return "two"
        if (mode === "four" || mode === "fourlyrics" || mode === "four-lyrics" || mode === "quad")
            return "four"
        return "vertical"
    }

    function normalizeLyricsBlockColorMode(value) {
        const mode = String(value || "inherit").toLowerCase()
        if (mode === "pywal" || mode === "palette" || mode === "manual")
            return mode
        return "inherit"
    }

    function normalizeLyricsBlockGlowMode(value) {
        const mode = String(value || "inherit").toLowerCase()
        if (mode === "on" || mode === "off")
            return mode
        return "inherit"
    }

    function normalizeLyricsMaterialMode(value) {
        const mode = String(value || "off").toLowerCase()
        if (mode === "cloud" || mode === "fog" || mode === "mist" || mode === "soft")
            return "cloud"
        if (mode === "glass" || mode === "frost" || mode === "frosted")
            return "glass"
        if (mode === "metal" || mode === "silver" || mode === "chrome")
            return "metal"
        if (mode === "sky" || mode === "ambient" || mode === "atmosphere")
            return "sky"
        return "off"
    }

    function normalizeLyricsAnimationMode(value) {
        const mode = String(value || "instant").toLowerCase()
        if (mode === "fade" || mode === "slide")
            return mode
        return "instant"
    }

    function normalizeLyricsRevealMode(value) {
        const mode = String(value || "progressive").toLowerCase()
        if (mode === "line" || mode === "full" || mode === "complete" || mode === "all")
            return "line"
        if (mode === "current" || mode === "word" || mode === "active")
            return "current"
        return "progressive"
    }

    function normalizeLyricsManualColor(value) {
        let next = String(value || "#f5f7ff").replace(/\s+/g, "")
        if (next.charAt(0) !== "#")
            next = "#" + next
        return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(next) ? next : "#f5f7ff"
    }

    function colorListFromData(values, fallback) {
        const result = []
        if (Array.isArray(values)) {
            for (let i = 0; i < values.length; i += 1)
                result.push(fromCss(values[i], fallback))
        }
        return result.length > 0 ? result : [fallback]
    }

    function popupBubbleSolidAlpha() {
        return themeMode === "dark" ? 0.74 : 0.88
    }

    function popupBubbleOpacity(opacity) {
        const n = Number(opacity)
        const base = isNaN(n) ? popupBubbleSolidAlpha() : n
        return popupBubblesSolid ? Math.max(base, popupBubbleSolidAlpha()) : base
    }

    function popupBubbleSurface() {
        const base = popupBubblesSolid ? withAlpha(paletteSurfaceCard, popupBubbleSolidAlpha()) : surfaceCard
        const tintAmount = themeId === "pywal16"
            ? (themeMode === "dark" ? 0.16 : 0.10)
            : (themeMode === "dark" ? 0.08 : 0.05)
        return mix(base, accentPrimary, tintAmount, base.a)
    }

    function withOpacity(colorValue, opacity, role) {
        return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, clampOpacity(opacity, colorValue.a, role))
    }

    function withAlpha(colorValue, opacity) {
        return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, Math.max(0, Math.min(1, Number(opacity) || 0)))
    }

    function hsvColor(hue, saturation, value, opacity) {
        const h = ((Number(hue) || 0) % 1 + 1) % 1
        const s = Math.max(0, Math.min(1, Number(saturation) || 0))
        const v = Math.max(0, Math.min(1, Number(value) || 0))
        const i = Math.floor(h * 6)
        const f = h * 6 - i
        const p = v * (1 - s)
        const q = v * (1 - f * s)
        const t = v * (1 - (1 - f) * s)
        var r = v
        var g = t
        var b = p

        switch (i % 6) {
        case 0: r = v; g = t; b = p; break
        case 1: r = q; g = v; b = p; break
        case 2: r = p; g = v; b = t; break
        case 3: r = p; g = q; b = v; break
        case 4: r = t; g = p; b = v; break
        case 5: r = v; g = p; b = q; break
        }

        return Qt.rgba(r, g, b, opacity === undefined ? 1 : Math.max(0, Math.min(1, Number(opacity) || 0)))
    }

    function hueOf(colorValue) {
        const maxV = Math.max(colorValue.r, colorValue.g, colorValue.b)
        const minV = Math.min(colorValue.r, colorValue.g, colorValue.b)
        const d = maxV - minV
        if (d <= 0.0001)
            return borderHue

        var h = 0
        if (maxV === colorValue.r)
            h = ((colorValue.g - colorValue.b) / d) % 6
        else if (maxV === colorValue.g)
            h = (colorValue.b - colorValue.r) / d + 2
        else
            h = (colorValue.r - colorValue.g) / d + 4

        return ((h / 6) % 1 + 1) % 1
    }

    function syncBorderValuesFromSurfaces() {
        borderAdaptEnabled = true
        borderHue = hueOf(sidebarBorderGlow)
    }

    function applyBorderAccent(adapt, hue, persist) {
        borderOverrideActive = true
        borderAdaptEnabled = adapt !== false
        borderHue = clampLevel(hue, borderHue)

        const accent = borderAdaptEnabled ? accentPrimary : hsvColor(borderHue, 0.82, 1.0, 1)
        const sharedBorderAlpha = Math.max(sidebarBorderGlow.a, popupBorderGlow.a)
        borderGlow = withAlpha(accent, borderGlow.a)
        sidebarBorderGlow = withAlpha(accent, sharedBorderAlpha)
        popupBorderGlow = withAlpha(accent, sharedBorderAlpha)
        if (persist !== false)
            saveBorder()
    }

    function applyLoadedBorderOverrides() {
        if (borderOverrideActive)
            applyBorderAccent(borderAdaptEnabled, borderHue, false)
        else
            syncBorderValuesFromSurfaces()
    }

    function resetBorderAccent() {
        borderOverrideActive = false
        borderAdaptEnabled = true
        borderResetProc.running = true
        applyTheme(themeId, false)
    }

    function syncOpacityValuesFromSurfaces() {
        syncPanelMaterial(Math.max(surfaceSidebar.a, surfacePopup.a))
        cardOpacity = surfaceCard.a
        syncBarOpacityFromSurface()
    }

    function applyOpacity(sidebar, popup, card, persist) {
        opacityOverrideActive = true
        syncPanelMaterial(panelOpacitySource(sidebar, popup))
        cardOpacity = clampOpacity(card, surfaceCard.a, "card")
        surfaceCard = withOpacity(paletteSurfaceCard, cardOpacity, "card")
        surfaceInput = withOpacity(paletteSurfaceInput, Math.max(minOpacityForRole("card"), cardOpacity - 0.08), "card")
        surfaceButton = withOpacity(paletteSurfaceButton, Math.max(minOpacityForRole("card"), cardOpacity - 0.06), "card")
        syncBarOpacityFromSurface()
        if (persist !== false)
            saveOpacity()
    }

    function applyBarOpacity(opacity, persist) {
        barOpacityOverrideActive = true
        barOpacity = clampBarOpacity(opacity, barOpacity)
        if (persist !== false)
            saveBarOpacity()
    }

    function applyLoadedBarOpacityOverride() {
        if (barOpacityOverrideActive)
            applyBarOpacity(barOpacity, false)
        else
            syncBarOpacityFromSurface()
    }

    function applyLoadedOpacityOverrides() {
        if (opacityOverrideActive)
            applyOpacity(sidebarOpacity, popupOpacity, cardOpacity, false)
        else
            syncOpacityValuesFromSurfaces()
        applyLoadedBarOpacityOverride()
    }

    function resetOpacity() {
        opacityOverrideActive = false
        barOpacityOverrideActive = false
        opacityResetProc.running = true
        applyTheme(themeId, false)
    }

    function syncGlowValuesFromSurfaces() {
        generalGlow = Math.max(0, Math.min(1, Math.max(sidebarBorderGlow.a / 0.78, popupBorderGlow.a / 0.78, textGlow.a / 0.38, iconGlow.a / 0.52)))
        const sharedBorderLevel = generalGlow > 0 ? Math.max(0, Math.min(1, Math.max(sidebarBorderGlow.a, popupBorderGlow.a) / (generalGlow * 0.78))) : 0
        sidebarBorderGlowLevel = sharedBorderLevel
        popupBorderGlowLevel = sharedBorderLevel
        iconGlowLevel = generalGlow > 0 ? Math.max(0, Math.min(1, iconGlow.a / (generalGlow * 0.52))) : 0
        textGlowLevel = Math.max(0, Math.min(1, textGlow.a / textGlowMaxAlpha()))

        const sharedGlowAlpha = Math.max(sidebarGlow.a, popupGlow.a)
        sidebarGlow = withAlpha(sidebarGlow, sharedGlowAlpha)
        popupGlow = withAlpha(sidebarGlow, sharedGlowAlpha)
        const sharedBorderAlpha = Math.max(sidebarBorderGlow.a, popupBorderGlow.a)
        sidebarBorderGlow = withAlpha(sidebarBorderGlow, sharedBorderAlpha)
        popupBorderGlow = withAlpha(sidebarBorderGlow, sharedBorderAlpha)
    }

    function textGlowMaxAlpha() {
        if (themeId === "pywal16" && themeMode === "dark")
            return 0.82
        if (themeMode === "dark")
            return 0.66
        return 0.48
    }

    function applyTextGlow(text, persist) {
        glowOverrideActive = true
        textGlowLevel = clampLevel(text, textGlowLevel)
        textGlow = withAlpha(textGlow, textGlowLevel * textGlowMaxAlpha())
        if (persist !== false)
            saveGlow()
    }

    function applyGlow(general, sidebarBorder, popupBorder, icon, text, persist) {
        glowOverrideActive = true
        generalGlow = clampLevel(general, generalGlow)
        const sidebarBorderValue = Number(sidebarBorder)
        const popupBorderValue = Number(popupBorder)
        const sidebarBorderChanged = !isNaN(sidebarBorderValue) && Math.abs(sidebarBorderValue - sidebarBorderGlowLevel) > 0.001
        const popupBorderChanged = !isNaN(popupBorderValue) && Math.abs(popupBorderValue - popupBorderGlowLevel) > 0.001
        const sharedBorderLevel = clampLevel(popupBorderChanged && !sidebarBorderChanged ? popupBorderValue : sidebarBorderValue, sidebarBorderGlowLevel)
        sidebarBorderGlowLevel = sharedBorderLevel
        popupBorderGlowLevel = sharedBorderLevel
        iconGlowLevel = clampLevel(icon === undefined ? generalGlow : icon, iconGlowLevel)
        sidebarGlow = withAlpha(sidebarGlow, generalGlow * sharedBorderLevel * 0.10)
        popupGlow = withAlpha(sidebarGlow, generalGlow * sharedBorderLevel * 0.10)
        iconGlow = withAlpha(iconGlow, generalGlow * iconGlowLevel * 0.52)
        buttonPrimaryGlow = withAlpha(buttonPrimaryGlow, generalGlow * 0.44)
        sidebarBorderGlow = withAlpha(sidebarBorderGlow, generalGlow * sharedBorderLevel * 0.78)
        popupBorderGlow = withAlpha(sidebarBorderGlow, generalGlow * sharedBorderLevel * 0.78)
        borderGlow = withAlpha(borderGlow, generalGlow * sharedBorderLevel * 0.66)
        applyTextGlow(text === undefined ? textGlowLevel : text, false)
        if (persist !== false)
            saveGlow()
    }

    function applyLoadedGlowOverrides() {
        if (glowOverrideActive)
            applyGlow(generalGlow, sidebarBorderGlowLevel, popupBorderGlowLevel, iconGlowLevel, textGlowLevel, false)
        else
            syncGlowValuesFromSurfaces()
    }

    function resetGlow() {
        glowOverrideActive = false
        glowResetProc.running = true
        applyTheme(themeId, false)
    }

    function mix(a, b, amount, opacity) {
        const t = Math.max(0, Math.min(1, Number(amount) || 0))
        const o = opacity === undefined ? (a.a + (b.a - a.a) * t) : opacity
        return Qt.rgba(
            a.r + (b.r - a.r) * t,
            a.g + (b.g - a.g) * t,
            a.b + (b.b - a.b) * t,
            o
        )
    }

    function fromHex(hex, fallback, opacity) {
        var h = String(hex || "").replace("#", "").trim()
        if (h.length !== 6)
            return fallback

        var r = parseInt(h.slice(0, 2), 16)
        var g = parseInt(h.slice(2, 4), 16)
        var b = parseInt(h.slice(4, 6), 16)
        if (isNaN(r) || isNaN(g) || isNaN(b))
            return fallback

        return Qt.rgba(r / 255, g / 255, b / 255, opacity === undefined ? 1 : opacity)
    }

    function fromCss(value, fallback) {
        const s = String(value || "").trim()
        if (s.indexOf("#") === 0)
            return fromHex(s, fallback)

        const match = s.match(/rgba?\(([^)]+)\)/)
        if (!match)
            return fallback

        const parts = match[1].split(",").map(function(v) { return Number(String(v).trim()) })
        if (parts.length < 3 || isNaN(parts[0]) || isNaN(parts[1]) || isNaN(parts[2]))
            return fallback

        return Qt.rgba(parts[0] / 255, parts[1] / 255, parts[2] / 255, parts.length > 3 && !isNaN(parts[3]) ? parts[3] : 1)
    }

    function buildThemePalette(data) {
        return {
            id: data.id || "pywal16",
            themeName: data.themeName || data.id || "pywal16",
            themeMode: data.themeMode || "balanced",
            notice: data.notice || "",
            surfaceBase: fromCss(data.surfaceBase, surfaceBase),
            surfaceSidebar: fromCss(data.surfaceSidebar, surfaceSidebar),
            surfacePopup: fromCss(data.surfacePopup, surfacePopup),
            surfaceCard: fromCss(data.surfaceCard, surfaceCard),
            surfaceInput: fromCss(data.surfaceInput, surfaceInput),
            surfaceButton: fromCss(data.surfaceButton, surfaceButton),
            textPrimary: fromCss(data.textPrimary, textPrimary),
            textSecondary: fromCss(data.textSecondary, textSecondary),
            textMuted: fromCss(data.textMuted, textMuted),
            accentPrimary: fromCss(data.accentPrimary, accentPrimary),
            accentSecondary: fromCss(data.accentSecondary, accentSecondary),
            accentTertiary: fromCss(data.accentTertiary, accentTertiary),
            lyricsPywalColor: fromCss(data.lyricsColor, accentPrimary),
            lyricsPalette: colorListFromData(data.lyricsPalette, fromCss(data.lyricsColor, accentPrimary)),
            borderSoft: fromCss(data.borderSoft, borderSoft),
            borderActive: fromCss(data.borderActive, borderActive),
            borderGlow: fromCss(data.borderGlow, borderGlow),
            sidebarBorderGlow: fromCss(data.sidebarBorderGlow, borderGlow),
            popupBorderGlow: fromCss(data.popupBorderGlow, borderGlow),
            buttonPrimaryBg: fromCss(data.buttonPrimaryBg, buttonPrimaryBg),
            buttonPrimaryText: fromCss(data.buttonPrimaryText, buttonPrimaryText),
            buttonPrimaryGlow: fromCss(data.buttonPrimaryGlow, buttonPrimaryGlow),
            buttonSecondaryBg: fromCss(data.buttonSecondaryBg, buttonSecondaryBg),
            buttonSecondaryText: fromCss(data.buttonSecondaryText, buttonSecondaryText),
            activeBg: fromCss(data.activeBg, activeBg),
            activeText: fromCss(data.activeText, activeText),
            hoverBg: fromCss(data.hoverBg, hoverBg),
            shadowColor: fromCss(data.shadowColor, shadowColor),
            sidebarGlow: fromCss(data.sidebarGlow, sidebarGlow),
            popupGlow: fromCss(data.popupGlow, popupGlow),
            textGlow: fromCss(data.textGlow, textGlow),
            iconGlow: fromCss(data.iconGlow, iconGlow),
            glassBlur: Number(data.glassBlur || glassBlur)
        }
    }

    function applyThemeMeta(palette, idOverride, notice) {
        themeId = idOverride || palette.id || "pywal16"
        themeName = palette.themeName || themeId
        themeMode = palette.themeMode || "balanced"
        themeNotice = notice || palette.notice || ""
    }

    function applyThemeBarStage(palette) {
        paletteSurfaceBase = palette.surfaceBase
        paletteSurfaceSidebar = palette.surfaceSidebar
        surfaceBase = palette.surfaceBase
        surfaceSidebar = palette.surfaceSidebar
        borderSoft = palette.borderSoft
        sidebarBorderGlow = palette.sidebarBorderGlow
        syncBarOpacityFromSurface()
    }

    function applyThemeTextStage(palette) {
        textPrimary = palette.textPrimary
        textSecondary = palette.textSecondary
        textMuted = palette.textMuted
        buttonPrimaryText = palette.buttonPrimaryText
        buttonSecondaryText = palette.buttonSecondaryText
        activeText = palette.activeText
    }

    function applyThemePanelStage(palette) {
        paletteSurfacePopup = palette.surfacePopup
        paletteSurfaceCard = palette.surfaceCard
        paletteSurfaceInput = palette.surfaceInput
        paletteSurfaceButton = palette.surfaceButton
        surfacePopup = palette.surfacePopup
        surfaceCard = palette.surfaceCard
        surfaceInput = palette.surfaceInput
        surfaceButton = palette.surfaceButton
        accentPrimary = palette.accentPrimary
        accentSecondary = palette.accentSecondary
        accentTertiary = palette.accentTertiary
        lyricsPywalColor = palette.lyricsPywalColor
        lyricsPalette = palette.lyricsPalette
        borderActive = palette.borderActive
        borderGlow = palette.borderGlow
        popupBorderGlow = palette.popupBorderGlow
        buttonPrimaryBg = palette.buttonPrimaryBg
        buttonSecondaryBg = palette.buttonSecondaryBg
        activeBg = palette.activeBg
        hoverBg = palette.hoverBg
    }

    function applyThemeGlowStage(palette) {
        buttonPrimaryGlow = palette.buttonPrimaryGlow
        shadowColor = palette.shadowColor
        sidebarGlow = palette.sidebarGlow
        popupGlow = palette.popupGlow
        textGlow = palette.textGlow
        iconGlow = palette.iconGlow
        glassBlur = palette.glassBlur
        applyLoadedBorderOverrides()
        applyLoadedGlowOverrides()
        applyLoadedOpacityOverrides()
    }

    function applyCompleteThemePalette(palette) {
        applyThemeBarStage(palette)
        applyThemeTextStage(palette)
        applyThemePanelStage(palette)
        applyThemeGlowStage(palette)
    }

    function startStagedThemePalette(palette, idOverride, notice) {
        stagedPaletteActive = true
        stagedThemeData = {
            palette: palette,
            idOverride: idOverride || "",
            notice: notice || ""
        }
        stagedPaletteStep = 0
        applyThemeMeta(palette, idOverride, notice)
        applyNextStagedThemeStep()
    }

    function applyNextStagedThemeStep() {
        const staged = stagedThemeData || {}
        const palette = staged.palette
        if (!palette) {
            stagedPaletteActive = false
            endPaletteApply()
            return
        }

        if (stagedPaletteStep === 0)
            applyThemeBarStage(palette)
        else if (stagedPaletteStep === 1)
            applyThemeTextStage(palette)
        else if (stagedPaletteStep === 2)
            applyThemePanelStage(palette)
        else
            applyThemeGlowStage(palette)

        if (stagedPaletteStep >= 3) {
            stagedPaletteActive = false
            stagedThemeData = ({})
            endPaletteApply()
            return
        }

        stagedPaletteStep += 1
        stagedThemeTimer.restart()
    }

    function applyThemeData(data, idOverride, notice, animate) {
        if (!data)
            return false

        const palette = buildThemePalette(data)
        beginPaletteApply(animate === true)
        if (animate === true && (idOverride || palette.id) === "pywal16") {
            startStagedThemePalette(palette, idOverride, notice)
            return true
        }

        applyThemeMeta(palette, idOverride, notice)
        applyCompleteThemePalette(palette)
        endPaletteApply()
        return true
    }

    function setDefaultPalette() {
        themeId = "default"
        themeName = "Velora Default"
        themeMode = "light"
        themeNotice = ""
        setPaletteSurfaces(
            Qt.rgba(255 / 255, 250 / 255, 254 / 255, 0.86),
            Qt.rgba(255 / 255, 247 / 255, 253 / 255, 0.88),
            Qt.rgba(255 / 255, 250 / 255, 254 / 255, 0.90),
            Qt.rgba(1, 1, 1, 0.76),
            Qt.rgba(1, 1, 1, 0.64),
            Qt.rgba(1, 1, 1, 0.66)
        )
        textPrimary = "#4d3f63"
        textSecondary = "#8d7ca3"
        textMuted = "#b7a9c7"
        accentPrimary = "#e8a6c8"
        accentSecondary = "#c894f2"
        accentTertiary = "#a8d8ff"
        lyricsPywalColor = "#e8a6c8"
        lyricsPalette = ["#e8a6c8", "#c894f2", "#a8d8ff"]
        borderSoft = Qt.rgba(1, 1, 1, 0.78)
        borderActive = Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.78)
        borderGlow = Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.18)
        sidebarBorderGlow = Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.18)
        popupBorderGlow = Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.18)
        buttonPrimaryBg = "#e8a6c8"
        buttonPrimaryText = "#ffffff"
        buttonPrimaryGlow = Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.22)
        buttonSecondaryBg = Qt.rgba(1, 1, 1, 0.58)
        buttonSecondaryText = "#6d5a82"
        activeBg = Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.35)
        activeText = "#ffffff"
        hoverBg = Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.16)
        shadowColor = Qt.rgba(95 / 255, 70 / 255, 130 / 255, 0.10)
        sidebarGlow = Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.10)
        popupGlow = Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.10)
        textGlow = Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.12)
        iconGlow = Qt.rgba(232 / 255, 166 / 255, 200 / 255, 0.18)
        glassBlur = 18
    }

    function setDarkPalette() {
        themeId = "dark"
        themeName = "Dark"
        themeMode = "dark"
        themeNotice = ""
        setPaletteSurfaces(
            Qt.rgba(28 / 255, 25 / 255, 36 / 255, 0.78),
            Qt.rgba(34 / 255, 29 / 255, 44 / 255, 0.82),
            Qt.rgba(39 / 255, 34 / 255, 50 / 255, 0.90),
            Qt.rgba(62 / 255, 54 / 255, 74 / 255, 0.72),
            Qt.rgba(62 / 255, 54 / 255, 74 / 255, 0.50),
            Qt.rgba(1, 1, 1, 0.12)
        )
        textPrimary = "#f2eaf7"
        textSecondary = "#d9c6ea"
        textMuted = "#a899b8"
        accentPrimary = "#e7a3c7"
        accentSecondary = "#b89cf2"
        accentTertiary = "#89c8ef"
        lyricsPywalColor = "#e7a3c7"
        lyricsPalette = ["#e7a3c7", "#b89cf2", "#89c8ef"]
        borderSoft = Qt.rgba(1, 1, 1, 0.18)
        borderActive = Qt.rgba(231 / 255, 163 / 255, 199 / 255, 0.66)
        borderGlow = Qt.rgba(137 / 255, 200 / 255, 239 / 255, 0.22)
        sidebarBorderGlow = Qt.rgba(137 / 255, 200 / 255, 239 / 255, 0.22)
        popupBorderGlow = Qt.rgba(137 / 255, 200 / 255, 239 / 255, 0.22)
        buttonPrimaryBg = "#d889b5"
        buttonPrimaryText = "#ffffff"
        buttonPrimaryGlow = Qt.rgba(216 / 255, 137 / 255, 181 / 255, 0.24)
        buttonSecondaryBg = Qt.rgba(1, 1, 1, 0.12)
        buttonSecondaryText = "#eadff3"
        activeBg = Qt.rgba(231 / 255, 163 / 255, 199 / 255, 0.32)
        activeText = "#ffffff"
        hoverBg = Qt.rgba(1, 1, 1, 0.10)
        shadowColor = Qt.rgba(16 / 255, 10 / 255, 24 / 255, 0.24)
        sidebarGlow = Qt.rgba(137 / 255, 200 / 255, 239 / 255, 0.16)
        popupGlow = Qt.rgba(137 / 255, 200 / 255, 239 / 255, 0.13)
        textGlow = Qt.rgba(231 / 255, 163 / 255, 199 / 255, 0.12)
        iconGlow = Qt.rgba(231 / 255, 163 / 255, 199 / 255, 0.18)
        glassBlur = 18
    }

    function setPinkPalette() {
        themeId = "pink"
        themeName = "Pink"
        themeMode = "light"
        themeNotice = ""
        setPaletteSurfaces(
            Qt.rgba(255 / 255, 244 / 255, 249 / 255, 0.74),
            Qt.rgba(255 / 255, 239 / 255, 248 / 255, 0.80),
            Qt.rgba(255 / 255, 244 / 255, 250 / 255, 0.86),
            Qt.rgba(1, 1, 1, 0.72),
            Qt.rgba(1, 1, 1, 0.58),
            Qt.rgba(1, 1, 1, 0.60)
        )
        textPrimary = "#5d3d56"
        textSecondary = "#966785"
        textMuted = "#c9a0b8"
        accentPrimary = "#ef8cba"
        accentSecondary = "#f2b1cf"
        accentTertiary = "#a8d8ff"
        lyricsPywalColor = "#ef8cba"
        lyricsPalette = ["#ef8cba", "#f2b1cf", "#a8d8ff"]
        borderSoft = Qt.rgba(1, 1, 1, 0.70)
        borderActive = Qt.rgba(239 / 255, 140 / 255, 186 / 255, 0.74)
        borderGlow = Qt.rgba(239 / 255, 140 / 255, 186 / 255, 0.24)
        sidebarBorderGlow = Qt.rgba(239 / 255, 140 / 255, 186 / 255, 0.24)
        popupBorderGlow = Qt.rgba(239 / 255, 140 / 255, 186 / 255, 0.24)
        buttonPrimaryBg = "#ef8cba"
        buttonPrimaryText = "#ffffff"
        buttonPrimaryGlow = Qt.rgba(239 / 255, 140 / 255, 186 / 255, 0.24)
        buttonSecondaryBg = Qt.rgba(1, 1, 1, 0.60)
        buttonSecondaryText = "#80536f"
        activeBg = Qt.rgba(239 / 255, 140 / 255, 186 / 255, 0.34)
        activeText = "#ffffff"
        hoverBg = Qt.rgba(239 / 255, 140 / 255, 186 / 255, 0.16)
        shadowColor = Qt.rgba(130 / 255, 72 / 255, 110 / 255, 0.13)
        sidebarGlow = Qt.rgba(239 / 255, 140 / 255, 186 / 255, 0.15)
        popupGlow = Qt.rgba(239 / 255, 140 / 255, 186 / 255, 0.13)
        textGlow = Qt.rgba(239 / 255, 140 / 255, 186 / 255, 0.10)
        iconGlow = Qt.rgba(239 / 255, 140 / 255, 186 / 255, 0.16)
        glassBlur = 18
    }

    function setLavenderPalette() {
        themeId = "lavender"
        themeName = "Lavender"
        themeMode = "light"
        themeNotice = ""
        setPaletteSurfaces(
            Qt.rgba(248 / 255, 246 / 255, 255 / 255, 0.74),
            Qt.rgba(244 / 255, 240 / 255, 255 / 255, 0.80),
            Qt.rgba(248 / 255, 246 / 255, 255 / 255, 0.86),
            Qt.rgba(1, 1, 1, 0.70),
            Qt.rgba(1, 1, 1, 0.56),
            Qt.rgba(1, 1, 1, 0.58)
        )
        textPrimary = "#4b416a"
        textSecondary = "#8171a4"
        textMuted = "#aaa0c6"
        accentPrimary = "#d8a4e6"
        accentSecondary = "#b994f2"
        accentTertiary = "#99d4ff"
        lyricsPywalColor = "#d8a4e6"
        lyricsPalette = ["#d8a4e6", "#b994f2", "#99d4ff"]
        borderSoft = Qt.rgba(1, 1, 1, 0.68)
        borderActive = Qt.rgba(185 / 255, 148 / 255, 242 / 255, 0.72)
        borderGlow = Qt.rgba(185 / 255, 148 / 255, 242 / 255, 0.24)
        sidebarBorderGlow = Qt.rgba(185 / 255, 148 / 255, 242 / 255, 0.24)
        popupBorderGlow = Qt.rgba(185 / 255, 148 / 255, 242 / 255, 0.24)
        buttonPrimaryBg = "#b994f2"
        buttonPrimaryText = "#ffffff"
        buttonPrimaryGlow = Qt.rgba(185 / 255, 148 / 255, 242 / 255, 0.22)
        buttonSecondaryBg = Qt.rgba(1, 1, 1, 0.58)
        buttonSecondaryText = "#675685"
        activeBg = Qt.rgba(185 / 255, 148 / 255, 242 / 255, 0.32)
        activeText = "#ffffff"
        hoverBg = Qt.rgba(185 / 255, 148 / 255, 242 / 255, 0.14)
        shadowColor = Qt.rgba(82 / 255, 62 / 255, 130 / 255, 0.12)
        sidebarGlow = Qt.rgba(185 / 255, 148 / 255, 242 / 255, 0.15)
        popupGlow = Qt.rgba(185 / 255, 148 / 255, 242 / 255, 0.13)
        textGlow = Qt.rgba(185 / 255, 148 / 255, 242 / 255, 0.10)
        iconGlow = Qt.rgba(185 / 255, 148 / 255, 242 / 255, 0.16)
        glassBlur = 18
    }

    function setReferencePalette() {
        setDarkPalette()
        themeId = "reference"
        themeName = "Velora · Referência"
        setPaletteSurfaces("#f5202430", "#f5202430", "#fa242936",
            "#e62d3345", "#f02a3041", "#cc30364b")
        textPrimary = "#edf1ff"
        textSecondary = "#c4cede"
        textMuted = "#8994a9"
        accentPrimary = "#3d70ef"
        accentSecondary = "#91adf1"
        accentTertiary = "#bbcbef"
        buttonPrimaryBg = "#3d70ef"
        buttonSecondaryText = "#e4eaff"
        activeBg = "#993d70ef"
        hoverBg = "#263d70ef"
        borderSoft = "#343f526f"
        borderActive = "#663d70ef"
        sidebarBorderGlow = "#293d5070"
        popupBorderGlow = "#343d5070"
        textGlow = "transparent"
        iconGlow = "transparent"
        sidebarGlow = "transparent"
        popupGlow = "transparent"
        shadowColor = "#240b101c"
    }

    function applyTheme(id, persist) {
        const requested = String(id || "default")
        const next = referencePalette ? "reference"
            : (requested === "reference" ? "pywal16" : requested)

        beginPaletteApply(persist !== false)
        if (next === "reference")
            setReferencePalette()
        else if (next === "dark")
            setDarkPalette()
        else if (next === "pink")
            setPinkPalette()
        else if (next === "lavender")
            setLavenderPalette()
        else if (next === "pywal16") {
            themeId = "pywal16"
            themeName = "pywal16"
            themeMode = "dynamic"
            themeNotice = "pywal16 selecionado; carregando tema gerado."
            loadPywal16(persist !== false)
        } else {
            setDefaultPalette()
        }

        if (!referencePalette) {
            applyLoadedGlowOverrides()
            applyLoadedBorderOverrides()
        }
        applyLoadedOpacityOverrides()
        endPaletteApply()

        if (persist !== false)
            saveTheme()
    }

    function reloadPywal16() {
        pywalAvailable = false
        if (themeId === "pywal16") {
            themeId = "pywal16"
            themeName = "pywal16"
            themeMode = "dynamic"
            themeNotice = "Recarregando pywal16."
            loadPywal16(true)
        } else if (!pywalProbe.running) {
            pywalProbe.running = true
        }
    }

    function saveTheme() {
        if (saveProc.running)
            saveProc.pendingTheme = themeId
        else {
            saveProc.command = [root.stateScript, "set", themeId]
            saveProc.running = true
        }
    }

    function saveOpacity() {
        const sidebar = Number(sidebarOpacity).toFixed(2)
        const popup = Number(popupOpacity).toFixed(2)
        const card = Number(cardOpacity).toFixed(2)
        if (opacitySaveProc.running)
            opacitySaveProc.pending = sidebar + "|" + popup + "|" + card
        else {
            opacitySaveProc.command = [root.stateScript, "opacity", "set", sidebar, popup, card]
            opacitySaveProc.running = true
        }
    }

    function saveBarOpacity() {
        const opacity = Number(barOpacity).toFixed(2)
        if (barOpacitySaveProc.running)
            barOpacitySaveProc.pending = opacity
        else {
            barOpacitySaveProc.command = [root.stateScript, "bar-opacity", "set", opacity]
            barOpacitySaveProc.running = true
        }
    }

    function saveGlow() {
        const general = Number(generalGlow).toFixed(2)
        const sidebarBorder = Number(sidebarBorderGlowLevel).toFixed(2)
        const popupBorder = Number(popupBorderGlowLevel).toFixed(2)
        const icon = Number(iconGlowLevel).toFixed(2)
        const text = Number(textGlowLevel).toFixed(2)
        if (glowSaveProc.running)
            glowSaveProc.pending = general + "|" + sidebarBorder + "|" + popupBorder + "|" + icon + "|" + text
        else {
            glowSaveProc.command = [root.stateScript, "glow", "set", general, sidebarBorder, popupBorder, icon, text]
            glowSaveProc.running = true
        }
    }

    function saveBorder() {
        const mode = borderAdaptEnabled ? "adapt" : "manual"
        const hue = Number(borderHue).toFixed(3)
        if (borderSaveProc.running)
            borderSaveProc.pending = mode + "|" + hue
        else {
            borderSaveProc.command = [root.stateScript, "border", "set", mode, hue]
            borderSaveProc.running = true
        }
    }

    function setVisualizerStrength(value, persist) {
        visualizerStrength = clampVisualizerStrength(value)
        if (persist !== false)
            saveVisualizerStrength()
    }

    function resetVisualizerStrength() {
        visualizerStrength = 0.46
        visualizerResetProc.running = true
    }

    function saveVisualizerStrength() {
        const strength = Number(visualizerStrength).toFixed(2)
        if (visualizerSaveProc.running)
            visualizerSaveProc.pending = strength
        else {
            visualizerSaveProc.command = [root.stateScript, "visualizer", "set", strength]
            visualizerSaveProc.running = true
        }
    }

    function setVisualizerMode(mode, persist) {
        visualizerMode = normalizeVisualizerMode(mode)
        if (persist !== false)
            saveVisualizerMode()
    }

    function saveVisualizerMode() {
        const mode = normalizeVisualizerMode(visualizerMode)
        if (visualizerModeSaveProc.running)
            visualizerModeSaveProc.pending = mode
        else {
            visualizerModeSaveProc.command = [root.stateScript, "visualizer-mode", "set", mode]
            visualizerModeSaveProc.running = true
        }
    }

    function setVisualizerPixelSize(value, persist) {
        visualizerPixelSize = clampVisualizerPixelSize(value)
        if (persist !== false)
            saveVisualizerPixelSize()
    }

    function saveVisualizerPixelSize() {
        const size = Number(visualizerPixelSize).toFixed(2)
        if (visualizerPixelSizeSaveProc.running)
            visualizerPixelSizeSaveProc.pending = size
        else {
            visualizerPixelSizeSaveProc.command = [root.stateScript, "visualizer-pixel-size", "set", size]
            visualizerPixelSizeSaveProc.running = true
        }
    }

    function setVisualizerGradientEnabled(enabled, persist) {
        visualizerGradientEnabled = truthyEnabled(enabled)
        if (persist !== false)
            saveVisualizerGradientEnabled()
    }

    function saveVisualizerGradientEnabled() {
        const enabled = visualizerGradientEnabled ? "on" : "off"
        if (visualizerGradientSaveProc.running)
            visualizerGradientSaveProc.pending = enabled
        else {
            visualizerGradientSaveProc.command = [root.stateScript, "visualizer-gradient", "set", enabled]
            visualizerGradientSaveProc.running = true
        }
    }

    function applyLyricsSettings(enabled, posX, posY, colorMode, manualColor, fontSize, opacity, spacing, shadow, uppercase, layoutMode, animationMode, activeWord, revealMode, pos2X, pos2Y, syncOffsetMs, floatEnabled, floatIntensity, glowEnabled, glowIntensity, persist) {
        lyricsEnabled = truthyEnabled(enabled)
        lyricsPositionX = clampLyricsPercent(posX, lyricsPositionX)
        lyricsPositionY = clampLyricsPercent(posY, lyricsPositionY)
        lyricsSecondPositionX = clampLyricsPercent(pos2X, lyricsSecondPositionX)
        lyricsSecondPositionY = clampLyricsPercent(pos2Y, lyricsSecondPositionY)
        lyricsColorMode = normalizeLyricsColorMode(colorMode)
        lyricsManualColor = normalizeLyricsManualColor(manualColor)
        lyricsFontSize = clampLyricsFontSize(fontSize)
        lyricsOpacity = clampLyricsOpacity(opacity)
        lyricsWordSpacing = clampLyricsWordSpacing(spacing)
        lyricsShadowEnabled = truthyEnabled(shadow)
        lyricsUppercase = truthyEnabled(uppercase)
        lyricsLayoutMode = normalizeLyricsLayoutMode(layoutMode)
        lyricsAnimationMode = normalizeLyricsAnimationMode(animationMode)
        lyricsActiveWordEnabled = truthyEnabled(activeWord)
        lyricsRevealMode = normalizeLyricsRevealMode(revealMode)
        lyricsSyncOffsetMs = clampLyricsSyncOffset(syncOffsetMs)
        lyricsFloatEnabled = truthyEnabled(floatEnabled)
        lyricsFloatIntensity = clampLyricsFloatIntensity(floatIntensity)
        lyricsGlowEnabled = truthyEnabled(glowEnabled)
        lyricsGlowIntensity = clampLyricsGlowIntensity(glowIntensity)
        if (persist !== false)
            saveLyricsSettings()
    }

    function resetLyricsSettings() {
        applyLyricsSettings(false, 18, 44, "pywal", "#f5f7ff", 86, 0.86, 8, true, true, "vertical", "instant", true, "progressive", 74, 18, 460, true, 5, true, 0.45, true)
    }

    function saveLyricsSettings() {
        const values = [
            lyricsEnabled ? "on" : "off",
            lyricsPositionX.toFixed(2),
            lyricsPositionY.toFixed(2),
            normalizeLyricsColorMode(lyricsColorMode),
            normalizeLyricsManualColor(lyricsManualColor),
            lyricsFontSize.toFixed(2),
            lyricsOpacity.toFixed(2),
            lyricsWordSpacing.toFixed(2),
            lyricsShadowEnabled ? "on" : "off",
            lyricsUppercase ? "on" : "off",
            normalizeLyricsLayoutMode(lyricsLayoutMode),
            normalizeLyricsAnimationMode(lyricsAnimationMode),
            lyricsActiveWordEnabled ? "on" : "off",
            normalizeLyricsRevealMode(lyricsRevealMode),
            lyricsSecondPositionX.toFixed(2),
            lyricsSecondPositionY.toFixed(2),
            lyricsSyncOffsetMs.toFixed(2),
            lyricsFloatEnabled ? "on" : "off",
            lyricsFloatIntensity.toFixed(2),
            "glow",
            lyricsGlowEnabled ? "on" : "off",
            lyricsGlowIntensity.toFixed(2)
        ]
        const payload = values.join("|")
        if (lyricsSaveProc.running)
            lyricsSaveProc.pending = payload
        else {
            lyricsSaveProc.command = [root.stateScript, "lyrics", "set"].concat(values)
            lyricsSaveProc.running = true
        }
    }

    function setLyricsCinematicEnabled(enabled, persist) {
        lyricsCinematicEnabled = truthyEnabled(enabled)
        if (persist !== false)
            saveLyricsCinematicEnabled()
    }

    function saveLyricsCinematicEnabled() {
        const enabled = lyricsCinematicEnabled ? "on" : "off"
        if (lyricsCinematicSaveProc.running)
            lyricsCinematicSaveProc.pending = enabled
        else {
            lyricsCinematicSaveProc.command = [root.stateScript, "lyrics-cinematic", "set", enabled]
            lyricsCinematicSaveProc.running = true
        }
    }

    function applyLyricsTransformSettings(scale, rotation, tiltX, tiltY, persist) {
        lyricsScale = clampLyricsScale(scale)
        lyricsRotation = clampLyricsRotation(rotation)
        lyricsTiltX = clampLyricsTransformAngle(tiltX, lyricsTiltX)
        lyricsTiltY = clampLyricsTransformAngle(tiltY, lyricsTiltY)
        if (persist !== false)
            saveLyricsTransformSettings()
    }

    function resetLyricsTransformSettings() {
        applyLyricsTransformSettings(1, 0, 0, 0, true)
    }

    function saveLyricsTransformSettings() {
        const values = [
            lyricsScale.toFixed(2),
            lyricsRotation.toFixed(2),
            lyricsTiltX.toFixed(2),
            lyricsTiltY.toFixed(2)
        ]
        const payload = values.join("|")
        if (lyricsTransformSaveProc.running)
            lyricsTransformSaveProc.pending = payload
        else {
            lyricsTransformSaveProc.command = [root.stateScript, "lyrics-transform", "set"].concat(values)
            lyricsTransformSaveProc.running = true
        }
    }

    function applyLyricsMaterialSettings(mode, intensity, depthEnabled, depthIntensity, fogEnabled, fogIntensity, maskFeather, persist) {
        lyricsMaterialMode = normalizeLyricsMaterialMode(mode)
        lyricsMaterialIntensity = clampLyricsMaterialIntensity(intensity, lyricsMaterialIntensity)
        lyricsDepthEnabled = truthyEnabled(depthEnabled)
        lyricsDepthIntensity = clampLyricsMaterialIntensity(depthIntensity, lyricsDepthIntensity)
        lyricsFogEnabled = truthyEnabled(fogEnabled)
        lyricsFogIntensity = clampLyricsMaterialIntensity(fogIntensity, lyricsFogIntensity)
        lyricsMaskFeather = clampLyricsMaskFeather(maskFeather)
        if (persist !== false)
            saveLyricsMaterialSettings()
    }

    function resetLyricsMaterialSettings() {
        applyLyricsMaterialSettings("off", 0.55, false, 0.45, false, 0.35, 0, true)
    }

    function saveLyricsMaterialSettings() {
        const values = [
            normalizeLyricsMaterialMode(lyricsMaterialMode),
            lyricsMaterialIntensity.toFixed(2),
            lyricsDepthEnabled ? "on" : "off",
            lyricsDepthIntensity.toFixed(2),
            lyricsFogEnabled ? "on" : "off",
            lyricsFogIntensity.toFixed(2),
            lyricsMaskFeather.toFixed(2)
        ]
        const payload = values.join("|")
        if (lyricsMaterialSaveProc.running)
            lyricsMaterialSaveProc.pending = payload
        else {
            lyricsMaterialSaveProc.command = [root.stateScript, "lyrics-material", "set"].concat(values)
            lyricsMaterialSaveProc.running = true
        }
    }

    function applyLyricsMaskSettings(enabled, brushSize, data, persist) {
        lyricsMaskEnabled = truthyEnabled(enabled)
        lyricsMaskBrushSize = clampLyricsMaskBrushSize(brushSize)
        lyricsMaskData = sanitizedLyricsMaskPayload(data)
        try {
            lyricsMaskStrokes = JSON.parse(lyricsMaskData)
        } catch (e) {
            lyricsMaskStrokes = []
        }
        lyricsMaskHasStrokes = lyricsMaskStrokes.length > 0
        lyricsMaskRevision += 1
        if (persist !== false)
            saveLyricsMaskSettings()
    }

    function clearLyricsMask(persist) {
        applyLyricsMaskSettings(lyricsMaskEnabled, lyricsMaskBrushSize, "[]", persist)
    }

    function saveLyricsMaskSettings() {
        const values = [
            lyricsMaskEnabled ? "on" : "off",
            lyricsMaskBrushSize.toFixed(2),
            lyricsMaskData
        ]
        const payload = values.join("|")
        if (lyricsMaskSaveProc.running)
            lyricsMaskSaveProc.pending = payload
        else {
            lyricsMaskSaveProc.command = [root.stateScript, "lyrics-mask", "set"].concat(values)
            lyricsMaskSaveProc.running = true
        }
    }

    function applyLyricsBlocksSettings(pos3X, pos3Y, pos4X, pos4Y, styleData, persist) {
        lyricsThirdPositionX = clampLyricsPercent(pos3X, lyricsThirdPositionX)
        lyricsThirdPositionY = clampLyricsPercent(pos3Y, lyricsThirdPositionY)
        lyricsFourthPositionX = clampLyricsPercent(pos4X, lyricsFourthPositionX)
        lyricsFourthPositionY = clampLyricsPercent(pos4Y, lyricsFourthPositionY)
        lyricsBlockStyleData = sanitizedLyricsBlockStylePayload(styleData)
        try {
            lyricsBlockStyles = JSON.parse(lyricsBlockStyleData)
        } catch (e) {
            lyricsBlockStyles = []
        }
        lyricsBlockStyleRevision += 1
        if (persist !== false)
            saveLyricsBlocksSettings()
    }

    function applyLyricsBlockStyle(blockIndex, colorMode, manualColor, glowMode, glowIntensity, persist) {
        const index = Math.max(0, Math.min(3, Number(blockIndex) || 0))
        const styles = Array.isArray(lyricsBlockStyles) ? lyricsBlockStyles.slice(0, 4) : []
        while (styles.length <= index)
            styles.push({})
        styles[index] = {
            colorMode: normalizeLyricsBlockColorMode(colorMode),
            manualColor: normalizeLyricsManualColor(manualColor || lyricsManualColor),
            glowMode: normalizeLyricsBlockGlowMode(glowMode),
            glowIntensity: clampLyricsGlowIntensity(glowIntensity)
        }
        applyLyricsBlocksSettings(lyricsThirdPositionX, lyricsThirdPositionY, lyricsFourthPositionX, lyricsFourthPositionY, JSON.stringify(styles), persist)
    }

    function saveLyricsBlocksSettings() {
        const values = [
            lyricsThirdPositionX.toFixed(2),
            lyricsThirdPositionY.toFixed(2),
            lyricsFourthPositionX.toFixed(2),
            lyricsFourthPositionY.toFixed(2),
            lyricsBlockStyleData
        ]
        const payload = values.join("|")
        if (lyricsBlocksSaveProc.running)
            lyricsBlocksSaveProc.pending = payload
        else {
            lyricsBlocksSaveProc.command = [root.stateScript, "lyrics-blocks", "set"].concat(values)
            lyricsBlocksSaveProc.running = true
        }
    }

    function setScreenVisualizerEnabled(enabled, persist) {
        screenVisualizerEnabled = truthyEnabled(enabled)
        if (persist !== false)
            saveScreenVisualizerEnabled()
    }

    function saveScreenVisualizerEnabled() {
        const enabled = screenVisualizerEnabled ? "on" : "off"
        if (screenVisualizerSaveProc.running)
            screenVisualizerSaveProc.pending = enabled
        else {
            screenVisualizerSaveProc.command = [root.stateScript, "screen-visualizer", "set", enabled]
            screenVisualizerSaveProc.running = true
        }
    }







    function setTopBarFrameLineEnabled(enabled, persist) {
        topBarFrameLineEnabled = truthyEnabled(enabled)
        if (persist !== false)
            saveTopBarFrameLineEnabled()
    }

    function saveTopBarFrameLineEnabled() {
        const enabled = topBarFrameLineEnabled ? "on" : "off"
        if (topBarFrameLineSaveProc.running)
            topBarFrameLineSaveProc.pending = enabled
        else {
            topBarFrameLineSaveProc.command = [root.stateScript, "topbar-frame-line", "set", enabled]
            topBarFrameLineSaveProc.running = true
        }
    }

    function setTopBarOpacity(value, persist) {
        topBarOpacity = Math.max(0, Math.min(1, Number(value)))
        if (persist !== false)
            saveTopBarOpacity()
    }

    function saveTopBarOpacity() {
        const value = topBarOpacity.toFixed(2)
        if (topBarOpacitySaveProc.running)
            topBarOpacitySaveProc.pending = value
        else {
            topBarOpacitySaveProc.command = [root.stateScript, "topbar-opacity", "set", value]
            topBarOpacitySaveProc.running = true
        }
    }

    function setTopBarGradientEnabled(enabled, persist) {
        topBarGradientEnabled = truthyEnabled(enabled)
        if (persist !== false)
            saveTopBarGradientEnabled()
    }

    function saveTopBarGradientEnabled() {
        const enabled = topBarGradientEnabled ? "on" : "off"
        if (topBarGradientSaveProc.running)
            topBarGradientSaveProc.pending = enabled
        else {
            topBarGradientSaveProc.command = [root.stateScript, "topbar-gradient", "set", enabled]
            topBarGradientSaveProc.running = true
        }
    }

    function setTopBarGradientStrength(value, persist) {
        topBarGradientStrength = Math.max(0, Math.min(1, Number(value)))
        if (persist !== false)
            saveTopBarGradientStrength()
    }

    function saveTopBarGradientStrength() {
        const value = topBarGradientStrength.toFixed(2)
        if (topBarGradientStrengthSaveProc.running)
            topBarGradientStrengthSaveProc.pending = value
        else {
            topBarGradientStrengthSaveProc.command = [root.stateScript, "topbar-gradient-strength", "set", value]
            topBarGradientStrengthSaveProc.running = true
        }
    }

    function setTopBarBubbleGradientEnabled(enabled, persist) {
        topBarBubbleGradientEnabled = truthyEnabled(enabled)
        if (persist !== false)
            saveTopBarBubbleGradientEnabled()
    }

    function saveTopBarBubbleGradientEnabled() {
        const enabled = topBarBubbleGradientEnabled ? "on" : "off"
        if (topBarBubbleGradientSaveProc.running)
            topBarBubbleGradientSaveProc.pending = enabled
        else {
            topBarBubbleGradientSaveProc.command = [root.stateScript, "topbar-bubble-gradient", "set", enabled]
            topBarBubbleGradientSaveProc.running = true
        }
    }

    function setTopBarBubbleGradientStrength(value, persist) {
        topBarBubbleGradientStrength = Math.max(0, Math.min(1, Number(value)))
        if (persist !== false)
            saveTopBarBubbleGradientStrength()
    }

    function saveTopBarBubbleGradientStrength() {
        const value = topBarBubbleGradientStrength.toFixed(2)
        if (topBarBubbleGradientStrengthSaveProc.running)
            topBarBubbleGradientStrengthSaveProc.pending = value
        else {
            topBarBubbleGradientStrengthSaveProc.command = [root.stateScript, "topbar-bubble-gradient-strength", "set", value]
            topBarBubbleGradientStrengthSaveProc.running = true
        }
    }

    function setTopBarCategoryGap(value, persist) {
        topBarCategoryGap = Math.max(0, Math.min(248, Number(value)))
        if (persist !== false)
            saveTopBarCategoryGap()
    }

    function saveTopBarCategoryGap() {
        const value = topBarCategoryGap.toFixed(1)
        if (topBarCategoryGapSaveProc.running)
            topBarCategoryGapSaveProc.pending = value
        else {
            topBarCategoryGapSaveProc.command = [root.stateScript, "topbar-category-gap", "set", value]
            topBarCategoryGapSaveProc.running = true
        }
    }

    function resetTopBarAppearance() {
        setTopBarOpacity(0.18)
        setTopBarGradientEnabled(true)
        setTopBarGradientStrength(0.82)
        setTopBarBubbleGradientEnabled(true)
        setTopBarBubbleGradientStrength(0.82)
        setTopBarCategoryGap(8)
    }

    function setPopupAttachedToBar(enabled, persist) {
        popupAttachedToBar = truthyEnabled(enabled)
        if (persist !== false)
            savePopupAttachedToBar()
    }

    function savePopupAttachedToBar() {
        const enabled = popupAttachedToBar ? "on" : "off"
        if (popupAttachSaveProc.running)
            popupAttachSaveProc.pending = enabled
        else {
            popupAttachSaveProc.command = [root.stateScript, "popup-attach", "set", enabled]
            popupAttachSaveProc.running = true
        }
    }

    function setPopupBubblesSolid(enabled, persist) {
        popupBubblesSolid = truthyEnabled(enabled) || String(enabled) === "solid"
        if (persist !== false)
            savePopupBubblesSolid()
    }

    function savePopupBubblesSolid() {
        const mode = popupBubblesSolid ? "solid" : "matched"
        if (popupBubblesSaveProc.running)
            popupBubblesSaveProc.pending = mode
        else {
            popupBubblesSaveProc.command = [root.stateScript, "popup-bubbles", "set", mode]
            popupBubblesSaveProc.running = true
        }
    }

    function setBarLabelsVisible(enabled, persist) {
        barLabelsVisible = truthyEnabled(enabled)
        if (persist !== false)
            saveBarLabelsVisible()
    }

    function saveBarLabelsVisible() {
        const enabled = barLabelsVisible ? "on" : "off"
        if (barLabelsSaveProc.running)
            barLabelsSaveProc.pending = enabled
        else {
            barLabelsSaveProc.command = [root.stateScript, "bar-labels", "set", enabled]
            barLabelsSaveProc.running = true
        }
    }

    function setBarBlurEnabled(enabled, persist) {
        barBlurEnabled = truthyEnabled(enabled)
        if (persist !== false)
            saveBarBlurEnabled()
    }

    function saveBarBlurEnabled() {
        const enabled = barBlurEnabled ? "on" : "off"
        if (barBlurSaveProc.running)
            barBlurSaveProc.pending = enabled
        else {
            barBlurSaveProc.command = [root.stateScript, "bar-blur", "set", enabled]
            barBlurSaveProc.running = true
        }
    }

    function setFrameBlurEnabled(enabled, persist) {
        frameBlurEnabled = truthyEnabled(enabled)
        if (persist !== false)
            saveFrameBlurEnabled()
    }

    function applyBarAppearance(iconSize, iconOpacity, iconSpacing, autoHide, cornerRadius, persist) {
        barIconSize = Math.max(32, Math.min(56, Number(iconSize) || 48))
        barIconOpacity = Math.max(0.30, Math.min(1.00, Number(iconOpacity) || 0.80))
        barIconSpacing = Math.max(8, Math.min(24, Number(iconSpacing) || 16))
        barAutoHideEnabled = truthyEnabled(autoHide)
        barCornerRadius = Math.max(0, Math.min(30, Number(cornerRadius) || 16))
        if (persist !== false)
            saveBarAppearance()
    }

    function saveBarAppearance() {
        const values = [
            barIconSize.toFixed(2),
            barIconOpacity.toFixed(2),
            barIconSpacing.toFixed(2),
            barAutoHideEnabled ? "on" : "off",
            barCornerRadius.toFixed(2)
        ]
        const payload = values.join("|")
        if (barAppearanceSaveProc.running)
            barAppearanceSaveProc.pending = payload
        else {
            barAppearanceSaveProc.command = [root.stateScript, "bar-appearance", "set"].concat(values)
            barAppearanceSaveProc.running = true
        }
    }

    function resetBarAppearance() {
        applyBarAppearance(48, 0.80, 16, false, 16, true)
    }

    function setBarWidth(value, persist) {
        const next = Math.max(88, Math.min(136, Number(value) || 112))
        barWidth = next
        if (persist !== false)
            saveBarWidth()
    }

    function saveBarWidth() {
        const value = Number(barWidth).toFixed(2)
        if (barWidthSaveProc.running)
            barWidthSaveProc.pending = value
        else {
            barWidthSaveProc.command = [root.stateScript, "bar-width", "set", value]
            barWidthSaveProc.running = true
        }
    }

    function resetBarWidth() {
        setBarWidth(112, true)
    }

    function saveFrameBlurEnabled() {
        const enabled = frameBlurEnabled ? "on" : "off"
        if (frameBlurSaveProc.running)
            frameBlurSaveProc.pending = enabled
        else {
            frameBlurSaveProc.command = [root.stateScript, "frame-blur", "set", enabled]
            frameBlurSaveProc.running = true
        }
    }

    function setProfileImagePath(path, persist) {
        profileImagePath = String(path || "").trim()
        if (persist !== false)
            saveProfileImagePath()
    }

    function saveProfileImagePath() {
        if (profileImageSaveProc.running)
            profileImageSaveProc.pending = profileImagePath
        else {
            profileImageSaveProc.command = [root.stateScript, "profile-image", "set", profileImagePath]
            profileImageSaveProc.running = true
        }
    }

    function applyLayout(position, frameEnabled, persist) {
        const nextPosition = String(position || "left") === "right" ? "right" : "left"
        const nextFrameEnabled = frameEnabled !== false && String(frameEnabled) !== "0" && String(frameEnabled) !== "false"
        barPosition = nextPosition
        desktopFrameEnabled = nextFrameEnabled
        if (persist !== false)
            saveLayout()
    }

    function setBarPosition(position, persist) {
        applyLayout(position, desktopFrameEnabled, persist)
    }

    function setDesktopFrameEnabled(enabled, persist) {
        applyLayout(barPosition, enabled, persist)
    }

    function normalizeWallpaperSelectorPosition(position) {
        return String(position || "center").toLowerCase() === "bottom" ? "bottom" : "center"
    }

    function setWallpaperSelectorPosition(position, persist) {
        wallpaperSelectorPosition = normalizeWallpaperSelectorPosition(position)
        if (persist !== false)
            saveWallpaperSelectorPosition()
    }

    function saveWallpaperSelectorPosition() {
        const position = normalizeWallpaperSelectorPosition(wallpaperSelectorPosition)
        if (wallpaperSelectorPositionSaveProc.running)
            wallpaperSelectorPositionSaveProc.pending = position
        else {
            wallpaperSelectorPositionSaveProc.command = [root.stateScript, "wallpaper-selector-position", "set", position]
            wallpaperSelectorPositionSaveProc.running = true
        }
    }

    function normalizeControlCenterPosition(position) {
        return String(position || "bottom").toLowerCase() === "right" ? "right" : "bottom"
    }

    function setControlCenterPosition(position, persist) {
        controlCenterPosition = normalizeControlCenterPosition(position)
        if (persist !== false)
            saveControlCenterPosition()
    }

    function saveControlCenterPosition() {
        const position = normalizeControlCenterPosition(controlCenterPosition)
        if (controlCenterPositionSaveProc.running)
            controlCenterPositionSaveProc.pending = position
        else {
            controlCenterPositionSaveProc.command = [root.stateScript, "control-center-position", "set", position]
            controlCenterPositionSaveProc.running = true
        }
    }

    function setWallpaperSelectorBlur(value, persist) {
        wallpaperSelectorBlur = Math.max(0, Math.min(1, Number(value)))
        if (persist !== false)
            saveWallpaperSelectorBlur()
    }

    function saveWallpaperSelectorBlur() {
        const value = wallpaperSelectorBlur.toFixed(2)
        if (wallpaperSelectorBlurSaveProc.running)
            wallpaperSelectorBlurSaveProc.pending = value
        else {
            wallpaperSelectorBlurSaveProc.command = [root.stateScript, "wallpaper-selector-blur", "set", value]
            wallpaperSelectorBlurSaveProc.running = true
        }
    }

    function saveLayout() {
        const enabled = desktopFrameEnabled ? "1" : "0"
        if (layoutSaveProc.running)
            layoutSaveProc.pending = barPosition + "|" + enabled
        else {
            layoutSaveProc.command = [root.stateScript, "layout", "set", barPosition, enabled]
            layoutSaveProc.running = true
        }
    }

    function normalizeLanguage(value) {
        const next = String(value || "pt-BR")
        if (next === "ja" || next === "jp" || next === "japanese")
            return "ja"
        if (next === "en" || next === "english")
            return "en"
        if (next === "pt" || next === "pt-BR" || next === "pt_BR" || next === "br")
            return "pt-BR"
        return "pt-BR"
    }

    function normalizeFontFamily(value) {
        const next = String(value || "noto").toLowerCase()
        if (next === "adwaita" || next === "adwaita-sans" || next === "adwaita_sans")
            return "adwaita"
        if (next === "cantarell")
            return "cantarell"
        if (next === "dejavu" || next === "dejavu-sans" || next === "dejavu_sans")
            return "dejavu"
        if (next === "liberation" || next === "liberation-sans" || next === "liberation_sans")
            return "liberation"
        if (next === "fantasque" || next === "fantasque-sans" || next === "fantasquesansm")
            return "fantasque"
        return "noto"
    }

    function fontFamilyForId(value) {
        const id = normalizeFontFamily(value)
        if (id === "adwaita")
            return "Adwaita Sans"
        if (id === "cantarell")
            return "Cantarell"
        if (id === "dejavu")
            return "DejaVu Sans"
        if (id === "liberation")
            return "Liberation Sans"
        if (id === "fantasque")
            return "FantasqueSansM Nerd Font"
        return "Noto Sans"
    }

    function setLanguage(value, persist) {
        language = normalizeLanguage(value)
        if (persist !== false)
            saveLanguage()
    }

    function saveLanguage() {
        if (languageSaveProc.running)
            languageSaveProc.pending = language
        else {
            languageSaveProc.command = [root.stateScript, "language", "set", language]
            languageSaveProc.running = true
        }
    }

    function setFontFamily(value, persist) {
        fontFamilyId = normalizeFontFamily(value)
        if (persist !== false)
            saveFontFamily()
    }

    function saveFontFamily() {
        const fontId = normalizeFontFamily(fontFamilyId)
        if (fontSaveProc.running)
            fontSaveProc.pending = fontId
        else {
            fontSaveProc.command = [root.stateScript, "font", "set", fontId]
            fontSaveProc.running = true
        }
    }

    function applyDumpRecord(key, value) {
        const line = String(value || "").trim()

        if (key === "theme") {
            if (line.length > 0)
                root.applyTheme(line, false)
            return
        }

        if (key === "opacity") {
            if (line.length <= 0 || line === "auto") {
                root.opacityOverrideActive = false
                root.syncOpacityValuesFromSurfaces()
                return
            }

            const opacityParts = line.split("|")
            if (opacityParts.length >= 3)
                root.applyOpacity(opacityParts[0], opacityParts[1], opacityParts[2], false)
            return
        }

        if (key === "barOpacity") {
            if (line.length <= 0 || line === "auto") {
                root.barOpacityOverrideActive = false
                root.syncBarOpacityFromSurface()
                return
            }

            root.applyBarOpacity(line, false)
            return
        }

        if (key === "glow") {
            if (line.length <= 0 || line === "auto") {
                root.glowOverrideActive = false
                root.syncGlowValuesFromSurfaces()
                return
            }

            const glowParts = line.split("|")
            if (glowParts.length >= 3)
                root.applyGlow(glowParts[0], glowParts[1], glowParts[2], glowParts.length >= 4 ? glowParts[3] : glowParts[0], glowParts.length >= 5 ? glowParts[4] : root.textGlowLevel, false)
            return
        }

        if (key === "border") {
            if (line.length <= 0 || line === "auto") {
                root.borderOverrideActive = false
                root.syncBorderValuesFromSurfaces()
                return
            }

            const borderParts = line.split("|")
            root.applyBorderAccent(borderParts[0] !== "manual", borderParts.length >= 2 ? borderParts[1] : root.borderHue, false)
            return
        }

        if (key === "layout") {
            if (line.length <= 0)
                return

            const layoutParts = line.split("|")
            root.applyLayout(layoutParts[0], layoutParts.length >= 2 ? layoutParts[1] : "1", false)
            return
        }

        if (key === "wallpaperSelectorPosition") {
            root.setWallpaperSelectorPosition(line, false)
            return
        }

        if (key === "wallpaperSelectorBlur") {
            root.setWallpaperSelectorBlur(line, false)
            return
        }

        if (key === "controlCenterPosition") {
            root.setControlCenterPosition(line, false)
            return
        }

        if (key === "language") {
            if (line.length > 0)
                root.setLanguage(line, false)
            return
        }

        if (key === "font") {
            if (line.length > 0)
                root.setFontFamily(line, false)
            return
        }

        if (key === "visualizer" && line.length > 0 && line !== "auto")
            root.setVisualizerStrength(line, false)

        if (key === "visualizerMode" && line.length > 0)
            root.setVisualizerMode(line, false)

        if (key === "visualizerPixelSize" && line.length > 0)
            root.setVisualizerPixelSize(line, false)

        if (key === "visualizerGradient")
            root.setVisualizerGradientEnabled(line !== "off" && line !== "0" && line !== "false", false)

        if (key === "screenVisualizer")
            root.setScreenVisualizerEnabled(line !== "off" && line !== "0" && line !== "false", false)

        if (key === "lyrics") {
            const parts = line.split("|")
            const hasLyricsGlow = parts.length > 21 && parts[19] === "glow"
            root.applyLyricsSettings(
                parts.length > 0 ? parts[0] : "off",
                parts.length > 1 ? parts[1] : 18,
                parts.length > 2 ? parts[2] : 44,
                parts.length > 3 ? parts[3] : "pywal",
                parts.length > 4 ? parts[4] : "#f5f7ff",
                parts.length > 5 ? parts[5] : 86,
                parts.length > 6 ? parts[6] : 0.86,
                parts.length > 7 ? parts[7] : 8,
                parts.length > 8 ? parts[8] : "on",
                parts.length > 9 ? parts[9] : "on",
                parts.length > 10 ? parts[10] : "vertical",
                parts.length > 11 ? parts[11] : "instant",
                parts.length > 12 ? parts[12] : "on",
                parts.length > 13 ? parts[13] : "progressive",
                parts.length > 14 ? parts[14] : 74,
                parts.length > 15 ? parts[15] : 18,
                parts.length > 16 ? parts[16] : 460,
                parts.length > 17 ? parts[17] : "on",
                parts.length > 18 ? parts[18] : 5,
                hasLyricsGlow ? parts[20] : "on",
                hasLyricsGlow ? parts[21] : 0.45,
                false
            )
        }

        if (key === "lyricsCinematic")
            root.setLyricsCinematicEnabled(line !== "off" && line !== "0" && line !== "false", false)

        if (key === "lyricsMask") {
            const parts = line.split("|")
            root.applyLyricsMaskSettings(
                parts.length > 0 ? parts[0] : "off",
                parts.length > 1 ? parts[1] : 56,
                parts.length > 2 ? parts.slice(2).join("|") : "[]",
                false
            )
        }

        if (key === "lyricsBlocks") {
            const parts = line.split("|")
            root.applyLyricsBlocksSettings(
                parts.length > 0 ? parts[0] : 8,
                parts.length > 1 ? parts[1] : 58,
                parts.length > 2 ? parts[2] : 72,
                parts.length > 3 ? parts[3] : 58,
                parts.length > 4 ? parts.slice(4).join("|") : "[]",
                false
            )
        }

        if (key === "lyricsTransform") {
            const parts = line.split("|")
            root.applyLyricsTransformSettings(
                parts.length > 0 ? parts[0] : 1,
                parts.length > 1 ? parts[1] : 0,
                parts.length > 2 ? parts[2] : 0,
                parts.length > 3 ? parts[3] : 0,
                false
            )
        }

        if (key === "lyricsMaterial") {
            const parts = line.split("|")
            root.applyLyricsMaterialSettings(
                parts.length > 0 ? parts[0] : "off",
                parts.length > 1 ? parts[1] : 0.55,
                parts.length > 2 ? parts[2] : "off",
                parts.length > 3 ? parts[3] : 0.45,
                parts.length > 4 ? parts[4] : "off",
                parts.length > 5 ? parts[5] : 0.35,
                parts.length > 6 ? parts[6] : 0,
                false
            )
        }

        if (key === "topBarFrameLine")
            root.setTopBarFrameLineEnabled(line !== "off" && line !== "0" && line !== "false", false)

        if (key === "topBarOpacity")
            root.setTopBarOpacity(line, false)

        if (key === "topBarGradient")
            root.setTopBarGradientEnabled(line !== "off" && line !== "0" && line !== "false", false)

        if (key === "topBarGradientStrength")
            root.setTopBarGradientStrength(line, false)

        if (key === "topBarBubbleGradient")
            root.setTopBarBubbleGradientEnabled(line !== "off" && line !== "0" && line !== "false", false)

        if (key === "topBarBubbleGradientStrength")
            root.setTopBarBubbleGradientStrength(line, false)

        if (key === "topBarCategoryGap")
            root.setTopBarCategoryGap(line, false)

        if (key === "popupAttach")
            root.setPopupAttachedToBar(line === "on" || line === "1" || line === "true", false)

        if (key === "popupBubbles")
            root.setPopupBubblesSolid(line === "solid" || line === "on" || line === "1" || line === "true", false)

        if (key === "barLabels")
            root.setBarLabelsVisible(line !== "off" && line !== "0" && line !== "false", false)

        if (key === "barBlur")
            root.setBarBlurEnabled(line !== "off" && line !== "0" && line !== "false", false)

        if (key === "frameBlur")
            root.setFrameBlurEnabled(line !== "off" && line !== "0" && line !== "false", false)

        if (key === "barAppearance") {
            const parts = line.split("|")
            root.applyBarAppearance(
                parts.length > 0 ? parts[0] : 48,
                parts.length > 1 ? parts[1] : 0.80,
                parts.length > 2 ? parts[2] : 16,
                parts.length > 3 ? parts[3] : "off",
                parts.length > 4 ? parts[4] : 16,
                false
            )
        }

        if (key === "barWidth")
            root.setBarWidth(line, false)

        if (key === "profileImage")
            root.setProfileImagePath(value, false)
    }

    Component.onCompleted: {
        setDefaultPalette()
        if (!loadAllProc.running)
            loadAllProc.running = true
    }

    property Process loadAllProc: Process {
        running: false
        command: [root.stateScript, "dump"]

        stdout: SplitParser {
            onRead: function(data) {
                const raw = String(data || "").trim()
                if (raw.length <= 0)
                    return

                const sep = raw.indexOf("|")
                if (sep < 0)
                    return

                root.applyDumpRecord(raw.slice(0, sep), raw.slice(sep + 1))
            }
        }

        onExited: running = false
    }

    property Process loadProc: Process {
        running: false
        command: [root.stateScript, "get"]

        stdout: SplitParser {
            onRead: function(data) {
                const id = String(data || "").trim()
                if (id.length > 0)
                    root.applyTheme(id, false)
            }
        }

        onExited: running = false
    }

    property Process saveProc: Process {
        property string pendingTheme: ""

        running: false
        command: [root.stateScript, "set", "default"]
        onExited: {
            running = false
            if (pendingTheme.length > 0) {
                const next = pendingTheme
                pendingTheme = ""
                command = [root.stateScript, "set", next]
                running = true
            }
        }
    }

    property Process opacityLoadProc: Process {
        running: false
        command: [root.stateScript, "opacity", "get"]

        stdout: SplitParser {
            onRead: function(data) {
                const line = String(data || "").trim()
                if (line.length <= 0 || line === "auto") {
                    root.opacityOverrideActive = false
                    root.syncOpacityValuesFromSurfaces()
                    return
                }

                const parts = line.split("|")
                if (parts.length >= 3)
                    root.applyOpacity(parts[0], parts[1], parts[2], false)
            }
        }

        onExited: running = false
    }

    property Process opacitySaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "opacity", "set", "0.88", "0.90", "0.76"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const parts = pending.split("|")
                pending = ""
                command = [root.stateScript, "opacity", "set", parts[0], parts[1], parts[2]]
                running = true
            }
        }
    }

    property Process opacityResetProc: Process {
        running: false
        command: [root.stateScript, "opacity", "reset"]
        onExited: running = false
    }

    property Process barOpacitySaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "bar-opacity", "set", "0.88"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "bar-opacity", "set", next]
                running = true
            }
        }
    }

    property Process glowLoadProc: Process {
        running: false
        command: [root.stateScript, "glow", "get"]

        stdout: SplitParser {
            onRead: function(data) {
                const line = String(data || "").trim()
                if (line.length <= 0 || line === "auto") {
                    root.glowOverrideActive = false
                    root.syncGlowValuesFromSurfaces()
                    return
                }

                const parts = line.split("|")
                if (parts.length >= 3)
                    root.applyGlow(parts[0], parts[1], parts[2], parts.length >= 4 ? parts[3] : parts[0], parts.length >= 5 ? parts[4] : root.textGlowLevel, false)
            }
        }

        onExited: running = false
    }

    property Process glowSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "glow", "set", "0.50", "0.50", "0.50", "0.50", "0.78"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const parts = pending.split("|")
                pending = ""
                command = [root.stateScript, "glow", "set", parts[0], parts[1], parts[2], parts[3], parts.length >= 5 ? parts[4] : root.textGlowLevel]
                running = true
            }
        }
    }

    property Process glowResetProc: Process {
        running: false
        command: [root.stateScript, "glow", "reset"]
        onExited: running = false
    }

    property Process borderLoadProc: Process {
        running: false
        command: [root.stateScript, "border", "get"]

        stdout: SplitParser {
            onRead: function(data) {
                const line = String(data || "").trim()
                if (line.length <= 0 || line === "auto") {
                    root.borderOverrideActive = false
                    root.syncBorderValuesFromSurfaces()
                    return
                }

                const parts = line.split("|")
                root.applyBorderAccent(parts[0] !== "manual", parts.length >= 2 ? parts[1] : root.borderHue, false)
            }
        }

        onExited: running = false
    }

    property Process borderSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "border", "set", "adapt", "0.55"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const parts = pending.split("|")
                pending = ""
                command = [root.stateScript, "border", "set", parts[0], parts[1]]
                running = true
            }
        }
    }

    property Process borderResetProc: Process {
        running: false
        command: [root.stateScript, "border", "reset"]
        onExited: running = false
    }

    property Process visualizerLoadProc: Process {
        running: false
        command: [root.stateScript, "visualizer", "get"]

        stdout: SplitParser {
            onRead: function(data) {
                const line = String(data || "").trim()
                if (line.length > 0 && line !== "auto")
                    root.setVisualizerStrength(line, false)
            }
        }

        onExited: running = false
    }

    property Process visualizerSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "visualizer", "set", "0.46"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "visualizer", "set", next]
                running = true
            }
        }
    }

    property Process visualizerResetProc: Process {
        running: false
        command: [root.stateScript, "visualizer", "reset"]
        onExited: running = false
    }

    property Process visualizerModeSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "visualizer-mode", "set", "wave"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "visualizer-mode", "set", next]
                running = true
            }
        }
    }

    property Process visualizerPixelSizeSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "visualizer-pixel-size", "set", "7.00"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "visualizer-pixel-size", "set", next]
                running = true
            }
        }
    }

    property Process visualizerGradientSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "visualizer-gradient", "set", "on"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "visualizer-gradient", "set", next]
                running = true
            }
        }
    }

    property Process screenVisualizerSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "screen-visualizer", "set", "on"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "screen-visualizer", "set", next]
                running = true
            }
        }
    }

    property Process lyricsSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "lyrics", "set", "off", "18.00", "44.00", "pywal", "#f5f7ff", "86.00", "0.86", "8.00", "on", "on", "vertical", "instant", "on", "progressive", "74.00", "18.00", "460.00", "on", "5.00", "glow", "on", "0.45"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const parts = pending.split("|")
                pending = ""
                command = [root.stateScript, "lyrics", "set"].concat(parts)
                running = true
            }
        }
    }

    property Process lyricsCinematicSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "lyrics-cinematic", "set", "on"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "lyrics-cinematic", "set", next]
                running = true
            }
        }
    }

    property Process lyricsTransformSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "lyrics-transform", "set", "1.00", "0.00", "0.00", "0.00"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const parts = pending.split("|")
                pending = ""
                command = [root.stateScript, "lyrics-transform", "set"].concat(parts)
                running = true
            }
        }
    }

    property Process lyricsMaterialSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "lyrics-material", "set", "off", "0.55", "off", "0.45", "off", "0.35", "0.00"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const parts = pending.split("|")
                pending = ""
                command = [root.stateScript, "lyrics-material", "set"].concat(parts)
                running = true
            }
        }
    }

    property Process lyricsMaskSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "lyrics-mask", "set", "off", "56.00", "[]"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const parts = pending.split("|")
                pending = ""
                command = [root.stateScript, "lyrics-mask", "set"].concat(parts)
                running = true
            }
        }
    }

    property Process lyricsBlocksSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "lyrics-blocks", "set", "8.00", "58.00", "72.00", "58.00", "[]"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const parts = pending.split("|")
                pending = ""
                command = [root.stateScript, "lyrics-blocks", "set"].concat(parts)
                running = true
            }
        }
    }

    property Process topBarSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "topbar", "set", "off"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "topbar", "set", next]
                running = true
            }
        }
    }

    property Process topBarFrameLineSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "topbar-frame-line", "set", "on"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "topbar-frame-line", "set", next]
                running = true
            }
        }
    }

    property Process topBarOpacitySaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "topbar-opacity", "set", "0.18"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "topbar-opacity", "set", next]
                running = true
            }
        }
    }

    property Process topBarGradientSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "topbar-gradient", "set", "on"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "topbar-gradient", "set", next]
                running = true
            }
        }
    }

    property Process topBarGradientStrengthSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "topbar-gradient-strength", "set", "0.82"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "topbar-gradient-strength", "set", next]
                running = true
            }
        }
    }

    property Process topBarBubbleGradientSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "topbar-bubble-gradient", "set", "on"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "topbar-bubble-gradient", "set", next]
                running = true
            }
        }
    }

    property Process topBarBubbleGradientStrengthSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "topbar-bubble-gradient-strength", "set", "0.82"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "topbar-bubble-gradient-strength", "set", next]
                running = true
            }
        }
    }

    property Process topBarCategoryGapSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "topbar-category-gap", "set", "8.0"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "topbar-category-gap", "set", next]
                running = true
            }
        }
    }

    property Process popupAttachSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "popup-attach", "set", "on"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "popup-attach", "set", next]
                running = true
            }
        }
    }

    property Process popupBubblesSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "popup-bubbles", "set", "matched"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "popup-bubbles", "set", next]
                running = true
            }
        }
    }

    property Process barLabelsSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "bar-labels", "set", "on"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "bar-labels", "set", next]
                running = true
            }
        }
    }

    property Process barBlurSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "bar-blur", "set", "on"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "bar-blur", "set", next]
                running = true
            }
        }
    }

    property Process frameBlurSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "frame-blur", "set", "on"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "frame-blur", "set", next]
                running = true
            }
        }
    }

    property Process barAppearanceSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "bar-appearance", "set", "48.00", "0.80", "16.00", "off", "16.00"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const parts = pending.split("|")
                pending = ""
                command = [root.stateScript, "bar-appearance", "set"].concat(parts)
                running = true
            }
        }
    }

    property Process barWidthSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "bar-width", "set", "112.00"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "bar-width", "set", next]
                running = true
            }
        }
    }

    property Process profileImageSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "profile-image", "set", ""]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "profile-image", "set", next]
                running = true
            }
        }
    }

    property Process layoutLoadProc: Process {
        running: false
        command: [root.stateScript, "layout", "get"]

        stdout: SplitParser {
            onRead: function(data) {
                const line = String(data || "").trim()
                if (line.length <= 0)
                    return

                const parts = line.split("|")
                root.applyLayout(parts[0], parts.length >= 2 ? parts[1] : "1", false)
            }
        }

        onExited: running = false
    }

    property Process layoutSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "layout", "set", "left", "1"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const parts = pending.split("|")
                pending = ""
                command = [root.stateScript, "layout", "set", parts[0], parts.length >= 2 ? parts[1] : "1"]
                running = true
            }
        }
    }

    property Process wallpaperSelectorPositionSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "wallpaper-selector-position", "set", "center"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "wallpaper-selector-position", "set", next]
                running = true
            }
        }
    }

    property Process controlCenterPositionSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "control-center-position", "set", "bottom"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "control-center-position", "set", next]
                running = true
            }
        }
    }

    property Process wallpaperSelectorBlurSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "wallpaper-selector-blur", "set", "0.55"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "wallpaper-selector-blur", "set", next]
                running = true
            }
        }
    }

    property Process languageLoadProc: Process {
        running: false
        command: [root.stateScript, "language", "get"]

        stdout: SplitParser {
            onRead: function(data) {
                const line = String(data || "").trim()
                if (line.length > 0)
                    root.setLanguage(line, false)
            }
        }

        onExited: running = false
    }

    property Process languageSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "language", "set", "ja"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "language", "set", next]
                running = true
            }
        }
    }

    property Process fontSaveProc: Process {
        property string pending: ""

        running: false
        command: [root.stateScript, "font", "set", "noto"]
        onExited: {
            running = false
            if (pending.length > 0) {
                const next = pending
                pending = ""
                command = [root.stateScript, "font", "set", next]
                running = true
            }
        }
    }

    property Process pywalProbe: Process {
        running: false
        command: [root.pywalScript, "--status"]

        stdout: SplitParser {
            onRead: function(data) {
                const status = String(data || "").trim()
                root.pywalAvailable = status !== "missing"
                if (root.themeId === "pywal16")
                    root.themeNotice = root.pywalAvailable
                        ? "pywal16 disponivel."
                        : "pywal16 ainda nao gerado; fallback Velora Default ativo."
            }
        }

        onExited: running = false
    }

    property Timer stagedThemeTimer: Timer {
        interval: root.stagedPaletteStepDelay
        repeat: false
        onTriggered: root.applyNextStagedThemeStep()
    }

    property Process pywalLoadProc: Process {
        property bool gotTheme: false
        property bool pendingReload: false
        property bool animateTheme: false

        running: false
        command: [root.pywalScript, "--emit-or-generate"]
        onStarted: gotTheme = false

        stdout: SplitParser {
            onRead: function(data) {
                const line = String(data || "").trim()
                if (line.length <= 0)
                    return

                try {
                    const parsed = JSON.parse(line)
                    pywalLoadProc.gotTheme = true
                    if (root.themeId !== "pywal16")
                        return
                    root.pywalAvailable = !parsed.fallback
                    root.applyThemeData(parsed, "pywal16", parsed.fallback
                        ? "pywal16 falhou; usando Velora Default como fallback."
                        : "pywal16 aplicado: " + (parsed.themeMode || "balanced"),
                        pywalLoadProc.animateTheme)
                } catch (e) {
                    if (root.themeId === "pywal16") {
                        root.setDefaultPalette()
                        root.themeNotice = "pywal16 invalido; fallback Velora Default ativo."
                    }
                }
            }
        }

        onExited: {
            running = false
            if (pendingReload && root.themeId === "pywal16") {
                pendingReload = false
                root.loadPywal16(animateTheme)
                return
            }
            pendingReload = false
            if (!gotTheme && root.themeId === "pywal16") {
                root.setDefaultPalette()
                root.themeNotice = "pywal16 falhou; Velora Default preservado."
            }
        }
    }
}
