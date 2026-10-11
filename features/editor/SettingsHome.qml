import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import "../../components" as Components

Rectangle {
    id: root

    required property var config
    required property var controller
    required property var editor
    required property var theme
    required property var profileService
    required property var wallpaperStore
    signal requestClose

    property string page: controller.settingsPage || "desktop"
    property string searchText: ""
    property int hyprlandBlurState: -1
    property string hyprlandBlurError: ""
    property bool hyprlandBlurBusy: false
    property string pendingColorRole: "accent"
    readonly property color ink: theme.textPrimary
    readonly property color mutedInk: theme.textSecondary
    readonly property color accent: theme.accent
    readonly property string barAvatarPath: controller.shell
        && controller.shell.unifiedTheme
        ? String(controller.shell.unifiedTheme.profileImagePath || "")
        : String(config.avatarPath || "")
    readonly property var navigation: [
        { id: "appearance", name: "Aparência", icon: "palette" },
        { id: "bar", name: "Barra", icon: "settings" },
        { id: "desktop", name: "Desktop e widgets", icon: "desktop_windows" },
        { id: "lock", name: "Tela de bloqueio", icon: "lock" },
        { id: "wallpapers", name: "Wallpapers e saves", icon: "image" },
        { id: "profiles", name: "Perfis salvos", icon: "person" },
        { id: "system", name: "Sistema e integrações", icon: "settings" }
    ]
    readonly property var manualColorTargets: [
        { role: "accent", label: "Destaque" },
        { role: "bar", label: "Barra" },
        { role: "icons", label: "Ícones" },
        { role: "widgets", label: "Widgets" },
        { role: "text", label: "Texto" },
        { role: "panels", label: "Painéis" }
    ]

    radius: 28
    color: Qt.rgba(theme.surfaceRaised.r, theme.surfaceRaised.g,
                   theme.surfaceRaised.b, 0.985)
    border.width: 1
    border.color: theme.borderStrong
    clip: true
    onPageChanged: {
        controller.setSettingsPage(page)
        if (page === "appearance") refreshHyprlandBlur()
    }
    Component.onCompleted: refreshHyprlandBlur()

    function refreshHyprlandBlur() {
        if (blurControl.running) return
        blurControl.command = ["python3", Quickshell.shellDir + "/scripts/hyprland-blur", "get"]
        blurControl.running = true
    }

    function setHyprlandBlur(enabled) {
        if (blurControl.running) return
        hyprlandBlurBusy = true
        hyprlandBlurError = ""
        blurControl.command = ["python3", Quickshell.shellDir + "/scripts/hyprland-blur",
            "set", enabled ? "on" : "off"]
        blurControl.running = true
    }

    function rgbHex(value) {
        const part = function(channel) {
            const text = Math.round(Math.max(0, Math.min(1, channel)) * 255)
                .toString(16)
            return text.length < 2 ? "0" + text : text
        }
        return "#" + part(value.r) + part(value.g) + part(value.b)
    }

    function openManualColor(role, value) {
        pendingColorRole = String(role)
        manualColorDialog.selectedColor = value
        manualColorDialog.open()
    }

    Process {
        id: blurControl
        running: false
        stdout: StdioCollector { id: blurOutput }
        stderr: StdioCollector { id: blurErrorOutput }
        onExited: function(exitCode) {
            running = false
            root.hyprlandBlurBusy = false
            if (exitCode === 0) {
                root.hyprlandBlurState = blurOutput.text.trim() === "on" ? 1 : 0
                root.hyprlandBlurError = ""
            } else {
                root.hyprlandBlurError = blurErrorOutput.text.trim()
                    || "Não foi possível consultar o blur do Hyprland."
            }
        }
    }

    component ActionButton: Rectangle {
        id: button
        property string label: ""
        property bool primary: false
        property bool selected: false
        signal triggered
        implicitWidth: Math.max(94, textItem.implicitWidth + 28)
        implicitHeight: 38
        radius: 13
        opacity: enabled ? 1 : 0.46
        color: primary || selected
            ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b,
                      pointer.containsMouse ? 0.95 : 0.78)
            : Qt.rgba(1, 1, 1, pointer.containsMouse ? 0.14 : 0.075)
        border.width: 1
        border.color: primary || selected ? root.theme.accentSoft
            : Qt.rgba(1, 1, 1, 0.13)
        Text {
            id: textItem; anchors.centerIn: parent; text: button.label
            color: root.ink; font.family: root.theme.bodyFont
            font.pixelSize: 12; font.weight: Font.DemiBold
        }
        MouseArea {
            id: pointer; anchors.fill: parent; hoverEnabled: true
            enabled: button.enabled
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: button.triggered()
        }
    }

    component ColorChoice: Rectangle {
        id: choice
        required property string role
        required property string label
        required property color selectedColor
        signal triggered
        implicitHeight: 54
        radius: 15
        color: colorPointer.containsMouse
            ? Qt.rgba(1, 1, 1, 0.11) : Qt.rgba(1, 1, 1, 0.06)
        border.width: 1
        border.color: root.theme.borderSubtle

        Rectangle {
            x: 9; anchors.verticalCenter: parent.verticalCenter
            width: 36; height: 36; radius: 11
            color: choice.selectedColor
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.32)
        }
        Column {
            x: 56; anchors.verticalCenter: parent.verticalCenter; spacing: 1
            Text { text: choice.label; color: root.ink; font.pixelSize: 12; font.weight: Font.DemiBold }
            Text { text: root.rgbHex(choice.selectedColor).toUpperCase(); color: root.mutedInk; font.pixelSize: 10 }
        }
        MouseArea {
            id: colorPointer; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: choice.triggered()
        }
    }

    ColorDialog {
        id: manualColorDialog
        title: "Escolher cor de " + root.pendingColorRole
        onAccepted: root.config.setCustomColor(
            root.pendingColorRole, root.rgbHex(selectedColor))
    }

    component SettingSlider: Column {
        id: setting
        property string label: ""
        property real value: 0
        signal committed(real value)
        width: parent ? parent.width : 300
        spacing: 7
        Row {
            width: parent.width
            Text { width: parent.width - valueText.width; text: setting.label; color: root.ink; font.family: root.theme.bodyFont; font.pixelSize: 12 }
            Text { id: valueText; text: Math.round(slider.value * 100) + "%"; color: root.mutedInk; font.family: root.theme.bodyFont; font.pixelSize: 11 }
        }
        Slider {
            id: slider; width: parent.width; from: 0; to: 1
            value: setting.value
            onMoved: setting.committed(value)
        }
    }

    component LiquidStylePicker: Column {
        width: parent ? parent.width : 300
        spacing: 8
        Text { text: "Liquid Glass"; color: root.ink; font.pixelSize: 14; font.weight: Font.DemiBold }
        Row {
            spacing: 8
            ActionButton {
                objectName: "liquidClearChoice"
                label: "Nítido"
                selected: root.config.liquidGlassStyle === "clear"
                onTriggered: root.config.setValue("bar.liquidStyle", "clear")
            }
            ActionButton {
                objectName: "liquidFrostedChoice"
                label: "Fosco"
                selected: root.config.liquidGlassStyle === "frosted"
                onTriggered: root.config.setValue("bar.liquidStyle", "frosted")
            }
        }
        Text {
            width: parent.width; wrapMode: Text.WordWrap
            text: root.config.liquidGlassStyle === "frosted"
                ? "Fundo suavizado para facilitar a leitura, com reflexos nas bordas."
                : "Fundo nítido, com refração suave e reflexos nas bordas."
            color: root.mutedInk; font.pixelSize: 11
        }
    }

    component WallpaperAdjustments: Column {
        width: parent ? parent.width : 300
        spacing: 10
        Text { text: "Wallpaper"; color: root.ink; font.pixelSize: 14; font.weight: Font.DemiBold }
        ActionButton {
            objectName: "wallpaperSelectorGlassToggle"
            label: root.config.wallpaperSelectorGlassEnabled ? "Vidro do seletor ligado" : "Vidro do seletor desligado"
            selected: root.config.wallpaperSelectorGlassEnabled
            onTriggered: root.config.setValue("desktop.wallpaperSelectorGlassEnabled", !root.config.wallpaperSelectorGlassEnabled)
        }
        ActionButton {
            objectName: "wallpaperBlurToggle"
            label: root.config.wallpaperBlurEnabled ? "Blur do wallpaper ligado" : "Blur do wallpaper desligado"
            selected: root.config.wallpaperBlurEnabled
            onTriggered: root.config.setValue("desktop.wallpaperBlurEnabled", !root.config.wallpaperBlurEnabled)
        }
        SettingSlider {
            label: "Intensidade do blur · fraco → forte"
            enabled: root.config.wallpaperBlurEnabled
            opacity: enabled ? 1 : 0.46
            value: root.config.wallpaperBlurStrength
            onCommitted: value => root.config.setValue("desktop.wallpaperBlurStrength", value)
        }
        SettingSlider {
            label: "Escurecer wallpaper"
            value: root.config.wallpaperDimming
            onCommitted: value => root.config.setValue("desktop.wallpaperDimming", value)
        }
    }

    component GalleryPicker: Rectangle {
        id: galleryPicker
        required property int galleryIndex
        readonly property int assetIndex: root.config.galleryOrder[galleryIndex] === undefined
            ? galleryIndex : root.config.galleryOrder[galleryIndex]
        property string title: ["Esquerda", "Centro", "Direita"][galleryIndex]
        height: 174
        radius: 16
        color: Qt.rgba(1, 1, 1, 0.06)
        border.width: 1
        border.color: root.theme.borderSubtle

        Rectangle {
            id: galleryPreview
            anchors.left: parent.left; anchors.right: parent.right
            anchors.top: parent.top; anchors.margins: 9
            height: 112; radius: 11; clip: true
            color: Qt.rgba(0, 0, 0, 0.20)
            Image {
                id: galleryImage
                anchors.fill: parent
                source: String(root.config.galleryPaths[galleryPicker.assetIndex] || "")
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
            }
            Text {
                anchors.centerIn: parent
                visible: galleryImage.status !== Image.Ready
                text: galleryPicker.title
                color: root.mutedInk; font.pixelSize: 11
            }
        }
        ActionButton {
            anchors.left: parent.left; anchors.right: parent.right
            anchors.bottom: parent.bottom; anchors.margins: 9
            label: "Trocar " + galleryPicker.title.toLowerCase()
            onTriggered: root.controller.chooseImage(galleryPicker.assetIndex + 1)
        }
    }

    component PageTitle: Column {
        property string title: ""
        property string detail: ""
        width: parent ? parent.width : 500; spacing: 4
        Text { text: parent.title; color: root.ink; font.family: root.theme.bodyFont; font.pixelSize: 23; font.weight: Font.Bold }
        Text { width: parent.width; text: parent.detail; color: root.mutedInk; font.family: root.theme.bodyFont; font.pixelSize: 12; wrapMode: Text.WordWrap }
    }

    Flickable {
        id: settingsViewport
        anchors.fill: parent
        contentWidth: Math.max(width, 860)
        contentHeight: Math.max(height, 444)
        interactive: contentWidth > width || contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        clip: true
    Item {
        width: settingsViewport.contentWidth
        height: settingsViewport.contentHeight
    Rectangle {
        id: header
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        height: 68; color: Qt.rgba(0, 0, 0, 0.12)
        Rectangle {
            x: 20; anchors.verticalCenter: parent.verticalCenter
            width: 38; height: 38; radius: 13
            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.24)
            Components.VeloraMaterialIcon { anchors.centerIn: parent; width: 24; height: 24; iconName: "settings"; iconColor: root.accent }
        }
        Column {
            x: 70; anchors.verticalCenter: parent.verticalCenter; spacing: 1
            Text { text: "Configurações do Velora"; color: root.ink; font.pixelSize: 17; font.weight: Font.Bold; font.family: root.theme.bodyFont }
            Text { text: "Uma experiência, um único shell"; color: root.mutedInk; font.pixelSize: 10; font.family: root.theme.bodyFont }
        }
        Rectangle {
            width: Math.min(360, parent.width * 0.34); height: 38; radius: 13
            anchors.centerIn: parent; color: Qt.rgba(0, 0, 0, 0.18)
            border.width: 1; border.color: search.activeFocus ? root.accent : root.theme.borderSubtle
            Components.VeloraMaterialIcon { x: 10; anchors.verticalCenter: parent.verticalCenter; width: 18; height: 18; iconName: "search"; iconColor: root.mutedInk }
            TextInput {
                id: search; x: 36; width: parent.width - 48; height: parent.height
                verticalAlignment: TextInput.AlignVCenter; color: root.ink
                font.pixelSize: 11; font.family: root.theme.bodyFont
                onTextChanged: root.searchText = text
                Text { anchors.fill: parent; verticalAlignment: Text.AlignVCenter; text: "Buscar configurações…"; color: root.theme.textMuted; font.pixelSize: 11; visible: search.text.length === 0 && !search.activeFocus }
            }
        }
        ActionButton { anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter; width: 38; label: "×"; onTriggered: root.requestClose() }
    }

    Rectangle {
        id: sidebar
        anchors.left: parent.left; anchors.top: header.bottom; anchors.bottom: parent.bottom
        width: 220; color: Qt.rgba(0, 0, 0, 0.10)
        Column {
            anchors.fill: parent; anchors.margins: 10; spacing: 5
            Repeater {
                model: root.navigation.filter(function(entry) {
                    const query = root.searchText.toLowerCase().trim()
                    return !query.length || entry.name.toLowerCase().includes(query)
                })
                Rectangle {
                    id: navItem
                    required property var modelData
                    width: parent.width; height: 44; radius: 13
                    color: root.page === modelData.id
                        ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.42)
                        : (navMouse.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent")
                    Components.VeloraMaterialIcon { x: 11; anchors.verticalCenter: parent.verticalCenter; width: 20; height: 20; iconName: navItem.modelData.icon; iconColor: root.page === navItem.modelData.id ? root.theme.accentSoft : root.mutedInk }
                    Text { x: 42; width: parent.width - 50; anchors.verticalCenter: parent.verticalCenter; text: navItem.modelData.name; color: root.ink; font.family: root.theme.bodyFont; font.pixelSize: 12; font.weight: root.page === navItem.modelData.id ? Font.DemiBold : Font.Normal; elide: Text.ElideRight }
                    MouseArea { id: navMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.page = navItem.modelData.id }
                }
            }
        }
    }

    Item {
        id: content
        anchors.left: sidebar.right; anchors.right: parent.right
        anchors.top: header.bottom; anchors.bottom: parent.bottom
        Flickable {
            anchors.fill: parent; anchors.margins: 24
            contentWidth: width; contentHeight: pageColumn.height
            clip: true; boundsBehavior: Flickable.StopAtBounds
            visible: root.page !== "system"
            Column {
                id: pageColumn; width: parent.width; spacing: 18
                PageTitle {
                    title: root.page === "appearance" ? "Aparência"
                        : root.page === "bar" ? "Barra unificada"
                        : root.page === "desktop" ? "Desktop e widgets"
                        : root.page === "lock" ? "Tela de bloqueio"
                        : root.page === "wallpapers" ? "Wallpapers e saves"
                        : "Perfis salvos"
                    detail: root.page === "bar" ? "A barra superior e a lateral formam uma única superfície."
                        : root.page === "desktop" ? "Escolha os elementos visíveis ou entre no modo de edição."
                        : root.page === "lock" ? "Edite a composição completa da lockscreen em uma pré-visualização."
                        : root.page === "wallpapers" ? "Cada wallpaper restaura automaticamente seu Desktop e sua Lock."
                        : root.page === "profiles" ? "Perfis nomeados continuam disponíveis para importar e compartilhar."
                        : "Cores, materiais e movimento do Velora."
                }

                Column {
                    width: parent.width; spacing: 12; visible: root.page === "appearance"
                    Text { text: "Paleta de cores"; color: root.ink; font.pixelSize: 14; font.weight: Font.DemiBold }
                    Row { spacing: 8
                        ActionButton { label: "Do wallpaper"; selected: root.config.accentMode === "wallpaper"; onTriggered: root.config.setValue("appearance.accentMode", "wallpaper") }
                        ActionButton { label: "Cor manual"; selected: root.config.accentMode === "custom"; onTriggered: root.config.setValue("appearance.accentMode", "custom") }
                    }
                    Column {
                        width: parent.width
                        spacing: 8
                        visible: root.config.accentMode === "custom"
                        Text {
                            text: "Cores por bloco"
                            color: root.ink; font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }
                        Text {
                            width: parent.width
                            text: "Clique em cada bloco para escolher sua cor. A paleta acompanha o perfil atual."
                            color: root.mutedInk; font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }
                        Flow {
                            width: parent.width
                            spacing: 8
                            Repeater {
                                model: root.manualColorTargets
                                ColorChoice {
                                    required property var modelData
                                    width: Math.max(150, (parent.width - 16) / 3)
                                    role: modelData.role
                                    label: modelData.label
                                    selectedColor: root.config.customColor(modelData.role)
                                    onTriggered: root.openManualColor(
                                        modelData.role, selectedColor)
                                }
                            }
                        }
                    }
                    Text {
                        text: "Tom do Pywal"
                        visible: root.config.accentMode === "wallpaper"
                        color: root.ink; font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                    Row {
                        spacing: 8
                        visible: root.config.accentMode === "wallpaper"
                        ActionButton { label: "Automático"; selected: root.config.pywalTone === "auto"; onTriggered: root.config.setValue("appearance.pywalTone", "auto") }
                        ActionButton { label: "Dark"; selected: root.config.pywalTone === "dark"; onTriggered: root.config.setValue("appearance.pywalTone", "dark") }
                        ActionButton { label: "Light"; selected: root.config.pywalTone === "light"; onTriggered: root.config.setValue("appearance.pywalTone", "light") }
                    }
                    Text {
                        width: parent.width
                        visible: root.config.accentMode === "wallpaper"
                        text: root.config.pywalTone === "auto"
                            ? "Automático acompanha o tema geral. Dark e Light forçam o tratamento da paleta do wallpaper."
                            : "A paleta será regenerada para o modo " + root.config.pywalTone + "."
                        color: root.mutedInk; font.pixelSize: 11
                        wrapMode: Text.WordWrap
                    }
                    SettingSlider { label: "Intensidade do vidro"; value: root.config.blurStrength; onCommitted: function(value) { root.config.setValue("appearance.blurStrength", value) } }
                    Text { text: "Desfoque global do Hyprland"; color: root.ink; font.pixelSize: 14; font.weight: Font.DemiBold }
                    Row { spacing: 8
                        ActionButton {
                            label: "Ativado"
                            selected: root.hyprlandBlurState === 1
                            enabled: root.hyprlandBlurState >= 0 && !root.hyprlandBlurBusy
                            onTriggered: root.setHyprlandBlur(true)
                        }
                        ActionButton {
                            label: "Desativado"
                            selected: root.hyprlandBlurState === 0
                            enabled: root.hyprlandBlurState >= 0 && !root.hyprlandBlurBusy
                            onTriggered: root.setHyprlandBlur(false)
                        }
                    }
                    Text {
                        width: parent.width
                        text: root.hyprlandBlurError.length > 0
                            ? root.hyprlandBlurError
                            : (root.hyprlandBlurState < 0 ? "Lendo estado do Hyprland…"
                                : "Afeta todas as janelas e permanece após reiniciar a sessão.")
                        color: root.hyprlandBlurError.length > 0 ? root.theme.danger : root.mutedInk
                        font.pixelSize: 11; wrapMode: Text.WordWrap
                    }
                    SettingSlider { label: "Reflexos"; value: root.config.reflectionStrength; onCommitted: function(value) { root.config.setValue("appearance.reflection", value) } }
                    Row { spacing: 8
                        ActionButton { label: root.config.reducedMotion ? "Movimento reduzido ✓" : "Reduzir movimento"; selected: root.config.reducedMotion; onTriggered: root.config.setValue("appearance.reducedMotion", !root.config.reducedMotion) }
                        ActionButton { label: root.config.characterPywal ? "Cores do personagem ✓" : "Cores do personagem"; selected: root.config.characterPywal; onTriggered: root.config.setCharacterPywal(!root.config.characterPywal) }
                    }
                }

                Column {
                    width: parent.width; spacing: 13; visible: root.page === "bar"
                    Text { text: "Material"; color: root.ink; font.pixelSize: 14; font.weight: Font.DemiBold }
                    Row { spacing: 8
                        Repeater {
                            model: [{id:"solid",label:"Sólido"},{id:"glass",label:"Translúcido"},{id:"liquid",label:"Liquid glass"}]
                            ActionButton { required property var modelData; label: modelData.label; selected: root.config.barMaterial === modelData.id; onTriggered: root.config.setBarAppearance(modelData.id, root.config.barWaveStrength) }
                        }
                    }
                    LiquidStylePicker { visible: root.config.barMaterial === "liquid" }
                    SettingSlider {
                        label: "Opacidade da barra"
                        value: root.config.barOpacity
                        visible: root.config.barMaterial !== "solid"
                        onCommitted: function(value) {
                            root.config.setBarOpacity(Math.max(0.08, value))
                        }
                    }
                    Text { visible: root.config.barMaterial === "glass"; text: "Desfoque das barras"; color: root.ink; font.pixelSize: 14; font.weight: Font.DemiBold }
                    Row { spacing: 8; visible: root.config.barMaterial === "glass"
                        ActionButton {
                            objectName: "barBlurToggle"
                            label: root.config.barBlurEnabled ? "Blur ligado" : "Blur desligado"
                            selected: root.config.barBlurEnabled
                            onTriggered: root.config.setValue("bar.blurEnabled", !root.config.barBlurEnabled)
                        }
                    }
                    Text {
                        width: parent.width; wrapMode: Text.WordWrap
                        visible: root.config.barMaterial === "glass"
                        text: root.config.barMaterial === "glass"
                            ? "Desfoque real do fundo da barra superior e da lateral."
                            : "O desfoque se aplica ao material Translúcido."
                        color: root.mutedInk; font.pixelSize: 11
                    }
                    Text { text: "Itens opcionais da barra superior"; color: root.ink; font.pixelSize: 14; font.weight: Font.DemiBold }
                    Row { spacing: 8
                        ActionButton {
                            objectName: "topbarMessageToggle"
                            label: root.config.topbarOneThingEnabled ? "Mensagem visível" : "Mensagem oculta"
                            selected: root.config.topbarOneThingEnabled
                            onTriggered: root.config.setValue("topbar.oneThingEnabled", !root.config.topbarOneThingEnabled)
                        }
                        ActionButton {
                            objectName: "topbarNotesToggle"
                            label: root.config.topbarNotesEnabled ? "Notas visíveis" : "Notas ocultas"
                            selected: root.config.topbarNotesEnabled
                            onTriggered: root.config.setValue("topbar.notesEnabled", !root.config.topbarNotesEnabled)
                        }
                    }
                    Text {
                        width: parent.width; wrapMode: Text.WordWrap
                        text: "Ocultar preserva a mensagem e as notas salvas."
                        color: root.mutedInk; font.pixelSize: 11
                    }
                    Text { text: "Foto de perfil da barra"; color: root.ink; font.pixelSize: 14; font.weight: Font.DemiBold }
                    Rectangle {
                        width: pageColumn.width; height: 88; radius: 15
                        color: Qt.rgba(1, 1, 1, 0.06)
                        border.width: 1; border.color: root.theme.borderSubtle
                        Rectangle {
                            x: 14; anchors.verticalCenter: parent.verticalCenter
                            width: 58; height: 58; radius: 29; clip: true
                            color: Qt.rgba(0, 0, 0, 0.22)
                            Image {
                                id: avatarPreviewImage
                                anchors.fill: parent
                                source: root.barAvatarPath.length > 0
                                    ? root.barAvatarPath
                                    : Qt.resolvedUrl("../../assets/profile-avatar.svg")
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                onStatusChanged: {
                                    if (status === Image.Error && root.controller.shell
                                            && root.controller.shell.unifiedTheme
                                            && root.config.avatarPath.length > 0
                                            && root.barAvatarPath !== root.config.avatarPath)
                                        root.controller.shell.unifiedTheme.setProfileImagePath(root.config.avatarPath)
                                }
                            }
                        }
                        Text {
                            x: 88; y: 12
                            text: "Avatar da lateral e da barra superior"
                            color: root.mutedInk; font.pixelSize: 11
                        }
                        Row {
                            x: 88; y: 38; spacing: 8
                            ActionButton { label: "Trocar imagem"; onTriggered: root.controller.chooseBarAvatar() }
                            ActionButton {
                                label: "Usar padrão"
                                enabled: root.barAvatarPath.length > 0
                                onTriggered: root.controller.resetBarAvatar()
                            }
                        }
                    }
                    Text {
                        width: parent.width
                        visible: root.controller.profileAvatarError.length > 0
                        text: root.controller.profileAvatarError
                        color: root.theme.danger
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                    }
                    Text { text: "Organização da parte superior"; color: root.ink; font.pixelSize: 14; font.weight: Font.DemiBold }
                    ActionButton {
                        label: "Arrastar itens no Desktop"
                        onTriggered: root.controller.beginEditing("desktop")
                    }
                    Repeater {
                        model: root.config.topbarToolsOrder
                        Rectangle {
                            id: toolOrderRow
                            required property string modelData
                            required property int index
                            width: pageColumn.width; height: 44; radius: 11
                            color: Qt.rgba(1, 1, 1, 0.06)
                            Text {
                                x: 13; anchors.verticalCenter: parent.verticalCenter
                                text: root.config.topbarToolLabel(toolOrderRow.modelData)
                                color: root.ink; font.pixelSize: 12
                            }
                            Row {
                                anchors.right: parent.right; anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter; spacing: 5
                                ActionButton {
                                    implicitWidth: 42; label: "←"
                                    enabled: toolOrderRow.index > 0
                                    onTriggered: root.config.stepTopbarTool(toolOrderRow.modelData, -1)
                                }
                                ActionButton {
                                    implicitWidth: 42; label: "→"
                                    enabled: toolOrderRow.index < root.config.topbarToolsOrder.length - 1
                                    onTriggered: root.config.stepTopbarTool(toolOrderRow.modelData, 1)
                                }
                            }
                        }
                    }
                    Text { text: "Esquerda e centro"; color: root.ink; font.pixelSize: 14; font.weight: Font.DemiBold }
                    Repeater {
                        model: root.config.referenceAppearance ? root.config.topbarLayout.filter(item => item.section !== "right") : root.config.topbarLayout
                        Rectangle {
                            id: barRow; required property var modelData
                            width: pageColumn.width; height: 48; radius: 13
                            color: Qt.rgba(1,1,1,0.06); border.width: 1; border.color: root.theme.borderSubtle
                            Text { x: 13; width: 190; height: parent.height; verticalAlignment: Text.AlignVCenter; text: barRow.modelData.type; color: root.ink; font.pixelSize: 11 }
                            Row { anchors.right: parent.right; anchors.rightMargin: 7; anchors.verticalCenter: parent.verticalCenter; spacing: 5
                                ActionButton { width: 42; label: "E"; selected: barRow.modelData.section === "left"; onTriggered: root.config.moveTopbarItemToSection(barRow.modelData.id, "left") }
                                ActionButton { width: 42; label: "C"; selected: barRow.modelData.section === "center"; onTriggered: root.config.moveTopbarItemToSection(barRow.modelData.id, "center") }
                                ActionButton { width: 42; label: "D"; selected: barRow.modelData.section === "right"; onTriggered: root.config.moveTopbarItemToSection(barRow.modelData.id, "right") }
                                ActionButton { width: 42; label: "↑"; onTriggered: root.config.moveTopbarItem(barRow.modelData.id, -1) }
                                ActionButton { width: 42; label: "↓"; onTriggered: root.config.moveTopbarItem(barRow.modelData.id, 1) }
                                ActionButton { width: 58; label: barRow.modelData.enabled ? "Ativo" : "Oculto"; selected: barRow.modelData.enabled; onTriggered: root.config.setTopbarItemEnabled(barRow.modelData.id, !barRow.modelData.enabled) }
                            }
                        }
                    }
                }

                Column {
                    width: parent.width; spacing: 10
                    visible: root.page === "desktop" || root.page === "lock"
                    ActionButton { label: root.page === "desktop" ? "Editar Desktop" : "Editar Lock"; primary: true; onTriggered: root.controller.beginEditing(root.page) }
                    Text {
                        visible: root.page === "desktop"
                        width: parent.width; wrapMode: Text.WordWrap
                        text: "No editor, arraste também os itens da barra superior para mudar a ordem."
                        color: root.mutedInk; font.pixelSize: 11
                    }
                    Text { text: "Superfície dos widgets"; color: root.ink; font.pixelSize: 14; font.weight: Font.DemiBold }
                    Row { spacing: 8
                        ActionButton {
                            label: "100% sólidos"
                            selected: root.config.widgetSurfaceMode === "solid"
                            onTriggered: root.config.setWidgetSurfaceMode("solid")
                        }
                        ActionButton {
                            label: "Iguais à barra"
                            selected: root.config.widgetSurfaceMode === "bar"
                            onTriggered: root.config.setWidgetSurfaceMode("bar")
                        }
                    }
                    Text {
                        width: parent.width
                        text: root.config.widgetSurfaceMode === "bar"
                            ? "Usa a mesma cor, transparência e desfoque da barra unificada."
                            : "Mantém todos os cartões completamente opacos."
                        color: root.mutedInk; font.pixelSize: 11
                        wrapMode: Text.WordWrap
                    }
                    ActionButton {
                        objectName: "desktopWidgetsToggle"
                        visible: root.page === "desktop"
                        label: root.config.desktopWidgetsEnabled ? "Ocultar todos os widgets" : "Mostrar todos os widgets"
                        selected: root.config.desktopWidgetsEnabled
                        onTriggered: root.config.setValue("desktop.widgetsEnabled", !root.config.desktopWidgetsEnabled)
                    }
                    ActionButton {
                        objectName: "desktopVisualizerToggle"
                        visible: root.page === "desktop"
                        label: root.config.desktopVisualizerEnabled ? "Visualizador do desktop ligado" : "Visualizador do desktop desligado"
                        selected: root.config.desktopVisualizerEnabled
                        onTriggered: root.config.setValue("desktop.visualizerEnabled", !root.config.desktopVisualizerEnabled)
                    }
                    WallpaperAdjustments { visible: root.page === "desktop" }
                    LiquidStylePicker { visible: root.config.widgetSurfaceMode === "bar" && root.config.barMaterial === "liquid" }
                    Text { text: "Elementos visíveis"; color: root.ink; font.pixelSize: 14; font.weight: Font.DemiBold }
                    ActionButton {
                        visible: root.config.widgetSurfaceMode === "bar" && root.config.barMaterial === "glass"
                        label: root.config.widgetBlurEnabled ? "Blur dos widgets ligado" : "Blur dos widgets desligado"
                        selected: root.config.widgetBlurEnabled
                        onTriggered: root.config.setValue("lockPreview.sharedWidgets.blurEnabled", !root.config.widgetBlurEnabled)
                    }
                    Repeater {
                        model: root.config.sharedWidgets
                        Rectangle {
                            id: widgetRow; required property var modelData
                            width: pageColumn.width; height: 48; radius: 13
                            color: Qt.rgba(1,1,1,0.06); border.width: 1; border.color: root.theme.borderSubtle
                            Text { x: 14; anchors.verticalCenter: parent.verticalCenter; text: widgetRow.modelData.name; color: root.ink; font.pixelSize: 12 }
                            ActionButton {
                                anchors.right: parent.right; anchors.rightMargin: 7; anchors.verticalCenter: parent.verticalCenter
                                label: (root.page === "desktop" ? widgetRow.modelData.desktopEnabled : widgetRow.modelData.lockEnabled) ? "Visível" : "Oculto"
                                selected: (root.page === "desktop" ? widgetRow.modelData.desktopEnabled : widgetRow.modelData.lockEnabled)
                                onTriggered: root.config.setSharedWidgetVisibility(widgetRow.modelData.kind,
                                    root.page === "desktop" ? !widgetRow.modelData.desktopEnabled : widgetRow.modelData.desktopEnabled,
                                    root.page === "lock" ? !widgetRow.modelData.lockEnabled : widgetRow.modelData.lockEnabled)
                            }
                        }
                    }
                    Text {
                        visible: root.page === "lock"
                        text: "Personagem principal"
                        color: root.ink; font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                    ActionButton {
                        visible: root.page === "lock"
                        label: "Trocar personagem principal"
                        onTriggered: root.controller.chooseImage(0)
                    }
                    Text {
                        visible: root.page === "desktop" || root.page === "lock"
                        text: "Imagens da galeria"
                        color: root.ink; font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                    Text {
                        visible: root.page === "desktop" || root.page === "lock"
                        width: parent.width
                        text: "Estas fotos são compartilhadas pelo Desktop e pela Lock. Clique na posição que deseja trocar."
                        color: root.mutedInk; font.pixelSize: 11
                        wrapMode: Text.WordWrap
                    }
                    Row {
                        visible: root.page === "desktop" || root.page === "lock"
                        width: parent.width
                        spacing: 8
                        GalleryPicker { galleryIndex: 0; width: (parent.width - 16) / 3 }
                        GalleryPicker { galleryIndex: 1; width: (parent.width - 16) / 3 }
                        GalleryPicker { galleryIndex: 2; width: (parent.width - 16) / 3 }
                    }
                }

                Column {
                    width: parent.width; spacing: 12; visible: root.page === "wallpapers"
                    WallpaperAdjustments {}
                    ActionButton { label: "Escolher wallpaper"; primary: true; onTriggered: root.controller.chooseWallpaper() }
                    Rectangle {
                        width: pageColumn.width; height: 68; radius: 15
                        color: Qt.rgba(1,1,1,0.06); border.width: 1; border.color: root.theme.borderSubtle
                        Text { x: 14; y: 11; text: "Save automático deste wallpaper"; color: root.ink; font.pixelSize: 12; font.weight: Font.DemiBold }
                        Text { x: 14; y: 36; width: parent.width - 28; text: root.wallpaperStore.activeKey || "Aguardando wallpaper"; color: root.mutedInk; font.pixelSize: 10; elide: Text.ElideMiddle }
                    }
                    Text { width: parent.width; wrapMode: Text.WordWrap; text: "Ao trocar de fundo, o Velora salva a composição atual e restaura o Desktop e a Lock associados ao novo wallpaper."; color: root.mutedInk; font.pixelSize: 11 }
                }

                Column {
                    width: parent.width; spacing: 9; visible: root.page === "profiles"
                    Row { spacing: 8
                        ActionButton { label: "Novo perfil"; onTriggered: root.profileService.createProfile("") }
                        ActionButton { label: "Importar .helixpack"; onTriggered: root.controller.importPackage() }
                    }
                    Repeater {
                        model: root.profileService.profiles
                        Rectangle {
                            id: profileRow; required property var modelData
                            width: pageColumn.width; height: 56; radius: 14
                            color: Qt.rgba(1,1,1,0.06); border.width: 1
                            border.color: String(modelData.id) === root.profileService.activeProfileId ? root.accent : root.theme.borderSubtle
                            Text { x: 14; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 290; text: profileRow.modelData.name; color: root.ink; font.pixelSize: 12; font.weight: Font.DemiBold; elide: Text.ElideRight }
                            Row { anchors.right: parent.right; anchors.rightMargin: 7; anchors.verticalCenter: parent.verticalCenter; spacing: 5
                                ActionButton { label: "Aplicar"; primary: String(profileRow.modelData.id) === root.profileService.activeProfileId; onTriggered: root.profileService.applyProfile(profileRow.modelData.id, true) }
                                ActionButton { label: "Salvar"; enabled: String(profileRow.modelData.id) === root.profileService.activeProfileId; opacity: enabled ? 1 : 0.4; onTriggered: root.profileService.updateProfile(profileRow.modelData.id) }
                                ActionButton { label: "Exportar"; onTriggered: root.controller.exportPackage(profileRow.modelData.id) }
                            }
                        }
                    }
                }
            }
        }

        Loader {
            anchors.fill: parent; anchors.margins: 10
            active: root.page === "system"; visible: active
            sourceComponent: Components.VeloraSettingsPanel {
                theme: root.controller.shell ? root.controller.shell.unifiedTheme : null
                externalSurface: true; open: true
                onCloseRequested: root.page = "desktop"
                onLyricsMaskEditorRequested: {
                    root.controller.hide()
                    if (root.controller.shell)
                        root.controller.shell.openLyricsMaskEditor()
                }
            }
        }
    }
    }
    }
}
