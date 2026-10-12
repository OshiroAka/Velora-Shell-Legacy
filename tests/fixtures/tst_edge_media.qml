import QtQuick
import QtQuick.Controls
import QtTest
import "../../components" as Components
Item { id: fixture; width: 500; height: 1100
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

Components.VeloraEdgeMediaPanel { id: panel; width: 400; height: 1050; media: media; library: library; theme: palette }
Components.VeloraEdgeApps { id: apps; x: 410; width: 56; height: 164 }
SignalSpy { id: openSpy; target: apps; signalName: "spotifyRequested" }
SignalSpy { id: closeSpy; target: panel; signalName: "closeRequested" }
TestCase {
 name: "EdgeMedia"; when: windowShown
 function init() { panel.lyrics=false; media.playing=true; media.canNext=true; media.skips=0; panel.forceActiveFocus(); wait(100) }
 function test_transport() {
   mouseClick(findChild(panel,"edgeMediaPlay")); compare(media.playing,false)
   mouseClick(findChild(panel,"edgeMediaNext")); compare(media.skips,1)
   mouseClick(findChild(panel,"edgeMediaPrevious")); compare(media.skips,0)
   media.canNext=false; mouseClick(findChild(panel,"edgeMediaNext")); compare(media.skips,0)
 }
 function test_seek_search_lyrics() {
   const seek=findChild(panel,"edgeMediaSeek")
   mousePress(seek,seek.width*.2,seek.height/2)
   mouseMove(seek,seek.width*.7,seek.height/2,20)
   const val=seek.value; media.sampledPosition=2; fuzzyCompare(seek.value,val,.1)
   mouseRelease(seek,seek.width*.7,seek.height/2)
   verify(media.seeked>120)
   const search=findChild(panel,"edgeMediaSearch")
   mouseClick(search); keyClick(Qt.Key_A); keyClick(Qt.Key_B); compare(library.query,"ab")
   compare(library.page,"search"); keyClick(Qt.Key_Return); compare(library.searches,1)
   panel.lyrics=true; library.page="lyrics"; wait(400)
   compare(findChild(panel,"edgeLyrics").count,6)
   const lineView=findChild(panel,"edgeLyrics")
   lineView.positionViewAtIndex(2,ListView.Center); wait(400)
   const words=findChild(panel,"edgeLyricWords2")
   verify(words); const previousX=words.x
   compare(words.font.family,"Liberation Serif")
   tryCompare(words.parent,"glow",1)
   const startY=lineView.contentY
   library.activeLine=3
   const slide=findChild(panel,"edgeLyricsSlide")
   verify(slide.running,"Synced verses must animate instead of jumping")
   wait(100)
   verify(Math.abs(lineView.contentY-startY)<Math.abs(slide.to-startY),"Scroll starts between the old and new verse")
   tryCompare(words.parent,"glow",0)
   tryCompare(findChild(panel,"edgeLyricWords3").parent,"glow",1)
   tryCompare(slide,"running",false)
   fuzzyCompare(lineView.contentY,slide.to,.01)
   library.activeLine=2
   wait(100)
   panel.reducedMotion=true
   compare(slide.running,false)
   panel.following=false; lineView.contentY += 130; wait(60)
   verify(Math.abs(words.x-previousX)>1,"Verse center follows the contour while scrolling")
   panel.reducedMotion=true; library.activeLine=4; wait(50)
   verify(findChild(panel,"edgeLyrics").visible)
   panel.forceActiveFocus(); keyClick(Qt.Key_Escape); compare(closeSpy.count,1)
 }
 function test_apps() {
   const spotify=findChild(apps,"edgeAppSpotify"), discord=findChild(apps,"edgeAppDiscord")
   mouseMove(spotify,22,22); tryCompare(spotify,"emphasis",1)
   mouseClick(spotify); compare(openSpy.count,1)
   mouseClick(discord); compare(openSpy.count,1)
   mouseMove(fixture,490,1090); tryCompare(spotify,"emphasis",0)
   spotify.forceActiveFocus(); keyClick(Qt.Key_Return); compare(openSpy.count,2)
   keyClick(Qt.Key_Tab); compare(discord.activeFocus,true)
   discord.focus=false; apps.reducedMotion=true; wait(220)
   mouseMove(spotify,22,22); compare(spotify.emphasis,1)
 }
}
}
