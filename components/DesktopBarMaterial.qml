import QtQuick
import Quickshell
import "../platform" as Platform

// Publish only the latest audio frame, at most 30 times/s. The compositor
// shades the union of the frame and peaks once, with one tint and backdrop.
QtObject {
    id: root
    required property string monitorName
    required property var composition
    property bool enabled: true
    readonly property bool supported: Platform.NativeBlur.supportsBarMaterial(composition.audioVisualizer)
    readonly property bool spectrumEnabled: enabled && composition.desktopVisualizerVisible
    readonly property color tint: composition.unifiedBarSurface
    readonly property string style: [composition.barMaterial === "solid" ? 0
        : composition.barMaterial === "glass" ? 1 : 2,
        tint.r, tint.g, tint.b, tint.a, composition.barBlurEnabled ? 1 : 0,
        spectrumEnabled ? 1 : 0].join(" ")
    property bool dirty: true
    property string lastMessage: ""
    onStyleChanged: dirty = true
    onSupportedChanged: dirty = true
    property int revision: Platform.NativeBlur.revision
    onRevisionChanged: { lastMessage = ""; dirty = true }
    function sync() {
        if (!supported || !composition.audioVisualizer) return
        const message = "velora-blur:desktop-bar-material "
            + monitorName + " " + style
            + composition.audioVisualizer.materialFrame()
        if (message !== lastMessage) {
            Platform.NativeBlur.dispatch(message)
            lastMessage = message
        }
        dirty = false
    }
    property Connections samples: Connections {
        target: root.composition.audioVisualizer
        function onBandsChanged() { if (root.spectrumEnabled) root.dirty = true }
    }
    property Timer publish: Timer {
        interval: 33
        running: root.supported && root.dirty
        repeat: true
        onTriggered: root.sync()
    }
    Component.onDestruction: Platform.NativeBlur.dispatch(
        "velora-blur:desktop-bar-material " + monitorName + " -1")
}
