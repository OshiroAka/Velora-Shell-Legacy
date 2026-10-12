import QtQuick
import QtQuick.Controls

Item {
    id: root
    required property var theme
    property string label: ""
    property string hint: ""
    signal triggered()
    implicitWidth: caption.implicitWidth + 4
    implicitHeight: 32
    activeFocusOnTab: enabled
    opacity: enabled ? 1 : .45
    Accessible.role: Accessible.Link
    Accessible.name: label
    Accessible.description: hint
    Accessible.onPressAction: if (enabled) triggered()
    Keys.onSpacePressed: triggered()
    Keys.onReturnPressed: triggered()
    Text {
        id: caption; anchors.verticalCenter: parent.verticalCenter
        text: root.label; color: pointer.containsMouse || root.activeFocus ? root.theme.textPrimary : root.theme.textSecondary
        font.family: root.theme.bodyFont; font.pixelSize: 11
        font.underline: pointer.containsMouse || root.activeFocus
    }
    MouseArea { id: pointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.triggered() }
    ToolTip.visible: pointer.containsMouse && hint.length > 0
    ToolTip.delay: 600
    ToolTip.text: hint
}
