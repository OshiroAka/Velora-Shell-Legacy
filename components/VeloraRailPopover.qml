pragma ComponentBehavior: Bound
import QtQuick
import "../core" as Core
import "../features/topbar" as TopBar

// Shared motion and input for panels extending out of the sidebar.
FocusScope {
    id: root
    required property var theme
    required property var system
    property var motion: defaultMotion
    Core.Motion { id: defaultMotion }
    readonly property bool reducedMotion: motion.reduced
    readonly property bool animating: expanding.running || handoffMotion.running || entering.running || closing.running || contentDelay.running
    property string toolType: "caffeine"
    property real preferredWidth: 300
    property real preferredHeight: 268
    property Component customContent: null
    property real contentPadding: 16
    property real contentMinimumWidth: preferredWidth - 2 * contentPadding
    property real contentMinimumHeight: preferredHeight - 2 * contentPadding
    property bool extraHovered: false
    property var extension: null
    property bool closeOnLeave: true
    property bool rightSide: false
    property real railWidth: 64
    property real anchorY: 260
    property bool triggerHovered: false
    property bool blocked: false
    property bool opened: false
    property bool mounted: false
    property real reveal: 0
    property real contentReveal: 0
    property var handoffSource: null
    property bool handoffActive: false
    property real handoffProgress: 1
    property real handoffFromWidth: 0
    property real handoffFromHeight: 0
    property real handoffFromY: 0
    readonly property real targetWidth: Math.min(preferredWidth, Math.max(0, width - railWidth - 16))
    readonly property real targetHeight: Math.min(preferredHeight, Math.max(0, height - 48))
    readonly property real bodyWidth: Math.min(Math.max(0, width - railWidth - 16), handoffActive ? (handoffFromWidth + (targetWidth - handoffFromWidth) * handoffProgress) * reveal : targetWidth * reveal)
    readonly property real bodyHeight: Math.min(Math.max(0, height - 48), handoffActive ? 34 + (handoffFromHeight + (targetHeight - handoffFromHeight) * handoffProgress - 34) * reveal : 34 + (targetHeight - 34) * reveal)
    readonly property real targetY: Math.max(24, Math.min(height - targetHeight - 24, anchorY - targetHeight / 2))
    readonly property real bodyY: Math.max(24, Math.min(height - bodyHeight - 24, handoffActive ? handoffFromY + (targetY - handoffFromY) * handoffProgress : anchorY - bodyHeight / 2))
    readonly property var outline: ({visible: mounted, y: bodyY, width: bodyWidth, height: bodyHeight, extension: extension})
    property alias maskItem: presenceArea
    readonly property bool panelHovered: presence.hovered || extraHovered
    readonly property bool panelHeld: hold.active || contentViewport.dragging || contentViewport.flicking || holdsInteraction(contentLoader.item)
    function holdsInteraction(item: var): bool { return !!item && item.interactionHeld === true }
    signal opening()
    signal shapeChanged()
    onOutlineChanged: shapeChanged()
    onPanelHoveredChanged: updatePresence()
    onPanelHeldChanged: updatePresence()
    onTriggerHoveredChanged: {
        if (!triggerHovered) blocked = false
        updatePresence()
    }
    onEnabledChanged: if (!enabled) close()

    function updatePresence() {
        if ((triggerHovered && !blocked) || panelHovered || panelHeld) {
            leaveDelay.stop()
            if (!opened && enabled && !blocked) {
                if (handoffSource && handoffSource !== root && handoffSource.opened) open()
                else enterDelay.restart()
            }
        } else {
            enterDelay.stop()
            if (mounted && closeOnLeave) leaveDelay.restart()
        }
    }
    function open() {
        if (!enabled || !system) return
        enterDelay.stop(); leaveDelay.stop(); closing.stop(); expanding.stop(); handoffMotion.stop(); entering.stop(); contentDelay.stop()
        const previous = handoffSource && handoffSource !== root && handoffSource.mounted ? handoffSource : null
        if (previous) {
            handoffFromWidth = previous.bodyWidth
            handoffFromHeight = previous.bodyHeight
            handoffFromY = previous.bodyY
            previous.closeInstant()
            handoffActive = true
            handoffProgress = 0
            reveal = 1
        }
        opened = true; mounted = true
        opening()
        forceActiveFocus()
        if (reducedMotion) {
            handoffActive = false; handoffProgress = 1; reveal = 1; contentReveal = 1
        } else {
            if (handoffActive) { handoffMotion.restart(); expanding.restart() }
            else expanding.restart()
            contentDelay.restart()
        }
    }
    function closeInstant() {
        enterDelay.stop(); leaveDelay.stop(); closing.stop(); expanding.stop()
        contentDelay.stop(); entering.stop(); handoffMotion.stop()
        opened = false; mounted = false; reveal = 0; contentReveal = 0
        handoffActive = false; handoffProgress = 1
    }
    function close() {
        enterDelay.stop(); leaveDelay.stop(); expanding.stop()
        contentDelay.stop(); entering.stop()
        if (handoffActive) {
            const w = bodyWidth / Math.max(0.001, reveal)
            const h = 34 + (bodyHeight - 34) / Math.max(0.001, reveal)
            const y = bodyY
            handoffMotion.stop()
            handoffFromWidth = w; handoffFromHeight = h; handoffFromY = y; handoffProgress = 0
        }
        opened = false
        if (reducedMotion) closeInstant()
        else if (mounted) closing.restart()
    }
    onReducedMotionChanged: if (reducedMotion) {
        expanding.stop(); handoffMotion.stop(); entering.stop(); closing.stop(); contentDelay.stop()
        handoffActive = false; handoffProgress = 1
        reveal = opened ? 1 : 0; contentReveal = reveal; mounted = opened
    }
    function toggle() {
        if (opened) { blocked = triggerHovered; close() }
        else { blocked = false; open() }
    }
    Keys.onEscapePressed: { blocked = triggerHovered; close() }
    Timer { id: enterDelay; interval: root.motion.intent; onTriggered: root.open() }
    Timer { id: leaveDelay; interval: root.motion.leaveGrace; onTriggered: if (root.closeOnLeave && !root.triggerHovered && !root.panelHovered && !root.panelHeld) root.close() }
    NumberAnimation { id: expanding; target: root; property: "reveal"; to: 1; duration: root.motion.geometryDuration; easing.type: root.motion.easeGeometry }
    NumberAnimation { id: handoffMotion; target: root; property: "handoffProgress"; to: 1; duration: root.motion.handoffDuration; easing.type: root.motion.easeHandoff; onFinished: root.handoffActive = false }
    Timer { id: contentDelay; interval: root.motion.contentDelay; onTriggered: if (root.opened) entering.restart() }
    NumberAnimation { id: entering; target: root; property: "contentReveal"; to: 1; duration: root.motion.contentDuration; easing.type: root.motion.easeContent }
    SequentialAnimation {
        id: closing
        NumberAnimation { target: root; property: "contentReveal"; to: 0; duration: root.motion.contentExit; easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "reveal"; to: 0; duration: root.motion.closeDuration; easing.type: root.motion.easeHandoff }
        ScriptAction { script: if (!root.opened) { root.mounted = false; root.handoffActive = false } }
    }
    Item {
        id: presenceArea
        // Include the rail's edge and the curved join while crossing to buttons.
        x: root.rightSide ? root.width - root.railWidth - root.bodyWidth : root.railWidth - 16
        y: root.bodyY - 12
        width: root.mounted ? root.bodyWidth + 16 : 0
        height: root.mounted ? root.bodyHeight + 24 : 0
        visible: root.mounted
        HoverHandler { id: presence; blocking: false }
        PointHandler { id: hold; acceptedButtons: Qt.LeftButton | Qt.RightButton }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            // Consume clicks on empty or disabled controls inside the panel.
            // Otherwise the full-screen outside catcher closes the popover.
            onPressed: mouse => mouse.accepted = true
        }
        Item {
            x: root.rightSide ? 0 : 16; y: 12
            width: root.bodyWidth; height: root.bodyHeight
            clip: true
            Flickable {
                id: contentViewport
                x: root.contentPadding; y: root.contentPadding - (1 - root.contentReveal) * 6
                width: Math.max(0, root.targetWidth - 2 * root.contentPadding); height: Math.max(0, root.targetHeight - 2 * root.contentPadding)
                contentWidth: Math.max(width, root.contentMinimumWidth)
                contentHeight: Math.max(height, root.contentMinimumHeight)
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentWidth > width || contentHeight > height
                opacity: root.contentReveal
                enabled: root.opened && root.reveal > 0.98 && root.contentReveal > 0.9
                Loader {
                    id: contentLoader
                    width: contentViewport.contentWidth
                    height: contentViewport.contentHeight
                    active: root.mounted
                    sourceComponent: root.customContent || toolsContent
                }
                Component {
                    id: toolsContent
                    TopBar.MicroToolsPanel {
                        active: root.mounted && !!root.theme && !!root.system
                        type: root.toolType
                        theme: root.theme; system: root.system
                        controller: root; actions: null
                    }
                }
            }
        }
    }
}
