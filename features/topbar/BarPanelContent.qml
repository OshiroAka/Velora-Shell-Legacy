import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.UPower
import "../../components" as Components

Loader {
    id: root
    required property string type
    required property var theme
    required property var systemStatus
    required property var system
    required property var fanPlus
    required property var timerService
    required property var clock
    required property var calendar
    required property var media
    required property var weather
    required property var controller
    required property var actions
    readonly property bool interactionHeld: item ? item.interactionHeld === true : false
    sourceComponent: ({ battery: batteryPanel, clock: clockPanel, calendar: clockPanel, timer: timerPanel,
        monitor: monitorPanel, paint: paintPanel, wifi: wifiPanel, caffeine: toolsPanel, cat: toolsPanel, usb: toolsPanel,
        thing: toolsPanel, notes: toolsPanel, search: toolsPanel, controls: toolsPanel })[type] || null

    Component {
        id: monitorPanel
        Components.VeloraMonitorSettings {
            reducedMotion: !!root.theme.config && root.theme.config.reducedMotion
            ink: root.theme.textPrimary
            uiFont: root.theme.bodyFont
            surfaceColor: root.theme.wallpaperSurfaceTone
        }
    }
    Component {
        id: paintPanel
        RowLayout {
            spacing: 8
            Repeater {
                model: [root.theme.wallpaperSurfaceTone, root.theme.accent, root.theme.accentAlt, root.theme.textPrimary]
                Rectangle {
                    required property color modelData
                    Layout.preferredWidth: 24; Layout.preferredHeight: 30
                    radius: 8; color: modelData
                    border.width: 1; border.color: root.theme.borderStrong
                    Behavior on color { ColorAnimation { duration: 420 } }
                }
            }
            Button {
                id: shuffleButton
                Layout.preferredWidth: 34; Layout.preferredHeight: 34
                enabled: !!root.system.palette && !root.system.palette.generating
                hoverEnabled: true
                Accessible.name: "Misturar cores"
                onClicked: root.system.palette.shuffle()
                background: Rectangle {
                    radius: 10
                    color: root.theme.withAlpha(root.theme.textPrimary, shuffleButton.down ? .22 : shuffleButton.hovered ? .15 : .08)
                    border.width: shuffleButton.activeFocus ? 1 : 0
                    border.color: root.theme.textSecondary
                }
                contentItem: BarIcon {
                    name: "paint"; color: root.theme.textPrimary
                    opacity: shuffleButton.enabled ? 1 : .45
                    SequentialAnimation on rotation {
                        running: !!root.system.palette && root.system.palette.generating
                        loops: Animation.Infinite
                        NumberAnimation { to: -18; duration: 240; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 18; duration: 240; easing.type: Easing.InOutSine }
                        onStopped: shuffleButton.contentItem.rotation = 0
                    }
                }
                ToolTip.visible: hovered && !!root.system.palette && root.system.palette.error.length > 0
                ToolTip.text: root.system.palette ? root.system.palette.error : ""
            }
        }
    }
    function time(seconds) {
        if (!(seconds > 0)) return ""
        const minutes = Math.ceil(seconds / 60)
        return minutes >= 60 ? Math.floor(minutes / 60) + " h " + minutes % 60 + " min" : minutes + " min"
    }
    function trackTime(seconds) {
        return Math.floor(Math.max(0, seconds) / 60) + ":" + String(Math.floor(Math.max(0, seconds)) % 60).padStart(2, "0")
    }
    component Label: Text {
        color: root.theme.textPrimary
        font.family: root.theme.bodyFont
        font.pixelSize: 12
        elide: Text.ElideRight
    }
    component Detail: Label {
        color: root.theme.textSecondary
        font.pixelSize: 11
        wrapMode: Text.WordWrap
    }
    component Heading: Label { font.pixelSize: 16; font.weight: Font.DemiBold }
    component Rule: Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: root.theme.borderSubtle }
    component Fact: RowLayout {
        property string label: ""
        property string value: ""
        Layout.fillWidth: true
        Detail { text: parent.label; Layout.fillWidth: true }
        Label { text: parent.value || "Indisponível"; Layout.maximumWidth: 200; font.pixelSize: 11 }
    }
    component ErrorText: Detail {
        Layout.fillWidth: true
        color: root.theme.warning
        text: root.system.error
        visible: text.length > 0
        maximumLineCount: 3
    }
    Component {
        id: batteryPanel
        ColumnLayout {
            spacing: 10
            RowLayout {
                Layout.fillWidth: true
                BatteryIndicator { available: root.systemStatus.hasBattery; level: root.systemStatus.batteryLevel; charging: root.systemStatus.batteryCharging; color: root.theme.accentSoft }
                Heading { Layout.fillWidth: true; text: root.systemStatus.hasBattery ? root.systemStatus.batteryPercent + "%" : "Sem bateria" }
                Detail {
                    text: !root.systemStatus.hasBattery ? "" : root.systemStatus.batteryCharging ? "Carregando"
                        : root.systemStatus.battery.state === UPowerDeviceState.FullyCharged ? "Carga completa"
                        : root.systemStatus.battery.state === UPowerDeviceState.Discharging ? "Na bateria" : "Conectada à energia"
                }
            }
            Fact {
                label: root.systemStatus.batteryCharging ? "Até carregar" : "Tempo restante"
                value: root.systemStatus.hasBattery ? root.time(root.systemStatus.batteryCharging ? root.systemStatus.battery.timeToFull : root.systemStatus.battery.timeToEmpty) : ""
            }
            Fact {
                label: "Saúde da bateria"
                value: root.systemStatus.hasBattery && root.systemStatus.battery.healthSupported ? Math.round(root.systemStatus.battery.healthPercentage) + "%" : ""
            }
            Rule {}
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: [
                        { key: "power-saver", label: "Economia", detail: "Prioriza a duração da bateria" },
                        { key: "balanced", label: "Equilibrado", detail: "Equilibra autonomia e velocidade" },
                        { key: "performance", label: "Desempenho", detail: "Prioriza a velocidade; consome mais energia" }
                    ]
                    Components.VeloraSystemChoice {
                        required property var modelData
                        objectName: "energyChoice-" + modelData.key
                        Layout.fillWidth: true
                        Layout.preferredHeight: 92
                        reducedMotion: !!root.theme.config && root.theme.config.reducedMotion
                        choice: modelData.key
                        text: modelData.label
                        explanation: modelData.detail
                        ink: root.theme.textPrimary
                        accent: root.theme.textPrimary
                        uiFont: root.theme.bodyFont
                        enabled: root.system.power.available && !root.system.powerBusy && root.system.power.profiles.indexOf(modelData.key) >= 0
                        selected: root.system.power.current === modelData.key
                        onClicked: root.system.setProfile(modelData.key)
                    }
                }
            }
            Detail { Layout.fillWidth: true; visible: !root.system.power.available; text: "Perfis de energia indisponíveis neste sistema." }
            Rule {}
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Label { text: "Fan+"; font.weight: Font.DemiBold }
                    Detail {
                        text: root.fanPlus.state === "unsupported" ? (root.fanPlus.error || "Indisponível neste dispositivo")
                            : root.fanPlus.state === "starting" ? "Ativando resfriamento…"
                            : root.fanPlus.state === "stopping" ? "Retornando ao controle automático…"
                            : root.fanPlus.state === "error" ? "Não foi possível controlar a ventoinha"
                            : "Resfriamento máximo"
                    }
                }
                Switch {
                    id: fanSwitch
                    implicitWidth: 40; implicitHeight: 36
                    Accessible.name: "Fan+ · Resfriamento máximo"
                    checked: root.fanPlus.enabled || (root.fanPlus.state === "error" && root.fanPlus.lastConfirmedActive)
                    enabled: root.fanPlus.supported && !root.fanPlus.busy
                    onToggled: root.fanPlus.toggle()
                    indicator: Rectangle {
                        x: 2; y: 8; width: 36; height: 20; radius: 10
                        color: root.theme.withAlpha(root.theme.textPrimary, fanSwitch.checked ? .4 : .18)
                        border.width: fanSwitch.activeFocus ? 1 : 0
                        border.color: root.theme.textPrimary
                        opacity: fanSwitch.enabled ? 1 : .4
                        Rectangle {
                            x: fanSwitch.checked ? 19 : 3; y: 3
                            width: 14; height: 14; radius: 7
                            color: root.theme.textPrimary
                        }
                    }
                }
            }
            Detail { Layout.fillWidth: true; visible: root.fanPlus.state === "error"; text: root.fanPlus.error; color: root.theme.warning }
            Item { Layout.fillHeight: true }
        }
    }
    Component {
        id: clockPanel
        ClockPanel { theme: root.theme; clock: root.clock; timerService: root.timerService; calendar: root.calendar; page: "calendar" }
    }
    Component {
        id: wifiPanel
        ColumnLayout {
            spacing: 10
            RowLayout {
                Layout.fillWidth: true
                Heading { text: "Internet"; Layout.fillWidth: true }
                BarAction { theme: root.theme; text: root.systemStatus.wifiEnabled ? "Wi-Fi ligado" : "Wi-Fi desligado"; highlighted: root.systemStatus.wifiEnabled; onClicked: root.systemStatus.toggleWifi() }
            }
            Heading { Layout.fillWidth: true; text: root.system.networkChanging ? "Conectando…" : root.system.network.connection || (root.systemStatus.wifiConnected ? root.systemStatus.wifiName : "Desconectado"); font.pixelSize: 14 }
            Fact { label: "Interface"; value: root.system.network.interface || "" }
            Fact { label: "IP local"; value: (root.system.network.addresses || []).join(", ") }
            Fact { label: "Sinal Wi-Fi"; value: root.systemStatus.wifiConnected ? Math.round(root.system.wifiStrength * 100) + "%" : "" }
            Fact { label: "VPN"; value: (root.system.network.vpn || []).join(", ") || "Nenhuma ativa" }
            Rule {}
            RowLayout {
                Layout.fillWidth: true
                Label { Layout.fillWidth: true; text: root.system.download >= 0 ? "↓ " + (root.system.download / 1024).toFixed(1) + " KiB/s" : "↓ —" }
                Label { text: root.system.upload >= 0 ? "↑ " + (root.system.upload / 1024).toFixed(1) + " KiB/s" : "↑ —" }
            }
            BarAction { Layout.fillWidth: true; theme: root.theme; text: "Gerenciar conexões…"; enabled: root.system.capabilities.networkEditor === true; onClicked: root.system.runAction("network-editor") }
            ErrorText {}
            Item { Layout.fillHeight: true }
        }
    }
    Component {
        id: toolsPanel
        MicroToolsPanel {
            type: root.type; theme: root.theme; system: root.system
            controller: root.controller; actions: root.actions
        }
    }
    Component {
        id: timerPanel
        TimerPanel { theme: root.theme; timerService: root.timerService; presented: root.active }
    }
}
