import QtQuick

// Visual placeholders; application actions will be connected separately.
Item {
    id: root
    property color ink: "white"
    property bool reducedMotion: false
    signal spotifyRequested()
    signal spotifyHoverChanged(bool hovered)
    implicitWidth: 56
    implicitHeight: 164

    Column {
        anchors.centerIn: parent
        spacing: 4
        Repeater {
            model: ["Spotify", "Discord", "WhatsApp"]
            delegate: Item {
                id: entry
                required property string modelData
                objectName: "edgeApp" + modelData
                width: 44
                height: 44
                activeFocusOnTab: true
                Accessible.role: modelData === "Spotify" ? Accessible.Button : Accessible.Graphic
                Accessible.name: modelData
                Accessible.onPressAction: if (modelData === "Spotify") root.spotifyRequested()
                Keys.onReturnPressed: if (modelData === "Spotify") root.spotifyRequested()
                Keys.onSpacePressed: if (modelData === "Spotify") root.spotifyRequested()
                readonly property bool highlighted: pointer.hovered || activeFocus
                onHighlightedChanged: if (modelData === "Spotify") root.spotifyHoverChanged(highlighted)
                readonly property real emphasis: iconMotion.emphasis
                VeloraIconMotion {
                    id: iconMotion
                    highlighted: entry.highlighted
                    reducedMotion: root.reducedMotion
                }
                HoverHandler { id: pointer; blocking: false }
                TapHandler { enabled: entry.modelData === "Spotify"; onTapped: root.spotifyRequested() }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: 13
                    color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, .08 * entry.emphasis)
                    border.width: entry.activeFocus ? 1 : 0
                    border.color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, .5)
                }
                Canvas {
                    id: icon
                    width: 28; height: 28
                    x: (parent.width - width) / 2
                    y: (parent.height - height) / 2 + iconMotion.lift
                    scale: iconMotion.zoom
                    opacity: iconMotion.inkOpacity
                    antialiasing: true
                    Connections {
                        target: root
                        function onInkChanged() { icon.requestPaint() }
                    }
                    onPaint: {
                        const c = getContext("2d")
                        c.reset()
                        c.scale(width / 24, height / 24)
                        c.strokeStyle = root.ink
                        c.fillStyle = root.ink
                        c.lineWidth = 1.65
                        c.lineCap = "round"
                        c.lineJoin = "round"
                        if (entry.modelData === "Spotify") {
                            c.beginPath(); c.arc(12, 12, 9.5, 0, Math.PI * 2); c.stroke()
                            for (let i = 0; i < 3; i++) {
                                c.beginPath()
                                c.moveTo(6.5 + i * .5, 8.4 + i * 3.3)
                                c.quadraticCurveTo(12, 6.5 + i * 3.3, 18 - i * .65, 10 + i * 3)
                                c.stroke()
                            }
                        } else if (entry.modelData === "Discord") {
                            c.beginPath()
                            c.moveTo(7, 5.2); c.lineTo(9, 4.6); c.lineTo(9.8, 6)
                            c.quadraticCurveTo(12, 5.5, 14.2, 6)
                            c.lineTo(15, 4.6); c.lineTo(17, 5.2)
                            c.quadraticCurveTo(20.5, 9.5, 21, 16)
                            c.quadraticCurveTo(18.5, 18, 16.4, 18.5)
                            c.lineTo(15.3, 16.8)
                            c.quadraticCurveTo(12, 17.8, 8.7, 16.8)
                            c.lineTo(7.6, 18.5)
                            c.quadraticCurveTo(5.5, 18, 3, 16)
                            c.quadraticCurveTo(3.5, 9.5, 7, 5.2)
                            c.closePath(); c.stroke()
                            c.beginPath(); c.ellipse(7.5, 10, 3, 4); c.fill()
                            c.beginPath(); c.ellipse(13.5, 10, 3, 4); c.fill()
                        } else {
                            c.beginPath()
                            c.moveTo(4.2, 17)
                            c.bezierCurveTo(-1, 9, 6, 1, 13, 2.5)
                            c.bezierCurveTo(24, 4, 24, 19, 13, 21)
                            c.quadraticCurveTo(8, 22, 6, 19.7)
                            c.lineTo(2.5, 21); c.closePath(); c.stroke()
                            c.beginPath()
                            c.moveTo(8, 7); c.lineTo(9.5, 9.5); c.lineTo(8.5, 10.7)
                            c.quadraticCurveTo(10, 13.7, 13, 15)
                            c.lineTo(14.5, 13.7); c.lineTo(17, 15)
                            c.quadraticCurveTo(17.2, 18, 14, 17)
                            c.bezierCurveTo(9, 16, 6, 12, 6.5, 8.5)
                            c.quadraticCurveTo(6.5, 7, 8, 7)
                            c.closePath(); c.stroke()
                        }
                    }
                }
            }
        }
    }
}
