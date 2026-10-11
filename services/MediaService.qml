pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Scope {
    id: root

    property bool active: false
    property bool detailActive: false
    property string preferredPlayer: ""
    property int playersRevision: 0
    property real sampledPosition: 0
    // Transport intent lets the visual stack distinguish a forward skip from
    // returning to the previous song. MPRIS metadata itself has no direction.
    property int transportDirection: 0
    property double transportRequestedAt: 0
    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME")
        || homeDir + "/.config"
    readonly property string historyPath: configHome
        + "/velora-shell/media-history.json"
    readonly property string cacheHome: Quickshell.env("XDG_CACHE_HOME")
    || homeDir + "/.cache"

readonly property string spotifyQueuePath:
    cacheHome + "/velora-shell/spotify-queue.json"

property var spotifyQueue: []
property var spotifyCurrent: null
property string spotifyQueueRevision: ""

readonly property bool spotifyQueueAvailable:
    spotifyQueue.length > 0
        && identity.toLowerCase().indexOf("spotify") >= 0

readonly property int spotifyQueueCount:
    spotifyQueue.length
    property var historyEntries: []
    readonly property var players: Mpris.players.values
    readonly property var player: choosePlayer(playersRevision, players.length, preferredPlayer)

    readonly property bool hasPlayer: player !== null
    readonly property string identity: player ? String(player.identity || "") : ""
    readonly property string title: player && String(player.trackTitle || "").length
        ? String(player.trackTitle) : "Nada tocando"
    readonly property string artist: player && String(player.trackArtist || "").length
        ? String(player.trackArtist) : ""
    readonly property string artUrl: player ? String(player.trackArtUrl || "") : ""
    readonly property string album: player ? String(player.trackAlbum || "") : ""
    readonly property string trackKey: player ? player.dbusName + "|" + title + "|" + artist + "|" + album : ""
    readonly property bool playing: player ? Boolean(player.isPlaying) : false
    readonly property bool canToggle: player ? Boolean(player.canTogglePlaying) : false
    readonly property bool canNext: player ? Boolean(player.canGoNext) : false
    readonly property bool canPrevious: player ? Boolean(player.canGoPrevious) : false
    readonly property bool canSeek: player ? Boolean(player.canSeek && player.positionSupported) && length > 0 : false
    readonly property bool canShuffle: player ? Boolean(player.shuffleSupported) : false
    readonly property bool shuffled: player ? Boolean(player.shuffle) : false
    readonly property bool canRepeat: player ? Boolean(player.loopSupported) : false
    readonly property int repeatMode: player ? Number(player.loopState) : 0
    readonly property real length: player ? Number(player.length || 0) : 0
    readonly property real progress: length > 0
        ? Math.max(0, Math.min(1, sampledPosition / length)) : 0

    function score(candidate) {
        if (!candidate)
            return -1
        // Browser MPRIS objects can survive after their media tab has closed.
        if (!String(candidate.trackTitle || "").trim().length)
            return -1
        let result = candidate.isPlaying ? 100 : 0
        if (String(candidate.identity || "").toLowerCase().includes("spotify"))
            result += 15
        if (String(candidate.trackTitle || "").length)
            result += 20
        if (String(candidate.trackArtist || "").length)
            result += 10
        return result
    }

    function choosePlayer(revision, count, preferred) {
        revision
        count
        const available = Mpris.players.values
        if (!available || available.length === 0)
            return null
        let best = null
        let bestScore = -1
        for (let index = 0; index < available.length; index += 1) {
            const candidateScore = score(available[index])
            if (candidateScore >= 0 && available[index].dbusName === preferred)
                return available[index]
            if (candidateScore > bestScore) {
                best = available[index]
                bestScore = candidateScore
            }
        }
        return best
    }

    function seekTo(seconds) {
        if (!canSeek || !Number.isFinite(seconds)) return false
        player.position = Math.max(0, Math.min(length, seconds))
        sampledPosition = Math.max(0, Math.min(length, seconds))
        return true
    }
    function toggleShuffle() { if (canShuffle) player.shuffle = !player.shuffle }
    function cycleRepeat() { if (canRepeat) player.loopState = (repeatMode + 1) % 3 }
    function openSpotify(query) {
        Quickshell.execDetached(["xdg-open", query ? "spotify:search:" + encodeURIComponent(String(query)) : "spotify:"])
    }
    function playTrack(uri) {
        if (!/^spotify:track:[a-zA-Z0-9]+$/.test(String(uri || ""))) return false
        const spotify = players.find(p => String(p.identity || "").toLowerCase().includes("spotify"))
        if (spotify) { preferredPlayer = spotify.dbusName; spotify.openUri(uri) }
        else Quickshell.execDetached(["xdg-open", uri])
        return true
    }

    function togglePlaying() {
        if (!canToggle)
            return false
        player.togglePlaying()
        return true
    }

    function previous() {
        if (!canPrevious)
            return false
        transportDirection = -1
        transportRequestedAt = Date.now()
        player.previous()
        return true
    }

    function next() {
        if (!canNext)
            return false
        transportDirection = 1
        transportRequestedAt = Date.now()
        player.next()
        return true
    }

    function clearTransportIntent() {
        transportDirection = 0
        transportRequestedAt = 0
    }

    function refreshPosition() {
        sampledPosition = player ? Number(player.position || 0) : 0
    }

    function recordHistory(key, title, artist, art) {
        const normalizedKey = String(key || "")
        const normalizedArt = String(art || "")
        if (!normalizedKey.length || !normalizedArt.length)
            return false
        const next = [{
            key: normalizedKey,
            title: String(title || ""),
            artist: String(artist || ""),
            art: normalizedArt
        }]
        for (let index = 0; index < historyEntries.length && next.length < 3; index += 1) {
            const entry = historyEntries[index] || ({})
            if (String(entry.key || "") !== normalizedKey
                    && String(entry.art || "").length)
                next.push(entry)
        }
        historyEntries = next
        historySave.restart()
        return true
    }

    function loadHistory(text) {
        try {
            const document = JSON.parse(text || "{}")
            const entries = Array.isArray(document.entries) ? document.entries : []
            const normalized = entries.filter(entry => entry
                && typeof entry === "object" && String(entry.art || "").length).slice(0, 3)
            if (JSON.stringify(normalized) !== JSON.stringify(historyEntries))
                historyEntries = normalized
        } catch (parseError) {
            console.warn("Ignoring invalid media history:", String(parseError))
            historyEntries = []
        }
    }

    onPlayerChanged: refreshPosition()
    onTrackKeyChanged: refreshPosition()
    onDetailActiveChanged: refreshPosition()

    Instantiator {
        model: root.players
        delegate: QtObject {
            id: observer
            required property var modelData
            property var playerObserver: Connections {
                target: observer.modelData
                function onIsPlayingChanged() { root.playersRevision += 1 }
                function onTrackTitleChanged() { root.playersRevision += 1 }
            }
        }
    }
    Connections {
        target: root.player
        function onPositionChanged() { root.refreshPosition() }
    }

    Connections {
        target: Mpris.players
        function onValuesChanged() { root.playersRevision += 1 }
    }

    Timer {
        // The preview does not need a video-rate progress clock. A five-second
        // cadence keeps the card current without waking the render path every
        // second while the glass scene is idle.
        interval: root.detailActive ? 250 : 5000
        repeat: true
        running: root.active && root.playing
        onTriggered: root.refreshPosition()
    }

    function loadSpotifyQueue(text) {
    try {
        const document = JSON.parse(text || "{}")

        spotifyQueue = Array.isArray(document.next)
            ? document.next.filter(entry =>
                entry && typeof entry === "object")
            : []

        spotifyCurrent =
            document.current
            && typeof document.current === "object"
                ? document.current
                : null

        spotifyQueueRevision =
            String(document.revision || "")

    } catch (error) {
        console.warn(
            "Ignoring invalid Spotify queue:",
            String(error)
        )

        spotifyQueue = []
        spotifyCurrent = null
        spotifyQueueRevision = ""
    }
}

FileView {
    id: spotifyQueueFile

    path: root.spotifyQueuePath
    watchChanges: true
    printErrors: false

    onLoaded:
        root.loadSpotifyQueue(text())

    onFileChanged:
        reload()

    onLoadFailed: function(errorCode) {
        if (errorCode === FileViewError.FileNotFound) {
            root.spotifyQueue = []
            root.spotifyCurrent = null
            root.spotifyQueueRevision = ""
        }
    }
}
    FileView {
        id: historyFile
        path: root.historyPath
        atomicWrites: true
        watchChanges: true
        printErrors: false
        onLoaded: root.loadHistory(text())
        onFileChanged: reload()
        onLoadFailed: function(errorCode) {
            if (errorCode === FileViewError.FileNotFound)
                root.historyEntries = []
        }
    }

    Timer {
        id: historySave
        interval: 180
        repeat: false
        onTriggered: historyFile.setText(JSON.stringify({
            version: 1,
            entries: root.historyEntries
        }, null, 2) + "\n")
    }
}
