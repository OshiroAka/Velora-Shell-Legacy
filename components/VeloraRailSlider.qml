import QtQuick
import "../features/topbar/TimerGeometry.js" as TimerGeometry

Item {
    id: root

    property bool reducedMotion: false
    property real value: 0
    property real minimumValue: 0
    property color accent: "#ff9d68"
    property string label: ""
    property bool available: true
    readonly property bool dragging: pointer.pressed
    property real topStretch: 0
    property real bottomStretch: 0
    Behavior on topStretch { enabled: !pointer.pressed && !root.reducedMotion; NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
    Behavior on bottomStretch { enabled: !pointer.pressed && !root.reducedMotion; NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
    signal edited(real value)

    Accessible.role: Accessible.Slider
    Accessible.name: label
    Accessible.description: Math.round(value * 100) + "%"
    Accessible.onIncreaseAction: adjust(0.05)
    Accessible.onDecreaseAction: adjust(-0.05)
    activeFocusOnTab: available

    function adjust(step) {
        if (available)
            edited(Math.max(minimumValue, Math.min(1, value + step)))
    }

    Keys.onUpPressed: adjust(0.05)
    Keys.onDownPressed: adjust(-0.05)
    Keys.onPressed: event => {
        if (!available) return
        if (event.key === Qt.Key_Home) { edited(minimumValue); event.accepted = true }
        if (event.key === Qt.Key_End) { edited(1); event.accepted = true }
    }

    Rectangle {
        id: well
        anchors.centerIn: parent
        width: 17
        height: parent.height - 28
        radius: width / 2
        color: "#bb080b0a"
        border.width: 1
        border.color: root.activeFocus ? root.accent : "#25ffffff"

        Rectangle {
            id: track
            x: (parent.width - width) / 2
            y: 7 - root.topStretch
            width: 9
            height: parent.height - 14 + root.topStretch + root.bottomStretch
            radius: width / 2
            color: "#38403e"

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: parent.height * Math.max(0, Math.min(1, root.value))
                radius: width / 2
                color: root.accent
            }

            Rectangle {
                x: (parent.width - width) / 2
                y: parent.height * (1 - Math.max(0, Math.min(1, root.value))) - height / 2
                width: 19
                height: 19
                radius: height / 2
                color: Qt.lighter(root.accent, pointer.pressed ? 1.18 : 1.08)
                border.width: 1
                border.color: "#28ffffff"
            }
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.available
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        function updateValue(mouse) {
            const top = well.y + 7
            const height = well.height - 14
            const bottom = top + height
            root.topStretch = Math.min(8, Math.max(0, TimerGeometry.resistance(top - mouse.y)))
            root.bottomStretch = Math.min(8, Math.max(0, TimerGeometry.resistance(mouse.y - bottom)))
            root.edited(Math.max(root.minimumValue, Math.min(1, 1 - (mouse.y - top) / height)))
        }
        onPressed: mouse => updateValue(mouse)
        onPositionChanged: mouse => { if (pressed) updateValue(mouse) }
        onReleased: mouse => { updateValue(mouse); root.topStretch = 0; root.bottomStretch = 0 }
        onCanceled: { root.topStretch = 0; root.bottomStretch = 0 }
        onWheel: wheel => {
            root.adjust(wheel.angleDelta.y > 0 ? 0.05 : -0.05)
            wheel.accepted = true
        }
    }
}
