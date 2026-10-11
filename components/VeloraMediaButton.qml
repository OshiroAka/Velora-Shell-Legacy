import QtQuick
import QtQuick.Controls

AbstractButton {
    id: root
    property string iconName: "play"
    property color ink: "white"
    property color accent: "#baa2d8"
    property bool primary: false
    property bool highlighted: false
    property bool animated: true
    property real cornerRadius: primary ? width / 2 : 9
    property string hint: ""
    implicitWidth: primary ? 62 : 40
    implicitHeight: implicitWidth
    hoverEnabled: true
    Accessible.name: hint
    ToolTip.visible: hovered && hint.length > 0
    ToolTip.text: hint
    ToolTip.delay: 700
    background: Rectangle {
        radius: root.cornerRadius
        color: root.primary ? root.accent : Qt.rgba(root.ink.r, root.ink.g, root.ink.b, root.down ? 0.15 : root.hovered ? 0.10 : root.highlighted ? 0.06 : 0)
        border.color: root.primary ? "transparent" : Qt.rgba(root.ink.r, root.ink.g, root.ink.b, root.activeFocus ? .5 : 0)
        scale: root.down ? 0.91 : root.hovered ? 1.065 : 1
        opacity: root.enabled ? 1 : 0.3
        Behavior on scale { NumberAnimation { duration: root.animated ? 150 : 0; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: root.animated ? 130 : 0 } }
    }
    contentItem: Item {
        VeloraMaterialIcon {
            anchors.centerIn: parent
            width: Math.min(root.primary ? 30 : 23, root.width * .58); height: width
            iconName: root.iconName
            iconColor: root.primary ? (root.accent.r * .299 + root.accent.g * .587 + root.accent.b * .114 > .55 ? "#171820" : "#ffffff") : root.highlighted ? root.accent : root.ink
            opacity: root.enabled ? 1 : 0.25
            filled: root.primary
            scale: root.down ? 0.92 : 1
            Behavior on scale { NumberAnimation { duration: root.animated ? 140 : 0 } }
        }
    }
}
