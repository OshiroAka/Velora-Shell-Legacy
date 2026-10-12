import QtQuick
import "../core" as Core

Item {
    id: root
    required property var theme
    property var options: []
    property string selected: ""
    property real tabWidth: 90
    property var motion: fallbackMotion
    Core.Motion { id: fallbackMotion; config: root.theme ? root.theme.config : null }
    readonly property int columns: Math.max(1, Math.min(options.length, Math.floor(width/tabWidth)))
    readonly property int selectedIndex: options.findIndex(option=>option.id === selected)
    readonly property real cellWidth: width/columns
    implicitWidth: options.length*tabWidth
    implicitHeight: Math.ceil(options.length/columns)*36
    width: Math.min(parent ? parent.width : implicitWidth, implicitWidth)
    signal chosen(string id)
    function moveFocus(index, delta) {
        const next = Math.max(0, Math.min(options.length-1, index+delta))
        chosen(options[next].id)
        tabs.itemAt(next).forceActiveFocus(Qt.TabFocusReason)
    }
    Rectangle { anchors.fill: parent; radius: 11; color: Qt.rgba(0,0,0,.10) }
    Rectangle {
        visible: root.selectedIndex >= 0
        x: (Math.max(0,root.selectedIndex)%root.columns)*root.cellWidth+2
        y: Math.floor(Math.max(0,root.selectedIndex)/root.columns)*36+2
        width: root.cellWidth-4; height: 32; radius: 9
        color: Qt.rgba(root.theme.accent.r,root.theme.accent.g,root.theme.accent.b,.18)
        border.width: 1; border.color: root.theme.borderSubtle
        Behavior on x { NumberAnimation { duration: root.motion.geometryDuration; easing.type: root.motion.easeGeometry } }
        Behavior on y { NumberAnimation { duration: root.motion.geometryDuration; easing.type: root.motion.easeGeometry } }
    }
    Repeater {
        id: tabs
        model: root.options
        Item {
            id: tab
            required property var modelData
            required property int index
            property string label: modelData.label
            function triggered() { root.chosen(modelData.id) }
            x: (index%root.columns)*root.cellWidth; y: Math.floor(index/root.columns)*36
            width: root.cellWidth; height: 36
            activeFocusOnTab: true
            Accessible.role: Accessible.Button; Accessible.name: label
            Accessible.checkable: true; Accessible.checked: root.selected === modelData.id
            Accessible.onPressAction: triggered()
            Keys.onSpacePressed: triggered()
            Keys.onReturnPressed: triggered()
            Keys.onLeftPressed: root.moveFocus(index, -1)
            Keys.onRightPressed: root.moveFocus(index, 1)
            Keys.onUpPressed: root.moveFocus(index, -root.columns)
            Keys.onDownPressed: root.moveFocus(index, root.columns)
            Rectangle { anchors.fill: parent; anchors.margins: 3; radius: 9
                color: pointer.containsMouse ? Qt.rgba(1,1,1,.05) : "transparent"
                border.width: tab.activeFocus ? 1 : 0; border.color: root.theme.accent }
            Text { anchors.centerIn: parent; text: tab.label
                color: root.selected === tab.modelData.id ? root.theme.textPrimary : root.theme.textSecondary
                font.family: root.theme.bodyFont; font.pixelSize: 11 }
            MouseArea { id: pointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: tab.triggered() }
        }
    }
}
