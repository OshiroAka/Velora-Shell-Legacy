import QtQuick

Rectangle {
    id: root
    required property var theme
    required property var motion
    property string mode: "fade"
    property real duration: 1
    property real progress: 0
    property int randomStep: 0
    readonly property int effectIndex: mode === "random" ? randomStep%5 : Math.max(0,["fade","wave","wipe","grow","outer"].indexOf(mode))
    readonly property bool animating: animation.running
    objectName: "wallpaperTransitionPreview"
    radius: 16; color: Qt.rgba(0,0,0,.12)
    border.width: 1; border.color: theme.borderSubtle
    implicitHeight: width*.53+52
    function replay() {
        animation.stop()
        if (!visible) return
        if (motion.reduced) { progress=.5; return }
        randomStep++
        progress=0
        animation.restart()
    }
    onModeChanged: replay()
    onVisibleChanged: { if (visible) replay(); else animation.stop() }
    Component.onCompleted: Qt.callLater(replay)
    Connections { target: root.motion; function onReducedChanged() { root.replay() } }
    NumberAnimation { id: animation; target: root; property: "progress"; from: 0; to: 1
        duration: Math.max(150,root.duration*1000); easing.type: Easing.InOutCubic }
    ShaderEffect {
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 8
        height: width*.53
        readonly property vector2d surfaceSize: Qt.vector2d(width,height)
        property color accent: root.theme.accent
        property real progress: root.progress
        property real effect: root.effectIndex
        fragmentShader: Qt.resolvedUrl("../../shaders/settings-transition.frag.qsb")
    }
    Text { x: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 15
        text: root.motion.reduced ? "Prévia estática · movimento reduzido" : "Ilustração da transição"
        color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 10 }
    Text {
        anchors.right: parent.right; anchors.rightMargin: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 12
        text: "↻"; color: root.theme.textPrimary; font.pixelSize: 20
        visible: !root.motion.reduced
        activeFocusOnTab: visible
        Accessible.role: Accessible.Button; Accessible.name: "Repetir prévia"
        Keys.onReturnPressed: root.replay()
        Keys.onSpacePressed: root.replay()
        MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: root.replay() }
    }
}
