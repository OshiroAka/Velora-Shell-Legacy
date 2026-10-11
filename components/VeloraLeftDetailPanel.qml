import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var theme: null
    property var clockState: null
    property string detailType: "clock"
    property string attachSide: "left"
    property real entryProgress: 1
    readonly property bool pywalStyle: theme && theme.themeId === "pywal16"
    readonly property bool darkSoft: theme && theme.themeMode === "dark"
    readonly property color ink: theme ? theme.textPrimary : Qt.rgba(0.47, 0.38, 0.55, 0.88)
    readonly property color inkSoft: theme ? theme.textSecondary : Qt.rgba(0.57, 0.48, 0.64, 0.66)
    readonly property color pink: theme ? (pywalStyle ? theme.accentSecondary : theme.accentPrimary) : Qt.rgba(0.88, 0.43, 0.66, 0.92)
    readonly property color lilac: theme ? (pywalStyle ? theme.accentPrimary : theme.accentSecondary) : Qt.rgba(0.58, 0.48, 0.73, 0.78)
    readonly property color card: theme ? (darkSoft ? theme.withAlpha(theme.surfaceCard, Math.min(theme.surfaceCard.a, 0.62)) : theme.surfaceCard) : Qt.rgba(1, 1, 1, 0.70)
    readonly property color borderSoft: theme ? theme.borderSoft : Qt.rgba(1, 1, 1, 0.78)
    readonly property string uiFont: theme ? theme.uiFont : "Noto Sans CJK JP"
    readonly property string monoFont: theme ? theme.monoFont : "JetBrainsMono Nerd Font"
    readonly property int cornerRadius: 22
    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string wallpaperDir: homeDir + "/Pictures/Wallpapers"
    readonly property string scanScript: Quickshell.shellDir + "/scripts/velora-wallpaper-scan"
    readonly property string applyScript: Quickshell.shellDir + "/scripts/velora-wallpaper-apply"
    readonly property var wallpaperFilterKeys: ["all", "static", "live", "engine"]
    readonly property int motionPanelGeometry: theme ? theme.motionPanelGeometry : 220
    readonly property int motionHover: theme ? theme.motionHover : 120
    readonly property int motionEaseHover: theme ? theme.motionEaseHover : Easing.OutCubic
    readonly property int motionEaseEmphasized: theme ? theme.motionEaseEmphasized : Easing.BezierSpline
    readonly property var motionEmphasizedCurve: theme ? theme.motionEmphasizedCurve : [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]

    property date currentDate: new Date()
    property var alarms: [
        { time: "07:00", detail: "Weekday", enabled: true },
        { time: "08:30", detail: "Weekend", enabled: true },
        { time: "22:00", detail: "Daily", enabled: true }
    ]
    property string lastAlarmMinute: ""
    property int timerSeconds: 1800
    property int timerRemaining: 1800
    property bool timerRunning: false
    readonly property var clockAlarms: clockState ? clockState.alarms : alarms
    readonly property date clockCurrentDate: clockState ? clockState.currentDate : currentDate
    readonly property int clockTimerSeconds: clockState ? clockState.timerSeconds : timerSeconds
    readonly property int clockTimerRemaining: clockState ? clockState.timerRemaining : timerRemaining
    readonly property bool clockTimerRunning: clockState ? clockState.timerRunning : timerRunning

    property string paintTool: "brush"
    property color paintColor: pink
    property real paintBrushSize: 12
    property real paintOpacity: 0.80
    property var paintStrokes: []
    property var paintRedoStrokes: []

    property var allWallpapers: []
    property var wallpapers: []
    property int wallpaperFilterIndex: 0
    property int wallpaperSelectedIndex: 0
    property bool wallpaperLoadedOnce: false
    property bool wallpaperScanComplete: false
    property string wallpaperApplyState: ""
    readonly property var fallbackWallpapers: []

    function alpha(colorValue, opacity) {
        return root.theme ? root.theme.alpha(colorValue, opacity) : Qt.rgba(colorValue.r, colorValue.g, colorValue.b, opacity)
    }

    function cssColor(colorValue, opacity) {
        const c = root.alpha(colorValue, opacity)
        return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + c.a + ")"
    }

    function clamp01(value) {
        return Math.max(0, Math.min(1, value))
    }

    function staged(delay) {
        return clamp01((entryProgress * 260 - delay) / 220)
    }

    function basename(path) {
        var name = String(path || "").split("/").pop()
        var dot = name.lastIndexOf(".")
        if (dot > 0)
            name = name.slice(0, dot)
        return name.replace(/[-_]+/g, " ")
    }

    function formatDuration(seconds) {
        const safe = Math.max(0, Math.floor(seconds))
        const h = Math.floor(safe / 3600)
        const m = Math.floor((safe % 3600) / 60)
        const s = safe % 60
        return String(h).padStart(2, "0") + ":" + String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0")
    }

    function alarmAt(index) {
        if (index >= 0 && index < clockAlarms.length)
            return clockAlarms[index]
        return { time: "07:00", detail: "", enabled: false }
    }

    function setAlarmList(next) {
        if (clockState)
            clockState.replaceAlarms(next)
        else {
            alarms = next
            lastAlarmMinute = ""
        }
    }

    function setAlarmEnabled(index, enabled) {
        if (index < 0 || index >= clockAlarms.length)
            return
        var next = clockAlarms.slice()
        var item = Object.assign({}, next[index])
        item.enabled = enabled
        next[index] = item
        setAlarmList(next)
    }

    function alarmTime(index) {
        return alarmAt(index).time || "07:00"
    }

    function addAlarm() {
        if (clockState) {
            clockState.addAlarm()
            return
        }
        var d = new Date(clockCurrentDate.getTime() + 60 * 60 * 1000)
        var next = clockAlarms.slice()
        next.push({
            time: String(d.getHours()).padStart(2, "0") + ":" + String(d.getMinutes()).padStart(2, "0"),
            detail: "Custom",
            enabled: true
        })
        setAlarmList(next)
    }

    function shiftAlarmMinutes(index, delta) {
        if (clockState) {
            clockState.shiftAlarmMinutes(index, delta)
            return
        }
        if (index < 0 || index >= clockAlarms.length)
            return
        var item = Object.assign({}, clockAlarms[index])
        var parts = String(item.time || "07:00").split(":")
        var total = ((parseInt(parts[0]) || 0) * 60 + (parseInt(parts[1]) || 0) + delta + 1440) % 1440
        item.time = String(Math.floor(total / 60)).padStart(2, "0") + ":" + String(total % 60).padStart(2, "0")
        var next = clockAlarms.slice()
        next[index] = item
        setAlarmList(next)
    }

    function removeAlarm(index) {
        if (clockState) {
            clockState.removeAlarm(index)
            return
        }
        if (clockAlarms.length <= 1 || index < 0 || index >= clockAlarms.length)
            return
        var next = clockAlarms.slice()
        next.splice(index, 1)
        setAlarmList(next)
    }

    function checkAlarms() {
        if (clockState) {
            clockState.checkAlarms()
            return
        }
        const hhmm = Qt.formatTime(clockCurrentDate, "HH:mm")
        const dayKey = Qt.formatDate(clockCurrentDate, "yyyyMMdd") + "-" + hhmm
        for (var i = 0; i < clockAlarms.length; ++i) {
            if (alarmAt(i).enabled && hhmm === alarmTime(i) && lastAlarmMinute !== dayKey) {
                lastAlarmMinute = dayKey
                notifyProcess.command = ["bash", "-lc", "notify-send 'Velora' 'Alarm " + alarmTime(i) + "' >/dev/null 2>&1 || true"]
                notifyProcess.running = true
                break
            }
        }
    }

    function adjustTimerSeconds(delta) {
        if (clockState) {
            clockState.adjustTimerSeconds(delta)
            return
        }
        const next = Math.max(60, Math.min(24 * 3600, clockTimerSeconds + delta))
        timerSeconds = next
        if (!timerRunning)
            timerRemaining = next
        else
            timerRemaining = Math.max(1, Math.min(24 * 3600, timerRemaining + delta))
    }

    function setTimerPreset(seconds) {
        if (clockState) {
            clockState.setTimerPreset(seconds)
            return
        }
        timerSeconds = seconds
        timerRemaining = seconds
        timerRunning = false
    }

    function toggleTimer() {
        if (clockState) {
            clockState.toggleTimer()
            return
        }
        if (clockTimerRemaining <= 0)
            timerRemaining = timerSeconds
        timerRunning = !timerRunning
    }

    function resetTimer() {
        if (clockState) {
            clockState.resetTimer()
            return
        }
        timerRunning = false
        timerRemaining = timerSeconds
    }

    function finishTimer() {
        if (clockState) {
            clockState.finishTimer()
            return
        }
        timerRunning = false
        timerRemaining = 0
        notifyProcess.command = ["bash", "-lc", "notify-send 'Velora' 'Timer finished' >/dev/null 2>&1 || true; if command -v mpv >/dev/null 2>&1 && [ -f /usr/share/sounds/freedesktop/stereo/complete.oga ]; then mpv --no-video --really-quiet /usr/share/sounds/freedesktop/stereo/complete.oga >/dev/null 2>&1 || true; fi"]
        notifyProcess.running = true
    }

    function wallpaperKindLabel(kind) {
        if (kind === "live")
            return "MPV"
        if (kind === "engine")
            return "Engine"
        return "Static"
    }

    function displaySource(entry) {
        if (!entry)
            return ""
        if (entry.preview && String(entry.preview).length > 0)
            return entry.preview
        return entry.path || ""
    }

    function refreshWallpapers() {
        const filter = wallpaperFilterKeys[Math.max(0, Math.min(wallpaperFilterIndex, wallpaperFilterKeys.length - 1))]
        var next = []
        const source = allWallpapers.length > 0 ? allWallpapers : fallbackWallpapers
        for (var i = 0; i < source.length; ++i) {
            const item = source[i]
            if (!item)
                continue
            if (filter === "all" || (item.kind || "static") === filter)
                next.push(item)
        }
        wallpapers = next.length > 0 ? next : source
        wallpaperSelectedIndex = Math.max(0, Math.min(wallpaperSelectedIndex, Math.max(0, wallpapers.length - 1)))
    }

    function ensureWallpaperLoaded() {
        if (!wallpaperLoadedOnce) {
            wallpaperLoadedOnce = true
            wallpaperScanComplete = false
            if (!scanWallpapers.running)
                scanWallpapers.running = true
        }
    }

    function applySelectedWallpaper() {
        if (applyWallpaper.running || wallpapers.length <= 0)
            return
        const item = wallpapers[Math.max(0, Math.min(wallpaperSelectedIndex, wallpapers.length - 1))]
        wallpaperApplyState = "applying"
        applyWallpaper.command = [applyScript, item.kind || "static", item.path, displaySource(item)]
        applyWallpaper.running = true
    }

    onDetailTypeChanged: {
        if (detailType === "wallpaper")
            ensureWallpaperLoaded()
    }

    onWallpaperFilterIndexChanged: refreshWallpapers()
    onAllWallpapersChanged: refreshWallpapers()

    Component.onCompleted: {
        if (detailType === "wallpaper")
            ensureWallpaperLoaded()
    }

    Timer {
        interval: 1000
        running: !root.clockState && root.detailType === "clock"
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.currentDate = new Date()
            root.checkAlarms()
        }
    }

    Timer {
        interval: 1000
        running: !root.clockState && root.clockTimerRunning
        repeat: true
        onTriggered: {
            if (root.clockTimerRemaining > 1)
                root.timerRemaining -= 1
            else
                root.finishTimer()
        }
    }

    Process {
        id: notifyProcess

        running: false
        command: ["bash", "-lc", "true"]
        onExited: running = false
    }

    Process {
        id: scanWallpapers

        running: false
        property var tmp: []
        command: [root.scanScript]

        onStarted: tmp = []

        stdout: SplitParser {
            onRead: function(data) {
                const line = String(data).trim()
                if (!line || line === "BEGIN")
                    return
                if (line === "END") {
                    if (scanWallpapers.tmp.length > 0)
                        root.allWallpapers = scanWallpapers.tmp.slice()
                    root.wallpaperScanComplete = true
                    return
                }
                const parts = line.split("|")
                if (parts.length < 3)
                    return
                const kind = (parts[0] || "static").toLowerCase()
                const path = parts[1] || ""
                const preview = parts[2] || ""
                const title = parts.length > 3 && parts.slice(3).join("|").length > 0 ? parts.slice(3).join("|") : (kind === "engine" ? "Workshop " + path : root.basename(path))
                scanWallpapers.tmp.push({
                    kind: kind,
                    path: path,
                    preview: preview,
                    title: title,
                    label: title,
                    category: root.wallpaperKindLabel(kind)
                })
                if (scanWallpapers.tmp.length <= 24 || scanWallpapers.tmp.length % 12 === 0)
                    root.allWallpapers = scanWallpapers.tmp.slice()
            }
        }

        onExited: {
            running = false
            if (tmp.length > 0)
                root.allWallpapers = tmp.slice()
            root.wallpaperScanComplete = true
            root.refreshWallpapers()
        }
    }

    Process {
        id: applyWallpaper

        running: false
        command: [root.applyScript, "static", ""]
        onExited: {
            running = false
            root.wallpaperApplyState = ""
        }
    }

    function tr(key) {
        const lang = root.theme ? root.theme.language : "pt-BR"
        const texts = {
            "ja": {
                "clockTitle": "クロック / アラーム",
                "nextAlarm": "次のアラーム",
                "timer": "タイマー",
                "customTimer": "カスタムタイマー",
                "addAlarm": "アラームを追加",
                "paintTitle": "画筆",
                "paintSub": "自由線",
                "brushSize": "ブラシサイズ",
                "opacity": "不透明度",
                "undo": "撤销",
                "redo": "重做",
                "wallpaperTitle": "WALLPAPER MANAGER",
                "wallpaperSub": "壁紙マネージャー",
                "collection": "コレクション",
                "favorites": "お気に入り",
                "history": "履歴",
                "all": "すべて",
                "animated": "アニメーション",
                "static": "静止画",
                "applyWallpaper": "壁紙を適用",
                "quickSelect": "クイックセレクト",
                "start": "開始",
                "pause": "一時停止",
                "reset": "リセット",
                "lap": "ラップ",
                "loading": "読み込み中...",
                "live": "MPV",
                "engine": "Engine",
                "noWallpapers": "壁紙なし",
                "applying": "適用中...",
                "weekday": "平日",
                "weekend": "週末",
                "daily": "毎日",
                "custom": "カスタム"
            },
            "en": {
                "clockTitle": "Clock / Alarm",
                "nextAlarm": "Next alarm",
                "timer": "Timer",
                "customTimer": "Custom timer",
                "addAlarm": "Add alarm",
                "paintTitle": "Paint",
                "paintSub": "Free draw",
                "brushSize": "Brush size",
                "opacity": "Opacity",
                "undo": "Undo",
                "redo": "Redo",
                "wallpaperTitle": "Wallpaper manager",
                "wallpaperSub": "Collections",
                "collection": "Collection",
                "favorites": "Favorites",
                "history": "History",
                "all": "All",
                "animated": "Animated",
                "static": "Static",
                "applyWallpaper": "Apply wallpaper",
                "quickSelect": "Quick select",
                "start": "Start",
                "pause": "Pause",
                "reset": "Reset",
                "lap": "Lap",
                "loading": "Loading...",
                "live": "MPV",
                "engine": "Engine",
                "noWallpapers": "No wallpapers",
                "applying": "Applying...",
                "weekday": "Weekday",
                "weekend": "Weekend",
                "daily": "Daily",
                "custom": "Custom"
            },
            "pt-BR": {
                "clockTitle": "Relogio / Alarme",
                "nextAlarm": "Proximo alarme",
                "timer": "Timer",
                "customTimer": "Timer customizado",
                "addAlarm": "Adicionar alarme",
                "paintTitle": "Desenhar",
                "paintSub": "Traco livre",
                "brushSize": "Tamanho do pincel",
                "opacity": "Opacidade",
                "undo": "Desfazer",
                "redo": "Refazer",
                "wallpaperTitle": "Seletor de wallpapers",
                "wallpaperSub": "Colecoes",
                "collection": "Colecao",
                "favorites": "Favoritos",
                "history": "Historico",
                "all": "Tudo",
                "animated": "Animacao",
                "static": "Estaticos",
                "applyWallpaper": "Aplicar wallpaper",
                "quickSelect": "Selecao rapida",
                "start": "Iniciar",
                "pause": "Pausar",
                "reset": "Resetar",
                "lap": "Volta",
                "loading": "Carregando...",
                "live": "MPV",
                "engine": "Engine",
                "noWallpapers": "Sem wallpapers",
                "applying": "Aplicando...",
                "weekday": "Dia útil",
                "weekend": "Fim de semana",
                "daily": "Todo dia",
                "custom": "Customizado"
            }
        }
        const table = texts[lang] || texts["pt-BR"]
        return table[key] || texts["pt-BR"][key] || key
    }

    function alarmDetailLabel(detail) {
        const value = String(detail || "").toLowerCase()
        if (value === "weekday")
            return tr("weekday")
        if (value === "weekend")
            return tr("weekend")
        if (value === "daily")
            return tr("daily")
        if (value === "custom")
            return tr("custom")
        return detail || ""
    }

    ClockDetail {
        anchors.fill: parent
        visible: root.detailType === "clock"
    }

    PaintDetail {
        anchors.fill: parent
        visible: root.detailType === "paint"
    }

    WallpaperDetail {
        anchors.fill: parent
        visible: root.detailType === "wallpaper"
    }

    component HeaderBar: RowLayout {
        id: header

        property string title: ""
        property string subtitle: ""

        Layout.fillWidth: true
        spacing: 10

        Text {
            text: root.attachSide === "left" ? "‹" : "›"
            color: root.ink
            font.family: root.monoFont
            font.pixelSize: 24
            font.weight: Font.Bold
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: header.title
                color: root.ink
                font.family: root.uiFont
                font.pixelSize: 14
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: header.subtitle.length > 0
                text: header.subtitle
                color: root.inkSoft
                font.family: root.uiFont
                font.pixelSize: 10
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
        }

        Text {
            text: "×"
            color: root.inkSoft
            font.family: root.monoFont
            font.pixelSize: 18
            font.weight: Font.Bold
        }
    }

    component Card: Rectangle {
        default property alias content: body.data
        property int delay: 0

        Layout.fillWidth: true
        radius: 13
        color: root.alpha(root.card, 0.34)
        border.width: 1
        border.color: root.alpha(root.borderSoft, 0.22)
        opacity: root.staged(delay)
        transform: Translate { y: Math.round((1 - root.staged(delay)) * 12) }

        ColumnLayout {
            id: body
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10
        }
    }

    component LabelText: Text {
        color: root.ink
        font.family: root.uiFont
        font.pixelSize: 12
        font.weight: Font.Bold
        elide: Text.ElideRight
    }

    component SmallText: Text {
        color: root.inkSoft
        font.family: root.uiFont
        font.pixelSize: 10
        font.weight: Font.DemiBold
        elide: Text.ElideRight
    }

    component SoftButton: Rectangle {
        id: softButton

        property string label: ""
        property bool active: false
        property bool hovered: false
        signal clicked()

        radius: 12
        opacity: enabled ? 1 : 0.46
        color: active ? root.alpha(root.pink, 0.26) : root.alpha(root.card, hovered ? 0.46 : 0.36)
        border.width: 1
        border.color: root.alpha(active ? root.pink : root.borderSoft, active ? 0.36 : (hovered ? 0.30 : 0.20))

        Text {
            anchors.centerIn: parent
            text: parent.label
            color: parent.active ? root.pink : root.ink
            font.family: root.uiFont
            font.pixelSize: 11
            font.weight: Font.Bold
        }

        MouseArea {
            anchors.fill: parent
            enabled: softButton.enabled
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onEntered: softButton.hovered = true
            onExited: softButton.hovered = false
            onClicked: softButton.clicked()
        }
    }

    component Toggle: Rectangle {
        id: toggle

        property bool checked: true
        signal clicked(bool checked)

        width: 36
        height: 20
        radius: 10
        color: checked ? root.alpha(root.pink, 0.70) : root.alpha(root.card, 0.72)
        border.width: 1
        border.color: root.alpha(checked ? root.pink : root.borderSoft, 0.28)

        Rectangle {
            width: 16
            height: 16
            radius: 8
            y: 2
            x: parent.checked ? parent.width - width - 2 : 2
            color: Qt.rgba(1, 1, 1, 0.95)

            Behavior on x {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                toggle.checked = !toggle.checked
                toggle.clicked(toggle.checked)
            }
        }
    }

    component SliderLine: Item {
        id: slider

        property real value: 0.6
        property bool interactive: true
        signal moved(real value)

        implicitHeight: 18

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 3
            radius: 2
            color: root.alpha(root.lilac, 0.16)
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * parent.value
            height: 3
            radius: 2
            color: root.alpha(root.pink, 0.60)
        }

        Rectangle {
            x: Math.max(0, Math.min(parent.width - width, parent.width * parent.value - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            radius: 8
            color: Qt.rgba(1, 1, 1, 0.92)
            border.width: 1
            border.color: root.alpha(root.borderSoft, 0.28)
        }

        MouseArea {
            anchors.fill: parent
            enabled: slider.interactive
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor

            function update(mouseX) {
                slider.value = root.clamp01(mouseX / Math.max(1, slider.width))
                slider.moved(slider.value)
            }

            onPressed: function(mouse) { update(mouse.x) }
            onPositionChanged: function(mouse) {
                if (pressed)
                    update(mouse.x)
            }
        }
    }

    component ClockDetail: Flickable {
        contentWidth: width
        contentHeight: column.implicitHeight + 24
        clip: true

        ColumnLayout {
            id: column
            x: 16
            y: 16
            width: Math.max(0, parent.width - 32)
            spacing: 12

            HeaderBar {
                title: root.tr("clockTitle")
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 12
                text: Qt.formatTime(root.clockCurrentDate, "HH:mm:ss")
                color: root.ink
                horizontalAlignment: Text.AlignHCenter
                font.family: root.monoFont
                font.pixelSize: 42
                font.weight: Font.Bold
            }

            SmallText {
                Layout.fillWidth: true
                text: Qt.formatDate(root.clockCurrentDate, "yyyy/MM/dd dddd")
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 15
            }

            SoftButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 190
                Layout.preferredHeight: 28
                label: "● JST / UTC+9"
            }

            Card {
                Layout.preferredHeight: 210
                delay: 60

                LabelText { text: root.tr("nextAlarm") }

                Repeater {
                    model: root.clockAlarms

                    AlarmRow {
                        required property int index
                        required property var modelData

                        alarmIndex: index
                        timeText: modelData.time
                        detailText: root.alarmDetailLabel(modelData.detail)
                        checked: modelData.enabled
                    }
                }

                SoftButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    label: "+ " + root.tr("addAlarm")
                    onClicked: root.addAlarm()
                }
            }

            Card {
                Layout.preferredHeight: 106
                delay: 110

                LabelText { text: root.tr("timer") }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    SoftButton { Layout.fillWidth: true; Layout.preferredHeight: 40; label: "00:10:00"; active: root.clockTimerSeconds === 600; onClicked: root.setTimerPreset(600) }
                    SoftButton { Layout.fillWidth: true; Layout.preferredHeight: 40; label: "00:25:00"; active: root.clockTimerSeconds === 1500; onClicked: root.setTimerPreset(1500) }
                    SoftButton { Layout.fillWidth: true; Layout.preferredHeight: 40; label: "00:50:00"; active: root.clockTimerSeconds === 3000; onClicked: root.setTimerPreset(3000) }
                }
            }

            Card {
                Layout.preferredHeight: 126
                delay: 150

                LabelText { text: root.tr("customTimer") }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    SoftButton { Layout.fillWidth: true; Layout.preferredHeight: 32; label: "-5m"; onClicked: root.adjustTimerSeconds(-300) }
                    SoftButton { Layout.fillWidth: true; Layout.preferredHeight: 32; label: "-1m"; onClicked: root.adjustTimerSeconds(-60) }
                    SoftButton { Layout.fillWidth: true; Layout.preferredHeight: 32; label: "+1m"; onClicked: root.adjustTimerSeconds(60) }
                    SoftButton { Layout.fillWidth: true; Layout.preferredHeight: 32; label: "+5m"; onClicked: root.adjustTimerSeconds(300) }
                }
                RowLayout {
                    Layout.fillWidth: true
                    SoftButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        label: root.formatDuration(root.clockTimerRemaining)
                        onClicked: root.resetTimer()
                    }
                    SoftButton {
                        Layout.preferredWidth: 62
                        Layout.preferredHeight: 38
                        label: root.clockTimerRunning ? "Ⅱ" : "▶"
                        active: true
                        onClicked: root.toggleTimer()
                    }
                }
            }

            CalendarGrid {
                Layout.fillWidth: true
                Layout.preferredHeight: 210
            }
        }
    }

    component AlarmRow: RowLayout {
        id: alarmRow

        property int alarmIndex: 0
        property string timeText: ""
        property string detailText: ""
        property bool checked: true

        Layout.fillWidth: true
        spacing: 10

        LabelText {
            text: parent.timeText
            font.family: root.monoFont
            font.pixelSize: 16
        }
        SmallText {
            Layout.fillWidth: true
            text: parent.detailText
            horizontalAlignment: Text.AlignRight
        }
        SoftButton {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 24
            label: "-"
            onClicked: root.shiftAlarmMinutes(alarmRow.alarmIndex, -1)
        }
        SoftButton {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 24
            label: "+"
            onClicked: root.shiftAlarmMinutes(alarmRow.alarmIndex, 1)
        }
        Toggle {
            checked: alarmRow.checked
            onClicked: function(value) {
                root.setAlarmEnabled(alarmRow.alarmIndex, value)
            }
        }
        SoftButton {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 24
            label: "×"
            enabled: root.clockAlarms.length > 1
            onClicked: root.removeAlarm(alarmRow.alarmIndex)
        }
    }

    component CalendarGrid: Card {
        delay: 230

        LabelText {
            Layout.fillWidth: true
            text: Qt.formatDate(new Date(), "yyyy/MM")
            horizontalAlignment: Text.AlignHCenter
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 7
            rowSpacing: 8
            columnSpacing: 4

                Repeater {
                    model: ["日", "月", "火", "水", "木", "金", "土", "", "", "", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31"]

                Rectangle {
                    required property int index
                    required property string modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: 21
                    radius: 11
                    color: modelData === "18" ? root.alpha(root.pink, 0.42) : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: modelData === "18" ? (root.theme ? root.theme.activeText : "white") : (index < 7 ? root.pink : root.ink)
                        font.family: root.uiFont
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }
            }
        }
    }

    component PaintDetail: ColumnLayout {
        id: paintDetail

        property var currentStroke: null

        function beginStroke(x, y) {
            currentStroke = {
                tool: root.paintTool,
                color: root.paintColor,
                size: root.paintTool === "eraser" ? root.paintBrushSize * 1.7 : root.paintBrushSize,
                opacity: root.paintTool === "eraser" ? 0.95 : root.paintOpacity,
                points: [{ x: x, y: y }]
            }
            root.paintRedoStrokes = []
            paintCanvas.requestPaint()
        }

        function appendPoint(x, y) {
            if (!currentStroke)
                return
            var points = currentStroke.points.slice()
            points.push({ x: x, y: y })
            currentStroke.points = points
            paintCanvas.requestPaint()
        }

        function finishStroke() {
            if (!currentStroke)
                return
            var next = root.paintStrokes.slice()
            next.push(currentStroke)
            root.paintStrokes = next
            currentStroke = null
            paintCanvas.requestPaint()
        }

        function undoStroke() {
            if (root.paintStrokes.length <= 0)
                return
            var next = root.paintStrokes.slice()
            var removed = next.pop()
            var redo = root.paintRedoStrokes.slice()
            redo.push(removed)
            root.paintStrokes = next
            root.paintRedoStrokes = redo
            paintCanvas.requestPaint()
        }

        function redoStroke() {
            if (root.paintRedoStrokes.length <= 0)
                return
            var redo = root.paintRedoStrokes.slice()
            var restored = redo.pop()
            var next = root.paintStrokes.slice()
            next.push(restored)
            root.paintStrokes = next
            root.paintRedoStrokes = redo
            paintCanvas.requestPaint()
        }

        function drawStroke(ctx, stroke) {
            if (!stroke || !stroke.points || stroke.points.length <= 0)
                return

            ctx.save()
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.lineWidth = Math.max(1, stroke.size || 1)
            ctx.strokeStyle = stroke.tool === "eraser" ? root.cssColor(root.card, 0.72) : root.cssColor(stroke.color || root.paintColor, stroke.opacity === undefined ? 1 : stroke.opacity)
            ctx.beginPath()
            ctx.moveTo(stroke.points[0].x, stroke.points[0].y)
            if (stroke.points.length === 1) {
                ctx.lineTo(stroke.points[0].x + 0.1, stroke.points[0].y + 0.1)
            } else {
                for (var i = 1; i < stroke.points.length; ++i)
                    ctx.lineTo(stroke.points[i].x, stroke.points[i].y)
            }
            ctx.stroke()
            ctx.restore()
        }

        anchors.margins: 16
        spacing: 12

        HeaderBar {
            title: root.tr("paintTitle")
            subtitle: root.tr("paintSub")
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 430
            radius: 14
            color: root.alpha(root.card, 0.28)
            border.width: 1
            border.color: root.alpha(root.borderSoft, 0.18)
            clip: true

            Canvas {
                id: paintCanvas

                anchors.fill: parent
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.clearRect(0, 0, width, height)
                    ctx.fillStyle = root.alpha(root.card, 0.18)
                    ctx.fillRect(0, 0, width, height)
                    ctx.strokeStyle = root.alpha(root.borderSoft, 0.08)
                    ctx.lineWidth = 1
                    for (let x = 16; x < width; x += 16) {
                        ctx.beginPath()
                        ctx.moveTo(x, 0)
                        ctx.lineTo(x, height)
                        ctx.stroke()
                    }
                    for (let y = 16; y < height; y += 16) {
                        ctx.beginPath()
                        ctx.moveTo(0, y)
                        ctx.lineTo(width, y)
                        ctx.stroke()
                    }
                    for (var i = 0; i < root.paintStrokes.length; ++i)
                        paintDetail.drawStroke(ctx, root.paintStrokes[i])
                    paintDetail.drawStroke(ctx, paintDetail.currentStroke)
                }

                Connections {
                    target: root
                    function onPaintStrokesChanged() { paintCanvas.requestPaint() }
                    function onPaintToolChanged() { paintCanvas.requestPaint() }
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                cursorShape: root.paintTool === "eraser" ? Qt.PointingHandCursor : Qt.CrossCursor
                onPressed: function(mouse) {
                    mouse.accepted = true
                    paintDetail.beginStroke(mouse.x, mouse.y)
                }
                onPositionChanged: function(mouse) {
                    if (pressed)
                        paintDetail.appendPoint(mouse.x, mouse.y)
                }
                onReleased: function(mouse) {
                    paintDetail.appendPoint(mouse.x, mouse.y)
                    paintDetail.finishStroke()
                }
                onCanceled: paintDetail.finishStroke()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Repeater {
                model: ["paint", "eraser", "box", "memo", "text", "image"]
                SoftButton {
                    required property int index

                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    label: index === 0 ? "✎" : (index === 1 ? "◇" : (index === 4 ? "T" : ""))
                    active: (index === 0 && root.paintTool === "brush") || (index === 1 && root.paintTool === "eraser")
                    onClicked: {
                        if (index === 0)
                            root.paintTool = "brush"
                        else if (index === 1)
                            root.paintTool = "eraser"
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Repeater {
                model: [root.pink, root.lilac, root.theme ? root.theme.accentTertiary : Qt.rgba(0.62, 0.78, 0.88, 1), Qt.rgba(1, 1, 1, 0.92), Qt.rgba(0.03, 0.03, 0.04, 1)]
                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 12
                    color: modelData
                    border.width: root.paintColor === modelData ? 2 : 1
                    border.color: root.paintColor === modelData ? root.pink : root.alpha(root.borderSoft, 0.28)

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.paintColor = modelData
                            root.paintTool = "brush"
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            SmallText { text: root.tr("brushSize") }
            SliderLine {
                Layout.fillWidth: true
                value: (root.paintBrushSize - 2) / 30
                onMoved: function(value) { root.paintBrushSize = Math.round(2 + value * 30) }
            }
            SmallText { text: Math.round(root.paintBrushSize) + "px" }
            SoftButton { Layout.preferredWidth: 86; Layout.preferredHeight: 38; label: root.tr("undo"); enabled: root.paintStrokes.length > 0; onClicked: paintDetail.undoStroke() }
            SoftButton { Layout.preferredWidth: 86; Layout.preferredHeight: 38; label: root.tr("redo"); enabled: root.paintRedoStrokes.length > 0; onClicked: paintDetail.redoStroke() }
        }
    }

    component WallpaperDetail: ColumnLayout {
        id: wallpaperDetail

        anchors.margins: 16
        spacing: 12

        Component.onCompleted: root.ensureWallpaperLoaded()

        HeaderBar {
            title: root.tr("wallpaperTitle")
            subtitle: root.tr("wallpaperSub")
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            SoftButton { Layout.fillWidth: true; Layout.preferredHeight: 42; label: root.tr("collection"); active: true; onClicked: root.ensureWallpaperLoaded() }
            SoftButton { Layout.fillWidth: true; Layout.preferredHeight: 42; label: root.tr("favorites"); enabled: false }
            SoftButton { Layout.fillWidth: true; Layout.preferredHeight: 42; label: root.tr("history"); enabled: false }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: [
                    { label: root.tr("all"), index: 0, width: 66 },
                    { label: root.tr("static"), index: 1, width: 78 },
                    { label: root.tr("live"), index: 2, width: 70 },
                    { label: root.tr("engine"), index: 3, width: 82 }
                ]

                SoftButton {
                    Layout.preferredWidth: modelData.width
                    Layout.preferredHeight: 34
                    label: modelData.label
                    active: root.wallpaperFilterIndex === modelData.index
                    onClicked: root.wallpaperFilterIndex = modelData.index
                }
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: wallpaperColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: wallpaperColumn

                width: parent.width
                spacing: 0

                Text {
                    visible: scanWallpapers.running || root.wallpapers.length <= 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: 94
                    text: scanWallpapers.running ? root.tr("loading") : root.tr("noWallpapers")
                    color: root.inkSoft
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: root.uiFont
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                Repeater {
                    model: root.wallpapers

                    Rectangle {
                        id: wallpaperCard

                        required property int index
                        required property var modelData
                        readonly property bool selected: index === root.wallpaperSelectedIndex
                        readonly property int collapsedHeight: 76
                        readonly property int expandedHeight: 218
                        property bool cardHovered: false
                        property bool cardPressed: false
                        property real focusProgress: selected ? 1 : 0
                        property real pressProgress: cardPressed ? 1 : (cardHovered ? 0.55 : 0)
                        property int cardTopMargin: index === 0 ? 0 : Math.round(-16 + focusProgress * 4)

                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight
                        Layout.topMargin: cardTopMargin
                        implicitHeight: Math.round(collapsedHeight + (expandedHeight - collapsedHeight) * focusProgress)
                        radius: 14
                        clip: true
                        border.width: selected ? 2 : 1
                        border.color: selected ? root.pink : root.alpha(root.borderSoft, 0.22)
                        color: root.alpha(root.card, 0.34)
                        opacity: 0.70 + focusProgress * 0.30
                        scale: 0.965 + focusProgress * 0.035 - pressProgress * 0.008
                        z: selected ? 10 : 1
                        transformOrigin: Item.Center

                        Behavior on focusProgress {
                            NumberAnimation {
                                duration: root.motionPanelGeometry
                                easing.type: root.motionEaseEmphasized
                                easing.bezierCurve: root.motionEmphasizedCurve
                            }
                        }

                        Behavior on pressProgress {
                            NumberAnimation {
                                duration: root.motionHover
                                easing.type: root.motionEaseHover
                            }
                        }

                        Behavior on implicitHeight {
                            NumberAnimation {
                                duration: root.motionPanelGeometry
                                easing.type: root.motionEaseEmphasized
                                easing.bezierCurve: root.motionEmphasizedCurve
                            }
                        }

                        Behavior on cardTopMargin {
                            NumberAnimation {
                                duration: root.motionPanelGeometry
                                easing.type: root.motionEaseEmphasized
                                easing.bezierCurve: root.motionEmphasizedCurve
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: root.motionPanelGeometry
                                easing.type: root.motionEaseEmphasized
                                easing.bezierCurve: root.motionEmphasizedCurve
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: root.motionPanelGeometry
                                easing.type: root.motionEaseEmphasized
                                easing.bezierCurve: root.motionEmphasizedCurve
                            }
                        }

                        Behavior on border.color {
                            ColorAnimation {
                                duration: root.motionHover
                                easing.type: root.motionEaseHover
                            }
                        }

                        Image {
                            anchors.fill: parent
                            source: root.displaySource(wallpaperCard.modelData)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            smooth: true
                            opacity: status === Image.Ready ? 1 : 0
                            scale: 1.06 - wallpaperCard.focusProgress * 0.035 + wallpaperCard.pressProgress * 0.006
                            transformOrigin: Item.Center

                            Behavior on scale {
                                NumberAnimation {
                                    duration: root.motionPanelGeometry
                                    easing.type: root.motionEaseEmphasized
                                    easing.bezierCurve: root.motionEmphasizedCurve
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: root.motionHover
                                    easing.type: root.motionEaseHover
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            visible: wallpaperCard.modelData.kind === "engine" && root.displaySource(wallpaperCard.modelData).length <= 0
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: root.alpha(root.lilac, 0.44) }
                                GradientStop { position: 1.0; color: root.alpha(root.pink, 0.36) }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: Qt.rgba(0, 0, 0, 0.26 - wallpaperCard.focusProgress * 0.13)

                            Behavior on color {
                                ColorAnimation {
                                    duration: root.motionPanelGeometry
                                    easing.type: root.motionEaseEmphasized
                                    easing.bezierCurve: root.motionEmphasizedCurve
                                }
                            }
                        }

                        ColumnLayout {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                                margins: 12
                            }
                            spacing: 2
                            opacity: 0.72 + wallpaperCard.focusProgress * 0.28

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: root.motionPanelGeometry
                                    easing.type: root.motionEaseEmphasized
                                    easing.bezierCurve: root.motionEmphasizedCurve
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: wallpaperCard.modelData.title || wallpaperCard.modelData.label || root.basename(wallpaperCard.modelData.path)
                                color: Qt.rgba(1, 1, 1, 0.94)
                                font.family: root.uiFont
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.wallpaperKindLabel(wallpaperCard.modelData.kind)
                                color: Qt.rgba(1, 1, 1, 0.74)
                                font.family: root.uiFont
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            visible: opacity > 0.02
                            anchors {
                                right: parent.right
                                top: parent.top
                                margins: 10
                            }
                            width: 28
                            height: 28
                            radius: 14
                            color: root.alpha(root.pink, 0.82)
                            opacity: wallpaperCard.focusProgress

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: root.motionPanelGeometry
                                    easing.type: root.motionEaseEmphasized
                                    easing.bezierCurve: root.motionEmphasizedCurve
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "✓"
                                color: root.theme ? root.theme.activeText : "white"
                                font.pixelSize: 13
                                font.weight: Font.Bold
                            }
                        }

                        MouseArea {
                            id: wallpaperMouse

                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressedChanged: wallpaperCard.cardPressed = pressed
                            onContainsMouseChanged: wallpaperCard.cardHovered = containsMouse
                            onClicked: root.wallpaperSelectedIndex = index
                            onDoubleClicked: {
                                root.wallpaperSelectedIndex = index
                                root.applySelectedWallpaper()
                            }
                        }
                    }
                }
            }
        }

        SoftButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            label: (applyWallpaper.running || root.wallpaperApplyState === "applying" ? root.tr("applying") : "✓ " + root.tr("applyWallpaper"))
            active: true
            enabled: !applyWallpaper.running && root.wallpapers.length > 0
            onClicked: root.applySelectedWallpaper()
        }

        LabelText { text: root.tr("quickSelect") }
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Repeater {
                model: Math.min(root.wallpapers.length, 4)

                Rectangle {
                    required property int index
                    readonly property var item: root.wallpapers[index]

                    Layout.fillWidth: true
                    Layout.preferredHeight: 62
                    radius: 10
                    clip: true
                    color: root.alpha(root.card, 0.32)
                    border.width: index === root.wallpaperSelectedIndex ? 2 : 1
                    border.color: index === root.wallpaperSelectedIndex ? root.pink : root.alpha(root.borderSoft, 0.28)

                    Image {
                        anchors.fill: parent
                        source: root.displaySource(parent.item)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.wallpaperSelectedIndex = index
                    }
                }
            }
        }
    }
}
