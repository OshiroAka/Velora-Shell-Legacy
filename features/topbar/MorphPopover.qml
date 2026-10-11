import QtQuick
import "../../core" as Core
import "TimerGeometry.js" as Geometry
import "TopBarGeometry.js" as PanelSizes

// One persistent connected surface; geometry leads, content follows.
FocusScope {
    id: root
    required property var controller
    property string desiredType: ""
    property string presentedType: ""
    property real barHeight: 40
    property real leftInset: 8
    property real rightInset: 8
    property var motion: defaultMotion
    Core.Motion { id: defaultMotion }
    property bool reducedMotion: motion.reduced
    property bool mounted: false
    property real reveal: 0
    property real contentReveal: 0
    property real anchorX: width / 2
    property real anchorWidth: 74
    property real bodyWidth: 300
    property real bodyHeight: 154
    property var anchorItem: controller.anchorItem
    default property alias content: contentHost.data
    readonly property var geometry: Geometry.panel(width, height, barHeight, anchorX,
        anchorWidth, bodyWidth, bodyHeight, reveal, leftInset, rightInset)
    readonly property rect panelRect: Qt.rect(geometry.x, geometry.y, geometry.width, geometry.height)
    readonly property real neckHalfWidth: geometry.neck
    readonly property bool interactive: desiredType === presentedType && desiredType.length > 0
        && reveal > 0.98 && contentReveal > 0.9 && !swapping.running && !geometryMoving
    readonly property bool geometryMoving: anchorMove.running || anchorResize.running || widthResize.running || heightResize.running
    readonly property bool pointerInside: presence.hovered
    readonly property bool pointerHeld: dragPresence.active || contentViewport.dragging || contentViewport.flicking
    readonly property real contentWidth: Math.max(0, PanelSizes.size(presentedType === "calendar" ? "clock" : presentedType)[0] - 32)
    readonly property real contentHeight: Math.max(0, PanelSizes.size(presentedType === "calendar" ? "clock" : presentedType)[1] - 32)
    visible: mounted

    function updateAnchor() {
        if (!anchorItem || !desiredType) return
        anchorWidth = anchorItem.width
        anchorX = anchorItem.mapToItem(root, anchorItem.width / 2, 0).x
    }
    function aim() {
        const size = PanelSizes.size(desiredType === "calendar" ? "clock" : desiredType)
        bodyWidth = size[0]
        bodyHeight = size[1]
        updateAnchor()
    }
    function present() { presentedType = desiredType }
    function synchronize() {
        contentDelay.stop(); opening.stop(); entering.stop(); closing.stop(); swapping.stop()
        if (reducedMotion) {
            mounted = false
            if (desiredType) { aim(); present() }
            else presentedType = ""
            reveal = desiredType ? 1 : 0
            contentReveal = reveal
            mounted = !!desiredType
            if (mounted) forceActiveFocus()
            return
        }
        if (!desiredType) {
            if (mounted) closing.start()
        } else if (!mounted) {
            aim(); present()
            mounted = true
            forceActiveFocus()
            opening.start(); contentDelay.restart()
        } else {
            // Retarget the live shape immediately. Old controls retain their
            // layout until their exit ends; the surface never unmounts.
            aim(); opening.start(); contentDelay.restart()
            if (desiredType !== presentedType) swapping.start()
        }
    }
    onReducedMotionChanged: synchronize()
    onDesiredTypeChanged: synchronize()
    onAnchorItemChanged: if (desiredType) Qt.callLater(updateAnchor)
    onWidthChanged: if (mounted) Qt.callLater(updateAnchor)
    Keys.onEscapePressed: controller.close()
    Behavior on anchorX { enabled: root.mounted && !root.reducedMotion; NumberAnimation { id: anchorMove; duration: root.motion.handoffDuration; easing.type: root.motion.easeHandoff } }
    Behavior on anchorWidth { enabled: root.mounted && !root.reducedMotion; NumberAnimation { id: anchorResize; duration: root.motion.handoffDuration; easing.type: root.motion.easeHandoff } }
    Behavior on bodyWidth { enabled: root.mounted && !root.reducedMotion; NumberAnimation { id: widthResize; duration: root.motion.handoffDuration; easing.type: root.motion.easeHandoff } }
    Behavior on bodyHeight { enabled: root.mounted && !root.reducedMotion; NumberAnimation { id: heightResize; duration: root.motion.handoffDuration; easing.type: root.motion.easeHandoff } }

    NumberAnimation { id: opening; target: root; property: "reveal"; to: 1; duration: root.motion.geometryDuration; easing.type: root.motion.easeGeometry }
    Timer { id: contentDelay; interval: root.motion.contentDelay; onTriggered: if (root.desiredType) entering.start() }
    NumberAnimation { id: entering; target: root; property: "contentReveal"; to: 1; duration: root.motion.contentDuration; easing.type: root.motion.easeContent }
    SequentialAnimation {
        id: swapping
        NumberAnimation { target: root; property: "contentReveal"; to: 0; duration: root.motion.contentExit; easing.type: Easing.InCubic }
        ScriptAction { script: { root.present(); root.forceActiveFocus() } }
    }
    SequentialAnimation {
        id: closing
        NumberAnimation { target: root; property: "contentReveal"; to: 0; duration: root.motion.contentExit; easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "reveal"; to: 0; duration: root.motion.closeDuration; easing.type: root.motion.easeHandoff }
        ScriptAction { script: if (!root.desiredType) { root.mounted = false; root.presentedType = "" } }
    }
    Item {
        // Include the curved seam and the small antialiasing fringe. Handlers
        // observe child controls without stealing their clicks or drags.
        x: root.panelRect.x - 8; y: root.barHeight
        width: root.panelRect.width + 16
        height: Math.max(0, root.panelRect.y + root.panelRect.height + 8 - y)
        HoverHandler { id: presence; blocking: false }
        PointHandler { id: dragPresence; acceptedButtons: Qt.AllButtons }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onWheel: wheel => { wheel.accepted = true }
        }
    Item {
        // Keep controls below the same pointer-observing ancestor. A sibling
        // hover area loses delivery when a Button or TextField takes the mouse.
        x: 12; y: root.panelRect.y + 4 - root.barHeight
        width: Math.max(0, root.panelRect.width - 8)
        height: Math.max(0, root.panelRect.height - 8)
        clip: true
        enabled: root.interactive
        opacity: root.contentReveal
        Flickable {
            id: contentViewport
            anchors.fill: parent
            anchors.margins: 12
            contentWidth: root.contentWidth
            contentHeight: root.contentHeight
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentWidth > width || contentHeight > height
            clip: true
        Item {
            id: contentHost
            y: -(1 - root.contentReveal) * 6
            width: root.contentWidth; height: root.contentHeight
            scale: 0.98 + 0.02 * root.contentReveal
            transformOrigin: Item.Top
        }
        }
    }
    }
}
