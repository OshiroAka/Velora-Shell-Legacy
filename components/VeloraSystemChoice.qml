import QtQuick
import QtQuick.Controls

// Symbolic previews: these show the effect of a choice, never live measurements.
Button {
    id: root
    required property string choice
    property bool monitorChoice: false
    property bool selected: false
    property bool reducedMotion: false
    property real previewProgress: 1
    function replay() {
        previewMotion.stop()
        if (visible && !reducedMotion) previewMotion.restart()
        else previewProgress = 1
    }
    onVisibleChanged: replay()
    onReducedMotionChanged: replay()
    onSelectedChanged: if (selected) replay()
    onHoveredChanged: if (hovered) replay()
    Component.onCompleted: replay()
    NumberAnimation {
        id: previewMotion; target: root; property: "previewProgress"
        from: 0; to: 1; duration: 360; easing.type: Easing.OutCubic
    }
    property color ink: "white"
    property color accent: ink
    property string uiFont: "sans-serif"
    property string explanation: ""
    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    implicitWidth: 104
    implicitHeight: monitorChoice ? 80 : 92
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    scale: down ? .97 : 1
    Behavior on scale { NumberAnimation { duration: root.reducedMotion ? 0 : 150; easing.type: Easing.OutCubic } }
    Accessible.role: Accessible.RadioButton
    Accessible.name: text
    Accessible.description: explanation
    Accessible.checked: selected
    Keys.onReturnPressed: if (enabled) clicked()
    background: Rectangle {
        radius: 12
        color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, root.selected ? .14 : root.hovered ? .09 : .035)
        border.width: 1
        border.color: root.activeFocus ? root.ink : root.selected ? root.alpha(root.accent, .65) : root.alpha(root.ink, .12)
        Behavior on color { ColorAnimation { duration: root.reducedMotion ? 0 : 160 } }
        Behavior on border.color { ColorAnimation { duration: root.reducedMotion ? 0 : 160 } }
    }
    contentItem: Item {
        opacity: root.enabled ? 1 : .35
        Canvas {
            id: drawing
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.monitorChoice ? 5 : 7
            width: 92
            height: 58
            property color stroke: root.selected ? root.accent : root.ink
            onStrokeChanged: requestPaint()
            Connections {
                target: root
                function onChoiceChanged() { drawing.requestPaint() }
                function onMonitorChoiceChanged() { drawing.requestPaint() }
                function onPreviewProgressChanged() { drawing.requestPaint() }
            }
            onPaint: {
                const c = getContext("2d")
                c.reset()
                c.strokeStyle = stroke; c.fillStyle = stroke
                c.lineWidth = 1.5; c.lineCap = "round"; c.lineJoin = "round"
                function line(x, y, xx, yy) { c.beginPath(); c.moveTo(x,y); c.lineTo(xx,yy); c.stroke() }
                function box(x,y,w,h,r) { c.beginPath(); c.roundedRect(x,y,w,h,r,r); c.stroke() }
                if (root.monitorChoice) {
                    for (let i = 0; i < 2; i++) {
                        const x = 7 + i * 43
                        const off = root.choice === "main" && i === 1
                        c.globalAlpha = off ? .25 : 1
                        box(x, 7, 34, 25, 3)
                        line(x+17,32,x+17,37); line(x+11,37,x+23,37)
                        if (off) {
                            line(x+14,18,x+20,18)
                        } else {
                            // Matching windows mean mirror; one continuous workspace means extend.
                            c.globalAlpha = .17; c.fillRect(x+3,10,28,19); c.globalAlpha = 1
                            if (root.choice === "extend") {
                                box(x + (i === 0 ? 17 : 3) + (1-root.previewProgress) * (i === 0 ? -6 : 6), 14, 13, 13, 1)
                                line(x+4,12,x+10,12)
                            } else {
                                box(x+6,13 + (1-root.previewProgress)*6,15,14,1); line(x+24,14,x+28,14); line(x+24,18,x+28,18)
                            }
                        }
                    }
                    if (root.choice === "extend") {
                        line(35,44,57,44); line(35,44,38,41); line(57,44,54,47)
                    } else if (root.choice === "mirror") {
                        line(42,41,50,41); line(42,45,50,45)
                    }
                } else {
                    const level = root.choice === "power-saver" ? 0 : root.choice === "balanced" ? 1 : 2
                    // A speed dial and an autonomy battery make the trade-off visible.
                    c.globalAlpha = .22
                    c.lineWidth = 3
                    c.beginPath(); c.arc(46,30,24,Math.PI,Math.PI*2); c.stroke()
                    c.globalAlpha = 1
                    c.beginPath(); c.arc(46,30,24,Math.PI,Math.PI*(1 + (.22 + level*.35)*root.previewProgress)); c.stroke()
                    c.lineWidth = 1.5
                    const angle = Math.PI * (1 + (.18 + level*.32)*root.previewProgress)
                    line(46,30,46+Math.cos(angle)*17,30+Math.sin(angle)*17)
                    c.beginPath(); c.arc(46,30,2,0,Math.PI*2); c.fill()
                    if (level === 0) {
                        c.beginPath(); c.moveTo(43,46); c.bezierCurveTo(33,34,51,34,53,34)
                        c.bezierCurveTo(55,44,48,49,43,46); c.stroke(); line(41,49,49,40)
                    } else if (level === 1) {
                        line(38,39,54,39); line(38,45,54,45)
                    } else {
                        c.beginPath(); c.moveTo(48,34); c.lineTo(40,43); c.lineTo(46,43)
                        c.lineTo(44,51); c.lineTo(53,40); c.lineTo(47,40); c.closePath(); c.stroke()
                    }
                }
            }
        }
        Row {
            visible: !root.monitorChoice
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 5
            spacing: 3
            Rectangle {
                width: 29; height: 11; radius: 2; color: "transparent"
                border.color: root.alpha(root.ink, .5)
                Row {
                    x: 3; y: 3; spacing: 2
                    Repeater {
                        model: 3
                        Rectangle {
                            required property int index
                            width: 6; height: 5; radius: 1
                            color: root.alpha(root.selected ? root.accent : root.ink,
                                index < (root.choice === "power-saver" ? 3 : root.choice === "balanced" ? 2 : 1) ? .9 : .12)
                        }
                    }
                }
                Rectangle { x: 30; y: 3; width: 2; height: 5; radius: 1; color: root.alpha(root.ink, .5) }
            }
        }
        Text {
            visible: root.monitorChoice
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            text: root.text; color: root.ink
            font.family: root.uiFont; font.pixelSize: 11
        }
        Rectangle {
            visible: root.selected
            anchors.right: parent.right; anchors.top: parent.top
            width: 4; height: 4; radius: 2; color: root.accent
        }
    }
}
