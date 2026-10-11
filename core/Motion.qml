import QtQuick

QtObject {
    property var config: null

    property bool reduced: !!config && config.reducedMotion
    readonly property real pace: config && config.motionPreset === "calm" ? 1.18
        : (config && config.motionPreset === "snappy" ? 0.82 : 1)
    // Connected surfaces and the wallpaper accordion share the approved timer
    // sequence. Keep unrelated scene/lock transitions on their existing tokens.
    readonly property int intent: 110
    readonly property int leaveGrace: 180
    readonly property int surfaceHover: reduced ? 0 : Math.round(110 * pace)
    readonly property int geometryDuration: reduced ? 0 : Math.round(220 * pace)
    readonly property int accordionDuration: reduced ? 0 : Math.round(420 * pace)
    readonly property int accordionCloseDuration: reduced ? 0 : Math.round(300 * pace)
    readonly property int handoffDuration: reduced ? 0 : Math.round(240 * pace)
    readonly property int contentDelay: reduced ? 0 : Math.round(120 * pace)
    readonly property int contentDuration: reduced ? 0 : Math.round(150 * pace)
    readonly property int contentExit: reduced ? 0 : Math.round(65 * pace)
    readonly property int closeDuration: reduced ? 0 : Math.round(125 * pace)
    readonly property int easeGeometry: Easing.OutCubic
    readonly property int easeHandoff: Easing.InOutCubic
    readonly property int easeContent: Easing.OutCubic
    readonly property int micro: reduced ? 70 : Math.round(140 * pace)
    readonly property int hover: reduced ? 80 : Math.round(190 * pace)
    readonly property int selection: reduced ? 80 : Math.round(240 * pace)
    readonly property int morph: reduced ? 90 : Math.round(300 * pace)
    readonly property int depth: reduced ? 100 : Math.round(420 * pace)
    readonly property int scene: reduced ? 110 : Math.round(520 * pace)
    readonly property int stagger: reduced ? 0 : 45
    readonly property int exit: reduced ? 90 : Math.round(220 * pace)
    readonly property int widgetOpen: reduced ? 140 : Math.round(800 * pace)
    readonly property int widgetExit: reduced ? 130 : Math.round(650 * pace)
    readonly property int widgetStagger: reduced ? 0 : 45
    readonly property int widgetSettle: reduced ? 0 : 90
}
