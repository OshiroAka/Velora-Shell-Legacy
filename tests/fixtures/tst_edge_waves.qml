import QtQuick
import QtTest
import "../../components" as Components
import "../../services" as Services
import "../../components/EdgeMediaContours.js" as Contours

Item {
    QtObject {
        id: analyzer
        property bool running: true
        property var frame: Array(64).fill(0)
        property int reads: 0
        signal bandsChanged()
        function materialFrame() { reads++; return frame.join(" ") }
    }
    Components.VeloraEdgeWaves {
        id: waves
        analyzer: analyzer
        synced: true
        lines: [{time: 0}, {time: 10}, {time: 20}]
        duration: 30
    }
    Services.VisualizerDemand { id: demand }
    TestCase {
        name: "EdgeWaves"; when: windowShown
        function init() {
            waves.active = false; waves.reducedMotion = false
            waves.page = "media"; waves.contour = 1; waves.playing = true
            waves.activeLine = 0; waves.position = 0
            analyzer.frame = Array(64).fill(0); analyzer.running = true
        }
        function test_audio_response_silence_and_lifecycle() {
            waves.active = true
            const rest = JSON.stringify(waves.samples)
            analyzer.frame = Array(64).fill(.8); analyzer.bandsChanged()
            tryVerify(() => waves.levels[10] > .6)
            verify(JSON.stringify(waves.samples) !== rest)
            // Joins remain fixed and media never reaches the controls.
            fuzzyCompare(waves.samples[0], Contours.samples(1)[0], .00001)
            fuzzyCompare(waves.samples[20], Contours.samples(1)[20], .00001)
            verify(waves.samples.every(v => v >= 0 && v <= .21))
            analyzer.frame = Array(64).fill(0); analyzer.bandsChanged()
            tryCompare(waves, "settling", false, 3000)
            compare(JSON.stringify(waves.samples), rest)
            const reads = analyzer.reads; wait(150); compare(analyzer.reads, reads)
            waves.playing = false; analyzer.bandsChanged(); wait(80)
            compare(analyzer.reads, reads)
            waves.playing = true; waves.active = false
            const closedReads = analyzer.reads
            analyzer.bandsChanged(); wait(100); compare(analyzer.reads, closedReads)
        }
        function test_lyrics_follow_timestamps_not_audio() {
            waves.page = "lyrics"; waves.contour = 2; waves.active = true
            wait(300)
            const first = JSON.stringify(waves.samples), reads = analyzer.reads
            analyzer.frame = Array(64).fill(1); analyzer.bandsChanged(); wait(80)
            compare(JSON.stringify(waves.samples), first); compare(analyzer.reads, reads)
            waves.position = 8; wait(300)
            verify(JSON.stringify(waves.samples) !== first)
            verify(waves.samples.every(v => v >= 0 && v <= .40))
            waves.activeLine = 1; waves.position = 14; wait(300)
            fuzzyCompare(waves.lyricPhase, 1.412, .001)
            waves.playing = false
            const paused = JSON.stringify(waves.samples); wait(300)
            compare(JSON.stringify(waves.samples), paused)
            waves.activeLine = 0; waves.position = 2
            fuzzyCompare(waves.lyricPhase, .212, .001)
            waves.reducedMotion = true
            compare(JSON.stringify(waves.samples), JSON.stringify(Contours.samples(2)))
            waves.reducedMotion = false; waves.synced = false
            compare(JSON.stringify(waves.samples), JSON.stringify(Contours.samples(2)))
            waves.synced = true
        }
        function test_demand_for_menu_with_bottom_hidden() {
            demand.desktopEnabled = false; demand.railVisible = false
            demand.mediaPlaying = true; demand.edgeMediaVisible = true
            compare(demand.active, true)
            demand.edgeMediaVisible = false; compare(demand.active, false)
            demand.edgeMediaVisible = true; demand.mediaPlaying = false
            compare(demand.active, false)
            waves.active = true; waves.reducedMotion = true
            compare(waves.spectrumActive, false)
        }
    }
}
