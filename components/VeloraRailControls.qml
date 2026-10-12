import QtQuick
import "../core" as Core
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Item {
    id: root

    property var theme: null
    property color accent: "#ff9d68"
    property bool rightSide: false
    property real railWidth: 64
    property var extraPanel: null
    property var motion: defaultMotion
    Core.Motion { id: defaultMotion }
    property var handoffSource: null
    readonly property bool mounted: volumePanel.mounted || brightnessPanel.mounted
    readonly property bool interactionHeld: volumePanel.panelHeld || brightnessPanel.panelHeld
    readonly property bool panelHovered: volumePanel.panelHovered || brightnessPanel.panelHovered
    readonly property var nativePanel: volumePanel.opened ? volumePanel.outline
        : brightnessPanel.opened ? brightnessPanel.outline
        : extraPanel && extraPanel.visible ? extraPanel
        : volumePanel.mounted ? volumePanel.outline
        : brightnessPanel.mounted ? brightnessPanel.outline
        : batteryPanel.visible ? batteryPanel : null
    signal levelOpening(var popover)
    signal levelClosed(string type)
    onPanelHoveredChanged: panelHoverChanged(panelHovered || interactionHeld)
    onInteractionHeldChanged: panelHoverChanged(panelHovered || interactionHeld)
    onNativePanelChanged: shapeChanged()
    property real volumeCenter: 300
    property real brightnessCenter: 390
    property real batteryCenter: 510
    property bool volumeOpen: false
    property bool brightnessOpen: false
    property bool batteryOpen: false
    property int refreshSerial: 0
    property alias volumeMask: volumePanel.maskItem
    property alias brightnessMask: brightnessPanel.maskItem
    property alias batteryMask: batteryPanel
    readonly property real levelPanelHeight: 130
    readonly property real extensionWidth: 48
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool audioAvailable: !!(sink && sink.ready && sink.audio)
    readonly property real volume: audioAvailable ? Math.max(0, Math.min(1, sink.audio.volume)) : 0
    property real brightness: 0
    property bool brightnessAvailable: false
    property int pendingBrightness: -1
    property real brightnessHoldUntil: 0
    property string currentProfile: ""
    property var availableProfiles: []
    property string batteryText: "—"
    property string batteryDetail: ""
    property string powerError: ""
    readonly property bool english: theme && String(theme.language).indexOf("en") === 0
    signal shapeChanged()
    signal panelHoverChanged(bool hovered)

    onVolumeOpenChanged: volumeOpen ? volumePanel.open() : volumePanel.close()
    onBrightnessOpenChanged: { brightnessOpen ? brightnessPanel.open() : brightnessPanel.close(); refreshBrightness() }
    onRefreshSerialChanged: if (brightnessOpen) refreshBrightness()
    onBatteryOpenChanged: { shapeChanged(); refreshPower() }
    onVolumeCenterChanged: shapeChanged()
    onBrightnessCenterChanged: shapeChanged()
    onBatteryCenterChanged: shapeChanged()
    onHeightChanged: shapeChanged()
    onWidthChanged: shapeChanged()

    function alpha(color, opacity) { return Qt.rgba(color.r, color.g, color.b, opacity) }

    function panelY(center, panelHeight) {
        return Math.max(26, Math.min(height - panelHeight - 24, center - panelHeight / 2))
    }

    // Extend the existing sidebar path, so translucent materials are filled once.
    function appendOutline(ctx, edge) {
        const panels = nativePanel && nativePanel.visible ? [nativePanel] : []
        for (const panel of panels) {
            const top = panel.y
            const bottom = top + panel.height
            const reach = panel.width
            const r = Math.min(12, reach / 2)
            ctx.lineTo(edge, top - r)
            ctx.bezierCurveTo(edge, top, edge + r, top, edge + r, top)
            ctx.lineTo(edge + reach - r, top)
            ctx.quadraticCurveTo(edge + reach, top, edge + reach, top + r)
            const tail = panel.extension
            if (tail && tail.width > 0.01) {
                const join = Math.min(8, tail.width / 2)
                const tip = Math.min(10, tail.width / 2)
                const tailTop = Math.max(top + r + join, tail.y)
                const tailBottom = Math.min(bottom - r - join, tail.y + tail.height)
                ctx.lineTo(edge + reach, tailTop - join)
                ctx.quadraticCurveTo(edge + reach, tailTop, edge + reach + join, tailTop)
                ctx.lineTo(edge + reach + tail.width - tip, tailTop)
                ctx.quadraticCurveTo(edge + reach + tail.width, tailTop, edge + reach + tail.width, tailTop + tip)
                ctx.lineTo(edge + reach + tail.width, tailBottom - tip)
                ctx.quadraticCurveTo(edge + reach + tail.width, tailBottom, edge + reach + tail.width - tip, tailBottom)
                ctx.lineTo(edge + reach + join, tailBottom)
                ctx.quadraticCurveTo(edge + reach, tailBottom, edge + reach, tailBottom + join)
            }
            ctx.lineTo(edge + reach, bottom - r)
            ctx.quadraticCurveTo(edge + reach, bottom, edge + reach - r, bottom)
            ctx.lineTo(edge + r, bottom)
            ctx.bezierCurveTo(edge + r, bottom, edge, bottom, edge, bottom + r)
        }
    }

    function refreshBrightness() {
        if (brightnessOpen && !brightnessQuery.running && !brightnessWriter.running && pendingBrightness < 0)
            brightnessQuery.running = true
    }

    function setBrightness(value) {
        brightness = Math.max(0.05, Math.min(1, value))
        brightnessHoldUntil = Date.now() + 800
        pendingBrightness = Math.round(brightness * 100)
        if (!brightnessCommit.running)
            brightnessCommit.start()
    }

    function commitBrightness() {
        if (brightnessWriter.running || pendingBrightness < 0)
            return
        brightnessWriter.command = ["brightnessctl", "set", pendingBrightness + "%"]
        pendingBrightness = -1
        brightnessWriter.running = true
    }

    function refreshPower() {
        if (!batteryOpen)
            return
        if (!powerQuery.running && !profileWriter.running)
            powerQuery.running = true
        if (!profilesQuery.running)
            profilesQuery.running = true
    }

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    Timer {
        interval: 2000
        repeat: true
        running: root.brightnessOpen
        onTriggered: root.refreshBrightness()
    }
    Timer {
        interval: 15000
        repeat: true
        running: root.batteryOpen
        onTriggered: root.refreshPower()
    }
    Timer { id: brightnessCommit; interval: 45; onTriggered: root.commitBrightness() }
    Process {
        id: brightnessQuery
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split(",")
                const value = fields.length > 3 ? Number(fields[3].replace("%", "")) / 100 : NaN
                root.brightnessAvailable = Number.isFinite(value)
                if (root.brightnessAvailable && !brightnessPanel.panelHeld && Date.now() >= root.brightnessHoldUntil)
                    root.brightness = value
            }
        }
    }
    Process {
        id: brightnessWriter
        onExited: (code, status) => {
            if (code !== 0) {
                root.brightnessAvailable = false
                root.brightnessHoldUntil = 0
            }
            if (root.pendingBrightness >= 0)
                brightnessCommit.restart()
            else if (code !== 0)
                root.refreshBrightness()
        }
    }
    Process {
        id: powerQuery
        command: [Quickshell.shellDir + "/scripts/velora-popup-status", "battery", "--force"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    const fields = line.split("|")
                    if (fields[0] === "BATTERY") {
                        root.batteryText = fields[2] !== "unknown" ? Math.round(Number(fields[1]) * 100) + "%" : "—"
                        const charging = String(fields[2]).toLowerCase().indexOf("discharg") < 0
                            && String(fields[2]).toLowerCase().indexOf("charg") >= 0
                        root.batteryDetail = fields[3] || (charging ? (root.english ? "Charging" : "Carregando") : (root.english ? "On battery" : "Na bateria"))
                        if (fields[3]) root.batteryDetail += charging ? (root.english ? " until full" : " até carregar") : (root.english ? " remaining" : " restantes")
                        if (fields[2] === "fully-charged") root.batteryDetail = root.english ? "Fully charged" : "Carga completa"
                        if (fields[2] === "unknown") root.batteryDetail = root.english ? "No battery" : "Sem bateria"
                    } else if (fields[0] === "POWER") {
                        root.currentProfile = fields[1]
                    }
                }
            }
        }
    }
    Process {
        id: profilesQuery
        command: ["powerprofilesctl", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.availableProfiles = ["power-saver", "balanced", "performance"].filter(mode => text.indexOf(mode + ":") >= 0)
        }
    }
    Process {
        id: profileWriter
        onExited: (code, status) => {
            root.powerError = code === 0 ? "" : (root.english ? "Could not change profile" : "Não foi possível alterar o perfil")
            root.refreshPower()
        }
    }

    VeloraRailLevelPopover {
        id: volumePanel
        objectName: "railVolumePopover"
        anchors.fill: parent
        theme: root.theme; motion: root.motion
        rightSide: root.rightSide; railWidth: root.railWidth
        anchorY: root.volumeCenter
        handoffSource: root.handoffSource
        value: root.volume; available: root.audioAvailable
        accent: root.accent; label: "Volume"
        onEdited: value => {
            root.sink.audio.volume = value
            if (value > 0) root.sink.audio.muted = false
        }
        onOpening: root.levelOpening(volumePanel)
        onOpenedChanged: if (!opened) Qt.callLater(function() { if (!volumePanel.opened) root.levelClosed("volume") })
        onShapeChanged: root.shapeChanged()
    }
    VeloraRailLevelPopover {
        id: brightnessPanel
        objectName: "railBrightnessPopover"
        anchors.fill: parent
        theme: root.theme; motion: root.motion
        rightSide: root.rightSide; railWidth: root.railWidth
        anchorY: root.brightnessCenter
        handoffSource: root.handoffSource
        value: root.brightness; minimumValue: .05; available: root.brightnessAvailable
        accent: root.accent; label: root.english ? "Brightness" : "Brilho"
        onEdited: value => root.setBrightness(value)
        onOpening: root.levelOpening(brightnessPanel)
        onOpenedChanged: if (!opened) Qt.callLater(function() { if (!brightnessPanel.opened) root.levelClosed("brightness") })
        onShapeChanged: root.shapeChanged()
    }

    Item {
        id: batteryPanel
        x: root.rightSide ? root.width - root.railWidth - width : root.railWidth
        y: root.panelY(root.batteryCenter + 10, height)
        width: root.batteryOpen ? Math.min(420, root.width - root.railWidth - 24) : 0
        height: 76
        visible: root.batteryOpen

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8
            Column {
                Layout.preferredWidth: 118
                spacing: 1
                Text {
                    text: root.batteryText
                    color: root.accent
                    font.family: root.theme ? root.theme.uiFont : "sans-serif"
                    font.pixelSize: 27
                    font.weight: Font.DemiBold
                }
                Text {
                    width: parent.width
                    text: root.powerError || root.batteryDetail
                    color: root.alpha(root.accent, 0.65)
                    font.family: root.theme ? root.theme.uiFont : "sans-serif"
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }
            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: root.alpha(root.accent, 0.15) }
            Repeater {
                model: [
                    { mode: "power-saver", label: root.english ? "Saver" : "Economia" },
                    { mode: "balanced", label: root.english ? "Balanced" : "Equilibrado" },
                    { mode: "performance", label: root.english ? "Performance" : "Desempenho" }
                ]
                Rectangle {
                    id: modeCard
                    required property var modelData
                    readonly property bool selected: root.currentProfile === modelData.mode
                    readonly property bool available: root.availableProfiles.indexOf(modelData.mode) >= 0 && !profileWriter.running
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 10
                    color: root.alpha(root.accent, selected ? 0.09 : (modeMouse.containsMouse ? 0.06 : 0.015))
                    border.width: selected ? 1.4 : 1
                    border.color: root.alpha(root.accent, selected ? 0.95 : 0.13)
                    opacity: available ? 1 : 0.45
                    Accessible.role: Accessible.Button
                    Accessible.name: modelData.label
                    Accessible.onPressAction: apply()
                    function apply() {
                        if (!available) return
                        root.powerError = ""
                        profileWriter.command = ["powerprofilesctl", "set", modelData.mode]
                        profileWriter.running = true
                    }
                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 6
                        text: modeCard.modelData.label
                        color: root.alpha(root.accent, modeCard.selected ? 1 : 0.7)
                        font.family: root.theme ? root.theme.uiFont : "sans-serif"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                    }
                    MouseArea {
                        id: modeMouse
                        anchors.fill: parent
                        enabled: modeCard.available
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modeCard.apply()
                    }
                }
            }
        }
    }
}
