import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import "services/VeloraSettingsTranslations.js" as VeloraSettingsTranslations

Item {
    id: root

    property alias surfaceItem: panelSurface
    property var theme: null
    property bool externalSurface: false
    property string attachSide: "left"
    readonly property int cornerRadius: 24
    readonly property bool pywalStyle: theme && theme.themeId === "pywal16"
    readonly property bool neon: pywalStyle && theme.themeMode === "dark"
    readonly property string uiFont: theme ? theme.uiFont : "Noto Sans CJK JP"
    readonly property string monoFont: theme ? theme.monoFont : "JetBrainsMono Nerd Font"
    readonly property color settingsLightText: theme ? theme.textPrimary : Qt.rgba(0.27, 0.21, 0.39, 0.94)
    readonly property color settingsLightTextSoft: theme ? theme.textSecondary : Qt.rgba(0.39, 0.32, 0.52, 0.70)
    readonly property color settingsLightAccent: accentPrimary()
    readonly property color settingsLightLine: theme ? alpha(theme.borderSoft, theme.themeMode === "dark" ? 0.34 : 0.42) : Qt.rgba(0.42, 0.31, 0.53, 0.10)
    readonly property color settingsLightPanel: theme ? alpha(theme.surfaceCard, theme.themeMode === "dark" ? 0.56 : 0.62) : Qt.rgba(1, 1, 1, 0.54)
    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string wallpaperDir: homeDir + "/Pictures/Wallpapers"
    readonly property string stateScript: Quickshell.shellDir + "/scripts/velora-theme-state"
    readonly property string applyScript: Quickshell.shellDir + "/scripts/velora-wallpaper-apply"
    readonly property string scanScript: Quickshell.shellDir + "/scripts/velora-wallpaper-scan"
    readonly property string terminalThemeScript: Quickshell.shellDir + "/scripts/velora-terminal-theme.py"
    readonly property string zenLiveScript: Quickshell.shellDir + "/scripts/velora-zen-live-apply"
    readonly property string zenThemeScript: Quickshell.shellDir + "/scripts/velora-zen-theme.py"
    readonly property string codeTransparencyScript: Quickshell.shellDir + "/scripts/velora-code-transparency"
    readonly property string velyricsStateScript: Quickshell.shellDir + "/scripts/velora-velyrics-state"
    readonly property string worldClockStateScript: Quickshell.shellDir + "/scripts/velora-world-clock-state"
    readonly property var navItems: [
        { key: "general", icon: "home" },
        { key: "bar", icon: "volume" },
        { key: "appearance", icon: "palette" },
        { key: "integrations", icon: "puzzle" }
    ]
    readonly property var fallbackLanguageOptions: [
        { id: "ja", label: "日本語", shortLabel: "JP" },
        { id: "en", label: "English", shortLabel: "EN" },
        { id: "pt-BR", label: "Português Brasil", shortLabel: "BR" }
    ]
    readonly property var fallbackFontOptions: [
        { id: "noto", label: "Noto Sans", family: "Noto Sans" },
        { id: "adwaita", label: "Adwaita Sans", family: "Adwaita Sans" },
        { id: "cantarell", label: "Cantarell", family: "Cantarell" },
        { id: "dejavu", label: "DejaVu Sans", family: "DejaVu Sans" },
        { id: "liberation", label: "Liberation Sans", family: "Liberation Sans" },
        { id: "fantasque", label: "FantasqueSansM", family: "FantasqueSansM Nerd Font" }
    ]
    readonly property var fallbackThemes: [
        { id: "default", title: "Light", subtitle: "Velora Default", mode: "light", preview: "default" },
        { id: "dark", title: "Dark", subtitle: "Manual", mode: "dark", preview: "dark" },
        { id: "pink", title: "Pink", subtitle: "Soft rose", mode: "light", preview: "pink" },
        { id: "lavender", title: "Lavender", subtitle: "Lilac glass", mode: "light", preview: "lavender" },
        { id: "pywal16", title: "pywal16", subtitle: "auto", mode: "dynamic", preview: "pywal16" }
    ]
    readonly property var fallbackWallpapers: []
    readonly property var worldClockOptions: [
        { label: "São Paulo", zone: "America/Sao_Paulo" },
        { label: "New York", zone: "America/New_York" },
        { label: "Los Angeles", zone: "America/Los_Angeles" },
        { label: "London", zone: "Europe/London" },
        { label: "Paris", zone: "Europe/Paris" },
        { label: "Berlin", zone: "Europe/Berlin" },
        { label: "Dubai", zone: "Asia/Dubai" },
        { label: "Tokyo", zone: "Asia/Tokyo" },
        { label: "Seoul", zone: "Asia/Seoul" },
        { label: "Sydney", zone: "Australia/Sydney" }
    ]

    property int activeNav: 0
    property int selectedIndex: 0
    property var allWallpapers: fallbackWallpapers
    property var wallpapers: fallbackWallpapers
    property string noticeText: ""
    property string powerProfile: "unknown"
    property bool zenAutoRestart: true
    property bool webThemeBalance: true
    property real codeOpacity: 0.96
    property string wallpaperTransition: "fade"
    property real wallpaperTransitionDuration: 0.42
    property real wallpaperStaticDelay: 0.04
    property string wallpaperLiveTransition: "shader"
    property bool terminalStrongColors: false
    property bool terminalThemeReloadPending: false
    property string velyricsMode: "line"
    property int velyricsWordsPerTerminal: 4
    property real velyricsFontScale: 1.0
    property string velyricsFontFamily: "Pixelon"
    property var velyricsFontFamilies: ["Pixelon"]
    property string velyricsFontSearch: ""
    property real velyricsSyncOffsetMs: 500.0
    property var worldClockItems: [worldClockOptions[1], worldClockOptions[7]]
    property bool open: visible
    property bool loadedOnce: false
    property bool scanComplete: false
    readonly property bool contentActive: visible || open || revealProgress > 0.01
    property real revealProgress: 0
    readonly property int motionPanelIn: theme ? theme.motionPanelIn : 220
    readonly property int motionPanelOut: theme ? theme.motionPanelOut : 140
    readonly property int motionHover: theme ? theme.motionHover : 120
    readonly property int motionPanelOffset: theme ? theme.motionPanelOffset : 28
    readonly property int motionEaseEnter: theme ? theme.motionEaseEnter : Easing.OutCubic
    readonly property int motionEaseExit: theme ? theme.motionEaseExit : Easing.InCubic
    readonly property int motionEaseHover: theme ? theme.motionEaseHover : Easing.OutCubic

    signal closeRequested()
    signal lyricsMaskEditorRequested()

    opacity: revealProgress
    scale: 0.992 + revealProgress * 0.008
    transformOrigin: attachSide === "right" ? Item.Right : Item.Left
    focus: visible
    activeFocusOnTab: true

    transform: Translate {
        x: Math.round((1 - root.revealProgress) * (root.attachSide === "right" ? root.motionPanelOffset : -root.motionPanelOffset))
        y: Math.round((1 - root.revealProgress) * 6)
    }

    onOpenChanged: {
        animateReveal()
        if (open)
            ensureLoaded()
    }
    onVisibleChanged: {
        if (visible && open && revealProgress <= 0.001 && !revealAnimation.running)
            animateReveal()
        if (visible && open)
            ensureLoaded()
    }

    function animateReveal() {
        revealAnimation.stop()
        revealAnimation.from = revealProgress
        revealAnimation.to = open ? 1 : 0
        revealAnimation.duration = open ? motionPanelIn : motionPanelOut
        revealAnimation.restart()
    }

    NumberAnimation {
        id: revealAnimation

        target: root
        property: "revealProgress"
        from: root.revealProgress
        to: root.open ? 1 : 0
        duration: root.open ? root.motionPanelIn : root.motionPanelOut
        easing.type: root.open ? root.motionEaseEnter : root.motionEaseExit
    }

    Component.onCompleted: {
        if (open)
            ensureLoaded()
    }

    Keys.onEscapePressed: root.closeRequested()
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Left || event.key === Qt.Key_A) {
            root.moveSelection(-1)
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Right || event.key === Qt.Key_D) {
            root.moveSelection(1)
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.applySelected()
            event.accepted = true
        }
    }

    function c(name, fallback) {
        return root.theme ? root.theme[name] : fallback
    }

    function accentPrimary() {
        return root.pywalStyle && root.theme ? root.theme.accentSecondary : root.c("accentPrimary", Qt.rgba(232 / 255, 166 / 255, 200 / 255, 1))
    }

    function accentSecondary() {
        return root.pywalStyle && root.theme ? root.theme.accentPrimary : root.c("accentSecondary", Qt.rgba(200 / 255, 148 / 255, 242 / 255, 1))
    }

    function alpha(colorValue, opacity) {
        return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, opacity)
    }

    function fontGlowEnabled() {
        return root.theme && root.theme.textGlow.a > 0.001
    }

    function profileImageSource() {
        const customPath = root.theme ? String(root.theme.profileImagePath || "").trim() : ""
        return customPath.length > 0 ? customPath : Qt.resolvedUrl("../assets/profile-avatar.svg")
    }

    function chooseProfileImage() {
        if (!profileImageChooser.running)
            profileImageChooser.running = true
    }

    function tr(key) {
        const lang = root.theme ? root.theme.language : "pt-BR"
        return VeloraSettingsTranslations.translate(key, lang)
    }

    component FontGlowEffect: MultiEffect {
        shadowEnabled: true
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
        shadowColor: root.theme ? root.theme.textGlow : Qt.rgba(0, 0, 0, 0)
        shadowOpacity: root.theme ? Math.min(1, 0.34 + root.theme.textGlowLevel * 0.66) : 0
        shadowBlur: root.theme ? Math.min(1, 0.24 + root.theme.textGlowLevel * 0.72) : 0
        blurMax: root.theme ? Math.round(12 + root.theme.textGlowLevel * 22) : 12
        autoPaddingEnabled: true
    }

    function percent(value) {
        return Math.round(Number(value || 0) * 100) + "%"
    }

    function secondsText(value) {
        const n = Number(value)
        return (isNaN(n) ? 0 : n).toFixed(2) + "s"
    }

    function wallpaperTransitionOptions() {
        return [
            { id: "fade", label: root.tr("transitionFade") },
            { id: "wave", label: root.tr("transitionWave") },
            { id: "wipe", label: root.tr("transitionWipe") },
            { id: "grow", label: root.tr("transitionGrow") },
            { id: "outer", label: root.tr("transitionOuter") },
            { id: "random", label: root.tr("transitionRandom") }
        ]
    }

    function wallpaperLiveTransitionOptions() {
        return [
            { id: "shader", label: root.tr("liveTransitionShader") },
            { id: "native", label: root.tr("liveTransitionNative") }
        ]
    }

    function isValidWallpaperTransition(id) {
        const value = String(id || "")
        const options = root.wallpaperTransitionOptions()
        for (let i = 0; i < options.length; i += 1) {
            if (options[i].id === value)
                return true
        }
        return false
    }

    function clampWallpaperDuration(value) {
        const n = Number(value)
        if (isNaN(n))
            return root.wallpaperTransitionDuration
        return Math.max(0.15, Math.min(3.00, n))
    }

    function clampWallpaperDelay(value) {
        const n = Number(value)
        if (isNaN(n))
            return root.wallpaperStaticDelay
        return Math.max(0, Math.min(0.80, n))
    }

    function applyWallpaperTransitionState(line) {
        const parts = String(line || "").trim().split("|")
        if (parts.length > 0 && root.isValidWallpaperTransition(parts[0]))
            root.wallpaperTransition = parts[0]
        if (parts.length > 1)
            root.wallpaperTransitionDuration = root.clampWallpaperDuration(parts[1])
        if (parts.length > 2)
            root.wallpaperStaticDelay = root.clampWallpaperDelay(parts[2])
    }

    function applyWallpaperLiveTransitionState(line) {
        root.wallpaperLiveTransition = String(line || "").trim() === "native" ? "native" : "shader"
    }

    function applyTerminalStrongColorsState(line) {
        const value = String(line || "").trim().toLowerCase()
        root.terminalStrongColors = value === "on" || value === "true" || value === "1"
    }

    function saveWallpaperTransition() {
        const transition = root.isValidWallpaperTransition(root.wallpaperTransition) ? root.wallpaperTransition : "fade"
        const duration = root.wallpaperTransitionDuration.toFixed(2)
        const delay = root.wallpaperStaticDelay.toFixed(2)
        const payload = transition + "|" + duration + "|" + delay

        if (!wallpaperTransitionSave.running) {
            wallpaperTransitionSave.command = [root.stateScript, "wallpaper-transition", "set", transition, duration, delay]
            wallpaperTransitionSave.running = true
        } else {
            wallpaperTransitionSave.pendingConfig = payload
        }

        root.noticeText = root.tr("wallpaperTransitionSaved")
        noticeReset.restart()
    }

    function setWallpaperTransition(id) {
        if (!root.isValidWallpaperTransition(id))
            return
        root.wallpaperTransition = String(id)
        root.saveWallpaperTransition()
    }

    function setWallpaperTransitionDuration(value) {
        root.wallpaperTransitionDuration = root.clampWallpaperDuration(value)
        root.saveWallpaperTransition()
    }

    function setWallpaperStaticDelay(value) {
        root.wallpaperStaticDelay = root.clampWallpaperDelay(value)
        root.saveWallpaperTransition()
    }

    function setWallpaperLiveTransition(mode) {
        const next = String(mode || "") === "native" ? "native" : "shader"
        if (root.wallpaperLiveTransition === next)
            return
        root.wallpaperLiveTransition = next
        if (!wallpaperLiveTransitionSave.running) {
            wallpaperLiveTransitionSave.command = [root.stateScript, "wallpaper-live-transition", "set", next]
            wallpaperLiveTransitionSave.running = true
        } else {
            wallpaperLiveTransitionSave.pendingMode = next
        }
        root.noticeText = root.tr("wallpaperLiveTransitionSaved")
        noticeReset.restart()
    }

    function setTerminalStrongColors(enabled) {
        const next = enabled === true
        if (root.terminalStrongColors === next)
            return
        root.terminalStrongColors = next
        if (!terminalStrongColorsSave.running) {
            terminalStrongColorsSave.command = [root.stateScript, "terminal-strong-colors", "set", next ? "on" : "off"]
            terminalStrongColorsSave.running = true
        } else {
            terminalStrongColorsSave.pendingValue = next
            terminalStrongColorsSave.hasPendingValue = true
        }
        root.noticeText = root.tr(next ? "terminalStrongColorsOn" : "terminalStrongColorsOff")
        noticeReset.restart()
    }

    function queueTerminalThemeApply() {
        if (terminalThemeApply.running) {
            root.terminalThemeReloadPending = true
            return
        }
        terminalThemeApply.running = true
    }

    function themeOptions() {
        return root.theme ? root.theme.themeOptions : root.fallbackThemes
    }

    function languageOptions() {
        return root.theme ? root.theme.languageOptions : root.fallbackLanguageOptions
    }

    function fontOptions() {
        return root.theme ? root.theme.fontOptions : root.fallbackFontOptions
    }

    function currentLanguage() {
        return root.theme ? root.theme.language : "pt-BR"
    }

    function currentLanguageIndex() {
        const options = root.languageOptions()
        for (let i = 0; i < options.length; i += 1) {
            if (options[i].id === root.currentLanguage())
                return i
        }
        return 0
    }

    function selectLanguage(id) {
        const options = root.languageOptions()
        var label = id
        for (let i = 0; i < options.length; i += 1) {
            if (options[i].id === id) {
                label = options[i].label
                break
            }
        }
        if (root.theme)
            root.theme.setLanguage(id)
        root.noticeText = root.tr("languageApplied") + label
        noticeReset.restart()
    }

    function currentThemeId() {
        return root.theme ? root.theme.themeId : "default"
    }

    function powerProfileOptions() {
        return [
            { id: "balanced", label: root.tr("powerBalanced"), icon: "battery" },
            { id: "performance", label: root.tr("powerPerformance"), icon: "sun" }
        ]
    }

    function powerProfileLabel(profile) {
        const value = String(profile || "")
        if (value === "balanced")
            return root.tr("powerBalanced")
        if (value === "performance")
            return root.tr("powerPerformance")
        return value.length > 0 ? value : "unknown"
    }

    function setPowerProfile(profile) {
        const value = String(profile || "")
        if (value !== "balanced" && value !== "performance")
            return

        root.powerProfile = value
        root.noticeText = root.tr("powerProfileApplied") + root.powerProfileLabel(value)
        noticeReset.restart()

        if (!powerProfileSet.running) {
            powerProfileSet.command = ["powerprofilesctl", "set", value]
            powerProfileSet.running = true
        } else {
            powerProfileSet.pendingProfile = value
        }
    }

    function selectTheme(id) {
        if (root.theme)
            root.theme.applyTheme(id)
        if (id === "pywal16")
            root.noticeText = "pywal16 preparado como opcao. Se nao houver tema gerado, o Default continua como fallback."
        else
            root.noticeText = "Tema aplicado: " + id
        noticeReset.restart()
    }

    function displaySource(entry) {
        if (!entry)
            return ""
        if (entry.preview && String(entry.preview).length > 0)
            return entry.preview
        if ((entry.kind || "static") !== "engine")
            return entry.path || ""
        return ""
    }

    function basename(path) {
        var name = String(path || "").split("/").pop()
        var dot = name.lastIndexOf(".")
        if (dot > 0)
            name = name.slice(0, dot)
        return name.replace(/[-_]+/g, " ")
    }

    function currentWallpaper() {
        if (root.wallpapers.length > 0)
            return root.wallpapers[Math.max(0, Math.min(root.selectedIndex, root.wallpapers.length - 1))]
        return (root.fallbackWallpapers[0] || ({}))
    }

    function currentWallpaperPath() {
        return root.currentWallpaper().path || ""
    }

    function currentWallpaperPreview() {
        return root.displaySource(root.currentWallpaper())
    }

    function currentWallpaperKind() {
        return root.currentWallpaper().kind || "static"
    }

    function wallpaperNavIndex() {
        return -1
    }

    function visualizerNavIndex() {
        return 1
    }

    function languageNavIndex() {
        return -1
    }

    function visualizerModeOptions() {
        return [
            { id: "wave", label: root.tr("visualizerWave"), icon: "volume" },
            { id: "pixels", label: root.tr("visualizerPixels"), icon: "box" }
        ]
    }

    function moveSelection(dir) {
        if (compactSettingsView) {
            compactSettingsView.activeTab = (compactSettingsView.activeTab + dir + compactSettingsView.tabs.length) % compactSettingsView.tabs.length
            return
        }

        if (root.activeNav === root.languageNavIndex()) {
            const options = root.languageOptions()
            if (options.length <= 0)
                return
            const nextIndex = (root.currentLanguageIndex() + dir + options.length) % options.length
            root.selectLanguage(options[nextIndex].id)
            return
        }

        if (root.activeNav !== root.wallpaperNavIndex())
            return

        const count = root.wallpapers.length
        if (count <= 0)
            return
        root.selectedIndex = (root.selectedIndex + dir + count) % count
    }

    function applySelected() {
        if (compactSettingsView) {
            compactSettingsView.markApplied()
            return
        }

        if (root.activeNav !== root.wallpaperNavIndex())
            return
        if (applyWallpaper.running)
            return
        const item = root.currentWallpaper()
        if (!item.path)
            return
        applyWallpaper.command = [root.applyScript, item.kind || "static", item.path, root.displaySource(item), root.wallpaperTransition, root.wallpaperTransitionDuration.toFixed(2), root.wallpaperStaticDelay.toFixed(2), root.wallpaperLiveTransition]
        applyWallpaper.running = true
    }

    function setZenAutoRestart(enabled) {
        root.zenAutoRestart = enabled
        if (!zenModeSave.running) {
            zenModeSave.command = [root.zenLiveScript, "mode", "set", enabled ? "restart" : "off"]
            zenModeSave.running = true
        } else {
            zenModeSave.pendingMode = enabled ? "restart" : "off"
        }

        root.noticeText = enabled ? root.tr("zenRestartOnNotice") : root.tr("zenRestartOffNotice")
        noticeReset.restart()
    }

    function setWebThemeBalance(enabled) {
        root.webThemeBalance = enabled
        const mode = enabled ? "balance" : "clean"
        if (!webThemeModeSave.running) {
            webThemeModeSave.command = [root.zenThemeScript, "--quiet", "mode", "set", mode]
            webThemeModeSave.running = true
        } else {
            webThemeModeSave.pendingMode = mode
        }

        root.noticeText = enabled ? root.tr("webBalanceOnNotice") : root.tr("webBalanceOffNotice")
        noticeReset.restart()
    }

    function setCodeOpacity(value) {
        const next = Math.max(0.60, Math.min(0.98, Number(value || 0.94)))
        root.codeOpacity = next
        if (!codeOpacitySave.running) {
            codeOpacitySave.command = [root.codeTransparencyScript, "set", next.toFixed(2)]
            codeOpacitySave.running = true
        } else {
            codeOpacitySave.pendingOpacity = next.toFixed(2)
        }

        root.noticeText = root.tr("codeOpacityNotice")
        noticeReset.restart()
    }

    function applyVelyricsState(line) {
        const parts = String(line || "").trim().split("|")
        if (parts.length > 0)
            root.velyricsMode = parts[0] === "words" ? "words" : "line"
        if (parts.length > 1) {
            const words = Number(parts[1])
            if (!isNaN(words))
                root.velyricsWordsPerTerminal = Math.max(1, Math.min(12, Math.round(words)))
        }
        if (parts.length > 2) {
            const scale = Number(parts[2])
            if (!isNaN(scale))
                root.velyricsFontScale = Math.max(0.5, Math.min(3.0, scale))
        }
        if (parts.length > 3) {
            const offset = Number(parts[3])
            if (!isNaN(offset))
                root.velyricsSyncOffsetMs = Math.max(0, Math.min(1500, offset))
        }
        if (parts.length > 4) {
            const family = parts.slice(4).join("|").trim()
            root.velyricsFontFamily = family.length > 0 ? family : "Pixelon"
        }
    }

    function applyVelyricsFonts(data) {
        try {
            const parsed = JSON.parse(String(data || "[]"))
            if (!Array.isArray(parsed))
                return
            const fonts = parsed.filter(function(family) { return String(family || "").trim().length > 0 })
            if (fonts.indexOf(root.velyricsFontFamily) < 0)
                fonts.unshift(root.velyricsFontFamily)
            root.velyricsFontFamilies = fonts
        } catch (error) {
            console.warn("[VeloraSettings] Não foi possível listar as fontes:", error)
        }
    }

    function filteredVelyricsFonts() {
        const query = String(root.velyricsFontSearch || "").trim().toLowerCase()
        if (query.length <= 0)
            return root.velyricsFontFamilies
        return root.velyricsFontFamilies.filter(function(family) {
            return String(family).toLowerCase().indexOf(query) >= 0
        })
    }

    function saveVelyricsSettings() {
        const payload = root.velyricsMode + "|" + root.velyricsWordsPerTerminal + "|" + root.velyricsFontScale.toFixed(2) + "|" + root.velyricsSyncOffsetMs.toFixed(1) + "|" + root.velyricsFontFamily
        if (!velyricsSettingsSave.running) {
            velyricsSettingsSave.command = [root.velyricsStateScript, "set", root.velyricsMode, String(root.velyricsWordsPerTerminal), root.velyricsFontScale.toFixed(2), root.velyricsSyncOffsetMs.toFixed(1), root.velyricsFontFamily]
            velyricsSettingsSave.running = true
        } else {
            velyricsSettingsSave.pendingConfig = payload
        }
        root.noticeText = "Configuração do Velyrics atualizada."
        noticeReset.restart()
    }

    function setVelyricsMode(mode) {
        root.velyricsMode = mode === "words" ? "words" : "line"
        root.saveVelyricsSettings()
    }

    function setVelyricsWordsPerTerminal(value) {
        root.velyricsWordsPerTerminal = Math.max(1, Math.min(12, Math.round(Number(value || 4))))
        root.saveVelyricsSettings()
    }

    function setVelyricsFontScale(value) {
        root.velyricsFontScale = Math.max(0.5, Math.min(3.0, Number(value || 1.0)))
        root.saveVelyricsSettings()
    }

    function setVelyricsFontFamily(family) {
        const next = String(family || "").replace(/\|/g, " ").trim()
        root.velyricsFontFamily = next.length > 0 ? next : "Pixelon"
        root.saveVelyricsSettings()
    }

    function setVelyricsFontSearch(query) {
        root.velyricsFontSearch = String(query || "")
    }

    function setVelyricsSyncOffset(value) {
        root.velyricsSyncOffsetMs = Math.max(0, Math.min(1500, Number(value || 500)))
        root.saveVelyricsSettings()
    }

    function resetVelyricsSettings() {
        root.velyricsMode = "line"
        root.velyricsWordsPerTerminal = 4
        root.velyricsFontScale = 1.0
        root.velyricsFontFamily = "Pixelon"
        root.velyricsFontSearch = ""
        root.velyricsSyncOffsetMs = 500.0
        root.saveVelyricsSettings()
    }

    function applyWorldClockState(line) {
        try {
            const payload = JSON.parse(String(line || "{}"))
            if (!payload.items || payload.items.length < 2)
                return
            root.worldClockItems = [
                { label: String(payload.items[0].label || "New York"), zone: String(payload.items[0].zone || "America/New_York") },
                { label: String(payload.items[1].label || "Tokyo"), zone: String(payload.items[1].zone || "Asia/Tokyo") }
            ]
        } catch (error) {
            console.warn("[VeloraSettings] Não foi possível ler os relógios mundiais:", error)
        }
    }

    function worldClockOptionIndex(slot) {
        const item = root.worldClockItems[Math.max(0, Math.min(1, slot))]
        const zone = item ? String(item.zone || "") : ""
        for (let index = 0; index < root.worldClockOptions.length; ++index) {
            if (root.worldClockOptions[index].zone === zone)
                return index
        }
        return 0
    }

    function cycleWorldClock(slot, direction) {
        const safeSlot = Math.max(0, Math.min(1, Math.round(slot)))
        const count = root.worldClockOptions.length
        const nextIndex = (root.worldClockOptionIndex(safeSlot) + (direction < 0 ? -1 : 1) + count) % count
        const next = root.worldClockOptions[nextIndex]
        const items = root.worldClockItems.slice(0)
        items[safeSlot] = next
        root.worldClockItems = items
        const pending = safeSlot + "|" + next.zone + "|" + next.label
        if (!worldClockSave.running) {
            worldClockSave.command = [root.worldClockStateScript, "set", String(safeSlot), next.zone, next.label]
            worldClockSave.running = true
        } else {
            worldClockSave.pendingConfig = pending
        }
        root.noticeText = "Relógios mundiais atualizados."
        noticeReset.restart()
    }

    function reload() {
        if (!scanWallpapers.running)
            scanWallpapers.running = true
    }

    function ensureLoaded() {
        if (loadedOnce)
            return

        loadedOnce = true
        reload()
        if (!powerProfileLoad.running)
            powerProfileLoad.running = true
        if (!zenModeLoad.running)
            zenModeLoad.running = true
        if (!webThemeModeLoad.running)
            webThemeModeLoad.running = true
        if (!codeOpacityLoad.running)
            codeOpacityLoad.running = true
        if (!wallpaperTransitionLoad.running)
            wallpaperTransitionLoad.running = true
        if (!wallpaperLiveTransitionLoad.running)
            wallpaperLiveTransitionLoad.running = true
        if (!terminalStrongColorsLoad.running)
            terminalStrongColorsLoad.running = true
        if (!velyricsSettingsLoad.running)
            velyricsSettingsLoad.running = true
        if (!velyricsFontsLoad.running)
            velyricsFontsLoad.running = true
        if (!worldClockLoad.running)
            worldClockLoad.running = true
    }

    Timer {
        id: noticeReset
        interval: 2800
        repeat: false
        onTriggered: root.noticeText = ""
    }

    Process {
        id: applyWallpaper

        running: false
        command: [root.applyScript, root.currentWallpaperKind(), root.currentWallpaperPath(), root.currentWallpaperPreview(), root.wallpaperTransition, root.wallpaperTransitionDuration.toFixed(2), root.wallpaperStaticDelay.toFixed(2), root.wallpaperLiveTransition]
        onExited: {
            running = false
        }
    }

    Process {
        id: customWallpaperChooser

        running: false
        command: ["bash", "-lc", "xdg-open \"$HOME/Pictures/Wallpapers\" >/dev/null 2>&1 || true"]
        onExited: running = false
    }

    Process {
        id: profileImageChooser

        running: false
        command: ["bash", "-lc", "file=\"\"; if command -v zenity >/dev/null 2>&1; then file=$(zenity --file-selection --title='Escolher foto de perfil' --file-filter='Imagens | *.png *.jpg *.jpeg *.webp' 2>/dev/null || true); elif command -v kdialog >/dev/null 2>&1; then file=$(kdialog --getopenfilename \"$HOME\" 'Images (*.png *.jpg *.jpeg *.webp)' 2>/dev/null || true); fi; [ -n \"$file\" ] && printf '%s\\n' \"$file\""]

        stdout: SplitParser {
            onRead: function(data) {
                const path = String(data || "").trim()
                if (path.length <= 0 || !root.theme)
                    return
                root.theme.setProfileImagePath(path)
                root.noticeText = root.tr("profilePhotoUpdated")
                noticeReset.restart()
            }
        }

        onExited: running = false
    }

    Process {
        id: powerProfileLoad

        running: false
        command: ["powerprofilesctl", "get"]

        stdout: SplitParser {
            onRead: function(data) {
                const value = String(data || "").trim()
                root.powerProfile = value.length > 0 ? value : "unknown"
            }
        }

        onExited: running = false
    }

    Process {
        id: powerProfileSet

        property string pendingProfile: ""
        running: false
        command: ["powerprofilesctl", "set", "balanced"]
        onExited: {
            running = false
            if (pendingProfile.length > 0) {
                const next = pendingProfile
                pendingProfile = ""
                command = ["powerprofilesctl", "set", next]
                running = true
                return
            }
            if (!powerProfileLoad.running)
                powerProfileLoad.running = true
        }
    }

    Process {
        id: zenModeLoad

        running: false
        command: [root.zenLiveScript, "mode", "get"]

        stdout: SplitParser {
            onRead: function(data) {
                root.zenAutoRestart = String(data || "").trim() !== "off"
            }
        }

        onExited: running = false
    }

    Process {
        id: zenModeSave

        property string pendingMode: ""
        running: false
        command: [root.zenLiveScript, "mode", "set", "restart"]
        onExited: {
            running = false
            if (pendingMode.length > 0) {
                const next = pendingMode
                pendingMode = ""
                command = [root.zenLiveScript, "mode", "set", next]
                running = true
            }
        }
    }

    Process {
        id: webThemeModeLoad

        running: false
        command: [root.zenThemeScript, "mode", "get"]

        stdout: SplitParser {
            onRead: function(data) {
                root.webThemeBalance = String(data || "").trim() !== "clean"
            }
        }

        onExited: running = false
    }

    Process {
        id: webThemeModeSave

        property string pendingMode: ""
        running: false
        command: [root.zenThemeScript, "--quiet", "mode", "set", "balance"]
        onExited: {
            running = false
            if (pendingMode.length > 0) {
                const next = pendingMode
                pendingMode = ""
                command = [root.zenThemeScript, "--quiet", "mode", "set", next]
                running = true
                return
            }
            if (root.zenAutoRestart && !zenThemeReload.running)
                zenThemeReload.running = true
        }
    }

    Process {
        id: zenThemeReload

        running: false
        command: [root.zenLiveScript, "--debounced"]
        onExited: running = false
    }

    Process {
        id: codeOpacityLoad

        running: false
        command: [root.codeTransparencyScript, "get"]

        stdout: SplitParser {
            onRead: function(data) {
                const value = Number(String(data || "").trim())
                if (!isNaN(value))
                    root.codeOpacity = Math.max(0.60, Math.min(0.98, value))
            }
        }

        onExited: running = false
    }

    Process {
        id: codeOpacitySave

        property string pendingOpacity: ""
        running: false
        command: [root.codeTransparencyScript, "set", root.codeOpacity.toFixed(2)]
        onExited: {
            running = false
            if (pendingOpacity.length > 0) {
                const next = pendingOpacity
                pendingOpacity = ""
                command = [root.codeTransparencyScript, "set", next]
                running = true
            }
        }
    }

    Process {
        id: wallpaperTransitionLoad

        running: false
        command: [root.stateScript, "wallpaper-transition", "get"]

        stdout: SplitParser {
            onRead: function(data) {
                root.applyWallpaperTransitionState(data)
            }
        }

        onExited: running = false
    }

    Process {
        id: wallpaperTransitionSave

        property string pendingConfig: ""
        running: false
        command: [root.stateScript, "wallpaper-transition", "set", root.wallpaperTransition, root.wallpaperTransitionDuration.toFixed(2), root.wallpaperStaticDelay.toFixed(2)]
        onExited: {
            running = false
            if (pendingConfig.length > 0) {
                const parts = pendingConfig.split("|")
                pendingConfig = ""
                command = [root.stateScript, "wallpaper-transition", "set", parts[0], parts[1], parts[2]]
                running = true
            }
        }
    }

    Process {
        id: wallpaperLiveTransitionLoad

        running: false
        command: [root.stateScript, "wallpaper-live-transition", "get"]

        stdout: SplitParser {
            onRead: function(data) { root.applyWallpaperLiveTransitionState(data) }
        }

        onExited: running = false
    }

    Process {
        id: wallpaperLiveTransitionSave

        property string pendingMode: ""
        running: false
        command: [root.stateScript, "wallpaper-live-transition", "set", root.wallpaperLiveTransition]
        onExited: {
            running = false
            if (pendingMode.length > 0) {
                const next = pendingMode
                pendingMode = ""
                command = [root.stateScript, "wallpaper-live-transition", "set", next]
                running = true
            }
        }
    }

    Process {
        id: terminalStrongColorsLoad

        running: false
        command: [root.stateScript, "terminal-strong-colors", "get"]
        stdout: SplitParser {
            onRead: function(data) { root.applyTerminalStrongColorsState(data) }
        }
        onExited: running = false
    }

    Process {
        id: terminalStrongColorsSave

        property bool pendingValue: false
        property bool hasPendingValue: false
        running: false
        command: [root.stateScript, "terminal-strong-colors", "set", root.terminalStrongColors ? "on" : "off"]
        onExited: {
            running = false
            root.queueTerminalThemeApply()
            if (hasPendingValue) {
                const next = pendingValue
                hasPendingValue = false
                command = [root.stateScript, "terminal-strong-colors", "set", next ? "on" : "off"]
                running = true
            }
        }
    }

    Process {
        id: terminalThemeApply

        running: false
        command: [root.terminalThemeScript, "--quiet"]
        onExited: {
            running = false
            if (root.terminalThemeReloadPending) {
                root.terminalThemeReloadPending = false
                running = true
            }
        }
    }

    Process {
        id: velyricsSettingsLoad

        running: false
        command: [root.velyricsStateScript, "get"]

        stdout: SplitParser {
            onRead: function(data) { root.applyVelyricsState(data) }
        }

        onExited: running = false
    }

    Process {
        id: velyricsSettingsSave

        property string pendingConfig: ""
        running: false
        command: [root.velyricsStateScript, "set", root.velyricsMode, String(root.velyricsWordsPerTerminal), root.velyricsFontScale.toFixed(2), root.velyricsSyncOffsetMs.toFixed(1), root.velyricsFontFamily]
        onExited: {
            running = false
            if (pendingConfig.length > 0) {
                const parts = pendingConfig.split("|")
                pendingConfig = ""
                command = [root.velyricsStateScript, "set", parts[0], parts[1], parts[2], parts[3], parts.slice(4).join("|")]
                running = true
            }
        }
    }

    Process {
        id: velyricsFontsLoad

        running: false
        command: [root.velyricsStateScript, "fonts"]

        stdout: SplitParser {
            onRead: function(data) { root.applyVelyricsFonts(data) }
        }

        onExited: running = false
    }

    Process {
        id: worldClockLoad

        running: false
        command: [root.worldClockStateScript, "get"]

        stdout: SplitParser {
            onRead: function(data) { root.applyWorldClockState(data) }
        }

        onExited: running = false
    }

    Process {
        id: worldClockSave

        property string pendingConfig: ""
        running: false
        command: [root.worldClockStateScript, "set", "0", "America/New_York", "New York"]
        onExited: {
            running = false
            if (pendingConfig.length > 0) {
                const parts = pendingConfig.split("|")
                pendingConfig = ""
                command = [root.worldClockStateScript, "set", parts[0], parts[1], parts[2]]
                running = true
            }
        }
    }

    Process {
        id: scanWallpapers

        running: false
        property var tmp: []
        command: [root.scanScript]

        onStarted: {
            tmp = []
            root.scanComplete = false
        }

        stdout: SplitParser {
            onRead: function(data) {
                const line = String(data).trim()
                if (!line || line === "BEGIN")
                    return

                if (line === "END") {
                    if (scanWallpapers.tmp.length > 0) {
                        root.allWallpapers = scanWallpapers.tmp.slice()
                        root.wallpapers = scanWallpapers.tmp.slice(0, Math.min(5, scanWallpapers.tmp.length))
                        root.selectedIndex = 0
                    }
                    root.scanComplete = true
                    return
                }

                const parts = line.split("|")
                if (parts.length < 3)
                    return

                const kind = parts[0].toLowerCase()
                const path = parts[1]
                const preview = parts[2]
                const title = parts.length > 3 && parts.slice(3).join("|").length > 0
                    ? parts.slice(3).join("|")
                    : root.basename(path)

                scanWallpapers.tmp.push({
                    kind: kind,
                    path: path,
                    preview: preview,
                    title: title,
                    label: title,
                    category: kind === "static" ? "Imagem estática" : kind
                })
            }
        }

        onExited: {
            running = false
            if (tmp.length > 0) {
                root.allWallpapers = tmp.slice()
                root.wallpapers = tmp.slice(0, Math.min(5, tmp.length))
                root.selectedIndex = 0
                root.scanComplete = true
            }
        }
    }

    Rectangle {
        visible: !root.externalSurface
        x: 10
        y: 13
        width: parent.width - 2
        height: parent.height - 4
        radius: root.cornerRadius + 4
        color: root.c("shadowColor", Qt.rgba(0.37, 0.25, 0.45, 0.11))
        opacity: 0.58
    }

    Rectangle {
        id: panelSurface

        anchors.fill: parent
        radius: root.cornerRadius
        color: root.externalSurface ? "transparent" : root.c("surfacePopup", Qt.rgba(1.0, 0.986, 1.0, 0.86))
        border.width: root.externalSurface ? 0 : 1
        border.color: root.pywalStyle && root.theme ? root.theme.popupBorderGlow : root.c("borderSoft", Qt.rgba(1, 1, 1, 0.74))
        clip: true
        antialiasing: true
        layer.enabled: !root.externalSurface
        layer.effect: DropShadow {
            transparentBorder: true
            radius: root.pywalStyle ? 42 : 52
            samples: root.pywalStyle ? 85 : 101
            horizontalOffset: 0
            verticalOffset: root.pywalStyle ? 0 : 18
            color: root.pywalStyle && root.theme ? root.alpha(root.theme.popupBorderGlow, root.theme.popupBorderGlow.a * 0.48) : root.c("shadowColor", Qt.rgba(0.48, 0.30, 0.50, 0.10))
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: function(mouse) { mouse.accepted = true }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: !root.externalSurface
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.alpha(root.c("surfaceCard", Qt.rgba(1, 1, 1, 0.68)), 0.54) }
                GradientStop { position: 0.56; color: root.alpha(root.c("surfaceCard", Qt.rgba(1, 1, 1, 0.68)), 0.20) }
                GradientStop { position: 1.0; color: root.alpha(root.accentPrimary(), root.neon ? 0.08 : 0.10) }
            }
        }

        VeloraCompactSettings {
            id: compactSettingsView

            anchors.fill: parent
            theme: root.theme
            controller: root
        }

        Rectangle {
            visible: false
            x: 200
            y: 0
            width: 1
            height: parent.height
            color: root.alpha(root.c("borderActive", Qt.rgba(232 / 255, 166 / 255, 200 / 255, 1)), 0.16)
        }

        Column {
            id: navColumn

            visible: false
            x: 22
            y: 26
            width: 154
            spacing: 16

            Repeater {
                model: root.navItems

                SettingsNavItem {
                    required property int index
                    required property var modelData

                    width: navColumn.width
                    itemData: modelData
                    active: root.activeNav === index
                    onClicked: root.activeNav = index
                }
            }
        }

        Item {
            id: mainArea

            visible: false
            x: 230
            y: 35
            width: parent.width - x - 34
            height: parent.height - 62

            Flickable {
                id: mainFlick

                anchors.fill: parent
                visible: root.activeNav <= 2
                clip: true
                contentWidth: width
                contentHeight: root.activeNav === 0 ? 840 : height
                boundsBehavior: Flickable.StopAtBounds

                Item {
                    id: mainContent

                    width: mainFlick.width
                    height: mainFlick.contentHeight

                Text {
                    x: 0
                    y: 0
                    visible: root.activeNav === 0
                    text: root.tr("themeStyle")
                    color: root.c("textPrimary", "#4d3f63")
                    font.family: root.uiFont
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    layer.enabled: root.fontGlowEnabled()
                    layer.effect: FontGlowEffect {}
                }

                Row {
                    id: themeRow

                    x: 0
                    y: 34
                    visible: root.activeNav === 0
                    spacing: 13

                    Repeater {
                        model: root.themeOptions()

                        ThemeCard {
                            required property var modelData

                            width: Math.floor((mainArea.width - themeRow.spacing * 4) / 5)
                            height: 124
                            itemData: modelData
                            selected: root.currentThemeId() === modelData.id
                            onClicked: root.selectTheme(modelData.id)
                        }
                    }
                }

	                Text {
	                    x: 0
	                    y: 160
	                    visible: root.activeNav === 0
	                    text: root.tr("layout")
	                    color: root.c("textPrimary", "#4d3f63")
	                    font.family: root.uiFont
	                    font.pixelSize: 14
	                    font.weight: Font.Bold
	                    layer.enabled: root.fontGlowEnabled()
	                    layer.effect: FontGlowEffect {}
	                }

                Row {
                    id: layoutRow

                    x: 0
                    y: 190
                    width: mainArea.width
                    visible: root.activeNav === 0
                    spacing: 10

                    LayoutPreviewButton {
                        width: 96
                        side: "left"
                        label: root.tr("layoutLeft")
                        active: root.theme ? root.theme.barPosition === "left" : true
                        onClicked: {
                            if (root.theme) {
                                root.theme.setBarPosition("left")
                            }
                        }
                    }

                    LayoutPreviewButton {
                        width: 96
                        side: "right"
                        label: root.tr("layoutRight")
                        active: root.theme ? root.theme.barPosition === "right" : false
                        onClicked: {
                            if (root.theme) {
                                root.theme.setBarPosition("right")
                            }
                        }
                    }

                }

                Row {
                    id: appSyncRow

                    x: 0
                    y: 242
                    width: mainArea.width
                    visible: root.activeNav === 0
                    spacing: 10

                    LayoutToggleButton {
                        width: 142
                        label: root.theme && root.theme.desktopFrameEnabled ? root.tr("frameOn") : root.tr("frameOff")
                        active: root.theme ? root.theme.desktopFrameEnabled : true
                        onClicked: {
                            if (root.theme)
                                root.theme.setDesktopFrameEnabled(!root.theme.desktopFrameEnabled)
                        }
                    }

                    LayoutToggleButton {
                        width: 184
                        label: root.tr("popupAttach")
                        active: root.theme ? root.theme.popupAttachedToBar : true
                        onClicked: {
                            if (root.theme)
                                root.theme.setPopupAttachedToBar(!root.theme.popupAttachedToBar)
                        }
                    }

                    LayoutToggleButton {
                        width: 154
                        label: root.zenAutoRestart ? root.tr("zenRestartOn") : root.tr("zenRestartOff")
                        active: root.zenAutoRestart
                        onClicked: root.setZenAutoRestart(!root.zenAutoRestart)
                    }

                }

                Text {
                    x: 0
                    y: 306
                    visible: root.activeNav === 0
                    text: root.tr("opacity")
                    color: root.c("textPrimary", "#4d3f63")
                    font.family: root.uiFont
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    layer.enabled: root.fontGlowEnabled()
                    layer.effect: FontGlowEffect {}
                }

	                Row {
	                    id: opacityRow

	                    x: 0
	                    y: 336
	                    width: mainArea.width
	                    visible: root.activeNav === 0
	                    spacing: 12
                        property int resetWidth: 74
                        property int controlCount: 4
                        property int controlWidth: Math.floor((width - spacing * controlCount - resetWidth) / controlCount)

                    OpacityControl {
                        width: opacityRow.controlWidth
                        label: root.tr("opacityAll")
                        minValue: root.theme ? root.theme.minPanelOpacity() : 0.25
                        value: root.theme ? root.theme.sidebarOpacity : 0.78
                        onMoved: function(nextValue) {
                            if (root.theme) {
                                root.theme.applyOpacity(nextValue, nextValue, Math.max(root.theme.minOpacityForRole("card"), nextValue - 0.10))
                                root.theme.applyBarOpacity(nextValue)
                            }
                        }
                    }

                    OpacityControl {
                        width: opacityRow.controlWidth
                        label: root.tr("opacityPanel")
                        minValue: root.theme ? root.theme.minPanelOpacity() : 0.25
                        value: root.theme ? root.theme.sidebarOpacity : 0.78
                        onMoved: function(nextValue) {
                            if (root.theme)
                                root.theme.applyOpacity(nextValue, nextValue, root.theme.cardOpacity)
                        }
                    }

                    OpacityControl {
                        width: opacityRow.controlWidth
                        label: root.tr("opacitySync")
                        minValue: root.theme ? root.theme.minPanelOpacity() : 0.25
                        value: root.theme ? root.theme.popupOpacity : 0.78
                        onMoved: function(nextValue) {
                            if (root.theme)
                                root.theme.applyOpacity(nextValue, nextValue, root.theme.cardOpacity)
                        }
                    }

                    OpacityControl {
                        width: opacityRow.controlWidth
                        label: root.tr("opacityCard")
                        minValue: root.theme ? root.theme.minOpacityForRole("card") : 0.25
                        value: root.theme ? root.theme.cardOpacity : 0.68
                        onMoved: function(nextValue) {
                            if (root.theme)
                                root.theme.applyOpacity(root.theme.sidebarOpacity, root.theme.sidebarOpacity, nextValue)
                        }
                    }

                    Rectangle {
                        id: resetOpacityButton

                        width: opacityRow.resetWidth
                        height: 42
                        radius: 9
                        color: resetOpacityMouse.containsMouse
                            ? root.c("hoverBg", Qt.rgba(0.92, 0.62, 0.78, 0.16))
                            : root.alpha(root.c("surfaceCard", Qt.rgba(1, 1, 1, 0.68)), 0.34)
                        border.width: 1
                        border.color: resetOpacityMouse.containsMouse
                            ? root.c("borderActive", Qt.rgba(0.90, 0.56, 0.74, 0.62))
                            : root.alpha(root.c("borderSoft", Qt.rgba(1, 1, 1, 0.68)), 0.56)

                        Text {
                            anchors.centerIn: parent
                            text: root.tr("reset")
                            color: root.c("textSecondary", "#8d7ca3")
                            font.family: root.uiFont
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            layer.enabled: root.fontGlowEnabled()
                            layer.effect: FontGlowEffect {}
                        }

                        MouseArea {
                            id: resetOpacityMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.theme)
                                    root.theme.resetGlow()
                                if (root.theme)
                                    root.theme.resetBorderAccent()
                                if (root.theme)
                                    root.theme.resetOpacity()
                                if (root.theme)
                                    root.theme.resetVisualizerStrength()
                                root.noticeText = root.tr("materialReset")
                                noticeReset.restart()
                            }
                        }
	                    }
	                }

                Row {
                    id: barOpacityRow

                    x: 0
                    y: 396
                    width: mainArea.width
                    visible: root.activeNav === 0
                    spacing: 12

                    OpacityControl {
                        width: Math.min(280, barOpacityRow.width)
                        label: root.tr("opacityBar")
                        minValue: root.theme ? root.theme.minOpacityForRole("sidebar") : 0.25
                        maxValue: 0.98
                        value: root.theme ? root.theme.barOpacity : 0.78
                        onMoved: function(nextValue) {
                            if (root.theme)
                                root.theme.applyBarOpacity(nextValue)
                        }
                    }
                }

                Text {
                    x: 0
                    y: 706
                    visible: root.activeNav === 0
                    text: root.tr("visualizer")
                    color: root.c("textPrimary", "#4d3f63")
                    font.family: root.uiFont
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    layer.enabled: root.fontGlowEnabled()
                    layer.effect: FontGlowEffect {}
                }

                Row {
                    id: visualizerRow

                    x: 0
                    y: 736
                    width: mainArea.width
                    visible: root.activeNav === 0
                    spacing: 12

                    OpacityControl {
                        width: Math.min(280, visualizerRow.width)
                        label: root.tr("visualizerStrength")
                        minValue: 0
                        maxValue: 0.90
                        value: root.theme ? root.theme.visualizerStrength : 0.46
                        onMoved: function(nextValue) {
                            if (root.theme)
                                root.theme.setVisualizerStrength(nextValue)
                        }
                    }
                }

                Text {
                    x: 0
	                    y: 456
	                    visible: root.activeNav === 0
	                    text: root.tr("glow")
                    color: root.c("textPrimary", "#4d3f63")
                    font.family: root.uiFont
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    layer.enabled: root.fontGlowEnabled()
                    layer.effect: FontGlowEffect {}
                }

                Row {
	                    id: glowRow

	                    x: 0
	                    y: 486
	                    width: mainArea.width
                    visible: root.activeNav === 0

                    OpacityControl {
                        width: Math.min(260, glowRow.width)
                        label: root.tr("fontGlow")
                        minValue: 0
                        maxValue: 1
                        value: root.theme ? root.theme.textGlowLevel : 0.78
                        onMoved: function(nextValue) {
                            if (root.theme)
                                root.theme.applyTextGlow(nextValue)
                        }
                    }
                }

	                Text {
	                    x: 0
	                    y: 546
	                    visible: root.activeNav === 0
	                    text: root.tr("border")
                    color: root.c("textPrimary", "#4d3f63")
                    font.family: root.uiFont
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    layer.enabled: root.fontGlowEnabled()
                    layer.effect: FontGlowEffect {}
                }

                Row {
	                    id: borderRow

	                    x: 0
	                    y: 576
	                    width: mainArea.width
                    visible: root.activeNav === 0
                    spacing: 14

                    BorderAdaptButton {
                        width: 116
                        active: root.theme ? root.theme.borderAdaptEnabled : true
                        onClicked: {
                            if (root.theme)
                                root.theme.applyBorderAccent(true, root.theme.borderHue)
                        }
                    }

                    BorderPaletteWheel {
                        width: 104
                        height: 104
                    }

                    Rectangle {
                        width: 220
                        height: 42
                        radius: 10
                        color: root.alpha(root.c("surfaceCard", Qt.rgba(1, 1, 1, 0.68)), 0.30)
                        border.width: 1
                        border.color: root.theme ? root.theme.sidebarBorderGlow : root.accentPrimary()
                        antialiasing: true
                        layer.enabled: root.pywalStyle
                        layer.effect: DropShadow {
                            transparentBorder: true
                            radius: 22
                            samples: 45
                            horizontalOffset: 0
                            verticalOffset: 0
                            color: root.theme ? root.alpha(root.theme.sidebarBorderGlow, root.theme.sidebarBorderGlow.a * 0.34) : Qt.rgba(0, 0, 0, 0)
                        }

                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: 10
                                rightMargin: 10
                            }

                            height: 5
                            radius: 3
                            color: root.theme ? root.theme.sidebarBorderGlow : root.accentPrimary()
                        }
                    }
                }

                Text {
                    x: 0
                    y: 0
                    visible: root.activeNav === 1
                    text: root.tr("wallpaper")
                    color: root.c("textPrimary", "#4d3f63")
                    font.family: root.uiFont
                    font.pixelSize: 15
                    font.weight: Font.Bold
                }

                Row {
                    id: wallpaperRow

                    x: 0
                    y: 34
                    visible: root.activeNav === 1
                    spacing: 13

                    Repeater {
                        model: Math.min(5, root.wallpapers.length)

                        WallpaperMini {
                            required property int index

                            width: Math.floor((mainArea.width - wallpaperRow.spacing * 4) / 5)
                            height: 88
                            source: root.contentActive && root.scanComplete ? root.displaySource(root.wallpapers[index]) : ""
                            selected: root.selectedIndex === index
                            onClicked: root.selectedIndex = index
                        }
                    }
                }

                Rectangle {
                    id: customButton

                    x: 0
                    y: 156
                    visible: root.activeNav === 1
                    width: 242
                    height: 42
                    radius: 8
                    color: customMouse.containsMouse
                        ? root.c("hoverBg", Qt.rgba(0.92, 0.62, 0.78, 0.16))
                        : root.c("buttonSecondaryBg", Qt.rgba(1, 1, 1, 0.58))
                    border.width: 1
                    border.color: customMouse.containsMouse
                        ? root.c("borderActive", Qt.rgba(0.90, 0.56, 0.74, 0.62))
                        : root.c("borderSoft", Qt.rgba(1, 1, 1, 0.68))
                    scale: customMouse.pressed ? 0.97 : (customMouse.containsMouse ? 1.015 : 1.0)
                    antialiasing: true

                    Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
                    Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 9

                        SmallIcon {
                            width: 17
                            height: 17
                            iconName: "folder"
                            colorOverride: root.c("textSecondary", "#8d7ca3")
                        }

                        Text {
                            text: root.tr("customWallpaper")
                            color: root.c("buttonSecondaryText", "#6d5a82")
                            font.family: root.uiFont
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                    }

                    MouseArea {
                        id: customMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.noticeText = root.tr("wallpaperFolderOpened")
                            noticeReset.restart()
                            if (!customWallpaperChooser.running)
                                customWallpaperChooser.running = true
                        }
                    }
                }

                Rectangle {
                    id: applyButton

                    x: mainArea.width - width
                    y: 156
                    visible: root.activeNav === 1
                    width: 132
                    height: 42
                    radius: 12
                    color: applyMouse.containsMouse
                        ? root.c("buttonPrimaryBg", root.accentPrimary())
                        : root.alpha(root.c("buttonPrimaryBg", root.accentPrimary()), 0.82)
                    scale: applyMouse.pressed ? 0.96 : (applyMouse.containsMouse ? 1.012 : 1.0)
                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        radius: 20
                        samples: 41
                        horizontalOffset: 0
                        verticalOffset: 8
                        color: root.c("buttonPrimaryGlow", root.c("shadowColor", Qt.rgba(0.50, 0.28, 0.46, 0.15)))
                    }

                    Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
                    Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

                    Text {
                        anchors.centerIn: parent
                        text: applyWallpaper.running ? root.tr("applying") : root.tr("apply")
                        color: root.c("buttonPrimaryText", "#ffffff")
                        font.family: root.uiFont
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: applyMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.applySelected()
                    }
                }

                Text {
                    x: 0
                    y: 214
                    visible: root.activeNav === 1
                    width: mainArea.width
                    text: root.noticeText.length > 0 ? root.noticeText : (root.theme && root.theme.themeNotice.length > 0 ? root.theme.themeNotice : "")
                    color: root.c("textMuted", "#b7a9c7")
                    elide: Text.ElideRight
                    font.family: root.uiFont
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }

                Text {
                    x: 0
                    y: 0
                    visible: root.activeNav === 2
                    text: root.tr("language")
                    color: root.c("textPrimary", "#4d3f63")
                    font.family: root.uiFont
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    layer.enabled: root.fontGlowEnabled()
                    layer.effect: FontGlowEffect {}
                }

                Text {
                    x: 0
                    y: 28
                    visible: root.activeNav === 2
                    width: mainArea.width
                    text: root.tr("languageHint")
                    color: root.c("textMuted", "#b7a9c7")
                    font.family: root.uiFont
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    layer.enabled: root.fontGlowEnabled()
                    layer.effect: FontGlowEffect {}
                }

                Row {
                    id: languageRow

                    x: 0
                    y: 72
                    width: mainArea.width
                    visible: root.activeNav === 2
                    spacing: 14

                    Repeater {
                        model: root.languageOptions()

                        LanguageButton {
                            required property var modelData

                            width: Math.floor((languageRow.width - languageRow.spacing * 2) / 3)
                            itemData: modelData
                            active: root.currentLanguage() === modelData.id
                            onClicked: root.selectLanguage(modelData.id)
                        }
                    }
                }

                Text {
                    x: 0
                    y: 162
                    visible: root.activeNav === 2
                    width: mainArea.width
                    text: root.noticeText
                    color: root.c("textMuted", "#b7a9c7")
                    font.family: root.uiFont
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    layer.enabled: root.fontGlowEnabled()
                    layer.effect: FontGlowEffect {}
                }
                }
            }

            Item {
                anchors.fill: parent
                visible: false

                Text {
                    anchors.centerIn: parent
                    text: "Esta seção será conectada na próxima etapa"
                    color: root.c("textSecondary", "#8d7ca3")
                    font.family: root.uiFont
                    font.pixelSize: 13
                    font.weight: Font.Bold
                }
            }
        }
    }

    component NewSettingsView: Rectangle {
        id: settingsView

        readonly property color bg: root.theme ? root.theme.mix(root.theme.surfacePopup, root.theme.accentPrimary, root.pywalStyle ? 0.05 : 0.02, root.theme.themeMode === "dark" ? Math.max(0.66, Math.min(0.84, root.theme.surfacePopup.a)) : Math.max(0.56, Math.min(0.74, root.theme.surfacePopup.a))) : Qt.rgba(1.0, 0.965, 0.995, 0.68)
        readonly property color panel: root.theme ? root.theme.mix(root.theme.surfaceCard, root.theme.accentPrimary, root.pywalStyle ? 0.08 : 0.04, root.theme.themeMode === "dark" ? 0.50 : 0.56) : Qt.rgba(1, 1, 1, 0.42)
        readonly property color panelStrong: root.theme ? root.theme.mix(root.theme.surfaceCard, root.theme.accentSecondary, root.pywalStyle ? 0.16 : 0.08, root.theme.themeMode === "dark" ? 0.64 : 0.70) : Qt.rgba(1, 1, 1, 0.58)
        readonly property color text: root.settingsLightText
        readonly property color textSoft: root.settingsLightTextSoft
        readonly property color line: root.settingsLightLine
        readonly property bool compact: width < 980
        readonly property int bodyX: compact ? 24 : 318
        readonly property int bodyTop: compact ? 126 : 112
        readonly property int bodyW: Math.max(320, width - bodyX - (compact ? 24 : 40))
        readonly property int contentColumns: bodyW > 820 ? 2 : 1

        function sectionTitle() {
            if (root.activeNav === 1)
                return root.tr("bar")
            if (root.activeNav === 2)
                return root.tr("appearance")
            if (root.activeNav === 3)
                return root.tr("integrations")
            return root.tr("general")
        }

        function sectionSubtitle() {
            if (root.activeNav === 1)
                return root.tr("barHint")
            if (root.activeNav === 2)
                return root.tr("appearanceHint")
            if (root.activeNav === 3)
                return root.tr("integrationsHint")
            return root.tr("generalHint")
        }

        function themeIcon(themeId) {
            if (themeId === "dark")
                return "moon"
            if (themeId === "pywal16")
                return "display"
            return "sun"
        }

        radius: root.cornerRadius
        color: bg
        clip: true

        Rectangle {
            x: 18
            y: 18
            width: parent.width - 36
            height: parent.height - 36
            radius: 20
            color: settingsView.panel
            border.width: 1
            border.color: root.theme ? root.alpha(root.theme.borderSoft, 0.48) : Qt.rgba(1, 1, 1, 0.48)
        }

        Rectangle {
            visible: !settingsView.compact
            x: 292
            y: 34
            width: 1
            height: parent.height - 98
            color: settingsView.line
        }

        ColumnLayout {
            visible: !settingsView.compact
            x: 42
            y: 48
            width: 210
            height: parent.height - 96
            spacing: 16

            Text {
                Layout.fillWidth: true
                text: root.tr("settingsTitle")
                color: settingsView.text
                font.family: root.uiFont
                font.pixelSize: 25
                font.weight: Font.Bold
            }

            Text {
                Layout.fillWidth: true
                text: root.tr("settingsSubtitle")
                color: settingsView.textSoft
                font.family: root.uiFont
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 18
                spacing: 10

                Repeater {
                    model: root.navItems

                    SettingsNavPill {
                        required property int index
                        required property var modelData

                        Layout.fillWidth: true
                        label: root.tr("nav_" + modelData.key)
                        iconName: modelData.icon
                        active: root.activeNav === index
                        onClicked: root.activeNav = index
                    }
                }
            }

            Item { Layout.fillHeight: true }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 86
                radius: 14
                color: settingsView.panel
                border.width: 1
                border.color: settingsView.line

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        radius: 24
                        color: settingsView.panelStrong
                        border.width: 1
                        border.color: root.alpha(root.settingsLightAccent, 0.28)
                        clip: true

                        Image {
                            id: profileSidebarImage

                            readonly property string fallbackSource: Qt.resolvedUrl("../assets/profile-avatar.svg")
                            property string requestedSource: root.profileImageSource()

                            anchors.fill: parent
                            anchors.margins: 3
                            source: requestedSource
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            mipmap: true

                            onRequestedSourceChanged: source = requestedSource
                            onStatusChanged: {
                                if (status === Image.Error && source !== fallbackSource)
                                    source = fallbackSource
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text { Layout.fillWidth: true; text: "Velora Shell"; color: settingsView.text; font.family: root.uiFont; font.pixelSize: 13; font.weight: Font.Bold }
                        Text { Layout.fillWidth: true; text: root.currentLanguage(); color: settingsView.textSoft; font.family: root.uiFont; font.pixelSize: 10; elide: Text.ElideRight }
                    }
                }
            }
        }

        RowLayout {
            visible: settingsView.compact
            x: 24
            y: 74
            width: parent.width - 48
            height: 42
            spacing: 8

            Repeater {
                model: root.navItems

                RectButton {
                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    label: root.tr("nav_" + modelData.key)
                    primary: root.activeNav === index
                    onClicked: root.activeNav = index
                }
            }
        }

        RowLayout {
            x: settingsView.bodyX
            y: 46
            width: settingsView.bodyW
            height: 52
            spacing: 14

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    text: settingsView.sectionTitle()
                    color: settingsView.text
                    font.family: root.uiFont
                    font.pixelSize: 23
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: settingsView.sectionSubtitle()
                    color: settingsView.textSoft
                    font.family: root.uiFont
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }

            WindowButton { label: "×"; onClicked: root.closeRequested() }
        }

        Flickable {
            id: settingsFlick

            x: settingsView.bodyX
            y: settingsView.bodyTop
            width: settingsView.bodyW
            height: parent.height - y - 84
            contentWidth: width
            contentHeight: settingsColumn.implicitHeight + 12
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: settingsColumn

                width: settingsFlick.width
                spacing: 14

                GridLayout {
                    visible: root.activeNav === 0
                    Layout.fillWidth: true
                    columns: settingsView.contentColumns
                    columnSpacing: 14
                    rowSpacing: 14

                    SettingsCard {
                        Layout.preferredHeight: 292
                        title: root.tr("barSide")
                        subtitle: root.tr("barSideHint")

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.margins: 18
                            anchors.topMargin: 72
                            spacing: 14

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                LayoutPreviewButton {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 66
                                    side: "left"
                                    label: root.tr("layoutLeft")
                                    active: root.theme ? root.theme.barPosition === "left" : true
                                    onClicked: {
                                        if (root.theme) {
                                            root.theme.setBarPosition("left")
                                        }
                                    }
                                }

                                LayoutPreviewButton {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 66
                                    side: "right"
                                    label: root.tr("layoutRight")
                                    active: root.theme ? root.theme.barPosition === "right" : false
                                    onClicked: {
                                        if (root.theme) {
                                            root.theme.setBarPosition("right")
                                        }
                                    }
                                }
                            }

                            SettingsToggleRow {
                                Layout.fillWidth: true
                                label: root.theme && root.theme.desktopFrameEnabled ? root.tr("frameOn") : root.tr("frameOff")
                                checked: root.theme ? root.theme.desktopFrameEnabled : true
                                onClicked: if (root.theme) root.theme.setDesktopFrameEnabled(!root.theme.desktopFrameEnabled)
                            }

                            SettingsToggleRow {
                                Layout.fillWidth: true
                                label: root.tr("popupAttach")
                                checked: root.theme ? root.theme.popupAttachedToBar : true
                                onClicked: if (root.theme) root.theme.setPopupAttachedToBar(!root.theme.popupAttachedToBar)
                            }
                        }
                    }

                    SettingsCard {
                        visible: false
                        Layout.preferredHeight: 0
                        title: root.tr("integrations")
                        subtitle: root.tr("integrationsHint")

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.margins: 18
                            anchors.topMargin: 72
                            spacing: 8

                            SettingsToggleRow {
                                Layout.fillWidth: true
                                label: root.zenAutoRestart ? root.tr("zenRestartOn") : root.tr("zenRestartOff")
                                checked: root.zenAutoRestart
                                onClicked: root.setZenAutoRestart(!root.zenAutoRestart)
                            }

                            SettingsToggleRow {
                                Layout.fillWidth: true
                                label: root.webThemeBalance ? root.tr("webBalanceOn") : root.tr("webBalanceOff")
                                checked: root.webThemeBalance
                                onClicked: root.setWebThemeBalance(!root.webThemeBalance)
                            }
                        }
                    }

                    SettingsCard {
                        Layout.preferredHeight: 176
                        title: root.tr("powerMode")
                        subtitle: root.tr("powerModeHint")

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.margins: 18
                            anchors.topMargin: 72
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Repeater {
                                    model: root.powerProfileOptions()

                                    AppearanceModeButton {
                                        required property var modelData

                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 70
                                        label: modelData.label
                                        iconName: modelData.icon
                                        active: root.powerProfile === modelData.id
                                        onClicked: root.setPowerProfile(modelData.id)
                                    }
                                }
                            }
                        }
                    }

                    SettingsCard {
                        Layout.preferredHeight: 188
                        title: root.tr("language")
                        subtitle: root.tr("languageHint")

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 18
                            spacing: 14

                            Repeater {
                                model: root.languageOptions()

                                LanguageButton {
                                    required property var modelData

                                    Layout.fillWidth: true
                                    itemData: modelData
                                    active: root.currentLanguage() === modelData.id
                                    onClicked: root.selectLanguage(modelData.id)
                                }
                            }
                        }
                    }

                    SettingsCard {
                        Layout.preferredHeight: 184
                        title: root.tr("profile")
                        subtitle: root.tr("profileHint")

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 18
                            spacing: 16

                            Rectangle {
                                Layout.preferredWidth: 66
                                Layout.preferredHeight: 66
                                radius: 33
                                color: settingsView.panelStrong
                                border.width: 1
                                border.color: root.alpha(root.settingsLightAccent, 0.36)
                                clip: true

                                Image {
                                    id: profileCardImage

                                    readonly property string fallbackSource: Qt.resolvedUrl("../assets/profile-avatar.svg")
                                    property string requestedSource: root.profileImageSource()

                                    anchors.fill: parent
                                    anchors.margins: 3
                                    source: requestedSource
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                    mipmap: true

                                    onRequestedSourceChanged: source = requestedSource
                                    onStatusChanged: {
                                        if (status === Image.Error && source !== fallbackSource)
                                            source = fallbackSource
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Text {
                                    Layout.fillWidth: true
                                    text: root.tr("profilePhotoNotice")
                                    color: settingsView.textSoft
                                    font.family: root.uiFont
                                    font.pixelSize: 11
                                    wrapMode: Text.WordWrap
                                }

                                RectButton {
                                    label: root.tr("changeProfilePhoto")
                                    widthHint: 190
                                    onClicked: root.chooseProfileImage()
                                }
                            }
                        }
                    }

                    SettingsCard {
                        Layout.preferredHeight: 202
                        title: "Relógios mundiais"
                        subtitle: "Escolha os dois fusos mostrados no menu do relógio."

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 18
                            spacing: 8

                            Repeater {
                                model: 2

                                RowLayout {
                                    required property int index

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 46
                                    spacing: 10

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            Layout.fillWidth: true
                                            text: root.worldClockItems[index] ? root.worldClockItems[index].label : "—"
                                            color: settingsView.text
                                            font.family: root.uiFont
                                            font.pixelSize: 12
                                            font.weight: Font.Bold
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: root.worldClockItems[index] ? root.worldClockItems[index].zone : ""
                                            color: settingsView.textSoft
                                            font.family: root.monoFont
                                            font.pixelSize: 9
                                            elide: Text.ElideRight
                                        }
                                    }

                                    RectButton {
                                        label: "‹"
                                        widthHint: 42
                                        onClicked: root.cycleWorldClock(index, -1)
                                    }

                                    RectButton {
                                        label: "›"
                                        widthHint: 42
                                        onClicked: root.cycleWorldClock(index, 1)
                                    }
                                }
                            }
                        }
                    }

                }

                GridLayout {
                    visible: root.activeNav === 2
                    Layout.fillWidth: true
                    columns: settingsView.contentColumns
                    columnSpacing: 14
                    rowSpacing: 14

                    SettingsCard {
                        Layout.preferredHeight: 220
                        title: root.tr("themeStyle")
                        subtitle: root.tr("appearanceHint")

                        GridLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 18
                            columns: settingsView.bodyW > 900 ? 5 : 3
                            columnSpacing: 10
                            rowSpacing: 10

                            Repeater {
                                model: root.themeOptions()

                                AppearanceModeButton {
                                    required property var modelData

                                    Layout.fillWidth: true
                                    label: modelData.title
                                    iconName: settingsView.themeIcon(modelData.id)
                                    active: root.currentThemeId() === modelData.id
                                    onClicked: root.selectTheme(modelData.id)
                                }
                            }
                        }
                    }

                    SettingsCard {
                        Layout.preferredHeight: 254
                        title: root.tr("fonts")
                        subtitle: root.theme && !root.theme.fontSelectionActive ? root.tr("fontJapaneseLocked") : root.tr("fontsHint")

                        GridLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 18
                            columns: settingsView.bodyW > 900 ? 3 : 2
                            columnSpacing: 9
                            rowSpacing: 9

                            Repeater {
                                model: root.fontOptions()

                                FontChoiceButton {
                                    required property var modelData

                                    Layout.fillWidth: true
                                    label: modelData.label
                                    familyName: modelData.family
                                    active: root.theme ? root.theme.fontFamilyId === modelData.id : modelData.id === "noto"
                                    enabled: root.theme ? root.theme.fontSelectionActive : true
                                    onClicked: if (root.theme && root.theme.fontSelectionActive) root.theme.setFontFamily(modelData.id)
                                }
                            }
                        }
                    }

                    SettingsCard {
                        Layout.preferredHeight: 322
                        title: root.tr("opacity")
                        subtitle: root.tr("codeOpacityHint")

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 18
                            spacing: 10

                            SettingsSlider {
                                Layout.fillWidth: true
                                label: root.tr("frameOpacity")
                                minValue: root.theme ? root.theme.minPanelOpacity() : 0.25
                                maxValue: 0.98
                                value: root.theme ? root.theme.sidebarOpacity : 0.78
                                onMoved: function(v) { if (root.theme) root.theme.applyOpacity(v, root.theme.popupOpacity, root.theme.cardOpacity) }
                            }

                            SettingsSlider {
                                Layout.fillWidth: true
                                label: root.tr("popupOpacity")
                                minValue: root.theme ? root.theme.minPanelOpacity() : 0.25
                                maxValue: 0.98
                                value: root.theme ? root.theme.popupOpacity : 0.78
                                onMoved: function(v) { if (root.theme) root.theme.applyOpacity(root.theme.sidebarOpacity, v, root.theme.cardOpacity) }
                            }

                            SettingsSlider {
                                Layout.fillWidth: true
                                label: root.tr("opacityCard")
                                minValue: root.theme ? root.theme.minOpacityForRole("card") : 0.25
                                maxValue: 0.98
                                value: root.theme ? root.theme.cardOpacity : 0.68
                                onMoved: function(v) { if (root.theme) root.theme.applyOpacity(root.theme.sidebarOpacity, root.theme.popupOpacity, v) }
                            }

                            SettingsSlider {
                                Layout.fillWidth: true
                                label: root.tr("barOpacity")
                                minValue: root.theme ? root.theme.minOpacityForRole("sidebar") : 0.25
                                maxValue: 0.98
                                value: root.theme ? root.theme.barOpacity : 0.78
                                onMoved: function(v) { if (root.theme) root.theme.applyBarOpacity(v) }
                            }

                            SettingsSlider {
                                Layout.fillWidth: true
                                label: root.tr("codeOpacity")
                                minValue: 0.60
                                maxValue: 0.98
                                value: root.codeOpacity
                                onMoved: function(v) { root.setCodeOpacity(v) }
                            }
                        }
                    }

                    SettingsCard {
                        Layout.preferredHeight: 146
                        title: root.tr("popups")
                        subtitle: root.tr("popupBubblesHint")

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 18
                            spacing: 8

                            SettingsToggleRow {
                                Layout.fillWidth: true
                                label: root.theme && root.theme.popupBubblesSolid ? root.tr("popupBubblesSolid") : root.tr("popupBubblesMatched")
                                checked: root.theme ? root.theme.popupBubblesSolid : false
                                onClicked: if (root.theme) root.theme.setPopupBubblesSolid(!root.theme.popupBubblesSolid)
                            }
                        }
                    }

                    SettingsCard {
                        visible: false
                        Layout.preferredHeight: 0
                        title: root.tr("glow")
                        subtitle: root.tr("appearanceHint")

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 18
                            spacing: 10

                            SettingsSlider {
                                Layout.fillWidth: true
                                label: root.tr("glowGeneral")
                                value: root.theme ? root.theme.generalGlow : 0.50
                                onMoved: function(v) { if (root.theme) root.theme.applyGlow(v, root.theme.sidebarBorderGlowLevel, root.theme.popupBorderGlowLevel, root.theme.iconGlowLevel, root.theme.textGlowLevel) }
                            }

                            SettingsSlider {
                                Layout.fillWidth: true
                                label: root.tr("borderGlow")
                                value: root.theme ? root.theme.sidebarBorderGlowLevel : 0.50
                                onMoved: function(v) { if (root.theme) root.theme.applyGlow(root.theme.generalGlow, v, v, root.theme.iconGlowLevel, root.theme.textGlowLevel) }
                            }

                            SettingsSlider {
                                Layout.fillWidth: true
                                label: root.tr("iconGlow")
                                value: root.theme ? root.theme.iconGlowLevel : 0.50
                                onMoved: function(v) { if (root.theme) root.theme.applyGlow(root.theme.generalGlow, root.theme.sidebarBorderGlowLevel, root.theme.popupBorderGlowLevel, v, root.theme.textGlowLevel) }
                            }

                            SettingsSlider {
                                Layout.fillWidth: true
                                label: root.tr("fontGlow")
                                value: root.theme ? root.theme.textGlowLevel : 0.78
                                onMoved: function(v) { if (root.theme) root.theme.applyTextGlow(v) }
                            }
                        }
                    }

                    SettingsCard {
                        Layout.preferredHeight: 210
                        title: root.tr("border")
                        subtitle: root.tr("adapt")

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 18
                            spacing: 16

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                BorderAdaptButton {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 42
                                    active: root.theme ? root.theme.borderAdaptEnabled : true
                                    onClicked: if (root.theme) root.theme.applyBorderAccent(true, root.theme.borderHue)
                                }

                                RectButton {
                                    Layout.fillWidth: true
                                    label: root.tr("reset")
                                    onClicked: if (root.theme) root.theme.resetBorderAccent()
                                }
                            }

                            BorderPaletteWheel {
                                Layout.preferredWidth: 104
                                Layout.preferredHeight: 104
                            }
                        }
                    }
                }

                GridLayout {
                    visible: root.activeNav === root.visualizerNavIndex()
                    Layout.fillWidth: true
                    columns: settingsView.contentColumns
                    columnSpacing: 14
                    rowSpacing: 14

                    SettingsCard {
                        Layout.preferredHeight: 322
                        title: root.tr("barOptions")
                        subtitle: root.tr("barOptionsHint")

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 18
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                SettingsSlider {
                                    Layout.fillWidth: true
                                    label: root.tr("barWidth")
                                    minValue: 88
                                    maxValue: 136
                                    value: root.theme ? root.theme.barWidth : 112
                                    valueText: Math.round(displayValue) + " px"
                                    disabled: false
                                    onMoved: function(v) { if (root.theme) root.theme.setBarWidth(v, false) }
                                    onCommitted: function(v) { if (root.theme) root.theme.setBarWidth(v, true) }
                                }

                                RectButton {
                                    Layout.preferredWidth: 72
                                    Layout.preferredHeight: 38
                                    Layout.alignment: Qt.AlignBottom
                                    label: root.tr("reset")
                                    enabled: true
                                    opacity: enabled ? 1 : 0.42
                                    onClicked: if (root.theme) root.theme.resetBarWidth()
                                }
                            }

                            SettingsToggleRow {
                                Layout.fillWidth: true
                                label: root.theme && root.theme.barLabelsVisible ? root.tr("barTitlesOn") : root.tr("barTitlesOff")
                                checked: root.theme ? root.theme.barLabelsVisible : true
                                onClicked: if (root.theme) root.theme.setBarLabelsVisible(!root.theme.barLabelsVisible)
                            }

                            SettingsToggleRow {
                                Layout.fillWidth: true
                                label: root.theme && root.theme.barBlurEnabled ? root.tr("barBlurOn") : root.tr("barBlurOff")
                                checked: root.theme ? root.theme.barBlurEnabled : true
                                onClicked: if (root.theme) root.theme.setBarBlurEnabled(!root.theme.barBlurEnabled)
                            }

                            SettingsToggleRow {
                                Layout.fillWidth: true
                                label: root.theme && root.theme.frameBlurEnabled ? root.tr("frameBlurOn") : root.tr("frameBlurOff")
                                checked: root.theme ? root.theme.frameBlurEnabled : true
                                onClicked: if (root.theme) root.theme.setFrameBlurEnabled(!root.theme.frameBlurEnabled)
                            }

                            SettingsToggleRow {
                                Layout.fillWidth: true
                                label: root.tr("popupAttach")
                                checked: root.theme ? root.theme.popupAttachedToBar : true
                                onClicked: if (root.theme) root.theme.setPopupAttachedToBar(!root.theme.popupAttachedToBar)
                            }
                        }
                    }

                    SettingsCard {
                        Layout.preferredHeight: 176
                        title: root.tr("barFrameOpacity")
                        subtitle: root.tr("barFrameOpacityHint")

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 18
                            spacing: 10

                            SettingsSlider {
                                Layout.fillWidth: true
                                label: root.tr("barOpacity")
                                minValue: root.theme ? root.theme.minOpacityForRole("sidebar") : 0.25
                                maxValue: 0.98
                                value: root.theme ? root.theme.barOpacity : 0.88
                                onMoved: function(v) { if (root.theme) root.theme.applyBarOpacity(v) }
                            }

                            SettingsSlider {
                                Layout.fillWidth: true
                                label: root.tr("frameOpacity")
                                minValue: root.theme ? root.theme.minOpacityForRole("sidebar") : 0.25
                                maxValue: 0.98
                                value: root.theme ? root.theme.sidebarOpacity : 0.88
                                onMoved: function(v) { if (root.theme) root.theme.applyOpacity(v, root.theme.popupOpacity, root.theme.cardOpacity) }
                            }
                        }
                    }

                    SettingsCard {
                        Layout.preferredHeight: 262
                        title: root.tr("barGlow")
                        subtitle: root.tr("barGlowHint")

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 18
                            spacing: 10

                            SettingsSlider {
                                Layout.fillWidth: true
                                label: root.tr("barGlow")
                                value: root.theme ? root.theme.generalGlow : 0.50
                                onMoved: function(v) { if (root.theme) root.theme.applyGlow(v, root.theme.sidebarBorderGlowLevel, root.theme.popupBorderGlowLevel, root.theme.iconGlowLevel, root.theme.textGlowLevel) }
                            }

                            SettingsSlider {
                                Layout.fillWidth: true
                                label: root.tr("borderGlow")
                                value: root.theme ? root.theme.sidebarBorderGlowLevel : 0.50
                                onMoved: function(v) { if (root.theme) root.theme.applyGlow(root.theme.generalGlow, v, v, root.theme.iconGlowLevel, root.theme.textGlowLevel) }
                            }

                            SettingsSlider {
                                Layout.fillWidth: true
                                label: root.tr("iconGlow")
                                value: root.theme ? root.theme.iconGlowLevel : 0.50
                                onMoved: function(v) { if (root.theme) root.theme.applyGlow(root.theme.generalGlow, root.theme.sidebarBorderGlowLevel, root.theme.popupBorderGlowLevel, v, root.theme.textGlowLevel) }
                            }

                            SettingsSlider {
                                Layout.fillWidth: true
                                label: root.tr("fontGlow")
                                value: root.theme ? root.theme.textGlowLevel : 0.78
                                onMoved: function(v) { if (root.theme) root.theme.applyTextGlow(v) }
                            }
                        }
                    }

                    SettingsCard {
                        Layout.preferredHeight: 186
                        title: root.tr("visualizerMode")
                        subtitle: root.tr("visualizerModeHint")

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.margins: 18
                            anchors.topMargin: 72
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Repeater {
                                    model: root.visualizerModeOptions()

                                    AppearanceModeButton {
                                        required property var modelData

                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 78
                                        label: modelData.label
                                        iconName: modelData.icon
                                        active: root.theme ? root.theme.visualizerMode === modelData.id : modelData.id === "wave"
                                        onClicked: if (root.theme) root.theme.setVisualizerMode(modelData.id)
                                    }
                                }
                            }
                        }
                    }

                    SettingsCard {
                        Layout.preferredHeight: 330
                        title: root.tr("visualizer")
                        subtitle: root.tr("visualizerHint")

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 18
                            spacing: 10

                            SettingsSlider {
                                Layout.fillWidth: true
                                label: root.tr("visualizerStrength")
                                minValue: 0
                                maxValue: 0.90
                                value: root.theme ? root.theme.visualizerStrength : 0.46
                                onMoved: function(v) { if (root.theme) root.theme.setVisualizerStrength(v) }
                            }

                            SettingsSlider {
                                Layout.fillWidth: true
                                label: root.tr("visualizerPixelSize")
                                minValue: 3
                                maxValue: 12
                                value: root.theme ? root.theme.visualizerPixelSize : 7
                                valueText: Math.round(root.theme ? root.theme.visualizerPixelSize : 7) + " px"
                                onMoved: function(v) { if (root.theme) root.theme.setVisualizerPixelSize(v) }
                            }

                            SettingsToggleRow {
                                Layout.fillWidth: true
                                label: root.theme && root.theme.visualizerGradientEnabled ? root.tr("visualizerGradientOn") : root.tr("visualizerGradientOff")
                                checked: root.theme ? root.theme.visualizerGradientEnabled : true
                                onClicked: if (root.theme) root.theme.setVisualizerGradientEnabled(!root.theme.visualizerGradientEnabled)
                            }
                        }
                    }

                    SettingsCard {
                        Layout.columnSpan: settingsView.contentColumns
                        Layout.preferredHeight: 382
                        title: root.tr("wallpaperMotion")
                        subtitle: root.tr("wallpaperMotionHint")

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 18
                            spacing: 10

                            GridLayout {
                                Layout.fillWidth: true
                                columns: settingsView.bodyW > 900 ? 6 : 3
                                columnSpacing: 8
                                rowSpacing: 8

                                Repeater {
                                    model: root.wallpaperTransitionOptions()

                                    TransitionButton {
                                        required property var modelData

                                        Layout.fillWidth: true
                                        label: modelData.label
                                        active: root.wallpaperTransition === modelData.id
                                        onClicked: root.setWallpaperTransition(modelData.id)
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.tr("wallpaperLiveTransition")
                                color: root.settingsLightText
                                font.family: root.uiFont
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Repeater {
                                    model: root.wallpaperLiveTransitionOptions()

                                    TransitionButton {
                                        required property var modelData

                                        Layout.fillWidth: true
                                        label: modelData.label
                                        active: root.wallpaperLiveTransition === modelData.id
                                        onClicked: root.setWallpaperLiveTransition(modelData.id)
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.tr("wallpaperLiveTransitionHint")
                                color: root.settingsLightText
                                font.family: root.uiFont
                                font.pixelSize: 10
                                wrapMode: Text.WordWrap
                            }

                            SettingsSlider {
                                Layout.fillWidth: true
                                label: root.tr("transitionDuration")
                                minValue: 0.15
                                maxValue: 3.00
                                value: root.wallpaperTransitionDuration
                                valueText: root.secondsText(root.wallpaperTransitionDuration)
                                onMoved: function(v) { root.setWallpaperTransitionDuration(v) }
                            }

                            SettingsSlider {
                                Layout.fillWidth: true
                                label: root.tr("staticDelay")
                                minValue: 0
                                maxValue: 0.80
                                value: root.wallpaperStaticDelay
                                valueText: root.secondsText(root.wallpaperStaticDelay)
                                onMoved: function(v) { root.setWallpaperStaticDelay(v) }
                            }
                        }
                    }
                }

                GridLayout {
                    visible: root.activeNav === root.wallpaperNavIndex()
                    Layout.fillWidth: true
                    columns: settingsView.contentColumns
                    columnSpacing: 14
                    rowSpacing: 14

                    SettingsCard {
                        Layout.columnSpan: settingsView.contentColumns
                        Layout.preferredHeight: 654
                        title: root.tr("wallpaper")
                        subtitle: root.tr("wallpaperHint")

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.margins: 18
                            anchors.topMargin: 72
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                Repeater {
                                    model: Math.min(5, root.wallpapers.length)

                                    WallpaperMini {
                                        required property int index

                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 104
                                        source: root.contentActive && root.scanComplete ? root.displaySource(root.wallpapers[index]) : ""
                                        selected: root.selectedIndex === index
                                        onClicked: root.selectedIndex = index
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 52
                                radius: 10
                                color: Qt.rgba(1, 1, 1, 0.38)
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: root.currentWallpaperPreview()
                                    fillMode: Image.PreserveAspectCrop
                                    opacity: 0.55
                                    asynchronous: true
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.tr("wallpaperTransition")
                                color: root.settingsLightText
                                font.family: root.uiFont
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: settingsView.bodyW > 900 ? 6 : 3
                                columnSpacing: 8
                                rowSpacing: 8

                                Repeater {
                                    model: root.wallpaperTransitionOptions()

                                    TransitionButton {
                                        required property var modelData

                                        Layout.fillWidth: true
                                        label: modelData.label
                                        active: root.wallpaperTransition === modelData.id
                                        onClicked: root.setWallpaperTransition(modelData.id)
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.tr("wallpaperLiveTransition")
                                color: root.settingsLightText
                                font.family: root.uiFont
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Repeater {
                                    model: root.wallpaperLiveTransitionOptions()

                                    TransitionButton {
                                        required property var modelData

                                        Layout.fillWidth: true
                                        label: modelData.label
                                        active: root.wallpaperLiveTransition === modelData.id
                                        onClicked: root.setWallpaperLiveTransition(modelData.id)
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.tr("wallpaperLiveTransitionHint")
                                color: root.settingsLightText
                                font.family: root.uiFont
                                font.pixelSize: 10
                                wrapMode: Text.WordWrap
                            }

                            SettingsToggleRow {
                                Layout.fillWidth: true
                                label: root.terminalStrongColors ? root.tr("terminalStrongColorsOn") : root.tr("terminalStrongColorsOff")
                                checked: root.terminalStrongColors
                                onClicked: root.setTerminalStrongColors(!root.terminalStrongColors)
                            }

                            SettingsSlider {
                                Layout.fillWidth: true
                                label: root.tr("transitionDuration")
                                minValue: 0.15
                                maxValue: 3.00
                                value: root.wallpaperTransitionDuration
                                valueText: root.secondsText(root.wallpaperTransitionDuration)
                                onMoved: function(v) { root.setWallpaperTransitionDuration(v) }
                            }

                            SettingsSlider {
                                Layout.fillWidth: true
                                label: root.tr("staticDelay")
                                minValue: 0
                                maxValue: 0.80
                                value: root.wallpaperStaticDelay
                                valueText: root.secondsText(root.wallpaperStaticDelay)
                                onMoved: function(v) { root.setWallpaperStaticDelay(v) }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                RectButton {
                                    label: root.tr("customWallpaper")
                                    widthHint: 220
                                    onClicked: {
                                        root.noticeText = root.tr("wallpaperFolderOpened")
                                        noticeReset.restart()
                                        if (!customWallpaperChooser.running)
                                            customWallpaperChooser.running = true
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                RectButton {
                                    label: applyWallpaper.running ? root.tr("applying") : root.tr("apply")
                                    widthHint: 132
                                    primary: true
                                    onClicked: root.applySelected()
                                }
                            }
                        }
                    }
                }

                GridLayout {
                    visible: root.activeNav === 3
                    Layout.fillWidth: true
                    columns: settingsView.contentColumns
                    columnSpacing: 14
                    rowSpacing: 14

                    SettingsCard {
                        Layout.preferredHeight: 200
                        title: root.tr("integrationOptions")
                        subtitle: root.tr("integrationsHint")

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 18
                            spacing: 8

                            SettingsToggleRow {
                                Layout.fillWidth: true
                                label: root.zenAutoRestart ? root.tr("zenRestartOn") : root.tr("zenRestartOff")
                                checked: root.zenAutoRestart
                                onClicked: root.setZenAutoRestart(!root.zenAutoRestart)
                            }

                            SettingsToggleRow {
                                Layout.fillWidth: true
                                label: root.webThemeBalance ? root.tr("webBalanceOn") : root.tr("webBalanceOff")
                                checked: root.webThemeBalance
                                onClicked: root.setWebThemeBalance(!root.webThemeBalance)
                            }
                        }
                    }

                    SettingsCard {
                        Layout.preferredHeight: 166
                        title: root.tr("codeOpacity")
                        subtitle: root.tr("codeOpacityHint")

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 18
                            spacing: 10

                            SettingsSlider {
                                Layout.fillWidth: true
                                label: root.tr("codeOpacity")
                                minValue: 0.60
                                maxValue: 0.98
                                value: root.codeOpacity
                                onMoved: function(v) { root.setCodeOpacity(v) }
                            }
                        }
                    }
                }

                GridLayout {
                    visible: root.activeNav === root.languageNavIndex()
                    Layout.fillWidth: true
                    columns: 1

                    SettingsCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 188
                        title: root.tr("language")
                        subtitle: root.tr("languageHint")

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 18
                            spacing: 14

                            Repeater {
                                model: root.languageOptions()

                                LanguageButton {
                                    required property var modelData

                                    Layout.fillWidth: true
                                    itemData: modelData
                                    active: root.currentLanguage() === modelData.id
                                    onClicked: root.selectLanguage(modelData.id)
                                }
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            x: settingsView.bodyX
            y: parent.height - 58
            width: settingsView.bodyW
            height: 40
            spacing: 14

            RectButton {
                label: root.tr("reset")
                widthHint: 110
                onClicked: {
                    if (root.theme) {
                        root.theme.resetOpacity()
                        root.theme.resetGlow()
                        root.theme.resetBorderAccent()
                        root.theme.resetVisualizerStrength()
                    }
                    root.noticeText = root.tr("materialReset")
                    noticeReset.restart()
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.noticeText.length > 0 ? root.noticeText : (root.theme && root.theme.themeNotice.length > 0 ? root.theme.themeNotice : "")
                color: settingsView.textSoft
                font.family: root.uiFont
                font.pixelSize: 11
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            RectButton { label: "OK"; widthHint: 86; primary: true; onClicked: root.closeRequested() }
        }
    }

    component SettingsNavPill: Rectangle {
        id: pill

        property string label: ""
        property string iconName: "box"
        property bool active: false
        property bool hovered: false
        signal clicked()

        Layout.preferredHeight: 50
        radius: 11
        color: active
            ? (root.theme ? root.alpha(root.theme.activeBg, Math.max(0.34, root.theme.activeBg.a)) : Qt.rgba(0.96, 0.72, 0.88, 0.32))
            : (hovered ? (root.theme ? root.alpha(root.theme.hoverBg, Math.max(0.20, root.theme.hoverBg.a)) : Qt.rgba(1, 1, 1, 0.28)) : "transparent")
        border.width: active || hovered ? 1 : 0
        border.color: root.theme ? root.alpha(root.theme.borderActive, active ? 0.40 : 0.22) : Qt.rgba(0.90, 0.52, 0.74, 0.24)
        scale: navMouse.pressed ? 0.98 : (hovered ? 1.01 : 1.0)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 14
            spacing: 12
            SmallIcon { Layout.preferredWidth: 18; Layout.preferredHeight: 18; iconName: parent.parent.iconName; colorOverride: parent.parent.active ? root.settingsLightAccent : root.settingsLightTextSoft }
            Text { Layout.fillWidth: true; text: parent.parent.label; color: parent.parent.active ? root.settingsLightAccent : root.settingsLightTextSoft; font.family: root.uiFont; font.pixelSize: 13; font.weight: Font.DemiBold }
        }

        MouseArea {
            id: navMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: pill.hovered = true
            onExited: pill.hovered = false
            onClicked: pill.clicked()
        }
    }

    component SettingsCard: Rectangle {
        property string title: ""
        property string subtitle: ""

        Layout.fillWidth: true
        Layout.fillHeight: false
        Layout.preferredHeight: 190
        Layout.minimumHeight: 170
        radius: 13
        color: root.theme ? root.theme.mix(root.theme.surfaceCard, root.theme.accentPrimary, root.pywalStyle ? 0.10 : 0.04, root.theme.themeMode === "dark" ? 0.58 : 0.64) : Qt.rgba(1, 1, 1, 0.46)
        border.width: 1
        border.color: root.theme ? root.alpha(root.theme.borderSoft, root.theme.themeMode === "dark" ? 0.42 : 0.48) : Qt.rgba(0.38, 0.28, 0.50, 0.08)

        Text { x: 18; y: 18; width: parent.width - 36; text: parent.title; color: root.settingsLightText; font.family: root.uiFont; font.pixelSize: 14; font.weight: Font.Bold; elide: Text.ElideRight }
        Text { x: 18; y: 44; width: parent.width - 36; text: parent.subtitle; color: root.settingsLightTextSoft; font.family: root.uiFont; font.pixelSize: 11; elide: Text.ElideRight }
    }

    component ComboField: Rectangle {
        property string label: ""
        property string iconName: "box"

        height: 42
        radius: 8
        color: Qt.rgba(1, 1, 1, 0.40)
        border.width: 1
        border.color: Qt.rgba(0.36, 0.26, 0.50, 0.12)
        RowLayout { anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
            SmallIcon { Layout.preferredWidth: 18; Layout.preferredHeight: 18; iconName: parent.parent.iconName; colorOverride: root.settingsLightTextSoft }
            Text { Layout.fillWidth: true; text: parent.parent.label; color: root.settingsLightText; font.family: root.uiFont; font.pixelSize: 12 }
            Text { text: "⌄"; color: root.settingsLightTextSoft; font.pixelSize: 17 }
        }
    }

    component SettingsToggleRow: Rectangle {
        id: toggleRow

        property string label: ""
        property bool checked: false
        property string buttonLabel: ""
        property bool hovered: false
        signal clicked()

        Layout.preferredHeight: 42
        radius: 8
        color: hovered ? Qt.rgba(1, 1, 1, 0.24) : "transparent"
        Text { anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: parent.label; color: root.settingsLightText; font.family: root.uiFont; font.pixelSize: 12 }
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: parent.buttonLabel.length > 0 ? 52 : 38
            height: 24
            radius: 12
            color: parent.buttonLabel.length > 0 ? Qt.rgba(0.95, 0.68, 0.86, 0.22) : (parent.checked ? root.settingsLightAccent : Qt.rgba(0.50, 0.43, 0.57, 0.14))
            Text { anchors.centerIn: parent; visible: parent.parent.buttonLabel.length > 0; text: parent.parent.buttonLabel; color: root.settingsLightAccent; font.family: root.uiFont; font.pixelSize: 10; font.weight: Font.Bold }
            Rectangle { visible: parent.parent.buttonLabel.length <= 0; x: parent.parent.checked ? parent.width - width - 3 : 3; anchors.verticalCenter: parent.verticalCenter; width: 18; height: 18; radius: 9; color: "white" }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: toggleRow.hovered = true
            onExited: toggleRow.hovered = false
            onClicked: toggleRow.clicked()
        }
    }

    component SettingsSlider: Item {
        id: settingsSlider

        property string label: ""
        property real value: 0.5
        property real minValue: 0
        property real maxValue: 1
        property string valueText: ""
        property bool disabled: false
        property bool dragging: false
        property real dragValue: value
        signal moved(real value)
        signal committed(real value)

        readonly property real displayValue: dragging ? dragValue : value
        readonly property real normalizedValue: Math.max(0, Math.min(1, (displayValue - minValue) / Math.max(0.01, maxValue - minValue)))

        Layout.preferredHeight: label.length > 0 ? 42 : 24
        implicitHeight: label.length > 0 ? 42 : 24
        height: implicitHeight
        opacity: disabled ? 0.42 : 1

        function valueFromX(xPos) {
            return minValue + Math.max(0, Math.min(1, xPos / Math.max(1, width))) * (maxValue - minValue)
        }

        function previewAt(xPos) {
            dragValue = valueFromX(xPos)
            moved(dragValue)
        }

        Text {
            visible: settingsSlider.label.length > 0
            anchors.left: parent.left
            anchors.top: parent.top
            text: settingsSlider.label
            color: root.settingsLightText
            font.family: root.uiFont
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        Text {
            visible: settingsSlider.label.length > 0
            anchors.right: parent.right
            anchors.top: parent.top
            text: settingsSlider.valueText.length > 0 ? settingsSlider.valueText : root.percent(settingsSlider.normalizedValue)
            color: root.settingsLightTextSoft
            font.family: root.monoFont
            font.pixelSize: 10
        }

        Rectangle {
            id: sliderTrack

            anchors.left: parent.left
            anchors.right: parent.right
            y: settingsSlider.label.length > 0 ? 28 : Math.round((parent.height - height) / 2)
            height: 5
            radius: 3
            color: Qt.rgba(0.50, 0.42, 0.58, 0.14)
        }

        Rectangle { anchors.left: sliderTrack.left; anchors.verticalCenter: sliderTrack.verticalCenter; width: sliderTrack.width * settingsSlider.normalizedValue; height: sliderTrack.height; radius: 3; color: root.settingsLightAccent }
        Rectangle { x: sliderTrack.x + sliderTrack.width * settingsSlider.normalizedValue - width / 2; anchors.verticalCenter: sliderTrack.verticalCenter; width: 18; height: 18; radius: 9; color: root.settingsLightAccent }
        MouseArea {
            anchors.fill: parent
            enabled: !settingsSlider.disabled
            preventStealing: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPressed: function(mouse) {
                settingsSlider.dragging = true
                settingsSlider.dragValue = settingsSlider.value
                settingsSlider.previewAt(mouse.x)
            }
            onPositionChanged: function(mouse) {
                if (pressed)
                    settingsSlider.previewAt(mouse.x)
            }
            onReleased: function(mouse) {
                settingsSlider.previewAt(mouse.x)
                const finalValue = settingsSlider.dragValue
                settingsSlider.dragging = false
                settingsSlider.committed(finalValue)
            }
            onCanceled: settingsSlider.dragging = false
        }
    }

    component AppearanceModeButton: Rectangle {
        property string label: ""
        property string iconName: "sun"
        property bool active: false
        signal clicked()

        Layout.preferredHeight: 78
        radius: 9
        color: active ? Qt.rgba(0.98, 0.78, 0.91, 0.30) : Qt.rgba(1, 1, 1, 0.28)
        border.width: 1
        border.color: active ? Qt.rgba(0.91, 0.48, 0.72, 0.44) : Qt.rgba(0.37, 0.26, 0.50, 0.10)
        ColumnLayout { anchors.centerIn: parent; spacing: 8
            SmallIcon { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 24; Layout.preferredHeight: 24; iconName: parent.parent.iconName; colorOverride: parent.parent.active ? root.settingsLightAccent : root.settingsLightTextSoft }
            Text { text: parent.parent.label; color: parent.parent.active ? root.settingsLightAccent : root.settingsLightText; font.family: root.uiFont; font.pixelSize: 12; font.weight: Font.DemiBold }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
    }

    component FontChoiceButton: Rectangle {
        id: button

        property string label: ""
        property string familyName: root.uiFont
        property bool active: false
        property bool hovered: false
        signal clicked()

        Layout.preferredHeight: 48
        radius: 8
        opacity: enabled ? 1 : 0.48
        color: active ? Qt.rgba(0.98, 0.78, 0.91, 0.30) : (hovered ? Qt.rgba(1, 1, 1, 0.34) : Qt.rgba(1, 1, 1, 0.24))
        border.width: 1
        border.color: active ? Qt.rgba(0.91, 0.48, 0.72, 0.44) : Qt.rgba(0.37, 0.26, 0.50, 0.10)

        Text {
            anchors.centerIn: parent
            width: parent.width - 16
            text: button.label
            color: button.active ? root.settingsLightAccent : root.settingsLightText
            font.family: button.familyName
            font.pixelSize: 12
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        MouseArea {
            anchors.fill: parent
            enabled: button.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: button.hovered = true
            onExited: button.hovered = false
            onClicked: button.clicked()
        }
    }

    component TransitionButton: Rectangle {
        id: button

        property string label: ""
        property bool active: false
        property bool hovered: false
        signal clicked()

        Layout.preferredHeight: 34
        radius: 8
        color: active ? Qt.rgba(0.98, 0.78, 0.91, 0.30) : (hovered ? Qt.rgba(1, 1, 1, 0.34) : Qt.rgba(1, 1, 1, 0.24))
        border.width: 1
        border.color: active ? Qt.rgba(0.91, 0.48, 0.72, 0.44) : Qt.rgba(0.37, 0.26, 0.50, 0.10)

        Text {
            anchors.centerIn: parent
            width: parent.width - 12
            text: button.label
            color: button.active ? root.settingsLightAccent : root.settingsLightText
            font.family: root.uiFont
            font.pixelSize: 11
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: button.hovered = true
            onExited: button.hovered = false
            onClicked: button.clicked()
        }
    }

    component RectButton: Rectangle {
        property string label: ""
        property bool primary: false
        property int widthHint: 92
        signal clicked()

        Layout.preferredWidth: widthHint
        Layout.preferredHeight: 40
        radius: 8
        color: primary ? root.accentPrimary() : Qt.rgba(1, 1, 1, 0.52)
        border.width: primary ? 0 : 1
        border.color: Qt.rgba(0.36, 0.26, 0.50, 0.10)
        Text { anchors.centerIn: parent; width: parent.width - 12; text: parent.label; color: parent.primary ? "white" : Qt.rgba(0.31, 0.25, 0.43, 0.92); font.family: root.uiFont; font.pixelSize: 12; font.weight: Font.Bold; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
    }

    component WindowButton: Rectangle {
        property string label: ""
        signal clicked()
        Layout.preferredWidth: 42
        Layout.preferredHeight: 34
        radius: 8
        color: Qt.rgba(1, 1, 1, 0.36)
        border.width: 1
        border.color: Qt.rgba(0.36, 0.26, 0.50, 0.08)
        Text { anchors.centerIn: parent; text: parent.label; color: Qt.rgba(0.31, 0.25, 0.43, 0.82); font.family: root.uiFont; font.pixelSize: 14 }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
    }

    component LayoutPreviewButton: Rectangle {
        id: button

        property string side: "left"
        property string label: ""
        property bool active: false
        property bool hovered: false
        readonly property bool rightSide: side === "right"
        readonly property bool topSide: side === "top"
        signal clicked()

        height: 58
        radius: 10
        color: active
            ? root.c("activeBg", Qt.rgba(0.92, 0.62, 0.78, 0.28))
            : (hovered ? root.c("hoverBg", Qt.rgba(0.92, 0.62, 0.78, 0.14)) : root.alpha(root.c("surfaceCard", Qt.rgba(1, 1, 1, 0.68)), 0.30))
        border.width: 1
        border.color: active
            ? root.c("borderActive", Qt.rgba(0.90, 0.56, 0.74, 0.72))
            : root.alpha(root.c("borderSoft", Qt.rgba(1, 1, 1, 0.68)), 0.52)
        antialiasing: true
        scale: previewMouse.pressed ? 0.97 : (hovered ? 1.012 : 1.0)

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

        Rectangle {
            id: previewScreen

            anchors {
                fill: parent
                margins: 9
            }

            radius: 6
            color: root.alpha(root.c("surfaceBase", Qt.rgba(1, 1, 1, 0.72)), 0.36)
            border.width: 1
            border.color: root.alpha(root.c("borderSoft", Qt.rgba(1, 1, 1, 0.68)), 0.38)
            clip: true
            antialiasing: true

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: 4
                color: "transparent"
                border.width: 1
                border.color: root.alpha(root.c("borderSoft", Qt.rgba(1, 1, 1, 0.68)), 0.22)
                antialiasing: true
            }

            Rectangle {
                width: button.topSide ? parent.width - 12 : 13
                height: button.topSide ? 8 : parent.height - 8
                x: button.topSide ? 6 : (button.rightSide ? parent.width - width - 4 : 4)
                y: button.topSide ? 4 : 4
                radius: 6
                color: root.alpha(root.c("surfaceSidebar", Qt.rgba(1, 1, 1, 0.78)), button.active ? 0.96 : 0.74)
                border.width: 1
                border.color: button.active ? root.accentPrimary() : root.alpha(root.c("borderSoft", Qt.rgba(1, 1, 1, 0.68)), 0.46)
                antialiasing: true

                Column {
                    visible: !button.topSide
                    anchors.centerIn: parent
                    spacing: 3

                    Repeater {
                        model: 4

                        Rectangle {
                            width: 5
                            height: 5
                            radius: 2.5
                            color: index === 0 ? root.accentPrimary() : root.alpha(root.c("textSecondary", "#8d7ca3"), 0.55)
                        }
                    }
                }
            }

            Rectangle {
                x: button.topSide ? 13 : (button.rightSide ? 6 : 21)
                y: button.topSide ? 18 : 9
                width: button.topSide ? Math.max(10, parent.width - 26) : Math.max(10, parent.width - 34)
                height: 3
                radius: 2
                color: root.alpha(root.c("textSecondary", "#8d7ca3"), 0.22)
            }

            Rectangle {
                x: button.topSide ? 13 : (button.rightSide ? 6 : 21)
                y: button.topSide ? 26 : 17
                width: button.topSide ? Math.max(10, parent.width - 34) : Math.max(10, parent.width - 44)
                height: button.topSide ? 9 : 18
                radius: 4
                color: root.alpha(root.accentSecondary(), button.active ? 0.24 : 0.12)
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 5
            text: button.label
            color: button.active ? root.c("textPrimary", "#4d3f63") : root.c("textSecondary", "#8d7ca3")
            font.family: root.uiFont
            font.pixelSize: 9
            font.weight: Font.Bold
            elide: Text.ElideRight
            width: parent.width - 12
            horizontalAlignment: Text.AlignHCenter
            layer.enabled: root.fontGlowEnabled()
            layer.effect: FontGlowEffect {}
        }

        MouseArea {
            id: previewMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: button.hovered = true
            onExited: button.hovered = false
            onClicked: button.clicked()
        }
    }

    component LayoutToggleButton: Rectangle {
        id: button

        property string label: ""
        property bool active: false
        property bool hovered: false
        signal clicked()

        height: 42
        radius: 9
        color: active
            ? root.c("activeBg", Qt.rgba(0.92, 0.62, 0.78, 0.28))
            : (hovered ? root.c("hoverBg", Qt.rgba(0.92, 0.62, 0.78, 0.14)) : root.alpha(root.c("surfaceCard", Qt.rgba(1, 1, 1, 0.68)), 0.34))
        border.width: 1
        border.color: active
            ? root.c("borderActive", Qt.rgba(0.90, 0.56, 0.74, 0.72))
            : root.alpha(root.c("borderSoft", Qt.rgba(1, 1, 1, 0.68)), 0.52)
        antialiasing: true
        scale: clickArea.pressed ? 0.97 : (hovered ? 1.012 : 1.0)

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

        Text {
            anchors.centerIn: parent
            text: button.label
            color: button.active ? root.c("textPrimary", "#4d3f63") : root.c("textSecondary", "#8d7ca3")
            font.family: root.uiFont
            font.pixelSize: 11
            font.weight: Font.Bold
            layer.enabled: root.fontGlowEnabled()
            layer.effect: FontGlowEffect {}
        }

        MouseArea {
            id: clickArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: button.hovered = true
            onExited: button.hovered = false
            onClicked: button.clicked()
        }
    }

    component LanguageButton: Rectangle {
        id: button

        property var itemData
        property bool active: false
        property bool hovered: false
        signal clicked()

        height: 72
        radius: 10
        color: active
            ? root.c("activeBg", Qt.rgba(0.92, 0.62, 0.78, 0.28))
            : (hovered ? root.c("hoverBg", Qt.rgba(0.92, 0.62, 0.78, 0.14)) : root.alpha(root.c("surfaceCard", Qt.rgba(1, 1, 1, 0.68)), 0.32))
        border.width: 1
        border.color: active
            ? root.c("borderActive", Qt.rgba(0.90, 0.56, 0.74, 0.72))
            : root.alpha(root.c("borderSoft", Qt.rgba(1, 1, 1, 0.68)), 0.52)
        antialiasing: true
        scale: languageMouse.pressed ? 0.97 : (hovered ? 1.012 : 1.0)

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

        Rectangle {
            x: 12
            y: 14
            width: 34
            height: 34
            radius: 17
            color: button.active ? root.alpha(root.accentPrimary(), 0.32) : root.alpha(root.c("surfaceInput", Qt.rgba(1, 1, 1, 0.58)), 0.52)
            border.width: 1
            border.color: button.active ? root.accentPrimary() : root.alpha(root.c("borderSoft", Qt.rgba(1, 1, 1, 0.68)), 0.48)
            antialiasing: true

            Text {
                anchors.centerIn: parent
                text: button.itemData.shortLabel || ""
                color: button.active ? root.accentPrimary() : root.c("textSecondary", "#8d7ca3")
                font.family: root.monoFont
                font.pixelSize: 11
                font.weight: Font.Bold
                layer.enabled: root.fontGlowEnabled()
                layer.effect: FontGlowEffect {}
            }
        }

        Text {
            x: 56
            y: 18
            width: parent.width - x - 12
            text: button.itemData.label || ""
            color: button.active ? root.c("textPrimary", "#4d3f63") : root.c("textSecondary", "#8d7ca3")
            font.family: root.uiFont
            font.pixelSize: 13
            font.weight: Font.Bold
            elide: Text.ElideRight
            layer.enabled: root.fontGlowEnabled()
            layer.effect: FontGlowEffect {}
        }

        MouseArea {
            id: languageMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: button.hovered = true
            onExited: button.hovered = false
            onClicked: button.clicked()
        }
    }

    component OpacityControl: Rectangle {
        id: control

        property string label: ""
        property real value: 0.70
        property real minValue: 0.25
        property real maxValue: 0.95
        signal moved(real value)

        height: 42
        radius: 9
        color: root.alpha(root.c("surfaceCard", Qt.rgba(1, 1, 1, 0.68)), 0.34)
        border.width: 1
        border.color: root.alpha(root.c("borderSoft", Qt.rgba(1, 1, 1, 0.68)), 0.52)
        antialiasing: true

        function valueFromX(xPos) {
            const span = Math.max(0.01, maxValue - minValue)
            return Math.max(minValue, Math.min(maxValue, minValue + (xPos - track.x) / Math.max(1, track.width) * span))
        }

        Text {
            x: 10
            y: 7
            text: control.label
            color: root.c("textPrimary", "#4d3f63")
            font.family: root.uiFont
            font.pixelSize: 10
            font.weight: Font.Bold
            layer.enabled: root.fontGlowEnabled()
            layer.effect: FontGlowEffect {}
        }

        Text {
            anchors {
                right: parent.right
                rightMargin: 10
                top: parent.top
                topMargin: 7
            }

            text: root.percent(control.value)
            color: root.c("textMuted", "#b7a9c7")
            font.family: root.monoFont
            font.pixelSize: 10
            font.weight: Font.Medium
            layer.enabled: root.fontGlowEnabled()
            layer.effect: FontGlowEffect {}
        }

        Rectangle {
            id: track

            x: 10
            y: 28
            width: parent.width - 20
            height: 4
            radius: 2
            color: root.alpha(root.c("textSecondary", "#8d7ca3"), 0.18)
        }

        Rectangle {
            x: track.x
            y: track.y
            width: Math.round(track.width * Math.max(0, Math.min(1, (control.value - control.minValue) / Math.max(0.01, control.maxValue - control.minValue))))
            height: track.height
            radius: track.radius
            color: root.accentPrimary()
        }

        Rectangle {
            x: Math.round(track.x + track.width * Math.max(0, Math.min(1, (control.value - control.minValue) / Math.max(0.01, control.maxValue - control.minValue))) - width / 2)
            y: track.y - 5
            width: 14
            height: 14
            radius: 7
            color: root.c("buttonPrimaryText", "#ffffff")
            border.width: 1
            border.color: root.alpha(root.accentPrimary(), 0.72)
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: function(mouse) {
                mouse.accepted = true
                control.moved(control.valueFromX(mouse.x))
            }
            onPositionChanged: function(mouse) {
                if (pressed) {
                    mouse.accepted = true
                    control.moved(control.valueFromX(mouse.x))
                }
            }
        }
    }

    component BorderAdaptButton: Rectangle {
        id: button

        property bool active: true
        property bool hovered: false
        signal clicked()

        height: 42
        radius: 10
        color: active
            ? root.c("activeBg", Qt.rgba(0.92, 0.62, 0.78, 0.28))
            : (hovered ? root.c("hoverBg", Qt.rgba(0.92, 0.62, 0.78, 0.14)) : root.alpha(root.c("surfaceCard", Qt.rgba(1, 1, 1, 0.68)), 0.30))
        border.width: 1
        border.color: active && root.theme ? root.theme.sidebarBorderGlow : root.alpha(root.c("borderSoft", Qt.rgba(1, 1, 1, 0.68)), 0.52)
        antialiasing: true

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

        Text {
            anchors.centerIn: parent
            text: root.tr("adapt")
            color: root.c("textPrimary", "#4d3f63")
            font.family: root.uiFont
            font.pixelSize: 11
            font.weight: Font.Bold
            layer.enabled: root.fontGlowEnabled()
            layer.effect: FontGlowEffect {}
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: button.hovered = true
            onExited: button.hovered = false
            onClicked: button.clicked()
        }
    }

    component BorderPaletteWheel: Item {
        id: wheel

        readonly property real selectedHue: root.theme ? root.theme.borderHue : 0.55
        readonly property color selectedColor: root.theme ? root.theme.sidebarBorderGlow : root.accentPrimary()
        readonly property real centerX: width / 2
        readonly property real centerY: height / 2
        readonly property real outerRadius: Math.min(width, height) / 2 - 3
        readonly property real dotRadius: outerRadius * 0.78

        function applyFromPoint(xPos, yPos) {
            if (!root.theme)
                return

            const dx = xPos - centerX
            const dy = yPos - centerY
            const hue = (Math.atan2(dy, dx) / (Math.PI * 2) + 1) % 1
            root.theme.applyBorderAccent(false, hue)
        }

        Canvas {
            id: wheelCanvas

            anchors.fill: parent
            antialiasing: true

            onPaint: {
                const ctx = getContext("2d")
                const cx = width / 2
                const cy = height / 2
                const r = Math.min(width, height) / 2 - 3
                ctx.clearRect(0, 0, width, height)

                for (let i = 0; i < 96; i += 1) {
                    const start = i / 96 * Math.PI * 2
                    const end = (i + 1.4) / 96 * Math.PI * 2
                    ctx.beginPath()
                    ctx.moveTo(cx, cy)
                    ctx.arc(cx, cy, r, start, end)
                    ctx.closePath()
                    ctx.fillStyle = root.theme ? root.theme.hsvColor(i / 96, 0.82, 1.0, 1) : Qt.rgba(1, 1, 1, 1)
                    ctx.fill()
                }

                ctx.beginPath()
                ctx.arc(cx, cy, r * 0.38, 0, Math.PI * 2)
                ctx.fillStyle = root.alpha(root.c("surfaceCard", Qt.rgba(1, 1, 1, 0.68)), 0.58)
                ctx.fill()
            }
        }

        Rectangle {
            x: Math.round(wheel.centerX + Math.cos(wheel.selectedHue * Math.PI * 2) * wheel.dotRadius - width / 2)
            y: Math.round(wheel.centerY + Math.sin(wheel.selectedHue * Math.PI * 2) * wheel.dotRadius - height / 2)
            width: 14
            height: 14
            radius: 7
            color: wheel.selectedColor
            border.width: 2
            border.color: root.c("buttonPrimaryText", "#ffffff")
            antialiasing: true
        }

        Rectangle {
            anchors.centerIn: parent
            width: 24
            height: 24
            radius: 12
            color: root.theme && root.theme.borderAdaptEnabled ? root.theme.accentPrimary : wheel.selectedColor
            border.width: 2
            border.color: root.alpha(root.c("buttonPrimaryText", Qt.rgba(1, 1, 1, 1)), 0.84)
            antialiasing: true
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: function(mouse) {
                mouse.accepted = true
                wheel.applyFromPoint(mouse.x, mouse.y)
            }
            onPositionChanged: function(mouse) {
                if (pressed) {
                    mouse.accepted = true
                    wheel.applyFromPoint(mouse.x, mouse.y)
                }
            }
        }

        Connections {
            target: root.theme
            function onBorderHueChanged() { wheelCanvas.requestPaint() }
            function onBorderAdaptEnabledChanged() { wheelCanvas.requestPaint() }
            function onAccentPrimaryChanged() { wheelCanvas.requestPaint() }
        }

        Component.onCompleted: wheelCanvas.requestPaint()
        onWidthChanged: wheelCanvas.requestPaint()
        onHeightChanged: wheelCanvas.requestPaint()
    }

    component SettingsNavItem: Rectangle {
        id: item

        property var itemData
        property bool active: false
        property bool hovered: false
        signal clicked()

        height: 54
        radius: 8
        scale: hovered ? 1.006 : 1.0
        transform: Translate {
            x: item.hovered || item.active ? 1 : 0
        }
        color: active
            ? root.alpha(root.c("activeBg", Qt.rgba(0.92, 0.62, 0.78, 0.28)), 0.58)
            : (hovered ? root.alpha(root.c("hoverBg", Qt.rgba(0.92, 0.62, 0.78, 0.14)), 0.36) : "transparent")
        border.width: 1
        border.color: active
            ? root.alpha(root.c("borderActive", Qt.rgba(0.90, 0.56, 0.74, 0.45)), 0.62)
            : (hovered ? root.alpha(root.accentPrimary(), 0.18) : "transparent")
        antialiasing: true
        layer.enabled: false
        layer.effect: DropShadow {
            transparentBorder: true
            radius: hovered ? 24 : 17
            samples: hovered ? 49 : 35
            horizontalOffset: 0
            verticalOffset: hovered ? 7 : 4
            color: root.alpha(root.c("shadowColor", Qt.rgba(0.28, 0.20, 0.34, 1)), hovered ? 0.20 : 0.12)
        }

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            x: 16
            spacing: 12

            SmallIcon {
                width: 21
                height: 21
                iconName: item.itemData.icon
                colorOverride: item.active
                    ? root.accentPrimary()
                    : root.c("textSecondary", "#8d7ca3")
            }

            Text {
                width: item.width - 52
                text: root.tr("nav_" + item.itemData.key)
                color: item.active ? root.c("textPrimary", "#4d3f63") : root.c("textSecondary", "#8d7ca3")
                font.family: root.uiFont
                font.pixelSize: 13
                font.weight: Font.Bold
                elide: Text.ElideRight
                layer.enabled: root.fontGlowEnabled()
                layer.effect: FontGlowEffect {}
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: item.hovered = true
            onExited: item.hovered = false
            onClicked: item.clicked()
        }
    }

    component ThemeCard: Item {
        id: card

        property var itemData
        property bool selected: false
        property bool hovered: false
        signal clicked()

        scale: mouse.pressed ? 0.96 : (hovered ? 1.012 : 1.0)
        transformOrigin: Item.Center

        Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

        Rectangle {
            id: preview

            width: parent.width
            height: 86
            radius: 8
            color: root.c("surfaceCard", Qt.rgba(1, 1, 1, 0.68))
            border.width: card.selected ? 2 : 1
            border.color: card.selected
                ? root.c("borderActive", Qt.rgba(0.90, 0.56, 0.74, 0.76))
                : root.c("borderSoft", Qt.rgba(1, 1, 1, 0.58))
            clip: true
            antialiasing: true
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                radius: card.hovered || card.selected ? 18 : 10
                samples: card.hovered || card.selected ? 37 : 21
                horizontalOffset: 0
                verticalOffset: card.hovered || card.selected ? 7 : 4
                color: root.c("shadowColor", Qt.rgba(0.46, 0.28, 0.48, card.hovered || card.selected ? 0.14 : 0.07))
            }

            Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

            ThemePreview {
                anchors.fill: parent
                anchors.margins: 7
                kind: card.itemData.preview
            }

            Rectangle {
                visible: card.selected
                anchors {
                    right: parent.right
                    top: parent.top
                    rightMargin: -5
                    topMargin: -5
                }

                width: 26
                height: 26
                radius: 13
                color: root.accentPrimary()
                border.width: 1
                border.color: root.alpha(root.c("borderSoft", Qt.rgba(1, 1, 1, 0.65)), 0.86)

                CheckIcon {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    colorOverride: root.c("buttonPrimaryText", "#ffffff")
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 96
            text: card.itemData.title
            color: card.selected ? root.accentPrimary() : root.c("textPrimary", "#4d3f63")
            font.family: root.uiFont
            font.pixelSize: 12
            font.weight: Font.Bold
            layer.enabled: root.fontGlowEnabled()
            layer.effect: FontGlowEffect {}
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: card.hovered = true
            onExited: card.hovered = false
            onClicked: card.clicked()
        }
    }

    component WallpaperMini: Rectangle {
        id: card

        property string source: ""
        property bool selected: false
        property bool hovered: false
        signal clicked()

        radius: 8
        color: root.c("surfaceCard", Qt.rgba(1, 1, 1, 0.68))
        border.width: selected ? 2 : 1
        border.color: selected
            ? root.c("borderActive", Qt.rgba(0.90, 0.56, 0.74, 0.78))
            : root.c("borderSoft", Qt.rgba(1, 1, 1, 0.52))
        clip: true
        antialiasing: true
        scale: mouse.pressed ? 0.97 : (hovered ? 1.012 : 1.0)
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            radius: hovered || selected ? 18 : 10
            samples: hovered || selected ? 37 : 21
            horizontalOffset: 0
            verticalOffset: hovered || selected ? 7 : 4
            color: root.c("shadowColor", Qt.rgba(0.38, 0.25, 0.44, hovered || selected ? 0.13 : 0.06))
        }

        Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

        Image {
            anchors.fill: parent
            anchors.margins: 1
            source: root.contentActive ? card.source : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 260
            sourceSize.height: 170
            asynchronous: true
            smooth: true
            mipmap: true
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: hovered ? root.alpha(root.c("surfaceCard", Qt.rgba(1, 1, 1, 0.68)), 0.12) : "transparent"
        }

        Rectangle {
            visible: selected
            anchors {
                right: parent.right
                top: parent.top
                rightMargin: -5
                topMargin: -5
            }

            width: 26
            height: 26
            radius: 13
            color: root.accentPrimary()
            border.width: 1
            border.color: root.alpha(root.c("borderSoft", Qt.rgba(1, 1, 1, 0.65)), 0.84)

            CheckIcon {
                anchors.centerIn: parent
                width: 12
                height: 12
                colorOverride: root.c("buttonPrimaryText", "#ffffff")
            }
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: card.hovered = true
            onExited: card.hovered = false
            onClicked: card.clicked()
        }
    }

    component ThemePreview: Item {
        id: preview

        property string kind: "default"
        readonly property color baseColor: kind === "dark"
            ? Qt.rgba(0.12, 0.11, 0.16, 1)
            : kind === "pink"
                ? Qt.rgba(1, 0.82, 0.90, 1)
                : kind === "lavender"
                    ? Qt.rgba(0.88, 0.82, 1, 1)
                    : kind === "pywal16"
                        ? Qt.rgba(0.92, 0.94, 0.98, 1)
                        : Qt.rgba(1, 0.96, 0.99, 1)

        Rectangle {
            anchors.fill: parent
            radius: 6
            color: preview.baseColor
        }

        Repeater {
            model: preview.kind === "pywal16" ? ["#e8a6c8", "#c894f2", "#a8d8ff", "#f4c56f", "#8fd6b8", "#6f7ea9"] : []

            Rectangle {
                required property int index
                required property string modelData

                x: 10 + (index % 3) * 23
                y: 13 + Math.floor(index / 3) * 24
                width: 17
                height: 17
                radius: 5
                color: modelData
            }
        }

        Rectangle {
            visible: preview.kind !== "pywal16"
            x: 10
            y: 12
            width: 21
            height: 52
            radius: 6
            color: preview.kind === "dark" ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.55)
        }

        Repeater {
            model: preview.kind !== "pywal16" ? 4 : 0

            Rectangle {
                required property int index

                x: 42 + (index % 2) * 28
                y: 14 + Math.floor(index / 2) * 25
                width: 22
                height: 18
                radius: 5
                color: preview.kind === "dark"
                    ? Qt.rgba(1, 1, 1, 0.12)
                    : Qt.rgba(1, 1, 1, 0.68)
                border.width: 1
                border.color: preview.kind === "pink"
                    ? Qt.rgba(0.95, 0.50, 0.70, 0.22)
                    : preview.kind === "lavender"
                        ? Qt.rgba(0.58, 0.42, 0.88, 0.22)
                        : Qt.rgba(1, 1, 1, 0.28)
            }
        }

        Text {
            visible: preview.kind === "pywal16"
            anchors {
                right: parent.right
                bottom: parent.bottom
                rightMargin: 8
                bottomMargin: 7
            }

            text: "auto"
            color: root.c("textSecondary", "#8d7ca3")
            font.family: root.monoFont
            font.pixelSize: 9
            font.weight: Font.Bold
        }
    }

    component SmallIcon: Canvas {
        id: icon

        property string iconName: "palette"
        property color colorOverride: root.c("textSecondary", "#8d7ca3")

        antialiasing: true
        onPaint: {
            const ctx = getContext("2d")
            const w = width
            const h = height
            const s = Math.min(w, h)
            const cx = w / 2
            const cy = h / 2
            ctx.reset()
            ctx.strokeStyle = colorOverride
            ctx.fillStyle = colorOverride
            ctx.lineWidth = Math.max(1.4, s * 0.09)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            if (iconName === "palette") {
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.36, Math.PI * 0.15, Math.PI * 1.95, false)
                ctx.quadraticCurveTo(s * 0.34, s * 0.92, s * 0.44, s * 0.67)
                ctx.stroke()
                for (let i = 0; i < 3; i += 1) {
                    ctx.beginPath()
                    ctx.arc(s * (0.35 + i * 0.15), s * (0.38 + (i % 2) * 0.12), s * 0.035, 0, Math.PI * 2)
                    ctx.fill()
                }
            } else if (iconName === "image" || iconName === "folder") {
                ctx.strokeRect(s * 0.14, s * 0.24, s * 0.72, s * 0.52)
                ctx.beginPath()
                ctx.moveTo(s * 0.20, s * 0.66)
                ctx.lineTo(s * 0.38, s * 0.50)
                ctx.lineTo(s * 0.52, s * 0.62)
                ctx.lineTo(s * 0.68, s * 0.44)
                ctx.lineTo(s * 0.82, s * 0.66)
                ctx.stroke()
            } else if (iconName === "puzzle") {
                ctx.strokeRect(s * 0.22, s * 0.24, s * 0.52, s * 0.52)
                ctx.beginPath()
                ctx.arc(s * 0.50, s * 0.24, s * 0.10, 0, Math.PI * 2)
                ctx.stroke()
            } else if (iconName === "cursor") {
                ctx.beginPath()
                ctx.moveTo(s * 0.22, s * 0.14)
                ctx.lineTo(s * 0.70, s * 0.54)
                ctx.lineTo(s * 0.48, s * 0.60)
                ctx.lineTo(s * 0.38, s * 0.82)
                ctx.closePath()
                ctx.stroke()
            } else if (iconName === "font") {
                ctx.beginPath()
                ctx.moveTo(s * 0.24, s * 0.76)
                ctx.lineTo(s * 0.46, s * 0.22)
                ctx.lineTo(s * 0.68, s * 0.76)
                ctx.moveTo(s * 0.34, s * 0.56)
                ctx.lineTo(s * 0.58, s * 0.56)
                ctx.stroke()
            } else if (iconName === "language") {
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.35, 0, Math.PI * 2)
                ctx.moveTo(cx - s * 0.35, cy)
                ctx.lineTo(cx + s * 0.35, cy)
                ctx.moveTo(cx, cy - s * 0.35)
                ctx.bezierCurveTo(cx - s * 0.16, cy - s * 0.12, cx - s * 0.16, cy + s * 0.12, cx, cy + s * 0.35)
                ctx.moveTo(cx, cy - s * 0.35)
                ctx.bezierCurveTo(cx + s * 0.16, cy - s * 0.12, cx + s * 0.16, cy + s * 0.12, cx, cy + s * 0.35)
                ctx.stroke()
            } else if (iconName === "sun") {
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.16, 0, Math.PI * 2)
                ctx.stroke()
                for (let j = 0; j < 8; j += 1) {
                    const a = j / 8 * Math.PI * 2
                    ctx.beginPath()
                    ctx.moveTo(cx + Math.cos(a) * s * 0.28, cy + Math.sin(a) * s * 0.28)
                    ctx.lineTo(cx + Math.cos(a) * s * 0.40, cy + Math.sin(a) * s * 0.40)
                    ctx.stroke()
                }
            } else if (iconName === "moon") {
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.30, Math.PI * 0.35, Math.PI * 1.70)
                ctx.quadraticCurveTo(s * 0.62, s * 0.56, s * 0.69, s * 0.28)
                ctx.stroke()
            } else if (iconName === "wifi") {
                for (let i = 0; i < 3; i += 1) {
                    ctx.beginPath()
                    ctx.arc(cx, cy + s * 0.20, s * (0.16 + i * 0.13), Math.PI * 1.18, Math.PI * 1.82)
                    ctx.stroke()
                }
                ctx.beginPath()
                ctx.arc(cx, cy + s * 0.22, s * 0.035, 0, Math.PI * 2)
                ctx.fill()
            } else if (iconName === "battery") {
                ctx.strokeRect(s * 0.23, s * 0.30, s * 0.48, s * 0.42)
                ctx.strokeRect(s * 0.40, s * 0.22, s * 0.14, s * 0.08)
            } else if (iconName === "bluetooth") {
                ctx.beginPath()
                ctx.moveTo(cx, s * 0.18)
                ctx.lineTo(s * 0.68, s * 0.34)
                ctx.lineTo(cx, s * 0.50)
                ctx.lineTo(s * 0.68, s * 0.66)
                ctx.lineTo(cx, s * 0.82)
                ctx.lineTo(cx, s * 0.18)
                ctx.moveTo(cx, s * 0.50)
                ctx.lineTo(s * 0.32, s * 0.34)
                ctx.moveTo(cx, s * 0.50)
                ctx.lineTo(s * 0.32, s * 0.66)
                ctx.stroke()
            } else if (iconName === "volume") {
                ctx.beginPath()
                ctx.moveTo(s * 0.18, s * 0.44)
                ctx.lineTo(s * 0.32, s * 0.44)
                ctx.lineTo(s * 0.52, s * 0.28)
                ctx.lineTo(s * 0.52, s * 0.72)
                ctx.lineTo(s * 0.32, s * 0.56)
                ctx.lineTo(s * 0.18, s * 0.56)
                ctx.closePath()
                ctx.stroke()
            } else if (iconName === "bell") {
                ctx.beginPath()
                ctx.moveTo(s * 0.30, s * 0.64)
                ctx.lineTo(s * 0.70, s * 0.64)
                ctx.quadraticCurveTo(s * 0.64, s * 0.54, s * 0.64, s * 0.42)
                ctx.quadraticCurveTo(s * 0.64, s * 0.25, cx, s * 0.25)
                ctx.quadraticCurveTo(s * 0.36, s * 0.25, s * 0.36, s * 0.42)
                ctx.quadraticCurveTo(s * 0.36, s * 0.54, s * 0.30, s * 0.64)
                ctx.stroke()
            } else if (iconName === "clock" || iconName === "calendar") {
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.32, 0, Math.PI * 2)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(cx, cy)
                ctx.lineTo(cx, s * 0.32)
                ctx.moveTo(cx, cy)
                ctx.lineTo(s * 0.62, s * 0.58)
                ctx.stroke()
            } else if (iconName === "display" || iconName === "box" || iconName === "memo" || iconName === "lock" || iconName === "home" || iconName === "globe") {
                ctx.strokeRect(s * 0.22, s * 0.26, s * 0.56, s * 0.44)
                ctx.beginPath()
                ctx.moveTo(s * 0.36, s * 0.80)
                ctx.lineTo(s * 0.64, s * 0.80)
                ctx.stroke()
            }
        }

        onColorOverrideChanged: requestPaint()
        onIconNameChanged: requestPaint()
    }

    component CheckIcon: Canvas {
        id: check

        property color colorOverride: "white"

        antialiasing: true
        onPaint: {
            const ctx = getContext("2d")
            const s = Math.min(width, height)
            ctx.reset()
            ctx.strokeStyle = colorOverride
            ctx.lineWidth = Math.max(1.7, s * 0.16)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.beginPath()
            ctx.moveTo(s * 0.18, s * 0.52)
            ctx.lineTo(s * 0.40, s * 0.72)
            ctx.lineTo(s * 0.82, s * 0.25)
            ctx.stroke()
        }

        onColorOverrideChanged: requestPaint()
    }
}
