pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../services" as Services
import "EdgeMediaContours.js" as Contours

VeloraRailPopover {
    id: root
    required property var media
    property var analyzer: null
    system: media
    rightSide: true
    property string page: "apps"
    property string pendingPage: "apps"
    readonly property bool mediaPanelActive: mounted && (page !== "apps" || pendingPage !== "apps")
    property bool spotifyHovered: false
    readonly property bool lyricsAvailable: !!media && media.spotifyPlaying
    property real labelReveal: 0
    property real labelContent: 0
    property real contour: page === "apps" ? 0 : page === "lyrics" ? 2 : 1
    // Hold the last contour through exit; stopping FFT must not snap the edge.
    property var contourSamples: Contours.samples(0)
    Connections {
        target: waves
        function onSamplesChanged() { if (root.opened) root.contourSamples = waves.samples }
    }
    readonly property bool spectrumActive: waves.spectrumActive
    property real dockProgress: opened && mediaPanelActive ? 1 : 0
    Behavior on dockProgress {
        NumberAnimation { duration: root.reducedMotion ? 0 : 2200; easing.type: Easing.InOutCubic }
    }
    readonly property real sidebarWaveScale: dockProgress * .55
    readonly property real sidebarWaveWidth: Math.min(400, Math.max(0, width - railWidth - 16)) * .55
    property var sidebarSamples: Contours.samples(1)
    onContourSamplesChanged: if (mediaPanelActive && page !== "apps") sidebarSamples = contourSamples.slice()
    function sidebarOffset(t) {
        const reach = Math.max(.001, dockProgress * 1.12)
        const rise = Math.max(0, Math.min(1, ((t - (1 - reach)) / .12)))
        return Contours.offset(sidebarSamples, t) * sidebarWaveWidth * dockProgress * rise * rise * (3 - 2 * rise)
    }
    function keepOpenForControl(type) {
        return mediaPanelActive && (type === "volume" || type === "brightness")
    }
    VeloraEdgeWaves {
        id: waves
        objectName: "edgeWaves"
        analyzer: root.analyzer
        active: root.opened && root.visible && root.page === root.pendingPage
        reducedMotion: root.reducedMotion
        playing: !!root.media && root.media.spotifyPlaying
        page: root.page; contour: root.contour
        synced: library.synced; lines: library.lines; activeLine: library.activeLine
        position: root.media ? root.media.sampledPosition : 0
        duration: root.media ? root.media.length : 0
    }
    function contourOffset(progress) { return Contours.offset(contourSamples, progress) * bodyWidth }
    property alias labelMask: labelArea
    readonly property color ink: theme ? theme.textPrimary : "white"
    readonly property string family: theme ? theme.bodyFont : "sans-serif"
    preferredWidth: page === "apps" ? 56 : 400
    preferredHeight: page === "apps" ? 164 : height
    verticalMargin: page === "apps" ? 24 : 0
    fullHeightSurface: page !== "apps"
    contentExitDuration: page === "apps" ? motion.contentExit : (reducedMotion ? 0 : 180)
    surfaceExitDuration: page === "apps" ? motion.closeDuration : (reducedMotion ? 0 : 760)
    contentPadding: 0
    closeOnLeave: page === "apps" && pendingPage === "apps"
    extraHovered: labelHover.hovered || lyricsButton.activeFocus
    extension: ({y: bodyY + 12, width: 104 * labelReveal * reveal, height: 44})
    Behavior on preferredWidth { NumberAnimation { duration: root.motion.geometryDuration; easing.type: Easing.InOutCubic } }
    Behavior on preferredHeight { NumberAnimation { duration: root.motion.geometryDuration; easing.type: Easing.InOutCubic } }
    Behavior on contour { NumberAnimation { duration: root.motion.geometryDuration; easing.type: Easing.InOutCubic } }
    Services.MediaLibraryService {
        id: library
        media: root.media
        active: root.opened && root.page !== "apps"
        page: root.page === "lyrics" ? "lyrics" : "queue"
    }
    function showPage(next) {
        if (next === "lyrics" && !lyricsAvailable) return
        if (next !== "apps") media.selectSpotify()
        pendingPage = next
        hideLabel()
        pageMotion.stop()
        if (reducedMotion) { page = next; contentReveal = 1 }
        else pageMotion.restart()
    }
    function updateLabel() {
        if (opened && page === "apps" && pendingPage === "apps" && lyricsAvailable
                && (spotifyHovered || extraHovered)) {
            labelLeave.stop(); labelOut.stop()
            if (reducedMotion) { labelReveal = 1; labelContent = 1 }
            else if (labelReveal < 1 && !labelIn.running) labelIn.restart()
        } else labelLeave.restart()
    }
    function hideLabel() {
        labelLeave.stop(); labelIn.stop()
        if (reducedMotion) { labelReveal = 0; labelContent = 0 }
        else labelOut.restart()
    }
    onPageChanged: library.page = page === "lyrics" ? "lyrics" : "queue"
    onSpotifyHoveredChanged: updateLabel()
    onExtraHoveredChanged: updateLabel()
    onLyricsAvailableChanged: { if (!lyricsAvailable) hideLabel(); else updateLabel() }
    onOpenedChanged: {
        if (!opened) { pageMotion.stop(); hideLabel() }
        else contourSamples = waves.samples
    }
    onMountedChanged: if (!mounted) {
        pageMotion.stop(); labelIn.stop(); labelOut.stop(); labelLeave.stop()
        page = "apps"; pendingPage = "apps"; spotifyHovered = false
        labelReveal = 0; labelContent = 0
        contourSamples = Contours.samples(0)
    }
    Connections {
        target: root.motion
        function onReducedChanged() {
            if (!root.reducedMotion) return
            pageMotion.complete(); labelIn.complete(); labelOut.complete()
        }
    }
    SequentialAnimation {
        id: pageMotion
        NumberAnimation { target: root; property: "contentReveal"; to: 0; duration: root.motion.contentExit }
        ScriptAction { script: root.page = root.pendingPage }
        PauseAnimation { duration: root.motion.geometryDuration }
        NumberAnimation { target: root; property: "contentReveal"; to: 1; duration: root.motion.contentDuration }
    }
    Timer { id: labelLeave; interval: root.motion.leaveGrace; onTriggered: root.hideLabel() }
    SequentialAnimation {
        id: labelIn
        NumberAnimation { target: root; property: "labelReveal"; to: 1; duration: root.motion.geometryDuration; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "labelContent"; to: 1; duration: root.motion.contentDuration }
    }
    SequentialAnimation {
        id: labelOut
        NumberAnimation { target: root; property: "labelContent"; to: 0; duration: root.motion.contentExit }
        NumberAnimation { target: root; property: "labelReveal"; to: 0; duration: root.motion.closeDuration; easing.type: Easing.InOutCubic }
    }
    Item {
        id: labelArea
        x: root.width - root.railWidth - root.bodyWidth - width
        y: root.extension.y
        width: root.mounted ? root.extension.width : 0
        height: width > 0 ? 44 : 0
        visible: height > 0
        clip: true
        HoverHandler { id: labelHover; blocking: false }
        Button {
            id: lyricsButton
            objectName: "edgeLyricsButton"
            width: 104; height: 44
            text: "Lyrics"
            opacity: root.labelContent
            enabled: root.opened && root.lyricsAvailable && opacity > .95
            Accessible.name: "Abrir letras da música no Spotify"
            onClicked: root.showPage("lyrics")
            background: Rectangle {
                anchors.margins: 4; anchors.fill: parent; radius: 9
                color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, lyricsButton.hovered || lyricsButton.activeFocus ? .09 : 0)
            }
            contentItem: Text {
                text: lyricsButton.text; color: root.ink; font.family: root.family; font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
        }
    }
    customContent: Component {
        Loader {
            readonly property bool interactionHeld: !!item && item.interactionHeld === true
            sourceComponent: root.page === "apps" ? apps : player
            Component {
                id: apps
                VeloraEdgeApps {
                    ink: root.ink; reducedMotion: root.reducedMotion
                    onSpotifyRequested: root.showPage("media")
                    onSpotifyHoverChanged: hovered => root.spotifyHovered = hovered
                }
            }
            Component {
                id: player
                VeloraEdgeMediaPanel {
                    media: root.media; library: library; theme: root.theme
                    lyrics: root.page === "lyrics"; reducedMotion: root.reducedMotion
                    contourSamples: root.contourSamples
                    onBackRequested: root.showPage("apps")
                    onLyricsRequested: root.showPage("lyrics")
                    onMediaRequested: root.showPage("media")
                    onCloseRequested: { root.blocked = root.triggerHovered; root.close() }
                }
            }
        }
    }
}
