pragma ComponentBehavior: Bound
import QtQuick

VeloraRailPopover {
    id: root
    system: root
    property real value: 0
    property real minimumValue: 0
    property bool available: true
    property color accent: "white"
    property string label: ""
    signal edited(real value)
    preferredWidth: 48
    preferredHeight: 130
    contentPadding: 0
    closeOnLeave: false // Owner also supports keyboard volume/brightness feedback.
    customContent: Component {
        Item {
            readonly property bool interactionHeld: slider.dragging
            VeloraRailSlider {
                id: slider
                objectName: "railLevelSlider"
                anchors.horizontalCenter: parent.horizontalCenter
                width: 32; height: parent.height
                value: root.value; minimumValue: root.minimumValue
                available: root.available; accent: root.accent; label: root.label
                reducedMotion: root.reducedMotion
                onEdited: value => root.edited(value)
            }
        }
    }
}
