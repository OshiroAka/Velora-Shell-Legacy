pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import "../features/lock" as MediaAssets
import "../core" as Core
import "../core/WallpaperAccordionGeometry.js" as Geometry

Item {
    id: carousel
    property var theme: null
    property bool open: false
    property real revealProgress: open ? 1 : 0
    property var entries: []
    property int selectedIndex: 0
    property int slideDirection: 0
    property real slideProgress: 0
    property string activeKey: ""
    property var favorites: []
    property string mediaFilter: "all"
    property string colorFilter: ""
    property string searchQuery: ""
    property bool favoritesOnly: false
    property bool gridMode: false
    property bool applying: false
    property string errorMessage: ""
    property bool keyboardFocus: false
    property bool glassEnabled: true
    property bool reducedMotion: false
    property var motion: defaultMotion
    Core.Motion { id: defaultMotion; reduced: carousel.reducedMotion || !!carousel.theme && !carousel.theme.motionEnabled }
    readonly property bool motionEnabled: !reducedMotion && !motion.reduced && (!theme || theme.motionEnabled)
    readonly property bool mounted: open || revealProgress > 0.001
    readonly property color surface: theme ? theme.surfacePopup : "#20222c"
    readonly property color ink: theme ? theme.textPrimary : "#f6effa"
    readonly property color accent: theme ? theme.accentPrimary : "#d5aacb"
    readonly property string uiFont: theme ? theme.uiFont : "Sans Serif"
    property var previewRatios: ({})
    readonly property real selectedAspect: previewRatios[currentKey] || 16 / 9
    readonly property var targetMetrics: Geometry.layout(width, height, entries.length, selectedAspect)
    property var fromMetrics: Geometry.layout(width, height, entries.length)
    property var toMetrics: fromMetrics
    readonly property var metrics: Geometry.interpolateMetrics(fromMetrics, toMetrics, geometryProgress)
    readonly property rect glassRect: Qt.rect(0, height * (1 - revealProgress) * 0.04,
        width, height * (0.92 + 0.08 * revealProgress))
    readonly property real glassRadius: Math.min(36, glassRect.height / 4)
    property bool ready: false
    property bool updating: false
    property bool openedOnce: false
    property int startIndex: 0
    property int focusIndex: 0
    property var fromWeights: ({0: 1})
    property real fromOffset: 0
    property real targetOffset: 0
    property real geometryProgress: 1
    property real contentProgress: 0
    property int pendingStep: 0
    property int pendingIndex: -1
    property real wheelRemainder: 0
    property int hoverIndex: -1
    property int intentIndex: -1
    readonly property var weights: Geometry.blend(fromWeights, focusIndex, geometryProgress)
    readonly property real scrollOffset: fromOffset + (targetOffset - fromOffset) * geometryProgress
    readonly property var windowIndices: mounted && !gridMode
        ? Geometry.visibleIndices(metrics, entries.length, weights, scrollOffset) : []
    readonly property var currentEntry: entries.length ? entries[normalizedIndex(selectedIndex)] : null
    readonly property string currentKey: entryKey(currentEntry)
    readonly property bool animating: geometry.running || contentFade.running || contentDelay.running || hoverDelay.running

    signal navigateRequested(int delta)
    signal selectRelativeRequested(int delta)
    signal selectAbsoluteRequested(int index)
    signal applyRequested(var entry)
    signal randomRequested()
    signal favoriteRequested(var entry)
    signal hideRequested(var entry)
    signal refreshRequested()
    signal closeRequested()
    signal mediaFilterRequested(string filter)
    signal colorFilterRequested(string filter)
    signal searchRequested(string query)
    signal favoritesOnlyRequested(bool enabled)
    signal gridModeRequested(bool enabled)

    function alpha(color, amount) {
        return theme && theme.alpha ? theme.alpha(color, amount) : Qt.rgba(color.r, color.g, color.b, amount)
    }
    function normalizedIndex(index) { return Geometry.clamp(0, index, Math.max(0, entries.length - 1)) }
    function entryKey(entry) {
        return entry ? String(entry.key || (String(entry.kind || "static") + ":" + String(entry.path || ""))) : ""
    }
    function mediaBadge(entry) {
        const media = String(entry ? entry.mediaType || entry.kind || "static" : "")
        return media === "engine" ? "ENGINE" : media === "gif" ? "GIF"
            : media === "vid" || media === "live" ? "VID" : "IMG"
    }
    function cardRect(index) { return Geometry.rect(metrics, index, weights, scrollOffset) }
    function syncModel() {
        if (!ready || updating) return
        const wanted = windowIndices
        for (let i = cardModel.count - 1; i >= 0; --i)
            if (wanted.indexOf(cardModel.get(i).entryIndex) < 0) cardModel.remove(i)
        for (const entryIndex of wanted) {
            let found = false
            for (let i = 0; i < cardModel.count; ++i)
                if (cardModel.get(i).entryIndex === entryIndex) { found = true; break }
            if (!found) cardModel.append({entryIndex: entryIndex})
        }
    }
    function revealContent() {
        if (!open) return
        if (motionEnabled) contentDelay.restart()
        else contentProgress = 1
    }
    function retarget(initial = false) {
        if (!ready || !open) return
        updating = true
        const snapshot = Geometry.compact(weights)
        const offset = scrollOffset
        const previousMetrics = metrics
        geometry.stop(); contentDelay.stop(); contentFade.stop()
        fromMetrics = initial ? targetMetrics : previousMetrics
        toMetrics = targetMetrics
        focusIndex = normalizedIndex(selectedIndex)
        startIndex = initial
            ? Geometry.clamp(0, focusIndex - Math.floor(toMetrics.visibleCount / 2), Math.max(0, entries.length - toMetrics.visibleCount))
            : Geometry.windowStart(entries.length, toMetrics.visibleCount, focusIndex, startIndex)
        targetOffset = startIndex * (toMetrics.collapsedWidth + toMetrics.gap)
        fromOffset = initial ? targetOffset : offset
        if (initial) {
            const seed = {}
            for (let i = startIndex; i < startIndex + metrics.visibleCount; ++i) seed[i] = 1 / metrics.visibleCount
            fromWeights = seed
        } else fromWeights = snapshot
        geometryProgress = motionEnabled ? 0 : 1
        contentProgress = motionEnabled ? 0 : 1
        if (motionEnabled) { geometry.start(); revealContent() }
        updating = false
        syncModel()
    }
    function requestSearchFocus() {
        secondary.open()
        search.forceActiveFocus()
        search.selectAll()
    }
    function handleEscape() {
        if (secondary.opened) secondary.close()
        else if (gridMode) gridModeRequested(false)
        else closeRequested()
    }
    function requestStep(delta) {
        if (!open || entries.length <= 1) return
        const direction = delta < 0 ? -1 : 1
        if (geometry.running) { pendingStep = direction; pendingIndex = -1; return }
        navigateRequested(direction)
    }
    function requestIndex(index) {
        if (!open) return
        if (geometry.running) { pendingIndex = normalizedIndex(index); pendingStep = 0; return }
        selectAbsoluteRequested(normalizedIndex(index))
    }
    function flushNavigation() {
        if (!open || geometry.running) return
        const index = pendingIndex, step = pendingStep
        pendingIndex = -1; pendingStep = 0
        if (index >= 0 && index !== selectedIndex) selectAbsoluteRequested(index)
        else if (step) navigateRequested(step)
    }
    function handleWheel(delta, pixels = false) {
        if (!open || Math.abs(delta) < 1 || entries.length <= 1) return
        // High-resolution trackpads emit many sub-notch events. Consume an
        // intent once, and discard inertia while that intent is being accepted.
        if (wheelCooldown.running) return
        if (wheelRemainder * delta < 0) wheelRemainder = 0
        wheelRemainder += delta
        const threshold = pixels ? 40 : 120
        if (Math.abs(wheelRemainder) < threshold) return
        requestStep(wheelRemainder < 0 ? 1 : -1)
        wheelRemainder = 0
        wheelCooldown.restart()
    }
    function wheelEvent(wheel) {
        const angle = wheel.angleDelta.y || wheel.angleDelta.x
        handleWheel(angle || wheel.pixelDelta.y || wheel.pixelDelta.x, !angle)
        wheel.accepted = true
    }
    function describeTile(tile: var): var {
        return {index: tile.entryIndex, rect: tile.cardRect, x: tile.x, y: tile.y,
            width: tile.width, height: tile.height, imageStatus: tile.imageStatus, source: tile.imageSource, livePreview: tile.livePreviewActive}
    }
    function diagnostics() {
        const delegates = []
        for (let i = 0; i < cards.count; ++i) {
            const tile = cards.itemAt(i)
            if (tile) delegates.push(describeTile(tile))
        }
        return {entries: entries.length, selectedIndex: selectedIndex, modelCount: cardModel.count,
            glassEnabled: glassEnabled,
            activeFocus: activeFocus, keyboardFocus: keyboardFocus,
            pendingStep: pendingStep, pendingIndex: pendingIndex, open: open, gridMode: gridMode, animating: animating, reducedMotion: !motionEnabled,
            contentProgress: contentProgress, geometryProgress: geometryProgress, metrics: metrics,
            stage: {x: stage.x, y: stage.y, width: stage.width, height: stage.height}, delegates: delegates}
    }
    Component.onCompleted: { ready = true; if (open) { retarget(true); openedOnce = true } }
    onSelectedIndexChanged: retarget()
    onEntriesChanged: { pendingStep = 0; pendingIndex = -1; cardModel.clear(); retarget(true) }
    onTargetMetricsChanged: if (ready && !updating) Qt.callLater(retarget)
    onWindowIndicesChanged: syncModel()
    onGridModeChanged: { if (open && !gridMode) retarget(true); syncModel() }
    onOpenChanged: {
        if (open) {
            retarget(!openedOnce)
            openedOnce = true
            if (keyboardFocus) Qt.callLater(function() { carousel.forceActiveFocus() })
        } else {
            hoverDelay.stop(); searchDelay.stop(); wheelCooldown.stop(); wheelRemainder = 0; secondary.close(); intentIndex = -1; hoverIndex = -1
            pendingStep = 0; pendingIndex = -1
            geometry.stop(); contentDelay.stop(); contentFade.stop()
            if (motionEnabled && mounted) { contentFade.to = 0; contentFade.duration = motion.contentExit; contentFade.start() }
            else contentProgress = 0
        }
    }
    onMountedChanged: if (!mounted) {
        geometry.stop(); contentFade.stop(); contentDelay.stop(); hoverDelay.stop(); searchDelay.stop(); wheelCooldown.stop()
        cardModel.clear()
    }
    onMotionEnabledChanged: if (!motionEnabled) {
        geometry.stop(); contentFade.stop(); contentDelay.stop(); hoverDelay.stop()
        geometryProgress = 1; contentProgress = open ? 1 : 0
        flushNavigation()
    }
    NumberAnimation { id: geometry; target: carousel; property: "geometryProgress"; to: 1; duration: carousel.motion.accordionDuration; easing.type: carousel.motion.easeHandoff; onFinished: Qt.callLater(carousel.flushNavigation) }
    Timer { id: contentDelay; interval: carousel.motion.contentDelay; onTriggered: {
        if (carousel.open) { contentFade.to = 1; contentFade.duration = carousel.motion.contentDuration; contentFade.start() }
    } }
    NumberAnimation { id: contentFade; target: carousel; property: "contentProgress"; easing.type: carousel.motion.easeContent }
    Timer { id: wheelCooldown; interval: carousel.motionEnabled ? carousel.motion.accordionDuration : carousel.motion.intent }
    Timer { id: hoverDelay; interval: carousel.motion.intent; onTriggered: if (carousel.open) carousel.intentIndex = carousel.hoverIndex }
    Timer { id: searchDelay; interval: 180; onTriggered: if (carousel.open) carousel.searchRequested(search.text) }
    ListModel { id: cardModel }
    focus: keyboardFocus
    visible: mounted
    opacity: open ? 1 : Math.min(1, revealProgress * 2)
    Keys.onPressed: event => {
        if (!open) return
        const ctrl = (event.modifiers & Qt.ControlModifier) !== 0
        if (!ctrl && (event.key === Qt.Key_Left || event.key === Qt.Key_A)) requestStep(-1)
        else if (!ctrl && (event.key === Qt.Key_Right || event.key === Qt.Key_D)) requestStep(1)
        else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) { if (currentEntry && !applying) applyRequested(currentEntry) }
        else if (event.key === Qt.Key_Escape) handleEscape()
        else if (event.key === Qt.Key_F && ctrl || event.key === Qt.Key_Slash) requestSearchFocus()
        else if (event.key === Qt.Key_F && currentEntry) favoriteRequested(currentEntry)
        else if (event.key === Qt.Key_H && currentEntry) hideRequested(currentEntry)
        else if (event.key === Qt.Key_R) { if (ctrl) refreshRequested(); else randomRequested() }
        else if (event.key === Qt.Key_G) gridModeRequested(!gridMode)
        else return
        event.accepted = true
    }
    MediaAssets.GlassPanel {
        visible: carousel.glassEnabled
        x: carousel.glassRect.x; y: carousel.glassRect.y
        width: carousel.glassRect.width; height: carousel.glassRect.height
        radius: carousel.glassRadius
        nativeOptics: true
        consumeInput: false
        surfaceColor: carousel.alpha(carousel.surface, 0.09)
        opacity: carousel.revealProgress
    }
    Rectangle {
        visible: carousel.glassEnabled
        x: carousel.glassRect.x; y: carousel.glassRect.y
        width: carousel.glassRect.width; height: carousel.glassRect.height
        radius: carousel.glassRadius
        color: "black"
        opacity: 0.34 * carousel.revealProgress
    }
    Item {
        anchors.fill: parent
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => { if (mouse.button === Qt.RightButton) secondary.open(); else carousel.closeRequested() }
            onWheel: wheel => carousel.wheelEvent(wheel)
        }
    }
    Item {
        id: stage
        x: carousel.metrics.stageX
        y: (carousel.height - height) / 2
        width: carousel.metrics.stageWidth
        height: carousel.metrics.cardHeight * (0.42 + 0.58 * carousel.revealProgress)
        clip: true
        visible: !carousel.gridMode
        Repeater {
            id: cards
            model: cardModel
            delegate: Rectangle {
                id: tile
                required property int entryIndex
                objectName: "wallpaperCard" + entryIndex
                readonly property var entry: carousel.entries[entryIndex] || ({})
                readonly property var cardRect: carousel.cardRect(entryIndex)
                readonly property bool selected: entryIndex === carousel.normalizedIndex(carousel.selectedIndex)
                readonly property bool intended: entryIndex === carousel.intentIndex
                readonly property int imageStatus: thumbnail.status
                readonly property url imageSource: thumbnail.source
                readonly property bool livePreviewActive: livePreview.active
                readonly property bool activeWallpaper: carousel.entryKey(entry) === carousel.activeKey
                x: cardRect.x; width: cardRect.width; height: stage.height
                radius: 18
                color: carousel.surface
                clip: true
                // Clip the complete image/gradient composition to the real radius.
                layer.enabled: true
                layer.effect: MultiEffect { maskEnabled: true; maskSource: roundedMask }
                Rectangle { id: roundedMask; width: tile.width; height: tile.height; radius: tile.radius; visible: false; layer.enabled: true }
                Image {
                    id: thumbnail
                    anchors.fill: parent
                    source: String(tile.entry.preview || "")
                    asynchronous: true; cache: true; retainWhileLoading: true
                    fillMode: Image.PreserveAspectCrop
                    // Fixed thumbnail budget: width animation never re-decodes 4K.
                    sourceSize.width: 720; sourceSize.height: 520
                    onStatusChanged: if (status === Image.Ready && implicitHeight > 0) {
                        const key = carousel.entryKey(tile.entry)
                        const ratio = implicitWidth / implicitHeight
                        if (Math.abs((carousel.previewRatios[key] || 0) - ratio) > 0.001) {
                            const ratios = Object.assign({}, carousel.previewRatios)
                            ratios[key] = ratio
                            carousel.previewRatios = ratios
                        }
                    }
                }
                // The strips show a crop. The shared cached texture is also
                // composed at the final hero size, revealing the complete image
                // continuously as this card receives the expansion budget.
                Rectangle {
                    width: carousel.metrics.expandedWidth; height: tile.height
                    x: (tile.width - width) / 2
                    opacity: tile.cardRect.focus
                    color: carousel.surface
                    Image {
                        anchors.fill: parent
                        source: thumbnail.source
                        sourceSize: thumbnail.sourceSize
                        asynchronous: true; cache: true; retainWhileLoading: true
                        fillMode: Image.PreserveAspectCrop
                    }
                }
                Loader {
                    id: livePreview
                    anchors.fill: parent
                    active: carousel.open && tile.selected && carousel.motionEnabled
                        && carousel.geometryProgress >= 0.999 && !carousel.gridMode
                        && carousel.pendingStep === 0 && carousel.pendingIndex < 0
                        && ["GIF", "VID"].indexOf(carousel.mediaBadge(tile.entry)) >= 0
                    sourceComponent: MediaAssets.LiveCharacter {
                        source: String(tile.entry.path || "")
                        playing: livePreview.active
                        fillMode: Image.PreserveAspectFit
                        sourceSize: Qt.size(720, 520)
                        mipmap: false
                    }
                }
                Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.16 * (1 - tile.cardRect.focus)) }
                Rectangle {
                    anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                    height: Math.min(140, parent.height * 0.45)
                    gradient: Gradient {
                        GradientStop { position: 0; color: "transparent" }
                        GradientStop { position: 1; color: "#a80c0d13" }
                    }
                }
                Rectangle {
                    anchors.fill: parent; radius: tile.radius; color: "transparent"
                    border.width: 1
                    border.color: carousel.alpha(tile.selected || tile.intended ? carousel.accent : carousel.ink, tile.selected || tile.intended ? 0.40 : 0.14)
                    Behavior on border.color { ColorAnimation { duration: carousel.motionEnabled ? carousel.motion.surfaceHover : 0 } }
                }
                Text {
                    anchors.centerIn: parent
                    visible: thumbnail.status !== Image.Ready && tile.selected
                    text: thumbnail.status === Image.Error ? "Preview indisponível" : "Carregando…"
                    width: Math.max(0, parent.width - 24); wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter; color: carousel.ink
                    font.pixelSize: 11; font.family: carousel.uiFont
                }
                Column {
                    anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                    anchors.margins: 18
                    spacing: 6
                    opacity: tile.selected ? carousel.contentProgress : 0
                    transform: Translate { y: (1 - carousel.contentProgress) * 6 }
                    Behavior on opacity { enabled: !tile.selected; NumberAnimation { duration: carousel.motionEnabled ? carousel.motion.contentExit : 0 } }
                    Text {
                        text: carousel.mediaBadge(tile.entry) + (tile.activeWallpaper ? " · ACTIVE" : "")
                            + (carousel.favorites.indexOf(carousel.entryKey(tile.entry)) >= 0 ? " · ♥" : "")
                        color: "#eee8ed"; font.pixelSize: 10; font.family: carousel.uiFont
                    }
                }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    enabled: carousel.open
                    onEntered: { carousel.hoverIndex = tile.entryIndex; hoverDelay.restart() }
                    onExited: if (carousel.hoverIndex === tile.entryIndex) { hoverDelay.stop(); carousel.hoverIndex = -1; carousel.intentIndex = -1 }
                    onClicked: mouse => {
                        carousel.requestIndex(tile.entryIndex); carousel.forceActiveFocus()
                        if (mouse.button === Qt.RightButton) secondary.open()
                    }
                    onDoubleClicked: mouse => { if (mouse.button === Qt.LeftButton && !carousel.applying) carousel.applyRequested(tile.entry) }
                    onWheel: wheel => carousel.wheelEvent(wheel)
                }
            }
        }
    }
    GridView {
        id: grid
        x: stage.x; y: stage.y; width: stage.width; height: stage.height
        visible: carousel.gridMode; clip: true
        model: carousel.open && visible ? carousel.entries : []
        cacheBuffer: 0
        cellWidth: width / Math.max(1, Math.floor(width / 240))
        cellHeight: Math.min(200, cellWidth * 0.65)
        currentIndex: carousel.selectedIndex
        delegate: Item {
            id: gridTile
            required property int index
            required property var modelData
            width: grid.cellWidth; height: grid.cellHeight
            Rectangle { anchors.fill: parent; anchors.margins: 3; radius: 12; color: "transparent"; border.width: 1; border.color: gridTile.index === carousel.selectedIndex ? carousel.accent : "transparent" }
            Image {
                anchors.fill: parent; anchors.margins: 6
                source: String(gridTile.modelData.preview || "")
                asynchronous: true; cache: true; fillMode: Image.PreserveAspectCrop
                sourceSize.width: 320; sourceSize.height: 200
            }
            MouseArea {
                anchors.fill: parent
                onClicked: { carousel.selectAbsoluteRequested(gridTile.index); carousel.forceActiveFocus() }
                onDoubleClicked: if (!carousel.applying) carousel.applyRequested(gridTile.modelData)
            }
        }
    }
    Text {
        anchors.centerIn: stage; visible: !carousel.entries.length
        text: "Nenhum wallpaper encontrado"; color: carousel.ink
        font.family: carousel.uiFont; font.pixelSize: 18
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter; y: stage.y + stage.height + 12
        width: Math.min(stage.width, 600); horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
        visible: text.length > 0
        text: carousel.errorMessage || (carousel.applying ? "Aplicando…" : "")
        color: carousel.ink; font.family: carousel.uiFont; font.pixelSize: 12
    }
    Popup {
        id: secondary
        x: Math.max(8, (carousel.width - width) / 2)
        y: Math.max(8, (carousel.height - height) / 2)
        width: Math.min(340, carousel.width - 16)
        height: Math.min(implicitHeight, carousel.height - 16)
        padding: 14; focus: true; modal: true
        background: Rectangle { radius: 18; color: carousel.surface; border.width: 1; border.color: carousel.alpha(carousel.ink, 0.18) }
        onClosed: if (carousel.open && carousel.keyboardFocus) carousel.forceActiveFocus()
        contentItem: Flickable {
            implicitHeight: secondaryColumn.implicitHeight
            contentHeight: secondaryColumn.height; clip: true
            Column {
                id: secondaryColumn
                width: parent.width; spacing: 3
                TextField {
                    id: search
                    width: parent.width; height: 38
                    text: carousel.searchQuery; placeholderText: "Buscar wallpaper"
                    color: carousel.ink; placeholderTextColor: carousel.alpha(carousel.ink, 0.55)
                    font.family: carousel.uiFont; font.pixelSize: 13
                    background: Rectangle { radius: 9; color: carousel.alpha(carousel.ink, 0.07); border.width: 1; border.color: carousel.alpha(carousel.ink, 0.15) }
                    onTextEdited: searchDelay.restart()
                }
                SecondaryAction { text: "Favorito · F"; enabled: !!carousel.currentEntry; onClicked: { carousel.favoriteRequested(carousel.currentEntry); secondary.close() } }
                SecondaryAction { text: "Ocultar · H"; enabled: !!carousel.currentEntry; onClicked: { carousel.hideRequested(carousel.currentEntry); secondary.close() } }
                SecondaryAction { text: "Aleatório · R"; onClicked: { carousel.randomRequested(); secondary.close() } }
                SecondaryAction { text: "Atualizar · Ctrl+R"; onClicked: { carousel.refreshRequested(); secondary.close() } }
                SecondaryAction {
                    text: "Tipo: " + (carousel.mediaFilter === "all" ? "Todos" : carousel.mediaFilter.toUpperCase()) + "  ›"
                    onClicked: { const types = ["all", "img", "gif", "vid", "engine"]; carousel.mediaFilterRequested(types[(types.indexOf(carousel.mediaFilter) + 1) % types.length]) }
                }
                SecondaryAction {
                    text: "Cor: " + (carousel.colorFilter || "Todas") + "  ›"
                    onClicked: { const colors = ["", "red", "orange", "yellow", "green", "cyan", "blue", "purple", "pink", "neutral"]; carousel.colorFilterRequested(colors[(colors.indexOf(carousel.colorFilter) + 1) % colors.length]) }
                }
                SecondaryAction { text: carousel.favoritesOnly ? "Mostrar todos" : "Somente favoritos"; onClicked: carousel.favoritesOnlyRequested(!carousel.favoritesOnly) }
                SecondaryAction { text: carousel.gridMode ? "Voltar aos cards · G" : "Grade · G"; onClicked: { carousel.gridModeRequested(!carousel.gridMode); secondary.close() } }
            }
        }
    }
    component SecondaryAction: ItemDelegate {
        id: action
        width: parent.width; height: 34
        contentItem: Text { text: action.text; color: carousel.ink; opacity: action.enabled ? 1 : 0.4; font.family: carousel.uiFont; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter }
        background: Rectangle { radius: 8; color: carousel.alpha(carousel.ink, action.hovered || action.activeFocus ? 0.10 : 0) }
    }
}
