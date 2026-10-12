import QtQuick
import QtQuick.Controls

Item {
    id: root
    required property var theme
    property bool reducedMotion: !!theme && !!theme.config && theme.config.reducedMotion
    property string label: ""
    property string hint: ""
    property real value: 0
    property real minimum: 0
    property real maximum: 1
    property string valueText: Math.round(control.value * 100) + "%"
    readonly property bool stacked: width < 540
    readonly property real trackWidth: Math.min(232, width - 62)
    property alias controlItem: control
    signal edited(real value)
    signal finalized(real value)
    implicitHeight: stacked ? (hint.length ? 86 : 68) : 66
    width: parent ? Math.min(560, parent.width) : 500
    opacity: enabled ? 1 : 0.45
    Column {
        y: root.stacked ? 4 : (parent.height-height)/2
        width: root.stacked ? parent.width : Math.max(80, parent.width-root.trackWidth-90)
        spacing: 4
        Text { width: parent.width; text: root.label; color: root.theme.textPrimary
            font.family: root.theme.bodyFont; font.pixelSize: 12; wrapMode: Text.WordWrap }
        Text { width: parent.width; visible: text.length > 0; text: root.hint; color: root.theme.textSecondary
            font.family: root.theme.bodyFont; font.pixelSize: 10; wrapMode: Text.WordWrap }
    }
    Row {
        anchors.right: parent.right
        y: root.stacked ? parent.height-34 : (parent.height-height)/2
        height: 32; spacing: 12
        VeloraMotionSlider {
            id: control
            objectName: "settingsSlider"
            width: root.trackWidth; implicitHeight: 32
            from: root.minimum; to: root.maximum; value: root.value
            Accessible.name: root.label
            onMoved: { root.edited(value); if (!pressed) root.finalized(value) }
            onPressedChanged: if (!pressed) root.finalized(value)
            ink: root.theme.textPrimary
            accent: root.theme.accent
            reducedMotion: root.reducedMotion
        }
        Rectangle {
            width: 50; height: 28; y: 2; radius: 8
            color: Qt.rgba(1,1,1,.045)
            Text { anchors.centerIn: parent; text: root.valueText; color: root.theme.textSecondary
                font.family: root.theme.bodyFont; font.pixelSize: 10 }
        }
    }
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.theme.borderSubtle; opacity: .45 }
}
