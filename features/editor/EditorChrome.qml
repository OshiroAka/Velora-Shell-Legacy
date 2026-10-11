import QtQuick
import QtQuick.Controls
import "../../components" as Components
import "../lock" as Lock
import "../../core/SurfaceGeometry.js" as Geometry

Item {
    id: root

    required property bool presented
    required property var controller
    required property var config
    required property var theme
    required property var motion
    required property var profileService
    required property var wallpaperStore
    required property var editor

    property bool catalogOpen: false
    property bool profilesOpen: false
    property bool barOpen: false
    property bool advancedOpen: false
    property bool navigationOpen: false
    property bool systemOpen: false
    readonly property bool settingsMode: controller.mode === "settings"
    readonly property bool editingMode: controller.mode === "editing"
    readonly property bool railOnRight: controller.shell ? controller.shell.barOnRight : false
    readonly property var surfaceArea: Geometry.area(width, height, config.topbarEnabled ? 64 : 0,
        railOnRight, config.topbarEnabled ? 40 : 0, 0, 18)
    function fitPanel(w, h, x, y) { return Geometry.fit(surfaceArea, w, h, x, y) }
    SettingsHome {
        id: settingsHome
        readonly property real wantedWidth: Math.min(1020, parent.width * 0.90)
        readonly property real wantedHeight: Math.min(760, parent.height * 0.88)
        readonly property var fitted: root.fitPanel(wantedWidth, wantedHeight, (parent.width - wantedWidth) / 2, (parent.height - wantedHeight) / 2)
        width: fitted.width; height: fitted.height
        x: Geometry.clamp(Math.round(fitted.x), root.surfaceArea.x, root.surfaceArea.x + root.surfaceArea.width - width)
        y: Geometry.clamp(Math.round(fitted.y), root.surfaceArea.y, root.surfaceArea.y + root.surfaceArea.height - height)
        z: 40; visible: root.settingsMode
        config: root.config; controller: root.controller; editor: root.editor
        theme: root.theme; profileService: root.profileService
        wallpaperStore: root.wallpaperStore
        onRequestClose: root.controller.hide()
    }
    readonly property bool desktop: editor.editSpace === "desktop"
    readonly property var selectedLayer: editor.layerById(editor.selectedLayerId)
    readonly property var selectedTransform: selectedLayer
        ? selectedLayer.transform : ({})
    readonly property var selectedStyle: selectedLayer
        ? (selectedLayer.style || ({})) : ({})
    property alias toolBarItem: toolBar
    property alias inspectorItem: inspector
    property alias catalogItem: catalog
    property alias profilesItem: profilesPanel
    property alias barItem: barPanel
    property alias layersItem: layersPanel
    property alias settingsItem: settingsHome

    function barLabel(type) {
        const labels = {
            brand: "Marca Velora", workspaces: "Áreas de trabalho",
            launcher: "Aplicativos", search: "Pesquisa",
            context: "Janela ativa", weather: "Clima",
            clock: "Data e hora", media: "Mídia",
            wifi: "Wi-Fi", volume: "Volume", battery: "Bateria",
            settings: "Editor", avatar: "Avatar"
        }
        return labels[String(type)] || String(type)
    }

    opacity: presented ? 1 : 0
    visible: opacity > 0.001
    Behavior on opacity {
        NumberAnimation { duration: root.motion.selection; easing.type: Easing.OutCubic }
    }

    function builtInEnabled(kind) {
        const widget = config.sharedWidgetByKind(kind)
        if (!widget)
            return false
        return desktop ? Boolean(widget.desktopEnabled) : Boolean(widget.lockEnabled)
    }

    function numeric(value, fallback) {
        const parsed = Number(value)
        return isFinite(parsed) ? parsed : fallback
    }

    component ToolButton: Rectangle {
        id: button
        property string glyph: ""
        property string caption: ""
        property bool activeState: false
        property bool compact: false
        signal triggered
        width: compact ? 42 : Math.max(54, label.implicitWidth + 22)
        height: 42
        radius: 16
        color: activeState
            ? Qt.rgba(root.theme.accent.r, root.theme.accent.g,
                      root.theme.accent.b, pointer.containsMouse ? 0.55 : 0.38)
            : Qt.rgba(1, 1, 1, pointer.containsMouse ? 0.20 : 0.08)
        border.width: 1
        border.color: pointer.containsMouse
            ? Qt.rgba(1, 1, 1, 0.56) : Qt.rgba(1, 1, 1, 0.18)
        scale: pointer.pressed ? 0.94 : 1
        opacity: enabled ? 1 : 0.38

        Behavior on color { ColorAnimation { duration: root.motion.reduced ? 0 : 190 } }
        Behavior on scale { NumberAnimation { duration: root.motion.micro; easing.type: Easing.OutCubic } }

        Text {
            id: label
            anchors.centerIn: parent
            text: button.caption.length ? button.caption : button.glyph
            color: "white"
            font.family: root.theme.bodyFont
            font.pixelSize: button.caption.length ? 11 : 18
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: pointer
            anchors.fill: parent
            enabled: button.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.triggered()
        }
    }

    component EasySlider: Column {
        property string title: ""
        property real value: 100
        property real from: 0
        property real to: 100
        signal committed(real value)
        width: inspectorFlow.width
        spacing: 4
        Text { text: title + " · " + Math.round(control.pressed ? control.value : value) + "%"
            color: "#edf2ff"; font.pixelSize: 13 }
        Slider {
            id: control
            width: parent.width; from: parent.from; to: parent.to
            value: parent.value; stepSize: 1
            onPressedChanged: if (!pressed) parent.committed(value)
            onMoved: if (!pressed) parent.committed(value)
        }
    }

    component MiniField: Item {
        id: field
        property string title: ""
        property string value: ""
        property string suffix: ""
        property real fieldWidth: 92
        signal accepted(string value)
        width: fieldWidth
        height: 48

        Text {
            x: 2; y: 0
            text: field.title
            color: Qt.rgba(1, 1, 1, 0.70)
            font.family: root.theme.bodyFont
            font.pixelSize: 9
            font.weight: Font.DemiBold
        }

        Rectangle {
            x: 0; y: 16
            width: parent.width; height: 30; radius: 11
            color: Qt.rgba(1, 1, 1, input.activeFocus ? 0.18 : 0.08)
            border.width: 1
            border.color: input.activeFocus
                ? root.theme.accentSoft : Qt.rgba(1, 1, 1, 0.16)

            TextInput {
                id: input
                anchors.fill: parent
                anchors.leftMargin: 9
                anchors.rightMargin: suffixLabel.implicitWidth + 8
                verticalAlignment: TextInput.AlignVCenter
                text: field.value
                color: "white"
                selectByMouse: true
                font.family: root.theme.bodyFont
                font.pixelSize: 11
                onEditingFinished: field.accepted(text)
            }

            Text {
                id: suffixLabel
                anchors.right: parent.right
                anchors.rightMargin: 7
                anchors.verticalCenter: parent.verticalCenter
                text: field.suffix
                color: Qt.rgba(1, 1, 1, 0.48)
                font.pixelSize: 9
            }
        }
    }

    Lock.GlassPanel {
        id: toolBar
        visible: root.editingMode
        width: Math.min(root.surfaceArea.width, 560)
        height: 64
        x: Geometry.clamp((parent.width - width) / 2, root.surfaceArea.x, root.surfaceArea.x + root.surfaceArea.width - width)
        y: Geometry.clamp(root.desktop ? parent.height - height - 18 : 18, root.surfaceArea.y, root.surfaceArea.y + root.surfaceArea.height - height)
        z: 30
        radius: 25
        nativeOptics: false
        materialMode: "solid"
        solidColor: "#202634"
        materialOpacity: 0.98
        surfaceColor: root.theme.glass
        borderColor: root.theme.border
        shadowColor: root.theme.shadow

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top; anchors.bottomMargin: 9
            visible: root.desktop
            text: "Arraste os itens da barra superior para mudar a ordem."
            color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 12
            style: Text.Outline; styleColor: root.theme.surfaceRaised
        }

        Row {
            anchors.centerIn: parent
            spacing: 8

            ToolButton {
                glyph: "+"; compact: true; activeState: root.catalogOpen
                onTriggered: { root.catalogOpen = !root.catalogOpen; root.profilesOpen = false; root.barOpen = false }
            }
            ToolButton {
                glyph: "↖"; compact: true
                activeState: root.editor.toolMode === "select"
                onTriggered: root.editor.setToolMode("select")
            }
            ToolButton {
                caption: "Recortar"
                enabled: root.selectedLayer && root.selectedLayer.type === "image"
                activeState: root.editor.toolMode === "crop"
                onTriggered: root.editor.setToolMode(
                    root.editor.toolMode === "crop" ? "select" : "crop")
            }
            ToolButton {
                caption: "Texto"
                onTriggered: root.editor.addText("Novo texto")
            }
            ToolButton {
                glyph: "↶"; compact: true; enabled: root.editor.canUndo
                onTriggered: root.editor.undo()
            }
            ToolButton {
                glyph: "↷"; compact: true; enabled: root.editor.canRedo
                onTriggered: root.editor.redo()
            }
            ToolButton {
                caption: "Concluir"
                activeState: true
                onTriggered: root.controller.returnToSettings()
            }
        }
    }

    Lock.GlassPanel {
        id: layersPanel
        visible: false
        x: root.surfaceArea.x
        y: Geometry.clamp(root.desktop ? 84 : 102, root.surfaceArea.y, root.surfaceArea.y + root.surfaceArea.height - height)
        width: Math.min(252, root.surfaceArea.width)
        height: Math.max(0, Math.min(520, parent.height - 190))
        z: 28
        radius: 26
        nativeOptics: false
        materialMode: "solid"
        solidColor: "#202634"
        materialOpacity: 0.98
        surfaceColor: root.theme.surfaceRaised
        borderColor: root.theme.borderStrong
        shadowColor: root.theme.shadow

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 9
            Text {
                text: "Elementos · " + (root.desktop ? "Desktop" : "Lockscreen")
                color: root.theme.textPrimary
                font.family: root.theme.bodyFont
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            Text {
                text: root.editor.editableLayers.length + " itens"
                color: root.theme.textMuted
                font.family: root.theme.bodyFont
                font.pixelSize: 10
            }
            Flickable {
                width: parent.width
                height: layersPanel.height - 82
                clip: true
                contentWidth: width
                contentHeight: layersColumn.height
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: layersColumn
                    width: parent.width
                    spacing: 5
                    Repeater {
                        model: root.editor.editableLayers
                        Rectangle {
                            id: layerRow
                            required property var modelData
                            width: layersColumn.width
                            height: 44
                            radius: 13
                            color: String(modelData.id) === root.editor.selectedLayerId
                                ? root.theme.accentMuted
                                : (layerPointer.containsMouse
                                    ? root.theme.surfaceHover : root.theme.surfaceSoft)
                            border.width: 1
                            border.color: String(modelData.id) === root.editor.selectedLayerId
                                ? root.theme.accent : root.theme.borderSubtle
                            Text {
                                x: 11; anchors.verticalCenter: parent.verticalCenter
                                text: modelData.sharedWidget ? "▦" : "◇"
                                color: root.theme.accentSoft
                                font.pixelSize: 14
                            }
                            Text {
                                x: 34; width: parent.width - 92
                                anchors.verticalCenter: parent.verticalCenter
                                text: String(modelData.name || modelData.type)
                                color: modelData.visible
                                    ? root.theme.textPrimary : root.theme.textMuted
                                elide: Text.ElideRight
                                font.family: root.theme.bodyFont
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 31
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.locked ? "⌾" : ""
                                color: root.theme.textMuted
                                font.pixelSize: 11
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.visible ? "●" : "○"
                                color: modelData.visible
                                    ? root.theme.success : root.theme.textMuted
                                font.pixelSize: 11
                            }
                            MouseArea {
                                id: layerPointer
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: function(mouse) {
                                    if (mouse.button === Qt.RightButton)
                                        root.editor.updateLayer(modelData.id,
                                            { visible: !modelData.visible })
                                    else
                                        root.editor.select(modelData.id)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Lock.GlassPanel {
        id: barPanel
        visible: false
        width: Math.min(560, root.surfaceArea.width)
        height: Math.max(0, Math.min(620, parent.height - 170))
        x: Math.max(root.surfaceArea.x, Math.min(root.surfaceArea.x + root.surfaceArea.width - width,
            toolBar.x + (toolBar.width - width) / 2))
        y: Geometry.clamp(toolBar.y - height - 12, root.surfaceArea.y, root.surfaceArea.y + root.surfaceArea.height - height)
        z: 33
        radius: 28
        nativeOptics: false
        materialMode: "solid"
        solidColor: "#202634"
        materialOpacity: 0.98
        surfaceColor: root.theme.glass
        borderColor: root.theme.border
        shadowColor: root.theme.shadow

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 9

            Text {
                text: "Composição da barra deste perfil"
                color: "white"
                font.family: root.theme.bodyFont
                font.pixelSize: 15
                font.weight: Font.Bold
            }
            Text {
                width: parent.width
                text: "Esquerda e direita ficam presas às bordas; o centro nunca se une a elas."
                wrapMode: Text.WordWrap
                color: Qt.rgba(1, 1, 1, 0.62)
                font.family: root.theme.bodyFont
                font.pixelSize: 10
            }

            Flickable {
                width: parent.width
                height: barPanel.height - 142
                clip: true
                contentWidth: width
                contentHeight: barRows.height
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: barRows
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: root.config.topbarLayout

                        Rectangle {
                            id: barRow
                            required property var modelData
                            width: barRows.width
                            height: 50
                            radius: 16
                            color: Qt.rgba(1, 1, 1, 0.065)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.13)

                            Text {
                                x: 12; width: 128; height: parent.height
                                text: root.barLabel(barRow.modelData.type)
                                color: barRow.modelData.enabled ? "white" : Qt.rgba(1, 1, 1, 0.42)
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                                font.family: root.theme.bodyFont
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }

                            Row {
                                anchors.right: parent.right
                                anchors.rightMargin: 7
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                ToolButton {
                                    caption: "E"; compact: true
                                    activeState: barRow.modelData.section === "left"
                                    onTriggered: root.config.moveTopbarItemToSection(barRow.modelData.id, "left")
                                }
                                ToolButton {
                                    caption: "C"; compact: true
                                    activeState: barRow.modelData.section === "center"
                                    onTriggered: root.config.moveTopbarItemToSection(barRow.modelData.id, "center")
                                }
                                ToolButton {
                                    caption: "D"; compact: true
                                    activeState: barRow.modelData.section === "right"
                                    onTriggered: root.config.moveTopbarItemToSection(barRow.modelData.id, "right")
                                }
                                ToolButton {
                                    glyph: "↑"; compact: true
                                    onTriggered: root.config.moveTopbarItem(barRow.modelData.id, -1)
                                }
                                ToolButton {
                                    glyph: "↓"; compact: true
                                    onTriggered: root.config.moveTopbarItem(barRow.modelData.id, 1)
                                }
                                ToolButton {
                                    caption: barRow.modelData.enabled ? "On" : "Off"
                                    compact: true
                                    activeState: barRow.modelData.enabled
                                    onTriggered: root.config.setTopbarItemEnabled(
                                        barRow.modelData.id, !barRow.modelData.enabled)
                                }
                            }
                        }
                    }
                }
            }

            Row {
                spacing: 8
                ToolButton { caption: "Restaurar padrão"; onTriggered: root.config.resetTopbarLayout() }
                ToolButton {
                    caption: "Salvar no perfil"
                    enabled: root.profileService.activeProfileId.length > 0
                    onTriggered: root.profileService.updateProfile(root.profileService.activeProfileId)
                }
            }
        }
    }

    Lock.GlassPanel {
        id: catalog
        visible: root.editingMode && root.catalogOpen
        opacity: visible ? 1 : 0
        width: Math.min(300, root.surfaceArea.width)
        height: Math.min(436, Math.max(0, root.surfaceArea.height - toolBar.height - 12))
        x: Math.max(root.surfaceArea.x, Math.min(root.surfaceArea.x + root.surfaceArea.width - width,
            toolBar.x + 8))
        y: Geometry.clamp(root.desktop ? toolBar.y - height - 12 : toolBar.y + toolBar.height + 12, root.surfaceArea.y, root.surfaceArea.y + root.surfaceArea.height - height)
        z: 32
        radius: 28
        nativeOptics: false
        materialMode: "solid"
        solidColor: "#202634"
        materialOpacity: 0.98
        surfaceColor: root.theme.glass
        borderColor: root.theme.border
        shadowColor: root.theme.shadow

        Flickable {
            anchors.fill: parent; anchors.margins: 16
            contentWidth: width; contentHeight: catalogContents.implicitHeight
            clip: true; boundsBehavior: Flickable.StopAtBounds
        Column {
            id: catalogContents
            width: parent.width
            spacing: 8

            Text {
                text: "Adicionar ao " + (root.desktop ? "Desktop" : "Lock")
                color: "white"
                font.family: root.theme.bodyFont
                font.pixelSize: 15
                font.weight: Font.Bold
            }

            Repeater {
                model: root.editor.builtInCatalog
                ToolButton {
                    required property var modelData
                    width: 268
                    caption: (root.builtInEnabled(modelData.kind) ? "✓  " : "+  ")
                        + modelData.name
                    activeState: root.builtInEnabled(modelData.kind)
                    onTriggered: root.editor.setBuiltInVisible(modelData.kind,
                        !root.builtInEnabled(modelData.kind))
                }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.16) }

            Flow {
                width: parent.width
                spacing: 7
                ToolButton { caption: "Imagem"; onTriggered: root.controller.chooseCustomImage() }
                ToolButton { caption: "Galeria 2×2"; onTriggered: root.controller.choosePhotoGrid("grid2") }
                ToolButton { caption: "3×3"; onTriggered: root.controller.choosePhotoGrid("grid3") }
                ToolButton { caption: "4×4"; onTriggered: root.controller.choosePhotoGrid("grid4") }
                ToolButton { caption: "Destaque"; onTriggered: root.controller.choosePhotoGrid("feature") }
            }
        }
        }
    }

    Lock.GlassPanel {
        id: profilesPanel
        visible: false
        width: Math.min(330, root.surfaceArea.width)
        height: Math.max(0, Math.min(470, parent.height - 170))
        x: Math.max(root.surfaceArea.x, Math.min(root.surfaceArea.x + root.surfaceArea.width - width,
            toolBar.x + 190))
        y: Geometry.clamp(root.desktop ? toolBar.y - height - 12 : toolBar.y + toolBar.height + 12, root.surfaceArea.y, root.surfaceArea.y + root.surfaceArea.height - height)
        z: 32
        radius: 28
        nativeOptics: false
        materialMode: "solid"
        solidColor: "#202634"
        materialOpacity: 0.98
        surfaceColor: root.theme.glass
        borderColor: root.theme.border
        shadowColor: root.theme.shadow

        Flickable {
            anchors.fill: parent; anchors.margins: 16
            contentWidth: width; contentHeight: profilesPanelContents.implicitHeight
            clip: true; boundsBehavior: Flickable.StopAtBounds
        Column {
            id: profilesPanelContents
            width: parent.width
            spacing: 8
            Text {
                text: "Perfis e wallpaper"
                color: "white"; font.family: root.theme.bodyFont
                font.pixelSize: 15; font.weight: Font.Bold
            }
            ToolButton { caption: "Trocar wallpaper"; width: 298; onTriggered: root.controller.chooseWallpaper() }
            Flow {
                width: parent.width
                spacing: 6
                visible: root.desktop
                ToolButton { caption: "Coluna"; onTriggered: root.editor.applyDesktopTemplate("side-column") }
                ToolButton { caption: "Cantos"; onTriggered: root.editor.applyDesktopTemplate("split-corners") }
                ToolButton { caption: "Periférico"; onTriggered: root.editor.applyDesktopTemplate("scattered") }
                ToolButton { caption: "Galeria ↑"; onTriggered: root.editor.applyDesktopTemplate("gallery-top-right") }
                ToolButton { caption: "Restaurar"; onTriggered: root.editor.restoreDesktopLayout() }
                ToolButton { caption: "Próximo"; onTriggered: root.editor.advanceDesktopTemplate() }
            }
            ToolButton {
                caption: "Salvar no perfil ativo"; width: 298
                enabled: root.profileService.activeProfileId.length > 0
                onTriggered: root.profileService.updateProfile(root.profileService.activeProfileId)
            }
            ToolButton { caption: "Importar .helixpack"; width: 298; onTriggered: root.controller.importPackage() }
            ToolButton {
                caption: "Exportar .helixpack"; width: 298
                enabled: root.profileService.activeProfileId.length > 0
                onTriggered: root.controller.exportPackage(root.profileService.activeProfileId)
            }
            Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.16) }
            Repeater {
                model: root.profileService.profiles
                ToolButton {
                    required property var modelData
                    width: 298
                    caption: String(modelData.name || modelData.id)
                    activeState: String(modelData.id) === root.profileService.activeProfileId
                    onTriggered: root.profileService.applyProfile(modelData.id, true)
                }
            }
        }
        }
    }

    Lock.GlassPanel {
        id: inspector
        visible: root.editingMode && Boolean(root.selectedLayer)
        x: Geometry.clamp(root.numeric(root.selectedTransform.x, 0) < 800
            ? parent.width - width - 20 : 20, root.surfaceArea.x, root.surfaceArea.x + root.surfaceArea.width - width)
        y: 78
        width: Math.min(360, parent.width * 0.40)
        height: Math.max(0, parent.height - 174)
        z: 29
        radius: 28
        nativeOptics: false
        materialMode: "solid"
        solidColor: "#202634"
        materialOpacity: 0.98
        surfaceColor: root.theme.glass
        borderColor: root.theme.border
        shadowColor: root.theme.shadow

        Flickable {
            id: inspectorScroll
            anchors.fill: parent
            anchors.margins: 14
            clip: true
            contentWidth: width
            contentHeight: inspectorFlow.height
            boundsBehavior: Flickable.StopAtBounds

            Flow {
                id: inspectorFlow
                width: inspectorScroll.width
                height: childrenRect.height
                spacing: 8

                Text {
                    width: inspectorFlow.width
                    height: 42
                    text: root.selectedLayer ? root.selectedLayer.name : ""
                    color: "white"
                    font.family: root.theme.bodyFont
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }


                Text {
                    width: inspectorFlow.width
                    text: "Arraste na cena para mover. Use os cantos para redimensionar."
                    wrapMode: Text.WordWrap
                    color: "#c5cddd"; font.pixelSize: 12
                }
                EasySlider {
                    title: "Tamanho"; from: 10; to: 300
                    value: Number(root.selectedTransform.scale || 1) * 100
                    onCommitted: function(v) { root.editor.setTransform(root.editor.selectedLayerId, "scale", v / 100) }
                }
                EasySlider {
                    title: "Opacidade do fundo"
                    value: Number(root.selectedStyle.surfaceOpacity === undefined ? 0.88 : root.selectedStyle.surfaceOpacity) * 100
                    onCommitted: function(v) {
                        root.editor.setItemStyle(root.editor.selectedLayerId, "surfaceOpacity", v / 100)
                    }
                }
                EasySlider {
                    title: "Opacidade do elemento"
                    value: Number(root.selectedTransform.opacity === undefined ? 1 : root.selectedTransform.opacity) * 100
                    onCommitted: function(v) { root.editor.setTransform(root.editor.selectedLayerId, "opacity", v / 100) }
                }
                Text {
                    width: inspectorFlow.width
                    text: "Conteúdo compartilhado entre Desktop e Lock. Posição e aparência independentes."
                    wrapMode: Text.WordWrap; color: "#aab5c8"; font.pixelSize: 11
                }
                ToolButton {
                    caption: "Trocar personagem"
                    visible: root.selectedLayer && root.selectedLayer.type === "character"
                    onTriggered: root.controller.chooseImage(0)
                }
                ToolButton {
                    caption: "Trocar avatar"
                    visible: root.selectedLayer && root.selectedLayer.type === "profile"
                    onTriggered: root.controller.chooseAvatar()
                }
                ToolButton {
                    caption: root.advancedOpen ? "Ocultar avançado" : "Avançado"
                    onTriggered: root.advancedOpen = !root.advancedOpen
                }
                ToolButton {
                    caption: "Liquid"
                    activeState: String(root.selectedStyle.material || "liquid") === "liquid"
                    onTriggered: root.editor.setItemStyle(root.editor.selectedLayerId,
                        "material", "liquid")
                }
                ToolButton {
                    caption: "Sólido"
                    activeState: String(root.selectedStyle.material || "") === "solid"
                    onTriggered: root.editor.setItemStyle(root.editor.selectedLayerId,
                        "material", "solid")
                }
                ToolButton {
                    caption: "Sem fundo"
                    activeState: String(root.selectedStyle.material || "") === "none"
                    onTriggered: root.editor.setItemStyle(root.editor.selectedLayerId,
                        "material", "none")
                }

                MiniField {
                    visible: root.advancedOpen
                    title: "Cor sólida"; fieldWidth: 104
                    value: String(root.selectedStyle.solidColor || "#20222a")
                    onAccepted: function(value) { root.editor.setItemStyle(
                        root.editor.selectedLayerId, "solidColor", value) }
                }
                MiniField {
                    visible: root.advancedOpen
                    title: "Fonte"; fieldWidth: root.desktop ? 186 : 142
                    value: String(root.selectedStyle.fontFamily || "Poppins")
                    onAccepted: function(value) { root.editor.setItemStyle(
                        root.editor.selectedLayerId, "fontFamily", value) }
                }
                ToolButton { caption: "Importar fonte"; onTriggered: root.controller.chooseFont() }

                MiniField {
                    visible: root.advancedOpen
                    title: "X"; suffix: "px"
                    value: Math.round(Number(root.selectedTransform.x || 0)).toString()
                    onAccepted: function(value) { root.editor.setTransform(
                        root.editor.selectedLayerId, "x", root.numeric(value, 0)) }
                }
                MiniField {
                    visible: root.advancedOpen
                    title: "Y"; suffix: "px"
                    value: Math.round(Number(root.selectedTransform.y || 0)).toString()
                    onAccepted: function(value) { root.editor.setTransform(
                        root.editor.selectedLayerId, "y", root.numeric(value, 0)) }
                }
                MiniField {
                    visible: root.advancedOpen
                    title: "Largura"; suffix: "px"
                    value: Math.round(Number(root.selectedLayer ? root.selectedLayer.baseWidth : 0)).toString()
                    onAccepted: function(value) { root.editor.updateLayer(
                        root.editor.selectedLayerId, { baseWidth: root.numeric(value, 8) }) }
                }
                MiniField {
                    visible: root.advancedOpen
                    title: "Altura"; suffix: "px"
                    value: Math.round(Number(root.selectedLayer ? root.selectedLayer.baseHeight : 0)).toString()
                    onAccepted: function(value) { root.editor.updateLayer(
                        root.editor.selectedLayerId, { baseHeight: root.numeric(value, 8) }) }
                }
                MiniField {
                    visible: root.advancedOpen
                    title: "Escala"; suffix: "×"
                    value: Number(root.selectedTransform.scale || 1).toFixed(2)
                    onAccepted: function(value) { root.editor.setTransform(
                        root.editor.selectedLayerId, "scale",
                        Math.max(0.02, Math.min(32, root.numeric(value, 1)))) }
                }
                MiniField {
                    visible: root.advancedOpen
                    title: "Rotação"; suffix: "°"
                    value: Math.round(Number(root.selectedTransform.rotation || 0)).toString()
                    onAccepted: function(value) { root.editor.setTransform(
                        root.editor.selectedLayerId, "rotation", root.numeric(value, 0)) }
                }
                MiniField {
                    title: "Opacidade"; suffix: "%"
                    value: Math.round(Number(root.selectedTransform.opacity === undefined
                        ? 1 : root.selectedTransform.opacity) * 100).toString()
                    onAccepted: function(value) { root.editor.setTransform(
                        root.editor.selectedLayerId, "opacity",
                        Math.max(0, Math.min(1, root.numeric(value, 100) / 100))) }
                }

                MiniField {
                    visible: root.advancedOpen
                    title: "Tamanho fonte"; suffix: "×"
                    value: Number(root.selectedStyle.fontScale || 1).toFixed(2)
                    onAccepted: function(value) { root.editor.setItemStyle(
                        root.editor.selectedLayerId, "fontScale",
                        Math.max(0.25, Math.min(4, root.numeric(value, 1)))) }
                }
                MiniField {
                    visible: root.advancedOpen
                    title: "Cor do texto"; fieldWidth: 104
                    value: String(root.selectedStyle.textColor || "")
                    onAccepted: function(value) { root.editor.setItemStyle(
                        root.editor.selectedLayerId, "textColor", value) }
                }

                ToolButton {
                    visible: root.selectedLayer && root.selectedLayer.type === "photoGrid"
                    caption: "2×2"; onTriggered: root.editor.setItemStyle(
                        root.editor.selectedLayerId, "galleryLayout", "grid2")
                }
                ToolButton {
                    visible: root.selectedLayer && root.selectedLayer.type === "photoGrid"
                    caption: "3×3"; onTriggered: root.editor.setItemStyle(
                        root.editor.selectedLayerId, "galleryLayout", "grid3")
                }
                ToolButton {
                    visible: root.selectedLayer && root.selectedLayer.type === "photoGrid"
                    caption: "4×4"; onTriggered: root.editor.setItemStyle(
                        root.editor.selectedLayerId, "galleryLayout", "grid4")
                }
                ToolButton {
                    visible: root.selectedLayer && root.selectedLayer.type === "photoGrid"
                    caption: "Destaque"; onTriggered: root.editor.setItemStyle(
                        root.editor.selectedLayerId, "galleryLayout", "feature")
                }

                ToolButton {
                    caption: root.selectedLayer && root.selectedLayer.locked
                        ? "Desbloquear" : "Bloquear"
                    onTriggered: root.editor.updateLayer(root.editor.selectedLayerId,
                        { locked: !root.selectedLayer.locked })
                }
                ToolButton {
                    caption: "Duplicar"; enabled: root.selectedLayer && !root.selectedLayer.sharedWidget
                    onTriggered: root.editor.duplicateSelected()
                }
                ToolButton {
                    caption: "Para frente"; enabled: root.selectedLayer && !root.selectedLayer.sharedWidget
                    onTriggered: root.editor.moveSelected(1)
                }
                ToolButton {
                    caption: "Para trás"; enabled: root.selectedLayer && !root.selectedLayer.sharedWidget
                    onTriggered: root.editor.moveSelected(-1)
                }
                ConfirmationMorph {
                    theme: root.theme
                    motion: root.motion
                    onConfirmed: root.editor.removeSelected()
                }
            }
        }
    }

    Lock.GlassPanel {
        visible: root.editingMode && root.controller.closePrompt
        anchors.centerIn: parent
        width: 430
        height: 190
        z: 80
        radius: 26
        nativeOptics: false
        materialMode: "solid"
        solidColor: "#202634"
        materialOpacity: 0.98
        surfaceColor: root.theme.surfaceRaised
        borderColor: root.theme.borderStrong
        shadowColor: root.theme.shadow

        Column {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 12
            Text {
                text: "Salvar alterações?"
                color: root.theme.textPrimary
                font.family: root.theme.bodyFont
                font.pixelSize: 19
                font.weight: Font.DemiBold
            }
            Text {
                width: parent.width
                text: "A composição foi modificada neste modo de edição."
                color: root.theme.textSecondary
                font.family: root.theme.bodyFont
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }
            Row {
                spacing: 8
                ToolButton {
                    caption: "Salvar"
                    activeState: true
                    onTriggered: root.controller.resolveClose("save")
                }
                ToolButton {
                    caption: "Descartar"
                    onTriggered: root.controller.resolveClose("discard")
                }
                ToolButton {
                    caption: "Voltar"
                    onTriggered: root.controller.resolveClose("return")
                }
            }
        }
    }
}
