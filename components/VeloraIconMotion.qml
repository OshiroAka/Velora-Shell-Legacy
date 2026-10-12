import QtQuick

// Animate the glyph only: its trigger and menu anchor stay stationary.
Item {
    id: root
    property bool highlighted: false
    property bool reducedMotion: false
    property real emphasis: highlighted ? 1 : 0
    readonly property real zoom: reducedMotion ? 1 : 1 + .12 * emphasis
    readonly property real lift: reducedMotion ? 0 : -2 * emphasis
    readonly property real inkOpacity: .76 + .24 * emphasis
    Behavior on emphasis {
        enabled: !root.reducedMotion
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }
}
