pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../features/topbar" as TopBar
import "../features/topbar/TimerGeometry.js" as TimerGeometry

Item {
    id: root
    required property var media
    required property var library
    required property var theme
    property bool animated: true
    readonly property color ink: theme ? theme.textPrimary : "#f5f2ff"
    readonly property color muted: theme ? theme.textSecondary : "#b2aebb"
    readonly property color baseAccent: theme ? theme.accent : "#cab6ed"
    readonly property color accent: Qt.hsla(baseAccent.hslHue, Math.min(.6, baseAccent.hslSaturation), Math.max(.7, baseAccent.hslLightness), 1)
    readonly property string family: theme ? theme.bodyFont : "sans-serif"
    readonly property bool hasTrack: !!media && media.hasPlayer
    readonly property bool interactionHeld: seek.pressed || searchField.activeFocus
        || lyricView.dragging || queueView.dragging || searchView.dragging
    readonly property int pageIndex: ["lyrics", "queue", "search"].indexOf(library.page)
    readonly property real position: Math.min(media.length || 0, Math.max(0, media.sampledPosition || 0))
    property bool following: true
    signal closeRequested()

    function alpha(color, value) { return Qt.rgba(color.r, color.g, color.b, value) }
    function clock(seconds) {
        const value = Math.max(0, Math.floor(Number(seconds) || 0))
        return Math.floor(value / 60) + ":" + (value % 60 < 10 ? "0" : "") + value % 60
    }
    function setPage(page) {
        library.page = page
        if (page === "search") Qt.callLater(() => searchField.forceActiveFocus())
        else { root.forceActiveFocus(); following = true }
    }
    function followLine() {
        if (following && library.activeLine >= 0)
            lyricView.positionViewAtIndex(library.activeLine, ListView.Center)
    }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Space) { if (root.hasTrack) root.media.togglePlaying(); event.accepted = true }
        else if (event.key === Qt.Key_Right && event.modifiers & Qt.ControlModifier) { root.media.next(); event.accepted = true }
        else if (event.key === Qt.Key_Left && event.modifiers & Qt.ControlModifier) { root.media.previous(); event.accepted = true }
        else if (event.key === Qt.Key_F && event.modifiers & Qt.ControlModifier) { root.setPage("search"); event.accepted = true }
    }
    Connections {
        target: root.library
        function onActiveLineChanged() { root.followLine() }
        function onLinesChanged() { root.following = true; Qt.callLater(root.followLine) }
    }

    RowLayout {
        id: header
        width: parent.width; height: 32; spacing: 10
        Text { text: "Música"; color: root.ink; font.family: root.family; font.pixelSize: 18; font.weight: Font.Medium }
        Rectangle { Layout.leftMargin: 7; implicitWidth: 4; implicitHeight: 4; radius: 2; color: root.accent; opacity: .6 }
        Text { Layout.fillWidth: true; text: root.hasTrack ? root.media.identity : "Spotify"; color: root.muted; font.family: root.family; font.pixelSize: 11 }
        Button {
            id: spotifyButton
            text: "Abrir Spotify  ↗"; hoverEnabled: true
            implicitHeight: 30; implicitWidth: 110
            Accessible.name: "Abrir Spotify"
            onClicked: root.media.openSpotify("")
            contentItem: Text { text: spotifyButton.text; color: root.ink; font.family: root.family; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            background: Rectangle { radius: 6; color: root.alpha(root.ink, spotifyButton.hovered ? .08 : 0); Behavior on color { ColorAnimation { duration: 120 } } }
        }
        VeloraMediaButton { iconName: "close"; ink: root.muted; accent: root.accent; animated: root.animated; hint: "Fechar (Esc)"; onClicked: root.closeRequested() }
    }
    RowLayout {
        id: body
        anchors { top: header.bottom; topMargin: 22; left: parent.left; right: parent.right; bottom: transport.top; bottomMargin: 24 }
        spacing: 28
        ColumnLayout {
            id: playerColumn
            Layout.preferredWidth: Math.min(310, root.width * .37)
            Layout.maximumWidth: Math.min(310, root.width * .37)
            Layout.minimumWidth: Math.min(310, root.width * .37)
            Layout.fillHeight: true
            spacing: 15
            Item {
                Layout.fillWidth: true
                Layout.minimumHeight: Math.min(playerColumn.width, Math.max(120, body.height - 106))
                Layout.preferredHeight: Layout.minimumHeight
                Layout.maximumHeight: Layout.minimumHeight
                VeloraMediaArtwork {
                    id: heroArt
                    objectName: "mediaArtwork"
                    anchors.centerIn: parent; width: Math.min(parent.width, parent.height); height: width
                    source: root.hasTrack ? root.media.artUrl : ""
                    accent: root.accent; ink: root.ink; radius: 12
                    animated: root.animated; selected: artworkHover.hovered
                    HoverHandler { id: artworkHover }
                    Rectangle {
                        anchors { left: parent.left; bottom: parent.bottom; margins: 12 }
                        width: statusRow.implicitWidth + 18; height: 25; radius: 6
                        color: "#b31b1b22"
                        Row {
                            id: statusRow
                            anchors.centerIn: parent; spacing: 6
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 5; height: 5; radius: 3; color: root.hasTrack && root.media.playing ? "#bdedb9" : "#d5cdda" }
                            Text { text: root.hasTrack ? (root.media.playing ? "TOCANDO AGORA" : "EM PAUSA") : "SEU PLAYER"; color: "#fff9ff"; font.family: root.family; font.pixelSize: 8; font.letterSpacing: 1; font.weight: Font.Medium }
                        }
                    }
                }
            }
            Column {
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumHeight: 82
                spacing: 2
                Text {
                    width: parent.width; text: root.hasTrack ? root.media.title : "Nada tocando"
                    textFormat: Text.PlainText; color: root.ink
                    font.family: root.family; font.pixelSize: 26; font.weight: Font.Light
                    maximumLineCount: 1; elide: Text.ElideRight
                }
                Text {
                    width: parent.width; text: root.hasTrack ? root.media.artist || root.media.identity : "Escolha uma música na busca."
                    textFormat: Text.PlainText; color: root.muted; font.family: root.family; font.pixelSize: 12; elide: Text.ElideRight
                }
                Text { width: parent.width; text: root.hasTrack ? root.media.album || "" : ""; color: root.muted; opacity: .55; font.family: root.family; font.pixelSize: 10; elide: Text.ElideRight; textFormat: Text.PlainText }
            }
        }
        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: root.alpha(root.ink, .08) }
        ColumnLayout {
            Layout.fillWidth: true; Layout.minimumWidth: 0; Layout.fillHeight: true; spacing: 15
            Item {
                id: tabs
                Layout.fillWidth: true; Layout.preferredHeight: 38
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.alpha(root.ink, .10) }
                Rectangle {
                    x: root.pageIndex * (tabs.width / 3); y: tabs.height - 2
                    width: tabs.width / 3 - 22; height: 2; radius: 1
                    color: root.ink
                    Behavior on x { NumberAnimation { duration: root.animated ? 220 : 0; easing.type: Easing.OutCubic } }
                }
                Row {
                    anchors.fill: parent
                    Repeater {
                        model: [{name: "Letras", page: "lyrics"}, {name: "A seguir", page: "queue"}, {name: "Buscar", page: "search"}]
                        delegate: AbstractButton {
                            id: tab
                            required property var modelData
                            required property int index
                            width: tabs.width / 3; height: 33; hoverEnabled: true
                            objectName: "mediaTab_" + modelData.page
                            Accessible.name: modelData.name
                            onClicked: root.setPage(modelData.page)
                            background: Rectangle { width: tab.width - 12; radius: 5; color: root.alpha(root.ink, tab.hovered ? .06 : 0) }
                            contentItem: Item {
                                Row {
                                    anchors.verticalCenter: parent.verticalCenter; spacing: 9
                                    Text { text: "0" + (tab.index + 1); color: root.muted; opacity: .45; font.family: root.family; font.pixelSize: 9; anchors.baseline: tabName.baseline }
                                    Text { id: tabName; text: tab.modelData.name; color: root.library.page === tab.modelData.page ? root.ink : root.muted; font.family: root.family; font.pixelSize: 13; font.weight: Font.Medium }
                                }
                            }
                        }
                    }
                }
            }
            Item {
                Layout.fillWidth: true; Layout.fillHeight: true
                Item {
                    id: lyricsPage
                    anchors.fill: parent
                    opacity: root.library.page === "lyrics" ? 1 : 0; visible: opacity > 0; enabled: root.library.page === "lyrics"
                    transform: Translate { y: (1 - lyricsPage.opacity) * 8 }
                    Behavior on opacity { NumberAnimation { duration: root.animated ? 180 : 0 } }
                    Text {
                        id: lyricsCaption; y: 2; width: parent.width
                        text: root.library.lyricsState === "ready" ? (root.library.synced ? "LETRA SINCRONIZADA" : "LETRA COMPLETA") : "LETRAS"
                        color: root.muted; font.family: root.family; font.pixelSize: 9; font.letterSpacing: 1.7
                    }
                    ListView {
                        id: lyricView
                        objectName: "mediaLyrics"
                        anchors { top: lyricsCaption.bottom; topMargin: 12; bottom: lyricsFooter.top; bottomMargin: 10; left: parent.left; right: parent.right }
                        model: root.library.lines
                        clip: true; spacing: 22; boundsBehavior: Flickable.StopAtBounds
                        header: Item { height: root.library.synced ? 65 : 12 }
                        footer: Item { height: root.library.synced ? 100 : 12 }
                        onDraggingChanged: if (dragging) root.following = false
                        Behavior on contentY { enabled: root.following && !lyricView.dragging && !lyricView.flicking; NumberAnimation { duration: root.animated ? 340 : 0; easing.type: Easing.OutCubic } }
                        delegate: Item {
                            id: lyric
                            required property int index
                            required property var modelData
                            readonly property bool current: root.library.synced && index === root.library.activeLine
                            width: lyricView.width; height: words.implicitHeight + 6
                            Text { x: 0; y: 9; text: String(lyric.index + 1).padStart(2, "0"); color: root.muted; opacity: lyric.current ? .8 : .2; font.family: root.family; font.pixelSize: 9; font.features: ({tnum: 1}) }
                            Rectangle { x: 26; y: 6; width: 2; height: parent.height - 12; radius: 1; color: root.ink; opacity: lyric.current ? .9 : 0; Behavior on opacity { NumberAnimation { duration: root.animated ? 260 : 0 } } }
                            Text {
                                id: words
                                x: 42; width: parent.width - 48
                                text: String(lyric.modelData.text || ""); textFormat: Text.PlainText
                                wrapMode: Text.WordWrap
                                font.family: root.family; font.pixelSize: 27; font.weight: Font.Medium
                                lineHeight: 1.12
                                color: root.ink
                                opacity: !root.library.synced ? .88 : lyric.current ? 1 : .26
                                scale: lyric.current ? 1 : .965; transformOrigin: Item.Left
                                Behavior on opacity { NumberAnimation { duration: root.animated ? 260 : 0 } }
                                Behavior on scale { NumberAnimation { duration: root.animated ? 300 : 0; easing.type: Easing.OutCubic } }
                            }
                            TapHandler { enabled: root.library.synced && root.media.canSeek; onTapped: { root.media.seekTo(Number(lyric.modelData.time)); root.following = true; root.followLine() } }
                        }
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    }
                    EmptyState {
                        anchors { fill: lyricView; margins: 20 }
                        visible: root.library.lines.length === 0
                        symbol: root.library.lyricsState === "loading" ? "volume" : "memo"
                        title: root.library.lyricsState === "loading" ? "Encontrando os versos…" : root.hasTrack ? "Esta faixa, só no som." : "A letra acompanha você."
                        detail: root.library.lyricsState === "loading" ? "Buscando a letra da música atual." : root.hasTrack ? "Ainda não encontramos uma letra para esta música." : "Dê play no Spotify para acompanhar\nas letras por aqui."
                        action: root.library.lyricsState === "error" ? "Tentar novamente" : !root.hasTrack ? "Abrir Spotify" : ""
                        onTriggered: root.hasTrack ? root.library.retryLyrics() : root.media.openSpotify("")
                    }
                    RowLayout {
                        id: lyricsFooter; anchors { bottom: parent.bottom; left: parent.left; right: parent.right } height: 24
                        Text { Layout.fillWidth: true; text: root.library.lines.length ? (root.library.synced ? "Sincronizada  ·  LRCLIB" : "Sem sincronização  ·  LRCLIB") : ""; color: root.muted; font.family: root.family; font.pixelSize: 9; opacity: .7 }
                        Button {
                            id: followButton
                            visible: root.library.synced && !root.following; text: "Acompanhar"; flat: true
                            onClicked: { root.following = true; root.followLine() }
                            contentItem: Text { text: followButton.text; font.family: root.family; font.pixelSize: 10; color: root.accent }
                            background: Item {}
                        }
                    }
                }
                Item {
                    id: queuePage
                    anchors.fill: parent
                    opacity: root.library.page === "queue" ? 1 : 0; visible: opacity > 0; enabled: root.library.page === "queue"
                    transform: Translate { y: (1 - queuePage.opacity) * 8 }
                    Behavior on opacity { NumberAnimation { duration: root.animated ? 180 : 0 } }
                    Text { id: queueCaption; text: "PRÓXIMAS NA FILA"; color: root.muted; font.family: root.family; font.pixelSize: 9; font.letterSpacing: 1.7 }
                    ListView {
                        id: queueView
                        anchors { top: queueCaption.bottom; topMargin: 15; left: parent.left; right: parent.right; bottom: parent.bottom }
                        clip: true; spacing: 4; boundsBehavior: Flickable.StopAtBounds
                        model: root.media.spotifyQueueAvailable ? root.media.spotifyQueue : []
                        delegate: TrackRow {
                            required property var modelData
                            required property int index
                            width: queueView.width; track: modelData; number: index + 1
                            onChosen: root.media.playTrack(String(modelData.uri || ""))
                        }
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    }
                    EmptyState { anchors.fill: queueView; anchors.margins: 20; visible: queueView.count === 0; symbol: "music"; title: "O que vem depois?"; detail: "Abra o Spotify para ver sua fila\ne escolher a próxima música."; action: "Buscar uma música"; onTriggered: root.setPage("search") }
                }
                Item {
                    id: searchPage
                    anchors.fill: parent
                    opacity: root.library.page === "search" ? 1 : 0; visible: opacity > 0; enabled: root.library.page === "search"
                    transform: Translate { y: (1 - searchPage.opacity) * 8 }
                    Behavior on opacity { NumberAnimation { duration: root.animated ? 180 : 0 } }
                    Rectangle {
                        id: searchBox
                        width: parent.width; height: 46; radius: 9
                        color: root.alpha(root.ink, .025)
                        border.color: root.alpha(root.ink, searchField.activeFocus ? .35 : .1)
                        Behavior on border.color { ColorAnimation { duration: root.animated ? 160 : 0 } }
                        VeloraMaterialIcon { x: 13; anchors.verticalCenter: parent.verticalCenter; width: 20; height: 20; iconName: "search"; iconColor: root.muted }
                        TextField {
                            id: searchField
                            objectName: "mediaSearch"
                            x: 42; width: parent.width - 78; height: parent.height
                            placeholderText: "Música ou artista no Spotify"
                            placeholderTextColor: root.alpha(root.muted, .72)
                            color: root.ink; selectionColor: root.alpha(root.accent, .35)
                            font.family: root.family; font.pixelSize: 12
                            text: root.library.query
                            onTextEdited: root.library.query = text
                            onAccepted: { root.library.query = text; root.library.search() }
                            background: Item {}
                            Keys.onEscapePressed: root.closeRequested()
                        }
                        VeloraMediaButton { width: 32; height: 32; anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter } visible: searchField.text.length > 0; iconName: "close"; hint: "Limpar busca"; ink: root.muted; animated: root.animated; onClicked: { root.library.query = ""; searchField.text = ""; searchField.forceActiveFocus() } }
                    }
                    Text {
                        id: searchCaption; y: searchBox.height + 15; width: parent.width
                        text: root.library.searchState === "loading" ? "PROCURANDO NO SPOTIFY…" : root.library.results.length ? "ENCONTRADAS PARA VOCÊ" : "EXPLORE SEU PRÓXIMO SOM"
                        color: root.muted; font.family: root.family; font.pixelSize: 9; font.letterSpacing: 1.4
                    }
                    ListView {
                        id: searchView
                        anchors { top: searchCaption.bottom; topMargin: 12; left: parent.left; right: parent.right; bottom: parent.bottom }
                        clip: true; spacing: 3; boundsBehavior: Flickable.StopAtBounds
                        model: root.library.results
                        delegate: TrackRow {
                            required property var modelData
                            width: searchView.width; track: modelData
                            onChosen: root.media.playTrack(String(modelData.uri || ""))
                        }
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    }
                    EmptyState {
                        anchors.fill: searchView; anchors.margins: 15
                        visible: searchView.count === 0
                        symbol: "search"
                        title: root.library.searchState === "loading" ? "Encontrando seu próximo som…" : root.library.searchState === "empty" ? "Vamos tentar outro nome?" : root.library.searchState === "offline" ? "Conecte seu Spotify." : "Qual é o som de hoje?"
                        detail: root.library.searchState === "offline" ? "Abra o aplicativo para pesquisar\ne tocar músicas neste menu." : root.library.searchState === "error" ? "A busca não respondeu. Você também\npode pesquisar direto no Spotify." : root.library.searchState === "empty" ? "Nenhuma faixa encontrada para esta busca." : "Pesquise uma música ou artista.\nO próximo play é seu."
                        action: ["offline", "error"].includes(root.library.searchState) ? "Buscar no Spotify ↗" : ""
                        onTriggered: root.media.openSpotify(root.library.query)
                    }
                }
            }
        }
    }
    Item {
        id: transport
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 96
        Slider {
            id: seek
            objectName: "mediaSeek"
            width: parent.width; height: 30; padding: 0
            from: 0; to: Math.max(1, root.media.length)
            enabled: root.hasTrack && root.media.canSeek
            Accessible.name: "Posição da música"
            property real overdrag: pressed ? TimerGeometry.resistance(seekTouch.point.position.x < 0 ? seekTouch.point.position.x : seekTouch.point.position.x > width ? seekTouch.point.position.x - width : 0) : 0
            Behavior on overdrag { enabled: !seek.pressed; NumberAnimation { duration: root.animated ? 210 : 0; easing.type: Easing.OutCubic } }
            PointHandler { id: seekTouch; acceptedButtons: Qt.LeftButton }
            Binding { target: seek; property: "value"; value: root.position; when: !seek.pressed; restoreMode: Binding.RestoreNone }
            onPressedChanged: if (!pressed && enabled) root.media.seekTo(value)
            onMoved: if (!pressed && enabled) root.media.seekTo(value)
            background: Item {
                x: Math.min(0, seek.overdrag); y: 3; width: seek.width + Math.abs(seek.overdrag); height: 21
                Repeater {
                    model: Math.max(51, Math.floor(seek.width / 5))
                    Rectangle {
                        required property int index
                        x: index * (parent.width - 1) / (Math.max(51, Math.floor(seek.width / 5)) - 1)
                        y: index % 5 === 0 ? 0 : 4
                        width: 1; height: index % 5 === 0 ? 21 : 13
                        color: root.alpha(root.ink, x <= seek.visualPosition * parent.width ? .48 : index % 5 === 0 ? .23 : .12)
                    }
                }
            }
            handle: Rectangle {
                x: Math.min(0, seek.overdrag) + seek.visualPosition * (seek.width + Math.abs(seek.overdrag) - width)
                y: 1; width: 2; height: 25; radius: 1; color: root.ink; opacity: seek.enabled ? 1 : .25
            }
        }
        RowLayout {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 49; spacing: 8
            VeloraMediaButton { objectName: "mediaPrevious"; iconName: "skip-previous"; hint: "Música anterior"; enabled: root.hasTrack && root.media.canPrevious; ink: root.ink; accent: root.accent; animated: root.animated; onClicked: root.media.previous() }
            TopBar.BarAction {
                objectName: "mediaPlay"; theme: root.theme
                text: root.hasTrack ? (root.media.playing ? "Pausar" : "Reproduzir") : "Abrir Spotify"
                implicitWidth: 112; implicitHeight: 40
                highlighted: root.hasTrack && root.media.playing
                enabled: !root.hasTrack || root.media.canToggle
                onClicked: root.hasTrack ? root.media.togglePlaying() : root.media.openSpotify("")
            }
            VeloraMediaButton { objectName: "mediaNext"; iconName: "skip-next"; hint: "Próxima música"; enabled: root.hasTrack && root.media.canNext; ink: root.ink; accent: root.accent; animated: root.animated; onClicked: root.media.next() }
            Rectangle { Layout.leftMargin: 8; Layout.rightMargin: 8; implicitWidth: 1; implicitHeight: 19; color: root.alpha(root.ink,.12) }
            VeloraMediaButton { iconName: "shuffle"; hint: "Aleatório"; enabled: root.hasTrack && root.media.canShuffle; highlighted: root.media.shuffled; ink: root.muted; accent: root.accent; animated: root.animated; onClicked: root.media.toggleShuffle() }
            VeloraMediaButton {
                iconName: "refresh"; hint: root.media.repeatMode === 1 ? "Repetir faixa" : root.media.repeatMode === 2 ? "Repetir fila" : "Repetição desligada"
                enabled: root.hasTrack && root.media.canRepeat; highlighted: root.media.repeatMode > 0
                ink: root.muted; accent: root.accent; animated: root.animated; onClicked: root.media.cycleRepeat()
                Text { anchors { right: parent.right; bottom: parent.bottom; margins: 5 } visible: root.media.repeatMode === 1; text: "1"; color: root.accent; font.pixelSize: 8 }
            }
            Item { Layout.fillWidth: true }
            TopBar.TimerLabel {
                text: root.clock(seek.pressed ? seek.value : root.position)
                color: root.ink; family: root.family; pixelSize: 36; weight: Font.Light; tabular: true
                transitionKey: root.media.title; animate: root.animated && !seek.pressed
            }
            Text { Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: 8; text: "/ " + root.clock(root.media.length); color: root.muted; opacity: .55; font.family: root.family; font.pixelSize: 12; font.features: ({tnum: 1}) }
        }
    }
    component EmptyState: Item {
        id: empty
        property string symbol: "music"
        property string title: ""
        property string detail: ""
        property string action: ""
        signal triggered()
        Column {
            anchors.centerIn: parent; width: parent.width; spacing: 14
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter; width: 52; height: 52; radius: 10
                color: root.alpha(root.accent, .09); border.color: root.alpha(root.accent, .10)
                VeloraMaterialIcon { anchors.centerIn: parent; width: 29; height: 29; iconName: empty.symbol; iconColor: root.accent; opacity: .85 }
            }
            Text { width: parent.width; text: empty.title; color: root.ink; font.family: root.family; font.pixelSize: 17; font.weight: Font.Medium; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap }
            Text { width: parent.width; text: empty.detail; color: root.muted; font.family: root.family; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; lineHeight: 1.35; wrapMode: Text.WordWrap; opacity: .8 }
            Button {
                id: emptyAction
                visible: empty.action.length > 0; anchors.horizontalCenter: parent.horizontalCenter; text: empty.action
                implicitHeight: 36; leftPadding: 18; rightPadding: 18; hoverEnabled: true
                onClicked: empty.triggered()
                contentItem: Text { text: emptyAction.text; color: root.accent; font.family: root.family; font.pixelSize: 11; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                background: Rectangle { radius: 9; color: root.alpha(root.ink, emptyAction.hovered ? .08 : .025); border.color: root.alpha(root.ink, .12) }
            }
        }
    }
    component TrackRow: AbstractButton {
        id: row
        property var track: ({})
        property int number: 0
        signal chosen()
        height: 62; hoverEnabled: true
        Accessible.name: String(track.title || "") + ", " + String(track.artist || "")
        onClicked: chosen()
        background: Rectangle {
            radius: 9; color: root.alpha(root.ink, row.down ? .12 : row.hovered ? .07 : 0)
            Behavior on color { ColorAnimation { duration: root.animated ? 130 : 0 } }
        }
        contentItem: Item {
            Rectangle { anchors.bottom: parent.bottom; x: 65; width: parent.width - x; height: 1; color: root.alpha(root.ink, .055) }
            VeloraMediaArtwork { id: smallArt; x: 8; y: 8; width: 46; height: 46; radius: 9; source: String(row.track.art || ""); ink: root.ink; accent: root.accent; animated: root.animated }
            Column {
                x: 65; width: parent.width - 112; anchors.verticalCenter: parent.verticalCenter; spacing: 3
                Text { width: parent.width; text: String(row.track.title || ""); textFormat: Text.PlainText; color: root.ink; font.family: root.family; font.pixelSize: 12; font.weight: Font.Medium; elide: Text.ElideRight }
                Text { width: parent.width; text: String(row.track.artist || ""); textFormat: Text.PlainText; color: root.muted; font.family: root.family; font.pixelSize: 10; elide: Text.ElideRight }
            }
            VeloraMaterialIcon { anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter } width: 22; height: 22; iconName: "play"; iconColor: root.accent; opacity: row.hovered ? 1 : .4; scale: row.down ? .88 : 1; Behavior on opacity { NumberAnimation { duration: root.animated ? 130 : 0 } } }
        }
    }
}
