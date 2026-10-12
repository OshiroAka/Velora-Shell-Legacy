import QtQuick
import "EdgeMediaContours.js" as Contours

// One consumer of the shared FFT. Lyrics use timestamps, never audio levels.
QtObject {
    id: root
    property var analyzer: null
    property bool active: false
    property bool reducedMotion: false
    property bool playing: false
    property string page: "apps"
    property real contour: 0
    property bool synced: false
    property var lines: []
    property int activeLine: -1
    property real position: 0
    property real duration: 0
    readonly property bool spectrumActive: active && !reducedMotion && playing && page === "media"
    readonly property bool lyricsActive: active && !reducedMotion && synced && activeLine >= 0 && page === "lyrics"
    readonly property real lyricTarget: {
        if (!lyricsActive || activeLine >= lines.length) return 0
        const start = Number(lines[activeLine].time)
        const end = activeLine + 1 < lines.length ? Number(lines[activeLine + 1].time) : duration
        const progress = end > start ? Math.max(0, Math.min(1, (position + .12 - start) / (end - start))) : 0
        return activeLine + progress
    }
    property real lyricPhase: lyricTarget
    Behavior on lyricPhase {
        enabled: root.lyricsActive && root.playing
        NumberAnimation { duration: 240; easing.type: Easing.Linear }
    }
    property var levels: Array(21).fill(0)
    property bool dirty: false
    property bool settling: false
    readonly property var samples: Contours.animatedSamples(contour, levels,
        lyricPhase, lyricsActive)

    function resetSpectrum() {
        dirty = false; settling = false
        levels = Array(21).fill(0)
    }
    onSpectrumActiveChanged: {
        if (spectrumActive) dirty = true
        else resetSpectrum()
    }
    onAnalyzerChanged: if (spectrumActive) dirty = true
    function updateSpectrum() {
        const frame = analyzer && analyzer.running && typeof analyzer.materialFrame === "function"
            ? String(analyzer.materialFrame()).trim().split(/\s+/).map(Number) : []
        const target = Contours.audioLevels(frame)
        let moving = false
        const next = target.map((value, i) => {
            const previous = levels[i] || 0
            const delta = value - previous
            if (Math.abs(delta) < .002) return value
            moving = true
            return previous + delta * (delta > 0 ? .48 : .18)
        })
        dirty = false; settling = moving
        if (next.some((value, i) => value !== levels[i])) levels = next
    }
    property Connections audioChanges: Connections {
        target: root.spectrumActive ? root.analyzer : null
        function onBandsChanged() { root.dirty = true }
        function onRunningChanged() { root.dirty = true }
    }
    property Timer sampleClock: Timer {
        interval: 33; repeat: true
        running: root.spectrumActive && (root.dirty || root.settling)
        onTriggered: root.updateSpectrum()
    }
}
