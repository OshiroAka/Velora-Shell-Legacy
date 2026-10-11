pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Velora.Visualizer 1.0

Item {
    id: root
    required property var media
    property var visualizer: null
    property color surfaceColor: "#272730"
    property color ink: "white"
    property color accent: "#b8a18d"
    property string fontFamily: "sans-serif"
    property real availableHeight: 176
    property bool selected: false
    property bool animated: true
    readonly property bool hasPlayer: !!media && media.hasPlayer
    readonly property bool playing: hasPlayer && media.playing
    signal triggerHoverChanged(bool inside)
    signal activated()
    implicitWidth: 44
    implicitHeight: 100
    height: implicitHeight

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Qt.rgba(root.surfaceColor.r, root.surfaceColor.g, root.surfaceColor.b, .60)
        border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, root.selected ? .65 : hover.hovered ? .4 : .20)
        Behavior on border.color { ColorAnimation { duration: root.animated ? 150 : 0 } }
        VeloraMediaArtwork {
            id: art
            x: 4; y: 4; width: parent.width - 8; height: width; radius: 10
            source: root.hasPlayer ? root.media.artUrl : ""
            accent: root.accent; ink: root.ink; animated: root.animated; selected: hover.hovered
        }
        Spectrum {
            x: 7; y: 46; width: parent.width - 14; height: 12
            analyzer: root.visualizer
            active: root.visible && root.playing && !!root.visualizer && root.visualizer.running
            visible: active
            referenceHeight: height; strength: .25
            accentStart: root.accent; accentMiddle: root.ink; accentEnd: root.accent
            outlineColor: "transparent"
        }
        Text {
            x: 3; y: 46; width: parent.width - 6
            visible: !root.playing
            text: root.hasPlayer ? "PAUSA" : "MÚSICA"
            color: root.ink; opacity: .65
            font.family: root.fontFamily; font.pixelSize: 7; font.letterSpacing: .65
            horizontalAlignment: Text.AlignHCenter
        }
        HoverHandler { id: hover; blocking: false; onHoveredChanged: root.triggerHoverChanged(hovered) }
        TapHandler { acceptedButtons: Qt.LeftButton; onTapped: root.activated() }
        ToolTip.visible: hover.hovered && !root.selected
        ToolTip.delay: 900
        ToolTip.text: root.hasPlayer ? root.media.title + (root.media.artist ? " · " + root.media.artist : "") : "Sua música · Spotify"
        VeloraMediaButton {
            objectName: "railMediaPlay"
            anchors.horizontalCenter: parent.horizontalCenter; y: 63
            width: 28; height: 28
            iconName: root.playing ? "pause" : "play"
            primary: false; highlighted: root.playing; cornerRadius: 8; ink: root.ink; accent: root.accent; animated: root.animated
            hint: root.hasPlayer ? (root.playing ? "Pausar" : "Reproduzir") : "Abrir música"
            onClicked: root.hasPlayer && root.media.canToggle ? root.media.togglePlaying() : root.activated()
        }
        Rectangle {
            x: 10; y: parent.height - 5; width: parent.width - 20; height: 2; radius: 1
            color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, .12)
            Rectangle { width: parent.width * (root.hasPlayer ? root.media.progress : 0); height: 2; radius: 1; color: root.accent }
        }
    }
}
