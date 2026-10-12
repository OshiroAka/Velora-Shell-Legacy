import QtQuick

// Lightweight illustrations of the real Clock/Calendar/Weather/Media cards.
// Deliberately no service instances, capture, timers, or continuous animation.
Item {
    id: root
    required property var theme
    property string kind: "clock"
    property string visualizerMode: "wave"
    property bool solid: false
    property color ink: theme.textPrimary
    property color soft: theme.textSecondary
    property color accent: theme.accentSoft
    implicitWidth: 190; implicitHeight: 92
    FontLoader { id: orbitron; source: "../../assets/fonts/Orbitron-Variable.ttf" }
    Item {
        width: 190; height: 92; anchors.centerIn: parent
        scale: Math.min(1, root.width / width, root.height / height)
        Loader {
            anchors.fill: parent
            sourceComponent: root.kind === "clock" ? clockFace : root.kind === "calendar" ? calendarFace
                : root.kind === "weather" ? weatherFace : root.kind === "media" ? mediaFace
                : root.kind === "gallery" ? galleryFace : root.kind === "system" ? systemFace
                : root.kind === "visualizer" ? visualizerFace : frameFace
        }
    }
    component MiniSurface: Rectangle {
        radius: 16
        color: root.solid ? root.theme.moduleSurface : Qt.rgba(root.accent.r, root.accent.g, root.accent.b, .10)
        border.color: root.theme.borderSubtle; border.width: 1
    }
    Component { id: clockFace
        Item {
            MiniSurface { width: 182; height: 78; anchors.centerIn: parent
                Text { anchors.horizontalCenter: parent.horizontalCenter; y: 9; text: "10:08"; color: root.ink; font.family: orbitron.name; font.pixelSize: 33 }
                Text { anchors.horizontalCenter: parent.horizontalCenter; y: 53; text: "domingo, 11 outubro"; color: root.soft; font.family: root.theme.bodyFont; font.pixelSize: 9 }
            }
        }
    }
    Component { id: calendarFace
        MiniSurface { width: 164; height: 92
            Text { x: 12; y: 6; text: "outubro"; color: root.ink; font.family: root.theme.bodyFont; font.pixelSize: 10 }
            Grid { x: 12; y: 28; columns: 7; spacing: 3
                Repeater { model: 21
                    Rectangle { required property int index; width: 20; height: 15; radius: 5; color: index === 10 ? root.accent : "transparent"
                        Text { anchors.centerIn: parent; text: parent.index+1; color: parent.index === 10 ? root.theme.inverseInk : root.soft; font.pixelSize: 8; font.family: root.theme.bodyFont }
                    }
                }
            }
        }
    }
    Component { id: weatherFace
        Item { MiniSurface { width: 180; height: 82; anchors.centerIn: parent
            Text { x: 14; y: 10; text: "Parcialmente nublado"; color: root.soft; font.family: root.theme.bodyFont; font.pixelSize: 8 }
            Text { x: 14; y: 22; text: "23°"; color: root.ink; font.family: root.theme.bodyFont; font.pixelSize: 33; font.weight: Font.Light }
            Text { x: 117; y: 23; text: "☀"; color: root.accent; font.pixelSize: 33 }
            Text { x: 16; y: 64; text: "26° / 18°"; color: root.soft; font.family: root.theme.bodyFont; font.pixelSize: 8 }
        } }
    }
    Component { id: mediaFace
        Item { MiniSurface { width: 184; height: 68; anchors.centerIn: parent
            Rectangle { x: 10; y: 12; width: 44; height: 44; radius: 22; color: root.accent
                Rectangle { anchors.centerIn: parent; width: 18; height: 18; radius: 9; color: root.theme.moduleSurface
                    Rectangle { anchors.centerIn: parent; width: 5; height: 5; radius: 3; color: root.accent } }
            }
            Text { x: 65; y: 12; text: "Sua música"; color: root.ink; font.family: root.theme.bodyFont; font.pixelSize: 11 }
            Text { x: 65; y: 30; text: "Artista · álbum"; color: root.soft; font.family: root.theme.bodyFont; font.pixelSize: 8 }
            Text { x: 65; y: 46; text: "‹      Ⅱ      ›"; color: root.ink; font.pixelSize: 11 }
        } }
    }
    Component { id: galleryFace
        Row { spacing: 6; y: 7
            Repeater { model: 3
                MiniSurface { required property int index; width: 59; height: 78; radius: 10; clip: true
                    Rectangle { width: 18; height: 18; radius: 9; x: 31; y: 13; color: root.accent; opacity: .55 }
                    Rectangle { width: 67; height: 58; x: -15; y: 49-index*5; rotation: -32; radius: 9; color: root.accent; opacity: .35 }
                    Rectangle { width: 50; height: 48; x: 27; y: 48+index*4; rotation: 34; radius: 8; color: root.accent; opacity: .22 }
                }
            }
        }
    }
    Component { id: systemFace
        MiniSurface {
            width: 180; height: 92
            Column { x: 13; y: 13; spacing: 9
                Repeater { model: ["CPU", "RAM", "SSD"]
                    Row { required property string modelData; required property int index; spacing: 10
                        Text { width: 28; text: parent.modelData; color: root.soft; font.family: root.theme.bodyFont; font.pixelSize: 9 }
                        Rectangle { y: 4; width: 100; height: 5; radius: 3; color: root.theme.borderSubtle
                            Rectangle { width: [36,64,48][index]; height: 5; radius: 3; color: root.accent }
                        }
                    }
                }
            }
        }
    }
    Component { id: visualizerFace
        Item {
            Row { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 18; spacing: 3
                Repeater { model: 27
                    Rectangle { required property int index; width: 4
                        height: 8 + 48*Math.pow(Math.sin((index+2)*.27),2)
                        y: 60-height; radius: root.visualizerMode === "wave" ? 3 : 0
                        color: root.accent; opacity: .4+.6*Math.sin((index+1)/29*Math.PI)
                    }
                }
            }
            Rectangle { x: 8; y: 80; width: 174; height: 2; radius: 1; color: root.accent; opacity: .5 }
        }
    }
    Component { id: frameFace
        MiniSurface { width: 182; height: 90; radius: 10
            Rectangle { anchors.fill: parent; anchors.margins: 7; radius: 6; color: "transparent"; border.color: root.accent; border.width: 2; opacity: .65 }
            Rectangle { x: 13; y: 13; width: 14; height: 64; radius: 5; color: root.accent; opacity: .35 }
            Rectangle { x: 40; y: 42; width: 108; height: 38; radius: 9; color: root.accent; opacity: .22 }
        }
    }
}
