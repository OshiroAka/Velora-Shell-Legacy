import QtQuick
import Quickshell
import Quickshell.Io
import "TopBarOrder.js" as TopBarOrder

Scope {
    id: root

    readonly property int supportedSchemaVersion: 8
    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || homeDir + "/.config"
    readonly property string configDir: configHome + "/velora-shell"
    readonly property string configPath: configDir + "/config.json"

    property bool ready: false
    readonly property bool referenceAppearance: true
    property string error: ""
    property string saveError: ""
    property bool savePending: false
    function retrySave() { savePending = true; saveTimer.restart() }
    property var defaultsData: ({})
    property var userData: ({})

    property string localeName: "system"
    property bool reducedMotion: false
    property string motionPreset: "balanced"
    property bool intelligentContrast: true
    property bool reduceTransparency: false
    property string visualStyle: "classic"
    property string colorScheme: "dark"
    property string materialMode: "glass"
    property real surfaceOpacity: 0.82
    property real blurStrength: 0.55
    property real appearanceContrast: 1.08
    property real reflectionStrength: 0.35
    property string accentMode: "wallpaper"
    property string pywalTone: "auto"
    property color accentColor: "#c8788f"
    property var customColors: ({
        accent: "#c8788f", bar: "#171a22", icons: "#f4f4f6",
        widgets: "#171a22", text: "#edf1ff", panels: "#11141b"
    })
    property bool characterPywal: false
    property bool waterCausticsEnabled: true
    property real waterCausticsIntensity: 0.32
    property bool waterCausticsLines: true
    property bool waterCausticsModules: false
    property string lockDimmingMode: "off"
    property real lockDimmingAmount: 0.28
    property bool topbarEnabled: true
    property bool topbarOneThingEnabled: true
    property bool topbarNotesEnabled: true
    property var topbarToolsOrder: TopBarOrder.defaults()
    property bool desktopWidgetsEnabled: true
    property bool desktopVisualizerEnabled: true
    property bool wallpaperBlurEnabled: false
    property real wallpaperBlurStrength: 0.35
    property real wallpaperDimming: 0
    property bool wallpaperSelectorGlassEnabled: true
    property bool widgetBlurEnabled: true
    property string systemName: "Velora Shell"
    property real topbarHeight: 40
    property real topbarScale: 1
    property real topbarGap: 4
    property real topbarMargin: 8
    property string barMaterial: "glass"
    property string liquidGlassStyle: "frosted"
    property bool barBlurEnabled: true
    property real barOpacity: 0.52
    property real barWaveStrength: 0.28
    // Shared Desktop/Lock widgets can either be fully opaque or consume the
    // exact same material tokens as the unified L-shaped bar.
    property string widgetSurfaceMode: "solid"
    property var topbarLayout: []
    property string profileName: "Velora"
    property string greeting: "Welcome back!!"
    property string verticalLabel: "VELORA SHELL"
    property string avatarPath: ""
    property string characterPath: ""
    property real characterScale: 1.0
    property real characterOffsetX: 0
    property real characterOffsetY: 0
    property bool characterFlipX: false
    property real clockOffsetX: 0
    property real clockOffsetY: 0
    property real clockScale: 1.0
    property real greetingOffsetX: 0
    property real greetingOffsetY: 0
    property real greetingFontSize: 25
    property real verticalLabelOffsetX: 0
    property real verticalLabelOffsetY: 0
    property real verticalLabelFontSize: 19
    property var galleryPaths: []
    property var galleryScales: []
    property var galleryOffsetsX: []
    property var galleryOffsetsY: []
    property var galleryFlipX: []
    property var galleryOrder: [0, 1, 2]
    property var dockEntries: []
    property var sceneLayers: []
    property var sharedWidgets: []
    property var calendarReminders: []
    property string desktopLayoutTemplate: "side-column"
    property string desktopLayoutSeed: "velora-shell-default"
    property bool migrationQueued: false

    signal configurationChanged
    signal configurationError(string message)

    function isObject(value) {
        return value !== null && typeof value === "object" && !Array.isArray(value)
    }

    function clone(value) {
        return value === undefined ? undefined : JSON.parse(JSON.stringify(value))
    }

    function defaultCustomColors() {
        return {
            accent: "#c8788f", bar: "#171a22", icons: "#f4f4f6",
            widgets: "#171a22", text: "#edf1ff", panels: "#11141b"
        }
    }

    function normalizedCustomColors(value) {
        const source = isObject(value) ? value : ({})
        const fallback = defaultCustomColors()
        const result = ({})
        for (const role of Object.keys(fallback)) {
            const candidate = String(source[role] || "")
            result[role] = /^#[0-9a-fA-F]{6}$/.test(candidate)
                ? candidate.toLowerCase() : fallback[role]
        }
        return result
    }

    function customColor(role) {
        const values = normalizedCustomColors(customColors)
        return String(values[String(role)] || values.accent)
    }

    function merge(base, overlay) {
        const result = isObject(base) ? clone(base) : ({})
        if (!isObject(overlay))
            return result
        for (const key in overlay) {
            const value = overlay[key]
            result[key] = isObject(value) && isObject(result[key])
                ? merge(result[key], value) : clone(value)
        }
        return result
    }

    function valueAt(document, path, fallback) {
        const parts = String(path).split(".")
        let cursor = document
        for (let index = 0; index < parts.length; index += 1) {
            if (!isObject(cursor) || cursor[parts[index]] === undefined)
                return fallback
            cursor = cursor[parts[index]]
        }
        return cursor
    }

    function setAt(document, path, value) {
        const result = isObject(document) ? clone(document) : ({})
        const parts = String(path).split(".")
        let cursor = result
        for (let index = 0; index < parts.length - 1; index += 1) {
            const key = parts[index]
            if (!isObject(cursor[key]))
                cursor[key] = ({})
            cursor = cursor[key]
        }
        cursor[parts[parts.length - 1]] = clone(value)
        return result
    }

    function limitedNumber(document, path, fallback, minimum, maximum) {
        const candidate = Number(valueAt(document, path, fallback))
        if (!isFinite(candidate))
            return fallback
        return Math.max(minimum, Math.min(maximum, candidate))
    }

    function defaultTopbarLayout() {
        return [
            { id: "bar-brand", type: "brand", section: "left", order: 0, enabled: false, scale: 1 },
            { id: "bar-launcher", type: "launcher", section: "left", order: 1, enabled: true, scale: 1 },
            { id: "bar-workspaces", type: "workspaces", section: "left", order: 2, enabled: true, scale: 1 },
            { id: "bar-context", type: "context", section: "left", order: 3, enabled: true, scale: 1 },
            { id: "bar-search", type: "search", section: "left", order: 4, enabled: false, scale: 1 },
            { id: "bar-weather", type: "weather", section: "center", order: 0, enabled: true, scale: 1 },
            { id: "bar-clock", type: "clock", section: "right", order: 0, enabled: true, scale: 1 },
            { id: "bar-wifi", type: "wifi", section: "right", order: 1, enabled: true, scale: 1 },
            { id: "bar-volume", type: "volume", section: "right", order: 2, enabled: true, scale: 1 },
            { id: "bar-battery", type: "battery", section: "right", order: 3, enabled: true, scale: 1 },
            { id: "bar-settings", type: "settings", section: "right", order: 4, enabled: true, scale: 1 },
            { id: "bar-avatar", type: "avatar", section: "right", order: 5, enabled: false, scale: 1 },
            { id: "bar-media", type: "media", section: "right", order: 6, enabled: true, scale: 1 }
        ]
    }

    function legacySegmentedTopbar(values) {
        if (!Array.isArray(values))
            return false
        return !values.some(function(item) {
            return isObject(item) && ["weather", "media"].includes(
                String(item.type || ""))
        })
    }

    function normalizedTopbarLayout(values) {
        const allowedTypes = ["brand", "workspaces", "launcher", "search",
                              "context", "weather", "clock", "media", "wifi",
                              "volume", "battery", "settings", "avatar"]
        const allowedSections = ["left", "center", "right"]
        const source = Array.isArray(values) && !legacySegmentedTopbar(values)
            ? values : defaultTopbarLayout()
        const result = []
        const identifiers = ({})
        for (let index = 0; index < source.length && result.length < 16; index += 1) {
            const entry = source[index]
            if (!isObject(entry))
                continue
            const identifier = String(entry.id || "")
            const type = String(entry.type || "")
            const section = String(entry.section || "")
            if (!identifier.length || identifiers[identifier]
                    || !allowedTypes.includes(type)
                    || !allowedSections.includes(section))
                continue
            identifiers[identifier] = true
            result.push({
                id: identifier.slice(0, 80),
                type: type,
                section: section,
                order: Math.max(0, Math.min(31, Math.round(Number(entry.order || 0)))),
                enabled: entry.enabled === undefined ? true : Boolean(entry.enabled),
                scale: Math.max(0.75, Math.min(1.35, Number(entry.scale || 1)))
            })
        }
        if (!result.length)
            return defaultTopbarLayout()
        result.sort(function(a, b) {
            const sectionOrder = { left: 0, center: 1, right: 2 }
            return sectionOrder[a.section] - sectionOrder[b.section]
                || a.order - b.order || a.id.localeCompare(b.id)
        })
        for (const section of allowedSections) {
            let position = 0
            for (let index = 0; index < result.length; index += 1) {
                if (result[index].section === section)
                    result[index].order = position++
            }
        }
        return result
    }

    function topbarItemsForSection(section, includeDisabled) {
        return topbarLayout.filter(function(item) {
            return item.section === section && (includeDisabled || item.enabled)
        }).sort(function(a, b) { return a.order - b.order })
    }

    function fileUrl(path) {
        const value = String(path || "")
        if (!value)
            return ""
        if (value.startsWith("project:"))
            return "file://" + Quickshell.shellDir + "/" + value.slice(8)
        if (value.startsWith("file:") || value.startsWith("qrc:") || value.startsWith("image:"))
            return value
        if (value.startsWith("/"))
            return "file://" + value
        return "file://" + configDir + "/" + value
    }

    function validate(document, source) {
        if (!isObject(document))
            return source + ": the root must be a JSON object"
        const version = Number(document.schemaVersion || 1)
        if (version < 1 || version > supportedSchemaVersion)
            return source + ": unsupported schemaVersion " + version

        const layers = valueAt(document, "lockPreview.scene.layers", null)
        if (layers !== null && !Array.isArray(layers))
            return source + ": lockPreview.scene.layers must be an array"
        if (Array.isArray(layers)) {
            const identifiers = ({})
            for (let layerIndex = 0; layerIndex < layers.length; layerIndex += 1) {
                const layer = layers[layerIndex]
                if (!isObject(layer) || !String(layer.id || "")
                        || !String(layer.type || ""))
                    return source + ": invalid scene layer at " + layerIndex
                if (identifiers[String(layer.id)])
                    return source + ": duplicated scene layer id " + layer.id
                identifiers[String(layer.id)] = true
            }
        }

        const widgets = valueAt(document, "lockPreview.sharedWidgets.items", null)
        if (widgets !== null && !Array.isArray(widgets))
            return source + ": lockPreview.sharedWidgets.items must be an array"
        if (Array.isArray(widgets)) {
            if (widgets.length !== 6)
                return source + ": shared widgets must contain exactly 6 entries"
            const widgetIds = ({})
            for (let widgetIndex = 0; widgetIndex < widgets.length; widgetIndex += 1) {
                const widget = widgets[widgetIndex]
                if (!isObject(widget) || !String(widget.id || "")
                        || !["clock", "calendar", "weather", "media", "gallery",
                            "system",
                            "galleryPhoto"].includes(String(widget.kind || "")))
                    return source + ": invalid shared widget at " + widgetIndex
                if (widgetIds[String(widget.id)])
                    return source + ": duplicated shared widget id " + widget.id
                widgetIds[String(widget.id)] = true
            }
        }

        const gallery = valueAt(document, "lockPreview.gallery", null)
        if (gallery !== null && (!Array.isArray(gallery) || gallery.length !== 3))
            return source + ": lockPreview.gallery must contain exactly three paths"
        if (Array.isArray(gallery)) {
            for (let index = 0; index < gallery.length; index += 1) {
                if (typeof gallery[index] !== "string" && !isObject(gallery[index]))
                    return source + ": lockPreview.gallery entries must be paths or objects"
            }
        }

        const dock = valueAt(document, "lockPreview.dock", null)
        if (dock !== null && (!Array.isArray(dock) || dock.length > 12))
            return source + ": lockPreview.dock must contain no more than twelve entries"
        const barLayout = valueAt(document, "topbar.layout", null)
        if (barLayout !== null && !Array.isArray(barLayout))
            return source + ": topbar.layout must be an array"
        if (Array.isArray(barLayout) && (barLayout.length < 1 || barLayout.length > 16))
            return source + ": topbar.layout must contain 1 to 16 entries"
        return ""
    }

    function parse(text, source, previous) {
        try {
            const document = JSON.parse(text || "{}")
            const validationError = validate(document, source)
            if (validationError)
                throw new Error(validationError)
            return { ok: true, data: document }
        } catch (parseError) {
            const message = source + ": " + String(parseError)
            error = message
            configurationError(message)
            return { ok: false, data: isObject(previous) ? clone(previous) : ({}) }
        }
    }

    function recompute() {
        const resolved = merge(defaultsData, userData)
        const sourceVersion = Number(valueAt(userData, "schemaVersion", 0))
        const legacyAppearance = Object.keys(userData).length > 0
            && sourceVersion > 0 && sourceVersion < 7
        localeName = String(valueAt(resolved, "appearance.locale", "system"))
        reducedMotion = Boolean(valueAt(resolved, "appearance.reducedMotion", false))
        const requestedMotion = String(valueAt(
            resolved, "appearance.motionPreset", "balanced"))
        motionPreset = ["calm", "balanced", "snappy"].includes(requestedMotion)
            ? requestedMotion : "balanced"
        intelligentContrast = Boolean(valueAt(
            resolved, "appearance.intelligentContrast", true))
        reduceTransparency = Boolean(valueAt(
            resolved, "appearance.reduceTransparency", false))
        const requestedStyle = String(valueAt(userData,
            "appearance.visualStyle", legacyAppearance ? "classic"
                : valueAt(resolved, "appearance.visualStyle", "editorial")))
        visualStyle = ["editorial", "classic", "minimal"].includes(requestedStyle)
            ? requestedStyle : (legacyAppearance ? "classic" : "editorial")
        const requestedScheme = String(valueAt(
            resolved, "appearance.colorScheme", "dark"))
        colorScheme = ["dark", "light"].includes(requestedScheme)
            ? requestedScheme : "dark"
        const requestedMaterial = String(valueAt(
            resolved, "appearance.material", "glass"))
        materialMode = ["glass", "solid", "adaptive"].includes(requestedMaterial)
            ? requestedMaterial : "glass"
        surfaceOpacity = limitedNumber(
            resolved, "appearance.surfaceOpacity", 0.82, 0.45, 1)
        blurStrength = limitedNumber(
            resolved, "appearance.blurStrength", 0.55, 0, 1)
        appearanceContrast = limitedNumber(
            resolved, "appearance.contrast", 1.08, 0.8, 1.35)
        reflectionStrength = limitedNumber(
            resolved, "appearance.reflection", 0.35, 0, 1)
        const requestedAccentMode = String(valueAt(
            resolved, "appearance.accentMode", "wallpaper"))
        accentMode = ["wallpaper", "custom"].includes(requestedAccentMode)
            ? requestedAccentMode : "wallpaper"
        const requestedPywalTone = String(valueAt(
            resolved, "appearance.pywalTone", "auto"))
        pywalTone = ["auto", "dark", "light"].includes(requestedPywalTone)
            ? requestedPywalTone : "auto"
        const requestedAccent = String(valueAt(
            resolved, "appearance.accentColor", "#c8788f"))
        accentColor = /^#[0-9a-fA-F]{6}$/.test(requestedAccent)
            ? requestedAccent : "#c8788f"
        customColors = normalizedCustomColors(valueAt(
            resolved, "appearance.customColors", {
                accent: String(accentColor), bar: "#171a22",
                icons: "#f4f4f6", widgets: "#171a22",
                text: "#edf1ff", panels: "#11141b"
            }))
        characterPywal = Boolean(valueAt(resolved, "appearance.characterPywal", false))
        waterCausticsEnabled = Boolean(valueAt(
            resolved, "lockPreview.caustics.enabled", true))
        waterCausticsIntensity = limitedNumber(
            resolved, "lockPreview.caustics.intensity", 0.32, 0, 1)
        waterCausticsLines = Boolean(valueAt(
            resolved, "lockPreview.caustics.lines", true))
        waterCausticsModules = Boolean(valueAt(
            resolved, "lockPreview.caustics.modules", false))
        const requestedDimmingMode = String(valueAt(
            resolved, "lockPreview.dimming.mode", "off"))
        lockDimmingMode = ["off", "background", "panel", "both"].includes(
            requestedDimmingMode) ? requestedDimmingMode : "off"
        lockDimmingAmount = limitedNumber(
            resolved, "lockPreview.dimming.amount", 0.28, 0, 0.72)
        topbarEnabled = Boolean(valueAt(resolved, "topbar.enabled", true))
        systemName = String(valueAt(resolved, "topbar.systemName", "Velora Shell"))
        const requestedTopbarLayout = valueAt(
            resolved, "topbar.layout", defaultTopbarLayout())
        const migrateSegmentedBar = legacySegmentedTopbar(
            requestedTopbarLayout)
        topbarHeight = migrateSegmentedBar ? 40
            : limitedNumber(resolved, "topbar.height", 40, 36, 52)
        topbarScale = limitedNumber(resolved, "topbar.scale", 1, 0.75, 1.35)
        topbarGap = migrateSegmentedBar ? 4
            : limitedNumber(resolved, "topbar.gap", 4, 0, 12)
        topbarMargin = migrateSegmentedBar ? 8 : limitedNumber(userData, "topbar.margin",
            legacyAppearance ? 8 : limitedNumber(
                resolved, "topbar.margin", 8, 6, 20), 6, 20)
        topbarLayout = normalizedTopbarLayout(requestedTopbarLayout)
        topbarOneThingEnabled = Boolean(valueAt(resolved, "topbar.oneThingEnabled", true))
        topbarNotesEnabled = Boolean(valueAt(resolved, "topbar.notesEnabled", true))
        topbarToolsOrder = TopBarOrder.normalize(valueAt(resolved, "topbar.toolsOrder", null))
        desktopWidgetsEnabled = Boolean(valueAt(resolved, "desktop.widgetsEnabled", true))
        desktopVisualizerEnabled = Boolean(valueAt(resolved, "desktop.visualizerEnabled", true))
        wallpaperBlurEnabled = Boolean(valueAt(resolved, "desktop.wallpaperBlurEnabled", false))
        wallpaperBlurStrength = limitedNumber(resolved, "desktop.wallpaperBlurStrength", 0.35, 0, 1)
        wallpaperDimming = limitedNumber(resolved, "desktop.wallpaperDimming", 0, 0, 1)
        wallpaperSelectorGlassEnabled = Boolean(valueAt(resolved, "desktop.wallpaperSelectorGlassEnabled", true))
        widgetBlurEnabled = Boolean(valueAt(resolved, "lockPreview.sharedWidgets.blurEnabled", true))
        barBlurEnabled = Boolean(valueAt(resolved, "bar.blurEnabled", true))
        const requestedBarMaterial = String(valueAt(
            resolved, "bar.material", "glass"))
        barMaterial = ["solid", "glass", "liquid"].includes(requestedBarMaterial)
            ? requestedBarMaterial : "glass"
        const requestedLiquidStyle = String(valueAt(resolved, "bar.liquidStyle", "frosted"))
        liquidGlassStyle = ["clear", "frosted"].includes(requestedLiquidStyle) ? requestedLiquidStyle : "frosted"
        barOpacity = limitedNumber(resolved, "bar.opacity", 0.52, 0.08, 0.96)
        barWaveStrength = limitedNumber(
            resolved, "bar.waveStrength", 0.28, 0, 1)
        const requestedWidgetSurface = String(valueAt(
            resolved, "lockPreview.sharedWidgets.surfaceMode", "solid"))
        widgetSurfaceMode = ["solid", "bar"].includes(requestedWidgetSurface)
            ? requestedWidgetSurface : "solid"
        profileName = String(valueAt(resolved, "profile.displayName", "Velora"))
        greeting = String(valueAt(resolved, "profile.greeting", "Welcome back!!"))
        verticalLabel = String(valueAt(resolved, "profile.verticalLabel", "VELORA SHELL"))
        avatarPath = fileUrl(valueAt(resolved, "profile.avatar", ""))
        characterPath = fileUrl(valueAt(resolved, "lockPreview.character.path", ""))
        characterScale = limitedNumber(resolved, "lockPreview.character.scale", 1.0, 0.5, 2.5)
        characterOffsetX = limitedNumber(resolved, "lockPreview.character.offsetX", 0, -800, 800)
        characterOffsetY = limitedNumber(resolved, "lockPreview.character.offsetY", 0, -800, 800)
        characterFlipX = Boolean(valueAt(resolved, "lockPreview.character.flipX", false))
        clockOffsetX = limitedNumber(resolved, "lockPreview.clock.offsetX", 0, -500, 500)
        clockOffsetY = limitedNumber(resolved, "lockPreview.clock.offsetY", 0, -400, 400)
        clockScale = limitedNumber(resolved, "lockPreview.clock.scale", 1.0, 0.55, 1.8)
        greetingOffsetX = limitedNumber(resolved, "lockPreview.titles.greeting.offsetX", 0, -500, 500)
        greetingOffsetY = limitedNumber(resolved, "lockPreview.titles.greeting.offsetY", 0, -400, 400)
        greetingFontSize = limitedNumber(resolved, "lockPreview.titles.greeting.fontSize", 25, 10, 64)
        verticalLabelOffsetX = limitedNumber(resolved, "lockPreview.titles.vertical.offsetX", 0, -500, 500)
        verticalLabelOffsetY = limitedNumber(resolved, "lockPreview.titles.vertical.offsetY", 0, -400, 400)
        verticalLabelFontSize = limitedNumber(resolved, "lockPreview.titles.vertical.fontSize", 19, 10, 64)

        const resolvedGallery = valueAt(resolved, "lockPreview.gallery", [])
        const gallery = []
        const scales = []
        const offsetsX = []
        const offsetsY = []
        const flips = []
        for (let index = 0; index < Math.min(3, resolvedGallery.length); index += 1) {
            const entry = normalizedGalleryEntry(resolvedGallery[index])
            gallery.push(fileUrl(entry.path))
            scales.push(Math.max(0.65, Math.min(2.5, Number(entry.scale))))
            offsetsX.push(Math.max(-400, Math.min(400, Number(entry.offsetX))))
            offsetsY.push(Math.max(-400, Math.min(400, Number(entry.offsetY))))
            flips.push(Boolean(entry.flipX))
        }
        galleryPaths = gallery
        galleryScales = scales
        galleryOffsetsX = offsetsX
        galleryOffsetsY = offsetsY
        galleryFlipX = flips
        galleryOrder = normalizedGalleryOrder(valueAt(resolved, "lockPreview.galleryOrder", [0, 1, 2]))

        const explicitScene = valueAt(userData, "lockPreview.scene.layers", null)
        const configuredScene = Array.isArray(explicitScene)
            ? explicitScene : (Object.keys(userData).length === 0
                ? valueAt(resolved, "lockPreview.scene.layers", [])
                : legacySceneForDocument(resolved))
        sceneLayers = lockOnlySceneLayers(normalizedSceneLayers(configuredScene))

        const reminderSource = valueAt(resolved, "lockPreview.calendar.reminders", [])
        calendarReminders = normalizedReminders(reminderSource)

        const explicitWidgets = valueAt(
            userData, "lockPreview.sharedWidgets.items", null)
        const defaultWidgets = valueAt(
            defaultsData, "lockPreview.sharedWidgets.items", [])
        const configuredWidgets = Array.isArray(explicitWidgets)
            ? explicitWidgets : defaultWidgets
        const documentVersion = Number(userData.schemaVersion
            || (Object.keys(userData).length === 0 ? supportedSchemaVersion : 1))
        desktopLayoutSeed = String(valueAt(userData,
            "lockPreview.sharedWidgets.layoutSeed",
            Object.keys(userData).length === 0
                ? valueAt(defaultsData, "lockPreview.sharedWidgets.layoutSeed",
                          "velora-shell-default") : "active-config"))
        if (!desktopLayoutSeed.length)
            desktopLayoutSeed = "active-config"
        const requestedTemplate = String(valueAt(userData,
            "lockPreview.sharedWidgets.layoutTemplate", ""))
        desktopLayoutTemplate = normalizeDesktopTemplateName(
            requestedTemplate, templateForSeed(desktopLayoutSeed))
        const hasLogicalWidgets = Array.isArray(explicitWidgets)
            && logicalWidgetSetComplete(explicitWidgets)
        if (hasLogicalWidgets && documentVersion >= 4) {
            // Stored coordinates are authoritative. Older releases rebuilt a
            // named template here and could move every card after a restart.
            sharedWidgets = normalizedSharedWidgets(explicitWidgets)
            desktopLayoutTemplate = "custom"
        } else {
            sharedWidgets = migratedSharedWidgets(
                configuredWidgets, configuredScene, defaultWidgets,
                desktopLayoutTemplate, desktopLayoutSeed)
        }

        const resolvedDock = valueAt(resolved, "lockPreview.dock", [])
        dockEntries = Array.isArray(resolvedDock) ? clone(resolvedDock.slice(0, 12)) : []
        ready = Object.keys(defaultsData).length > 0
        if (ready)
            error = ""
        configurationChanged()
        if (ready && Object.keys(userData).length > 0
                && (documentVersion < supportedSchemaVersion
                    || migrateSegmentedBar) && !migrationQueued) {
            migrationQueued = true
            migrationTimer.restart()
        }
    }

    function reload() {
        defaultsFile.reload()
        userFile.reload()
    }

    function normalizedGalleryEntry(entry) {
        if (typeof entry === "string") {
            return {
                path: entry,
                scale: 1.0,
                offsetX: 0,
                offsetY: 0,
                flipX: false
            }
        }
        const source = isObject(entry) ? entry : ({})
        const scale = Number(source.scale === undefined ? 1.0 : source.scale)
        const offsetX = Number(source.offsetX === undefined ? 0 : source.offsetX)
        const offsetY = Number(source.offsetY === undefined ? 0 : source.offsetY)
        return {
            path: String(source.path || ""),
            scale: isFinite(scale) ? Math.max(0.65, Math.min(2.5, scale)) : 1.0,
            offsetX: isFinite(offsetX) ? Math.max(-400, Math.min(400, offsetX)) : 0,
            offsetY: isFinite(offsetY) ? Math.max(-400, Math.min(400, offsetY)) : 0,
            flipX: Boolean(source.flipX)
        }
    }

    function normalizedCharacterEntry(entry) {
        const source = isObject(entry) ? entry : ({})
        const scale = Number(source.scale === undefined ? 1.0 : source.scale)
        const offsetX = Number(source.offsetX === undefined ? 0 : source.offsetX)
        const offsetY = Number(source.offsetY === undefined ? 0 : source.offsetY)
        return {
            path: String(source.path || ""),
            scale: isFinite(scale) ? Math.max(0.5, Math.min(2.5, scale)) : 1.0,
            offsetX: isFinite(offsetX) ? Math.max(-800, Math.min(800, offsetX)) : 0,
            offsetY: isFinite(offsetY) ? Math.max(-800, Math.min(800, offsetY)) : 0,
            flipX: Boolean(source.flipX)
        }
    }

    function moduleSize(type) {
        const sizes = {
            character: [560, 945], image: [320, 240], clock: [282, 120],
            calendar: [282, 260], weather: [282, 128], profileHeader: [169, 58],
            greeting: [180, 52], verticalLabel: [28, 210], gallery: [302, 294],
            media: [294, 76], mediaPlayer: [294, 76], system: [302, 194],
            photoGrid: [360, 360], text: [320, 96]
        }
        return sizes[type] || [240, 120]
    }

    function normalizedCrop(value) {
        const source = isObject(value) ? value : ({})
        const number = function(candidate, fallback) {
            const parsed = Number(candidate)
            return isFinite(parsed) ? Math.max(0, Math.min(1, parsed)) : fallback
        }
        const x = number(source.x, 0)
        const y = number(source.y, 0)
        const width = Math.max(0.01, Math.min(1 - x, number(source.width, 1)))
        const height = Math.max(0.01, Math.min(1 - y, number(source.height, 1)))
        return { x: x, y: y, width: width, height: height }
    }

    function normalizedItemStyle(value, fallbackRadius) {
        const source = isObject(value) ? value : ({})
        const modes = ["inherit", "liquid", "solid", "none"]
        const layouts = ["feature", "strip3", "grid2", "grid3", "grid4"]
        const number = function(candidate, fallback, minimum, maximum) {
            const parsed = Number(candidate)
            return isFinite(parsed) ? Math.max(minimum, Math.min(maximum, parsed)) : fallback
        }
        return {
            material: modes.includes(String(source.material))
                ? String(source.material) : "inherit",
            solidColor: String(source.solidColor || "#20222a"),
            surfaceOpacity: number(source.surfaceOpacity, 0.82, 0, 1),
            radius: number(source.radius, Number(fallbackRadius || 28), 0, 240),
            fontFamily: String(source.fontFamily || "Poppins").slice(0, 160),
            displayFontFamily: String(source.displayFontFamily || "").slice(0, 160),
            fontAsset: fileUrl(String(source.fontAsset || "")),
            fontScale: number(source.fontScale, 1, 0.25, 4),
            fontWeight: Math.round(number(source.fontWeight, 500, 100, 900)),
            letterSpacing: number(source.letterSpacing, 0, -8, 32),
            textColor: String(source.textColor || ""),
            accentColor: String(source.accentColor || ""),
            galleryLayout: layouts.includes(String(source.galleryLayout))
                ? String(source.galleryLayout) : "feature",
            gap: number(source.gap, 10, 0, 80)
        }
    }

    function normalizedPhotoItems(values) {
        const source = Array.isArray(values) ? values.slice(0, 16) : []
        return source.map(function(entry, index) {
            const item = isObject(entry) ? entry : ({ path: String(entry || "") })
            return {
                id: String(item.id || ("photo-" + index)),
                path: fileUrl(String(item.path || "")),
                crop: normalizedCrop(item.crop),
                flipX: Boolean(item.flipX)
            }
        })
    }

    function normalizedReminders(values) {
        const source = Array.isArray(values) ? values.slice(0, 512) : []
        const repeats = ["none", "daily", "weekly", "monthly", "yearly"]
        return source.map(function(value, index) {
            const item = isObject(value) ? value : ({})
            return {
                id: String(item.id || ("reminder-" + index)),
                title: String(item.title || "Lembrete").slice(0, 160),
                start: String(item.start || ""),
                end: String(item.end || ""),
                allDay: Boolean(item.allDay),
                notes: String(item.notes || "").slice(0, 2000),
                color: String(item.color || "#8ca8ff"),
                completed: Boolean(item.completed),
                repeat: repeats.includes(String(item.repeat))
                    ? String(item.repeat) : "none"
            }
        })
    }

    function normalizedSceneLayer(value, fallbackOrder) {
        const source = isObject(value) ? value : ({})
        const allowed = ["character", "image", "clock", "calendar", "weather",
                         "profileHeader", "greeting", "verticalLabel", "gallery",
                         "mediaPlayer", "photoGrid", "text"]
        const type = allowed.includes(String(source.type)) ? String(source.type) : "image"
        const legacyTransform = isObject(source.transform) ? source.transform : ({})
        const desktopSource = isObject(source.desktop) ? source.desktop : legacyTransform
        const lockSource = isObject(source.lock) ? source.lock : legacyTransform
        const size = moduleSize(type)
        const number = function(candidate, fallback, minimum, maximum) {
            const parsed = Number(candidate)
            return isFinite(parsed) ? Math.max(minimum, Math.min(maximum, parsed)) : fallback
        }
        const layer = {
            id: String(source.id || (type + "-" + fallbackOrder)),
            type: type,
            name: String(source.name || type).slice(0, 80),
            plane: String(source.plane) === "belowPanel" ? "belowPanel" : "abovePanel",
            order: Math.max(0, Math.round(number(source.order, fallbackOrder, 0, 100000))),
            desktopEnabled: source.desktopEnabled === undefined
                ? false : Boolean(source.desktopEnabled),
            lockEnabled: source.lockEnabled === undefined
                ? (source.visible === undefined ? true : Boolean(source.visible))
                : Boolean(source.lockEnabled),
            visible: source.lockEnabled === undefined
                ? (source.visible === undefined ? true : Boolean(source.visible))
                : Boolean(source.lockEnabled),
            locked: Boolean(source.locked),
            desktop: normalizedWidgetTransform(desktopSource, legacyTransform),
            lock: normalizedWidgetTransform(lockSource, legacyTransform),
            baseWidth: number(source.baseWidth, size[0], 8, 8192),
            baseHeight: number(source.baseHeight, size[1], 8, 8192),
            desktopStyle: normalizedItemStyle(source.desktopStyle, 28),
            lockStyle: normalizedItemStyle(source.lockStyle, 28),
            crop: normalizedCrop(source.crop),
            variantId: String(source.variantId || "inherit").slice(0, 80)
        }
        layer.transform = clone(layer.lock)
        if (type === "image" || type === "character")
            layer.source = fileUrl(String(source.source || ""))
        if (type === "text")
            layer.text = String(source.text || source.name || "Texto").slice(0, 2000)
        if (type === "photoGrid")
            layer.items = normalizedPhotoItems(source.items)
        return layer
    }

    function normalizedSceneLayers(values) {
        const source = Array.isArray(values) ? values : []
        const result = []
        const identifiers = ({})
        for (let index = 0; index < source.length; index += 1) {
            const layer = normalizedSceneLayer(source[index], index)
            if (identifiers[layer.id])
                layer.id = layer.id + "-" + index
            identifiers[layer.id] = true
            result.push(layer)
        }
        result.sort(function(first, second) {
            if (first.plane !== second.plane)
                return first.plane === "belowPanel" ? -1 : 1
            return first.order - second.order
        })
        return result
    }

    function normalizedWidgetTransform(value, fallback) {
        const source = isObject(value) ? value : ({})
        const base = isObject(fallback) ? fallback : ({})
        const number = function(candidate, fallbackValue, minimum, maximum) {
            const parsed = Number(candidate)
            return isFinite(parsed)
                ? Math.max(minimum, Math.min(maximum, parsed)) : fallbackValue
        }
        return {
            x: number(source.x, Number(base.x || 0), -1600, 3200),
            y: number(source.y, Number(base.y || 0), -900, 1800),
            scale: number(source.scale, Number(base.scale === undefined ? 1 : base.scale), 0.02, 32),
            rotation: number(source.rotation, Number(base.rotation || 0), -360, 360),
            opacity: number(source.opacity, Number(base.opacity === undefined ? 1 : base.opacity), 0, 1),
            flipX: source.flipX === undefined ? Boolean(base.flipX) : Boolean(source.flipX)
        }
    }

    function normalizedWidgetSize(value, fallbackWidth, fallbackHeight) {
        const source = isObject(value) ? value : ({})
        const width = Number(source.width)
        const height = Number(source.height)
        return {
            width: isFinite(width) ? Math.max(8, Math.min(8192, width))
                : Math.max(8, Number(fallbackWidth || 8)),
            height: isFinite(height) ? Math.max(8, Math.min(8192, height))
                : Math.max(8, Number(fallbackHeight || 8))
        }
    }

    function widgetKinds() {
        return ["clock", "calendar", "weather", "media", "gallery", "system"]
    }

    function normalizedSharedWidget(value, fallbackOrder) {
        const source = isObject(value) ? value : ({})
        const requestedKind = String(source.kind || "")
        const kind = widgetKinds().includes(requestedKind)
            ? requestedKind : widgetKinds()[Math.max(0,
                Math.min(widgetKinds().length - 1, fallbackOrder))]
        const size = moduleSize(kind)
        const width = Number(source.baseWidth)
        const height = Number(source.baseHeight)
        const legacyEnabled = source.enabled === undefined
            ? true : Boolean(source.enabled)
        const result = {
            id: String(source.id || ("shared-" + kind)),
            kind: kind,
            name: String(source.name || widgetDisplayName(kind)).slice(0, 80),
            desktopEnabled: source.desktopEnabled === undefined
                ? legacyEnabled : Boolean(source.desktopEnabled),
            lockEnabled: source.lockEnabled === undefined
                ? legacyEnabled : Boolean(source.lockEnabled),
            locked: Boolean(source.locked),
            stagger: Math.max(0, Math.min(31, Math.round(Number(
                source.stagger === undefined ? fallbackOrder : source.stagger)))),
            baseWidth: isFinite(width) ? Math.max(8, Math.min(8192, width)) : size[0],
            baseHeight: isFinite(height) ? Math.max(8, Math.min(8192, height)) : size[1],
            desktopSize: normalizedWidgetSize(source.desktopSize,
                isFinite(width) ? width : size[0],
                isFinite(height) ? height : size[1]),
            lockSize: normalizedWidgetSize(source.lockSize,
                isFinite(width) ? width : size[0],
                isFinite(height) ? height : size[1]),
            desktop: normalizedWidgetTransform(source.desktop, ({})),
            lock: normalizedWidgetTransform(source.lock, ({})),
            desktopStyle: normalizedItemStyle(source.desktopStyle, 28),
            lockStyle: normalizedItemStyle(source.lockStyle, 28),
            variantId: String(source.variantId || "inherit").slice(0, 80)
        }
        result.desktop = constrainWidgetTransform(result, result.desktop)
        result.lock = constrainWidgetTransform(result, result.lock)
        return result
    }

    function widgetDisplayName(kind) {
        const names = {
            clock: "Relógio", calendar: "Calendário", weather: "Previsão",
            media: "Mídia", gallery: "Galeria", system: "Sistema"
        }
        return names[String(kind)] || String(kind)
    }

    function logicalWidgetSetComplete(values) {
        if (!Array.isArray(values) || values.length !== widgetKinds().length)
            return false
        const found = ({})
        for (let index = 0; index < values.length; index += 1)
            found[String(values[index] && values[index].kind || "")] = true
        return widgetKinds().every(function(kind) { return Boolean(found[kind]) })
    }

    function normalizedSharedWidgets(values) {
        const source = Array.isArray(values) ? values : []
        const byKind = ({})
        for (let index = 0; index < source.length; index += 1) {
            const kind = String(source[index] && source[index].kind || "")
            if (widgetKinds().includes(kind) && !byKind[kind])
                byKind[kind] = source[index]
        }
        const result = []
        const defaults = valueAt(defaultsData, "lockPreview.sharedWidgets.items", [])
        for (let index = 0; index < widgetKinds().length; index += 1) {
            const kind = widgetKinds()[index]
            let fallback = null
            for (let defaultIndex = 0; defaultIndex < defaults.length; defaultIndex += 1) {
                if (String(defaults[defaultIndex].kind) === kind) {
                    fallback = defaults[defaultIndex]
                    break
                }
            }
            result.push(normalizedSharedWidget(byKind[kind] || fallback || {
                id: "shared-" + kind, kind: kind
            }, index))
        }
        return result
    }

    function layerForSharedKind(layers, kind) {
        const identifiers = {
            clock: ["clock"], calendar: ["calendar"], weather: ["weather"],
            media: ["media-player", "media"], gallery: ["gallery"]
        }
        const candidates = identifiers[kind] || []
        for (let index = 0; index < layers.length; index += 1) {
            if (candidates.includes(String(layers[index].id))
                    || (kind === "media" && String(layers[index].type) === "mediaPlayer"))
                return layers[index]
        }
        return null
    }

    function migratedSharedWidgets(values, sceneValues, defaults, template, seed) {
        const result = normalizedSharedWidgets(defaults)
        const source = Array.isArray(values) ? values : []
        const layers = normalizedSceneLayers(sceneValues)
        for (let index = 0; index < result.length; index += 1) {
            const widget = result[index]
            let legacyWidget = null
            for (let sourceIndex = 0; sourceIndex < source.length; sourceIndex += 1) {
                const candidate = source[sourceIndex] || ({})
                if (String(candidate.kind) === widget.kind
                        || (widget.kind === "gallery"
                            && String(candidate.kind) === "galleryPhoto"
                            && Number(candidate.slot || 0) === 0)) {
                    legacyWidget = candidate
                    break
                }
            }
            const layer = layerForSharedKind(layers, widget.kind)
            if (legacyWidget) {
                widget.lock = normalizedWidgetTransform(
                    legacyWidget.lock, widget.lock)
                const legacyEnabled = legacyWidget.lockEnabled === undefined
                    ? (legacyWidget.enabled === undefined
                        ? true : Boolean(legacyWidget.enabled))
                    : Boolean(legacyWidget.lockEnabled)
                widget.lockEnabled = legacyEnabled
                widget.locked = Boolean(legacyWidget.locked)
            } else if (layer) {
                widget.lock = normalizedWidgetTransform(layer.transform, widget.lock)
                widget.lockEnabled = Boolean(layer.visible)
                widget.locked = Boolean(layer.locked)
            }
            if (widget.kind === "system")
                widget.lockEnabled = false
        }
        return desktopLayoutForWidgets(result, template, seed)
    }

    function lockOnlySceneLayers(values) {
        const sharedTypes = ["clock", "calendar", "weather", "gallery", "mediaPlayer"]
        return (Array.isArray(values) ? values : []).filter(function(layer) {
            return !sharedTypes.includes(String(layer.type || ""))
        })
    }

    function constrainWidgetTransform(widget, value) {
        const result = normalizedWidgetTransform(value, ({}))
        if (!widget || String(widget.kind) !== "gallery")
            return result
        const radians = Number(result.rotation || 0) * Math.PI / 180
        const cosine = Math.cos(radians)
        const sine = Math.sin(radians)
        const baseWidth = Math.max(8, Number(widget.baseWidth || 302))
        const baseHeight = Math.max(8, Number(widget.baseHeight || 294))
        const unitSpan = Math.max(0.001,
            Math.abs(baseWidth * cosine) + Math.abs(baseHeight * sine))
        result.scale = Math.min(Number(result.scale || 1), 800 / unitSpan)
        const widthVectorX = baseWidth * result.scale * cosine
        const heightVectorX = -baseHeight * result.scale * sine
        const minimumOffset = Math.min(0, widthVectorX, heightVectorX,
                                       widthVectorX + heightVectorX)
        const maximumOffset = Math.max(0, widthVectorX, heightVectorX,
                                       widthVectorX + heightVectorX)
        const minimumX = 800 - minimumOffset
        const maximumX = 1600 - maximumOffset
        result.x = Math.max(minimumX, Math.min(maximumX, Number(result.x || 0)))
        return result
    }

    function desktopTemplateNames() {
        return ["side-column", "split-corners", "scattered",
                "gallery-top-right", "custom"]
    }

    function normalizeDesktopTemplateName(name, fallback) {
        const aliases = {
            "bottom-strip": "split-corners",
            "lower-clusters": "split-corners",
            "top-strip": "side-column",
            "upper-clusters": "side-column"
        }
        const requested = aliases[String(name)] || String(name)
        return desktopTemplateNames().includes(requested)
            ? requested
            : (fallback === undefined ? "custom" : String(fallback))
    }

    function desktopTemplateLabel(name) {
        const labels = {
            "side-column": "Coluna lateral",
            "split-corners": "Cantos divididos",
            "scattered": "Composição periférica",
            "gallery-top-right": "Galeria superior direita",
            "custom": "Personalizado"
        }
        return labels[String(name)] || labels.custom
    }

    function templateForSeed(seed) {
        // Compatibility entry point for old profiles. It is intentionally
        // deterministic and no longer chooses a random-looking preset.
        return "side-column"
    }

    function desktopTemplatePositions(name) {
        const templates = {
            "side-column": {
                clock: [48, 88, 1], calendar: [48, 228, 0.74],
                weather: [48, 438, 1], media: [653, 770, 1],
                gallery: [1250, 88, 1], system: [48, 592, 0.95]
            },
            "split-corners": {
                clock: [48, 90, 1], calendar: [48, 560, 0.82],
                weather: [48, 232, 1], media: [653, 770, 1],
                gallery: [1250, 90, 1], system: [1278, 615, 0.90]
            },
            "scattered": {
                // The source video uses peripheral anchors, not free jitter:
                // two compact edge clusters plus a centred media card.
                clock: [48, 104, 0.94], calendar: [48, 596, 0.72],
                weather: [1284, 604, 0.86], media: [653, 770, 1],
                gallery: [1250, 92, 1], system: [1290, 382, 0.84]
            },
            "gallery-top-right": {
                clock: [1260, 390, 0.92], calendar: [48, 100, 0.80],
                weather: [1260, 520, 0.92], media: [653, 770, 1],
                gallery: [1250, 76, 1], system: [48, 584, 0.92]
            }
        }
        return templates[String(name)] || templates["side-column"]
    }

    function desktopLayoutForWidgets(values, name, seed) {
        const requested = desktopTemplateNames().includes(String(name))
            && String(name) !== "custom" ? String(name) : templateForSeed(seed)
        const positions = desktopTemplatePositions(requested)
        const result = clone(values)
        for (let index = 0; index < result.length; index += 1) {
            const widget = result[index]
            const position = positions[widget.kind] || [48, 92, 1]
            widget.desktop = constrainWidgetTransform(widget, {
                x: position[0],
                y: position[1],
                scale: position[2],
                rotation: 0,
                opacity: 1,
                flipX: false
            })
        }
        return result
    }

    function sharedWidgetById(identifier) {
        for (let index = 0; index < sharedWidgets.length; index += 1) {
            if (String(sharedWidgets[index].id) === String(identifier))
                return sharedWidgets[index]
        }
        return null
    }

    function sharedWidgetByKind(kind) {
        for (let index = 0; index < sharedWidgets.length; index += 1) {
            if (String(sharedWidgets[index].kind) === String(kind))
                return sharedWidgets[index]
        }
        return null
    }

    function sharedWidgetLayers(space) {
        const target = String(space) === "desktop" ? "desktop" : "lock"
        return sharedWidgets.map(function(widget) {
            const size = normalizedWidgetSize(widget[target + "Size"],
                widget.baseWidth, widget.baseHeight)
            return {
                id: widget.id,
                type: widget.kind,
                name: widget.name,
                plane: "abovePanel",
                order: widget.stagger,
                visible: target === "desktop"
                    ? widget.desktopEnabled : widget.lockEnabled,
                locked: widget.locked,
                sharedWidget: true,
                baseWidth: size.width,
                baseHeight: size.height,
                transform: clone(widget[target]),
                style: clone(widget[target + "Style"]),
                variantId: String(widget.variantId || "inherit")
            }
        })
    }

    function setSharedWidgets(values, persist) {
        const normalized = normalizedSharedWidgets(values)
        sharedWidgets = normalized
        configurationChanged()
        if (persist === false)
            return true
        let next = isObject(userData) ? clone(userData) : ({})
        next.schemaVersion = supportedSchemaVersion
        next = setAt(next, "appearance.motionPreset", motionPreset)
        next = setAt(next, "appearance.intelligentContrast", intelligentContrast)
        next = setAt(next, "appearance.reduceTransparency", reduceTransparency)
        next = setAt(next, "appearance.visualStyle", visualStyle)
        next = setAt(next, "appearance.colorScheme", colorScheme)
        next = setAt(next, "appearance.material", materialMode)
        next = setAt(next, "appearance.surfaceOpacity", surfaceOpacity)
        next = setAt(next, "appearance.blurStrength", blurStrength)
        next = setAt(next, "appearance.contrast", appearanceContrast)
        next = setAt(next, "appearance.reflection", reflectionStrength)
        next = setAt(next, "appearance.accentMode", accentMode)
        next = setAt(next, "appearance.accentColor", String(accentColor))
        next = setAt(next, "lockPreview.sharedWidgets.items", normalized)
        next = setAt(next, "lockPreview.sharedWidgets.layoutTemplate",
                     desktopLayoutTemplate)
        next = setAt(next, "lockPreview.sharedWidgets.layoutSeed",
                     desktopLayoutSeed)
        next = setAt(next, "lockPreview.scene.layers", sceneLayers)
        userData = next
        saveTimer.restart()
        return true
    }

    function setBarAppearance(material, waveStrength) {
        const requested = String(material || barMaterial)
        let next = isObject(userData) ? clone(userData) : ({})
        next = setAt(next, "bar.material",
            ["solid", "glass", "liquid"].includes(requested)
                ? requested : "glass")
        next = setAt(next, "bar.waveStrength", Math.max(0,
            Math.min(1, Number(waveStrength === undefined
                ? barWaveStrength : waveStrength))))
        userData = next
        recompute()
        saveTimer.restart()
        return true
    }

    function setBarOpacity(opacity) {
        let next = isObject(userData) ? clone(userData) : ({})
        next = setAt(next, "bar.opacity", Math.max(0.08,
            Math.min(0.96, Number(opacity))))
        userData = next
        recompute()
        saveTimer.restart()
        return true
    }

    function setWidgetSurfaceMode(mode) {
        const requested = String(mode || "solid")
        if (!["solid", "bar"].includes(requested))
            return false
        setValue("lockPreview.sharedWidgets.surfaceMode", requested)
        return true
    }

    function defaultWallpaperComposition() {
        const positions = {
            clock: [74, 48, 350, 145],
            calendar: [74, 215, 350, 285],
            weather: [74, 525, 360, 255],
            gallery: [1170, 70, 360, 210],
            media: [1170, 300, 360, 100]
        }
        const widgets = clone(sharedWidgets)
        for (let index = 0; index < widgets.length; index += 1) {
            const widget = widgets[index]
            const rect = positions[String(widget.kind)]
            widget.desktopEnabled = String(widget.kind) !== "system"
            if (!rect)
                continue
            widget.desktop = Object.assign({}, widget.desktop || ({}), {
                x: rect[0], y: rect[1], scale: 1,
                rotation: 0, opacity: 1, flipX: false
            })
            widget.desktopSize = { width: rect[2], height: rect[3] }
        }
        const snapshot = compositionSnapshot()
        snapshot.sharedWidgets = {
            layoutTemplate: "custom",
            layoutSeed: "wallpaper-default-v1",
            items: widgets
        }
        return snapshot
    }

    function setSharedWidgetState(values, template, seed, persist) {
        const requestedTemplate = String(template || desktopLayoutTemplate)
        desktopLayoutTemplate = normalizeDesktopTemplateName(
            requestedTemplate, "custom")
        desktopLayoutSeed = String(seed || desktopLayoutSeed || "active-config")
        return setSharedWidgets(values, persist)
    }

    function markDesktopLayoutCustom(persist) {
        if (desktopLayoutTemplate === "custom")
            return true
        desktopLayoutTemplate = "custom"
        if (persist === false) {
            configurationChanged()
            return true
        }
        return setSharedWidgets(sharedWidgets, true)
    }

    function applyDesktopTemplate(name) {
        const normalizedName = normalizeDesktopTemplateName(name, "")
        const requested = normalizedName.length > 0 && normalizedName !== "custom"
            ? normalizedName : templateForSeed(desktopLayoutSeed)
        const next = desktopLayoutForWidgets(
            sharedWidgets, requested, desktopLayoutSeed)
        return setSharedWidgetState(next, requested, desktopLayoutSeed, true)
    }

    function restoreDesktopLayout() {
        return applyDesktopTemplate(templateForSeed(desktopLayoutSeed))
    }

    function advanceDesktopTemplate() {
        const templates = desktopTemplateNames().slice(0, 4)
        let index = templates.indexOf(desktopLayoutTemplate)
        if (index < 0)
            index = templates.indexOf(templateForSeed(desktopLayoutSeed))
        return applyDesktopTemplate(templates[(index + 1) % templates.length])
    }

    function widgetVisibleAtProgress(kind, progress) {
        const widget = sharedWidgetByKind(kind)
        if (!widget)
            return false
        const amount = Math.max(0, Math.min(1, Number(progress || 0)))
        const desktopOpacity = desktopWidgetsEnabled && widget.desktopEnabled
            ? Number(widget.desktop.opacity === undefined ? 1 : widget.desktop.opacity) : 0
        const lockOpacity = widget.lockEnabled
            ? Number(widget.lock.opacity === undefined ? 1 : widget.lock.opacity) : 0
        return desktopOpacity * (1 - amount) + lockOpacity * amount > 0.001
    }

    function setSharedWidgetVisibility(kind, desktopEnabled, lockEnabled) {
        const next = clone(sharedWidgets)
        for (let index = 0; index < next.length; index += 1) {
            if (String(next[index].kind) !== String(kind))
                continue
            next[index].desktopEnabled = Boolean(desktopEnabled)
            next[index].lockEnabled = Boolean(lockEnabled)
            return setSharedWidgets(next, true)
        }
        return false
    }

    function sharedWidgetVisibilitySnapshot(progress) {
        const result = ({})
        for (let index = 0; index < sharedWidgets.length; index += 1) {
            const widget = sharedWidgets[index]
            result[String(widget.kind)] = {
                desktop: Boolean(widget.desktopEnabled),
                lock: Boolean(widget.lockEnabled),
                visibleNow: widgetVisibleAtProgress(widget.kind, progress)
            }
        }
        return result
    }

    function legacySceneForDocument(document) {
        const character = normalizedCharacterEntry(valueAt(document, "lockPreview.character", ({})))
        const clockScaleValue = limitedNumber(document, "lockPreview.clock.scale", 1, 0.55, 1.8)
        const clockX = limitedNumber(document, "lockPreview.clock.offsetX", 0, -500, 500)
        const clockY = limitedNumber(document, "lockPreview.clock.offsetY", 0, -400, 400)
        const greetingX = limitedNumber(document, "lockPreview.titles.greeting.offsetX", 0, -500, 500)
        const greetingY = limitedNumber(document, "lockPreview.titles.greeting.offsetY", 0, -400, 400)
        const verticalX = limitedNumber(document, "lockPreview.titles.vertical.offsetX", 0, -500, 500)
        const verticalY = limitedNumber(document, "lockPreview.titles.vertical.offsetY", 0, -400, 400)
        const make = function(id, type, name, x, y, scale, order, flip) {
            return { id: id, type: type, name: name, plane: "abovePanel", order: order,
                     visible: true, locked: false,
                     transform: { x: x, y: y, scale: scale, rotation: 0,
                                  opacity: 1, flipX: Boolean(flip) } }
        }
        return [
            make("clock", "clock", "Relógio", 199.5 + clockX, 138 + clockY,
                 clockScaleValue, 10, false),
            make("calendar", "calendar", "Calendário", 199.5, 297, 1, 20, false),
            make("weather", "weather", "Previsão", 199.5, 565, 1, 30, false),
            make("character", "character", "Personagem", 482.5 + character.offsetX,
                 25 + character.offsetY, character.scale, 50, character.flipX),
            make("vertical-label", "verticalLabel", "Texto vertical",
                 1045.5 + verticalX, 255 + verticalY, 1, 60, false),
            make("profile-header", "profileHeader", "Perfil", 1240.5, 132, 1, 70, false),
            make("greeting", "greeting", "Saudação", 1234.5 + greetingX,
                 250 + greetingY, 1, 80, false),
            make("gallery", "gallery", "Galeria", 1077.5, 304, 1, 90, false),
            make("media-player", "mediaPlayer", "Mídia", 1081.5, 613, 1, 100, false)
        ]
    }

    function sceneLayerById(identifier) {
        for (let index = 0; index < sceneLayers.length; index += 1) {
            if (String(sceneLayers[index].id) === String(identifier))
                return sceneLayers[index]
        }
        return null
    }

    function setSceneLayers(values, persist) {
        const normalized = normalizedSceneLayers(values)
        sceneLayers = normalized
        configurationChanged()
        if (persist === false)
            return true
        let next = isObject(userData) ? clone(userData) : ({})
        next.schemaVersion = supportedSchemaVersion
        next = setAt(next, "lockPreview.scene.layers", normalized)
        userData = next
        saveTimer.restart()
        return true
    }

    function resolvedGalleryEntries() {
        const resolved = merge(defaultsData, userData)
        const entries = valueAt(resolved, "lockPreview.gallery", [])
        const normalized = []
        for (let index = 0; index < Math.min(3, entries.length); index += 1)
            normalized.push(normalizedGalleryEntry(entries[index]))
        return normalized
    }

    function normalizedGalleryOrder(order) {
        if (!Array.isArray(order) || order.length !== 3)
            return [0, 1, 2]
        const normalized = order.map(function(value) { return Number(value) })
        const sorted = normalized.slice().sort()
        return sorted[0] === 0 && sorted[1] === 1 && sorted[2] === 2
            ? normalized : [0, 1, 2]
    }

    function compositionSnapshot() {
        const characterLayer = sceneLayerById("character")
        const characterTransform = characterLayer ? characterLayer.transform : ({})
        const character = {
            path: String(characterPath || ""),
            scale: Number(characterTransform.scale === undefined
                          ? characterScale : characterTransform.scale),
            offsetX: Number(characterTransform.x === undefined
                            ? characterOffsetX : characterTransform.x - 482.5),
            offsetY: Number(characterTransform.y === undefined
                            ? characterOffsetY : characterTransform.y - 25),
            flipX: Boolean(characterTransform.flipX === undefined
                           ? characterFlipX : characterTransform.flipX)
        }
        const gallery = []
        for (let index = 0; index < 3; index += 1) {
            gallery.push({
                path: String(galleryPaths[index] || ""),
                scale: Number(galleryScales[index] || 1),
                offsetX: Number(galleryOffsetsX[index] || 0),
                offsetY: Number(galleryOffsetsY[index] || 0),
                flipX: Boolean(galleryFlipX[index])
            })
        }
        return {
            schemaVersion: 8,
            canvas: { width: 1600, height: 900 },
            character: character,
            gallery: gallery,
            galleryOrder: normalizedGalleryOrder(galleryOrder),
            scene: { layers: clone(sceneLayers) },
            sharedWidgets: {
                surfaceMode: widgetSurfaceMode,
                blurEnabled: widgetBlurEnabled,
                layoutTemplate: desktopLayoutTemplate,
                layoutSeed: desktopLayoutSeed,
                items: clone(sharedWidgets)
            },
            calendar: { reminders: clone(calendarReminders) },
            topbarLayout: clone(topbarLayout),
            topbar: {
                toolsOrder: clone(topbarToolsOrder),
                height: topbarHeight,
                scale: topbarScale,
                gap: topbarGap,
                margin: topbarMargin
            },
            profile: {
                displayName: profileName,
                greeting: greeting,
                verticalLabel: verticalLabel,
                avatar: String(avatarPath || "")
            },
            appearance: {
                visualStyle: visualStyle,
                colorScheme: colorScheme,
                material: materialMode,
                surfaceOpacity: surfaceOpacity,
                blurStrength: blurStrength,
                contrast: appearanceContrast,
                reflection: reflectionStrength,
                accentMode: accentMode,
                pywalTone: pywalTone,
                accentColor: String(accentColor),
                customColors: clone(customColors),
                characterPywal: characterPywal,
                waterCausticsEnabled: waterCausticsEnabled,
                waterCausticsIntensity: waterCausticsIntensity,
                waterCausticsLines: waterCausticsLines,
                waterCausticsModules: waterCausticsModules,
                lockDimmingMode: lockDimmingMode,
                lockDimmingAmount: lockDimmingAmount
            }
        }
    }

    function applyComposition(snapshot, profileSeed) {
        if (!isObject(snapshot) || !isObject(snapshot.character)
                || !Array.isArray(snapshot.gallery) || snapshot.gallery.length !== 3)
            return false
        const character = normalizedCharacterEntry(snapshot.character)
        const gallery = snapshot.gallery.map(function(entry) {
            return normalizedGalleryEntry(entry)
        })
        let next = isObject(userData) ? clone(userData) : ({})
        next.schemaVersion = supportedSchemaVersion
        next = setAt(next, "lockPreview.character", character)
        next = setAt(next, "lockPreview.gallery", gallery)
        next = setAt(next, "lockPreview.galleryOrder",
                     normalizedGalleryOrder(snapshot.galleryOrder))
        const sceneSource = isObject(snapshot.scene) && Array.isArray(snapshot.scene.layers)
            ? snapshot.scene.layers : legacySceneForDocument(merge(defaultsData, next))
        const normalizedScene = lockOnlySceneLayers(normalizedSceneLayers(sceneSource))
        next = setAt(next, "lockPreview.scene.layers", normalizedScene)
        const snapshotVersion = Number(snapshot.schemaVersion || 1)
        if (snapshotVersion < 7) {
            next = setAt(next, "appearance.visualStyle", "classic")
            next = setAt(next, "appearance.colorScheme", "dark")
            next = setAt(next, "appearance.material", "glass")
            next = setAt(next, "topbar.margin", 0)
        }
        const requestedSeed = String(profileSeed
            || (isObject(snapshot.sharedWidgets)
                ? snapshot.sharedWidgets.layoutSeed : "")
            || desktopLayoutSeed || "active-config")
        const requestedTemplate = isObject(snapshot.sharedWidgets)
            ? String(snapshot.sharedWidgets.layoutTemplate || "") : ""
        const normalizedRequestedTemplate = normalizeDesktopTemplateName(
            requestedTemplate, "")
        const widgetSource = isObject(snapshot.sharedWidgets)
                && Array.isArray(snapshot.sharedWidgets.items)
                && snapshotVersion >= 4
                && logicalWidgetSetComplete(snapshot.sharedWidgets.items)
            ? snapshot.sharedWidgets.items
            : migratedSharedWidgets(
                isObject(snapshot.sharedWidgets)
                    ? snapshot.sharedWidgets.items : [],
                sceneSource,
                valueAt(defaultsData, "lockPreview.sharedWidgets.items", []),
                normalizedRequestedTemplate.length > 0
                    ? normalizedRequestedTemplate : templateForSeed(requestedSeed),
                requestedSeed)
        const normalizedWidgets = normalizedSharedWidgets(widgetSource)
        // Profiles and wallpaper saves own literal coordinates. Never
        // regenerate them from a seed while applying a composition.
        const resolvedTemplate = "custom"
        next = setAt(next, "lockPreview.sharedWidgets.items",
                     normalizedWidgets)
        next = setAt(next, "lockPreview.sharedWidgets.layoutSeed", requestedSeed)
        next = setAt(next, "lockPreview.sharedWidgets.layoutTemplate",
                     resolvedTemplate)
        if (isObject(snapshot.sharedWidgets)) {
            if (typeof snapshot.sharedWidgets.blurEnabled === "boolean")
                next = setAt(next, "lockPreview.sharedWidgets.blurEnabled", snapshot.sharedWidgets.blurEnabled)
            const requestedSurfaceMode = String(
                snapshot.sharedWidgets.surfaceMode || widgetSurfaceMode)
            next = setAt(next, "lockPreview.sharedWidgets.surfaceMode",
                ["solid", "bar"].includes(requestedSurfaceMode)
                    ? requestedSurfaceMode : "solid")
        }
        if (isObject(snapshot.profile)) {
            next = setAt(next, "profile.displayName", String(snapshot.profile.displayName || profileName))
            next = setAt(next, "profile.greeting", String(snapshot.profile.greeting || greeting))
            next = setAt(next, "profile.verticalLabel", String(snapshot.profile.verticalLabel || verticalLabel))
            if (snapshot.profile.avatar !== undefined)
                next = setAt(next, "profile.avatar", String(snapshot.profile.avatar || ""))
        }
        if (isObject(snapshot.appearance)) {
            const snapshotStyle = String(snapshot.appearance.visualStyle
                || (snapshotVersion < 7 ? "classic" : "editorial"))
            next = setAt(next, "appearance.visualStyle",
                ["editorial", "classic", "minimal"].includes(snapshotStyle)
                    ? snapshotStyle : "classic")
            const snapshotScheme = String(snapshot.appearance.colorScheme || "dark")
            next = setAt(next, "appearance.colorScheme",
                ["dark", "light"].includes(snapshotScheme)
                    ? snapshotScheme : "dark")
            const snapshotMaterial = String(snapshot.appearance.material || "glass")
            next = setAt(next, "appearance.material",
                ["glass", "solid", "adaptive"].includes(snapshotMaterial)
                    ? snapshotMaterial : "glass")
            const appearanceNumber = function(value, fallback, minimum, maximum) {
                const parsed = Number(value)
                return isFinite(parsed) ? Math.max(minimum,
                    Math.min(maximum, parsed)) : fallback
            }
            next = setAt(next, "appearance.surfaceOpacity", appearanceNumber(
                snapshot.appearance.surfaceOpacity, 0.82, 0.45, 1))
            next = setAt(next, "appearance.blurStrength", appearanceNumber(
                snapshot.appearance.blurStrength, 0.55, 0, 1))
            next = setAt(next, "appearance.contrast", appearanceNumber(
                snapshot.appearance.contrast, 1.08, 0.8, 1.35))
            next = setAt(next, "appearance.reflection", appearanceNumber(
                snapshot.appearance.reflection, 0.35, 0, 1))
            const snapshotAccentMode = String(
                snapshot.appearance.accentMode || "wallpaper")
            next = setAt(next, "appearance.accentMode",
                ["wallpaper", "custom"].includes(snapshotAccentMode)
                    ? snapshotAccentMode : "wallpaper")
            const snapshotPywalTone = String(
                snapshot.appearance.pywalTone || "auto")
            next = setAt(next, "appearance.pywalTone",
                ["auto", "dark", "light"].includes(snapshotPywalTone)
                    ? snapshotPywalTone : "auto")
            const snapshotAccent = String(
                snapshot.appearance.accentColor || "#c8788f")
            next = setAt(next, "appearance.accentColor",
                /^#[0-9a-fA-F]{6}$/.test(snapshotAccent)
                    ? snapshotAccent : "#c8788f")
            next = setAt(next, "appearance.customColors",
                         normalizedCustomColors(snapshot.appearance.customColors))
            next = setAt(next, "appearance.characterPywal",
                         Boolean(snapshot.appearance.characterPywal))
            next = setAt(next, "lockPreview.caustics.enabled",
                         snapshot.appearance.waterCausticsEnabled === undefined
                            ? true : Boolean(snapshot.appearance.waterCausticsEnabled))
            const causticsIntensity = Number(
                snapshot.appearance.waterCausticsIntensity)
            next = setAt(next, "lockPreview.caustics.intensity",
                         isFinite(causticsIntensity)
                            ? Math.max(0, Math.min(1, causticsIntensity)) : 0.32)
            next = setAt(next, "lockPreview.caustics.lines",
                         snapshot.appearance.waterCausticsLines === undefined
                            ? true : Boolean(snapshot.appearance.waterCausticsLines))
            next = setAt(next, "lockPreview.caustics.modules",
                         Boolean(snapshot.appearance.waterCausticsModules))
            const dimmingMode = String(snapshot.appearance.lockDimmingMode || "off")
            next = setAt(next, "lockPreview.dimming.mode",
                         ["off", "background", "panel", "both"].includes(dimmingMode)
                            ? dimmingMode : "off")
            const dimmingAmount = Number(snapshot.appearance.lockDimmingAmount)
            next = setAt(next, "lockPreview.dimming.amount",
                         isFinite(dimmingAmount)
                            ? Math.max(0, Math.min(0.72, dimmingAmount)) : 0.28)
        }
        if (isObject(snapshot.calendar))
            next = setAt(next, "lockPreview.calendar.reminders",
                         normalizedReminders(snapshot.calendar.reminders))
        next = setAt(next, "topbar.layout", normalizedTopbarLayout(
            Array.isArray(snapshot.topbarLayout)
                ? snapshot.topbarLayout : defaultTopbarLayout()))
        if (snapshotVersion >= 7 && isObject(snapshot.topbar)) {
            if (Array.isArray(snapshot.topbar.toolsOrder))
                next = setAt(next, "topbar.toolsOrder", TopBarOrder.normalize(snapshot.topbar.toolsOrder))
            const metric = function(value, fallback, minimum, maximum) {
                const parsed = Number(value)
                return isFinite(parsed) ? Math.max(minimum,
                    Math.min(maximum, parsed)) : fallback
            }
            next = setAt(next, "topbar.height", metric(
                snapshot.topbar.height, 40, 36, 52))
            next = setAt(next, "topbar.scale", metric(
                snapshot.topbar.scale, 1, 0.75, 1.35))
            next = setAt(next, "topbar.gap", metric(
                snapshot.topbar.gap, 4, 0, 12))
            next = setAt(next, "topbar.margin", metric(
                snapshot.topbar.margin, 8, 6, 20))
        }
        userData = next
        recompute()
        saveTimer.restart()
        return true
    }

    function applyReferenceAppearance() {
        let next = clone(userData)
        next = setAt(next, "appearance.stylePreset", "reference")
        next = setAt(next, "appearance.referenceVersion", 3)
        next = setAt(next, "appearance.accentMode", "wallpaper")
        next = setAt(next, "appearance.colorScheme", "dark")
        next = setAt(next, "appearance.locale", "pt_BR")
        next = setAt(next, "topbar.height", 40)
        next = setAt(next, "bar.material", valueAt(next,
            "bar.material", "glass"))
        next = setAt(next, "bar.opacity", valueAt(next,
            "bar.opacity", 0.52))
        next = setAt(next, "bar.waveStrength", valueAt(next,
            "bar.waveStrength", 0.28))
        next = setAt(next, "lockPreview.sharedWidgets.surfaceMode",
            valueAt(next, "lockPreview.sharedWidgets.surfaceMode", "solid"))
        userData = next
        recompute()
        saveTimer.restart()
        return true
    }

    function setValue(path, value) {
        let next = isObject(userData) ? clone(userData) : ({})
        next.schemaVersion = supportedSchemaVersion
        userData = setAt(next, path, value)
        recompute()
        saveTimer.restart()
    }

    function appearanceSnapshot() {
        return {
            locale: localeName,
            reducedMotion: reducedMotion,
            motionPreset: motionPreset,
            intelligentContrast: intelligentContrast,
            reduceTransparency: reduceTransparency,
            visualStyle: visualStyle,
            colorScheme: colorScheme,
            material: materialMode,
            surfaceOpacity: surfaceOpacity,
            blurStrength: blurStrength,
            contrast: appearanceContrast,
            reflection: reflectionStrength,
            accentMode: accentMode,
            pywalTone: pywalTone,
            accentColor: String(accentColor),
            customColors: clone(customColors),
            characterPywal: characterPywal
        }
    }

    function applyAppearance(values) {
        const source = isObject(values) ? values : ({})
        let next = isObject(userData) ? clone(userData) : ({})
        next.schemaVersion = supportedSchemaVersion
        const put = function(name, value) {
            next = setAt(next, "appearance." + name, value)
        }
        const style = String(source.visualStyle || visualStyle)
        const scheme = String(source.colorScheme || colorScheme)
        const material = String(source.material || materialMode)
        const motionValue = String(source.motionPreset || motionPreset)
        const accentValue = String(source.accentColor || String(accentColor))
        put("locale", String(source.locale || localeName))
        put("reducedMotion", source.reducedMotion === undefined
            ? reducedMotion : Boolean(source.reducedMotion))
        put("motionPreset", ["calm", "balanced", "snappy"].includes(motionValue)
            ? motionValue : "balanced")
        put("intelligentContrast", source.intelligentContrast === undefined
            ? intelligentContrast : Boolean(source.intelligentContrast))
        put("reduceTransparency", source.reduceTransparency === undefined
            ? reduceTransparency : Boolean(source.reduceTransparency))
        put("visualStyle", ["editorial", "classic", "minimal"].includes(style)
            ? style : "editorial")
        put("colorScheme", ["dark", "light"].includes(scheme) ? scheme : "dark")
        put("material", ["glass", "solid", "adaptive"].includes(material)
            ? material : "glass")
        put("surfaceOpacity", Math.max(0.45, Math.min(1,
            Number(source.surfaceOpacity === undefined
                ? surfaceOpacity : source.surfaceOpacity))))
        put("blurStrength", Math.max(0, Math.min(1,
            Number(source.blurStrength === undefined
                ? blurStrength : source.blurStrength))))
        put("contrast", Math.max(0.8, Math.min(1.35,
            Number(source.contrast === undefined
                ? appearanceContrast : source.contrast))))
        put("reflection", Math.max(0, Math.min(1,
            Number(source.reflection === undefined
                ? reflectionStrength : source.reflection))))
        const accentSource = String(source.accentMode || accentMode)
        put("accentMode", ["wallpaper", "custom"].includes(accentSource)
            ? accentSource : "wallpaper")
        const pywalToneSource = String(source.pywalTone || pywalTone)
        put("pywalTone", ["auto", "dark", "light"].includes(pywalToneSource)
            ? pywalToneSource : "auto")
        put("accentColor", /^#[0-9a-fA-F]{6}$/.test(accentValue)
            ? accentValue : "#c8788f")
        put("customColors", normalizedCustomColors(
            source.customColors === undefined ? customColors : source.customColors))
        put("characterPywal", source.characterPywal === undefined
            ? characterPywal : Boolean(source.characterPywal))
        userData = next
        recompute()
        saveTimer.restart()
        return true
    }

    function setTopbarMetrics(values) {
        const source = isObject(values) ? values : ({})
        let next = isObject(userData) ? clone(userData) : ({})
        next.schemaVersion = supportedSchemaVersion
        const metric = function(value, fallback, minimum, maximum) {
            const parsed = Number(value)
            return isFinite(parsed) ? Math.max(minimum,
                Math.min(maximum, parsed)) : fallback
        }
        if (isObject(next.topbar)) delete next.topbar.variant
        next = setAt(next, "topbar.height", metric(
            source.height, topbarHeight, 36, 52))
        next = setAt(next, "topbar.scale", metric(
            source.scale, topbarScale, 0.75, 1.35))
        next = setAt(next, "topbar.gap", metric(
            source.gap, topbarGap, 0, 12))
        next = setAt(next, "topbar.margin", metric(
            source.margin, topbarMargin, 6, 20))
        userData = next
        recompute()
        saveTimer.restart()
        return true
    }

    function setTopbarLayout(values) {
        setValue("topbar.layout", normalizedTopbarLayout(values))
        return true
    }

    function topbarToolLabel(type) { return TopBarOrder.label(type) }
    function moveTopbarTool(type, target) {
        if (!topbarToolsOrder.includes(type) || !topbarToolsOrder.includes(target)) return false
        setValue("topbar.toolsOrder", TopBarOrder.move(topbarToolsOrder, type, target))
        return true
    }
    function stepTopbarTool(type, direction) {
        const index = topbarToolsOrder.indexOf(type)
        const next = index + (direction < 0 ? -1 : 1)
        if (index < 0 || next < 0 || next >= topbarToolsOrder.length) return false
        return moveTopbarTool(type, topbarToolsOrder[next])
    }

    function setTopbarItemEnabled(identifier, enabled) {
        const next = clone(topbarLayout)
        for (let index = 0; index < next.length; index += 1) {
            if (String(next[index].id) === String(identifier)) {
                next[index].enabled = Boolean(enabled)
                return setTopbarLayout(next)
            }
        }
        return false
    }

    function moveTopbarItem(identifier, direction) {
        const next = clone(topbarLayout)
        const current = next.findIndex(function(item) {
            return String(item.id) === String(identifier)
        })
        if (current < 0)
            return false
        const section = next[current].section
        const siblings = next.filter(function(item) {
            return item.section === section
        }).sort(function(a, b) { return a.order - b.order })
        const position = siblings.findIndex(function(item) {
            return String(item.id) === String(identifier)
        })
        const target = Math.max(0, Math.min(siblings.length - 1,
            position + (Number(direction) < 0 ? -1 : 1)))
        if (position === target)
            return false
        const otherId = siblings[target].id
        const other = next.findIndex(function(item) {
            return String(item.id) === String(otherId)
        })
        const previousOrder = next[current].order
        next[current].order = next[other].order
        next[other].order = previousOrder
        return setTopbarLayout(next)
    }

    function moveTopbarItemToSection(identifier, section) {
        if (!["left", "center", "right"].includes(String(section)))
            return false
        const next = clone(topbarLayout)
        const current = next.findIndex(function(item) {
            return String(item.id) === String(identifier)
        })
        if (current < 0)
            return false
        if (next[current].section === String(section))
            return false
        next[current].section = String(section)
        next[current].order = next.filter(function(item) {
            return item.section === section && String(item.id) !== String(identifier)
        }).length
        return setTopbarLayout(next)
    }

    function resetTopbarLayout() {
        return setTopbarLayout(defaultTopbarLayout())
    }

    function setCharacterValue(field, value) {
        if (!["path", "scale", "offsetX", "offsetY", "flipX"].includes(field))
            return false
        setValue("lockPreview.character." + field, value)
        return true
    }

    function setCharacterPywal(enabled) {
        setValue("appearance.characterPywal", Boolean(enabled))
        return true
    }

    function setCustomColor(role, value) {
        const requestedRole = String(role)
        const nextColors = normalizedCustomColors(customColors)
        const candidate = String(value || "").toLowerCase()
        if (nextColors[requestedRole] === undefined
                || !/^#[0-9a-f]{6}$/.test(candidate))
            return false
        nextColors[requestedRole] = candidate
        let next = isObject(userData) ? clone(userData) : ({})
        next.schemaVersion = supportedSchemaVersion
        next = setAt(next, "appearance.accentMode", "custom")
        next = setAt(next, "appearance.customColors", nextColors)
        if (requestedRole === "accent")
            next = setAt(next, "appearance.accentColor", candidate)
        userData = next
        recompute()
        saveTimer.restart()
        return true
    }

    function setClockValue(field, value) {
        if (!["scale", "offsetX", "offsetY"].includes(field))
            return false
        setValue("lockPreview.clock." + field, value)
        return true
    }

    function setProfileValue(field, value) {
        if (!["greeting", "verticalLabel"].includes(field))
            return false
        setValue("profile." + field, String(value))
        return true
    }

    function setTitleValue(target, field, value) {
        if (!["greeting", "vertical"].includes(target)
                || !["fontSize", "offsetX", "offsetY"].includes(field))
            return false
        setValue("lockPreview.titles." + target + "." + field, value)
        return true
    }

    function resetClockTransform() {
        setClockValue("scale", 1.0)
        setClockValue("offsetX", 0)
        setClockValue("offsetY", 0)
    }

    function resetTitleTransform(target) {
        const name = target === "vertical" ? "vertical" : "greeting"
        setTitleValue(name, "fontSize", name === "vertical" ? 19 : 25)
        setTitleValue(name, "offsetX", 0)
        setTitleValue(name, "offsetY", 0)
    }

    function setGalleryValue(index, field, value) {
        const target = Math.max(0, Math.min(2, Number(index)))
        if (!["path", "scale", "offsetX", "offsetY", "flipX"].includes(field))
            return false
        const entries = resolvedGalleryEntries()
        if (entries.length !== 3)
            return false
        entries[target][field] = value
        setValue("lockPreview.gallery", entries)
        return true
    }

    function setGalleryOrder(order) {
        const normalized = normalizedGalleryOrder(order)
        if (JSON.stringify(normalized) !== JSON.stringify(order))
            return false
        setValue("lockPreview.galleryOrder", normalized)
        return true
    }

    function setCalendarReminders(values) {
        const normalized = normalizedReminders(values)
        setValue("lockPreview.calendar.reminders", normalized)
        return true
    }

    function resetVisualTransform(target) {
        const selected = Number(target)
        if (selected === 0) {
            setCharacterValue("scale", 1.0)
            setCharacterValue("offsetX", 0)
            setCharacterValue("offsetY", 0)
            setCharacterValue("flipX", false)
            return true
        }
        const index = selected - 1
        if (index < 0 || index > 2)
            return false
        const entries = resolvedGalleryEntries()
        entries[index].scale = 1.0
        entries[index].offsetX = 0
        entries[index].offsetY = 0
        entries[index].flipX = false
        setValue("lockPreview.gallery", entries)
        return true
    }

    function assetStatus() {
        return {
            character: characterPath,
            avatar: avatarPath,
            galleryCount: galleryPaths.length,
            dockCount: dockEntries.length
        }
    }

    function persistSchemaMigration() {
        if (!ready || Object.keys(userData).length === 0) {
            migrationQueued = false
            return false
        }
        let next = clone(userData)
        next.schemaVersion = supportedSchemaVersion
        next = setAt(next, "appearance.motionPreset", motionPreset)
        next = setAt(next, "appearance.intelligentContrast", intelligentContrast)
        next = setAt(next, "appearance.reduceTransparency", reduceTransparency)
        next = setAt(next, "appearance.visualStyle", visualStyle)
        next = setAt(next, "appearance.colorScheme", colorScheme)
        next = setAt(next, "appearance.material", materialMode)
        next = setAt(next, "appearance.surfaceOpacity", surfaceOpacity)
        next = setAt(next, "appearance.blurStrength", blurStrength)
        next = setAt(next, "appearance.contrast", appearanceContrast)
        next = setAt(next, "appearance.reflection", reflectionStrength)
        next = setAt(next, "appearance.accentMode", accentMode)
        next = setAt(next, "appearance.pywalTone", pywalTone)
        next = setAt(next, "appearance.accentColor", String(accentColor))
        next = setAt(next, "appearance.customColors", clone(customColors))
        next = setAt(next, "lockPreview.scene.layers", sceneLayers)
        next = setAt(next, "lockPreview.sharedWidgets.items", sharedWidgets)
        next = setAt(next, "lockPreview.sharedWidgets.layoutTemplate",
                     desktopLayoutTemplate)
        next = setAt(next, "lockPreview.sharedWidgets.layoutSeed",
                     desktopLayoutSeed)
        next = setAt(next, "lockPreview.sharedWidgets.surfaceMode",
                     widgetSurfaceMode)
        next = setAt(next, "lockPreview.calendar.reminders", calendarReminders)
        next = setAt(next, "topbar.layout", topbarLayout)
        next = setAt(next, "topbar.height", topbarHeight)
        next = setAt(next, "topbar.scale", topbarScale)
        next = setAt(next, "topbar.gap", topbarGap)
        next = setAt(next, "topbar.margin", topbarMargin)
        next = setAt(next, "bar.material", barMaterial)
        next = setAt(next, "bar.opacity", barOpacity)
        next = setAt(next, "bar.waveStrength", barWaveStrength)
        userData = next
        migrationQueued = false
        saveTimer.restart()
        return true
    }

    FileView {
        id: defaultsFile
        path: Quickshell.shellDir + "/config/default.json"
        printErrors: true
        onLoaded: {
            const result = root.parse(text(), "defaults", root.defaultsData)
            if (result.ok)
                root.defaultsData = result.data
            root.recompute()
        }
        onLoadFailed: root.configurationError("Unable to load config/default.json")
    }

    FileView {
        id: userFile
        path: root.configPath
        atomicWrites: true
        onSaved: { root.saveError = ""; root.savePending = false }
        onSaveFailed: function(code) {
            root.saveError = "Não foi possível salvar as configurações (" + code + ")."
            root.savePending = false
        }
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const result = root.parse(text(), root.configPath, root.userData)
            if (result.ok)
                root.userData = result.data
            root.recompute()
        }
        onLoadFailed: function(errorCode) {
            if (errorCode === FileViewError.FileNotFound)
                root.userData = ({})
            root.recompute()
        }
    }

    Timer {
        id: migrationTimer
        interval: 40
        repeat: false
        onTriggered: root.persistSchemaMigration()
    }

    Timer {
        id: saveTimer
        interval: 220
        repeat: false
        onRunningChanged: if (running) root.savePending = true
        onTriggered: userFile.setText(JSON.stringify(root.userData, null, 2) + "\n")
    }
}
