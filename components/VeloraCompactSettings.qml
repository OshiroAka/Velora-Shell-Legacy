import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Rectangle {
    id: ui

    property var theme: null
    property var controller: null
    property bool embedded: false
    property var palette: null
    property string category: ""
    property bool resetArmed: false
    property string mediaSection: "playback"
    property int activeTab: 1
    property int selectedLyricsBlock: 0

    readonly property color accent: palette ? palette.accent : theme ? theme.accentPrimary : "#3f7cff"
    readonly property color primaryText: palette ? palette.textPrimary : theme ? theme.textPrimary : "#f5f7ff"
    readonly property color secondaryText: palette ? palette.textSecondary : theme ? theme.textSecondary : "#8f99b2"
    readonly property color panelColor: theme
        ? theme.withAlpha(theme.surfacePopup, theme.themeMode === "dark" ? 0.90 : 0.86)
        : Qt.rgba(0.025, 0.045, 0.10, 0.94)
    readonly property color cardColor: theme
        ? theme.withAlpha(theme.surfaceCard, theme.themeMode === "dark" ? 0.44 : 0.58)
        : Qt.rgba(0.04, 0.07, 0.14, 0.82)
    readonly property color inputColor: theme
        ? theme.withAlpha(theme.surfaceInput, theme.themeMode === "dark" ? 0.38 : 0.55)
        : Qt.rgba(0.03, 0.055, 0.12, 0.88)
    readonly property color lineColor: theme
        ? theme.withAlpha(theme.borderSoft, theme.themeMode === "dark" ? 0.13 : 0.30)
        : Qt.rgba(0.35, 0.50, 0.82, 0.22)
    readonly property string uiFont: palette ? palette.bodyFont : theme ? theme.uiFont : "Noto Sans"
    readonly property var tabs: ["Geral", "Barra", "Menu", "Wallpaper", "Moldura", "Lyrics", "Velyrics"]
    readonly property bool externalSurface: controller ? controller.externalSurface === true : false

    implicitHeight: embedded ? (pageLoader.item ? pageLoader.item.implicitHeight : 0) + 50 : 640
    radius: 24
    color: externalSurface || embedded ? "transparent" : panelColor
    border.width: externalSurface || embedded ? 0 : 1
    border.color: theme ? theme.withAlpha(theme.accentPrimary, 0.25) : Qt.rgba(0.20, 0.42, 0.85, 0.34)
    clip: true
    antialiasing: true

    function resetCurrentPage() {
        if (!theme)
            return

        if (embedded && category === "appearance") {
            if (controller) controller.selectTheme("default")
            return
        }
        if (embedded && category === "language") {
            theme.setLanguage("pt-BR")
            return
        }
        if (activeTab === 0) {
            if (controller)
                controller.selectTheme("default")
            theme.setLanguage("pt-BR")
        } else if (activeTab === 1) {
            theme.resetBarAppearance()
            theme.resetBarWidth()
            theme.resetTopBarAppearance()
            theme.setBarLabelsVisible(true)
            theme.setBarBlurEnabled(true)
        } else if (activeTab === 2) {
            theme.setControlCenterPosition("bottom")
        } else if (activeTab === 3 && controller) {
            controller.wallpaperTransition = "fade"
            controller.wallpaperTransitionDuration = 1.0
            controller.wallpaperStaticDelay = 0.12
            controller.saveWallpaperTransition()
            controller.setWallpaperLiveTransition("shader")
            if (!embedded) controller.setTerminalStrongColors(false)
            theme.setWallpaperSelectorPosition("center")
            theme.setWallpaperSelectorBlur(0.55)
        } else if (activeTab === 4) {
            theme.setDesktopFrameEnabled(true)
            theme.setFrameBlurEnabled(true)
            theme.setPopupAttachedToBar(true)
            theme.setVisualizerMode("wave")
            theme.setVisualizerStrength(0.46)
        } else if (activeTab === 5) {
            theme.resetLyricsSettings()
            theme.resetLyricsTransformSettings()
            theme.resetLyricsMaterialSettings()
        } else if (activeTab === 6 && controller) {
            controller.resetVelyricsSettings()
        }
    }

    function overrideValue(map, key, fallback) {
        return map && map[key] !== undefined ? map[key] : fallback
    }

    function updateLyrics(overrides) {
        if (!theme)
            return
        if (controller && controller.visible === false)
            return

        theme.applyLyricsSettings(
            overrideValue(overrides, "enabled", theme.lyricsEnabled),
            overrideValue(overrides, "posX", theme.lyricsPositionX),
            overrideValue(overrides, "posY", theme.lyricsPositionY),
            overrideValue(overrides, "colorMode", theme.lyricsColorMode),
            overrideValue(overrides, "manualColor", theme.lyricsManualColor),
            overrideValue(overrides, "fontSize", theme.lyricsFontSize),
            overrideValue(overrides, "opacity", theme.lyricsOpacity),
            overrideValue(overrides, "spacing", theme.lyricsWordSpacing),
            overrideValue(overrides, "shadow", theme.lyricsShadowEnabled),
            overrideValue(overrides, "uppercase", theme.lyricsUppercase),
            overrideValue(overrides, "layout", theme.lyricsLayoutMode),
            overrideValue(overrides, "animation", theme.lyricsAnimationMode),
            overrideValue(overrides, "activeWord", theme.lyricsActiveWordEnabled),
            overrideValue(overrides, "revealMode", theme.lyricsRevealMode),
            overrideValue(overrides, "pos2X", theme.lyricsSecondPositionX),
            overrideValue(overrides, "pos2Y", theme.lyricsSecondPositionY),
            overrideValue(overrides, "syncOffsetMs", theme.lyricsSyncOffsetMs),
            overrideValue(overrides, "floatEnabled", theme.lyricsFloatEnabled),
            overrideValue(overrides, "floatIntensity", theme.lyricsFloatIntensity),
            overrideValue(overrides, "glowEnabled", theme.lyricsGlowEnabled),
            overrideValue(overrides, "glowIntensity", theme.lyricsGlowIntensity),
            true
        )
    }

    function updateLyricsTransform(overrides) {
        if (!theme)
            return
        theme.applyLyricsTransformSettings(
            overrideValue(overrides, "scale", theme.lyricsScale),
            overrideValue(overrides, "rotation", theme.lyricsRotation),
            overrideValue(overrides, "tiltX", theme.lyricsTiltX),
            overrideValue(overrides, "tiltY", theme.lyricsTiltY),
            true
        )
    }

    function updateLyricsMaterial(overrides) {
        if (!theme)
            return
        theme.applyLyricsMaterialSettings(
            overrideValue(overrides, "mode", theme.lyricsMaterialMode),
            overrideValue(overrides, "intensity", theme.lyricsMaterialIntensity),
            overrideValue(overrides, "depthEnabled", theme.lyricsDepthEnabled),
            overrideValue(overrides, "depthIntensity", theme.lyricsDepthIntensity),
            overrideValue(overrides, "fogEnabled", theme.lyricsFogEnabled),
            overrideValue(overrides, "fogIntensity", theme.lyricsFogIntensity),
            overrideValue(overrides, "maskFeather", theme.lyricsMaskFeather),
            true
        )
    }

    function lyricsPreviewWords() {
        const words = ["THE", "FEAR", "OF", "WAR", "ARISING"]
        const mode = theme ? theme.lyricsRevealMode : "progressive"
        if (mode === "current")
            return ["FEAR"]
        if (mode === "line")
            return words
        return words.slice(0, 2)
    }

    function lyricsPreviewSourceIndex(index) {
        return theme && theme.lyricsRevealMode === "current" ? 1 : index
    }

    function lyricsPreviewColor(index) {
        if (!theme)
            return primaryText
        if (theme.lyricsColorMode === "manual")
            return theme.lyricsManualColor
        if (theme.lyricsColorMode === "palette" && theme.lyricsPalette && theme.lyricsPalette.length > 0)
            return theme.lyricsPalette[index % theme.lyricsPalette.length]
        return theme.lyricsPywalColor
    }

    function selectLyricsLayout(layoutId) {
        if (layoutId === "two" && theme && theme.lyricsLayoutMode !== "two") {
            updateLyrics({ layout: "two", posX: 8, posY: 11, pos2X: 72, pos2Y: 10, revealMode: "progressive" })
            return
        }
        if (layoutId === "four" && theme && theme.lyricsLayoutMode !== "four") {
            selectedLyricsBlock = 0
            updateLyrics({ layout: "four", posX: 8, posY: 11, pos2X: 72, pos2Y: 10, revealMode: "progressive" })
            theme.applyLyricsBlocksSettings(8, 58, 72, 58, theme.lyricsBlockStyleData, true)
            return
        }
        updateLyrics({ layout: layoutId })
    }

    function lyricsBlockCount() {
        if (!theme)
            return 1
        return theme.lyricsLayoutMode === "four" ? 4 : (theme.lyricsLayoutMode === "two" ? 2 : 1)
    }

    function clampSelectedLyricsBlock() {
        selectedLyricsBlock = Math.max(0, Math.min(lyricsBlockCount() - 1, selectedLyricsBlock))
        return selectedLyricsBlock
    }

    function selectedLyricsBlockX() {
        const block = clampSelectedLyricsBlock()
        if (block === 1)
            return theme ? theme.lyricsSecondPositionX : 72
        if (block === 2)
            return theme ? theme.lyricsThirdPositionX : 8
        if (block === 3)
            return theme ? theme.lyricsFourthPositionX : 72
        return theme ? theme.lyricsPositionX : 8
    }

    function selectedLyricsBlockY() {
        const block = clampSelectedLyricsBlock()
        if (block === 1)
            return theme ? theme.lyricsSecondPositionY : 10
        if (block === 2)
            return theme ? theme.lyricsThirdPositionY : 58
        if (block === 3)
            return theme ? theme.lyricsFourthPositionY : 58
        return theme ? theme.lyricsPositionY : 11
    }

    function updateSelectedLyricsBlockPosition(axis, value) {
        if (!theme)
            return
        const block = clampSelectedLyricsBlock()
        if (block === 0)
            updateLyrics(axis === "x" ? { posX: value } : { posY: value })
        else if (block === 1)
            updateLyrics(axis === "x" ? { pos2X: value } : { pos2Y: value })
        else {
            const pos3X = block === 2 && axis === "x" ? value : theme.lyricsThirdPositionX
            const pos3Y = block === 2 && axis === "y" ? value : theme.lyricsThirdPositionY
            const pos4X = block === 3 && axis === "x" ? value : theme.lyricsFourthPositionX
            const pos4Y = block === 3 && axis === "y" ? value : theme.lyricsFourthPositionY
            theme.applyLyricsBlocksSettings(pos3X, pos3Y, pos4X, pos4Y, theme.lyricsBlockStyleData, true)
        }
    }

    function updateSelectedLyricsBlockStyle(overrides) {
        if (!theme)
            return
        const block = clampSelectedLyricsBlock()
        theme.applyLyricsBlockStyle(
            block,
            overrideValue(overrides, "colorMode", theme.lyricsBlockColorMode(block)),
            overrideValue(overrides, "manualColor", theme.lyricsBlockManualColor(block)),
            overrideValue(overrides, "glowMode", theme.lyricsBlockGlowMode(block)),
            overrideValue(overrides, "glowIntensity", theme.lyricsBlockGlowIntensity(block)),
            true
        )
    }





    Keys.onEscapePressed: if (controller) controller.closeRequested()

    component SectionTitle: Text {
        required property string label
        text: label
        color: ui.accent
        font.family: ui.uiFont
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.letterSpacing: 0.4
    }

    component Divider: Rectangle {
        implicitHeight: 1
        color: ui.lineColor
    }

    component UiIcon: Canvas {
        id: glyph

        property string iconName: "settings"
        property color lineColor: ui.primaryText

        antialiasing: true
        onIconNameChanged: requestPaint()
        onLineColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        function boxPath(ctx, x, y, w, h, r) {
            ctx.beginPath()
            ctx.moveTo(x + r, y)
            ctx.lineTo(x + w - r, y)
            ctx.quadraticCurveTo(x + w, y, x + w, y + r)
            ctx.lineTo(x + w, y + h - r)
            ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h)
            ctx.lineTo(x + r, y + h)
            ctx.quadraticCurveTo(x, y + h, x, y + h - r)
            ctx.lineTo(x, y + r)
            ctx.quadraticCurveTo(x, y, x + r, y)
            ctx.closePath()
        }

        onPaint: {
            const ctx = getContext("2d")
            const s = Math.min(width, height)
            const ox = (width - s) / 2
            const oy = (height - s) / 2
            const cx = width / 2
            const cy = height / 2
            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = lineColor
            ctx.fillStyle = lineColor
            ctx.lineWidth = Math.max(1.4, s * 0.075)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            if (iconName === "check") {
                ctx.beginPath()
                ctx.moveTo(ox + s * 0.22, oy + s * 0.52)
                ctx.lineTo(ox + s * 0.43, oy + s * 0.72)
                ctx.lineTo(ox + s * 0.80, oy + s * 0.29)
                ctx.stroke()
            } else if (iconName === "refresh") {
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.29, Math.PI * 0.25, Math.PI * 1.78)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(ox + s * 0.18, oy + s * 0.29)
                ctx.lineTo(ox + s * 0.18, oy + s * 0.52)
                ctx.lineTo(ox + s * 0.38, oy + s * 0.42)
                ctx.stroke()
            } else if (iconName === "discord") {
                boxPath(ctx, ox + s * 0.17, oy + s * 0.27, s * 0.66, s * 0.48, s * 0.18)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(ox + s * 0.40, oy + s * 0.50, s * 0.045, 0, Math.PI * 2)
                ctx.arc(ox + s * 0.60, oy + s * 0.50, s * 0.045, 0, Math.PI * 2)
                ctx.fill()
                ctx.beginPath()
                ctx.arc(cx, oy + s * 0.54, s * 0.19, 0.16, Math.PI - 0.16)
                ctx.stroke()
            } else if (iconName === "battery") {
                boxPath(ctx, ox + s * 0.17, oy + s * 0.30, s * 0.60, s * 0.40, s * 0.07)
                ctx.stroke()
                ctx.fillRect(ox + s * 0.78, oy + s * 0.42, s * 0.07, s * 0.16)
                ctx.fillRect(ox + s * 0.25, oy + s * 0.38, s * 0.34, s * 0.24)
            } else if (iconName === "sun") {
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.17, 0, Math.PI * 2)
                ctx.stroke()
                for (let i = 0; i < 8; i += 1) {
                    const a = i * Math.PI / 4
                    ctx.beginPath()
                    ctx.moveTo(cx + Math.cos(a) * s * 0.28, cy + Math.sin(a) * s * 0.28)
                    ctx.lineTo(cx + Math.cos(a) * s * 0.39, cy + Math.sin(a) * s * 0.39)
                    ctx.stroke()
                }
            } else if (iconName === "wallpaper") {
                boxPath(ctx, ox + s * 0.13, oy + s * 0.20, s * 0.74, s * 0.60, s * 0.06)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(ox + s * 0.19, oy + s * 0.70)
                ctx.lineTo(ox + s * 0.39, oy + s * 0.49)
                ctx.lineTo(ox + s * 0.53, oy + s * 0.62)
                ctx.lineTo(ox + s * 0.70, oy + s * 0.43)
                ctx.lineTo(ox + s * 0.82, oy + s * 0.62)
                ctx.stroke()
            } else if (iconName === "volume") {
                ctx.beginPath()
                ctx.moveTo(ox + s * 0.18, oy + s * 0.42)
                ctx.lineTo(ox + s * 0.34, oy + s * 0.42)
                ctx.lineTo(ox + s * 0.53, oy + s * 0.26)
                ctx.lineTo(ox + s * 0.53, oy + s * 0.74)
                ctx.lineTo(ox + s * 0.34, oy + s * 0.58)
                ctx.lineTo(ox + s * 0.18, oy + s * 0.58)
                ctx.closePath()
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(ox + s * 0.52, cy, s * 0.25, -0.8, 0.8)
                ctx.stroke()
            } else if (iconName === "box") {
                ctx.beginPath()
                ctx.moveTo(cx, oy + s * 0.16)
                ctx.lineTo(ox + s * 0.82, oy + s * 0.34)
                ctx.lineTo(ox + s * 0.82, oy + s * 0.68)
                ctx.lineTo(cx, oy + s * 0.84)
                ctx.lineTo(ox + s * 0.18, oy + s * 0.68)
                ctx.lineTo(ox + s * 0.18, oy + s * 0.34)
                ctx.closePath()
                ctx.moveTo(ox + s * 0.18, oy + s * 0.34)
                ctx.lineTo(cx, oy + s * 0.51)
                ctx.lineTo(ox + s * 0.82, oy + s * 0.34)
                ctx.moveTo(cx, oy + s * 0.51)
                ctx.lineTo(cx, oy + s * 0.84)
                ctx.stroke()
            } else {
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.21, 0, Math.PI * 2)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.07, 0, Math.PI * 2)
                ctx.stroke()
                for (let i = 0; i < 8; i += 1) {
                    const a = i * Math.PI / 4
                    ctx.beginPath()
                    ctx.moveTo(cx + Math.cos(a) * s * 0.27, cy + Math.sin(a) * s * 0.27)
                    ctx.lineTo(cx + Math.cos(a) * s * 0.39, cy + Math.sin(a) * s * 0.39)
                    ctx.stroke()
                }
            }
        }
    }

    component ChoiceButton: Rectangle {
        id: choice

        property string label: ""
        property string iconName: ""
        property bool active: false
        property bool compact: false
        signal clicked()
        activeFocusOnTab: enabled
        Accessible.role: Accessible.Button; Accessible.name: label
        Keys.onReturnPressed: clicked()
        Keys.onSpacePressed: clicked()

        implicitHeight: compact ? 34 : 38
        radius: 9
        color: active ? ui.theme.withAlpha(ui.accent, 0.22) : ui.inputColor
        border.width: 1
        border.color: active ? ui.theme.withAlpha(ui.accent, 0.82) : ui.lineColor

        Row {
            anchors.centerIn: parent
            spacing: 6

            UiIcon {
                visible: choice.iconName.length > 0
                width: visible ? 18 : 0
                height: 18
                iconName: choice.iconName
                lineColor: choice.active ? ui.accent : ui.secondaryText
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: choice.label
                color: choice.active ? ui.primaryText : ui.secondaryText
                font.family: ui.uiFont
                font.pixelSize: 11
                font.weight: choice.active ? Font.DemiBold : Font.Medium
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: choice.clicked()
        }
    }

    component ToggleRow: Item {
        id: toggleRow

        property string label: ""
        property string hint: ""
        property bool checked: false
        signal toggled()
        activeFocusOnTab: enabled
        Accessible.role: Accessible.CheckBox; Accessible.name: label; Accessible.checked: checked
        Accessible.description: hint
        Accessible.onPressAction: toggled()
        Keys.onSpacePressed: toggled()
        Keys.onReturnPressed: toggled()

        implicitHeight: ui.embedded ? 36 : 54

        Column {
            anchors.left: parent.left
            anchors.right: switchTrack.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Text {
                width: parent.width
                text: toggleRow.label
                color: ui.primaryText
                font.family: ui.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                visible: !ui.embedded && text.length > 0
                text: toggleRow.hint
                color: ui.secondaryText
                font.family: ui.uiFont
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }

        Rectangle {
            id: switchTrack
            x: Math.min(parent.width-width, 360)
            anchors.verticalCenter: parent.verticalCenter
            width: 42
            height: 24
            radius: 12
            color: toggleRow.checked ? ui.accent : ui.inputColor
            border.width: toggleRow.checked ? 0 : 1
            border.color: ui.lineColor

            Rectangle {
                width: 18
                height: 18
                radius: 9
                x: toggleRow.checked ? parent.width - width - 3 : 3
                anchors.verticalCenter: parent.verticalCenter
                color: toggleRow.checked ? "#ffffff" : ui.secondaryText

                Behavior on x { NumberAnimation { duration: ui.palette && ui.palette.config && ui.palette.config.reducedMotion ? 0 : 140; easing.type: Easing.OutCubic } }
            }
        }

        ToolTip.visible: ui.embedded && (togglePointer.containsMouse || toggleRow.activeFocus) && hint.length > 0
        ToolTip.delay: 600
        ToolTip.text: hint
        MouseArea {
            id: togglePointer
            hoverEnabled: true
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: toggleRow.toggled()
        }
    }

    component SettingSlider: VeloraSettingsSlider {
        theme: ui.palette || sliderPalette
        signal valueRequested(real newValue)
        signal valueCommitted(real newValue)
        onEdited: value => valueRequested(value)
        onFinalized: value => valueCommitted(value)
    }
    QtObject {
        id: sliderPalette
        readonly property color textPrimary: ui.primaryText
        readonly property color textSecondary: ui.secondaryText
        readonly property color accent: ui.accent
        readonly property color borderStrong: ui.lineColor
        readonly property color borderSubtle: ui.lineColor
        readonly property string bodyFont: ui.uiFont
    }


    component TextInputRow: Item {
        id: inputRow

        property string label: ""
        property string hint: ""
        property string value: ""
        signal valueSubmitted(string newValue)

        implicitHeight: hint.length > 0 ? 76 : 62

        Column {
            anchors.left: parent.left
            anchors.right: inputBox.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Text {
                width: parent.width
                text: inputRow.label
                color: ui.primaryText
                font.family: ui.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                visible: inputRow.hint.length > 0
                text: inputRow.hint
                color: ui.secondaryText
                font.family: ui.uiFont
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }

        Rectangle {
            id: inputBox
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 126
            height: 38
            radius: 9
            color: ui.inputColor
            border.width: 1
            border.color: colorInput.activeFocus ? ui.accent : ui.lineColor

            TextInput {
                id: colorInput
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                text: inputRow.value
                color: ui.primaryText
                selectionColor: ui.theme.withAlpha(ui.accent, 0.45)
                selectedTextColor: ui.primaryText
                font.family: ui.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
                clip: true

                onEditingFinished: inputRow.valueSubmitted(text)
                Keys.onReturnPressed: {
                    inputRow.valueSubmitted(text)
                    focus = false
                }
                Keys.onEnterPressed: {
                    inputRow.valueSubmitted(text)
                    focus = false
                }
            }
        }
    }

    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: ui.embedded ? 0 : 76
        visible: !ui.embedded

        UiIcon {
            anchors.left: parent.left
            anchors.leftMargin: 22
            anchors.verticalCenter: parent.verticalCenter
            width: 35
            height: 35
            iconName: "settings"
            lineColor: ui.primaryText
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 68
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Text {
                text: "Configurações"
                color: ui.primaryText
                font.family: ui.uiFont
                font.pixelSize: 17
                font.weight: Font.DemiBold
            }

            Text {
                text: "Personalize sua experiência"
                color: ui.secondaryText
                font.family: ui.uiFont
                font.pixelSize: 10
            }
        }
    }

    Rectangle {
        id: tabBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        height: ui.embedded ? 0 : 43
        visible: !ui.embedded
        radius: 10
        color: ui.inputColor
        border.width: 1
        border.color: ui.lineColor

        Row {
            anchors.fill: parent
            anchors.margins: 2

            Repeater {
                model: ui.tabs

                Rectangle {
                    id: tabButton
                    required property int index
                    required property string modelData

                    width: parent.width / ui.tabs.length
                    height: parent.height
                    radius: 8
                    color: ui.activeTab === index ? ui.theme.withAlpha(ui.accent, 0.20) : "transparent"
                    border.width: ui.activeTab === index ? 1 : 0
                    border.color: ui.theme.withAlpha(ui.accent, 0.75)

                    Text {
                        anchors.centerIn: parent
                        text: tabButton.modelData
                        color: ui.activeTab === tabButton.index ? ui.primaryText : ui.secondaryText
                        font.family: ui.uiFont
                        font.pixelSize: 10
                        font.weight: ui.activeTab === tabButton.index ? Font.DemiBold : Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ui.activeTab = tabButton.index
                            scroller.contentY = 0
                        }
                    }
                }
            }
        }
    }

    Flickable {
        id: scroller
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: ui.embedded ? parent.top : tabBar.bottom
        anchors.bottom: footer.top
        anchors.leftMargin: ui.embedded ? 0 : 18
        anchors.rightMargin: ui.embedded ? 0 : 12
        anchors.topMargin: ui.embedded ? 0 : 12
        anchors.bottomMargin: ui.embedded ? 0 : 8
        clip: true
        contentWidth: width
        contentHeight: pageLoader.item ? pageLoader.item.implicitHeight + 8 : 0
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 2600
        interactive: !ui.embedded

        Loader {
            id: pageLoader
            width: scroller.width - (ui.embedded ? 0 : 6)
            sourceComponent: ui.embedded
                ? (ui.category === "appearance" ? themePage
                : ui.category === "language" ? languagePage
                : ui.category === "system" ? systemPage
                : ui.category === "bar" ? sidebarPage
                : ui.category === "wallpapers" ? wallpaperPage
                : ui.category === "desktop" ? framePage
                : ui.category === "media" ? (ui.mediaSection === "position" ? lyricsPosition
                    : ui.mediaSection === "style" ? lyricsStyle
                    : ui.mediaSection === "material" ? lyricsMaterial
                    : ui.mediaSection === "velyrics" ? velyricsPage : lyricsPlayback)
                : null)
                : ui.activeTab === 0 ? generalPage
                : (ui.activeTab === 1 ? barPage
                : (ui.activeTab === 2 ? menuPage
                : (ui.activeTab === 3 ? wallpaperPage
                : (ui.activeTab === 4 ? framePage
                : (ui.activeTab === 5 ? lyricsPlayback : velyricsPage)))))
        }

        Rectangle {
            anchors.right: parent.right
            y: scroller.visibleArea.yPosition * scroller.height
            width: 3
            height: Math.max(24, scroller.visibleArea.heightRatio * scroller.height)
            radius: 2
            color: ui.theme.withAlpha(ui.accent, 0.40)
            visible: scroller.visibleArea.heightRatio < 0.99
        }
    }

    Item {
        id: footer
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: ui.embedded && ui.category === "system" ? 0 : 50
        visible: height > 0
        ChoiceButton { x: 18; anchors.verticalCenter: parent.verticalCenter; width: 114
            objectName: "legacy.reset"
            label: ui.resetArmed ? "Confirmar" : "Redefinir"; onClicked: {
                if (!ui.resetArmed) { ui.resetArmed = true; return }
                const tabs = {appearance:0,language:0,bar:1,wallpapers:3,desktop:4,media:ui.mediaSection === "velyrics" ? 6 : 5}
                if (ui.embedded) ui.activeTab = tabs[ui.category] === undefined ? 0 : tabs[ui.category]
                ui.resetCurrentPage(); ui.resetArmed = false
            } }
        Text { anchors.right: parent.right; anchors.rightMargin: 18; anchors.verticalCenter: parent.verticalCenter
            visible: !ui.embedded
            text: ui.controller ? ui.controller.noticeText || "Salvamento automático" : ""
            color: ui.secondaryText; font.pixelSize: 11; font.family: ui.uiFont }
    }


    Component { id: generalPage; Column { spacing: 12
        Loader { width: parent.width; sourceComponent: themePage }
        Loader { width: parent.width; sourceComponent: languagePage }
        Loader { width: parent.width; sourceComponent: powerPage }
    } }
    Component { id: themePage; Column { objectName: "legacy.theme"; width: parent ? parent.width : 400; spacing: 12
            SectionTitle { label: "APARÊNCIA" }

            Text {
                text: "Tema do sistema"
                color: ui.primaryText
                font.family: ui.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            Flow {
                width: parent.width
                spacing: 7

                Repeater {
                    model: ui.controller ? ui.controller.themeOptions() : []

                    ChoiceButton {
                        required property var modelData
                        width: Math.min(220, (parent.width - 7) / 2)
                        label: modelData.title
                        active: ui.theme && ui.theme.themeId === modelData.id
                        onClicked: if (ui.controller) ui.controller.selectTheme(modelData.id)
                    }
                }
            }


    } }

    Component { id: languagePage; Column { objectName: "legacy.language"; width: parent ? parent.width : 400; spacing: 12

            SectionTitle { label: "IDIOMA" }

            Flow {
                width: parent.width
                spacing: 7

                Repeater {
                    model: ui.controller ? ui.controller.languageOptions() : []

                    ChoiceButton {
                        required property var modelData
                        width: Math.min(180, (parent.width - 14) / 3)
                        label: modelData.shortLabel
                        active: ui.theme && ui.theme.language === modelData.id
                        onClicked: if (ui.controller) ui.controller.selectLanguage(modelData.id)
                    }
                }
            }


    } }

    Component { id: powerPage; Column { width: parent ? parent.width : 400; spacing: 12

            SectionTitle { label: "ENERGIA" }

            Row {
                width: parent.width
                spacing: 7

                ChoiceButton {
                    width: Math.min(220, (parent.width - 7) / 2)
                    label: "Equilibrado"
                    iconName: "battery"
                    active: ui.controller && ui.controller.powerProfile === "balanced"
                    onClicked: if (ui.controller) ui.controller.setPowerProfile("balanced")
                }

                ChoiceButton {
                    width: Math.min(220, (parent.width - 7) / 2)
                    label: "Desempenho"
                    iconName: "sun"
                    active: ui.controller && ui.controller.powerProfile === "performance"
                    onClicked: if (ui.controller) ui.controller.setPowerProfile("performance")
                }
            }
    } }


    Component {
        id: barPage

        Column {
            spacing: 8

            SectionTitle { label: "APARÊNCIA" }

            SettingSlider {
                width: parent.width
                label: "Tamanho dos ícones"
                hint: "O layout atual usa largura fixa; o valor antigo é preservado."
                minimum: 32
                maximum: 56
                value: ui.theme ? ui.theme.barIconSize : 48
                valueText: Math.round(value) + "px"
                onValueRequested: function(newValue) {
                    if (ui.theme) ui.theme.applyBarAppearance(Math.round(newValue), ui.theme.barIconOpacity, ui.theme.barIconSpacing, ui.theme.barAutoHideEnabled, ui.theme.barCornerRadius, true)
                }
            }

            SettingSlider {
                enabled: false
                width: parent.width
                label: "Largura da barra"
                hint: "Redimensiona barra, relógio e área reservada"
                minimum: 88
                maximum: 136
                value: ui.theme ? ui.theme.barWidth : 112
                valueText: Math.round(value) + "px"
                onValueRequested: function(newValue) { if (ui.theme) ui.theme.setBarWidth(newValue, false) }
                onValueCommitted: function(newValue) { if (ui.theme) ui.theme.setBarWidth(newValue, true) }
            }

            Row {
                width: parent.width
                spacing: (width - 4 * 46) / 3

                Repeater {
                    model: [32, 40, 48, 56]

                    Rectangle {
                        id: iconPreview
                        required property int modelData
                        width: 46
                        height: 42
                        radius: 9
                        color: ui.theme && Math.abs(ui.theme.barIconSize - modelData) < 3 ? ui.theme.withAlpha(ui.accent, 0.20) : ui.inputColor
                        border.width: 1
                        border.color: ui.theme && Math.abs(ui.theme.barIconSize - modelData) < 3 ? ui.accent : ui.lineColor

                        UiIcon {
                            anchors.centerIn: parent
                            width: Math.round(iconPreview.modelData * 0.48)
                            height: width
                            iconName: "discord"
                            lineColor: ui.primaryText
                            opacity: ui.theme ? ui.theme.barIconOpacity : 0.8
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (ui.theme) ui.theme.applyBarAppearance(iconPreview.modelData, ui.theme.barIconOpacity, ui.theme.barIconSpacing, ui.theme.barAutoHideEnabled, ui.theme.barCornerRadius, true)
                        }
                    }
                }
            }

            SettingSlider {
                width: parent.width
                label: "Opacidade dos ícones"
                hint: "Transparência dos ícones da barra"
                minimum: 0.30
                maximum: 1.0
                value: ui.theme ? ui.theme.barIconOpacity : 0.8
                valueText: Math.round(value * 100) + "%"
                onValueRequested: function(newValue) {
                    if (ui.theme) ui.theme.applyBarAppearance(ui.theme.barIconSize, newValue, ui.theme.barIconSpacing, ui.theme.barAutoHideEnabled, ui.theme.barCornerRadius, true)
                }
            }

            SettingSlider {
                width: parent.width
                label: "Transparência da barra lateral"
                hint: "Controla somente a superfície da barra lateral"
                minimum: ui.theme ? ui.theme.minOpacityForRole("sidebar") : 0.25
                maximum: 0.98
                value: ui.theme ? ui.theme.barOpacity : 0.88
                valueText: Math.round(value * 100) + "%"
                onValueRequested: function(newValue) { if (ui.theme) ui.theme.applyBarOpacity(newValue) }
            }

            SettingSlider {
                width: parent.width
                label: "Espaçamento entre ícones"
                hint: "Distância vertical entre os ícones"
                minimum: 8
                maximum: 24
                value: ui.theme ? ui.theme.barIconSpacing : 16
                valueText: Math.round(value) + "px"
                onValueRequested: function(newValue) {
                    if (ui.theme) ui.theme.applyBarAppearance(ui.theme.barIconSize, ui.theme.barIconOpacity, Math.round(newValue), ui.theme.barAutoHideEnabled, ui.theme.barCornerRadius, true)
                }
            }

            Divider { width: parent.width }
            SectionTitle { label: "POSIÇÃO" }

            Row {
                width: parent.width
                spacing: 7

                Column {
                    width: parent.width - positionButtons.width - 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        text: "Posição da barra"
                        color: ui.primaryText
                        font.family: ui.uiFont
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        text: "Escolha onde a barra será exibida"
                        color: ui.secondaryText
                        font.family: ui.uiFont
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }
                }

                Row {
                    id: positionButtons
                    width: implicitWidth
                    spacing: 4

                    ChoiceButton {
                        width: 66
                        compact: true
                        label: "Esquerda"
                        active: ui.theme && ui.theme.barPosition === "left"
                        onClicked: {
                            if (ui.theme) {
                                ui.theme.setBarPosition("left")
                            }
                        }
                    }

                    ChoiceButton {
                        width: 60
                        compact: true
                        label: "Direita"
                        active: ui.theme && ui.theme.barPosition === "right"
                        onClicked: {
                            if (ui.theme) {
                                ui.theme.setBarPosition("right")
                            }
                        }
                    }
                }
            }

            Divider { width: parent.width }
            SectionTitle { label: "COMPORTAMENTO" }

            ToggleRow {
                width: parent.width
                label: "Mostrar rótulos"
                hint: "Disponível apenas no layout antigo da barra superior."
                checked: ui.theme ? ui.theme.barLabelsVisible : true
                onToggled: if (ui.theme) ui.theme.setBarLabelsVisible(!ui.theme.barLabelsVisible)
            }

            ToggleRow {
                width: parent.width
                label: "Auto-ocultar"
                hint: "Oculta a barra automaticamente"
                checked: ui.theme ? ui.theme.barAutoHideEnabled : false
                onToggled: if (ui.theme) ui.theme.applyBarAppearance(ui.theme.barIconSize, ui.theme.barIconOpacity, ui.theme.barIconSpacing, !ui.theme.barAutoHideEnabled, ui.theme.barCornerRadius, true)
            }

            Divider { width: parent.width }
            SectionTitle { label: "ESTILO" }

            SettingSlider {
                width: parent.width
                label: "Borda arredondada"
                hint: "Arredondamento dos cantos da barra"
                minimum: 0
                maximum: 30
                value: ui.theme ? ui.theme.barCornerRadius : 16
                valueText: Math.round(value) + "px"
                onValueRequested: function(newValue) {
                    if (ui.theme) ui.theme.applyBarAppearance(ui.theme.barIconSize, ui.theme.barIconOpacity, ui.theme.barIconSpacing, ui.theme.barAutoHideEnabled, Math.round(newValue), true)
                }
            }

            Row {
                width: parent.width
                spacing: 8

                Column {
                    width: parent.width - blurChoice.width - 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        text: "Efeito de fundo"
                        color: ui.primaryText
                        font.family: ui.uiFont
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: "Estilo do fundo da barra"
                        color: ui.secondaryText
                        font.family: ui.uiFont
                        font.pixelSize: 10
                    }
                }

                ChoiceButton {
                    id: blurChoice
                    objectName: "legacy.bar-blur"
                    width: 148
                    label: ui.theme && ui.theme.barBlurEnabled ? "Desfoque (Blur)" : "Sólido"
                    active: ui.theme ? ui.theme.barBlurEnabled : true
                    onClicked: if (ui.theme) ui.theme.setBarBlurEnabled(!ui.theme.barBlurEnabled)
                }
            }
        }
    }

    Component {
        id: menuPage

        Column {
            objectName: "legacy.menu-position"
            spacing: 12

            SectionTitle { label: "CENTRAL DE CONTROLE" }

            Text {
                width: parent.width
                text: "Escolha onde a Central será exibida ao pressionar SUPER+R"
                color: ui.secondaryText
                font.family: ui.uiFont
                font.pixelSize: 10
                wrapMode: Text.WordWrap
            }

            Row {
                width: parent.width
                spacing: 10

                Repeater {
                    model: [
                        { id: "bottom", title: "Inferior central", hint: "Central integrada à borda inferior" },
                        { id: "right", title: "Lateral direita", hint: "Central alta inspirada no Android" }
                    ]

                    Rectangle {
                        id: menuChoice
                        required property var modelData
                        readonly property bool selected: ui.theme && ui.theme.controlCenterPosition === modelData.id

                        width: (parent.width - 10) / 2
                        height: 232
                        radius: 14
                        color: selected ? ui.theme.withAlpha(ui.accent, 0.17) : ui.cardColor
                        border.width: selected ? 2 : 1
                        border.color: selected ? ui.accent : ui.lineColor
                        clip: true

                        Rectangle {
                            id: previewStage
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 10
                            height: 150
                            radius: 10
                            color: ui.theme.withAlpha(ui.theme.surfaceBase, 0.38)
                            border.width: 1
                            border.color: ui.theme.withAlpha(ui.theme.borderSoft, 0.20)

                            Rectangle {
                                visible: menuChoice.modelData.id === "bottom"
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 9
                                width: parent.width * 0.74
                                height: 62
                                radius: 11
                                color: ui.theme.withAlpha(ui.accent, 0.30)
                                border.width: 1
                                border.color: ui.theme.withAlpha(ui.theme.borderSoft, 0.48)

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 5
                                    Repeater {
                                        model: 4
                                        Rectangle { width: 18; height: 18; radius: 5; color: ui.theme.withAlpha(index % 2 === 0 ? ui.theme.accentPrimary : ui.theme.accentTertiary, 0.56) }
                                    }
                                }
                            }

                            Rectangle {
                                visible: menuChoice.modelData.id === "right"
                                anchors.right: parent.right
                                anchors.rightMargin: 9
                                anchors.verticalCenter: parent.verticalCenter
                                width: 70
                                height: 128
                                radius: 12
                                color: ui.theme.withAlpha(ui.accent, 0.30)
                                border.width: 1
                                border.color: ui.theme.withAlpha(ui.theme.borderSoft, 0.48)

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 7
                                    spacing: 5
                                    Rectangle { width: parent.width; height: 17; radius: 5; color: ui.theme.withAlpha(ui.theme.accentPrimary, 0.48) }
                                    Row {
                                        width: parent.width
                                        spacing: 4
                                        Rectangle { width: (parent.width - 4) / 2; height: 18; radius: 6; color: ui.theme.withAlpha(ui.theme.accentTertiary, 0.48) }
                                        Rectangle { width: (parent.width - 4) / 2; height: 18; radius: 6; color: ui.theme.withAlpha(ui.theme.accentSecondary, 0.48) }
                                    }
                                    Rectangle { width: parent.width; height: 31; radius: 6; color: ui.theme.withAlpha(ui.theme.accentPrimary, 0.38) }
                                    Grid {
                                        columns: 3
                                        spacing: 4
                                        Repeater { model: 6; Rectangle { width: 15; height: 15; radius: 5; color: ui.theme.withAlpha(index % 2 === 0 ? ui.theme.accentSecondary : ui.theme.accentTertiary, 0.46) } }
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: previewStage.bottom
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            anchors.topMargin: 9
                            text: menuChoice.modelData.title
                            color: ui.primaryText
                            font.family: ui.uiFont
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            anchors.bottomMargin: 10
                            text: menuChoice.modelData.hint
                            color: ui.secondaryText
                            font.family: ui.uiFont
                            font.pixelSize: 9
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (ui.theme) ui.theme.setControlCenterPosition(menuChoice.modelData.id)
                        }
                    }
                }
            }

            Divider { width: parent.width }

            Text {
                width: parent.width
                text: ui.theme && ui.theme.controlCenterPosition === "right"
                    ? "A Central abre à direita. Som, Wi‑Fi, Tela, Notificações, Bluetooth e Bateria continuam no centro inferior."
                    : "A Central e as seis páginas de sistema permanecem juntas no centro inferior."
                color: ui.secondaryText
                font.family: ui.uiFont
                font.pixelSize: 10
                wrapMode: Text.WordWrap
            }
        }
    }

    Component {
        id: wallpaperPage

        Column {
            spacing: 12

            SectionTitle { label: "SELETOR" }

            Text {
                text: "Posição do seletor de wallpapers"
                color: ui.primaryText
                font.family: ui.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            Row {
                width: parent.width
                spacing: 7

                ChoiceButton {
                    width: Math.min(220, (parent.width - 7) / 2)
                    label: "Centro"
                    iconName: "wallpaper"
                    active: ui.theme && ui.theme.wallpaperSelectorPosition === "center"
                    onClicked: if (ui.theme) ui.theme.setWallpaperSelectorPosition("center")
                }

                ChoiceButton {
                    width: Math.min(220, (parent.width - 7) / 2)
                    label: "Inferior (clássico)"
                    iconName: "box"
                    active: ui.theme && ui.theme.wallpaperSelectorPosition === "bottom"
                    onClicked: if (ui.theme) ui.theme.setWallpaperSelectorPosition("bottom")
                }
            }

            Text {
                width: parent.width
                text: ui.theme && ui.theme.wallpaperSelectorPosition === "bottom"
                    ? "Usa o seletor antigo abaixo da moldura."
                    : "Usa o accordion de wallpapers no centro."
                color: ui.secondaryText
                font.family: ui.uiFont
                font.pixelSize: 10
                wrapMode: Text.WordWrap
            }

            ChoiceButton {
                visible: !ui.embedded
                objectName: "legacy.selector-glass"
                width: parent.width
                label: active ? "Vidro do seletor ligado" : "Vidro do seletor desligado"
                active: !!ui.controller && ui.controller.wallpaperSelectorGlassEnabled
                onClicked: if (ui.controller) ui.controller.setWallpaperSelectorGlass(!active)
            }

            Divider { width: parent.width }
            SectionTitle { objectName: "wallpaper.transition"; label: "TRANSIÇÃO" }

            Text {
                text: "Animação ao trocar o wallpaper"
                color: ui.primaryText
                font.family: ui.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            Flow {
                width: parent.width
                spacing: 7

                Repeater {
                    model: ui.controller ? ui.controller.wallpaperTransitionOptions() : []

                    ChoiceButton {
                        required property var modelData
                        width: Math.min(220, (parent.width - 7) / 2)
                        label: modelData.label
                        active: ui.controller && ui.controller.wallpaperTransition === modelData.id
                        onClicked: if (ui.controller) ui.controller.setWallpaperTransition(modelData.id)
                    }
                }
            }

            Text {
                text: "Motor para troca live → live"
                color: ui.primaryText
                font.family: ui.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            Row {
                width: parent.width
                spacing: 7

                ChoiceButton {
                    width: Math.min(220, (parent.width - 7) / 2)
                    label: "Shaders"
                    active: ui.controller && ui.controller.wallpaperLiveTransition === "shader"
                    onClicked: if (ui.controller) ui.controller.setWallpaperLiveTransition("shader")
                }

                ChoiceButton {
                    width: Math.min(220, (parent.width - 7) / 2)
                    label: "Nativa do awww"
                    active: ui.controller && ui.controller.wallpaperLiveTransition === "native"
                    onClicked: if (ui.controller) ui.controller.setWallpaperLiveTransition("native")
                }
            }

            Text {
                width: parent.width
                text: ui.controller && ui.controller.wallpaperLiveTransition === "native"
                    ? "Desativa o shader entre lives. Wallpapers estáticos continuam leves com o awww."
                    : "O shader só é usado de live para live. Wallpapers estáticos usam sempre o awww."
                color: ui.secondaryText
                font.family: ui.uiFont
                font.pixelSize: 10
                wrapMode: Text.WordWrap
            }



            SettingSlider {
                width: parent.width
                label: "Duração"
                hint: "Velocidade da animação de transição"
                minimum: 0.15
                maximum: 3.0
                value: ui.controller ? ui.controller.wallpaperTransitionDuration : 1.0
                valueText: value.toFixed(2) + "s"
                onValueRequested: function(newValue) { if (ui.controller) ui.controller.setWallpaperTransitionDuration(newValue) }
            }

            SettingSlider {
                width: parent.width
                label: "Atraso da imagem estática"
                hint: "Tempo de preparação antes da troca"
                minimum: 0
                maximum: 0.8
                value: ui.controller ? ui.controller.wallpaperStaticDelay : 0.12
                valueText: value.toFixed(2) + "s"
                onValueRequested: function(newValue) { if (ui.controller) ui.controller.setWallpaperStaticDelay(newValue) }
            }

            Rectangle {
                width: parent.width
                height: 76
                radius: 11
                color: ui.theme.withAlpha(ui.accent, 0.10)
                border.width: 1
                border.color: ui.theme.withAlpha(ui.accent, 0.30)

                UiIcon {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    height: 28
                    iconName: "wallpaper"
                    lineColor: ui.accent
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 54
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Text {
                        text: ui.controller && ui.controller.wallpaperLiveTransition === "native"
                            ? "Awww nativo prioriza leveza"
                            : "Shaders somente entre wallpapers live"
                        color: ui.primaryText
                        font.family: ui.uiFont
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        text: "Imagens estáticas não usam mais mpvpaper nem shader."
                        color: ui.secondaryText
                        font.family: ui.uiFont
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }

    Component {
        id: framePage

        Column {
            spacing: 8

            SectionTitle { label: "MOLDURA" }

            ToggleRow {
                width: parent.width
                label: "Moldura da área de trabalho"
                hint: "Exibe a moldura integrada do Velora"
                checked: ui.theme ? ui.theme.desktopFrameEnabled : true
                onToggled: if (ui.theme) ui.theme.setDesktopFrameEnabled(!ui.theme.desktopFrameEnabled)
            }

            ToggleRow {
                enabled: false
                width: parent.width
                label: "Desfoque da moldura"
                hint: "Aplica blur ao fundo dos painéis"
                checked: ui.theme ? ui.theme.frameBlurEnabled : true
                onToggled: if (ui.theme) ui.theme.setFrameBlurEnabled(!ui.theme.frameBlurEnabled)
            }

            SettingSlider {
                width: parent.width
                label: "Transparência da moldura"
                hint: "Controla a moldura sem sobrepor a barra"
                minimum: ui.theme ? ui.theme.minOpacityForRole("sidebar") : 0.25
                maximum: 0.98
                value: ui.theme ? ui.theme.sidebarOpacity : 0.88
                valueText: Math.round(value * 100) + "%"
                onValueRequested: function(newValue) {
                    if (ui.theme)
                        ui.theme.applyOpacity(newValue, ui.theme.popupOpacity, ui.theme.cardOpacity)
                }
            }

            ToggleRow {
                width: parent.width
                label: "Painéis unidos à barra"
                hint: "Integra buscas e seletores à moldura"
                checked: ui.theme ? ui.theme.popupAttachedToBar : true
                onToggled: if (ui.theme) ui.theme.setPopupAttachedToBar(!ui.theme.popupAttachedToBar)
            }

            Divider { width: parent.width }
            SectionTitle { label: "VISUALIZADOR" }

            Row {
                width: parent.width
                spacing: 7

                ChoiceButton {
                    width: Math.min(220, (parent.width - 7) / 2)
                    label: "Wave"
                    iconName: "volume"
                    active: ui.theme && ui.theme.visualizerMode === "wave"
                    onClicked: if (ui.theme) ui.theme.setVisualizerMode("wave")
                }

                ChoiceButton {
                    width: Math.min(220, (parent.width - 7) / 2)
                    label: "Pixels"
                    iconName: "box"
                    active: ui.theme && ui.theme.visualizerMode === "pixels"
                    onClicked: if (ui.theme) ui.theme.setVisualizerMode("pixels")
                }
            }

            SettingSlider {
                width: parent.width
                label: "Intensidade"
                hint: "Força do visualizador de áudio"
                minimum: 0
                maximum: 1
                value: ui.theme ? ui.theme.visualizerStrength : 0.46
                valueText: Math.round(value * 100) + "%"
                onValueRequested: function(newValue) { if (ui.theme) ui.theme.setVisualizerStrength(newValue) }
            }
        }
    }


    Component { id: lyricsPlayback; Column { width: parent ? parent.width : 400; spacing: 12
            SectionTitle { label: "LYRICS NO WALLPAPER" }

            ToggleRow {
                width: parent.width
                label: "Ativar lyrics"
                hint: "Mostra a letra atual integrada ao wallpaper"
                checked: ui.theme ? ui.theme.lyricsEnabled : false
                onToggled: ui.updateLyrics({ enabled: !(ui.theme && ui.theme.lyricsEnabled) })
            }

            ToggleRow {
                enabled: false
                width: parent.width
                label: "Modo cinemático"
                hint: "Na topbar, troca frases com slide e recuo da anterior"
                checked: ui.theme ? ui.theme.lyricsCinematicEnabled : true
                onToggled: if (ui.theme) ui.theme.setLyricsCinematicEnabled(!ui.theme.lyricsCinematicEnabled, true)
            }

            Rectangle {
                width: parent.width
                height: 126
                radius: 12
                color: ui.theme.withAlpha(ui.accent, 0.10)
                border.width: 1
                border.color: ui.theme.withAlpha(ui.accent, 0.28)
                clip: true

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Repeater {
                        model: ui.lyricsPreviewWords()

                        Text {
                            id: lyricsPreviewText

                            required property int index
                            required property string modelData

                            text: modelData
                            color: ui.lyricsPreviewColor(ui.lyricsPreviewSourceIndex(index))
                            opacity: ui.lyricsPreviewSourceIndex(index) === 1 && ui.theme && ui.theme.lyricsActiveWordEnabled ? 1.0 : 0.62
                            font.family: ui.uiFont
                            font.pixelSize: Math.max(18, Math.min(32, ui.theme ? ui.theme.lyricsFontSize * 0.30 : 26))
                            font.weight: Font.Black
                            style: ui.theme && ui.theme.lyricsShadowEnabled ? Text.Outline : Text.Normal
                            styleColor: Qt.rgba(0, 0, 0, 0.34)
                            layer.enabled: ui.theme && ui.theme.lyricsGlowEnabled && ui.theme.lyricsGlowIntensity > 0.01
                            layer.smooth: true
                            layer.effect: DropShadow {
                                property int glowRadius: Math.round(5 + (ui.theme ? ui.theme.lyricsGlowIntensity : 0.45) * 16)

                                horizontalOffset: 0
                                verticalOffset: 0
                                radius: glowRadius
                                samples: Math.max(11, glowRadius * 2 + 1)
                                spread: 0
                                transparentBorder: true
                                color: ui.theme ? ui.theme.withAlpha(lyricsPreviewText.color, 0.30 + ui.theme.lyricsGlowIntensity * 0.52) : Qt.rgba(1, 1, 1, 0.42)
                            }
                        }
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 12
                    width: 138
                    text: "Palavras empilhadas, sem frase corrida."
                    color: ui.secondaryText
                    font.family: ui.uiFont
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignRight
                }
            }

            Divider { width: parent.width }
            SectionTitle { label: "EXIBIÇÃO" }

            Flow {
                width: parent.width
                spacing: 7

                Repeater {
                    model: [
                        { id: "progressive", label: "Progressivo" },
                        { id: "line", label: "Linha" },
                        { id: "current", label: "Atual" }
                    ]

                    ChoiceButton {
                        required property var modelData
                        width: Math.min(180, (parent.width - 14) / 3)
                        compact: true
                        label: modelData.label
                        active: ui.theme && ui.theme.lyricsRevealMode === modelData.id
                        onClicked: ui.updateLyrics({ revealMode: modelData.id })
                    }
                }
            }

            SettingSlider {
                width: parent.width
                label: "Sincronia"
                hint: "Use negativo para atrasar, positivo para adiantar"
                minimum: -3000
                maximum: 3000
                value: ui.theme ? ui.theme.lyricsSyncOffsetMs : 460
                valueText: (value > 0 ? "+" : "") + Math.round(value) + "ms"
                onValueRequested: function(newValue) { ui.updateLyrics({ syncOffsetMs: newValue }) }
            }

            Divider { width: parent.width }
            SectionTitle { label: "LAYOUT" }

            Flow {
                width: parent.width
                spacing: 7

                Repeater {
                    model: [
                        { id: "simple", label: "Simples" },
                        { id: "vertical", label: "Vertical" },
                        { id: "cascade", label: "Cascata" },
                        { id: "centered", label: "Centro" },
                        { id: "two", label: "Dois lados" },
                        { id: "four", label: "4 lyrics" }
                    ]

                    ChoiceButton {
                        required property var modelData
                        width: Math.min(220, (parent.width - 7) / 2)
                        compact: true
                        label: modelData.label
                        active: ui.theme && ui.theme.lyricsLayoutMode === modelData.id
                        onClicked: ui.selectLyricsLayout(modelData.id)
                    }
                }
            }

            Column {
                width: parent.width
                visible: ui.theme && (ui.theme.lyricsLayoutMode === "two" || ui.theme.lyricsLayoutMode === "four")
                height: visible ? implicitHeight : 0
                spacing: 8

                Divider { width: parent.width }
                SectionTitle { label: "BLOCO" }

                Flow {
                    width: parent.width
                    spacing: 7

                    Repeater {
                        model: ui.lyricsBlockCount()

                        ChoiceButton {
                            required property int index
                            width: ui.lyricsBlockCount() > 2 ? (parent.width - 7) / 2 : (parent.width - 7) / 2
                            compact: true
                            label: "Bloco " + (index + 1)
                            active: ui.selectedLyricsBlock === index
                            onClicked: ui.selectedLyricsBlock = index
                        }
                    }
                }

                SettingSlider {
                    width: parent.width
                    label: "Bloco X"
                    hint: "Posição horizontal do bloco selecionado"
                    minimum: 0
                    maximum: 100
                    value: ui.selectedLyricsBlockX()
                    valueText: Math.round(value) + "%"
                    onValueRequested: function(newValue) { ui.updateSelectedLyricsBlockPosition("x", newValue) }
                }

                SettingSlider {
                    width: parent.width
                    label: "Bloco Y"
                    hint: "Posição vertical do bloco selecionado"
                    minimum: 0
                    maximum: 100
                    value: ui.selectedLyricsBlockY()
                    valueText: Math.round(value) + "%"
                    onValueRequested: function(newValue) { ui.updateSelectedLyricsBlockPosition("y", newValue) }
                }

                Flow {
                    width: parent.width
                    spacing: 7

                    Repeater {
                        model: [
                            { id: "inherit", label: "Cor geral" },
                            { id: "pywal", label: "Pywal" },
                            { id: "palette", label: "Paleta" },
                            { id: "manual", label: "Manual" }
                        ]

                        ChoiceButton {
                            required property var modelData
                            width: Math.min(220, (parent.width - 7) / 2)
                            compact: true
                            label: modelData.label
                            active: ui.theme && ui.theme.lyricsBlockColorMode(ui.selectedLyricsBlock) === modelData.id
                            onClicked: ui.updateSelectedLyricsBlockStyle({ colorMode: modelData.id })
                        }
                    }
                }

                TextInputRow {
                    width: parent.width
                    visible: ui.theme && ui.theme.lyricsBlockColorMode(ui.selectedLyricsBlock) === "manual"
                    height: visible ? implicitHeight : 0
                    label: "Cor do bloco"
                    hint: "Hexadecimal do bloco selecionado"
                    value: ui.theme ? ui.theme.lyricsBlockManualColor(ui.selectedLyricsBlock) : "#f5f7ff"
                    onValueSubmitted: function(newValue) { ui.updateSelectedLyricsBlockStyle({ colorMode: "manual", manualColor: newValue }) }
                }

                Flow {
                    width: parent.width
                    spacing: 7

                    Repeater {
                        model: [
                            { id: "inherit", label: "Glow geral" },
                            { id: "on", label: "Glow ON" },
                            { id: "off", label: "Glow OFF" }
                        ]

                        ChoiceButton {
                            required property var modelData
                            width: Math.min(180, (parent.width - 14) / 3)
                            compact: true
                            label: modelData.label
                            active: ui.theme && ui.theme.lyricsBlockGlowMode(ui.selectedLyricsBlock) === modelData.id
                            onClicked: ui.updateSelectedLyricsBlockStyle({ glowMode: modelData.id })
                        }
                    }
                }

                SettingSlider {
                    width: parent.width
                    label: "Glow do bloco"
                    hint: "Intensidade individual do brilho"
                    minimum: 0
                    maximum: 1
                    value: ui.theme ? ui.theme.lyricsBlockGlowIntensity(ui.selectedLyricsBlock) : 0.45
                    valueText: Math.round(value * 100) + "%"
                    onValueRequested: function(newValue) { ui.updateSelectedLyricsBlockStyle({ glowIntensity: newValue }) }
                }
            }

            Divider { width: parent.width }
            SectionTitle { label: "ANIMAÇÃO" }

            ToggleRow {
                width: parent.width
                label: "Flutuação"
                hint: "Movimento suave nas palavras"
                checked: ui.theme ? ui.theme.lyricsFloatEnabled : true
                onToggled: ui.updateLyrics({ floatEnabled: !(ui.theme && ui.theme.lyricsFloatEnabled) })
            }

            SettingSlider {
                width: parent.width
                visible: ui.theme ? ui.theme.lyricsFloatEnabled : true
                height: visible ? implicitHeight : 0
                label: "Força da flutuação"
                hint: "Deslocamento suave em pixels"
                minimum: 0
                maximum: 24
                value: ui.theme ? ui.theme.lyricsFloatIntensity : 5
                valueText: Math.round(value) + "px"
                onValueRequested: function(newValue) { ui.updateLyrics({ floatIntensity: newValue }) }
            }

            Flow {
                width: parent.width
                spacing: 7

                Repeater {
                    model: [
                        { id: "instant", label: "Instantâneo" },
                        { id: "fade", label: "Fade" },
                        { id: "slide", label: "Slide" }
                    ]

                    ChoiceButton {
                        required property var modelData
                        width: Math.min(180, (parent.width - 14) / 3)
                        compact: true
                        label: modelData.label
                        active: ui.theme && ui.theme.lyricsAnimationMode === modelData.id
                        onClicked: ui.updateLyrics({ animation: modelData.id })
                    }
                }
            }

            Text {
                width: parent.width
                text: ui.theme && ui.theme.lyricsAnimationMode === "instant"
                    ? "Instantâneo troca as palavras sem fade nem espera."
                    : "Fade e Slide ficam disponíveis para testes futuros."
                color: ui.secondaryText
                font.family: ui.uiFont
                font.pixelSize: 10
                wrapMode: Text.WordWrap
            }
    } }

    Component { id: lyricsPosition; Column { width: parent ? parent.width : 400; spacing: 12
            SectionTitle { label: "POSIÇÃO" }

            SettingSlider {
                width: parent.width
                label: "Posição X"
                hint: ui.theme && ui.theme.lyricsLayoutMode === "two" ? "Bloco esquerdo na tela" : "Deslocamento horizontal na tela"
                minimum: 0
                maximum: 100
                value: ui.theme ? ui.theme.lyricsPositionX : 18
                valueText: Math.round(value) + "%"
                onValueRequested: function(newValue) { ui.updateLyrics({ posX: newValue }) }
            }

            SettingSlider {
                width: parent.width
                label: "Posição Y"
                hint: ui.theme && ui.theme.lyricsLayoutMode === "two" ? "Altura do bloco esquerdo" : "Deslocamento vertical na tela"
                minimum: 0
                maximum: 100
                value: ui.theme ? ui.theme.lyricsPositionY : 44
                valueText: Math.round(value) + "%"
                onValueRequested: function(newValue) { ui.updateLyrics({ posY: newValue }) }
            }

            SettingSlider {
                width: parent.width
                visible: ui.theme && ui.theme.lyricsLayoutMode === "two"
                height: visible ? implicitHeight : 0
                label: "Posição 2 X"
                hint: "Bloco direito no layout dois lados"
                minimum: 0
                maximum: 100
                value: ui.theme ? ui.theme.lyricsSecondPositionX : 74
                valueText: Math.round(value) + "%"
                onValueRequested: function(newValue) { ui.updateLyrics({ pos2X: newValue }) }
            }

            SettingSlider {
                width: parent.width
                visible: ui.theme && ui.theme.lyricsLayoutMode === "two"
                height: visible ? implicitHeight : 0
                label: "Posição 2 Y"
                hint: "Altura do bloco direito"
                minimum: 0
                maximum: 100
                value: ui.theme ? ui.theme.lyricsSecondPositionY : 18
                valueText: Math.round(value) + "%"
                onValueRequested: function(newValue) { ui.updateLyrics({ pos2Y: newValue }) }
            }

            Divider { width: parent.width }
            SectionTitle { label: "TRANSFORMAR" }

            SettingSlider {
                width: parent.width
                label: "Escala"
                hint: "Redimensiona o bloco de lyrics"
                minimum: 0.35
                maximum: 2.50
                value: ui.theme ? ui.theme.lyricsScale : 1
                valueText: Math.round(value * 100) + "%"
                onValueRequested: function(newValue) { ui.updateLyricsTransform({ scale: newValue }) }
            }

            SettingSlider {
                width: parent.width
                label: "Rotação"
                hint: "Inclinação plana da lyrics"
                minimum: -60
                maximum: 60
                value: ui.theme ? ui.theme.lyricsRotation : 0
                valueText: Math.round(value) + "°"
                onValueRequested: function(newValue) { ui.updateLyricsTransform({ rotation: newValue }) }
            }

            SettingSlider {
                width: parent.width
                label: "Perspectiva X"
                hint: "Dobra a lyrics para cima ou para baixo"
                minimum: -70
                maximum: 70
                value: ui.theme ? ui.theme.lyricsTiltX : 0
                valueText: Math.round(value) + "°"
                onValueRequested: function(newValue) { ui.updateLyricsTransform({ tiltX: newValue }) }
            }

            SettingSlider {
                width: parent.width
                label: "Perspectiva Y"
                hint: "Dobra a lyrics para esquerda ou direita"
                minimum: -70
                maximum: 70
                value: ui.theme ? ui.theme.lyricsTiltY : 0
                valueText: Math.round(value) + "°"
                onValueRequested: function(newValue) { ui.updateLyricsTransform({ tiltY: newValue }) }
            }

            ChoiceButton {
                width: parent.width
                label: "Resetar transformação"
                active: false
                onClicked: if (ui.theme) ui.theme.resetLyricsTransformSettings()
            }

            Divider { width: parent.width }

    } }

    Component { id: lyricsStyle; Column { width: parent ? parent.width : 400; spacing: 12
            SectionTitle { label: "COR" }

            Flow {
                width: parent.width
                spacing: 7

                ChoiceButton {
                    width: Math.min(180, (parent.width - 14) / 3)
                    label: "Pywal"
                    active: ui.theme && ui.theme.lyricsColorMode === "pywal"
                    onClicked: ui.updateLyrics({ colorMode: "pywal" })
                }

                ChoiceButton {
                    width: Math.min(180, (parent.width - 14) / 3)
                    label: "Paleta"
                    active: ui.theme && ui.theme.lyricsColorMode === "palette"
                    onClicked: ui.updateLyrics({ colorMode: "palette" })
                }

                ChoiceButton {
                    width: Math.min(180, (parent.width - 14) / 3)
                    label: "Manual"
                    active: ui.theme && ui.theme.lyricsColorMode === "manual"
                    onClicked: ui.updateLyrics({ colorMode: "manual" })
                }
            }

            TextInputRow {
                width: parent.width
                visible: ui.theme && ui.theme.lyricsColorMode === "manual"
                height: visible ? implicitHeight : 0
                label: "Cor manual"
                hint: "Hexadecimal, ex: #f5f7ff"
                value: ui.theme ? ui.theme.lyricsManualColor : "#f5f7ff"
                onValueSubmitted: function(newValue) { ui.updateLyrics({ manualColor: newValue, colorMode: "manual" }) }
            }

            Divider { width: parent.width }
            SectionTitle { label: "TIPOGRAFIA" }

            SettingSlider {
                width: parent.width
                label: "Tamanho"
                hint: "Tamanho da palavra no wallpaper"
                minimum: 24
                maximum: 180
                value: ui.theme ? ui.theme.lyricsFontSize : 86
                valueText: Math.round(value) + "px"
                onValueRequested: function(newValue) { ui.updateLyrics({ fontSize: newValue }) }
            }

            SettingSlider {
                width: parent.width
                label: "Espaçamento"
                hint: "Distância entre palavras"
                minimum: 0
                maximum: 48
                value: ui.theme ? ui.theme.lyricsWordSpacing : 8
                valueText: Math.round(value) + "px"
                onValueRequested: function(newValue) { ui.updateLyrics({ spacing: newValue }) }
            }

            SettingSlider {
                width: parent.width
                label: "Opacidade"
                hint: "Transparência das lyrics"
                minimum: 0.15
                maximum: 1.0
                value: ui.theme ? ui.theme.lyricsOpacity : 0.86
                valueText: Math.round(value * 100) + "%"
                onValueRequested: function(newValue) { ui.updateLyrics({ opacity: newValue }) }
            }

            ToggleRow {
                width: parent.width
                label: "Caixa alta"
                hint: "Transforma a linha em palavras maiúsculas"
                checked: ui.theme ? ui.theme.lyricsUppercase : true
                onToggled: ui.updateLyrics({ uppercase: !(ui.theme && ui.theme.lyricsUppercase) })
            }

            ToggleRow {
                width: parent.width
                label: "Sombra"
                hint: "Melhora leitura sobre wallpapers claros"
                checked: ui.theme ? ui.theme.lyricsShadowEnabled : true
                onToggled: ui.updateLyrics({ shadow: !(ui.theme && ui.theme.lyricsShadowEnabled) })
            }

            ToggleRow {
                width: parent.width
                label: "Glow"
                hint: "Brilho suave para wallpapers escuros"
                checked: ui.theme ? ui.theme.lyricsGlowEnabled : true
                onToggled: ui.updateLyrics({ glowEnabled: !(ui.theme && ui.theme.lyricsGlowEnabled) })
            }

            SettingSlider {
                width: parent.width
                visible: ui.theme ? ui.theme.lyricsGlowEnabled : true
                height: visible ? implicitHeight : 0
                label: "Força do glow"
                hint: "Intensidade do brilho ao redor da letra"
                minimum: 0
                maximum: 1
                value: ui.theme ? ui.theme.lyricsGlowIntensity : 0.45
                valueText: Math.round(value * 100) + "%"
                onValueRequested: function(newValue) { ui.updateLyrics({ glowIntensity: newValue }) }
            }

            Divider { width: parent.width }

    } }

    Component { id: lyricsMaterial; Column { width: parent ? parent.width : 400; spacing: 12
            SectionTitle { label: "MATERIAL" }

            Flow {
                width: parent.width
                spacing: 7

                Repeater {
                    model: [
                        { id: "off", label: "Off" },
                        { id: "cloud", label: "Nuvem" },
                        { id: "glass", label: "Vidro" },
                        { id: "metal", label: "Metal" },
                        { id: "sky", label: "Céu" }
                    ]

                    ChoiceButton {
                        required property var modelData
                        width: Math.min(180, (parent.width - 14) / 3)
                        compact: true
                        label: modelData.label
                        active: ui.theme && ui.theme.lyricsMaterialMode === modelData.id
                        onClicked: ui.updateLyricsMaterial({ mode: modelData.id })
                    }
                }
            }

            SettingSlider {
                width: parent.width
                visible: ui.theme ? ui.theme.lyricsMaterialMode !== "off" : false
                height: visible ? implicitHeight : 0
                label: "Textura"
                hint: "Mistura a cor da letra com o material escolhido"
                minimum: 0
                maximum: 1
                value: ui.theme ? ui.theme.lyricsMaterialIntensity : 0.55
                valueText: Math.round(value * 100) + "%"
                onValueRequested: function(newValue) { ui.updateLyricsMaterial({ intensity: newValue }) }
            }

            ToggleRow {
                width: parent.width
                label: "Profundidade"
                hint: "Borda e sombra ambiental para integrar no wallpaper"
                checked: ui.theme ? ui.theme.lyricsDepthEnabled : false
                onToggled: ui.updateLyricsMaterial({ depthEnabled: !(ui.theme && ui.theme.lyricsDepthEnabled) })
            }

            SettingSlider {
                width: parent.width
                visible: ui.theme ? ui.theme.lyricsDepthEnabled : false
                height: visible ? implicitHeight : 0
                label: "Força da profundidade"
                hint: "Intensidade do relevo e sombra direcional"
                minimum: 0
                maximum: 1
                value: ui.theme ? ui.theme.lyricsDepthIntensity : 0.45
                valueText: Math.round(value * 100) + "%"
                onValueRequested: function(newValue) { ui.updateLyricsMaterial({ depthIntensity: newValue }) }
            }

            ToggleRow {
                width: parent.width
                label: "Névoa"
                hint: "Reduz contraste para parecer mais distante"
                checked: ui.theme ? ui.theme.lyricsFogEnabled : false
                onToggled: ui.updateLyricsMaterial({ fogEnabled: !(ui.theme && ui.theme.lyricsFogEnabled) })
            }

            SettingSlider {
                width: parent.width
                visible: ui.theme ? ui.theme.lyricsFogEnabled : false
                height: visible ? implicitHeight : 0
                label: "Força da névoa"
                hint: "Quanto a letra se mistura com o ar do wallpaper"
                minimum: 0
                maximum: 1
                value: ui.theme ? ui.theme.lyricsFogIntensity : 0.35
                valueText: Math.round(value * 100) + "%"
                onValueRequested: function(newValue) { ui.updateLyricsMaterial({ fogIntensity: newValue }) }
            }

            ToggleRow {
                width: parent.width
                label: "Máscara manual"
                hint: "Recorta a letra nas áreas desenhadas"
                checked: ui.theme ? ui.theme.lyricsMaskEnabled : false
                onToggled: if (ui.theme) ui.theme.applyLyricsMaskSettings(!ui.theme.lyricsMaskEnabled, ui.theme.lyricsMaskBrushSize, ui.theme.lyricsMaskData, true)
            }

            SettingSlider {
                width: parent.width
                visible: ui.theme ? ui.theme.lyricsMaskEnabled : false
                height: visible ? implicitHeight : 0
                label: "Tamanho do pincel"
                hint: "Largura usada para pintar a área de recorte"
                minimum: 6
                maximum: 180
                value: ui.theme ? ui.theme.lyricsMaskBrushSize : 56
                valueText: Math.round(value) + "px"
                onValueRequested: function(newValue) {
                    if (ui.theme)
                        ui.theme.applyLyricsMaskSettings(ui.theme.lyricsMaskEnabled, newValue, ui.theme.lyricsMaskData, true)
                }
            }

            SettingSlider {
                width: parent.width
                visible: ui.theme ? ui.theme.lyricsMaskEnabled : false
                height: visible ? implicitHeight : 0
                label: "Suavização da máscara"
                hint: "Feather na borda do recorte manual"
                minimum: 0
                maximum: 80
                value: ui.theme ? ui.theme.lyricsMaskFeather : 0
                valueText: Math.round(value) + "px"
                onValueRequested: function(newValue) { ui.updateLyricsMaterial({ maskFeather: newValue }) }
            }

            Flow {
                width: parent.width
                visible: ui.theme ? ui.theme.lyricsMaskEnabled : false
                height: visible ? implicitHeight : 0
                spacing: 7

                ChoiceButton {
                    width: Math.min(220, (parent.width - 7) / 2)
                    label: "Editar máscara"
                    active: ui.theme && ui.theme.lyricsMaskHasStrokes
                    onClicked: if (ui.controller) ui.controller.lyricsMaskEditorRequested()
                }

                ChoiceButton {
                    width: Math.min(220, (parent.width - 7) / 2)
                    label: "Limpar"
                    active: false
                    onClicked: if (ui.theme) ui.theme.clearLyricsMask(true)
                }
            }

            ToggleRow {
                width: parent.width
                label: "Palavra ativa"
                hint: "Destaca a palavra sincronizada atual"
                checked: ui.theme ? ui.theme.lyricsActiveWordEnabled : true
                onToggled: ui.updateLyrics({ activeWord: !(ui.theme && ui.theme.lyricsActiveWordEnabled) })
            }

            Divider { width: parent.width }

    } }


    Component {
        id: velyricsPage

        Column {
            spacing: 10

            SectionTitle { label: "VELYRICS NO INFINITE DESKTOP" }

            Text {
                width: parent.width
                text: "Funciona a partir de 1 terminal. Com 3 ou mais, o Infinite Desktop acompanha o terminal que recebeu a linha."
                color: ui.secondaryText
                font.family: ui.uiFont
                font.pixelSize: 10
                wrapMode: Text.WordWrap
            }

            ToggleRow {
                width: parent.width
                label: "Agrupar por palavras"
                hint: "Desligado usa uma linha completa por terminal"
                checked: ui.controller ? ui.controller.velyricsMode === "words" : false
                onToggled: if (ui.controller) ui.controller.setVelyricsMode(ui.controller.velyricsMode === "words" ? "line" : "words")
            }

            SettingSlider {
                width: parent.width
                visible: ui.controller ? ui.controller.velyricsMode === "words" : false
                height: visible ? implicitHeight : 0
                label: "Palavras por terminal"
                hint: "A câmera avança somente quando começa o próximo grupo"
                minimum: 1
                maximum: 12
                value: ui.controller ? ui.controller.velyricsWordsPerTerminal : 4
                valueText: Math.round(value) + (Math.round(value) === 1 ? " palavra" : " palavras")
                onValueRequested: function(newValue) { if (ui.controller) ui.controller.setVelyricsWordsPerTerminal(newValue) }
            }

            Divider { width: parent.width }
            SectionTitle { label: "SINCRONISMO" }

            SettingSlider {
                width: parent.width
                label: "Sincronismo do terminal"
                hint: "Antecipa a troca das linhas em relação ao Spotify"
                minimum: 0
                maximum: 1500
                value: ui.controller ? ui.controller.velyricsSyncOffsetMs : 500
                valueText: Math.round(value) + " ms"
                onValueRequested: function(newValue) { if (ui.controller) ui.controller.setVelyricsSyncOffset(newValue) }
            }

            Divider { width: parent.width }
            SectionTitle { label: "TIPOGRAFIA" }

            SettingSlider {
                width: parent.width
                label: "Tamanho da fonte"
                hint: "Escala a fonte escolhida dentro de cada terminal"
                minimum: 0.5
                maximum: 3.0
                value: ui.controller ? ui.controller.velyricsFontScale : 1.0
                valueText: Math.round(value * 100) + "%"
                onValueRequested: function(newValue) { if (ui.controller) ui.controller.setVelyricsFontScale(newValue) }
            }

            Text {
                width: parent.width
                text: "Fonte · " + (ui.controller ? ui.controller.velyricsFontFamily : "Pixelon")
                color: ui.primaryText
                font.family: ui.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Rectangle {
                width: parent.width
                height: 38
                radius: 9
                color: ui.theme.withAlpha(ui.theme.surfaceButton, 0.76)
                border.width: 1
                border.color: fontSearch.activeFocus ? ui.theme.withAlpha(ui.accent, 0.68) : ui.theme.withAlpha(ui.theme.borderSoft, 0.32)

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    visible: fontSearch.text.length <= 0
                    text: "Buscar entre as fontes do sistema…"
                    color: ui.secondaryText
                    font.family: ui.uiFont
                    font.pixelSize: 10
                }

                TextInput {
                    id: fontSearch
                    objectName: "velyrics.font-search"
                    anchors {
                        fill: parent
                        leftMargin: 12
                        rightMargin: 12
                    }
                    verticalAlignment: TextInput.AlignVCenter
                    text: ui.controller ? ui.controller.velyricsFontSearch : ""
                    color: ui.primaryText
                    selectionColor: ui.theme.withAlpha(ui.accent, 0.42)
                    selectedTextColor: ui.primaryText
                    font.family: ui.uiFont
                    font.pixelSize: 11
                    clip: true
                    onTextEdited: if (ui.controller) ui.controller.setVelyricsFontSearch(text)
                }
            }

            Rectangle {
                width: parent.width
                height: 158
                radius: 10
                color: ui.theme.withAlpha(ui.theme.surfaceButton, 0.44)
                border.width: 1
                border.color: ui.theme.withAlpha(ui.theme.borderSoft, 0.26)
                clip: true

                ListView {
                    id: fontList
                    objectName: "velyrics.font"
                    anchors {
                        fill: parent
                        margins: 4
                    }
                    spacing: 2
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: ui.controller ? ui.controller.filteredVelyricsFonts() : ["Pixelon"]

                    delegate: Rectangle {
                        required property var modelData
                        readonly property string familyName: String(modelData)
                        width: fontList.width
                        height: 31
                        radius: 7
                        color: ui.controller && ui.controller.velyricsFontFamily === familyName
                            ? ui.theme.withAlpha(ui.accent, 0.22)
                            : (fontMouse.containsMouse ? ui.theme.withAlpha(ui.theme.surfaceCard, 0.42) : "transparent")

                        Text {
                            anchors {
                                left: parent.left
                                right: parent.right
                                leftMargin: 9
                                rightMargin: 9
                                verticalCenter: parent.verticalCenter
                            }
                            text: familyName
                            color: ui.primaryText
                            font.family: familyName
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: fontMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (ui.controller) ui.controller.setVelyricsFontFamily(familyName)
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 128
                radius: 12
                color: ui.theme.withAlpha(ui.accent, 0.10)
                border.width: 1
                border.color: ui.theme.withAlpha(ui.accent, 0.28)
                clip: true

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 28
                    text: ui.controller && ui.controller.velyricsMode === "words" ? "VELORA LYRICS FLOW" : "THE MUSIC MOVES THROUGH THE DESKTOP"
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    color: ui.theme ? ui.theme.lyricsPywalColor : ui.primaryText
                    font.family: ui.controller ? ui.controller.velyricsFontFamily : "Pixelon"
                    font.pixelSize: Math.max(18, Math.min(52, 25 * (ui.controller ? ui.controller.velyricsFontScale : 1.0)))
                }
            }

            Text {
                width: parent.width
                text: "As alterações são aplicadas à sessão ativa sem reiniciar o Spotify."
                color: ui.secondaryText
                font.family: ui.uiFont
                font.pixelSize: 10
                wrapMode: Text.WordWrap
            }
        }
    }

    Component { id: sidebarPage; Column { width: parent ? parent.width : 400; spacing: 12

        Loader { width: parent.width; sourceComponent: barPage }
        Loader { width: parent.width; sourceComponent: menuPage }

    } }

    Component { id: systemPage; Column { width: parent ? parent.width : 400; spacing: 12

        Loader { width: parent.width; sourceComponent: powerPage }
            ToggleRow {
                width: parent.width
                label: "Cores de terminal fortes"
                hint: ui.controller && ui.controller.terminalStrongColors
                    ? "Fundo escuro e contrastado, ainda combinado ao wallpaper"
                    : "Usa a cor normal extraída do wallpaper"
                checked: ui.controller ? ui.controller.terminalStrongColors : false
                onToggled: if (ui.controller) ui.controller.setTerminalStrongColors(!ui.controller.terminalStrongColors)
            }
        SectionTitle { label: "INTEGRAÇÕES" }
        ToggleRow { width: parent.width; label: "Reiniciar Zen automaticamente"; hint: "Aplicação do tema no navegador"
            checked: ui.controller.zenAutoRestart; onToggled: ui.controller.setZenAutoRestart(!checked) }
        ToggleRow { width: parent.width; label: "Balanceamento do tema Web"; hint: "Ajusta o tema dos sites no Zen"
            checked: ui.controller.webThemeBalance; onToggled: ui.controller.setWebThemeBalance(!checked) }
        SettingSlider { width: parent.width; label: "Opacidade do VS Code"; minimum: 0.3; maximum: 1
            value: ui.controller.codeOpacity; valueText: Math.round(value*100)+"%"
            onValueRequested: value => ui.controller.setCodeOpacity(value) }
        SectionTitle { objectName: "historical.world-clock"; label: "RELÓGIOS MUNDIAIS" }
        Repeater { model: 2
            Row { required property int index; width: parent.width; spacing: 8
                ChoiceButton { width: 40; label: "‹"; onClicked: ui.controller.cycleWorldClock(parent.index,-1) }
                Text { width: parent.width-96; height: 36; verticalAlignment: Text.AlignVCenter
                    text: ui.controller.worldClockItems[parent.index].label; color: ui.primaryText; font.family: ui.uiFont }
                ChoiceButton { width: 40; label: "›"; onClicked: ui.controller.cycleWorldClock(parent.index,1) }
            }
        }

    } }
}
