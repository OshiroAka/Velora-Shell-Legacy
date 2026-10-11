import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    required property var media
    property bool active: false
    property string page: "lyrics"
    property string query: ""
    property var lines: []
    property bool synced: false
    property string lyricsState: "idle"
    property string loadedTrack: ""
    property string requestedTrack: ""
    property var results: []
    property string searchState: "idle"
    property string requestedQuery: ""
    readonly property string trackKey: media ? String(media.trackKey || "") : ""
    readonly property string helper: decodeURIComponent(Qt.resolvedUrl("../scripts/velora-media-library").toString().replace("file://", ""))
    readonly property int activeLine: {
        if (!synced || !media) return -1
        const position = media.sampledPosition + 0.12
        let index = -1
        for (let i = 0; i < lines.length; i++) {
            if (Number(lines[i].time) > position) break
            index = i
        }
        return index
    }

    function artwork(url) {
        const value = String(url || "")
        return value.startsWith("spotify:image:") ? "https://i.scdn.co/image/" + value.substring(14) : value
    }
    function fetchLyrics() {
        if (!active || page !== "lyrics" || lyricsProcess.running || !trackKey || loadedTrack === trackKey) return
        requestedTrack = trackKey
        lyricsState = "loading"
        lyricsProcess.command = ["python3", helper, "lyrics", JSON.stringify({
            title: media.title, artist: media.artist, album: media.album, duration: media.length
        })]
        lyricsProcess.running = true
    }
    function acceptLyrics(text) {
        if (!active || requestedTrack !== trackKey) return
        try {
            const data = JSON.parse(text)
            lines = Array.isArray(data.lines) ? data.lines : []
            synced = data.synced === true
            loadedTrack = requestedTrack
            lyricsState = data.ok ? "ready" : (data.reason === "fetch-failed" ? "error" : "empty")
        } catch (_) { lyricsState = "error" }
    }
    function retryLyrics() { loadedTrack = ""; fetchLyrics() }
    function search() {
        if (!active || page !== "search" || query.trim().length < 2 || searchProcess.running) return
        requestedQuery = query.trim()
        searchState = "loading"
        searchProcess.command = ["python3", helper, "search", requestedQuery]
        searchProcess.running = true
    }
    function acceptSearch(text) {
        if (!active || requestedQuery !== query.trim()) return
        try {
            const data = JSON.parse(text)
            results = Array.isArray(data.tracks) ? data.tracks : []
            searchState = data.ok ? (results.length ? "ready" : "empty") : (data.reason === "spotify-offline" ? "offline" : "error")
        } catch (_) { searchState = "error" }
    }
    onTrackKeyChanged: {
        lines = []; synced = false; loadedTrack = ""; lyricsState = "idle"
        lyricsDelay.restart()
    }
    onActiveChanged: {
        if (media) media.detailActive = active
        if (active) { lyricsDelay.restart(); if (query.trim().length > 1) searchDelay.restart() }
        else { lyricsDelay.stop(); searchDelay.stop(); lyricsProcess.running = false; searchProcess.running = false }
    }
    onPageChanged: { lyricsDelay.restart(); if (page === "search" && query.trim().length > 1) searchDelay.restart() }
    onQueryChanged: {
        results = []
        searchState = query.trim().length > 1 ? "loading" : "idle"
        searchDelay.restart()
    }
    Component.onDestruction: if (media) media.detailActive = false
    Timer { id: lyricsDelay; interval: 160; onTriggered: root.fetchLyrics() }
    Timer { id: searchDelay; interval: 360; onTriggered: root.search() }
    Process {
        id: lyricsProcess
        stdout: StdioCollector { onStreamFinished: root.acceptLyrics(text) }
        onExited: function() { if (root.active && root.requestedTrack !== root.trackKey) lyricsDelay.restart() }
    }
    Process {
        id: searchProcess
        stdout: StdioCollector { onStreamFinished: root.acceptSearch(text) }
        onExited: function() { if (root.active && root.requestedQuery !== root.query.trim()) searchDelay.restart() }
    }
}
