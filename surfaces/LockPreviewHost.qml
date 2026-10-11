import QtQuick
import "../platform" as Platform
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../features/lock" as Lock

Variants {
    id: root

    required property var controller
    required property var compositor
    required property var config
    required property var theme
    required property var motion
    required property var clock
    required property var calendarService
    required property var media
    required property var weather
    required property var visualizer
    required property var profileService
    required property var editor
    required property var transition
    required property var causticsClock
    required property int opticsGeneration
    property bool settingsVisible: false

    model: controller.mounted && compositor.focusedScreen
        ? [compositor.focusedScreen] : []

    Scope {
        id: surfacePair

        required property var modelData

        Connections {
            target: root.controller
            function onShownChanged() {
                Platform.NativeBlur.dispatch("velora-blur:transition "
                    + (root.controller.shown ? "open " + root.motion.widgetOpen
                       : "close " + root.motion.widgetExit))
            }
        }

        Connections {
            target: root
            function onOpticsGenerationChanged() {
                Platform.NativeBlur.dispatch("velora-blur:transition "
                    + (root.controller.shown
                       ? "open " + root.motion.widgetOpen : "reset"))
                lockScene.queueProfileDialOptics()
                lockScene.syncWaterCaustics()
            }
        }

        PanelWindow {
            id: desktopBlurSurface

            readonly property real designScale: Math.min(width / 1600, height / 900)
            readonly property real designOriginX: (width - 1600 * designScale) / 2
            readonly property real designOriginY: (height - 900 * designScale) / 2

            screen: surfacePair.modelData
            color: "transparent"
            implicitWidth: surfacePair.modelData.width
            implicitHeight: surfacePair.modelData.height
            exclusionMode: ExclusionMode.Ignore
            focusable: false

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: root.compositor.surfaceNamespace + "-desktop"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            mask: Region {}

            Item {
                id: desktopDialOpticalRegion
                x: Math.round(desktopBlurSurface.designOriginX
                              + (lockScene.profileDialCenterX
                                 - lockScene.profileDialDepth)
                                * desktopBlurSurface.designScale)
                y: Math.round(desktopBlurSurface.designOriginY
                              + (lockScene.profileDialCenterY
                                 - lockScene.profileDialHalfHeight)
                                * desktopBlurSurface.designScale)
                width: lockScene.profileDialVisible
                    ? Math.round(lockScene.profileDialDepth * 2
                                 * desktopBlurSurface.designScale) : 0
                height: lockScene.profileDialVisible
                    ? Math.round(lockScene.profileDialHalfHeight * 2
                                 * desktopBlurSurface.designScale) : 0
                opacity: 0
            }

            BackgroundEffect.blurRegion: Region {
                item: !Platform.NativeBlur.supports("transition") ? desktopDialOpticalRegion : null
                radius: Math.round(lockScene.profileDialHalfHeight * desktopBlurSurface.designScale)
            }
        }

        PanelWindow {
            id: panelSurface

            readonly property real designScale: Math.min(width / 1600, height / 900)
            readonly property real designOriginX: (width - 1600 * designScale) / 2
            readonly property real designOriginY: (height - 900 * designScale) / 2

            screen: surfacePair.modelData
            color: "transparent"
            implicitWidth: surfacePair.modelData.width
            implicitHeight: surfacePair.modelData.height
            exclusionMode: ExclusionMode.Ignore
            focusable: root.controller.shown

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: root.compositor.surfaceNamespace + "-panel"
            WlrLayershell.keyboardFocus: root.controller.shown
                ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            Item {
                id: panelDialOpticalRegion
                x: Math.round(panelSurface.designOriginX
                              + (lockScene.profileDialCenterX
                                 - lockScene.profileDialDepth)
                                * panelSurface.designScale)
                y: Math.round(panelSurface.designOriginY
                              + (lockScene.profileDialCenterY
                                 - lockScene.profileDialHalfHeight)
                                * panelSurface.designScale)
                width: lockScene.profileDialVisible
                    ? Math.round(lockScene.profileDialDepth * 2
                                 * panelSurface.designScale) : 0
                height: lockScene.profileDialVisible
                    ? Math.round(lockScene.profileDialHalfHeight * 2
                                 * panelSurface.designScale) : 0
                opacity: 0
            }

            Item {
                id: panelOpticalRegion
                x: panelSurface.designOriginX + lockScene.mainPanelX * panelSurface.designScale
                y: panelSurface.designOriginY + (103 + (1 - lockScene.opticsReveal) * 50) * panelSurface.designScale
                width: 1277 * panelSurface.designScale
                height: 610 * panelSurface.designScale
                visible: root.controller.mounted && !root.theme.editorial
                opacity: 0
            }
            BackgroundEffect.blurRegion: Region {
                item: !Platform.NativeBlur.supports("transition") ? panelOpticalRegion : null
                radius: Math.round(root.theme.panelRadius * panelSurface.designScale)
                Region {
                    item: !Platform.NativeBlur.supports("dial") ? panelDialOpticalRegion : null
                    radius: Math.round(lockScene.profileDialHalfHeight * panelSurface.designScale)
                    intersection: Intersection.Combine
                }
            }

            Item {
                id: panelInputRegion
                width: root.controller.occluding ? panelSurface.width : 0
                height: root.controller.occluding ? panelSurface.height : 0
                opacity: 0
            }

            // A warmed lock must not leave an invisible full-screen input
            // surface on the desktop.
            mask: Region { item: panelInputRegion }

            FocusScope {
                id: inputScope
                anchors.fill: parent
                focus: root.controller.shown

            Keys.onEscapePressed: {
                if (!lockScene.cancelProfileGesture())
                    root.controller.hide()
            }

                Lock.LockScene {
                    id: lockScene
                    anchors.fill: parent
                    presented: root.controller.shown
                    config: root.config
                    theme: root.theme
                    motion: root.motion
                    clock: root.clock
                    calendarService: root.calendarService
                    media: root.media
                    weather: root.weather
                    visualizer: root.visualizer
                    profileService: root.profileService
                    editor: root.editor
                    transition: root.transition
                    causticsClock: root.causticsClock
                    onCloseRequested: root.controller.hide()
                }

                function claimFocus() {
                    if (!root.controller.shown)
                        return
                    forceActiveFocus(Qt.ShortcutFocusReason)
                }

                Component.onCompleted: Qt.callLater(claimFocus)

                Connections {
                    target: root.controller
                    function onOpened() { Qt.callLater(inputScope.claimFocus) }
                }
            }
        }
    }
}
