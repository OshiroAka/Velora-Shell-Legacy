import QtQuick
import Quickshell
import Quickshell.Io
import "services/VeloraSettingsTranslations.js" as VeloraSettingsTranslations

Item {
    id: root

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
    property bool scanComplete: false
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
    readonly property bool busy: (blurControl.running && hyprlandBlurBusy) || applyWallpaper.running || powerProfileSet.running || zenModeSave.running || webThemeModeSave.running || zenThemeReload.running || codeOpacitySave.running || wallpaperTransitionSave.running || wallpaperLiveTransitionSave.running || terminalStrongColorsSave.running || terminalThemeApply.running || velyricsSettingsSave.running || worldClockSave.running
    property var composition: null
    property var config: null
    property string activePage: ""
    property var loadedDomains: ({})
    property string operationError: ""
    property bool active: false
    signal closeRequested()
    signal lyricsMaskEditorRequested()
    onActivePageChanged: if (active) ensureLoaded()
    onActiveChanged: {
        if (active) ensureLoaded()
        else cancelReads()
    }
    function cancelReads() {
        if (!hyprlandBlurBusy) blurControl.running = false
        loadedDomains = ({})
        noticeReset.stop()
        for (const process of [powerProfileLoad, zenModeLoad, webThemeModeLoad,
                codeOpacityLoad, wallpaperTransitionLoad, wallpaperLiveTransitionLoad,
                terminalStrongColorsLoad, velyricsSettingsLoad, velyricsFontsLoad,
                worldClockLoad, scanWallpapers]) process.running = false
    }
    function setWallpaperSelectorGlass(enabled) {
        if (config) config.setValue("desktop.wallpaperSelectorGlassEnabled", !!enabled)
        else if (composition) composition.setWallpaperSelectorGlass(!!enabled)
    }
    readonly property bool wallpaperSelectorGlassEnabled: config
        ? config.wallpaperSelectorGlassEnabled
        : !!composition && composition.wallpaperSelectorGlassEnabled
    function operationFinished(code, detail) {
        if (code === 0) operationError = ""
        if (code !== 0) operationError = String(detail || "Não foi possível salvar a alteração.").trim()
        noticeText = code === 0 ? "Salvo" : operationError
        if (active) noticeReset.restart()
    }
    property int hyprlandBlurState: -1
    property string hyprlandBlurError: ""
    property bool hyprlandBlurBusy: false
    function refreshHyprlandBlur() {
        if (blurControl.running) return
        blurControl.command = ["python3", Quickshell.shellDir + "/scripts/hyprland-blur", "get"]
        blurControl.running = true
    }
    function setHyprlandBlur(enabled) {
        if (blurControl.running) return
        hyprlandBlurBusy = true
        hyprlandBlurError = ""
        blurControl.command = ["python3", Quickshell.shellDir + "/scripts/hyprland-blur", "set", enabled ? "on" : "off"]
        blurControl.running = true
    }
    Process {
        id: blurControl
        stdout: StdioCollector { id: blurOutput }
        stderr: StdioCollector { id: blurErrors }
        onExited: function(code) {
            const saving = root.hyprlandBlurBusy
            root.hyprlandBlurBusy = false
            if (code === 0) {
                root.hyprlandBlurState = blurOutput.text.trim() === "on" ? 1 : 0
                root.hyprlandBlurError = ""
            } else root.hyprlandBlurError = blurErrors.text.trim() || "Não foi possível consultar ou alterar o blur do Hyprland."
            if (saving) root.operationFinished(code, root.hyprlandBlurError)
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

        root.operationError = ""
        root.noticeText = "Salvando…"
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
        root.operationError = ""
        root.noticeText = "Salvando…"
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
        root.operationError = ""
        root.noticeText = "Salvando…"
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

        root.operationError = ""
        root.noticeText = "Salvando…"
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



    function applySelected() {
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

        root.operationError = ""
        root.noticeText = "Salvando…"
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

        root.operationError = ""
        root.noticeText = "Salvando…"
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

        root.operationError = ""
        root.noticeText = "Salvando…"
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
        root.operationError = ""
        root.noticeText = "Salvando…"
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
        root.velyricsSyncOffsetMs = Math.max(0, Math.min(1500, Number(value === undefined ? 500 : value)))
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
        root.operationError = ""
        root.noticeText = "Salvando…"
        noticeReset.restart()
    }

    function reload() {
        if (!scanWallpapers.running)
            scanWallpapers.running = true
    }

    function ensureLoaded() {
        const domain = activePage
        if (!active || !domain || loadedDomains[domain]) return
        const next = Object.assign({}, loadedDomains); next[domain] = true; loadedDomains = next
        if (domain === "wallpapers") {
            reload()
            wallpaperTransitionLoad.running = true
            wallpaperLiveTransitionLoad.running = true
        } else if (domain === "system") {
            refreshHyprlandBlur()
            powerProfileLoad.running = true
            zenModeLoad.running = true
            webThemeModeLoad.running = true
            codeOpacityLoad.running = true
            terminalStrongColorsLoad.running = true
            worldClockLoad.running = true
        } else if (domain === "velyrics") {
            velyricsSettingsLoad.running = true
            velyricsFontsLoad.running = true
        }
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
        stderr: StdioCollector { id: applyWallpaperErrors }
        onExited: function(exitCode) {
            root.operationFinished(exitCode, applyWallpaperErrors.text)
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
        stderr: StdioCollector { id: powerProfileSetErrors }
        onExited: function(exitCode) {
            root.operationFinished(exitCode, powerProfileSetErrors.text)
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
        stderr: StdioCollector { id: zenModeSaveErrors }
        onExited: function(exitCode) {
            root.operationFinished(exitCode, zenModeSaveErrors.text)
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
        stderr: StdioCollector { id: webThemeModeSaveErrors }
        onExited: function(exitCode) {
            root.operationFinished(exitCode, webThemeModeSaveErrors.text)
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
        stderr: StdioCollector { id: zenThemeReloadErrors }
        onExited: function(exitCode) { running = false; root.operationFinished(exitCode, zenThemeReloadErrors.text) }
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
        stderr: StdioCollector { id: codeOpacitySaveErrors }
        onExited: function(exitCode) {
            root.operationFinished(exitCode, codeOpacitySaveErrors.text)
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
        stderr: StdioCollector { id: wallpaperTransitionSaveErrors }
        onExited: function(exitCode) {
            root.operationFinished(exitCode, wallpaperTransitionSaveErrors.text)
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
        stderr: StdioCollector { id: wallpaperLiveTransitionSaveErrors }
        onExited: function(exitCode) {
            root.operationFinished(exitCode, wallpaperLiveTransitionSaveErrors.text)
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
        stderr: StdioCollector { id: terminalStrongColorsSaveErrors }
        onExited: function(exitCode) {
            root.operationFinished(exitCode, terminalStrongColorsSaveErrors.text)
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
        stderr: StdioCollector { id: terminalThemeApplyErrors }
        onExited: function(exitCode) {
            root.operationFinished(exitCode, terminalThemeApplyErrors.text)
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
        stderr: StdioCollector { id: velyricsSettingsSaveErrors }
        onExited: function(exitCode) {
            root.operationFinished(exitCode, velyricsSettingsSaveErrors.text)
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
        stderr: StdioCollector { id: worldClockSaveErrors }
        onExited: function(exitCode) {
            root.operationFinished(exitCode, worldClockSaveErrors.text)
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


}
