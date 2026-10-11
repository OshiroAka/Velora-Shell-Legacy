import QtQuick

FocusScope {
    id: root
    required property var controller
    required property var host
    required property var config
    required property var theme
    required property var status
    required property var system
    required property var fanPlus
    required property var timerService
    required property var clock
    required property var calendar
    required property var media
    required property var actions
    required property var weather
    property real barHeight: 40
    property real leftInset: 8
    property real rightInset: 8
    readonly property string desiredType: controller.owner === host ? controller.activeType : ""
    required property var motionTokens
    readonly property bool motionMounted: motion.mounted
    readonly property real neckHalfWidth: motion.neckHalfWidth
    readonly property real anchorX: motion.anchorX
    readonly property bool mounted: motion.mounted
    readonly property rect panelRect: motion.panelRect
    Keys.onEscapePressed: controller.close()
    function refreshAnchor() { if (mounted) motion.updateAnchor() }
    function syncPresence() {
        controller.panelPresence(host, motionMounted && motion.pointerInside,
            motionMounted && (motion.pointerHeld || motionContent.interactionHeld))
    }
    Connections {
        target: root.controller
        function onOwnerChanged() { Qt.callLater(root.syncPresence) }
        function onActiveTypeChanged() { Qt.callLater(root.syncPresence) }
    }
    MorphPopover {
        id: motion
        anchors.fill: parent
        controller: root.controller
        barHeight: root.barHeight
        leftInset: root.leftInset
        rightInset: root.rightInset
        motion: root.motionTokens
        reducedMotion: root.config.reducedMotion
        desiredType: root.desiredType
        onPointerInsideChanged: root.syncPresence()
        onPointerHeldChanged: root.syncPresence()
        onMountedChanged: root.syncPresence()
        BarPanelContent {
            id: motionContent
            anchors.fill: parent
            active: motion.mounted
            type: motion.presentedType
            theme: root.theme; systemStatus: root.status; system: root.system
            fanPlus: root.fanPlus
            timerService: root.timerService; clock: root.clock; calendar: root.calendar
            media: root.media; weather: root.weather
            controller: root.controller; actions: root.actions
            onInteractionHeldChanged: root.syncPresence()
        }
    }
}
