import QtQuick
import QtQuick.Controls
import "../../core" as Core
import "../../components" as Components
import "SettingsCatalog.js" as Catalog

Item {
    id: root
    required property var config
    required property var controller
    required property var editor
    required property var theme
    required property var profileService
    required property var wallpaperStore
    property var motion: defaultMotion
    Core.Motion { id: defaultMotion; config: root.config }
    property bool presented: true
    property bool nativeConnected: false
    property string page: controller.settingsPage || "wallpapers"
    property string section: "main"
    onSectionChanged: if (controller.settingsSection !== undefined) controller.settingsSection = section
    property string searchText: ""
    property bool moreOpen: false
    property var pendingResult: null
    property string searchNotice: ""
    property alias contentItem: contentLoader.item
    property var scrollPositions: ({})
    readonly property var navigation: Catalog.categories
    readonly property var searchResults: Catalog.search(searchText)
    readonly property bool compact: width < 700
    readonly property real preferredWidth: lifecycle.presentedPage === "wallpapers"
        ? (section === "selector" ? 760 : section === "effects" ? 840 : 1040)
        : lifecycle.presentedPage === "motion" ? 760
        : lifecycle.presentedPage === "bar" && section === "main" ? 920
        : lifecycle.presentedPage === "language" ? 840 : 1040
    readonly property real preferredHeight: controls.y + (searchText || moreOpen
        ? titleRow.y + titleRow.height + 16 + Math.min(350, Math.max(112, (searchText ? searchResults.length : navigation.length)*61))
        : viewport.y + (contentLoader.item ? contentLoader.item.implicitHeight : 240)) + 42
    readonly property real reveal: lifecycle.reveal
    readonly property bool animating: lifecycle.animating
    readonly property real join: surface.join
    readonly property color ink: theme.textPrimary
    readonly property color mutedInk: theme.textSecondary
    readonly property color accent: theme.accent
    readonly property bool liquidMaterial: config.barMaterial === "liquid" && !config.reduceTransparency
    readonly property bool blurMaterial: config.barMaterial !== "solid" && config.barBlurEnabled && !config.reduceTransparency
    readonly property color surfaceTint: config.reduceTransparency
        ? Qt.rgba(theme.barSurface.r, theme.barSurface.g, theme.barSurface.b, 1)
        : theme.barSurface
    readonly property var currentCategory: Catalog.category(page)
    property alias materialItem: materialBounds
    signal requestClose()
    signal finishedClosing()

    onPageChanged: { moreOpen = false; controller.setSettingsPage(page) }
    SettingsMotion {
        id: lifecycle
        motion: root.motion; presented: root.presented; desiredPage: root.page
        onClosed: root.finishedClosing()
        onPresentedPageChanged: {
            root.section = "main"
            if (root.pendingResult && root.pendingResult.page === presentedPage)
                root.section = root.pendingResult.section
            Qt.callLater(root.restorePosition)
        }
    }
    SettingsSurface {
        id: surface
        anchors.fill: parent
        visible: !root.nativeConnected
        tint: root.surfaceTint
        rim: "transparent"
    }
    Item {
        id: materialBounds
        x: surface.join; width: Math.max(0, parent.width-2*x); height: parent.height
        // Native plugin receives this bounded body. The concave joins are drawn
        // by the Shape above without adding another window or native surface.
    }
    function navigate(id) {
        const positions = Object.assign({}, scrollPositions)
        positions[page + "/" + section] = viewport.contentY
        scrollPositions = positions
        pendingResult = null; searchText = ""; search.text = ""
        controller.setSettingsPage(id)
    }
    function restorePosition() {
        if (pendingResult) { focusResult(); return }
        viewport.contentY = Math.max(0, Math.min(scrollPositions[lifecycle.presentedPage+"/"+section] || 0,
            viewport.contentHeight-viewport.height))
    }
    function findTarget(item, result) {
        if (!item || item.visible === false) return null
        if (item.objectName === result.target) return item
        const label = item.label !== undefined ? item.label : item.text
        if (result.label && label !== undefined
                && Catalog.normalize(label) === Catalog.normalize(result.label)) return item
        const children = item.children || []
        for (let i=0;i<children.length;i++) { const found=findTarget(children[i],result); if(found) return found }
        return null
    }
    function focusResult() {
        if (!pendingResult || lifecycle.presentedPage !== pendingResult.page || !contentLoader.item) return
        if (contentLoader.item.prepareResult(pendingResult)) { focusRetry.restart(); return }
        let target=findTarget(contentLoader.item,pendingResult)
        searchNotice = ""
        if (!target && pendingResult.fallbackLabel) {
            target=findTarget(contentLoader.item,{label:pendingResult.fallbackLabel})
            searchNotice=pendingResult.conditionHint || ""
        }
        if (!target) {
            searchNotice = "Esta opção depende do estado atual. Verifique os controles desta categoria."
            return
        }
        const point=target.mapToItem(contentLoader,0,0)
        viewport.contentY=Math.max(0,Math.min(point.y-24,viewport.contentHeight-viewport.height))
        target.forceActiveFocus(Qt.TabFocusReason)
        focusRing.targetItem=target
        focusTimeout.restart()
        pendingResult=null
    }
    function selectResult(result) {
        searchText=""; search.text=""; moreOpen=false
        pendingResult=result
        searchNotice=""
        controller.setSettingsPage(result.page)
        section=result.section
        if (result.action === "editor") { controller.beginEditing(result.page === "lock" ? "lock" : "desktop"); pendingResult=null }
        else if (result.action && contentLoader.item) { contentLoader.item.openTool(result.action); pendingResult=null }
        else Qt.callLater(focusResult)
    }
    // Bounded retry accommodates an asynchronous file/adapter load, not polling.
    Timer { id: focusRetry; interval: 40; repeat: false; onTriggered: root.focusResult() }
    Timer { id: focusTimeout; interval: 1800; onTriggered: focusRing.targetItem=null }
    Keys.onEscapePressed: event => {
        if (root.searchText) { search.text=""; root.searchText="" }
        else if (root.moreOpen) root.moreOpen=false
        else root.requestClose()
        event.accepted=true
    }
    Keys.onPressed: event => {
        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_F) {
            search.forceActiveFocus(); event.accepted=true
        }
    }

    component NavButton: Rectangle {
        id: nav
        property string label: ""
        property string icon: ""
        property bool selected: false
        signal triggered()
        height: 48; radius: 12
        activeFocusOnTab: enabled
        Accessible.role: Accessible.Button; Accessible.name: label
        color: selected ? Qt.rgba(root.accent.r,root.accent.g,root.accent.b,.25)
            : hover.hovered ? Qt.rgba(root.ink.r,root.ink.g,root.ink.b,.065) : "transparent"
        border.width: selected || activeFocus ? 1 : 0
        border.color: Qt.rgba(root.accent.r,root.accent.g,root.accent.b,.55)
        Behavior on color { ColorAnimation { duration: root.motion.surfaceHover } }
        Row { anchors.centerIn: parent; spacing: 10
            Components.VeloraMaterialIcon { width: 21; height: 21; iconName: nav.icon; iconColor: root.ink; visible: nav.icon.length > 0 }
            Text { text: nav.label; color: root.ink; font.family: root.theme.bodyFont; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
        }
        HoverHandler { id: hover }
        TapHandler { onTapped: nav.triggered() }
        Keys.onReturnPressed: triggered()
        Keys.onSpacePressed: triggered()
    }
    Item {
        id: controls
        // Layout padding is independent of animated height; using the clipped
        // surface join here would make content height feed back into its width.
        x: Math.min(42,root.width*.04)+16; width: Math.max(0,root.width-2*x)
        height: root.height-14; y: 12
        opacity: lifecycle.chromeReveal
        enabled: lifecycle.interactive
        clip: true
        Row {
            id: tabs
            width: parent.width; height: 50; spacing: 6
            Repeater {
                model: root.compact ? [root.currentCategory] : root.navigation.slice(0,4)
                NavButton {
                    required property var modelData
                    width: root.compact ? Math.max(100,tabs.width-136) : (tabs.width-112-24)/4
                    label: root.compact ? modelData.name : (modelData.id === "motion" ? "Movimento" : modelData.id === "desktop" ? "Widgets" : modelData.name)
                    icon: modelData.icon; selected: root.page === modelData.id
                    onTriggered: root.compact ? root.moreOpen=!root.moreOpen : root.navigate(modelData.id)
                }
            }
            NavButton { width: 70; label: "Mais"; icon: ""; selected: root.moreOpen || (!root.compact && !["wallpapers","bar","motion","desktop"].includes(root.page)); onTriggered: root.moreOpen=!root.moreOpen }
            NavButton { width: 36; label: "×"; onTriggered: root.requestClose() }
        }
        Rectangle { y: tabs.height+8; width: parent.width; height: 1; color: root.theme.borderSubtle }
        Item {
            id: titleRow
            y: tabs.height+22; width: parent.width; height: root.compact ? 72 : 44
            Text { text: root.currentCategory.name; color: root.ink; font.family: root.theme.bodyFont; font.pixelSize: 18; font.weight: Font.Medium
                width: root.compact ? parent.width : parent.width*.53; elide: Text.ElideRight }
            Text { y: 25; width: parent.width*.53; visible: !root.compact; text: root.currentCategory.detail; color: root.mutedInk; font.family: root.theme.bodyFont; font.pixelSize: 10; elide: Text.ElideRight }
            TextField {
                id: search
                objectName: "settingsSearch"
                x: root.compact ? 0 : parent.width*.56; y: root.compact ? 32 : 0
                width: root.compact ? parent.width : parent.width-x; height: 36
                color: root.ink; font.family: root.theme.bodyFont; font.pixelSize: 12
                placeholderText: "Buscar configuração…"; placeholderTextColor: root.mutedInk
                onTextChanged: root.searchText=text
                onAccepted: if (root.searchResults.length) root.selectResult(root.searchResults[0])
                background: Rectangle { radius: 10; color: Qt.rgba(0,0,0,.12); border.color: search.activeFocus ? root.accent : root.theme.borderSubtle }
            }
        }
        Components.VeloraSettingsTabs {
            id: subsections
            theme: root.theme; motion: root.motion; tabWidth: root.page === "bar" ? 145 : 115
            y: titleRow.y+titleRow.height+8; width: Math.min(parent.width, implicitWidth)
            visible: root.page === "bar" || root.page === "media" || root.page === "wallpapers"
            options: root.page === "bar" ? [{id:"main",label:"Material e avatar"},{id:"layout",label:"Organização"},{id:"sidebar",label:"Lateral e menus"}]
                : root.page === "media" ? [{id:"playback",label:"Lyrics"},{id:"position",label:"Posição"},{id:"style",label:"Texto e cor"},{id:"material",label:"Efeitos"},{id:"velyrics",label:"Velyrics"}]
                : root.page === "wallpapers" ? [{id:"main",label:"Biblioteca"},{id:"effects",label:"Efeitos"},{id:"transitions",label:"Transições"},{id:"selector",label:"Seletor"}] : []
            selected: root.page === "media" && root.section === "main" ? "playback" : root.section
            onChosen: id => { root.section=id; viewport.contentY=0 }
        }
        Flickable {
            id: viewport
            objectName: "settingsViewport"
            y: subsections.visible ? subsections.y+subsections.height+12 : titleRow.y+titleRow.height+16
            width: parent.width; height: Math.max(0,parent.height-y-26)
            contentWidth: Math.max(width,480)
            contentHeight: contentLoader.height
            clip: true; boundsBehavior: Flickable.StopAtBounds
            visible: !root.searchText && !root.moreOpen
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }
            Loader {
                id: contentLoader
                width: viewport.contentWidth
                opacity: lifecycle.contentReveal
                y: (1-lifecycle.contentReveal)*8
                active: lifecycle.reveal > 0 && root.visible
                sourceComponent: SettingsContent {
                    config: root.config; controller: root.controller; editor: root.editor
                    theme: root.theme; motion: root.motion; profileService: root.profileService
                    wallpaperStore: root.wallpaperStore; page: lifecycle.presentedPage
                    section: root.section; mediaSection: root.section === "main" ? "playback" : root.section
                    onRevealSetting: id => {
                        const result = Catalog.entries.find(entry => entry.id === id)
                        if (result) root.selectResult(result)
                    }
                    onImplicitHeightChanged: if (root.pendingResult) focusRetry.restart()
                }
                onLoaded: { root.restorePosition(); if (root.pendingResult) focusRetry.restart() }
            }
            Rectangle {
                id: focusRing
                property var targetItem: null
                visible: !!targetItem
                x: targetItem ? targetItem.mapToItem(contentLoader,0,0).x-3 : 0
                y: targetItem ? targetItem.mapToItem(contentLoader,0,0).y-3 : 0
                width: targetItem ? targetItem.width+6 : 0; height: targetItem ? targetItem.height+6 : 0
                color: "transparent"; border.color: root.accent; border.width: 1; radius: 10
            }
        }
        ListView {
            id: results
            x: 0; y: titleRow.y+titleRow.height+16; width: parent.width; height: Math.max(0,parent.height-y-26)
            visible: !!root.searchText || root.moreOpen
            clip: true; spacing: 5
            model: root.searchText ? root.searchResults : root.navigation
            delegate: Rectangle {
                required property var modelData
                width: results.width; height: 56; radius: 10
                color: resultHover.hovered ? Qt.rgba(root.accent.r,root.accent.g,root.accent.b,.17) : Qt.rgba(1,1,1,.035)
                activeFocusOnTab: true
                function activate() { root.searchText ? root.selectResult(modelData) : root.navigate(modelData.id) }
                Accessible.role: Accessible.Button; Accessible.name: modelData.name
                Text { x: 14; y: 9; width: parent.width-28; text: modelData.name; color: root.ink; font.pixelSize: 12; elide: Text.ElideRight; font.family: root.theme.bodyFont }
                Text { x: 14; y: 31; width: parent.width-28; text: root.searchText ? Catalog.category(modelData.page).name : modelData.detail; color: root.mutedInk; font.pixelSize: 10; elide: Text.ElideRight; font.family: root.theme.bodyFont }
                HoverHandler { id: resultHover }
                TapHandler { onTapped: parent.activate() }
                Keys.onReturnPressed: activate()
                Keys.onSpacePressed: activate()
            }
            Text { anchors.centerIn: parent; visible: root.searchText && results.count === 0; text: "Nenhuma configuração encontrada"; color: root.mutedInk; font.pixelSize: 12 }
        }
        Text {
            anchors.left: parent.left; anchors.bottom: parent.bottom; width: parent.width
            text: root.config.saveError || root.controller.integrationError || root.searchNotice
                || (root.config.savePending || (root.controller.integrations && root.controller.integrations.busy) ? "Salvando…" : "Salvamento automático")
            color: root.config.saveError || root.controller.integrationError ? root.theme.danger : root.mutedInk
            font.family: root.theme.bodyFont; font.pixelSize: 10; elide: Text.ElideRight
        }
    }
}
