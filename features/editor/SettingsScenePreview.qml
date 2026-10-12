import QtQuick
import QtQuick.Effects

Item {
    id: root
    required property var theme
    property url imageSource: ""
    property real blur: 0
    property real dimming: 0
    clip: true
    Item {
        id: scenery; anchors.fill: parent
        visible: !effect.visible
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.darker(root.theme.accentSoft, 1.5) }
                GradientStop { position: 1; color: root.theme.moduleSurface }
            }
            Rectangle { x: parent.width*.68; y: parent.height*.16; width: parent.height*.23; height: width; radius: width/2; color: root.theme.accentSoft; opacity: .7 }
            Repeater { model: 3
                Rectangle {
                    required property int index
                    x: parent.width*(index*.42-.12); y: parent.height*(.72-index*.09)
                    width: parent.width*.68; height: parent.height; radius: 30
                    rotation: -32+index*12; color: index === 1 ? root.theme.accent : root.theme.moduleSurface
                    opacity: .8
                }
            }
        }
        Image {
            anchors.fill: parent; source: root.imageSource
            sourceSize.width: 700; asynchronous: true; fillMode: Image.PreserveAspectCrop
        }
    }
    MultiEffect {
        id: effect; anchors.fill: parent; source: scenery
        visible: root.blur > 0 && root.visible && GraphicsInfo.api !== GraphicsInfo.Software
        blurEnabled: visible; blurMax: 48; blur: root.blur
        autoPaddingEnabled: false
    }
    Rectangle { anchors.fill: parent; color: "black"; opacity: root.dimming }
}
