import QtQuick
import QtQuick.Controls
import QtTest
import "../../components" as Components

Item {
    id: fixture
    width: 1000; height: 720
    Rectangle { anchors.fill: parent; color: "#101317" }
    Rectangle { x: 0; y: 0; width: 64; height: parent.height; color: "#25252d" }
    Rectangle { x: 55; y: 30; width: 920; height: 650; radius: 18; color: "#25252d"; border.color: "#4a4350" }
    QtObject {
        id: palette
        property color textPrimary: "#f5f0f7"
        property color textSecondary: "#bcb2c4"
        property color accent: "#d9c0f3"
        property color accentSoft: "#d9c0f3"
        property color danger: "#ff9999"
        property string bodyFont: "Poppins"
        function withAlpha(c, a) { return Qt.rgba(c.r,c.g,c.b,a) }
    }
    QtObject {
        id: media
        property bool hasPlayer: true
        property string title: "Luz de outubro"
        property string artist: "Velora Sessions"
        property string album: "October Sessions · 2026"
        property string identity: "Spotify"
        property string artUrl: Qt.resolvedUrl("../../assets/dashboard-cover.svg").toString()
        property bool playing: true
        property bool canSeek: true
        property bool canToggle: true
        property bool canPrevious: true
        property bool canNext: true
        property bool canShuffle: true
        property bool shuffled: false
        property bool canRepeat: true
        property int repeatMode: 0
        property real length: 215
        property real sampledPosition: 74
        property int skips: 0
        property real seeked: -1
        property string launched: ""
        property string played: ""
        property bool spotifyQueueAvailable: true
        property var spotifyQueue: [{title:"Depois da chuva",artist:"Velora Sessions",uri:"spotify:track:test123",art:artUrl},{title:"Cidade devagar",artist:"Velora Sessions",uri:"spotify:track:test456",art:artUrl}]
        function togglePlaying() { playing = !playing }
        function next() { skips++ }
        function previous() { skips-- }
        function seekTo(value) { seeked = value; sampledPosition = value }
        function toggleShuffle() { shuffled = !shuffled }
        function cycleRepeat() { repeatMode = (repeatMode + 1) % 3 }
        function openSpotify(query) { launched = query || "spotify:" }
        function playTrack(uri) { played = uri }
    }
    QtObject {
        id: library
        property string page: "lyrics"
        property string query: ""
        property int searches: 0
        property string lyricsState: "ready"
        property bool synced: true
        property int activeLine: 2
        property string searchState: "idle"
        property var results: []
        // Original fixture text, not song lyrics.
        property var lines: [ {time:0,text:"A cidade acorda devagar"},{time:30,text:"O céu muda de cor"},{time:60,text:"Deixa o mundo lá fora"},{time:90,text:"Hoje o tempo é nosso"},{time:120,text:"E a música fica"},{time:150,text:"Até o último raio de sol"} ]
        function search() { searches++ }
        function retryLyrics() {}
    }
    Components.VeloraMediaPanel { id: panel; x: 79; y: 54; width: 872; height: 602; media: media; library: library; theme: palette }
    SignalSpy { id: closeSpy; target: panel; signalName: "closeRequested" }
    TestCase {
        name: "MediaPanel"
        when: windowShown
        function init() {
            library.page = "lyrics"; library.query = ""; library.results = []; library.searchState = "idle"
            media.hasPlayer = true; media.canNext = true; media.skips = 0; media.playing = true; media.seeked = -1
            panel.forceActiveFocus(); wait(220)
        }
        function test_transport_and_capabilities() {
            mouseClick(findChild(panel,"mediaPlay")); compare(media.playing,false)
            mouseClick(findChild(panel,"mediaNext")); compare(media.skips,1)
            mouseClick(findChild(panel,"mediaPrevious")); compare(media.skips,0)
            media.canNext = false; mouseClick(findChild(panel,"mediaNext")); compare(media.skips,0)
        }
        function test_seek_commits_and_stays_local_during_drag() {
            const slider = findChild(panel,"mediaSeek")
            mousePress(slider,slider.width*.25,slider.height/2)
            mouseMove(slider,slider.width*.7,slider.height/2,20)
            verify(slider.pressed)
            const dragged = slider.value
            media.sampledPosition = 2
            fuzzyCompare(slider.value,dragged,.1)
            mouseRelease(slider,slider.width*.7,slider.height/2)
            verify(media.seeked > 120 && media.seeked < 180)
        }
        function test_search_keyboard_and_escape() {
            mouseClick(findChild(panel,"mediaTab_search")); wait(220)
            const field = findChild(panel,"mediaSearch")
            verify(field.activeFocus)
            keyClick(Qt.Key_M); keyClick(Qt.Key_U); keyClick(Qt.Key_S); keyClick(Qt.Key_E)
            compare(library.query,"muse"); verify(panel.interactionHeld)
            keyClick(Qt.Key_Return); compare(library.searches,1)
            closeSpy.clear(); keyClick(Qt.Key_Escape); compare(closeSpy.count,1)
        }
        function test_empty_player_and_preview() {
            media.hasPlayer=false
            mouseClick(findChild(panel,"mediaPlay")); compare(media.launched,"spotify:")
            media.hasPlayer=true
            const artwork=findChild(panel,"mediaArtwork")
            tryCompare(artwork,"ready",true,3000)
            verify(artwork.width >= 250)
            panel.following=true; panel.followLine(); wait(550)
            let saved=false
            fixture.grabToImage(result => { saved=result.saveToFile("/tmp/velora-media-preview.png") })
            tryVerify(() => saved,3000)
        }
        function test_tabs_and_motion() {
            mouseClick(findChild(panel,"mediaTab_queue")); wait(240); compare(library.page,"queue")
            mouseClick(findChild(panel,"mediaTab_lyrics")); wait(240); compare(library.page,"lyrics")
            library.activeLine = 4; wait(400)
            const view=findChild(panel,"mediaLyrics"); verify(view.contentY > 0)
            panel.animated=false; panel.setPage("search"); wait(10)
            verify(findChild(panel,"mediaSearch").activeFocus)
            panel.animated=true
        }
    }
}
