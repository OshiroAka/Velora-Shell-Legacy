import QtQuick
import QtQuick.Shapes

// The bottom edge is open: the surface joins the desktop frame rather than
// drawing a rounded window floating above it. Shape geometry changes only
// during presentation/resizing; no Canvas, render loop or offscreen layer.
Shape {
    id: root
    property color tint: "#99162028"
    property color rim: "#558eb9ca"
    property real join: Math.min(42, width*.04, height*.3)
    property real corner: Math.min(24, height*.3)
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    ShapePath {
        fillColor: root.tint
        strokeColor: "transparent"
        startX: 0; startY: root.height
        PathQuad { x: root.join; y: root.height-root.join; controlX: root.join; controlY: root.height }
        PathLine { x: root.join; y: root.corner }
        PathQuad { x: root.join+root.corner; y: 0; controlX: root.join; controlY: 0 }
        PathLine { x: root.width-root.join-root.corner; y: 0 }
        PathQuad { x: root.width-root.join; y: root.corner; controlX: root.width-root.join; controlY: 0 }
        PathLine { x: root.width-root.join; y: root.height-root.join }
        PathQuad { x: root.width; y: root.height; controlX: root.width-root.join; controlY: root.height }
        PathLine { x: 0; y: root.height }
    }
    ShapePath {
        fillColor: "transparent"; strokeColor: root.rim; strokeWidth: 1
        startX: 0; startY: root.height-.5
        PathQuad { x: root.join; y: root.height-root.join; controlX: root.join; controlY: root.height }
        PathLine { x: root.join; y: root.corner }
        PathQuad { x: root.join+root.corner; y: .5; controlX: root.join; controlY: .5 }
        PathLine { x: root.width-root.join-root.corner; y: .5 }
        PathQuad { x: root.width-root.join; y: root.corner; controlX: root.width-root.join; controlY: .5 }
        PathLine { x: root.width-root.join; y: root.height-root.join }
        PathQuad { x: root.width; y: root.height-.5; controlX: root.width-root.join; controlY: root.height }
    }
}
