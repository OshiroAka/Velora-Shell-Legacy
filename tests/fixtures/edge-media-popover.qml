import QtQuick
import QtQuick.Controls
import QtTest
import QtQuick.Window
import Quickshell
import "../../components" as Components
ShellRoot { id: fixture
    property string activeRailControl: ""
    property string quickPopupType: ""
    QtObject { id: otherPopover; function close() {} }
    // SHELL_CONTROL_HANDLERS
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
        property bool spotifyPlaying: true
        property bool detailActive: false
        property string trackKey: ""
        property int selections: 0
        function selectSpotify() { selections++ }
        property bool canVolume: true
        property real volume: .6
        property var players: []
        property var player: null
        function setVolume(v) { volume = v }
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


Window { id: win; width: 500; height: 1100; visible: true
Components.VeloraEdgePopover { id: edge; width: 500; height: 1100; railWidth: 4; anchorY: 550; media: media; theme: palette }
TestCase {
 id: test; name: "EdgePopover"; when: false
 function test_morph_lyrics_lifecycle() {
    edge.triggerHovered=true; tryCompare(edge,"opened",true)
    tryCompare(edge,"contentReveal",1)
    compare(edge.bodyWidth,56)
    const spotify=findChild(edge,"edgeAppSpotify")
    verify(spotify)
    mouseMove(spotify,22,22)
    tryCompare(edge,"labelReveal",1)
    tryCompare(edge,"labelContent",1)
    const label=findChild(edge,"edgeLyricsButton")
    mouseMove(label,40,22); wait(300); compare(edge.labelReveal,1)
    mouseClick(label,40,22)
    tryCompare(edge,"page","lyrics")
    tryCompare(edge,"bodyHeight",1100)
    tryCompare(edge,"contentReveal",1)
    compare(edge.bodyY,0); compare(edge.bodyWidth,400); compare(edge.closeOnLeave,false)
    verify(media.selections>0); compare(media.detailActive,true); compare(edge.mediaPanelActive,true)
    edge.showPage("media"); tryCompare(edge,"page","media"); tryCompare(edge,"contentReveal",1)
    compare(edge.bodyY,0); compare(edge.bodyHeight,1100)
    verify(edge.dockProgress > 0 && edge.dockProgress < 1,"Dock is still morphing after menu entry")
    tryCompare(edge,"dockProgress",1,3000)
    const retainedCurve=JSON.stringify(edge.sidebarSamples)
    const exitingContour=JSON.stringify(edge.contourSamples)
    edge.close()
    compare(edge.bodyHeight,1100); compare(edge.bodyY,0)
    wait(100)
    compare(edge.bodyWidth,400)
    verify(edge.contentReveal < 1 && edge.contentReveal > 0,"Content fades before surface retracts")
    compare(JSON.stringify(edge.contourSamples),exitingContour)
    wait(200)
    verify(edge.mounted && edge.bodyWidth > 300 && edge.bodyWidth < 400,"Slow surface exit retains its intermediate pose")
    verify(edge.dockProgress > .8 && edge.dockProgress < 1,"Undocking starts with panel exit")
    compare(JSON.stringify(edge.sidebarSamples),retainedCurve)
    edge.open(); edge.showPage("media"); tryCompare(edge,"contentReveal",1)
    verify(edge.sidebarWaveScale > 0)
    fixture.activeRailControl="volume"; fixture.onActiveRailControlChanged()
    compare(edge.opened,true)
    fixture.activeRailControl="brightness"; fixture.onActiveRailControlChanged()
    compare(edge.opened,true)
    fixture.quickPopupType="volume"; fixture.onQuickPopupTypeChanged()
    compare(edge.opened,true)
    fixture.quickPopupType="brightness"; fixture.onQuickPopupTypeChanged()
    compare(edge.opened,true)
    verify(!edge.keepOpenForControl("battery"))
    edge.triggerHovered=false
    mouseMove(win.contentItem,10,1000)
    edge.close()
    wait(250)
    const intermediateWidth=edge.bodyWidth
    edge.close() // Repeated requests must not restart the content delay.
    wait(250)
    verify(edge.bodyWidth < intermediateWidth,"Repeated close continues retracting")
    tryCompare(edge,"mounted",false,1200)
    tryCompare(edge,"dockProgress",0,3000)
    edge.open(); edge.showPage("lyrics"); tryCompare(edge,"contentReveal",1)
    edge.motion.reduced=true
    edge.close(); compare(edge.mounted,false); compare(media.detailActive,false)
    compare(edge.page,"apps"); compare(edge.mediaPanelActive,false)
    compare(edge.sidebarWaveScale,0)
    edge.open(); edge.triggerHovered=false
    media.spotifyPlaying=false; edge.spotifyHovered=true; wait(400)
    compare(edge.labelReveal,0)
    edge.close(); compare(edge.mounted,false)
 }
}
}

 Timer { interval: 250; running: true; onTriggered: {
   try { test.test_morph_lyrics_lifecycle(); console.info("EDGE_POPOVER_OK") }
   catch(e) { console.error("EDGE_POPOVER_FAILED", String(e)) }
   Qt.quit()
 } }
}
