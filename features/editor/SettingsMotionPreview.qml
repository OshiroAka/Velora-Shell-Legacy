import QtQuick
import "../../components" as Components

Rectangle {
    id: root
    required property var theme
    required property var motion
    property real expansion: 1
    property real contents: 1
    readonly property bool animating: sequence.running
    implicitHeight: 204
    radius: 16; color: Qt.rgba(0,0,0,.10); border.color: theme.borderSubtle
    function replay() {
        sequence.stop()
        if (!visible || motion.reduced) { expansion=1; contents=1; return }
        sequence.restart()
    }
    onVisibleChanged: { if (!visible) { sequence.stop(); expansion=1; contents=1 } }
    Component.onCompleted: Qt.callLater(replay)
    Connections { target: root.motion; function onReducedChanged() { root.replay() } }
    SequentialAnimation {
        id: sequence
        ScriptAction { script: { root.expansion=0; root.contents=0 } }
        PauseAnimation { duration: 180 }
        NumberAnimation { target: root; property: "expansion"; to: 1; duration: root.motion.geometryDuration; easing.type: root.motion.easeGeometry }
        NumberAnimation { target: root; property: "contents"; to: 1; duration: root.motion.contentDuration; easing.type: root.motion.easeContent }
    }
    Item {
        x: 24; y: 16; width: parent.width-48; height: 132
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 8; radius: 4; color: root.theme.accent; opacity: .3 }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom
            width: 60+Math.min(240,parent.width-60)*root.expansion; height: 8+106*root.expansion
            radius: 14*root.expansion
            color: Qt.rgba(root.theme.accent.r,root.theme.accent.g,root.theme.accent.b,.23)
            border.color: root.theme.borderStrong
            Item {
                anchors.fill: parent; anchors.margins: 15; opacity: root.contents
                Rectangle { width: 62; height: 6; radius: 3; color: root.theme.accentSoft }
                Row { y: 21; spacing: 9
                    Repeater { model: 3
                        Rectangle { width: 48; height: 38; radius: 8; color: Qt.rgba(1,1,1,.09)
                            Rectangle { anchors.centerIn: parent; width: 22; height: 4; radius: 2; color: root.theme.accentSoft; opacity: .55 }
                        }
                    }
                }
            }
        }
    }
    Row { x: 20; y: 163; spacing: 16
        Repeater { model: ["Superfície", "Conteúdo", "Repouso"]
            Text { required property string modelData; required property int index; text: (index+1)+"  "+modelData
                color: (root.expansion < 1 ? index === 0 : root.contents < 1 ? index === 1 : index === 2) ? root.theme.textPrimary : root.theme.textSecondary
                font.family: root.theme.bodyFont; font.pixelSize: 10 }
        }
    }
    Components.VeloraSettingsLink {
        anchors.right: parent.right; anchors.rightMargin: 20; y: 154
        theme: root.theme; label: root.motion.reduced ? "Prévia estática" : "Repetir ↻"
        enabled: !root.motion.reduced
        onTriggered: root.replay()
    }
}
