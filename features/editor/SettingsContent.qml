import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import "../../components" as Components

Item {
    id: root

    required property var config
    required property var controller
    required property var editor
    required property var theme
    required property var profileService
    required property var wallpaperStore
    signal requestClose
    signal revealSetting(string id)

    property string page: "wallpapers"
    property string librarySearch: ""
    property string libraryKind: "all"
    readonly property int hyprlandBlurState: integrations ? integrations.hyprlandBlurState : -1
    readonly property string hyprlandBlurError: integrations ? integrations.hyprlandBlurError : ""
    readonly property bool hyprlandBlurBusy: integrations ? integrations.hyprlandBlurBusy : false
    property string pendingColorRole: "accent"
    readonly property color ink: theme.textPrimary
    readonly property color mutedInk: theme.textSecondary
    readonly property color accent: theme.accent
    readonly property string barAvatarPath: controller.shell
        && controller.shell.unifiedTheme
        ? String(controller.shell.unifiedTheme.profileImagePath || "")
        : String(config.avatarPath || "")
    readonly property var manualColorTargets: [
        { role: "accent", label: "Destaque" },
        { role: "bar", label: "Barra" },
        { role: "icons", label: "Ícones" },
        { role: "widgets", label: "Widgets" },
        { role: "text", label: "Texto" },
        { role: "panels", label: "Painéis" }
    ]

    property var motion: null
    property var integrations: controller.integrations || null
    property string mediaSection: "playback"
    property string section: "main"
    onSectionChanged: Qt.callLater(function() {
        if (root.motion && !root.motion.reduced) sectionEntrance.restart()
    })
    readonly property var legacyTheme: controller.shell ? controller.shell.unifiedTheme : null
    readonly property var wallpaper: controller.wallpaperService || null
    implicitHeight: pageLoader.y + (pageLoader.item ? pageLoader.item.implicitHeight : 0)
    function setHyprlandBlur(enabled) { if (integrations) integrations.setHyprlandBlur(enabled) }

    function prepareResult(result) {
        return pageLoader.item && typeof pageLoader.item.prepareResult === "function"
            ? pageLoader.item.prepareResult(result) : false
    }
    component SettingSwitch: Components.VeloraSettingsSwitch { theme: root.theme; motion: root.motion }
    component ContextLink: Components.VeloraSettingsLink { theme: root.theme }

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

    component ActionButton: Rectangle {
        id: button
        property string label: ""
        property bool primary: false
        property bool selected: false
        signal triggered
        activeFocusOnTab: enabled
        Accessible.role: Accessible.Button
        Accessible.name: label
        Keys.onSpacePressed: triggered()
        Keys.onReturnPressed: triggered()
        implicitWidth: Math.max(94, textItem.implicitWidth + 28)
        implicitHeight: 38
        radius: 13
        opacity: enabled ? 1 : 0.46
        color: primary || selected
            ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b,
                      pointer.containsMouse ? 0.46 : 0.28)
            : Qt.rgba(1, 1, 1, pointer.containsMouse ? 0.14 : 0.055)
        border.width: 1
        border.color: primary || selected || activeFocus ? root.theme.accentSoft
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
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: label
        Keys.onSpacePressed: triggered()
        Keys.onReturnPressed: triggered()
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

    component SettingSlider: Components.VeloraSettingsSlider {
        theme: root.theme
        signal committed(real value)
        onEdited: value => committed(value)
    }

    component LiquidStylePicker: Column {
        width: parent ? parent.width : 300
        spacing: 8
        Text { text: "Liquid Glass"; color: root.ink; font.pixelSize: 14; font.weight: Font.DemiBold }
        Components.VeloraSettingsTabs {
            theme: root.theme; motion: root.motion
            options: [{id:"clear",label:"Nítido"},{id:"frosted",label:"Fosco"}]
            selected: root.config.liquidGlassStyle
            onChosen: id => root.config.setValue("bar.liquidStyle", id)
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
        width: parent ? parent.width : 640; spacing: 14
        Row {
            width: parent.width; spacing: 12
            Repeater { model: ["Original", "Com seus ajustes"]
                Column {
                    required property string modelData
                    required property int index
                    width: (parent.width-12)/2; spacing: 7
                    SettingsScenePreview {
                        width: parent.width; height: Math.min(194,width*.6)
                        theme: root.theme
                        imageSource: root.wallpaper ? root.wallpaper.currentPreviewPath || root.wallpaper.currentPath : ""
                        blur: index === 1 && root.config.wallpaperBlurEnabled ? root.config.wallpaperBlurStrength : 0
                        dimming: index === 1 ? root.config.wallpaperDimming : 0
                    }
                    Text { text: parent.modelData; color: root.mutedInk; font.family: root.theme.bodyFont; font.pixelSize: 10 }
                }
            }
        }
        Flow {
            width: parent.width; spacing: 24
            Column { width: Math.min(320,(parent.width-24)/2); spacing: 2
                SettingSwitch {
                    objectName: "wallpaperBlurToggle"; label: "Blur do wallpaper"
                    checked: root.config.wallpaperBlurEnabled
                    onTriggered: root.config.setValue("desktop.wallpaperBlurEnabled", !checked)
                }
                SettingSlider {
                    objectName: "wallpaper.blur-strength"; label: "Intensidade"
                    enabled: root.config.wallpaperBlurEnabled
                    value: root.config.wallpaperBlurStrength
                    onCommitted: value => root.config.setValue("desktop.wallpaperBlurStrength",value)
                }
            }
            Column { width: Math.min(320,(parent.width-24)/2); spacing: 2
                Text { height: 36; text: "Luz do fundo"; verticalAlignment: Text.AlignVCenter; color: root.ink; font.family: root.theme.bodyFont; font.pixelSize: 12 }
                SettingSlider { objectName: "wallpaper.dimming"; label: "Escurecer wallpaper"; value: root.config.wallpaperDimming
                    onCommitted: value => root.config.setValue("desktop.wallpaperDimming",value) }
            }
        }
    }

    component PageTitle: Column {
        property string title: ""
        property string detail: ""
        width: parent ? parent.width : 500; spacing: 4
        Text { text: parent.title; color: root.ink; font.family: root.theme.bodyFont; font.pixelSize: 23; font.weight: Font.Bold }
        Text { width: parent.width; text: parent.detail; color: root.mutedInk; font.family: root.theme.bodyFont; font.pixelSize: 12; wrapMode: Text.WordWrap }
    }

    component LegacyControls: Loader {
        property string category: ""
        width: parent ? parent.width : 600
        active: visible && !!root.legacyTheme && !!root.integrations
        sourceComponent: Components.VeloraCompactSettings {
            width: parent.width; height: implicitHeight
            embedded: true; category: parent.category
            theme: root.legacyTheme; palette: root.theme; controller: root.integrations
            mediaSection: root.mediaSection
        }
    }
    function openTool(kind) {
        const shell = controller.shell
        if (!shell) return
        if (kind === "monitor") {
            if (!shell.composition || !shell.composition.openMonitorSettings()) {
                controller.integrationError = "O painel de monitores precisa de uma barra ativa neste monitor."
                return
            }
        } else shell.openQuickPopup(kind)
        controller.hide()
    }
    Text {
        id: pickerErrorLabel
        width: parent.width
        visible: root.controller.pickerError.length > 0
        text: root.controller.pickerError
        color: root.theme.danger
        font.pixelSize: 12
        wrapMode: Text.WordWrap
    }
    Loader {
        id: pageLoader
        readonly property real restingY: pickerErrorLabel.visible ? pickerErrorLabel.height + 12 : 0
        y: restingY
        onRestingYChanged: if (!sectionEntrance.running) y = restingY
        width: parent.width
        onLoaded: {
            sectionEntrance.stop()
            opacity = 1; y = restingY
            if (root.motion && !root.motion.reduced) sectionEntrance.restart()
        }
        sourceComponent: root.page === "appearance" ? appearancePage
            : root.page === "bar" ? (root.section === "sidebar" ? sidebarPage : root.section === "layout" ? barLayoutPage : barPage)
            : root.page === "desktop" || root.page === "lock" ? desktopPage
            : root.page === "motion" ? motionPage
            : root.page === "system" ? systemPage
            : root.page === "media" ? mediaPage
            : root.page === "language" ? languagePage
            : root.page === "profiles" ? profilesPage : wallpapersPage
    }
    SequentialAnimation {
        id: sectionEntrance
        ScriptAction { script: { pageLoader.opacity=0; pageLoader.y=pageLoader.restingY+8 } }
        PauseAnimation { duration: root.motion ? root.motion.geometryDuration : 0 }
        ParallelAnimation {
            NumberAnimation { target: pageLoader; property: "opacity"; to: 1; duration: root.motion ? root.motion.contentDuration : 0 }
            NumberAnimation { target: pageLoader; property: "y"; to: pageLoader.restingY; duration: root.motion ? root.motion.contentDuration : 0; easing.type: Easing.OutCubic }
        }
    }
    Connections { target: root.motion
        function onReducedChanged() { if(root.motion.reduced) { sectionEntrance.stop(); pageLoader.opacity=1; pageLoader.y=pageLoader.restingY } }
    }
    Component { id: sidebarPage; LegacyControls { category: "bar" } }
    Component { id: appearancePage
                Column {
                    width: parent ? parent.width : 600; spacing: 12
                    Text { text: "Paleta de cores"; color: root.ink; font.pixelSize: 14; font.weight: Font.DemiBold }
                    Components.VeloraSettingsTabs {
                        theme: root.theme; motion: root.motion; tabWidth: 130
                        options: [{id:"wallpaper",label:"Do wallpaper"},{id:"custom",label:"Cor manual"}]
                        selected: root.config.accentMode
                        onChosen: id => root.config.setValue("appearance.accentMode",id)
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
                                    objectName: "appearance.color." + modelData.role
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
                    Components.VeloraSettingsTabs {
                        visible: root.config.accentMode === "wallpaper"
                        theme: root.theme; motion: root.motion
                        options: [{id:"auto",label:"Automático"},{id:"dark",label:"Dark"},{id:"light",label:"Light"}]
                        selected: root.config.pywalTone
                        onChosen: id => root.config.setValue("appearance.pywalTone",id)
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
                    SettingSlider { label: "Reflexos"; value: root.config.reflectionStrength; onCommitted: function(value) { root.config.setValue("appearance.reflection", value) } }
                    Row { spacing: 8

                        SettingSwitch { objectName: "appearance.character-pywal"; label: "Cores do personagem"; checked: root.config.characterPywal; onTriggered: root.config.setCharacterPywal(!root.config.characterPywal) }
                    }
                    LegacyControls { category: "appearance" }
                }
    }

    Component { id: barPage
                Column {
                    width: parent ? parent.width : 600; spacing: 13
                    SettingsMaterialChoices {
                        objectName: "bar.material"
                        width: parent.width; theme: root.theme; config: root.config; motion: root.motion
                        imageSource: root.wallpaper ? root.wallpaper.currentPreviewPath || root.wallpaper.currentPath : ""
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
                    SettingSwitch {
                        visible: root.config.barMaterial === "glass"
                        objectName: "barBlurToggle"; label: "Blur das barras"
                        hint: "Desfoque do fundo da barra superior e da lateral."
                        checked: root.config.barBlurEnabled
                        onTriggered: root.config.setValue("bar.blurEnabled", !checked)
                    }
                    Text { text: "Na barra superior"; color: root.mutedInk; font.family: root.theme.bodyFont; font.pixelSize: 11 }
                    Row { spacing: 8
                        SettingSwitch {
                            objectName: "topbarMessageToggle"
                            label: "Mensagem"; hint: "Ocultar preserva a mensagem salva."
                            checked: root.config.topbarOneThingEnabled
                            onTriggered: root.config.setValue("topbar.oneThingEnabled", !root.config.topbarOneThingEnabled)
                        }
                        SettingSwitch {
                            objectName: "topbarNotesToggle"
                            label: "Notas"; hint: "Ocultar preserva as notas salvas."
                            checked: root.config.topbarNotesEnabled
                            onTriggered: root.config.setValue("topbar.notesEnabled", !root.config.topbarNotesEnabled)
                        }
                    }
                    Rectangle {
                        width: Math.min(520,parent.width); height: 88; radius: 15
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
                            ContextLink {
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
                }
    }
    Component { id: barLayoutPage
        Column { width: parent.width; spacing: 12
                    Text { text: "Organização da parte superior"; color: root.ink; font.pixelSize: 14; font.weight: Font.DemiBold }
                    ActionButton {
                        label: "Arrastar itens no Desktop"
                        onTriggered: root.controller.beginEditing("desktop")
                    }
                    Flow { width: parent.width; spacing: 12
                    Repeater {
                        model: root.config.topbarToolsOrder
                        Rectangle {
                            id: toolOrderRow
                            objectName: "bar.tools-order"
                            required property string modelData
                            required property int index
                            width: (root.width-12*(Math.max(1,Math.floor(root.width/230))-1))/Math.max(1,Math.floor(root.width/230)); height: 44; radius: 11
                            color: Qt.rgba(1, 1, 1, 0.06)
                            Text {
                                x: 13; anchors.verticalCenter: parent.verticalCenter
                                width: parent.width-120; elide: Text.ElideRight
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
                    }
                    Text { text: "Esquerda e centro"; color: root.ink; font.pixelSize: 14; font.weight: Font.DemiBold }
                    Repeater {
                        model: root.config.referenceAppearance ? root.config.topbarLayout.filter(item => item.section !== "right") : root.config.topbarLayout
                        Rectangle {
                            id: barRow; objectName: "bar.layout"; required property var modelData
                            width: parent.width; height: 48; radius: 13
                            color: Qt.rgba(1,1,1,0.06); border.width: 1; border.color: root.theme.borderSubtle
                            Text { x: 13; width: Math.max(60,parent.width-330); elide: Text.ElideRight; height: parent.height; verticalAlignment: Text.AlignVCenter; text: barRow.modelData.type; color: root.ink; font.pixelSize: 11 }
                            Row { anchors.right: parent.right; anchors.rightMargin: 7; anchors.verticalCenter: parent.verticalCenter; spacing: 5
                                Components.VeloraSettingsTabs {
                                    theme: root.theme; motion: root.motion; tabWidth: 64
                                    options: [{id:"left",label:"Esquerda"},{id:"center",label:"Centro"},{id:"right",label:"Direita"}]
                                    selected: barRow.modelData.section
                                    onChosen: id => root.config.moveTopbarItemToSection(barRow.modelData.id,id)
                                }
                                ActionButton { width: 32; label: "↑"; Accessible.name: "Mover " + barRow.modelData.type + " para cima"; onTriggered: root.config.moveTopbarItem(barRow.modelData.id, -1) }
                                ActionButton { width: 32; label: "↓"; Accessible.name: "Mover " + barRow.modelData.type + " para baixo"; onTriggered: root.config.moveTopbarItem(barRow.modelData.id, 1) }
                                SettingSwitch { width: 42; label: barRow.modelData.type; checked: barRow.modelData.enabled; onTriggered: root.config.setTopbarItemEnabled(barRow.modelData.id, !checked) }

                            }
                        }
                    }


}
    }
    Component { id: desktopPage
        SettingsWidgets {
            width: parent.width
            config: root.config; controller: root.controller; editor: root.editor
            theme: root.theme; motion: root.motion; legacyTheme: root.legacyTheme; space: root.page
        }
    }
    Component { id: wallpapersPage
        Loader { width: parent.width
            sourceComponent: root.section === "transitions" ? wallpaperTransitionsPage
                : root.section === "effects" ? wallpaperEffectsPage
                : root.section === "selector" ? wallpaperSelectorPage : wallpaperLibraryPage }
    }
    Component { id: wallpaperTransitionsPage
        WallpaperTransitions { width: parent.width; theme: root.theme; motion: root.motion; backend: root.integrations }
    }
    Component { id: wallpaperEffectsPage; WallpaperAdjustments { } }
    Component { id: wallpaperSelectorPage
        Column { width: parent.width; spacing: 18
            Text { text: "Posição do seletor"; color: root.ink; font.family: root.theme.bodyFont; font.pixelSize: 14 }
            Components.VeloraSettingsTabs {
                objectName: "legacy.selector-position"
                theme: root.theme; motion: root.motion; tabWidth: 155
                options: [{id:"center",label:"Centro"},{id:"bottom",label:"Inferior (clássico)"}]
                selected: root.legacyTheme ? root.legacyTheme.wallpaperSelectorPosition : "center"
                onChosen: id => { if(root.legacyTheme) root.legacyTheme.setWallpaperSelectorPosition(id) }
            }
            Text { text: "Abra seus wallpapers no centro ou junto à base do desktop."
                color: root.mutedInk; font.family: root.theme.bodyFont; font.pixelSize: 11 }
        SettingSwitch {
            objectName: "wallpaperSelectorGlassToggle"
            label: "Vidro do seletor"
            checked: root.config.wallpaperSelectorGlassEnabled
            onTriggered: root.config.setValue("desktop.wallpaperSelectorGlassEnabled", !root.config.wallpaperSelectorGlassEnabled)
        }
        }
    }
    Component { id: wallpaperLibraryPage
Column {
    width: parent ? parent.width : 600; spacing: 18
    Item {
        width: parent.width
        height: preview.height
        Rectangle {
            id: preview; width: Math.min(parent.width, 640)
            height: Math.min(260, width*.52); radius: 16
            color: Qt.rgba(0,0,0,.18); border.color: root.theme.borderStrong
            clip: true
            Image { id: wallpaperImage; anchors.fill: parent; anchors.margins: 1
                source: root.wallpaper ? root.wallpaper.currentPreviewPath || root.wallpaper.currentPath : ""
                sourceSize.width: 960; asynchronous: true; fillMode: Image.PreserveAspectCrop }
            Text { anchors.centerIn: parent; visible: wallpaperImage.status !== Image.Ready
                text: "Seu wallpaper"; color: root.mutedInk; font.family: root.theme.bodyFont }
            ActionButton { anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 12
                label: "Escolher arquivo…"; onTriggered: root.controller.chooseWallpaper() }
        }

    }
    Flow { width: parent.width; spacing: 16
        Components.VeloraSettingsTabs {
            theme: root.theme; motion: root.motion; tabWidth: 130
            options: [{id:"all",label:"Todos"},{id:"static",label:"Imagens"},{id:"live",label:"Vídeos e animações"}]
            selected: root.libraryKind
            onChosen: id => root.libraryKind=id
        }
        ContextLink { label: "Atualizar biblioteca"; enabled: !!root.integrations; onTriggered: root.integrations.reload() }
    }
    TextField { width: parent.width; height: 36; placeholderText: "Buscar na biblioteca de wallpapers…"; placeholderTextColor: root.mutedInk; color: root.ink
        font.family: root.theme.bodyFont; onTextChanged: root.librarySearch=text
        background: Rectangle { radius: 10; color: Qt.rgba(0,0,0,.10); border.color: root.theme.borderSubtle } }
    GridView {
        id: library
        objectName: "wallpaperLibrary"
        width: parent.width; height: Math.min(240, contentHeight)
        clip: true; cellWidth: width / Math.max(2, Math.floor(width/140)); cellHeight: 104
        model: root.integrations ? root.integrations.allWallpapers.filter(entry =>
            (root.libraryKind === "all" || (root.libraryKind === "static" ? entry.kind === "static" : entry.kind !== "static"))
            && (!root.librarySearch || entry.title.toLowerCase().includes(root.librarySearch.toLowerCase()))) : []
        delegate: Rectangle {
            required property var modelData
            width: library.cellWidth - 9; height: library.cellHeight - 9; radius: 10; clip: true
            color: Qt.rgba(0,0,0,.16)
            border.width: 1
            border.color: root.wallpaper && root.wallpaper.currentPath === modelData.path ? root.accent : root.theme.borderSubtle
            Image { anchors.fill: parent; anchors.margins: 2; source: modelData.preview || modelData.path
                sourceSize.width: 260; asynchronous: true; fillMode: Image.PreserveAspectCrop }
            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: 24; color: Qt.rgba(0,0,0,.60)
                Text { anchors.fill: parent; anchors.margins: 4; text: modelData.title; color: "white"; font.pixelSize: 10; elide: Text.ElideRight } }
            activeFocusOnTab: true
            Accessible.role: Accessible.Button; Accessible.name: modelData.title
            function apply() { if (root.wallpaper) root.profileService.setDraftWallpaper(encodeURI("file://" + modelData.path)) }
            Keys.onReturnPressed: apply()
            TapHandler { onTapped: parent.apply() }
        }
    }
    Text { width: parent.width; visible: library.count === 0; text: "Nenhum wallpaper encontrado. Escolha um arquivo para começar."
        wrapMode: Text.WordWrap; color: root.mutedInk; font.pixelSize: 12 }

    Text { objectName: "wallpaper.autosave"; width: parent.width; wrapMode: Text.WordWrap; text: "O Velora salva automaticamente a composição por wallpaper, preservando as cores e a barra atuais ao restaurá-la."
        color: root.mutedInk; font.pixelSize: 12 }
    Text { width: parent.width; wrapMode: Text.WordWrap; text: root.wallpaper ? root.wallpaper.error : ""; color: root.theme.danger; visible: text.length > 0 }
}
    }
    Component { id: profilesPage
        Column {
            id: profilesPanel
            width: parent.width; spacing: 12
            property string selectedId: root.profileService.activeProfileId
            readonly property var selectedProfile: root.profileService.profiles.find(item => String(item.id) === selectedId) || null
            Flow { width: parent.width; spacing: 18
                ActionButton { label: "Novo perfil"; onTriggered: root.profileService.createProfile("") }
                ContextLink { label: "Importar .helixpack"; onTriggered: root.controller.importPackage() }
            }
            Flow { width: parent.width; spacing: 10
                Repeater { model: root.profileService.profiles
                    Rectangle {
                        id: profileCard
                        required property var modelData
                        readonly property bool selected: String(modelData.id) === profilesPanel.selectedId
                        width: Math.min(280,(profilesPanel.width-10)/2); height: 66; radius: 13
                        color: Qt.rgba(root.accent.r,root.accent.g,root.accent.b,selected ? .16 : .04)
                        border.width: 1; border.color: selected || activeFocus ? root.theme.accentSoft : root.theme.borderSubtle
                        activeFocusOnTab: true
                        Accessible.role: Accessible.Button; Accessible.name: modelData.name
                        Accessible.checkable: true; Accessible.checked: selected
                        function triggered() { profilesPanel.selectedId=String(modelData.id) }
                        Accessible.onPressAction: triggered()
                        Keys.onSpacePressed: triggered()
                        Keys.onReturnPressed: triggered()
                        Components.VeloraMaterialIcon { x: 14; y: 22; width: 22; height: 22; iconName: "layers"; iconColor: root.mutedInk }
                        Text { x: 50; y: 13; width: parent.width-62; text: profileCard.modelData.name; elide: Text.ElideRight; color: root.ink; font.family: root.theme.bodyFont; font.pixelSize: 12 }
                        Text { x: 50; y: 35; text: String(profileCard.modelData.id) === root.profileService.activeProfileId ? "Em uso" : "Salvo"; color: root.mutedInk; font.family: root.theme.bodyFont; font.pixelSize: 10 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: profileCard.triggered() }
                    }
                }
            }
            Flow { visible: !!profilesPanel.selectedProfile; width: parent.width; spacing: 18
                ActionButton { objectName: "profile.apply"; label: "Aplicar"; primary: true; onTriggered: root.profileService.applyProfile(profilesPanel.selectedId,true) }
                ContextLink { objectName: "profile.save"; label: "Salvar"; enabled: profilesPanel.selectedId === root.profileService.activeProfileId; onTriggered: root.profileService.updateProfile(profilesPanel.selectedId) }
                ContextLink { objectName: "profile.export"; label: "Exportar"; onTriggered: root.controller.exportPackage(profilesPanel.selectedId) }
            }
            ContextLink {
                label: "O que o perfil guarda?"
                hint: "Composição, imagens, paleta e organização da barra. Material da barra, opções gerais do desktop e movimento reduzido permanecem como estão. Saves por wallpaper restauram apenas a composição."
                onTriggered: scopeNote.visible=!scopeNote.visible
            }
            Text { id: scopeNote; visible: false; width: parent.width; wrapMode: Text.WordWrap; color: root.mutedInk; font.family: root.theme.bodyFont; font.pixelSize: 11
                text: "Composição, imagens, paleta e organização da barra. Material da barra, opções gerais do desktop e movimento reduzido permanecem como estão. Saves por wallpaper restauram apenas a composição." }
            Text { width: parent.width; wrapMode: Text.WordWrap; color: root.theme.danger; font.pixelSize: 12; text: root.profileService.error || ""; visible: text.length > 0 }
        }
    }
    Component { id: motionPage
        Column { width: parent.width; spacing: 14
            SettingsMotionPreview { width: parent.width; theme: root.theme; motion: root.motion }
            Flow { width: parent.width; spacing: 24
                SettingSwitch {
                    objectName: "motion.reduced"; label: "Movimento reduzido"
                    hint: "Mostra os controles diretamente, sem expansão nem deslocamentos."
                    checked: root.config.reducedMotion
                    onTriggered: root.config.setValue("appearance.reducedMotion", !checked)
                }
                ContextLink { label: "Transições do wallpaper →"; onTriggered: root.revealSetting("wallpaper.transition") }
            }
        }
    }
    Component { id: systemPage
Column { width: parent ? parent.width : 600; spacing: 14
                    Text { text: "Desfoque global do Hyprland"; color: root.ink; font.pixelSize: 14; font.weight: Font.DemiBold }
                    SettingSwitch {
                        objectName: "system.hyprland-blur"
                        label: "Desfoque global"; checked: root.hyprlandBlurState === 1
                        enabled: root.hyprlandBlurState >= 0 && !root.hyprlandBlurBusy
                        onTriggered: root.setHyprlandBlur(!checked)
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

    Flow { width: parent.width; spacing: 8
        ContextLink { label: "Monitor, escala e resolução ↗"; enabled: !!root.controller.shell; onTriggered: root.openTool("monitor") }
        ContextLink { label: "Energia e Fan+ ↗"; enabled: !!root.controller.shell; onTriggered: root.openTool("battery") }
        ContextLink { label: "Brilho ↗"; enabled: !!root.controller.shell; onTriggered: root.openTool("brightness") }
    }
    LegacyControls { category: "system" }
}
    }
    Component { id: mediaPage
Column { width: parent ? parent.width : 600; spacing: 14
    ContextLink { label: "Volume e saída de áudio ↗"; onTriggered: root.openTool("volume") }
    LegacyControls { category: "media" }
}
    }
    Component { id: languagePage
Column { width: parent ? parent.width : 600; spacing: 16
    LegacyControls { category: "language" }
    Text { width: parent.width; wrapMode: Text.WordWrap; text: "O idioma selecionado é usado pelos componentes traduzidos do shell. Algumas opções das Settings ainda aparecem em português."; color: root.mutedInk; font.pixelSize: 12 }
    Text { text: "Formato de data e hora"; color: root.ink; font.pixelSize: 14 }
    Components.VeloraSettingsTabs {
        theme: root.theme; motion: root.motion; tabWidth: 110
        options: [{id:"pt_BR",label:"Português"},{id:"en_US",label:"English"},{id:"ja_JP",label:"日本語"}]
        selected: root.config.localeName
        onChosen: id => root.config.setValue("appearance.locale",id)
    }
    ContextLink { label: "Movimento reduzido →"; onTriggered: root.controller.setSettingsPage("motion") }
}
    }
}
