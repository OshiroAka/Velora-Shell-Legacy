pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "EdgeMediaContours.js" as Contours

Item {
    id: root
    required property var media
    required property var library
    required property var theme
    property bool lyrics: false
    property bool reducedMotion: false
    property bool following: true
    property var contourSamples: Contours.samples(lyrics ? 2 : 1)
    readonly property color ink: theme ? theme.textPrimary : "white"
    readonly property color muted: theme ? theme.textSecondary : "#aeb8bf"
    readonly property string family: theme ? theme.bodyFont : "sans-serif"
    readonly property string lyricsFamily: lyricFont.name || "serif"
    FontLoader { id: lyricFont; source: "../assets/fonts/LiberationSerif-Regular.ttf" }
    readonly property bool hasTrack: !!media && media.hasPlayer
    readonly property real position: Math.max(0, Math.min(media.length || 0, media.sampledPosition || 0))
    readonly property bool interactionHeld: seek.pressed || volume.pressed || search.activeFocus
        || lines.dragging || lines.flicking || tracks.dragging || tracks.flicking || players.popup.visible
    signal backRequested()
    signal lyricsRequested()
    signal mediaRequested()
    signal closeRequested()
    function alpha(c, a) { return Qt.rgba(c.r,c.g,c.b,a) }
    function time(seconds) {
        const s = Math.max(0, Math.floor(seconds || 0))
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }
    function followLine() {
        if (!following || !lyrics || library.activeLine < 0 || lines.dragging || lines.flicking) return
        lyricSlide.stop()
        const start = lines.contentY
        // positionViewAtIndex changes contentY internally and bypasses its
        // Behavior. Measure that destination, then animate the real property.
        lines.positionViewAtIndex(library.activeLine, ListView.Center)
        const destination = lines.contentY
        if (reducedMotion || !visible || Math.abs(destination - start) < .5) return
        lines.contentY = start
        lyricSlide.from = start; lyricSlide.to = destination
        lyricSlide.restart()
    }
    NumberAnimation {
        id: lyricSlide
        objectName: "edgeLyricsSlide"
        target: lines; property: "contentY"
        duration: 900; easing.type: Easing.InOutCubic
    }
    onReducedMotionChanged: if (reducedMotion) lyricSlide.complete()
    onVisibleChanged: if (!visible) lyricSlide.stop()
    onLyricsChanged: if (!lyrics) lyricSlide.stop()
    Connections {
        target: root.library
        function onActiveLineChanged() { root.followLine() }
        function onLinesChanged() { root.following = true; Qt.callLater(root.followLine) }
    }
    Component.onCompleted: Qt.callLater(followLine)
    Keys.onEscapePressed: closeRequested()
    Keys.onSpacePressed: if (hasTrack && media.canToggle) media.togglePlaying()

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: root.lyrics ? 46 : 104; anchors.rightMargin: 24
        anchors.topMargin: 22; anchors.bottomMargin: 26
        spacing: 14
        RowLayout {
            Layout.fillWidth: true; spacing: 6
            Layout.leftMargin: Math.max(0, Contours.offset(root.contourSamples,
                38 / Math.max(1, root.height)) * root.width + 24 - (root.lyrics ? 46 : 104))
            VeloraMaterialIcon { implicitWidth: 23; implicitHeight: 23; iconName: "music"; iconColor: root.ink }
            Text {
                Layout.fillWidth: true; Layout.leftMargin: 5
                text: root.lyrics ? "Lyrics" : "Media"
                color: root.ink; font.family: root.lyrics ? root.lyricsFamily : root.family
                font.pixelSize: root.lyrics ? 23 : 17
            }
            IconButton {
                iconName: root.lyrics ? "music" : "memo"
                hint: root.lyrics ? "Voltar à música" : "Letras da música"
                enabled: root.lyrics || root.media.spotifyPlaying
                onClicked: root.lyrics ? root.mediaRequested() : root.lyricsRequested()
            }
            IconButton { iconName: "close"; hint: "Fechar"; onClicked: root.closeRequested() }
        }
        Rectangle {
            visible: root.lyrics; Layout.fillWidth: true
            Layout.leftMargin: Math.max(0, Contours.offset(root.contourSamples,
                65 / Math.max(1, root.height)) * root.width + 24 - 46)
            implicitHeight: 1; color: root.alpha(root.ink, .12)
        }

        VeloraMediaArtwork {
            visible: !root.lyrics
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(parent.width, 252, Math.max(110, root.height * .24))
            Layout.preferredHeight: Layout.preferredWidth
            source: root.hasTrack ? root.media.artUrl : ""
            radius: 18; ink: root.ink; accent: root.ink; animated: !root.reducedMotion
        }
        ColumnLayout {
            visible: !root.lyrics; Layout.fillWidth: true; spacing: 3
            Text {
                Layout.fillWidth: true
                text: root.hasTrack ? root.media.title : "Seu Spotify, aqui"
                textFormat: Text.PlainText; color: root.ink; font.family: root.family
                font.pixelSize: 22; font.weight: Font.Light
                wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true; text: root.hasTrack ? root.media.artist : "Abra o Spotify para começar."
                textFormat: Text.PlainText; color: root.muted; font.family: root.family; font.pixelSize: 13
                elide: Text.ElideRight
            }
        }

        Item {
            visible: root.lyrics; Layout.fillWidth: true; Layout.fillHeight: true
            ListView {
                id: lines
                objectName: "edgeLyrics"
                anchors.top: parent.top; anchors.bottom: parent.bottom
                anchors.bottomMargin: root.following ? 0 : 34
                x: -46; width: root.width
                clip: true; spacing: 30
                cacheBuffer: height * 2
                model: root.library.lines
                boundsBehavior: Flickable.StopAtBounds
                header: Item { height: lines.height * .28 }
                footer: Item { height: lines.height * .38 }
                onDraggingChanged: if (dragging) { lyricSlide.stop(); root.following = false }
                delegate: Item {
                    id: line
                    required property var modelData
                    required property int index
                    readonly property bool current: root.library.synced && index === root.library.activeLine
                    property real glow: current ? 1 : 0
                    Behavior on glow {
                        NumberAnimation { duration: root.reducedMotion ? 0 : 420; easing.type: Easing.InOutCubic }
                    }
                    readonly property real screenY: lines.mapToItem(root, 0, 0).y
                        + y - lines.contentY + height / 2
                    readonly property real boundary: Contours.offset(root.contourSamples,
                        screenY / Math.max(1, root.height)) * root.width
                    width: lines.width; height: words.implicitHeight + 16
                    Text {
                        id: words
                        objectName: "edgeLyricWords" + line.index
                        // A constant wrapping width keeps the row's height stable
                        // while its center follows the actual surface silhouette.
                        width: Math.max(120, root.width * .60 - 52)
                        x: line.boundary + 24 + (root.width - line.boundary - 48 - width) / 2
                        y: 8
                        text: String(line.modelData.text || ""); textFormat: Text.PlainText
                        color: root.ink; font.family: root.lyricsFamily; font.pixelSize: 26
                        wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter
                        lineHeight: 1.3; opacity: !root.library.synced || line.current ? 1 : .34
                        scale: line.current ? 1 : .93
                        layer.enabled: root.lyrics && root.visible && line.glow > .001
                            && GraphicsInfo.api !== GraphicsInfo.Software
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: root.ink
                            shadowOpacity: line.glow * .9
                            shadowBlur: .75
                            shadowHorizontalOffset: 0
                            shadowVerticalOffset: 0
                        }
                        Behavior on opacity { NumberAnimation { duration: root.reducedMotion ? 0 : 260 } }
                        Behavior on scale { NumberAnimation { duration: root.reducedMotion ? 0 : 300; easing.type: Easing.OutCubic } }
                    }
                    TapHandler {
                        enabled: root.library.synced && root.media.canSeek
                        onTapped: { root.media.seekTo(Number(line.modelData.time)); root.following = true; root.followLine() }
                    }
                }
            }
            Column {
                anchors.centerIn: parent; width: parent.width; spacing: 14
                visible: root.library.lines.length === 0
                Text {
                    width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                    text: root.library.lyricsState === "loading" ? "Buscando a letra…"
                        : root.library.lyricsState === "error" ? "Não foi possível carregar a letra."
                        : "Letra indisponível para esta faixa."
                    color: root.muted; font.family: root.family; font.pixelSize: 14
                }
                VeloraSettingsLink {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.library.lyricsState === "error"
                    label: "Tentar novamente"; theme: root.theme
                    onTriggered: root.library.retryLyrics()
                }
            }
            VeloraSettingsLink {
                anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                visible: root.library.synced && !root.following
                label: "Acompanhar"; theme: root.theme
                onTriggered: { root.following = true; root.followLine() }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true; Layout.maximumWidth: root.lyrics ? 250 : Infinity
            Layout.alignment: Qt.AlignRight; spacing: 0
            VeloraMotionSlider {
                id: seek; objectName: "edgeMediaSeek"
                Layout.fillWidth: true; implicitHeight: 24
                handleSize: 7
                from: 0; to: Math.max(1, root.media.length || 0)
                enabled: root.hasTrack && root.media.canSeek
                ink: root.ink; reducedMotion: root.reducedMotion
                Accessible.name: "Posição da música"
                Binding { target: seek; property: "value"; value: root.position; when: !seek.pressed }
                onPressedChanged: if (!pressed && enabled) root.media.seekTo(value)
                Keys.onLeftPressed: root.media.seekTo(root.position - 5)
                Keys.onRightPressed: root.media.seekTo(root.position + 5)
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: root.time(seek.pressed ? seek.value : root.position); color: root.muted; font.family: root.family; font.pixelSize: 10 }
                Item { Layout.fillWidth: true }
                Text { text: root.time(root.media.length); color: root.muted; font.family: root.family; font.pixelSize: 10 }
            }
        }
        RowLayout {
            visible: !root.lyrics; Layout.fillWidth: true
            IconButton { iconName: "shuffle"; hint: "Aleatório"; enabled: root.media.canShuffle; highlighted: root.media.shuffled; onClicked: root.media.toggleShuffle() }
            Item { Layout.fillWidth: true }
            IconButton { objectName: "edgeMediaPrevious"; iconName: "skip-previous"; hint: "Anterior"; enabled: root.media.canPrevious; onClicked: root.media.previous() }
            IconButton {
                objectName: "edgeMediaPlay"
                implicitWidth: 54; implicitHeight: 54
                iconName: root.hasTrack && root.media.playing ? "pause" : "play"
                hint: !root.hasTrack ? "Abrir Spotify" : root.media.playing ? "Pausar" : "Reproduzir"
                enabled: !root.hasTrack || root.media.canToggle
                background: Rectangle { radius: width / 2; color: root.alpha(root.ink, parent.hovered ? .09 : 0); border.color: root.alpha(root.ink, .7) }
                onClicked: root.hasTrack ? root.media.togglePlaying() : root.media.openSpotify("")
            }
            IconButton { objectName: "edgeMediaNext"; iconName: "skip-next"; hint: "Próxima"; enabled: root.media.canNext; onClicked: root.media.next() }
            Item { Layout.fillWidth: true }
            IconButton { iconName: "refresh"; hint: "Repetição"; enabled: root.media.canRepeat; highlighted: root.media.repeatMode > 0; onClicked: root.media.cycleRepeat() }
        }
        RowLayout {
            visible: !root.lyrics && root.media.canVolume; Layout.fillWidth: true; spacing: 10
            VeloraMaterialIcon { implicitWidth: 20; implicitHeight: 20; iconName: "volume"; iconColor: root.ink }
            VeloraMotionSlider {
                id: volume; objectName: "edgeMediaVolume"
                Layout.fillWidth: true; from: 0; to: 1; stepSize: .01
                handleSize: 7
                ink: root.ink; reducedMotion: root.reducedMotion
                Accessible.name: "Volume do player"
                Binding { target: volume; property: "value"; value: root.media.volume; when: !volume.pressed }
                onMoved: root.media.setVolume(value)
            }
            Text { text: Math.round(volume.value * 100); color: root.muted; font.family: root.family; font.pixelSize: 11 }
        }
        ComboBox {
            id: players; objectName: "edgeMediaPlayer"
            visible: !root.lyrics && count > 0; Layout.fillWidth: true; implicitHeight: 36
            model: root.media.players || []; textRole: "identity"
            currentIndex: (root.media.players || []).indexOf(root.media.player)
            Accessible.name: "Player de mídia"
            onActivated: index => root.media.preferredPlayer = root.media.players[index].dbusName
            background: Rectangle { radius: 9; color: root.alpha(root.ink, .045); border.color: root.alpha(root.ink, .08) }
            contentItem: Text { leftPadding: 12; rightPadding: 30; text: players.displayText; color: root.ink; font.family: root.family; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
        }
        TextField {
            id: search; objectName: "edgeMediaSearch"
            visible: !root.lyrics; Layout.fillWidth: true; implicitHeight: 36
            placeholderText: "Buscar no Spotify…"; placeholderTextColor: root.muted
            color: root.ink; font.family: root.family; font.pixelSize: 12
            leftPadding: 12; selectByMouse: true
            Accessible.name: "Buscar no Spotify"
            onTextEdited: { root.library.page = text.trim().length > 1 ? "search" : "queue"; root.library.query = text }
            onAccepted: root.library.search()
            Keys.onEscapePressed: root.closeRequested()
            background: Rectangle { radius: 9; color: root.alpha(root.ink, .045); border.color: root.alpha(root.ink, search.activeFocus ? .35 : .07) }
        }
        Text {
            visible: !root.lyrics; Layout.fillWidth: true
            text: root.library.page === "search" ? "Resultados" : "A seguir"
            color: root.ink; font.family: root.family; font.pixelSize: 15
        }
        Item {
            visible: !root.lyrics; Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumHeight: 60
            ListView {
                id: tracks; objectName: "edgeMediaTracks"
                anchors.fill: parent; clip: true; spacing: 5
                boundsBehavior: Flickable.StopAtBounds
                model: root.library.page === "search" ? root.library.results : root.media.spotifyQueueAvailable ? root.media.spotifyQueue : []
                delegate: ItemDelegate {
                    id: track
                    required property var modelData
                    width: tracks.width; height: 58
                    Accessible.name: String(modelData.title || "") + " · " + String(modelData.artist || "")
                    enabled: /^spotify:track:[a-zA-Z0-9]+$/.test(String(modelData.uri || ""))
                    onClicked: root.media.playTrack(modelData.uri)
                    background: Rectangle { radius: 9; color: root.alpha(root.ink, track.hovered ? .09 : .025) }
                    contentItem: RowLayout {
                        spacing: 10
                        VeloraMediaArtwork { implicitWidth: 42; implicitHeight: 42; source: String(track.modelData.art || ""); radius: 7; ink: root.ink; animated: !root.reducedMotion }
                        Column {
                            Layout.fillWidth: true; spacing: 3
                            Text { width: parent.width; text: String(track.modelData.title || ""); textFormat: Text.PlainText; color: root.ink; font.family: root.family; font.pixelSize: 11; elide: Text.ElideRight }
                            Text { width: parent.width; text: String(track.modelData.artist || ""); textFormat: Text.PlainText; color: root.muted; font.family: root.family; font.pixelSize: 10; elide: Text.ElideRight }
                        }
                    }
                }
            }
            Text {
                anchors.fill: parent; visible: tracks.count === 0; wrapMode: Text.WordWrap
                text: root.library.page !== "search" ? "A fila aparece quando estiver disponível no Spotify."
                    : root.library.searchState === "loading" ? "Buscando…"
                    : root.library.searchState === "offline" ? "Abra o Spotify para buscar."
                    : root.library.searchState === "error" ? "Não foi possível buscar. Pressione Enter para tentar novamente."
                    : "Nenhuma música encontrada."
                color: root.muted; font.family: root.family; font.pixelSize: 11
            }
        }
        VeloraSettingsLink {
            Layout.alignment: Qt.AlignHCenter
            label: "Voltar aos apps"; theme: root.theme
            onTriggered: root.backRequested()
        }
    }
    component IconButton: VeloraMediaButton {
        ink: root.ink; accent: root.ink; animated: !root.reducedMotion
        implicitWidth: 30; implicitHeight: 30
        ToolTip.visible: false
    }
}
