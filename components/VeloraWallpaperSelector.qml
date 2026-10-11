import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var theme: null
    property alias surfaceItem: panelSurface
    property bool externalSurface: false
    property string attachSide: "left"
    readonly property int cornerRadius: 28
    readonly property bool pywalStyle: theme && theme.themeId === "pywal16"
    readonly property bool neon: pywalStyle && theme.themeMode === "dark"
    readonly property color ink: theme ? theme.textPrimary : Qt.rgba(0.90, 0.88, 0.92, 0.94)
    readonly property color inkSoft: theme ? theme.textSecondary : Qt.rgba(0.78, 0.74, 0.82, 0.70)
    readonly property color pink: theme ? (pywalStyle ? theme.accentSecondary : theme.accentPrimary) : Qt.rgba(0.88, 0.43, 0.66, 0.92)
    readonly property color lilac: theme ? (pywalStyle ? theme.accentPrimary : theme.accentSecondary) : Qt.rgba(0.58, 0.48, 0.73, 0.78)
    readonly property color glass: theme ? theme.surfacePopup : Qt.rgba(0.10, 0.09, 0.11, 0.82)
    readonly property color card: theme ? theme.surfaceCard : Qt.rgba(1, 1, 1, 0.62)
    readonly property color borderSoft: theme ? theme.borderSoft : Qt.rgba(1, 1, 1, 0.38)
    readonly property color selectorEdge: theme ? (pywalStyle && theme.borderAdaptEnabled ? theme.popupBorderGlow : theme.borderActive) : pink
    readonly property color selectorTint: theme ? (pywalStyle && theme.borderAdaptEnabled ? theme.popupBorderGlow : theme.accentPrimary) : pink
    readonly property string uiFont: theme ? theme.uiFont : "Noto Sans CJK JP"
    readonly property string monoFont: theme ? theme.monoFont : "JetBrainsMono Nerd Font"
    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string wallpaperDir: homeDir + "/Pictures/Wallpapers"
    readonly property string applyScript: Quickshell.shellDir + "/scripts/velora-wallpaper-apply"
    readonly property string scanScript: Quickshell.shellDir + "/scripts/velora-wallpaper-scan"
    readonly property string visibilityScript: Quickshell.shellDir + "/scripts/velora-wallpaper-visibility"
    readonly property var filterKeys: ["all", "static", "live", "engine"]
    readonly property var modeFilterIndexes: [1, 2, 3]
    readonly property var fallbackWallpapers: []

    property int activeFilter: 1
    property int selectedIndex: 2
    property int deckLastIndex: selectedIndex
    property int deckDirection: 1
    property bool suppressDeckAnimation: false
    property real coverflowRunningIndex: selectedIndex
    property real coverflowAnimationIndex: selectedIndex
    property bool rouletteSpinning: false
    property int rouletteTargetIndex: selectedIndex
    property int rouletteSpinStepsRemaining: 0
    property int rouletteSpinTotalSteps: 0
    property bool loadedOnce: false
    property bool scanComplete: false
    property bool open: visible
    property bool preload: false
    property bool visibilitySaveQueued: false
    property var allWallpapers: fallbackWallpapers
    property var wallpapers: fallbackWallpapers
    property var lowerWallpapers: []
    property var hiddenWallpapers: []
    property real revealProgress: 0
    property real wheelProgress: 1
    property real rouletteRotation: 0
    property real modeSwapProgress: 1
    property real applyPulse: 0
    readonly property bool contentActive: visible || open || revealProgress > 0.01
    readonly property bool showcaseLayout: width >= 720
    readonly property int wallcardsOpenDuration: 640
    readonly property int wallcardsMoveDuration: 540
    readonly property int wallcardsCloseDuration: Math.max(170, motionPanelOut)
    readonly property int preloadThumbLimit: 36
    readonly property int preloadHeroLimit: 0
    readonly property int motionFast: theme ? theme.motionFast : 120
    readonly property int motionSlow: theme ? theme.motionSlow : 320
    readonly property int motionPanelIn: theme ? theme.motionPanelIn : 220
    readonly property int motionPanelOut: theme ? theme.motionPanelOut : 140
    readonly property int motionHover: theme ? theme.motionHover : 120
    readonly property int motionPanelOffset: theme ? theme.motionPanelOffset : 28
    readonly property int motionEaseEnter: theme ? theme.motionEaseEnter : Easing.OutCubic
    readonly property int motionEaseExit: theme ? theme.motionEaseExit : Easing.InCubic
    readonly property int motionEaseHover: theme ? theme.motionEaseHover : Easing.OutCubic

    signal closeRequested()
    signal visibilityRequested()

    opacity: open ? 1 : revealProgress
    scale: 1
    transformOrigin: Item.Top
    focus: visible
    activeFocusOnTab: true

    transform: Translate {
        y: 0
    }

    onOpenChanged: {
        animateReveal()
        if (open)
            ensureLoaded()
    }

    onPreloadChanged: {
        if (preload)
            ensureLoaded()
    }

    onVisibleChanged: {
        if (visible && open && revealProgress <= 0.001 && !revealAnimation.running)
            animateReveal()
        if (visible && open)
            ensureLoaded()
    }

    onActiveFilterChanged: {
        refreshWallpapers()
        syncModeFromFilter()
    }

    onAllWallpapersChanged: refreshWallpapers()
    onHiddenWallpapersChanged: refreshWallpapers()
    onSelectedIndexChanged: startWheelTransition()

    Component.onCompleted: {
        syncWheelState()
        if (open || preload)
            ensureLoaded()
    }

    function alpha(colorValue, opacity) {
        return root.theme ? root.theme.alpha(colorValue, opacity) : Qt.rgba(colorValue.r, colorValue.g, colorValue.b, opacity)
    }

    function cssColor(colorValue, opacity) {
        const c = root.alpha(colorValue, opacity)
        return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + c.a + ")"
    }

    function animateReveal() {
        revealAnimation.stop()
        revealAnimation.from = revealProgress
        revealAnimation.to = open ? 1 : 0
        revealAnimation.duration = open ? root.wallcardsOpenDuration : root.wallcardsCloseDuration
        revealAnimation.easing.type = open ? Easing.InOutCubic : Easing.InCubic
        revealAnimation.restart()
    }

    function basename(path) {
        var name = String(path || "").split("/").pop()
        var dot = name.lastIndexOf(".")
        if (dot > 0)
            name = name.slice(0, dot)
        return name.replace(/[-_]+/g, " ")
    }

    function kindCategory(kind) {
        if (kind === "live")
            return "MPV"
        if (kind === "engine")
            return "Engine"
        return "Imagem estática"
    }

    function modeLabelFromFilter(index) {
        const key = filterKeys[Math.max(0, Math.min(index, filterKeys.length - 1))]
        if (key === "live")
            return "MPV"
        if (key === "engine")
            return "ENGINE"
        if (key === "static")
            return "STATIC"
        return "ALL"
    }

    function syncModeFromFilter() {
        if (modeFilterIndexes.indexOf(activeFilter) >= 0)
            return
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

    function wallpaperKey(entry) {
        if (!entry)
            return ""
        return String(entry.path || "")
    }

    function isWallpaperHidden(entry) {
        const key = root.wallpaperKey(entry)
        return key.length > 0 && root.hiddenWallpapers.indexOf(key) >= 0
    }

    function visibleAllWallpapers() {
        var next = []
        for (var i = 0; i < root.allWallpapers.length; i++) {
            if (!root.isWallpaperHidden(root.allWallpapers[i]))
                next.push(root.allWallpapers[i])
        }
        return next
    }

    function visibleWallpapersByKinds(kinds) {
        var next = []
        for (var i = 0; i < root.allWallpapers.length; i++) {
            const entry = root.allWallpapers[i]
            if (!entry || root.isWallpaperHidden(entry))
                continue
            if (kinds.indexOf(entry.kind || "static") >= 0)
                next.push(entry)
        }
        return next
    }

    function activeWallpaperKinds() {
        const key = filterKeys[Math.max(0, Math.min(root.activeFilter, filterKeys.length - 1))]
        if (key === "all")
            return ["static", "live", "engine"]
        return [key]
    }

    function bottomWallpapers() {
        return root.lowerWallpapers
    }

    function filterMatches(entry) {
        if (!entry || root.isWallpaperHidden(entry))
            return false

        const key = root.filterKeys[Math.max(0, Math.min(root.activeFilter, root.filterKeys.length - 1))]
        if (key === "all")
            return true
        return (entry.kind || "static") === key
    }

    function refreshWallpapers() {
        const next = root.visibleWallpapersByKinds(root.activeWallpaperKinds())

        root.suppressDeckAnimation = true
        root.wallpapers = next.length > 0 ? next : root.fallbackWallpapers
        root.lowerWallpapers = []
        root.selectedIndex = Math.max(0, Math.min(root.selectedIndex, Math.max(0, root.wallpapers.length - 1)))
        root.syncWheelState()
        root.suppressDeckAnimation = false
    }

    function ensureLoaded() {
        if (!loadedOnce) {
            loadedOnce = true
            reload()
        }
        loadVisibility()
    }

    function reload() {
        if (!scanWallpapers.running) {
            scanComplete = false
            scanWallpapers.running = true
        }
    }

    function loadVisibility() {
        if (!loadVisibilityProcess.running)
            loadVisibilityProcess.running = true
    }

    function queueVisibilitySave() {
        root.visibilitySaveQueued = true
        visibilitySaveDebounce.restart()
    }

    function flushVisibilitySave() {
        if (visibilitySaveProcess.running)
            return

        root.visibilitySaveQueued = false
        visibilitySaveProcess.command = [root.visibilityScript, "set", JSON.stringify(root.hiddenWallpapers)]
        visibilitySaveProcess.running = true
    }

    function normalizedIndex() {
        return Math.max(0, Math.min(root.selectedIndex, Math.max(0, root.wallpapers.length - 1)))
    }

    function currentWallpaper() {
        if (root.wallpapers.length > 0)
            return root.wallpapers[root.normalizedIndex()]
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

    function currentWallpaperTitle() {
        return root.currentWallpaper().title || root.currentWallpaper().label || root.basename(root.currentWallpaper().path)
    }

    function currentWallpaperCategory() {
        return root.currentWallpaper().category || root.kindCategory(root.currentWallpaperKind())
    }

    function currentWallpaperTags() {
        const kind = root.currentWallpaperKind()
        var tags = [root.modeLabelFromFilter(root.activeFilter), root.currentWallpaperCategory()]
        if (kind === "static")
            tags.push("Still")
        else if (kind === "live")
            tags.push("Motion")
        else
            tags.push("Engine")
        tags.push(root.pywalStyle ? "Pywal" : "Velora")
        return tags
    }

    function paletteSwatch(index) {
        if (!root.theme) {
            const fallback = [
                Qt.rgba(0.40, 0.42, 0.58, 1),
                Qt.rgba(0.58, 0.62, 0.78, 1),
                Qt.rgba(0.66, 0.58, 0.82, 1),
                Qt.rgba(0.88, 0.58, 0.74, 1),
                Qt.rgba(0.96, 0.76, 0.86, 1)
            ]
            return fallback[Math.max(0, Math.min(index, fallback.length - 1))]
        }

        const colors = [
            root.theme.accentPrimary,
            root.theme.accentSecondary,
            root.theme.accentTertiary,
            root.theme.textSecondary,
            root.theme.surfaceCard
        ]
        return colors[Math.max(0, Math.min(index, colors.length - 1))]
    }

    function preloadWallpaper(index) {
        const list = root.allWallpapers.length > 0 ? root.allWallpapers : root.fallbackWallpapers
        if (list.length <= 0)
            return null
        return list[Math.max(0, Math.min(index, list.length - 1))]
    }

    function selectionDirection(fromIndex, toIndex) {
        const count = root.wallpapers.length
        if (count <= 1 || fromIndex === toIndex)
            return root.deckDirection
        if (fromIndex === count - 1 && toIndex === 0)
            return 1
        if (fromIndex === 0 && toIndex === count - 1)
            return -1
        return toIndex > fromIndex ? 1 : -1
    }

    function selectionDelta(fromIndex, toIndex) {
        const count = root.wallpapers.length
        if (count <= 1 || fromIndex === toIndex)
            return 0

        var diff = toIndex - fromIndex
        const half = count / 2
        if (diff > half)
            diff -= count
        else if (diff < -half)
            diff += count
        return diff
    }

    function rouletteStep() {
        const count = Math.max(1, root.wheelSlotCount())
        return 180 / count
    }

    function rouletteBaseRotation(index) {
        const count = Math.max(1, root.wheelSlotCount())
        return 90 - (Math.max(0, index) + 0.5) * (180 / count)
    }

    function nearestRouletteRotation(index) {
        const base = root.rouletteBaseRotation(index)
        const turns = Math.round((root.rouletteRotation - base) / 360)
        return base + turns * 360
    }

    function syncRouletteRotation() {
        rouletteSettleAnimation.stop()
        rouletteSpinAnimation.stop()
        root.rouletteRotation = 0
    }

    function syncWheelState() {
        wheelAnimation.stop()
        coverflowIndexAnimation.stop()
        root.deckLastIndex = root.normalizedIndex()
        root.wheelProgress = 1
        root.coverflowRunningIndex = root.deckLastIndex
        root.coverflowAnimationIndex = root.coverflowRunningIndex
        root.syncRouletteRotation()
    }

    function startWheelTransition() {
        if (root.suppressDeckAnimation) {
            root.syncWheelState()
            return
        }

        const count = root.wallpapers.length
        if (count <= 0)
            return

        const nextIndex = root.normalizedIndex()
        const prevIndex = Math.max(0, Math.min(root.deckLastIndex, count - 1))
        if (prevIndex === nextIndex)
            return

        const delta = root.selectionDelta(prevIndex, nextIndex)
        if (delta === 0)
            return

        coverflowIndexAnimation.stop()
        rouletteSettleAnimation.stop()
        root.deckDirection = delta > 0 ? 1 : -1
        root.deckLastIndex = nextIndex
        root.coverflowRunningIndex += delta
        root.wheelProgress = 1
        coverflowIndexAnimation.duration = root.wallcardsMoveDuration
        coverflowIndexAnimation.easing.type = Easing.InOutCubic
        coverflowIndexAnimation.from = root.coverflowAnimationIndex
        coverflowIndexAnimation.to = root.coverflowRunningIndex
        coverflowIndexAnimation.restart()
    }

    function moveSelection(dir) {
        const count = root.wallpapers.length
        if (count <= 0)
            return
        root.selectedIndex = (root.selectedIndex + dir + count) % count
    }

    function wheelSlotCount() {
        if (root.wallpapers.length <= 0)
            return 1
        if (root.wallpapers.length <= 4)
            return root.wallpapers.length

        const visible = Math.min(13, root.wallpapers.length)
        return visible % 2 === 0 ? visible - 1 : visible
    }

    function wheelIndex(slot) {
        const count = root.wallpapers.length
        if (count <= 0)
            return 0
        const visibleCount = root.wheelSlotCount()
        const center = Math.floor(visibleCount / 2)
        return (root.selectedIndex - center + slot + count) % count
    }

    function wheelWallpaper(slot) {
        if (root.wallpapers.length <= 0)
            return (root.fallbackWallpapers[0] || ({}))
        return root.wallpapers[root.wheelIndex(slot)]
    }

    function wheelBoundaryAngle(offset, slotCount) {
        const centerSlot = Math.floor(slotCount / 2)
        const leftSpan = Math.max(1, centerSlot + 0.5)
        const rightSpan = Math.max(1, slotCount - centerSlot - 0.5)
        const span = offset < 0 ? leftSpan : rightSpan
        const sign = offset < 0 ? -1 : 1
        const distance = Math.min(Math.abs(offset), span)

        if (distance <= 0.001)
            return 0

        const centerHalf = slotCount <= 3 ? 42 : (slotCount <= 5 ? 37 : 38)
        const maxAngle = 88
        if (distance <= 0.5)
            return sign * centerHalf * (distance / 0.5)

        const sideT = Math.min(1, (distance - 0.5) / Math.max(0.001, span - 0.5))
        const compressed = Math.pow(sideT, 0.90)
        return sign * (centerHalf + (maxAngle - centerHalf) * compressed)
    }

    function bottomWheelSlotCount() {
        return root.lowerWallpapers.length > 0 ? 7 : 0
    }

    function bottomWheelWallpaper(slot) {
        const list = root.lowerWallpapers
        if (list.length <= 0)
            return null
        const center = Math.floor(root.bottomWheelSlotCount() / 2)
        return list[(slot - center + list.length) % list.length]
    }

    function setModeFilter(index) {
        if (root.activeFilter === index)
            return
        modeSwapAnimation.stop()
        root.modeSwapProgress = 0
        root.activeFilter = index
        modeSwapAnimation.restart()
    }

    function cycleWallpaperMode(dir) {
        var current = root.modeFilterIndexes.indexOf(root.activeFilter)
        if (current < 0)
            current = 0
        const next = (current + dir + root.modeFilterIndexes.length) % root.modeFilterIndexes.length
        root.setModeFilter(root.modeFilterIndexes[next])
    }

    function spinRoulette() {
        const count = root.wallpapers.length
        if (count <= 0 || root.rouletteSpinning)
            return

        var target = Math.floor(Math.random() * count)
        if (count > 1 && target === root.normalizedIndex())
            target = (target + 1 + Math.floor(Math.random() * (count - 1))) % count

        root.rouletteTargetIndex = target
        root.rouletteSpinning = true
        rouletteSettleAnimation.stop()
        rouletteSpinAnimation.stop()

        const currentIndex = root.normalizedIndex()
        var forward = (target - currentIndex + count) % count
        if (forward === 0)
            forward = count
        const turns = 4 + Math.floor(Math.random() * 3)
        root.rouletteSpinStepsRemaining = turns * count + forward
        root.rouletteSpinTotalSteps = root.rouletteSpinStepsRemaining
        rouletteStepTimer.interval = 58
        rouletteStepTimer.restart()
    }

    function applySelected() {
        if (applyWallpaper.running)
            return
        const item = root.currentWallpaper()
        if (!item.path)
            return
        applyPulseAnimation.restart()
        applyWallpaper.command = [root.applyScript, item.kind || "static", item.path, root.displaySource(item)]
        applyWallpaper.running = true
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

        if (event.key === Qt.Key_Down || event.key === Qt.Key_S) {
            root.cycleWallpaperMode(1)
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Up || event.key === Qt.Key_W) {
            root.cycleWallpaperMode(-1)
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.applySelected()
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Space) {
            root.spinRoulette()
            event.accepted = true
        }
    }

    NumberAnimation {
        id: revealAnimation

        target: root
        property: "revealProgress"
        from: root.revealProgress
        to: root.open ? 1 : 0
        duration: root.open ? root.wallcardsOpenDuration : root.wallcardsCloseDuration
        easing.type: root.open ? Easing.InOutCubic : Easing.InCubic
    }

    NumberAnimation {
        id: wheelAnimation

        target: root
        property: "wheelProgress"
        from: 0
        to: 1
        duration: 260
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: coverflowIndexAnimation

        target: root
        property: "coverflowAnimationIndex"
        duration: root.wallcardsMoveDuration
        easing.type: Easing.InOutCubic
    }

    NumberAnimation {
        id: rouletteSettleAnimation

        target: root
        property: "rouletteRotation"
        from: root.rouletteRotation
        to: root.nearestRouletteRotation(root.normalizedIndex())
        duration: Math.max(360, root.motionSlow + 120)
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: rouletteSpinAnimation

        target: root
        property: "rouletteRotation"
        from: root.rouletteRotation
        to: root.rouletteRotation
        duration: 2600
        easing.type: Easing.OutCubic

        onRunningChanged: {
            if (!running && root.rouletteSpinning) {
                root.suppressDeckAnimation = true
                root.selectedIndex = Math.max(0, Math.min(root.rouletteTargetIndex, Math.max(0, root.wallpapers.length - 1)))
                root.deckLastIndex = root.selectedIndex
                root.wheelProgress = 1
                root.suppressDeckAnimation = false
                root.rouletteSpinning = false
            }
        }
    }

    Timer {
        id: rouletteStepTimer

        interval: 70
        repeat: false
        onTriggered: {
            if (root.rouletteSpinStepsRemaining <= 0) {
                root.rouletteSpinning = false
                return
            }

            root.moveSelection(1)
            root.rouletteSpinStepsRemaining--

            if (root.rouletteSpinStepsRemaining > 0) {
                const done = root.rouletteSpinTotalSteps - root.rouletteSpinStepsRemaining
                interval = Math.min(190, 58 + done * 5)
                restart()
            } else {
                root.rouletteSpinning = false
            }
        }
    }

    NumberAnimation {
        id: modeSwapAnimation

        target: root
        property: "modeSwapProgress"
        from: 0
        to: 1
        duration: Math.max(300, root.motionSlow)
        easing.type: Easing.OutCubic
    }

    SequentialAnimation {
        id: applyPulseAnimation

        NumberAnimation {
            target: root
            property: "applyPulse"
            from: 0
            to: 1
            duration: root.motionFast
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "applyPulse"
            from: 1
            to: 0
            duration: root.motionFast
            easing.type: Easing.InOutSine
        }
    }

    Process {
        id: applyWallpaper

        running: false
        command: [root.applyScript, root.currentWallpaperKind(), root.currentWallpaperPath(), root.currentWallpaperPreview()]
        onExited: {
            running = false
        }
    }

    Process {
        id: scanWallpapers

        running: false
        property var tmp: []
        command: [root.scanScript]

        onStarted: tmp = []

        stdout: SplitParser {
            onRead: function(data) {
                const line = String(data).trim()
                if (!line || line === "BEGIN")
                    return

                if (line === "END") {
                    if (scanWallpapers.tmp.length > 0)
                        root.allWallpapers = scanWallpapers.tmp.slice()
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
                    : (kind === "engine" ? "Workshop " + path : root.basename(path))
                const category = root.kindCategory(kind)

                scanWallpapers.tmp.push({
                    kind: kind,
                    path: path,
                    preview: preview,
                    title: title,
                    label: title,
                    category: category
                })
            }
        }

        onExited: {
            running = false
            if (tmp.length > 0) {
                root.allWallpapers = tmp.slice()
                root.scanComplete = true
            }
        }
    }

    Process {
        id: loadVisibilityProcess

        running: false
        command: [root.visibilityScript, "list"]

        stdout: SplitParser {
            onRead: function(data) {
                try {
                    const parsed = JSON.parse(String(data).trim() || "[]")
                    root.hiddenWallpapers = Array.isArray(parsed) ? parsed : []
                } catch(e) {
                    root.hiddenWallpapers = []
                }
            }
        }

        onExited: running = false
    }

    Timer {
        id: visibilitySaveDebounce

        interval: 180
        repeat: false
        onTriggered: root.flushVisibilitySave()
    }

    Process {
        id: visibilitySaveProcess

        running: false
        command: [root.visibilityScript, "set", "[]"]
        onExited: {
            running = false
            if (root.visibilitySaveQueued)
                visibilitySaveDebounce.restart()
        }
    }

    Item {
        id: ramPreloadCache

        width: 1
        height: 1
        opacity: 0
        visible: root.preload
        z: -1000

        Repeater {
            model: root.preload && root.scanComplete ? Math.min(root.allWallpapers.length, root.preloadThumbLimit) : 0

            Image {
                required property int index

                width: 1
                height: 1
                source: root.displaySource(root.preloadWallpaper(index))
                sourceSize.width: 320
                sourceSize.height: 192
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: false
                mipmap: false
            }
        }

        Repeater {
            model: root.preload && root.scanComplete ? Math.min(root.allWallpapers.length, root.preloadHeroLimit) : 0

            Image {
                required property int index

                width: 1
                height: 1
                source: root.displaySource(root.preloadWallpaper(index))
                sourceSize.width: 1000
                sourceSize.height: 560
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: false
                mipmap: false
            }
        }
    }

    Rectangle {
        id: panelSurface

        readonly property int infoPanelWidth: root.showcaseLayout ? 0 : Math.round(Math.min(330, Math.max(286, width * 0.245)))
        readonly property int infoGap: root.showcaseLayout ? 0 : Math.round(Math.max(24, width * 0.026))
        readonly property int leftStageWidth: root.showcaseLayout ? width : Math.max(420, width - infoPanelWidth - infoGap)
        readonly property int bottomDockHeight: 62

        anchors.fill: parent
        radius: root.externalSurface ? 0 : root.cornerRadius
        color: "transparent"
        border.width: 0
        clip: true
        antialiasing: true

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: function(mouse) { mouse.accepted = true }
        }

        Image {
            id: heroBackdrop

            anchors.fill: parent
            source: ""
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 1600
            sourceSize.height: 900
            asynchronous: true
            cache: true
            smooth: true
            visible: false
        }

        FastBlur {
            anchors.fill: parent
            source: heroBackdrop
            radius: 54
            opacity: root.pywalStyle && root.theme.themeMode === "dark" ? 0.24 : 0.34
            visible: false
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            visible: false
        }

        Rectangle {
            anchors.fill: parent
            visible: false
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, root.neon ? 0.20 : 0.16) }
                GradientStop { position: 0.48; color: Qt.rgba(0, 0, 0, root.neon ? 0.08 : 0.05) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, root.neon ? 0.24 : 0.18) }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: root.cornerRadius
            color: "transparent"
            visible: false
            border.width: 0
            border.color: root.alpha(root.borderSoft, 0.62)
        }

        Item {
            id: showcaseStage

            visible: root.showcaseLayout
            enabled: root.showcaseLayout
            x: 0
            y: 0
            width: panelSurface.leftStageWidth
            height: parent.height
            z: 66

            Rectangle {
                id: previewCard

                readonly property real preferredWidth: Math.min(700, Math.max(540, showcaseStage.width * 0.475))

                x: Math.round((showcaseStage.width - width) / 2)
                y: Math.round(Math.max(148, showcaseStage.height * 0.158) - (1 - root.revealProgress) * 18)
                width: Math.round(Math.min(showcaseStage.width - 76, preferredWidth))
                height: Math.round(width * 0.60)
                radius: 20
                color: Qt.rgba(1, 0.985, 1, root.neon ? 0.82 : 0.90)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, root.neon ? 0.72 : 0.88)
                clip: true
                antialiasing: true
                opacity: Math.min(1, root.revealProgress * 1.22)
                scale: 0.985 + root.revealProgress * 0.015
                z: 40
                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    radius: 36
                    samples: 73
                    horizontalOffset: 0
                    verticalOffset: 18
                    color: Qt.rgba(232 / 255, 136 / 255, 194 / 255, root.neon ? 0.16 : 0.12)
                }

                Behavior on x { NumberAnimation { duration: root.wallcardsMoveDuration; easing.type: Easing.InOutCubic } }
                Behavior on width { NumberAnimation { duration: root.motionSlow; easing.type: root.motionEaseHover } }

                Image {
                    anchors.fill: parent
                    anchors.margins: 8
                    source: root.contentActive ? root.currentWallpaperPreview() : ""
                    fillMode: Image.PreserveAspectCrop
                    retainWhileLoading: true
                    sourceSize.width: 1200
                    sourceSize.height: 760
                    asynchronous: true
                    cache: true
                    smooth: true
                    mipmap: true
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 8
                    radius: Math.max(0, parent.radius - 8)
                    color: "transparent"
                    border.width: 1
                    border.color: root.alpha(root.selectorEdge, 0.30)
                    antialiasing: true
                }

                Rectangle {
                    visible: false
                    x: 20
                    y: 20
                    width: previewLabel.implicitWidth + 22
                    height: 32
                    radius: 16
                    color: Qt.rgba(0.10, 0.10, 0.13, root.neon ? 0.58 : 0.42)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.18)
                    antialiasing: true

                    Text {
                        id: previewLabel

                        anchors.centerIn: parent
                        text: "Preview"
                        color: "white"
                        font.family: root.uiFont
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }
                }

                Rectangle {
                    visible: false
                    x: parent.width - width - 20
                    y: 18
                    width: 44
                    height: 44
                    radius: 22
                    color: Qt.rgba(1, 0.985, 1, 0.88)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.74)
                    antialiasing: true

                    Text {
                        anchors.centerIn: parent
                        text: "♡"
                        color: root.pink
                        font.family: root.uiFont
                        font.pixelSize: 25
                        font.weight: Font.DemiBold
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 18
                    spacing: 10

                    Repeater {
                        model: Math.min(8, Math.max(1, root.wallpapers.length))

                        Rectangle {
                            width: index === root.normalizedIndex() % Math.min(8, Math.max(1, root.wallpapers.length)) ? 12 : 9
                            height: width
                            radius: width / 2
                            color: index === root.normalizedIndex() % Math.min(8, Math.max(1, root.wallpapers.length))
                                ? root.alpha(root.pink, 0.86)
                                : Qt.rgba(1, 1, 1, 0.48)
                            border.width: 1
                            border.color: Qt.rgba(255, 255, 255, 0.28)
                            antialiasing: true
                        }
                    }
                }
            }
        }

        Item {
            id: coverflowStage

            visible: !root.showcaseLayout
            enabled: !root.showcaseLayout
            anchors.fill: parent
            clip: true
            z: 80
            readonly property real cardWidth: Math.min(width - 28, Math.max(270, width * 0.92))
            readonly property real cardHeight: cardWidth * 0.565
            readonly property real stripHeight: cardHeight * 0.42
            readonly property real cardSpacing: 1
            readonly property real deckX: Math.round(Math.max(10, (width - cardWidth) / 2))
            readonly property real deckCenterY: height * 0.52
            readonly property real deckY: Math.max(62, height * 0.12)
            readonly property real shearFactor: -0.045
            readonly property real visibleDistance: Math.max(5,
                Math.ceil((deckCenterY - cardHeight / 2 + stripHeight) / Math.max(1, stripHeight + cardSpacing)) + 2,
                Math.ceil((height - deckCenterY - cardHeight / 2 + stripHeight) / Math.max(1, stripHeight + cardSpacing)) + 2)
            readonly property real sourceKeepDistance: visibleDistance + 2
            readonly property int renderSlotCount: Math.max(5, Math.ceil(sourceKeepDistance) * 2 + 3)
            readonly property int renderCenterSlot: Math.floor(renderSlotCount / 2)
            readonly property var swatches: [
                Qt.rgba(0.93, 0.22, 0.28, 1),
                Qt.rgba(0.98, 0.56, 0.19, 1),
                Qt.rgba(0.98, 0.83, 0.24, 1),
                Qt.rgba(0.40, 0.78, 0.36, 1),
                Qt.rgba(0.26, 0.76, 0.72, 1),
                Qt.rgba(0.25, 0.55, 0.95, 1),
                Qt.rgba(0.56, 0.40, 0.96, 1),
                Qt.rgba(0.90, 0.46, 0.77, 1),
                Qt.rgba(0.95, 0.95, 0.98, 1)
            ]

            function slotBase() {
                return Math.floor(root.coverflowAnimationIndex)
            }

            function slotOffset(slot) {
                return slotBase() + slot - renderCenterSlot - root.coverflowAnimationIndex
            }

            function coverIndex(slot) {
                const count = root.wallpapers.length
                if (count <= 0)
                    return 0

                const raw = slotBase() + slot - renderCenterSlot
                return ((raw % count) + count) % count
            }

            function slotHeight(offset) {
                const t = Math.min(1, Math.abs(offset))
                return cardHeight + (stripHeight - cardHeight) * t
            }

            function slotScale(offset) {
                return slotHeight(offset) / cardHeight
            }

            function slotY(offset) {
                const centerTop = deckCenterY - cardHeight / 2
                const bottomStart = deckCenterY + cardHeight / 2 + cardSpacing
                const topStart = deckCenterY - cardHeight / 2 - cardSpacing - stripHeight

                if (offset >= 0 && offset <= 1)
                    return centerTop + (bottomStart - centerTop) * offset
                if (offset > 1)
                    return bottomStart + (offset - 1) * (stripHeight + cardSpacing)
                if (offset >= -1 && offset < 0)
                    return centerTop + (topStart - centerTop) * (-offset)
                return topStart + (offset + 1) * (stripHeight + cardSpacing)
            }

            WheelHandler {
                onWheel: function(event) {
                    const dx = Number(event.angleDelta.x)
                    const dy = Number(event.angleDelta.y)
                    const delta = Math.abs(dx) > Math.abs(dy) ? dx : dy
                    if (delta !== 0)
                        root.moveSelection(delta < 0 ? 1 : -1)
                    event.accepted = true
                }
            }

            Rectangle {
                id: swatchDock

                x: Math.round((parent.width - width) / 2)
                y: Math.round(20 - (1 - root.revealProgress) * 18)
                width: swatchRow.implicitWidth + 24
                height: 32
                opacity: Math.min(1, root.revealProgress * 1.35)
                radius: 10
                color: Qt.rgba(0.08, 0.08, 0.09, root.neon ? 0.72 : 0.68)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.14)
                antialiasing: true
                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    radius: 18
                    samples: 37
                    horizontalOffset: 0
                    verticalOffset: 8
                    color: Qt.rgba(0, 0, 0, 0.24)
                }

                Row {
                    id: swatchRow

                    anchors.centerIn: parent
                    spacing: 8

                    Item {
                        width: 24
                        height: 22

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: Qt.rgba(1, 1, 1, 0.08)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.42)
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "▦"
                            color: Qt.rgba(1, 1, 1, 0.84)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: root.monoFont
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }
                    }

                    Text {
                        width: 10
                        height: 22
                        text: "›"
                        color: Qt.rgba(1, 1, 1, 0.62)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: root.monoFont
                        font.pixelSize: 14
                        font.weight: Font.Bold
                    }

                    Repeater {
                        model: coverflowStage.swatches

                        Rectangle {
                            width: 17
                            height: 17
                            radius: 5
                            color: modelData
                            border.width: index === root.activeFilter ? 2 : 1
                            border.color: index === root.activeFilter ? Qt.rgba(1, 1, 1, 0.92) : Qt.rgba(1, 1, 1, 0.30)
                            antialiasing: true

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (index <= 3)
                                        root.setModeFilter(index)
                                }
                            }
                        }
                    }

                    Text {
                        width: 18
                        height: 22
                        text: "⌕"
                        color: Qt.rgba(1, 1, 1, 0.72)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: root.monoFont
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }
                }
            }

            Item {
                id: coverflowDeck

                x: Math.round((1 - root.revealProgress) * -64)
                y: 0
                width: parent.width
                height: parent.height
                transformOrigin: Item.Top

                Repeater {
                    model: root.contentActive && !root.showcaseLayout ? coverflowStage.renderSlotCount : 0

                    Item {
                        id: coverTile

                        required property int index
                        readonly property int wallpaperIndex: coverflowStage.coverIndex(index)
                        readonly property var entry: root.wallpapers.length > wallpaperIndex ? root.wallpapers[wallpaperIndex] : (root.fallbackWallpapers[0] || ({}))
                        readonly property real offset: coverflowStage.slotOffset(index)
                        readonly property real distance: Math.abs(offset)
                        readonly property real focusAmount: Math.max(0, 1 - Math.min(1, distance))
                        readonly property real sideAmount: Math.min(1, distance)
                        readonly property real compressScale: coverflowStage.slotScale(offset)
                        readonly property bool selected: distance < 0.22
                        readonly property bool rendered: distance <= coverflowStage.sourceKeepDistance
                        readonly property bool sourceActive: distance <= coverflowStage.sourceKeepDistance

                        width: coverflowStage.cardWidth
                        height: coverflowStage.cardHeight
                        x: coverflowStage.deckX
                        y: coverflowStage.slotY(offset)
                        z: Math.round(100 + focusAmount * 20 - distance)
                        visible: rendered
                        opacity: 1
                        transformOrigin: Item.TopLeft
                        transform: [
                            Matrix4x4 {
                                matrix: Qt.matrix4x4(1, coverflowStage.shearFactor, 0, 0,
                                                     0, 1, 0, 0,
                                                     0, 0, 1, 0,
                                                     0, 0, 0, 1)
                            },
                            Scale {
                                origin.x: 0
                                origin.y: 0
                                xScale: 1
                                yScale: coverTile.compressScale
                            }
                        ]

                        Image {
                            width: coverflowStage.cardWidth
                            height: parent.height
                            x: 0
                            y: 0
                            source: root.contentActive && coverTile.sourceActive ? root.displaySource(coverTile.entry) : ""
                            fillMode: Image.PreserveAspectCrop
                            retainWhileLoading: true
                            sourceSize.width: Math.round(coverflowStage.cardWidth * 1.5)
                            sourceSize.height: Math.round(coverflowStage.cardHeight * 1.5)
                            asynchronous: true
                            cache: true
                            smooth: true
                            mipmap: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (coverTile.selected)
                                    root.applySelected()
                                else
                                    root.moveSelection(coverTile.offset > 0 ? 1 : -1)
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: applyWallpaper.running
                x: Math.round((parent.width - width) / 2)
                y: Math.round(coverflowStage.deckY + coverflowStage.cardHeight + 26)
                width: 54
                height: 28
                radius: 14
                color: Qt.rgba(0.10, 0.09, 0.11, 0.54)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.20)

                Text {
                    anchors.centerIn: parent
                    text: "✓"
                    color: root.pink
                    font.family: root.uiFont
                    font.pixelSize: 14
                    font.weight: Font.Bold
                }
            }
        }

        Item {
            id: perspectiveStage

            visible: root.showcaseLayout
            enabled: root.showcaseLayout
            x: 0
            y: Math.round(Math.min(parent.height - height - panelSurface.bottomDockHeight - 22, previewCard.y + previewCard.height * 0.985))
            width: panelSurface.leftStageWidth
            height: Math.round(Math.max(220, Math.min(270, parent.height * 0.30)))
            clip: false
            z: 34
            readonly property real centerX: width * 0.50
            readonly property real ribbonWidth: Math.min(width - 300, 1040)
            readonly property real ribbonX: Math.round((width - ribbonWidth) / 2)
            readonly property real ribbonY: 40
            readonly property real ribbonHeight: 160
            readonly property int ribbonCardCount: 5
            readonly property int centerSlot: Math.floor(ribbonCardCount / 2)

            function slotOffset(slot) {
                return slot - centerSlot
            }

            function entryForSlot(slot) {
                const count = root.wallpapers.length
                if (count <= 0)
                    return (root.fallbackWallpapers[0] || ({}))
                const index = (root.selectedIndex + slotOffset(slot) + count) % count
                return root.wallpapers[index]
            }

            function indexForSlot(slot) {
                const count = root.wallpapers.length
                if (count <= 0)
                    return 0
                return (root.selectedIndex + slotOffset(slot) + count) % count
            }

            function slotWidth(offset) {
                const distance = Math.abs(offset)
                if (distance < 0.5)
                    return 216
                if (distance < 1.5)
                    return 176
                return 142
            }

            function slotHeight(offset) {
                return slotWidth(offset) * 0.52
            }

            function slotCenterX(offset) {
                const spacing = Math.min(194, ribbonWidth * 0.186)
                return centerX + offset * spacing
            }

            function slotCenterY(offset) {
                const distance = Math.abs(offset)
                return ribbonY + 128 - distance * 12
            }

            function slotRotation(offset) {
                return offset * 4.6
            }

            function slotYaw(offset) {
                return 0
            }

            function slotOpacity(offset) {
                return Math.max(0.62, 1 - Math.abs(offset) * 0.09)
            }

            WheelHandler {
                onWheel: function(event) {
                    if (!root.rouletteSpinning) {
                        const dx = Number(event.angleDelta.x)
                        const dy = Number(event.angleDelta.y)
                        const delta = Math.abs(dx) > Math.abs(dy) ? dx : dy
                        if (delta !== 0)
                            root.moveSelection(delta < 0 ? 1 : -1)
                    }
                    event.accepted = true
                }
            }

            Canvas {
                id: perspectivePlatform

                anchors.fill: parent
                antialiasing: true
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                Connections {
                    target: root
                    function onSelectorEdgeChanged() { perspectivePlatform.requestPaint() }
                    function onSelectorTintChanged() { perspectivePlatform.requestPaint() }
                    function onNeonChanged() { perspectivePlatform.requestPaint() }
                }

                onPaint: {
                    const ctx = getContext("2d")
                    const x0 = perspectiveStage.ribbonX
                    const x1 = perspectiveStage.ribbonX + perspectiveStage.ribbonWidth
                    const cx = perspectiveStage.centerX
                    const y = perspectiveStage.ribbonY
                    const topSide = y + 52
                    const topCenter = y + 18
                    const bottomSide = y + 106
                    const bottomCenter = y + 148

                    function ribbonPath(inset) {
                        const pad = inset || 0
                        const left = x0 + pad
                        const right = x1 - pad
                        const topS = topSide + pad * 0.24
                        const topC = topCenter + pad * 0.18
                        const bottomS = bottomSide - pad * 0.10
                        const bottomC = bottomCenter - pad * 0.18

                        ctx.beginPath()
                        ctx.moveTo(left, topS)
                        ctx.bezierCurveTo(left + perspectiveStage.ribbonWidth * 0.18, topS + 26, cx - perspectiveStage.ribbonWidth * 0.22, topC, cx, topC)
                        ctx.bezierCurveTo(cx + perspectiveStage.ribbonWidth * 0.22, topC, right - perspectiveStage.ribbonWidth * 0.18, topS + 26, right, topS)
                        ctx.lineTo(right - 22, bottomS)
                        ctx.bezierCurveTo(right - perspectiveStage.ribbonWidth * 0.18, bottomS + 38, cx + perspectiveStage.ribbonWidth * 0.18, bottomC, cx, bottomC)
                        ctx.bezierCurveTo(cx - perspectiveStage.ribbonWidth * 0.18, bottomC, left + perspectiveStage.ribbonWidth * 0.18, bottomS + 38, left + 22, bottomS)
                        ctx.closePath()
                    }

                    ctx.reset()
                    ctx.clearRect(0, 0, width, height)

                    ctx.save()
                    ctx.shadowColor = "rgba(76,69,92,0.12)"
                    ctx.shadowBlur = 15
                    ctx.shadowOffsetY = 10
                    ribbonPath(0)
                    ctx.fillStyle = "rgba(88,82,104,0.10)"
                    ctx.fill()
                    ctx.restore()

                    ctx.save()
                    ctx.shadowColor = "rgba(232,136,194,0.09)"
                    ctx.shadowBlur = 12
                    ctx.shadowOffsetY = 5
                    ribbonPath(2)
                    ctx.fillStyle = "rgba(255,249,253,0.68)"
                    ctx.fill()
                    ctx.strokeStyle = "rgba(255,255,255,0.90)"
                    ctx.lineWidth = 6
                    ctx.stroke()
                    ctx.restore()

                    ribbonPath(15)
                    ctx.strokeStyle = "rgba(214,175,234,0.16)"
                    ctx.lineWidth = 1.0
                    ctx.stroke()

                    ctx.beginPath()
                    ctx.moveTo(x0 + 24, bottomSide + 16)
                    ctx.bezierCurveTo(x0 + perspectiveStage.ribbonWidth * 0.24, bottomSide + 50, x1 - perspectiveStage.ribbonWidth * 0.24, bottomSide + 50, x1 - 24, bottomSide + 16)
                    ctx.strokeStyle = "rgba(145,118,184,0.16)"
                    ctx.lineWidth = 2.0
                    ctx.stroke()
                }
            }

            Repeater {
                model: root.contentActive ? perspectiveStage.ribbonCardCount : 0

                RibbonWallpaperCard {
                    id: perspectiveTile

                    required property int index
                    readonly property int tileSlotOffset: perspectiveStage.slotOffset(index)
                    readonly property real tileFocusAmount: Math.max(0, 1 - Math.min(1, Math.abs(tileSlotOffset) / Math.max(1, perspectiveStage.centerSlot)))
                    readonly property bool centerSelected: index === perspectiveStage.centerSlot
                    readonly property int wallpaperIndex: perspectiveStage.indexForSlot(index)

                    x: Math.round(perspectiveStage.slotCenterX(tileSlotOffset) - width / 2)
                    y: Math.round(perspectiveStage.slotCenterY(tileSlotOffset) - height / 2)
                    width: perspectiveStage.slotWidth(tileSlotOffset)
                    height: perspectiveStage.slotHeight(tileSlotOffset)
                    entry: perspectiveStage.entryForSlot(index)
                    selected: centerSelected
                    cardRotation: perspectiveStage.slotRotation(tileSlotOffset)
                    cardYaw: perspectiveStage.slotYaw(tileSlotOffset)
                    z: Math.round(70 + tileFocusAmount * 20)
                    opacity: perspectiveStage.slotOpacity(tileSlotOffset)
                    onClicked: {
                        if (perspectiveTile.centerSelected)
                            root.applySelected()
                        else
                            root.selectedIndex = perspectiveTile.wallpaperIndex
                    }
                }
            }

            Text {
                x: Math.round(perspectiveStage.ribbonX + 34)
                y: Math.round(perspectiveStage.ribbonY + 86)
                width: 42
                height: 44
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "‹"
                color: Qt.rgba(130 / 255, 101 / 255, 190 / 255, 1.0)
                font.family: root.uiFont
                font.pixelSize: 50
                font.weight: Font.Bold
                z: 160

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.moveSelection(-1)
                }
            }

            Text {
                x: Math.round(perspectiveStage.ribbonX + perspectiveStage.ribbonWidth - width - 34)
                y: Math.round(perspectiveStage.ribbonY + 86)
                width: 42
                height: 44
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "›"
                color: Qt.rgba(130 / 255, 101 / 255, 190 / 255, 1.0)
                font.family: root.uiFont
                font.pixelSize: 50
                font.weight: Font.Bold
                z: 160

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.moveSelection(1)
                }
            }
        }

        Item {
            id: wheelNavDock

            visible: root.showcaseLayout
            enabled: root.showcaseLayout
            x: Math.round((panelSurface.leftStageWidth - width) / 2)
            y: Math.round(Math.min(parent.height - height - 54, perspectiveStage.y + perspectiveStage.ribbonY + perspectiveStage.ribbonHeight + 18))
            width: 160
            height: 42
            z: 88
            opacity: Math.min(1, root.revealProgress * 1.28)

            Rectangle {
                anchors.fill: parent
                radius: 21
                color: Qt.rgba(1, 0.985, 1, root.neon ? 0.76 : 0.88)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.62)
                antialiasing: true
                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    radius: 20
                    samples: 41
                    horizontalOffset: 0
                    verticalOffset: 8
                    color: Qt.rgba(232 / 255, 136 / 255, 194 / 255, 0.10)
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 18

                Repeater {
                    model: 4

                    Rectangle {
                        readonly property bool active: index === Math.max(0, Math.min(3, root.activeFilter))

                        anchors.verticalCenter: parent.verticalCenter
                        width: active ? 14 : 12
                        height: width
                        radius: width / 2
                        color: active ? root.alpha(root.pink, 0.82) : "transparent"
                        border.width: active ? 0 : 2
                        border.color: root.alpha(root.lilac, 0.66)
                        antialiasing: true

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setModeFilter(index)
                        }
                    }
                }
            }
        }

        Rectangle {
            id: bottomModeDock

            visible: false
            enabled: false
            x: 18
            y: parent.height - height - 16
            width: Math.min(390, panelSurface.leftStageWidth - 36)
            height: 48
            radius: 18
            color: root.alpha(root.card, root.neon ? 0.62 : 0.78)
            border.width: 1
            border.color: root.alpha(root.borderSoft, 0.42)
            antialiasing: true
            z: 86
            opacity: Math.min(1, root.revealProgress * 1.18)

            Row {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 12
                spacing: 14

                Text {
                    height: parent.height
                    width: Math.min(182, parent.width - 152)
                    verticalAlignment: Text.AlignVCenter
                    text: "Wallpaper Selector"
                    color: root.lilac
                    font.family: root.uiFont
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                ModeButton { label: "GRID"; active: root.activeFilter === 0; onClicked: root.setModeFilter(0) }
                ModeButton { label: "MIX"; active: root.activeFilter !== 0; onClicked: root.setModeFilter(1) }
            }
        }

        Rectangle {
            id: searchDock

            visible: false
            enabled: false
            x: Math.round((panelSurface.leftStageWidth - width) / 2)
            y: parent.height - height - 16
            width: Math.min(300, Math.max(220, panelSurface.leftStageWidth * 0.28))
            height: 48
            radius: 20
            color: root.alpha(root.card, root.neon ? 0.56 : 0.82)
            border.width: 1
            border.color: root.alpha(root.borderSoft, 0.38)
            antialiasing: true
            z: 87
            opacity: Math.min(1, root.revealProgress * 1.18)

            Row {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    text: "⌕"
                    color: root.lilac
                    font.family: root.monoFont
                    font.pixelSize: 17
                    font.weight: Font.Bold
                }

                Text {
                    text: "Search wallpapers"
                    color: root.inkSoft
                    font.family: root.uiFont
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }
            }
        }

        Rectangle {
            id: infoPanel

            visible: false
            enabled: false
            x: Math.round(panelSurface.leftStageWidth + panelSurface.infoGap)
            y: Math.round(Math.max(42, parent.height * 0.125) - (1 - root.revealProgress) * 16)
            width: panelSurface.infoPanelWidth
            height: Math.round(Math.min(560, parent.height - y - 104))
            radius: 24
            color: root.alpha(root.card, root.neon ? 0.70 : 0.82)
            border.width: 1
            border.color: root.alpha(root.borderSoft, 0.52)
            antialiasing: true
            z: 90
            opacity: Math.min(1, root.revealProgress * 1.20)
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                radius: 30
                samples: 61
                horizontalOffset: 0
                verticalOffset: 14
                color: Qt.rgba(0, 0, 0, root.neon ? 0.30 : 0.12)
            }

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                Row {
                    width: parent.width
                    height: 28
                    spacing: 8

                    Text {
                        width: parent.width - 92
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        text: "Wallpaper Info"
                        color: root.pink
                        font.family: root.uiFont
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: 84
                        height: parent.height
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        text: root.wallpapers.length + " items"
                        color: root.inkSoft
                        font.family: root.monoFont
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }

                Row {
                    spacing: 8
                    ModeButton { label: "STATIC"; active: root.activeFilter === 1; onClicked: root.setModeFilter(1) }
                    ModeButton { label: "MPV"; active: root.activeFilter === 2; onClicked: root.setModeFilter(2) }
                    ModeButton { label: "ENGINE"; active: root.activeFilter === 3; onClicked: root.setModeFilter(3) }
                }

                Rectangle {
                    width: parent.width
                    height: Math.min(178, Math.max(130, parent.height * 0.31))
                    radius: 20
                    color: root.alpha(root.glass, 0.34)
                    border.width: 1
                    border.color: root.alpha(root.borderSoft, 0.44)
                    clip: true
                    antialiasing: true

                    Image {
                        anchors.fill: parent
                        source: root.contentActive ? root.currentWallpaperPreview() : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 680
                        sourceSize.height: 420
                        asynchronous: true
                        cache: true
                        smooth: true
                    }

                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.00) }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, root.neon ? 0.42 : 0.28) }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 5

                    Text {
                        width: parent.width
                        text: root.currentWallpaperTitle()
                        color: root.ink
                        font.family: root.uiFont
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: "by Velora Shell"
                        color: root.inkSoft
                        font.family: root.monoFont
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                }

                Flow {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: root.currentWallpaperTags()

                        Rectangle {
                            width: tagText.implicitWidth + 18
                            height: 24
                            radius: 12
                            color: root.alpha(root.lilac, root.neon ? 0.22 : 0.13)
                            border.width: 1
                            border.color: root.alpha(root.lilac, root.neon ? 0.38 : 0.24)
                            antialiasing: true

                            Text {
                                id: tagText

                                anchors.centerIn: parent
                                text: modelData
                                color: root.lilac
                                font.family: root.uiFont
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 9

                    Text {
                        width: parent.width
                        text: "Palette"
                        color: root.pink
                        font.family: root.uiFont
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }

                    Row {
                        spacing: 10

                        Repeater {
                            model: 5

                            Rectangle {
                                width: 25
                                height: 25
                                radius: 13
                                color: root.paletteSwatch(index)
                                border.width: 1
                                border.color: root.alpha(root.borderSoft, 0.45)
                                antialiasing: true
                            }
                        }
                    }

                    InfoLine { label: "Type"; value: root.currentWallpaperCategory() }
                    InfoLine { label: "Mode"; value: root.modeLabelFromFilter(root.activeFilter) }
                    InfoLine { label: "Source"; value: root.currentWallpaperKind() }
                }

                ActionButton {
                    width: parent.width
                    label: root.rouletteSpinning ? "Spinning..." : "Random pick"
                    primary: false
                    enabled: !root.rouletteSpinning
                    onClicked: root.spinRoulette()
                }

                ActionButton {
                    width: parent.width
                    label: applyWallpaper.running ? "Applying..." : "Set as Wallpaper"
                    primary: true
                    enabled: !applyWallpaper.running && !root.rouletteSpinning
                    onClicked: root.applySelected()
                }
            }
        }
    }

    component InfoLine: Row {
        property string label: ""
        property string value: ""

        width: parent ? parent.width : 220
        height: 22
        spacing: 8

        Text {
            width: 76
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            text: label
            color: root.inkSoft
            font.family: root.uiFont
            font.pixelSize: 11
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            width: parent.width - 84
            height: parent.height
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            text: value
            color: root.pink
            font.family: root.uiFont
            font.pixelSize: 11
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
    }

    component WheelTile: Item {
        id: tile

        property var entry: null
        property bool selected: false
        property real centerX: width * 0.5
        property real centerY: height
        property real outerRadiusX: width * 0.45
        property real outerRadiusY: height * 0.8
        property real innerRadiusX: width * 0.28
        property real innerRadiusY: height * 0.5
        property real startAngle: Math.PI
        property real endAngle: Math.PI * 2
        property real angularGap: 0.04
        property real radialGap: 14
        property real slotOffset: 0
        property real focusAmount: 0
        readonly property real segmentPadding: 14
        readonly property real safeEndAngle: Math.max(startAngle + 0.03, endAngle)
        readonly property real visualStartAngle: Math.min(startAngle + angularGap, segmentMid - 0.012)
        readonly property real visualEndAngle: Math.max(safeEndAngle - angularGap, segmentMid + 0.012)
        readonly property real segmentMid: (startAngle + safeEndAngle) / 2
        readonly property real visualOuterRadiusX: Math.max(1, outerRadiusX - radialGap * 0.82)
        readonly property real visualOuterRadiusY: Math.max(1, outerRadiusY - radialGap * 0.62)
        readonly property real visualInnerRadiusX: Math.max(1, innerRadiusX + radialGap * 0.66)
        readonly property real visualInnerRadiusY: Math.max(1, innerRadiusY + radialGap * 0.44)
        readonly property real segmentX: Math.max(0, Math.floor(segmentMinX() - segmentPadding))
        readonly property real segmentY: Math.max(0, Math.floor(segmentMinY() - segmentPadding))
        readonly property real segmentWidth: Math.min(width - segmentX, Math.ceil(segmentMaxX() - segmentMinX() + segmentPadding * 2))
        readonly property real segmentHeight: Math.min(height - segmentY, Math.ceil(segmentMaxY() - segmentMinY() + segmentPadding * 2))
        signal clicked()

        onCenterXChanged: requestSegmentPaint()
        onCenterYChanged: requestSegmentPaint()
        onOuterRadiusXChanged: requestSegmentPaint()
        onOuterRadiusYChanged: requestSegmentPaint()
        onInnerRadiusXChanged: requestSegmentPaint()
        onInnerRadiusYChanged: requestSegmentPaint()
        onStartAngleChanged: requestSegmentPaint()
        onEndAngleChanged: requestSegmentPaint()
        onAngularGapChanged: requestSegmentPaint()
        onRadialGapChanged: requestSegmentPaint()
        onSelectedChanged: requestSegmentPaint()

        Connections {
            target: root
            function onSelectorEdgeChanged() { tile.requestSegmentPaint() }
            function onSelectorTintChanged() { tile.requestSegmentPaint() }
            function onNeonChanged() { tile.requestSegmentPaint() }
        }

        function px(angle, radiusX) {
            return centerX + Math.cos(angle) * radiusX
        }

        function py(angle, radiusY) {
            return centerY + Math.sin(angle) * radiusY
        }

        function segmentMinX() {
            return Math.min(px(visualStartAngle, visualOuterRadiusX), px(visualEndAngle, visualOuterRadiusX), px(segmentMid, visualOuterRadiusX), px(visualStartAngle, visualInnerRadiusX), px(visualEndAngle, visualInnerRadiusX), px(segmentMid, visualInnerRadiusX))
        }

        function segmentMaxX() {
            return Math.max(px(visualStartAngle, visualOuterRadiusX), px(visualEndAngle, visualOuterRadiusX), px(segmentMid, visualOuterRadiusX), px(visualStartAngle, visualInnerRadiusX), px(visualEndAngle, visualInnerRadiusX), px(segmentMid, visualInnerRadiusX))
        }

        function segmentMinY() {
            return Math.min(py(visualStartAngle, visualOuterRadiusY), py(visualEndAngle, visualOuterRadiusY), py(segmentMid, visualOuterRadiusY), py(visualStartAngle, visualInnerRadiusY), py(visualEndAngle, visualInnerRadiusY), py(segmentMid, visualInnerRadiusY))
        }

        function segmentMaxY() {
            return Math.max(py(visualStartAngle, visualOuterRadiusY), py(visualEndAngle, visualOuterRadiusY), py(segmentMid, visualOuterRadiusY), py(visualStartAngle, visualInnerRadiusY), py(visualEndAngle, visualInnerRadiusY), py(segmentMid, visualInnerRadiusY))
        }

        function requestSegmentPaint() {
            tileMask.requestPaint()
            tileBorder.requestPaint()
        }

        function drawSegment(ctx, offsetX, offsetY) {
            const ox = offsetX || 0
            const oy = offsetY || 0
            const samples = 22
            ctx.beginPath()

            for (let i = 0; i <= samples; i++) {
                const angle = visualStartAngle + (visualEndAngle - visualStartAngle) * i / samples
                const x = px(angle, visualOuterRadiusX) - ox
                const y = py(angle, visualOuterRadiusY) - oy
                if (i === 0)
                    ctx.moveTo(x, y)
                else
                    ctx.lineTo(x, y)
            }

            for (let i = samples; i >= 0; i--) {
                const angle = visualStartAngle + (visualEndAngle - visualStartAngle) * i / samples
                ctx.lineTo(px(angle, visualInnerRadiusX) - ox, py(angle, visualInnerRadiusY) - oy)
            }

            ctx.closePath()
        }

        Item {
            id: tileSource

            x: tile.segmentX
            y: tile.segmentY
            width: tile.segmentWidth
            height: tile.segmentHeight
            visible: true

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.90) }
                    GradientStop { position: 1.0; color: Qt.rgba(0.99, 0.93, 0.98, 0.78) }
                }
            }

            Image {
                anchors.fill: parent
                source: root.contentActive ? root.displaySource(tile.entry) : ""
                fillMode: Image.PreserveAspectCrop
                horizontalAlignment: Image.AlignHCenter
                verticalAlignment: Image.AlignVCenter
                sourceSize.width: 560
                sourceSize.height: 330
                asynchronous: true
                smooth: true
                mipmap: true
            }

            Rectangle {
                anchors.fill: parent
                color: selected ? Qt.rgba(239 / 255, 126 / 255, 185 / 255, 0.08) : Qt.rgba(1, 1, 1, 0.04)
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, selected ? 0.10 : 0.06) }
                    GradientStop { position: 0.64; color: Qt.rgba(0, 0, 0, 0.00) }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, selected ? 0.07 : 0.05) }
                }
            }
        }

        ShaderEffectSource {
            id: tileSourceProxy

            width: tile.segmentWidth
            height: tile.segmentHeight
            visible: false
            sourceItem: tileSource
            live: true
            recursive: true
            hideSource: true
        }

        Canvas {
            id: tileMask

            x: tile.segmentX
            y: tile.segmentY
            width: tile.segmentWidth
            height: tile.segmentHeight
            visible: false
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d")

                ctx.reset()
                ctx.clearRect(0, 0, width, height)
                ctx.fillStyle = "white"
                tile.drawSegment(ctx, tile.segmentX, tile.segmentY)
                ctx.fill()
            }
        }

        OpacityMask {
            x: tile.segmentX
            y: tile.segmentY
            width: tile.segmentWidth
            height: tile.segmentHeight
            source: tileSourceProxy
            maskSource: tileMask
            cached: false
        }

        Canvas {
            id: tileBorder

            x: tile.segmentX
            y: tile.segmentY
            width: tile.segmentWidth
            height: tile.segmentHeight
            opacity: selected ? 0.98 : 0.82
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d")

                ctx.reset()
                ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = "rgba(255,255,255,0.98)"
                ctx.lineWidth = 4.4
                tile.drawSegment(ctx, tile.segmentX, tile.segmentY)
                ctx.stroke()

                if (selected) {
                    ctx.strokeStyle = "rgba(239,126,185,0.72)"
                    ctx.lineWidth = 2.1
                    tile.drawSegment(ctx, tile.segmentX, tile.segmentY)
                    ctx.stroke()
                }
            }
        }

        Rectangle {
            visible: false
            x: tile.px(tile.segmentMid, (tile.outerRadiusX + tile.innerRadiusX) * 0.5) - width / 2
            y: tile.py(tile.segmentMid, (tile.outerRadiusY + tile.innerRadiusY) * 0.5) - height / 2
            width: 14
            height: 14
            radius: 7
            color: root.alpha(root.selectorTint, root.neon ? 0.46 : 0.36)
            border.width: 1
            border.color: root.alpha(root.selectorEdge, root.neon ? 0.72 : 0.58)
        }

        MouseArea {
            x: tile.segmentX
            y: tile.segmentY
            width: tile.segmentWidth
            height: tile.segmentHeight
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.clicked()
        }
    }

    component EllipseWallpaperCard: Item {
        id: cardTile

        property var entry: null
        property bool selected: false
        property real cardRotation: 0
        property real cardYaw: 0
        property real frontDepth: 0
        signal clicked()

        transformOrigin: Item.Center
        antialiasing: true
        transform: [
            Rotation {
                origin.x: cardTile.width / 2
                origin.y: cardTile.height / 2
                axis.x: 0
                axis.y: 1
                axis.z: 0
                angle: cardTile.cardYaw
            },
            Rotation {
                origin.x: cardTile.width / 2
                origin.y: cardTile.height / 2
                axis.x: 0
                axis.y: 0
                axis.z: 1
                angle: cardTile.cardRotation
            }
        ]

        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: 14
            color: Qt.rgba(76 / 255, 74 / 255, 92 / 255, 0.08 + cardTile.frontDepth * 0.035)
            opacity: 0.78
            antialiasing: true
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                radius: Math.round(10 + cardTile.frontDepth * 9)
                samples: Math.round(21 + cardTile.frontDepth * 18)
                horizontalOffset: 0
                verticalOffset: Math.round(6 + cardTile.frontDepth * 6)
                color: Qt.rgba(58 / 255, 55 / 255, 74 / 255, 0.13)
            }
        }

        Rectangle {
            id: cardShell

            anchors.fill: parent
            radius: 12
            color: Qt.rgba(1, 0.985, 1, 0.88)
            border.width: selected ? 2 : 1
            border.color: selected
                ? Qt.rgba(239 / 255, 126 / 255, 185 / 255, 0.86)
                : Qt.rgba(1, 1, 1, 0.82)
            antialiasing: true
            clip: true

            Image {
                anchors.fill: parent
                anchors.margins: selected ? 4 : 5
                source: root.contentActive ? root.displaySource(cardTile.entry) : ""
                fillMode: Image.PreserveAspectCrop
                retainWhileLoading: true
                asynchronous: true
                cache: true
                smooth: true
                mipmap: true
                sourceSize.width: Math.round(cardTile.width * 2.6)
                sourceSize.height: Math.round(cardTile.height * 2.6)
                opacity: 0.94 + cardTile.frontDepth * 0.06
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: selected ? 4 : 5
                radius: Math.max(0, cardShell.radius - 6)
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.42)
                antialiasing: true
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.00; color: Qt.rgba(1, 1, 1, 0.08 + cardTile.frontDepth * 0.04) }
                    GradientStop { position: 0.58; color: Qt.rgba(1, 1, 1, 0.00) }
                    GradientStop { position: 1.00; color: Qt.rgba(0, 0, 0, 0.07 - cardTile.frontDepth * 0.025) }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -6
            radius: 16
            visible: selected
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(239 / 255, 126 / 255, 185 / 255, 0.38)
            antialiasing: true
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: cardTile.clicked()
        }
    }

    component RibbonWallpaperCard: Item {
        id: ribbonCard

        property var entry: null
        property bool selected: false
        property real cardRotation: 0
        property real cardYaw: 0
        signal clicked()

        transformOrigin: Item.Center
        antialiasing: true
        transform: Rotation {
            origin.x: ribbonCard.width / 2
            origin.y: ribbonCard.height / 2
            axis.x: 0
            axis.y: 0
            axis.z: 1
            angle: ribbonCard.cardRotation
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: 11
            color: Qt.rgba(66 / 255, 62 / 255, 82 / 255, 0.10)
            antialiasing: true
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                radius: selected ? 16 : 12
                samples: selected ? 33 : 25
                horizontalOffset: 0
                verticalOffset: selected ? 8 : 6
                color: Qt.rgba(58 / 255, 54 / 255, 74 / 255, selected ? 0.18 : 0.13)
            }
        }

        Rectangle {
            id: ribbonCardShell

            anchors.fill: parent
            radius: 9
            color: Qt.rgba(1, 0.985, 1, 0.90)
            border.width: selected ? 2 : 1
            border.color: selected
                ? Qt.rgba(239 / 255, 126 / 255, 185 / 255, 0.78)
                : Qt.rgba(1, 1, 1, 0.88)
            antialiasing: true
            clip: true

            Image {
                anchors.fill: parent
                anchors.margins: selected ? 4 : 5
                source: root.contentActive ? root.displaySource(ribbonCard.entry) : ""
                fillMode: Image.PreserveAspectCrop
                retainWhileLoading: true
                asynchronous: true
                cache: true
                smooth: true
                mipmap: true
                sourceSize.width: Math.round(ribbonCard.width * 2.8)
                sourceSize.height: Math.round(ribbonCard.height * 2.8)
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: selected ? 4 : 5
                radius: Math.max(0, ribbonCardShell.radius - 5)
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.46)
                antialiasing: true
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.08) }
                    GradientStop { position: 0.62; color: Qt.rgba(1, 1, 1, 0.00) }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, selected ? 0.04 : 0.07) }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: ribbonCard.clicked()
        }
    }

    component ModeButton: Rectangle {
        id: chip

        property string label: ""
        property bool active: false
        property bool hovered: false
        signal clicked()

        width: Math.max(74, labelText.implicitWidth + 28)
        height: 28
        radius: 14
        color: active ? root.alpha(root.pink, 0.66) : (hovered ? root.alpha(root.card, 0.36) : root.alpha(root.card, 0.22))
        border.width: 1
        border.color: active ? root.alpha(root.borderSoft, 0.70) : root.alpha(root.borderSoft, 0.30)
        antialiasing: true

        Text {
            id: labelText

            anchors.centerIn: parent
            text: chip.label
            color: active ? (root.theme ? root.theme.activeText : "white") : root.inkSoft
            font.family: root.monoFont
            font.pixelSize: 11
            font.weight: Font.Bold
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: chip.hovered = true
            onExited: chip.hovered = false
            onClicked: chip.clicked()
        }
    }

    component ActionButton: Rectangle {
        id: button

        property string label: ""
        property bool primary: false
        property bool hovered: false
        signal clicked()

        height: 46
        radius: 23
        opacity: enabled ? 1 : 0.58
        color: primary
            ? (hovered ? root.alpha(root.pink, 0.86) : root.alpha(root.pink, 0.72))
            : (hovered ? root.alpha(root.card, 0.54) : root.alpha(root.card, 0.36))
        border.width: 1
        border.color: primary ? root.alpha(root.borderSoft, 0.66) : root.alpha(root.borderSoft, 0.42)
        scale: actionMouse.pressed && enabled ? 0.975 : (hovered && enabled ? 1.015 : 1)
        antialiasing: true

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on opacity { NumberAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

        Text {
            anchors.centerIn: parent
            text: button.label
            color: primary ? (root.theme ? root.theme.activeText : "white") : root.ink
            font.family: root.uiFont
            font.pixelSize: 14
            font.weight: Font.Bold
            elide: Text.ElideRight
        }

        MouseArea {
            id: actionMouse

            anchors.fill: parent
            hoverEnabled: true
            enabled: button.enabled
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onEntered: button.hovered = true
            onExited: button.hovered = false
            onClicked: button.clicked()
        }
    }

    component RoundButton: Rectangle {
        id: button

        property string icon: "down"
        property string label: ""
        property bool compact: false
        property bool hovered: false
        signal clicked()

        width: compact ? 48 : 92
        height: compact ? 48 : 72
        radius: height / 2
        color: compact ? (hovered ? root.alpha(root.card, 0.56) : root.alpha(root.card, 0.38)) : (hovered ? Qt.rgba(0, 0, 0, 0.46) : Qt.rgba(0, 0, 0, 0.34))
        border.width: 1
        border.color: compact ? root.alpha(root.borderSoft, hovered ? 0.66 : 0.44) : Qt.rgba(1, 1, 1, hovered ? 0.32 : 0.18)
        scale: hovered ? 1.025 : 1
        antialiasing: true
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            radius: 22
            samples: 45
            horizontalOffset: 0
            verticalOffset: 10
            color: Qt.rgba(0, 0, 0, 0.22)
        }

        Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

        Column {
            anchors.centerIn: parent
            spacing: compact ? 0 : 3

            PanelIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                width: compact ? 18 : 20
                height: compact ? 18 : 20
                kind: button.icon
            }

            Text {
                visible: !button.compact && button.label.length > 0
                anchors.horizontalCenter: parent.horizontalCenter
                text: button.label
                color: root.inkSoft
                font.family: root.monoFont
                font.pixelSize: 9
                font.weight: Font.Bold
            }
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

    component HubButton: Item {
        id: hub

        property bool hovered: false
        property bool pressed: false
        signal clicked()

        width: 104
        height: 78

        function roundedRect(ctx, x, y, w, h, r) {
            const radius = Math.min(r, w / 2, h / 2)
            ctx.beginPath()
            ctx.moveTo(x + radius, y)
            ctx.lineTo(x + w - radius, y)
            ctx.arcTo(x + w, y, x + w, y + radius, radius)
            ctx.lineTo(x + w, y + h - radius)
            ctx.arcTo(x + w, y + h, x + w - radius, y + h, radius)
            ctx.lineTo(x + radius, y + h)
            ctx.arcTo(x, y + h, x, y + h - radius, radius)
            ctx.lineTo(x, y + radius)
            ctx.arcTo(x, y, x + radius, y, radius)
            ctx.closePath()
        }

        Canvas {
            id: hubCanvas

            anchors.fill: parent
            antialiasing: true
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d")
                const lift = hub.pressed ? 3 : (hub.hovered ? -1 : 0)

                ctx.reset()
                ctx.clearRect(0, 0, width, height)

                ctx.save()
                hub.roundedRect(ctx, 4, 8 + lift, width - 8, height + 18, 34)
                ctx.fillStyle = hub.hovered ? "rgba(55, 55, 58, 0.74)" : "rgba(42, 42, 45, 0.66)"
                ctx.fill()
                ctx.strokeStyle = "rgba(255, 255, 255, 0.26)"
                ctx.lineWidth = 1.2
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(22, 15 + lift)
                ctx.quadraticCurveTo(width / 2, 2 + lift, width - 22, 15 + lift)
                ctx.strokeStyle = "rgba(255, 255, 255, 0.20)"
                ctx.lineWidth = 1.0
                ctx.stroke()
                ctx.restore()
            }
        }

        PanelIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 25 + (hub.pressed ? 3 : 0)
            width: 19
            height: 19
            kind: "down"
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                hub.hovered = true
                hubCanvas.requestPaint()
            }
            onExited: {
                hub.hovered = false
                hub.pressed = false
                hubCanvas.requestPaint()
            }
            onPressed: {
                hub.pressed = true
                hubCanvas.requestPaint()
            }
            onReleased: {
                hub.pressed = false
                hubCanvas.requestPaint()
            }
            onClicked: hub.clicked()
        }
    }

    component VisibilityButton: Rectangle {
        id: button

        property bool hovered: false
        signal clicked()

        width: 44
        height: 44
        radius: height / 2
        z: 91
        color: hovered ? Qt.rgba(58, 58, 62, 0.54) : Qt.rgba(42, 42, 46, 0.42)
        border.width: 1
        border.color: hovered ? Qt.rgba(255, 255, 255, 0.34) : Qt.rgba(255, 255, 255, 0.20)
        antialiasing: true

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

        PanelIcon {
            anchors.centerIn: parent
            width: 20
            height: 20
            kind: "hide"
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

    component PanelIcon: Canvas {
        id: iconCanvas

        property string kind: "down"

        onKindChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = root.cssColor(root.ink, 0.86)
            ctx.fillStyle = root.cssColor(root.ink, 0.86)
            ctx.lineWidth = Math.max(1.8, Math.min(width, height) * 0.10)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            if (kind === "left" || kind === "right") {
                const flip = kind === "left" ? -1 : 1
                ctx.translate(width / 2, height / 2)
                ctx.scale(flip, 1)
                ctx.beginPath()
                ctx.moveTo(-width * 0.18, -height * 0.27)
                ctx.lineTo(width * 0.16, 0)
                ctx.lineTo(-width * 0.18, height * 0.27)
                ctx.stroke()
                return
            }

            if (kind === "tune") {
                for (let i = 0; i < 3; i++) {
                    const y = height * (0.28 + i * 0.22)
                    ctx.beginPath()
                    ctx.moveTo(width * 0.18, y)
                    ctx.lineTo(width * 0.82, y)
                    ctx.stroke()
                    ctx.beginPath()
                    ctx.arc(width * (i === 0 ? 0.62 : (i === 1 ? 0.38 : 0.70)), y, 2.1, 0, Math.PI * 2)
                    ctx.fill()
                }
                return
            }

            if (kind === "hide") {
                ctx.beginPath()
                ctx.ellipse(width * 0.50, height * 0.50, width * 0.31, height * 0.22, 0, 0, Math.PI * 2)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(width * 0.50, height * 0.50, Math.min(width, height) * 0.09, 0, Math.PI * 2)
                ctx.fill()
                ctx.beginPath()
                ctx.moveTo(width * 0.20, height * 0.80)
                ctx.lineTo(width * 0.80, height * 0.20)
                ctx.stroke()
                return
            }

            ctx.beginPath()
            ctx.moveTo(width * 0.28, height * 0.38)
            ctx.lineTo(width * 0.50, height * 0.62)
            ctx.lineTo(width * 0.72, height * 0.38)
            ctx.stroke()
        }
    }

    component RouletteRimCanvas: Canvas {
        id: rim

        property real centerX: width * 0.5
        property real centerY: height * 0.5
        property real outerRadius: Math.min(width, height) * 0.47
        property real outerRadiusY: outerRadius
        property real innerRadius: Math.min(width, height) * 0.18
        property real innerRadiusY: innerRadius
        property int slotCount: 1
        property real phase: 0

        antialiasing: true
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onCenterXChanged: requestPaint()
        onCenterYChanged: requestPaint()
        onOuterRadiusChanged: requestPaint()
        onOuterRadiusYChanged: requestPaint()
        onInnerRadiusChanged: requestPaint()
        onInnerRadiusYChanged: requestPaint()
        onSlotCountChanged: requestPaint()
        onPhaseChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            const count = Math.max(1, slotCount)
            const centerSlot = Math.floor(count / 2)

            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            ctx.beginPath()
            ctx.ellipse(centerX, centerY, outerRadius, outerRadiusY, 0, 0, Math.PI)
            ctx.strokeStyle = root.cssColor(root.selectorEdge, root.neon ? 0.72 : 0.58)
            ctx.lineWidth = 7
            ctx.stroke()

            ctx.beginPath()
            ctx.ellipse(centerX, centerY, innerRadius, innerRadiusY, 0, 0, Math.PI)
            ctx.strokeStyle = root.cssColor(root.selectorEdge, root.neon ? 0.56 : 0.42)
            ctx.lineWidth = 3
            ctx.stroke()

            for (let i = 0; i <= count; i++) {
                const offset = i - centerSlot - 0.5 + phase
                const degrees = root.wheelBoundaryAngle(offset, count)
                const a = (90 - degrees) * Math.PI / 180
                ctx.beginPath()
                ctx.moveTo(centerX + Math.cos(a) * innerRadius, centerY + Math.sin(a) * innerRadiusY)
                ctx.lineTo(centerX + Math.cos(a) * outerRadius, centerY + Math.sin(a) * outerRadiusY)
                ctx.strokeStyle = root.cssColor(root.selectorEdge, i % 2 === 0 ? 0.44 : 0.30)
                ctx.lineWidth = i === centerSlot || i === centerSlot + 1 ? 1.8 : 1.2
                ctx.stroke()
            }
        }
    }

    component ReferencePetalsCanvas: Canvas {
        id: petals

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            const cx = width * 0.50
            const baseY = height * 0.62

            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            ctx.save()
            ctx.strokeStyle = "rgba(236,236,236,0.52)"
            ctx.fillStyle = "rgba(242,242,242,0.64)"
            ctx.lineWidth = 1.8
            ctx.beginPath()
            ctx.moveTo(cx - 12, baseY)
            ctx.bezierCurveTo(cx - 42, height * 0.48, cx - 18, height * 0.35, cx + 18, height * 0.25)
            ctx.stroke()

            function flower(x, y, s, dark) {
                ctx.save()
                ctx.translate(x, y)
                ctx.fillStyle = dark ? "rgba(210,210,210,0.52)" : "rgba(250,250,250,0.74)"
                ctx.strokeStyle = dark ? "rgba(185,185,185,0.32)" : "rgba(255,255,255,0.40)"
                ctx.lineWidth = 0.8
                for (let i = 0; i < 6; i++) {
                    ctx.rotate(Math.PI / 3)
                    ctx.beginPath()
                    ctx.arc(0, -s * 0.78, s * 0.42, 0, Math.PI * 2)
                    ctx.fill()
                    ctx.stroke()
                }
                ctx.fillStyle = "rgba(225,225,225,0.70)"
                ctx.beginPath()
                ctx.arc(0, 0, s * 0.28, 0, Math.PI * 2)
                ctx.fill()
                ctx.restore()
            }

            flower(cx + 16, height * 0.28, 21, false)
            flower(cx - 34, height * 0.40, 18, true)
            flower(cx + 84, height * 0.49, 16, false)
            flower(cx - 96, height * 0.51, 14, true)
            flower(cx + 145, height * 0.54, 13, false)

            ctx.strokeStyle = "rgba(232,232,232,0.32)"
            ctx.lineWidth = 1.0
            for (let b = 0; b < 6; b++) {
                const bx = cx + [-28, 42, 76, -82, 112, -116][b]
                const by = height * [0.36, 0.38, 0.44, 0.48, 0.52, 0.56][b]
                ctx.beginPath()
                ctx.moveTo(cx, height * 0.44)
                ctx.quadraticCurveTo((cx + bx) / 2, by - 26, bx, by)
                ctx.stroke()
            }
            ctx.restore()

            const flecks = [
                [0.07, 0.21, 4, 0], [0.15, 0.34, 5, 1], [0.22, 0.47, 3, 0],
                [0.31, 0.08, 3, 1], [0.40, 0.49, 4, 0], [0.62, 0.18, 3, 1],
                [0.74, 0.31, 5, 0], [0.83, 0.43, 4, 1], [0.93, 0.26, 5, 0],
                [0.55, 0.06, 3, 1], [0.69, 0.51, 3, 0], [0.12, 0.55, 4, 1]
            ]

            for (let i = 0; i < flecks.length; i++) {
                const p = flecks[i]
                const x = width * p[0]
                const y = height * p[1]
                const s = p[2]
                ctx.save()
                ctx.translate(x, y)
                ctx.rotate((i * 37 % 160) * Math.PI / 180)
                ctx.fillStyle = p[3] ? "rgba(255,255,255,0.78)" : "rgba(0,0,0,0.76)"
                ctx.beginPath()
                ctx.moveTo(0, -s)
                ctx.quadraticCurveTo(s * 0.72, 0, 0, s)
                ctx.quadraticCurveTo(-s * 0.55, 0, 0, -s)
                ctx.fill()
                ctx.restore()
            }
        }
    }

    component RadialGlassCanvas: Canvas {
        id: glass

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            const cx = width * 0.50
            const cy = height + 34
            const rOuterX = Math.min(width * 0.47, 390)
            const rOuterY = Math.min(height * 0.84, 352)
            const rInnerX = Math.min(width * 0.29, 244)
            const rInnerY = Math.min(height * 0.53, 222)
            const rCoreX = rInnerX * 0.42
            const rCoreY = rInnerY * 0.44

            function annularSegment(outerX, outerY, innerX, innerY, start, end) {
                const samples = 64
                ctx.beginPath()
                for (let i = 0; i <= samples; i++) {
                    const a = start + (end - start) * i / samples
                    const x = cx + Math.cos(a) * outerX
                    const y = cy + Math.sin(a) * outerY
                    if (i === 0)
                        ctx.moveTo(x, y)
                    else
                        ctx.lineTo(x, y)
                }
                for (let i = samples; i >= 0; i--) {
                    const a = start + (end - start) * i / samples
                    ctx.lineTo(cx + Math.cos(a) * innerX, cy + Math.sin(a) * innerY)
                }
                ctx.closePath()
            }

            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            ctx.fillStyle = "rgba(236, 238, 242, 0.30)"
            annularSegment(rOuterX, rOuterY, rInnerX, rInnerY, Math.PI, Math.PI * 2)
            ctx.fill()

            ctx.fillStyle = "rgba(236, 238, 242, 0.22)"
            annularSegment(rInnerX, rInnerY, rCoreX, rCoreY, Math.PI, Math.PI * 2)
            ctx.fill()

            ctx.strokeStyle = "rgba(255, 255, 255, 0.26)"
            ctx.lineWidth = 1.4
            annularSegment(rOuterX, rOuterY, rInnerX, rInnerY, Math.PI, Math.PI * 2)
            ctx.stroke()
        }
    }

    component RadialFrameCanvas: Canvas {
        id: frame

        property int topSlots: Math.max(1, root.wheelSlotCount())
        property int bottomSlots: Math.max(0, root.bottomWheelSlotCount())
        property real topPhase: root.deckDirection * (1 - root.wheelProgress) * (Math.PI / topSlots)
        readonly property real bottomSpan: 118 * Math.PI / 180

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onTopSlotsChanged: requestPaint()
        onBottomSlotsChanged: requestPaint()
        onTopPhaseChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            const cx = width * 0.50
            const cy = height + 34
            const rOuterX = Math.min(width * 0.47, 390)
            const rOuterY = Math.min(height * 0.84, 352)
            const rInnerX = Math.min(width * 0.29, 244)
            const rInnerY = Math.min(height * 0.53, 222)
            const rCoreX = rInnerX * 0.42
            const rCoreY = rInnerY * 0.44

            function strokeArc(rx, ry, start, end, color, lineWidth) {
                const samples = 96
                ctx.beginPath()
                for (let i = 0; i <= samples; i++) {
                    const a = start + (end - start) * i / samples
                    const x = cx + Math.cos(a) * rx
                    const y = cy + Math.sin(a) * ry
                    if (i === 0)
                        ctx.moveTo(x, y)
                    else
                        ctx.lineTo(x, y)
                }
                ctx.strokeStyle = color
                ctx.lineWidth = lineWidth
                ctx.stroke()
            }

            function strokeDivider(angle, innerX, innerY, outerX, outerY, alpha, lineWidth) {
                const sx = cx + Math.cos(angle) * innerX
                const sy = cy + Math.sin(angle) * innerY
                const ex = cx + Math.cos(angle) * outerX
                const ey = cy + Math.sin(angle) * outerY
                ctx.beginPath()
                ctx.moveTo(sx, sy)
                ctx.lineTo(ex, ey)
                ctx.strokeStyle = "rgba(255,255,255," + alpha + ")"
                ctx.lineWidth = lineWidth
                ctx.stroke()
            }

            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            ctx.lineCap = "butt"
            ctx.lineJoin = "round"

            strokeArc(rOuterX, rOuterY, Math.PI, Math.PI * 2, "rgba(255,255,255,0.54)", 9)
            strokeArc(rInnerX, rInnerY, Math.PI, Math.PI * 2, "rgba(255,255,255,0.36)", 5)

            if (bottomSlots > 0)
                strokeArc(rCoreX, rCoreY, -Math.PI / 2 - bottomSpan / 2, -Math.PI / 2 + bottomSpan / 2, "rgba(255,255,255,0.30)", 3.2)

            const topStep = Math.PI / topSlots
            for (let i = 0; i <= topSlots; i++) {
                const a = -Math.PI + frame.topPhase + i * topStep
                if (a >= -Math.PI && a <= 0)
                    strokeDivider(a, rInnerX, rInnerY, rOuterX, rOuterY, 0.24, 1.25)
            }

            if (bottomSlots > 0) {
                const start = -Math.PI / 2 - bottomSpan / 2
                const step = bottomSpan / bottomSlots
                for (let i = 0; i <= bottomSlots; i++)
                    strokeDivider(start + i * step, rCoreX, rCoreY, rInnerX, rInnerY, 0.18, 1.0)
            }
        }
    }
}
