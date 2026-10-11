import QtQuick
import "../platform" as Platform
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../features/settings" as Settings
import "../features/editor" as Editor

Variants {
    id: root

    required property var controller
    required property var compositor
    required property var config
    required property var theme
    required property var motion
    required property var profileService
    required property var wallpaperStore
    required property var editor
    required property int opticsGeneration

    model: controller.mounted && !controller.picking && compositor.focusedScreen
        ? [compositor.focusedScreen] : []

    PanelWindow {
        id: editorWindow
        required property var modelData
        readonly property bool editingDesktop: root.controller.mode === "editing" && root.controller.editSpace === "desktop"

        screen: modelData
        color: "transparent"
        implicitWidth: modelData.width
        implicitHeight: modelData.height
        exclusionMode: ExclusionMode.Ignore

        anchors { top: true; bottom: true; left: true; right: true }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "velora-shell-editor"
        WlrLayershell.keyboardFocus: root.controller.shown
            ? (editingDesktop ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive) : WlrKeyboardFocus.None

        BackgroundEffect.blurRegion: Region {
            Region { item: !Platform.NativeBlur.supports("editor-shape") && chrome.toolBarItem.visible ? chrome.toolBarItem : null; radius: 25 }
            Region { item: !Platform.NativeBlur.supports("editor-shape") && chrome.layersItem.visible ? chrome.layersItem : null; radius: 26; intersection: Intersection.Combine }
            Region { item: !Platform.NativeBlur.supports("editor-shape") && chrome.inspectorItem.visible ? chrome.inspectorItem : null; radius: 28; intersection: Intersection.Combine }
            Region { item: !Platform.NativeBlur.supports("editor-shape") && chrome.catalogItem.visible ? chrome.catalogItem : null; radius: 28; intersection: Intersection.Combine }
            Region { item: !Platform.NativeBlur.supports("editor-shape") && chrome.profilesItem.visible ? chrome.profilesItem : null; radius: 28; intersection: Intersection.Combine }
            Region { item: !Platform.NativeBlur.supports("editor-shape") && chrome.barItem.visible ? chrome.barItem : null; radius: 28; intersection: Intersection.Combine }
        }

        Item { id: topbarInputGap; width: editorWindow.width; height: 40 }
        mask: Region {
            item: inputScope
            Region {
                item: editorWindow.editingDesktop && root.config.topbarEnabled ? topbarInputGap : null
                intersection: Intersection.Subtract
            }
        }
        property bool shapeDirty: true
        property int appliedOpticsGeneration: root.opticsGeneration
        onAppliedOpticsGenerationChanged: queueShape()

        function queueShape() { shapeDirty = true }

        function shapeFields(item) {
            const topLeft = item.mapToItem(inputScope, 0, 0)
            const radius = Math.min(28, item.width * 0.5, item.height * 0.5)
            return [topLeft.x / width, topLeft.y / height,
                    item.width / width, item.height / height,
                    radius / width].map(function(value) {
                return Number(value).toFixed(6)
            }).join(" ")
        }

        function syncShape() {
            if (width <= 0 || height <= 0)
                return
            const candidates = [chrome.toolBarItem, chrome.layersItem,
                chrome.inspectorItem, chrome.catalogItem,
                chrome.profilesItem, chrome.barItem, chrome.settingsItem]
            const shapes = []
            for (let index = 0; index < candidates.length; index += 1) {
                const item = candidates[index]
                if (item && item.visible && item.width > 1 && item.height > 1)
                    shapes.push(shapeFields(item))
            }
            Platform.NativeBlur.dispatch("velora-blur:editor-shape " + shapes.length
                + (shapes.length ? " " + shapes.join(" ") : ""))
        }

        FrameAnimation {
            running: editorWindow.shapeDirty
            onTriggered: {
                editorWindow.syncShape()
                editorWindow.shapeDirty = false
            }
        }

        FocusScope {
            id: inputScope
            anchors.fill: parent
            focus: root.controller.shown

            Keys.onEscapePressed: {
                if (root.editor.toolMode === "crop")
                    root.editor.setToolMode("select")
                else if (root.editor.selectedLayerId.length > 0)
                    root.editor.clearSelection()
                else
                    root.controller.hide()
            }

            Keys.onPressed: function(event) {
                if (!(event.modifiers & Qt.ControlModifier))
                    return
                if (event.key === Qt.Key_Z
                        && (event.modifiers & Qt.ShiftModifier)) {
                    root.editor.redo()
                    event.accepted = true
                } else if (event.key === Qt.Key_Z) {
                    root.editor.undo()
                    event.accepted = true
                } else if (event.key === Qt.Key_Y) {
                    root.editor.redo()
                    event.accepted = true
                } else if (event.key === Qt.Key_D) {
                    root.editor.duplicateSelected()
                    event.accepted = true
                }
            }

            Settings.SceneEditorOverlay {
                barOnRight: root.controller.shell ? root.controller.shell.barOnRight : false
                anchors.fill: parent
                z: 1
                active: root.controller.shown
                    && root.controller.mode === "editing"
                config: root.config
                editor: root.editor
                theme: root.theme
                motion: root.motion
            }

            Editor.EditorChrome {
                id: chrome
                anchors.fill: parent
                z: 2
                presented: root.controller.shown
                controller: root.controller
                config: root.config
                theme: root.theme
                motion: root.motion
                profileService: root.profileService
                wallpaperStore: root.wallpaperStore
                editor: root.editor
            }

            function claimFocus() {
                if (root.controller.shown)
                    forceActiveFocus(Qt.ShortcutFocusReason)
            }

            Component.onCompleted: Qt.callLater(claimFocus)

            Connections {
                target: root.controller
                function onSerialChanged() { editorWindow.queueShape() }
                function onOpened() {
                    editorWindow.queueShape()
                    Qt.callLater(inputScope.claimFocus)
                }
                function onClosed() { editorWindow.queueShape() }
            }

            Connections {
                target: root.editor
                function onSelectionChanged() { editorWindow.queueShape() }
            }

            Connections {
                target: chrome.toolBarItem
                function onXChanged() { editorWindow.queueShape() }
                function onYChanged() { editorWindow.queueShape() }
                function onWidthChanged() { editorWindow.queueShape() }
                function onHeightChanged() { editorWindow.queueShape() }
                function onVisibleChanged() { editorWindow.queueShape() }
            }
            Connections {
                target: chrome.layersItem
                function onXChanged() { editorWindow.queueShape() }
                function onYChanged() { editorWindow.queueShape() }
                function onWidthChanged() { editorWindow.queueShape() }
                function onHeightChanged() { editorWindow.queueShape() }
                function onVisibleChanged() { editorWindow.queueShape() }
            }
            Connections {
                target: chrome.inspectorItem
                function onXChanged() { editorWindow.queueShape() }
                function onYChanged() { editorWindow.queueShape() }
                function onWidthChanged() { editorWindow.queueShape() }
                function onHeightChanged() { editorWindow.queueShape() }
                function onVisibleChanged() { editorWindow.queueShape() }
            }
            Connections {
                target: chrome.catalogItem
                function onXChanged() { editorWindow.queueShape() }
                function onYChanged() { editorWindow.queueShape() }
                function onWidthChanged() { editorWindow.queueShape() }
                function onHeightChanged() { editorWindow.queueShape() }
                function onVisibleChanged() { editorWindow.queueShape() }
            }
            Connections {
                target: chrome.profilesItem
                function onXChanged() { editorWindow.queueShape() }
                function onYChanged() { editorWindow.queueShape() }
                function onWidthChanged() { editorWindow.queueShape() }
                function onHeightChanged() { editorWindow.queueShape() }
                function onVisibleChanged() { editorWindow.queueShape() }
            }
            Connections {
                target: chrome.barItem
                function onXChanged() { editorWindow.queueShape() }
                function onYChanged() { editorWindow.queueShape() }
                function onWidthChanged() { editorWindow.queueShape() }
                function onHeightChanged() { editorWindow.queueShape() }
                function onVisibleChanged() { editorWindow.queueShape() }
            }
        }

        Component.onCompleted: queueShape()
        Component.onDestruction:
            Platform.NativeBlur.dispatch("velora-blur:editor-shape 0")
    }
}
