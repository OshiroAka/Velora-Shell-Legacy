import QtQuick
import QtQuick.Controls

Slider {
    id: root
    property color ink: "white"
    property color accent: ink
    property bool reducedMotion: false
    property real handleSize: 14
    readonly property real overflow: pressed && pointer.active
        ? pointer.point.position.x < leftPadding ? pointer.point.position.x - leftPadding
        : pointer.point.position.x > width - rightPadding ? pointer.point.position.x - width + rightPadding : 0 : 0
    property real overdrag: reducedMotion || !visible ? 0 : 8 * overflow / (Math.abs(overflow) + 48)
    property real displayPosition: visualPosition
    implicitHeight: 32
    hoverEnabled: true
    Behavior on overdrag {
        enabled: !root.pressed && !root.reducedMotion && root.visible
        NumberAnimation { duration: 210; easing.type: Easing.OutCubic }
    }
    Behavior on displayPosition {
        enabled: !root.pressed && !root.reducedMotion && root.visible
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }
    PointHandler { id: pointer; target: null; acceptedButtons: Qt.LeftButton }
    background: Item {
        x: root.leftPadding; y: (root.height - height) / 2
        width: root.availableWidth; height: 4
        Rectangle {
            x: Math.min(0, root.overdrag)
            width: parent.width + Math.abs(root.overdrag); height: parent.height; radius: 2
            color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, .18)
            Rectangle {
                width: Math.max(0, Math.min(parent.width, root.displayPosition * root.availableWidth + Math.max(0, root.overdrag)))
                height: parent.height; radius: 2; color: root.accent
            }
        }
    }
    handle: Item {
        x: root.leftPadding + root.displayPosition * (root.availableWidth - width) + root.overdrag
        y: (root.height - height) / 2
        width: root.handleSize; height: width
        Rectangle {
            anchors.centerIn: parent; width: 28; height: 28; radius: 14
            color: root.ink
            opacity: root.pressed ? .12 : root.hovered || root.activeFocus ? .065 : 0
            Behavior on opacity { NumberAnimation { duration: root.reducedMotion ? 0 : 140 } }
        }
        Rectangle {
            anchors.centerIn: parent
            width: root.handleSize + (root.pressed ? 3 : 0); height: width; radius: width / 2
            color: root.ink
            border.width: root.activeFocus ? 2 : 0; border.color: root.accent
            Behavior on width { NumberAnimation { duration: root.reducedMotion ? 0 : 160; easing.type: Easing.OutCubic } }
        }
    }
}
