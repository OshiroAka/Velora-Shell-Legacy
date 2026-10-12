pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root
    property bool opened: true
    property bool reducedMotion: false
    property color surfaceColor: "#24242d"
    readonly property bool interactionHeld: awaitingConfirmation || outputs.popup.visible || modeSelect.popup.visible
    property color ink: "white"
    property string uiFont: "sans-serif"
    property var monitors: []
    property int monitorIndex: 0
    property string selectedMode: ""
    property real selectedScale: 1
    property string layoutMode: "extend"
    property string error: ""
    property string pendingToken: ""
    readonly property bool awaitingConfirmation: pendingToken.length > 0
    readonly property string helper: Quickshell.shellDir + "/scripts/velora-monitor-control"
    readonly property var monitor: monitors.length > monitorIndex ? monitors[monitorIndex] : null
    readonly property var modes: monitor && monitor.availableModes
        ? monitor.availableModes.filter((value, index, values) => values.indexOf(value) === index) : []
    readonly property bool busy: query.running || writer.running || actionProcess.running
    onOpenedChanged: {
        if (opened) refresh()
        else if (awaitingConfirmation) revert()
    }
    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function refresh() { if (!query.running && !writer.running) query.running = true }
    function select(index) {
        monitorIndex = index
        const item = monitor
        if (!item) return
        const current = item.width + "x" + item.height + "@" + Number(item.refreshRate).toFixed(2)
        selectedMode = modes.find(m => modeSpec(m) === current) || modes[0] || ""
        selectedScale = Number(item.scale) || 1
    }
    function modeSpec(mode) { return String(mode).replace(/Hz$/i, "") }
    function apply() {
        if (!monitor || busy || awaitingConfirmation) return
        const mode = modeSpec(selectedMode)
        if (modes.indexOf(selectedMode) < 0 || !/^\d+x\d+@\d+(\.\d+)?$/.test(mode)) { error = "Modo indisponível"; return }
        const scale = Number(selectedScale)
        if (!Number.isFinite(scale) || scale < 0.5 || scale > 3) { error = "Escala inválida"; return }
        error = ""
        writer.command = [helper, "apply", layoutMode, monitor.name, mode, scale.toFixed(2)]
        writer.running = true
    }
    function confirm() {
        if (!awaitingConfirmation || actionProcess.running) return
        actionProcess.command = [helper, "confirm", pendingToken]
        pendingToken = ""
        rollback.stop()
        actionProcess.running = true
    }
    function revert() {
        if (!awaitingConfirmation || actionProcess.running) return
        actionProcess.command = [helper, "revert", pendingToken]
        pendingToken = ""
        rollback.stop()
        actionProcess.running = true
    }
    Timer { id: rollback; interval: 12000; onTriggered: root.revert() }
    Process {
        id: query
        command: [root.helper, "probe"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const oldName = root.monitor ? root.monitor.name : ""
                    root.monitors = JSON.parse(text).filter(m => m && m.name)
                    const index = root.monitors.findIndex(m => m.name === oldName)
                    root.select(index >= 0 ? index : 0)
                    root.error = ""
                } catch (e) { root.error = "Não foi possível consultar os monitores" }
            }
        }
    }
    Process {
        id: writer
        stdout: StdioCollector { id: result }
        onExited: code => {
            if (code !== 0 || !/^monitor-[0-9a-f]{16}\.json$/.test(result.text.trim())) {
                root.error = "Não foi possível aplicar o modo"
            } else {
                root.pendingToken = result.text.trim()
                rollback.restart()
            }
        }
    }
    Process {
        id: actionProcess
        onExited: code => {
            if (code !== 0) root.error = "Não foi possível confirmar ou restaurar. Aguarde a reversão automática."
            else root.refresh()
        }
    }
    Column {
                anchors.margins: 0
                anchors.fill: parent
                spacing: 9
                Text { text: "Monitores"; color: root.ink; font.family: root.uiFont; font.pixelSize: 17; font.weight: Font.DemiBold }
                Row {
                    width: parent.width
                    spacing: 6
                    Repeater {
                        model: [
                            { key: "extend", label: "Estender", detail: "Um espaço de trabalho distribuído entre as telas" },
                            { key: "mirror", label: "Espelhar", detail: "O mesmo conteúdo nas duas telas" },
                            { key: "main", label: "Só este", detail: "Usa apenas o monitor selecionado abaixo" }
                        ]
                        VeloraSystemChoice {
                            required property var modelData
                            objectName: "monitorChoice-" + modelData.key
                            width: (root.width - 12) / 3
                            monitorChoice: true
                            reducedMotion: root.reducedMotion
                            choice: modelData.key
                            text: modelData.label
                            explanation: modelData.detail
                            ink: root.ink
                            uiFont: root.uiFont
                            selected: root.layoutMode === modelData.key
                            enabled: modelData.key === "extend" || root.monitors.length > 1
                            onClicked: root.layoutMode = modelData.key
                        }
                    }
                }
                MonitorSelect {
                    id: outputs
                    objectName: "monitorOutput"
                    width: parent.width; height: 36
                    model: root.monitors.map(m => m.name + (m.description ? " · " + m.description : ""))
                    currentIndex: root.monitorIndex
                    onActivated: index => root.select(index)
                }
                Text { text: "Resolução e frequência"; color: root.ink; font.family: root.uiFont; font.pixelSize: 11 }
                MonitorSelect {
                    id: modeSelect
                    objectName: "monitorMode"
                    width: parent.width; height: 36
                    model: root.modes
                    currentIndex: root.modes.indexOf(root.selectedMode)
                    onActivated: index => root.selectedMode = root.modes[index]
                }
                Text { text: "Escala · " + Math.round(root.selectedScale * 100) + "%"; color: root.ink; font.family: root.uiFont; font.pixelSize: 11 }
                VeloraMotionSlider {
                    id: scaleControl
                    objectName: "monitorScale"
                    width: parent.width; height: 30
                    Accessible.name: "Escala do monitor"
                    from: 0.5; to: 3; stepSize: 0.05
                    value: root.selectedScale
                    onMoved: root.selectedScale = Math.round(value * 20) / 20
                    ink: root.ink
                    accent: root.alpha(root.ink, .65)
                    reducedMotion: root.reducedMotion
                }
                Text {
                    width: parent.width
                    text: root.error || (root.awaitingConfirmation ? "Confirme em 12 segundos ou a tela será restaurada." : "As mudanças são aplicadas à sessão atual.")
                    color: root.ink; opacity: root.error ? 1 : 0.7
                    font.family: root.uiFont; font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
                Row {
                    spacing: 8
                    MonitorButton { text: root.awaitingConfirmation ? "Manter" : "Aplicar"; enabled: !!root.monitor && !root.busy; onClicked: if (root.awaitingConfirmation) root.confirm(); else root.apply() }
                    MonitorButton { text: root.awaitingConfirmation ? "Restaurar" : "Detectar"; enabled: !root.busy; onClicked: if (root.awaitingConfirmation) root.revert(); else root.refresh() }
                }
    }
    Component.onCompleted: refresh()
    Component.onDestruction: revert()
    component MonitorButton: Button {
        id: button
        property bool selected: false
        width: 100; height: 31
        background: Rectangle { radius: 9; color: root.alpha(root.ink, button.selected ? 0.23 : button.hovered ? 0.18 : 0.08); border.width: 1; border.color: root.alpha(root.ink, button.selected ? 0.5 : 0.2) }
        contentItem: Text { text: button.text; color: root.ink; opacity: button.enabled ? 1 : 0.45; font.family: root.uiFont; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
    }
    component MonitorSelect: ComboBox {
        id: select
        font.family: root.uiFont
        font.pixelSize: 11
        background: Rectangle {
            radius: 9
            color: root.alpha(root.ink, select.pressed ? 0.19 : select.hovered ? 0.14 : 0.08)
            border.width: 1
            border.color: root.alpha(root.ink, select.activeFocus ? 0.5 : 0.2)
        }
        contentItem: Text {
            leftPadding: 11; rightPadding: 24
            text: select.displayText
            color: root.ink
            font: select.font
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        indicator: Text {
            x: select.width - width - 10
            anchors.verticalCenter: parent.verticalCenter
            text: "⌄"
            color: root.ink
            font.pixelSize: 14
        }
        delegate: ItemDelegate {
            id: option
            required property int index
            required property var modelData
            width: select.width - 8; height: 32
            text: String(modelData)
            font.family: root.uiFont; font.pixelSize: 11
            highlighted: select.highlightedIndex === index
            background: Rectangle {
                radius: 7
                color: root.alpha(root.ink, option.highlighted || option.hovered ? 0.18 : 0.04)
            }
            contentItem: Text {
                text: option.text
                color: root.ink
                font: option.font
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                leftPadding: 8
            }
        }
        popup: Popup {
            y: select.height + 3
            width: select.width
            implicitHeight: Math.min(168, select.count * 32 + 8)
            padding: 4
            background: Rectangle {
                radius: 10
                color: root.surfaceColor
                border.width: 1
                border.color: root.alpha(root.ink, 0.26)
            }
            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: select.popup.visible ? select.delegateModel : null
                currentIndex: select.highlightedIndex
                boundsBehavior: Flickable.StopAtBounds
            }
        }
    }
}
