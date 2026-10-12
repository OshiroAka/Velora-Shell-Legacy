import QtQuick
import "../../components" as Components

Column {
    id: root
    required property var config
    required property var controller
    required property var editor
    required property var theme
    required property var motion
    property var legacyTheme: null
    property string space: "desktop"
    property string selectedKind: "clock"
    onSelectedKindChanged: {
        contextEntrance.stop()
        if (motion && !motion.reduced && visible) contextEntrance.restart()
        else context.opacity = 1
    }
    onVisibleChanged: if (!visible) { contextEntrance.stop(); context.opacity = 1 }
    readonly property var selectedWidget: config.sharedWidgets.find(item => item.kind === selectedKind) || null
    readonly property string selectedName: selectedWidget ? selectedWidget.name
        : selectedKind === "visualizer" ? "Visualizador" : "Moldura"
    readonly property int columns: Math.max(1, Math.min(space === "desktop" ? 4 : 3, Math.floor((width+12)/190)))
    spacing: 10

    SequentialAnimation {
        id: contextEntrance
        ScriptAction { script: context.opacity = 0 }
        PauseAnimation { duration: root.motion ? root.motion.geometryDuration : 0 }
        NumberAnimation { target: context; property: "opacity"; to: 1; duration: root.motion ? root.motion.contentDuration : 0 }
    }
    Connections {
        target: root.motion
        function onReducedChanged() { if (root.motion.reduced) { contextEntrance.stop(); context.opacity = 1 } }
    }

    function prepareResult(result) {
        let kind = ""
        if (result.id.indexOf("legacy.visualizer") === 0 || result.id === "desktop.visualizer") kind = "visualizer"
        else if (result.id.indexOf("legacy.frame") === 0 || result.id === "legacy.attach") kind = "frame"
        else if (result.id.indexOf("scene.gallery") === 0) kind = "gallery"
        else if (result.id.indexOf("widget.") === 0) kind = result.id.split(".")[1]
        if (kind && selectedKind !== kind) { selectedKind = kind; return true }
        return false
    }
    function editSelected() {
        const identifier = selectedWidget ? selectedWidget.id : ""
        controller.beginEditing(space)
        if (identifier) editor.select(identifier)
    }
    function toggleWidget(widget) {
        config.setSharedWidgetVisibility(widget.kind,
            space === "desktop" ? !widget.desktopEnabled : widget.desktopEnabled,
            space === "lock" ? !widget.lockEnabled : widget.lockEnabled)
    }

    component Link: Components.VeloraSettingsLink { theme: root.theme }
    component Toggle: Components.VeloraSettingsSwitch { theme: root.theme; motion: root.motion }
    component Caption: Text { color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 11 }

    Flow {
        width: parent.width; spacing: 18
        Rectangle {
            objectName: "scene.enter-" + root.space
            width: actionText.implicitWidth+28; height: 38; radius: 12
            color: Qt.rgba(root.theme.accent.r,root.theme.accent.g,root.theme.accent.b,.28)
            border.color: root.theme.accentSoft; border.width: 1
            activeFocusOnTab: true
            function triggered() { root.controller.beginEditing(root.space) }
            Accessible.role: Accessible.Button; Accessible.name: actionText.text
            Accessible.onPressAction: triggered()
            Keys.onReturnPressed: triggered()
            Keys.onSpacePressed: triggered()
            Text { id: actionText; anchors.centerIn: parent; text: root.space === "desktop" ? "Editar Desktop" : "Editar prévia"; color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 12; font.weight: Font.DemiBold }
            Rectangle { anchors.fill: parent; radius: 12; color: "transparent"; border.width: parent.activeFocus ? 2 : 0; border.color: root.theme.textPrimary }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.triggered() }
        }
        Toggle {
            objectName: "desktopWidgetsToggle"; visible: root.space === "desktop"
            label: "Widgets no desktop"; checked: root.config.desktopWidgetsEnabled
            hint: "Ocultar todos preserva a escolha de cada widget."
            onTriggered: root.config.setValue("desktop.widgetsEnabled", !checked)
        }
        Link { visible: root.space === "lock"; objectName: "scene.character"; label: "Trocar personagem principal ↗"; onTriggered: root.controller.chooseImage(0) }
    }
    Caption {
        width: parent.width; wrapMode: Text.WordWrap
        text: root.space === "desktop" && !root.config.desktopWidgetsEnabled
            ? "Widgets ocultos no desktop. Suas escolhas estão preservadas."
            : "Selecione uma miniatura para ajustar. Use o switch para mostrar ou ocultar."
    }

    component WidgetCard: Rectangle {
        id: card
        required property string kind
        required property string title
        property bool checked: false
        property bool canToggle: true
        property string toggleName: ""
        signal toggleRequested()
        readonly property bool selected: root.selectedKind === kind
        width: (root.width-(root.columns-1)*12)/root.columns; height: 132; radius: 17
        color: Qt.rgba(root.theme.accent.r,root.theme.accent.g,root.theme.accent.b,selected ? .14 : hover.hovered ? .08 : .035)
        border.color: selected || activeFocus ? root.theme.accentSoft : root.theme.borderSubtle
        border.width: 1
        Behavior on color { ColorAnimation { duration: root.motion ? root.motion.surfaceHover : 0 } }
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: title + ", ajustes"
        Accessible.checkable: true; Accessible.checked: selected
        Accessible.onPressAction: triggered()
        function triggered() { root.selectedKind = kind }
        Keys.onSpacePressed: triggered()
        Keys.onReturnPressed: triggered()
        HoverHandler { id: hover }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: card.triggered() }
        SettingsWidgetPreview {
            anchors.top: parent.top; anchors.topMargin: 9; anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width-28; height: 81; theme: root.theme; kind: card.kind
            solid: root.config.widgetSurfaceMode === "solid"
            visualizerMode: root.legacyTheme ? root.legacyTheme.visualizerMode : "wave"
            opacity: card.checked ? 1 : .56
            Accessible.ignored: true
        }
        Text {
            x: 13; y: 102; width: parent.width-70
            text: card.title; color: root.theme.textPrimary; font.family: root.theme.bodyFont
            font.pixelSize: 11; elide: Text.ElideRight
        }
        Toggle {
            objectName: card.toggleName
            anchors.right: parent.right; anchors.rightMargin: 10; y: 92
            width: 42; label: card.title + (root.space === "lock" ? " na prévia Lock" : " no desktop")
            checked: card.checked; enabled: card.canToggle
            onTriggered: card.toggleRequested()
        }
    }
    Flow {
        width: parent.width; spacing: 12
        Repeater {
            model: root.config.sharedWidgets
            WidgetCard {
                required property var modelData
                objectName: "widgetCard."+kind
                kind: modelData.kind; title: modelData.name
                toggleName: "widget."+kind+"."+root.space
                checked: root.space === "desktop" ? modelData.desktopEnabled : modelData.lockEnabled
                onToggleRequested: root.toggleWidget(modelData)
            }
        }
        WidgetCard {
            visible: root.space === "desktop"; objectName: "widgetCard.visualizer"
            kind: "visualizer"; title: "Visualizador"; toggleName: "desktopVisualizerToggle"
            checked: root.config.desktopVisualizerEnabled
            onToggleRequested: root.config.setValue("desktop.visualizerEnabled", !checked)
        }
        WidgetCard {
            visible: root.space === "desktop"; objectName: "widgetCard.frame"
            kind: "frame"; title: "Moldura"; toggleName: "legacy.frame"
            checked: root.legacyTheme ? root.legacyTheme.desktopFrameEnabled : false
            canToggle: !!root.legacyTheme
            onToggleRequested: root.legacyTheme.setDesktopFrameEnabled(!checked)
        }
    }
    Rectangle {
        width: parent.width; height: context.implicitHeight+22; radius: 14
        color: Qt.rgba(root.theme.accent.r,root.theme.accent.g,root.theme.accent.b,.055)
        Column {
            id: context; x: 14; y: 11; width: parent.width-28; spacing: 8
            Row {
                spacing: 18
                Text { text: root.selectedName; color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 12; font.weight: Font.DemiBold; height: 32; verticalAlignment: Text.AlignVCenter }
                Link { visible: !!root.selectedWidget; label: "Posição e estilo ↗"; onTriggered: root.editSelected() }
            }
            Caption {
                visible: !!root.selectedWidget && root.selectedKind !== "gallery"
                width: parent.width; wrapMode: Text.WordWrap
                text: ({clock:"Tipografia e tamanho no editor.",calendar:"Agenda e lembretes no widget do calendário.",weather:"A previsão acompanha sua localização configurada.",media:"Controles conectados ao seu player.",system:"CPU, memória e armazenamento no desktop."})[root.selectedKind] || ""
            }
            Loader {
                width: parent.width; active: root.selectedKind === "gallery"
                sourceComponent: Column {
                    width: parent.width; spacing: 6
                    Caption { text: "Fotos compartilhadas entre Desktop e Lock." }
                    Flow { width: parent.width; spacing: 8
                        Repeater { model: 3
                            Rectangle {
                                id: photo; required property int index
                                readonly property int assetIndex: root.config.galleryOrder[index] === undefined ? index : root.config.galleryOrder[index]
                                objectName: "scene.gallery."+(index+1)
                                width: Math.min(174,(context.width-16)/3); height: 100; radius: 10
                                color: Qt.rgba(0,0,0,.12); clip: true
                                activeFocusOnTab: true
                                function triggered() { root.controller.chooseImage(assetIndex+1) }
                                Accessible.role: Accessible.Button; Accessible.name: "Trocar imagem " + (index+1)
                                Accessible.onPressAction: triggered()
                                Keys.onSpacePressed: triggered()
                                Keys.onReturnPressed: triggered()
                                Image { id: photoImage; anchors.fill: parent; source: String(root.config.galleryPaths[photo.assetIndex] || ""); sourceSize.width: 220; asynchronous: true; fillMode: Image.PreserveAspectCrop }
                                SettingsWidgetPreview { anchors.fill: parent; visible: photoImage.status !== Image.Ready; theme: root.theme; kind: "gallery"; opacity: .45 }
                                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 27; color: Qt.rgba(0,0,0,.5)
                                    Text { anchors.centerIn: parent; text: ["Esquerda", "Centro", "Direita"][photo.index]+" ↗"; color: "white"; font.family: root.theme.bodyFont; font.pixelSize: 10 } }
                                Rectangle { anchors.fill: parent; radius: 10; color: "transparent"; border.color: root.theme.accent; border.width: parent.activeFocus ? 2 : 0 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: photo.triggered() }
                            }
                        }
                    }
                }
            }
            Loader {
                width: parent.width; active: root.selectedKind === "visualizer" && !!root.legacyTheme
                sourceComponent: Column {
                    width: parent.width; spacing: 4
                    Components.VeloraSettingsTabs {
                        objectName: "legacy.visualizer-mode"; theme: root.theme; motion: root.motion
                        options: [{id:"wave",label:"Wave"},{id:"pixels",label:"Pixels"}]
                        selected: root.legacyTheme.visualizerMode
                        onChosen: id => root.legacyTheme.setVisualizerMode(id)
                    }
                    Components.VeloraSettingsSlider {
                        objectName: "legacy.visualizer-strength"; theme: root.theme; label: "Intensidade"
                        value: root.legacyTheme.visualizerStrength
                        onEdited: value => root.legacyTheme.setVisualizerStrength(value)
                    }
                }
            }
            Loader {
                width: parent.width; active: root.selectedKind === "frame" && !!root.legacyTheme
                sourceComponent: Column {
                    width: parent.width; spacing: 4
                    Toggle { objectName: "legacy.attach"; label: "Painéis unidos à barra"; checked: root.legacyTheme.popupAttachedToBar; onTriggered: root.legacyTheme.setPopupAttachedToBar(!checked) }
                    Components.VeloraSettingsSlider {
                        objectName: "legacy.frame-opacity"; theme: root.theme; label: "Transparência da moldura"
                        minimum: root.legacyTheme.minOpacityForRole("sidebar"); maximum: .98
                        value: root.legacyTheme.sidebarOpacity
                        onEdited: value => root.legacyTheme.applyOpacity(value,root.legacyTheme.popupOpacity,root.legacyTheme.cardOpacity)
                    }
                    Toggle { objectName: "legacy.frame-blur"; label: "Desfoque da moldura"; enabled: false; checked: root.legacyTheme.frameBlurEnabled; hint: "Controle histórico indisponível neste material." }
                }
            }
        }
    }
    Flow {
        visible: root.space === "desktop"; width: parent.width; spacing: 14
        Text { text: "Superfície"; height: 36; verticalAlignment: Text.AlignVCenter; color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 11 }
        Components.VeloraSettingsTabs {
            objectName: "widgets.surface"; theme: root.theme; motion: root.motion; tabWidth: 116
            options: [{id:"solid",label:"100% sólidos"},{id:"bar",label:"Iguais à barra"}]
            selected: root.config.widgetSurfaceMode
            onChosen: id => root.config.setWidgetSurfaceMode(id)
        }
        Toggle {
            objectName: "widgets.blur"; label: "Blur dos widgets"
            visible: root.config.widgetSurfaceMode === "bar" && root.config.barMaterial === "glass"
            checked: root.config.widgetBlurEnabled
            onTriggered: root.config.setValue("lockPreview.sharedWidgets.blurEnabled", !checked)
        }
    }
    Flow {
        width: parent.width; spacing: 20
        Link { label: "Wallpaper →"; onTriggered: root.controller.setSettingsPage("wallpapers") }
        Link { visible: root.space === "desktop"; label: "Material da barra →"; hint: "A opção Iguais à barra herda a cor, transparência e desfoque da barra."; onTriggered: root.controller.setSettingsPage("bar") }
        Link { visible: root.space === "lock"; label: "Superfícies dos widgets →"; onTriggered: root.controller.setSettingsPage("desktop") }
        Link { label: root.space === "desktop" ? "Prévia Lock →" : "Desktop →"; hint: "Cada espaço mantém sua visibilidade, posição e aparência."; onTriggered: root.controller.setSettingsPage(root.space === "desktop" ? "lock" : "desktop") }
    }
}
