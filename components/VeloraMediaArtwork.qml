pragma ComponentBehavior: Bound
import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property string source: ""
    property color accent: "#baa2d8"
    property color ink: "#f6f2ff"
    property real radius: 22
    property bool animated: true
    property bool selected: false
    readonly property bool ready: cover.status === Image.Ready
    clip: true
    Rectangle {
        anchors.fill: parent; radius: root.radius
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.30) }
            GradientStop { position: 1; color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.035) }
        }
        // A quiet record motif gives empty/failed artwork an intentional state.
        Rectangle {
            anchors.centerIn: parent; width: parent.width * 0.67; height: width; radius: width / 2
            color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.035)
            border.color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.12)
            Rectangle {
                anchors.centerIn: parent; width: parent.width * 0.72; height: width; radius: width / 2
                color: "transparent"; border.color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.08)
            }
            VeloraMaterialIcon { anchors.centerIn: parent; width: Math.max(16, parent.width * .24); height: width; iconName: "music"; iconColor: root.accent }
        }
    }
    Image {
        id: cover
        anchors.fill: parent
        source: root.source.startsWith("spotify:image:") ? "https://i.scdn.co/image/" + root.source.substring(14) : root.source
        sourceSize: Qt.size(Math.min(640, Math.ceil(root.width * 2)), Math.min(640, Math.ceil(root.width * 2)))
        asynchronous: true; fillMode: Image.PreserveAspectCrop
        opacity: status === Image.Ready ? 1 : 0
        scale: root.selected ? 1.035 : 1
        Behavior on opacity { NumberAnimation { duration: root.animated ? 220 : 0 } }
        Behavior on scale { NumberAnimation { duration: root.animated ? 240 : 0; easing.type: Easing.OutCubic } }
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle { width: root.width; height: root.height; radius: root.radius; color: "white" }
        }
    }
    Rectangle {
        anchors.fill: parent; radius: root.radius; color: "transparent"
        border.color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.13)
    }
}
