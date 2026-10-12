import QtQuick
import QtQuick.Controls
import "../core" as Core

Item {
    id: root
    required property var theme
    property var motion: fallbackMotion
    property string label: ""
    property string hint: ""
    property bool checked: false
    signal triggered()
    Core.Motion { id: fallbackMotion; config: root.theme ? root.theme.config : null }
    implicitWidth: label.length ? caption.implicitWidth + 58 : 42
    implicitHeight: 36
    width: implicitWidth
    opacity: enabled ? 1 : .45
    activeFocusOnTab: enabled
    Accessible.role: Accessible.CheckBox
    Accessible.name: label
    Accessible.description: hint
    Accessible.checkable: true
    Accessible.checked: checked
    Accessible.onPressAction: if (enabled) triggered()
    Keys.onSpacePressed: triggered()
    Keys.onReturnPressed: triggered()
    Text {
        id: caption
        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, parent.width - 58)
        text: root.label; visible: width > 0
        color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 12
        elide: Text.ElideRight
    }
    Rectangle {
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        width: 36; height: 20; radius: 10
        color: root.checked ? root.theme.accent : root.theme.borderStrong
        Rectangle {
            x: root.checked ? 19 : 3; y: 3; width: 14; height: 14; radius: 7
            color: root.checked ? root.theme.inverseInk : root.theme.textPrimary
            Behavior on x { NumberAnimation { duration: root.motion ? root.motion.surfaceHover : 0; easing.type: Easing.OutCubic } }
        }
    }
    Rectangle {
        anchors.fill: parent; anchors.margins: -2; radius: 9; color: "transparent"
        border.width: root.activeFocus ? 1 : 0; border.color: root.theme.accent
    }
    MouseArea {
        id: pointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }
    ToolTip.visible: pointer.containsMouse && hint.length > 0
    ToolTip.delay: 600
    ToolTip.text: hint
}
