import QtQuick
import Quickshell.Hyprland
import "../../components" as Components
import "BarGeometry.js" as BarGeometry

Item {
    id: root
    required property var config
    required property var theme
    required property var clock
    required property var media
    required property var weather
    required property var status
    required property var actions
    required property var compositor
    required property var editorController
    required property var controller
    required property var host
    required property var system
    required property var timerService
    required property real wavePhase
    property int opticsGeneration: 0
    property alias barSurfaceItem: background
    property real leftInset: 0
    property real rightInset: 20
    signal geometryChanged()
    function sectionWidth(section) {
        return config.topbarItemsForSection(section, false).reduce((sum, item) => sum + legacyItemWidth(item.type), 0)
    }
    readonly property var sectionBounds: BarGeometry.sections(width,
        sectionWidth("left"), sectionWidth("center"), toolRow.width, leftInset, rightInset)
    onSectionBoundsChanged: geometryChanged()
    readonly property var hyprMonitor: Hyprland.monitorFor(host.screen)
    readonly property var workspaceIds: {
        const ids = [1, 2, 3, 4, 5]
        for (const workspace of Hyprland.workspaces.values)
            if (workspace.id > 0 && !ids.includes(workspace.id)) ids.push(workspace.id)
        const active = hyprMonitor && hyprMonitor.activeWorkspace ? hyprMonitor.activeWorkspace.id : 0
        if (active > 0 && !ids.includes(active)) ids.push(active)
        return ids.sort((a, b) => a - b)
    }
    readonly property real unit: 1
    readonly property bool compact: width < 1280
    readonly property real density: width < 760 ? 0.8 : 1
    readonly property bool editing: editorController.shown && editorController.mode === "editing"
        && editorController.editSpace === "desktop"
    readonly property var visibleTools: config.topbarToolsOrder.filter(type =>
        type !== "caffeine" && (type !== "thing" || config.topbarOneThingEnabled)
        && (type !== "notes" || config.topbarNotesEnabled))
    property string dragType: ""
    property int dragFrom: -1
    property int dragTo: -1
    property real dragOrigin: 0
    property real dragPosition: 0
    property real dragWidth: 0
    onEditingChanged: { cancelDrag(); root.controller.close() }
    function cancelDrag() { dragType = ""; dragFrom = -1; dragTo = -1 }
    function beginDrag(type, item, point) {
        dragType = type; dragFrom = visibleTools.indexOf(type); dragTo = dragFrom
        dragOrigin = point; dragPosition = point; dragWidth = item.width
    }
    function updateDrag(point) {
        dragPosition = point
        let target = 0
        for (let i = 0; i < toolRepeater.count; ++i) {
            const item = toolRepeater.itemAt(i)
            if (point > toolRow.x + item.x + item.width / 2) target = i + 1
        }
        dragTo = Math.max(0, Math.min(visibleTools.length - 1, target > dragFrom ? target - 1 : target))
    }
    function finishDrag() {
        const type = dragType, target = visibleTools[dragTo]
        cancelDrag()
        if (target && type !== target) config.moveTopbarTool(type, target)
    }
    function displacement(index, type) {
        if (!dragType) return 0
        if (type === dragType) return dragPosition - dragOrigin
        if (dragFrom < dragTo && index > dragFrom && index <= dragTo) return -dragWidth - toolRow.spacing
        if (dragTo < dragFrom && index >= dragTo && index < dragFrom) return dragWidth + toolRow.spacing
        return 0
    }
    function label(type) {
        return ({cat: "RunCat · CPU", caffeine: "Manter acordado", timer: "Timer", usb: "Dispositivos USB",
            thing: "One Thing", notes: "Notas · arraste para baixo para criar", battery: "Bateria", monitor: "Monitores", paint: "Misturar cores do wallpaper", wifi: "Wi-Fi",
            search: "Buscar aplicativos", controls: "Controles", clock: "Data e calendário"})[type] || type
    }
    function legacyItemWidth(type) {
        const widths = { launcher: 90, workspaces: 208, context: compact ? 130 : 250,
            clock: compact ? 210 : 330, media: compact ? 100 : 140,
            wifi: 54, volume: 54, battery: 86, settings: 48, avatar: 48,
            search: 48, weather: 60, brand: 90 }
        return (widths[type] || 48) * unit
    }
    function legacyGlyph(type) {
        if (type === "launcher") return "apps"
        if (type === "media") return media.playing ? "pause" : "play"
        if (type === "volume") return status.muted ? "volume-muted" : "volume"
        if (type === "battery") return "battery"
        return type === "avatar" ? "person" : type
    }
    function legacyLabel(type) {
        if (type === "clock") return clock.locale().toString(clock.now,
            compact ? "ddd, dd MMM — HH:mm" : "ddd, dd 'de' MMMM — HH:mm").replace(/\./g, "")
        if (type === "media") return media.hasPlayer ? media.title : "Sem mídia"
        if (type === "battery") return status.hasBattery ? status.batteryPercent + "%" : ""
        if (type === "weather") return weather.available
            ? weather.temperature + "° · " + weather.description : ""
        if (type === "brand") return "Velora"
        return ""
    }
    function activateLegacy(type) {
        if (type === "launcher" || type === "search") actions.openLauncher()
        else if (type === "media") media.hasPlayer ? media.togglePlaying() : actions.openMusic()
        else if (type === "wifi") actions.openNetworkSettings()
        else if (type === "volume") status.toggleMuted()
        else if (type === "clock") editorController.show("desktop")
        else actions.openSettings()
    }

    Item { id: background; anchors.fill: parent }
    component Section: Row {
        id: section
        required property string sectionName
        height: root.height
        Repeater {
            model: root.config.topbarItemsForSection(section.sectionName, false)
            Item {
                id: entry
                required property var modelData
                readonly property string type: modelData.type
                width: root.legacyItemWidth(type)
                height: root.height
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6 * root.unit
                    radius: 16 * root.unit
                    color: root.theme.accentMuted
                    visible: pointer.containsMouse && entry.type !== "workspaces"
                }
                Components.VeloraIconMotion {
                    id: legacyIconMotion
                    highlighted: pointer.containsMouse || entry.activeFocus
                    reducedMotion: root.config.reducedMotion
                }
                Row {
                    id: entryVisual
                    anchors.centerIn: parent
                    spacing: 8 * root.unit
                    visible: !["workspaces", "context"].includes(entry.type)
                    Components.VeloraMaterialIcon {
                        scale: legacyIconMotion.zoom
                        transform: Translate { y: legacyIconMotion.lift }
                        opacity: legacyIconMotion.inkOpacity
                        anchors.verticalCenter: parent.verticalCenter
                        width: 23 * root.unit; height: width
                        visible: !["clock", "brand"].includes(entry.type)
                        iconName: root.legacyGlyph(entry.type)
                        iconColor: root.theme.accentSoft
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: text.length > 0
                        text: root.legacyLabel(entry.type)
                        width: entry.type === "media" ? entry.width - 46 * root.unit : implicitWidth
                        elide: Text.ElideRight
                        color: root.theme.textPrimary
                        font.family: "Poppins"
                        font.pixelSize: (entry.type === "clock" ? 15 : 12) * root.unit
                    }
                }
                Loader {
                    active: entry.type === "weather"
                    x: entryVisual.x + entryVisual.width + 10
                    width: 46; height: root.height
                    sourceComponent: catComponent
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1; height: 27 * root.unit
                    color: root.theme.borderSubtle
                    visible: ["launcher", "workspaces", "media", "battery"].includes(entry.type)
                }
                Column {
                    x: 14 * root.unit
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 24 * root.unit
                    visible: entry.type === "context"
                    spacing: -1 * root.unit
                    Text {
                        width: parent.width
                        text: root.editorController.mounted ? "Velora"
                            : String(root.compositor.activeToplevel
                                ? (root.compositor.activeToplevel.appId || "Desktop") : "Desktop")
                        color: root.theme.textMuted
                        font.family: "Poppins"; font.pixelSize: 11 * root.unit
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: root.editorController.mounted ? "Configurações"
                            : String(root.compositor.activeToplevel
                                ? root.compositor.activeToplevel.title : "Área de trabalho")
                        color: root.theme.textPrimary
                        font.family: "Poppins"; font.pixelSize: 12 * root.unit
                        elide: Text.ElideRight
                    }
                }
                MouseArea {
                    id: pointer
                    anchors.fill: parent
                    enabled: entry.type !== "workspaces" && entry.type !== "weather"
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activateLegacy(entry.type)
                    onWheel: function(event) {
                        if (entry.type === "volume") root.status.adjustVolume(event.angleDelta.y > 0 ? 1 : -1)
                    }
                }
                Loader {
                    anchors.centerIn: parent
                    active: entry.type === "workspaces"
                    width: Math.min(176, entry.width - 32); height: 32
                    sourceComponent: WorkspaceSwitcher {
                        theme: root.theme
                        workspaceIds: root.workspaceIds
                        activeWorkspaceId: root.hyprMonitor && root.hyprMonitor.activeWorkspace
                            ? root.hyprMonitor.activeWorkspace.id : 0
                        onWorkspaceRequested: workspaceId => Hyprland.dispatch("workspace " + workspaceId)
                    }
                }
            }
        }
    }
    Flickable {
        x: root.sectionBounds.left.x; width: root.sectionBounds.left.width; height: root.height
        contentWidth: leftSection.width; contentHeight: height
        clip: true; boundsBehavior: Flickable.StopAtBounds
        interactive: contentWidth > width
        onContentXChanged: root.geometryChanged()
        Section { id: leftSection; sectionName: "left" }
    }
    Flickable {
        x: root.sectionBounds.center.x; width: root.sectionBounds.center.width; height: root.height
        contentWidth: centerSection.width; contentHeight: height
        clip: true; boundsBehavior: Flickable.StopAtBounds
        interactive: contentWidth > width
        onContentXChanged: root.geometryChanged()
        Section { id: centerSection; sectionName: "center" }
    }

    Component {
        id: catComponent
        BarItem {
            id: catItem
            theme: root.theme
            reducedMotion: root.config.reducedMotion
            label: root.label("cat")
            selected: root.controller.owner === root.host && root.controller.activeType === "cat"
            onActivated: root.controller.toggle("cat", catItem, root.host)
            onSecondaryActivated: root.controller.toggle("cat", catItem, root.host)
            Component.onCompleted: root.controller.registerItem("cat", catItem, root.host)
            Component.onDestruction: root.controller.unregisterItem(catItem)
            Components.VeloraIconMotion {
                id: catMotion
                highlighted: catItem.hovered || catItem.activeFocus
                reducedMotion: root.config.reducedMotion
            }
            RunCatIcon {
                scale: catMotion.zoom
                transform: Translate { y: catMotion.lift }
                anchors.centerIn: parent
                width: 34; height: 22
                color: root.theme.textPrimary
                cpuUsage: root.system.cpuUsage
                animate: root.system.enabled && root.system.catAnimation
            }
        }
    }

    Flickable {
        x: root.sectionBounds.right.x; width: root.sectionBounds.right.width; height: root.height
        contentWidth: toolRow.width; contentHeight: height
        clip: true; boundsBehavior: Flickable.StopAtBounds
        interactive: contentWidth > width
        onContentXChanged: root.geometryChanged()
    Row {
        id: toolRow
        height: root.height
        spacing: 1
        Repeater {
            id: toolRepeater
            model: root.visibleTools
            BarItem {
                id: item
                required property string modelData
                required property int index
                readonly property string type: modelData
                theme: root.theme
                reducedMotion: root.config.reducedMotion
                width: (type === "clock" ? 178 : type === "thing" ? (root.width < 1000 ? 90 : 160)
                    : type === "timer" ? 74 : type === "battery" ? 44 : 36) * root.density
                height: root.height
                label: root.label(type)
                Rectangle {
                    // A trailing divider for message, timer and search; avoid
                    // doubling it when the calendar follows one of them.
                    visible: ["thing", "timer", "search"].includes(item.type)
                        || (item.type === "clock" && item.index > 0
                            && !["thing", "timer", "search"].includes(root.visibleTools[item.index - 1]))
                    x: item.type === "clock" ? 0 : parent.width - 1
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1; height: 16; radius: 0.5
                    color: root.theme.withAlpha(root.theme.textPrimary, 0.32)
                }
                selected: root.controller.owner === root.host && root.controller.activeType === type
                dragToCreate: type === "notes" && !root.editing
                onHoveredChanged: {
                    if (hovered && !root.editing) root.controller.enter(type, item, root.host)
                    else root.controller.leave(item)
                }
                z: root.dragType === type ? 10 : 0
                transform: Translate {
                    x: root.displacement(item.index, item.type)
                    Behavior on x { enabled: root.dragType !== item.type; NumberAnimation { duration: root.config.reducedMotion ? 0 : 120 } }
                }
                onDraggedDown: {
                    root.system.newNote()
                    if (!selected) root.controller.toggle(type, item, root.host)
                }
                onActivated: if (!root.editing) root.controller.toggle(type, item, root.host)
                onSecondaryActivated: if (!root.editing) root.controller.toggle(type, item, root.host)
                Keys.onLeftPressed: event => {
                    if (root.editing) root.config.stepTopbarTool(type, -1)
                    else event.accepted = false
                }
                Keys.onRightPressed: event => {
                    if (root.editing) root.config.stepTopbarTool(type, 1)
                    else event.accepted = false
                }
                Keys.onEscapePressed: if (root.dragType) root.cancelDrag()
                Rectangle {
                    anchors.fill: parent; anchors.margins: 3
                    visible: root.editing
                    radius: 7; color: "transparent"
                    border.width: 1
                    border.color: root.theme.withAlpha(root.theme.accentSoft, root.dragType === item.type ? 1 : 0.35)
                }
                MouseArea {
                    anchors.fill: parent; z: 30
                    enabled: root.editing
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    preventStealing: true
                    onPressed: mouse => {
                        item.forceActiveFocus()
                        root.beginDrag(item.type, item, mapToItem(root, mouse.x, mouse.y).x)
                    }
                    onPositionChanged: mouse => {
                        if (pressed && root.dragType === item.type)
                            root.updateDrag(mapToItem(root, mouse.x, mouse.y).x)
                    }
                    onReleased: if (root.dragType === item.type) root.finishDrag()
                    onCanceled: root.cancelDrag()
                }
                Component.onCompleted: root.controller.registerItem(type, item, root.host)
                Component.onDestruction: root.controller.unregisterItem(item)
                Components.VeloraIconMotion {
                    id: iconMotion
                    highlighted: item.hovered || item.activeFocus
                    reducedMotion: root.config.reducedMotion
                }
                BatteryIndicator {
                    scale: iconMotion.zoom
                    transform: Translate { y: iconMotion.lift }
                    opacity: iconMotion.inkOpacity
                    anchors.centerIn: parent
                    visible: item.type === "battery"
                    available: root.status.hasBattery; level: root.status.batteryLevel; charging: root.status.batteryCharging
                    color: root.theme.textPrimary; warningColor: root.theme.warning; criticalColor: root.theme.danger
                }
                BarIcon {
                    scale: iconMotion.zoom
                    transform: Translate { y: iconMotion.lift }
                    opacity: iconMotion.inkOpacity
                    anchors.centerIn: parent
                    width: item.type === "cat" ? 34 : item.type === "caffeine" ? 24 : 20
                    height: 22
                    visible: !["timer", "thing", "clock", "battery", "caffeine", "cat"].includes(item.type)
                    name: item.type
                    color: root.theme.textPrimary
                    level: root.system.wifiStrength
                    muted: item.type === "wifi" && !root.status.wifiEnabled
                    connected: root.status.wifiConnected
                }
                Loader {
                    scale: iconMotion.zoom
                    transform: Translate { y: iconMotion.lift }
                    opacity: iconMotion.inkOpacity
                    anchors.centerIn: parent
                    active: item.type === "caffeine"
                    width: 24; height: 22
                    sourceComponent: CoffeeIcon {
                        color: root.theme.textPrimary
                        active: root.system.caffeineActive
                        animate: root.system.enabled
                        opacity: active ? 1 : 0.7
                        Behavior on opacity { NumberAnimation { duration: 160 } }
                    }
                }
                Rectangle {
                    anchors.centerIn: parent
                    visible: item.type === "timer"
                    width: parent.width - 10; height: 25; radius: 7
                    color: root.timerService.countdown.running || root.timerService.finished
                        ? root.theme.textPrimary : root.theme.withAlpha(root.theme.textPrimary, 0.07)
                    border.width: 1
                    border.color: root.theme.withAlpha(root.theme.textPrimary, 0.18)
                    Rectangle {
                        anchors.fill: parent; anchors.margins: 3
                        radius: 4; color: "transparent"
                        border.width: 1; border.color: root.theme.withAlpha(root.theme.textPrimary, 0.09)
                    }
                    Behavior on color { ColorAnimation { duration: 160 } }
                    TimerLabel {
                        anchors.centerIn: parent; text: root.timerService.barText || root.timerService.timerText
                        transitionKey: root.timerService.duration + ":" + root.timerService.engaged
                        color: root.timerService.countdown.running || root.timerService.finished ? root.theme.profileDark : root.theme.textPrimary
                        family: root.theme.bodyFont; pixelSize: 14; tabular: true
                        Behavior on color { ColorAnimation { duration: 160 } }
                    }
                }
                Rectangle {
                    anchors.centerIn: parent
                    visible: item.type === "thing"
                    width: parent.width - 16; height: 25; radius: 7
                    color: root.theme.withAlpha(root.theme.textPrimary, 0.07)
                    border.width: 1
                    border.color: root.theme.withAlpha(root.theme.textPrimary, 0.18)
                }
                Text {
                    anchors.centerIn: parent
                    width: parent.width - 28
                    visible: item.type === "thing"
                    text: item.type === "thing" ? root.system.oneThing || "What is the one thing?"
                        : root.clock.locale().toString(root.clock.now, "ddd d MMM  HH:mm").replace(/\./g, "")
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    color: root.theme.textPrimary
                    font.family: root.theme.bodyFont; font.pixelSize: 12
                }
                TimerLabel {
                    anchors.centerIn: parent
                    visible: item.type === "clock"
                    text: root.clock.locale().toString(root.clock.now, "ddd d MMM  HH:mm").replace(/\./g, "")
                    transitionKey: "clock"
                    color: root.theme.textPrimary
                    family: root.theme.bodyFont; pixelSize: 12
                }
            }
        }
    }
    }
}
