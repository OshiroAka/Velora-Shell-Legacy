import QtQuick
import "../platform" as Platform
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../features/lock" as Lock
import "../features/widgets" as Widgets

Variants {
    id: root

    required property var compositor
    required property var preview
    required property var settings
    required property var config
    required property var theme
    required property var motion
    required property var clock
    required property var calendarService
    required property var media
    required property var weather
    required property var visualizer
    required property var status
    required property var transition
    required property var editor
    required property var profileService
    required property var causticsClock
    required property int opticsGeneration
    property bool barOnRight: false
    property bool nativeBarMaterial: false
    property int visualizerRailInset: 0
    property int visualizerCornerRadius: 0
    property int visualizerBottomInset: 0

    model: compositor.focusedScreen ? [compositor.focusedScreen] : []

    PanelWindow {
        id: widgetWindow
        required property var modelData
        property bool nativeShapeDirty: true
        property int nativeShapeRetries: 0

        screen: modelData
        color: "transparent"
        implicitWidth: modelData.width
        implicitHeight: modelData.height
        exclusionMode: ExclusionMode.Ignore
        focusable: false

        anchors { top: true; bottom: true; left: true; right: true }

        WlrLayershell.layer: root.settings.shown
            && root.settings.mode === "editing" ? WlrLayer.Top
            : (root.preview.occluding ? WlrLayer.Overlay : WlrLayer.Bottom)
        WlrLayershell.namespace: "velora-shell-shared-widgets"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        function nativeShape(item, radius) {
            if (!item || width <= 0 || height <= 0 || !item.visible
                    || item.opacity <= 0.001
                    || String(item.currentMaterial || "liquid") !== "liquid")
                return "0 0 0 0 0 0 0 0"
            const center = item.mapToItem(
                sharedScene, item.width * 0.5, item.height * 0.5)
            const right = item.mapToItem(
                sharedScene, item.width, item.height * 0.5)
            const bottom = item.mapToItem(
                sharedScene, item.width * 0.5, item.height)
            const widthVectorX = right.x - center.x
            const widthVectorY = right.y - center.y
            const heightVectorX = bottom.x - center.x
            const heightVectorY = bottom.y - center.y
            const mappedWidth = Math.max(0.01,
                Math.sqrt(widthVectorX * widthVectorX
                          + widthVectorY * widthVectorY) * 2)
            const mappedHeight = Math.max(0.01,
                Math.sqrt(heightVectorX * heightVectorX
                          + heightVectorY * heightVectorY) * 2)
            const rotation = Math.atan2(widthVectorY, widthVectorX)
                * 180 / Math.PI
            const radiusPixels = Number(radius)
                * mappedWidth / Math.max(1, item.width)
            return "1 "
                + ((center.x - mappedWidth * 0.5) / width).toFixed(6) + " "
                + ((center.y - mappedHeight * 0.5) / height).toFixed(6) + " "
                + (mappedWidth / width).toFixed(6) + " "
                + (mappedHeight / height).toFixed(6) + " "
                + (radiusPixels / width).toFixed(6) + " "
                + rotation.toFixed(4) + " "
                + Math.max(0, Math.min(1, item.opacity)).toFixed(4)
        }

        function queueNativeShapes() { nativeShapeDirty = true }

        function scheduleNativeShapeResync() {
            nativeShapeRetries = 4
            queueNativeShapes()
            nativeShapeRetry.restart()
        }

        function syncNativeShapes() {
            if (width <= 0 || height <= 0)
                return
            const shapes = [
                nativeShape(sharedScene.clockHitItem, 27),
                nativeShape(sharedScene.calendarHitItem, 28),
                nativeShape(sharedScene.weatherHitItem, 28),
                nativeShape(sharedScene.mediaHitItem, 28),
                nativeShape(sharedScene.galleryHitItem, 28),
                nativeShape(sharedScene.systemHitItem, 28)
            ]
            const caustics = root.preview.shown
                && root.config.waterCausticsEnabled
                && root.config.waterCausticsLines
                && root.config.waterCausticsModules
            Platform.NativeBlur.dispatch("velora-blur:shared-widgets-shape 1 "
                + (caustics ? "1 " : "0 ") + shapes.join(" "))
        }

        onWidthChanged: queueNativeShapes()
        onHeightChanged: queueNativeShapes()
        property int appliedOpticsGeneration: root.opticsGeneration
        onAppliedOpticsGenerationChanged: scheduleNativeShapeResync()

        Timer {
            id: nativeShapeRetry
            interval: 120
            repeat: true
            onTriggered: {
                widgetWindow.queueNativeShapes()
                widgetWindow.nativeShapeRetries -= 1
                if (widgetWindow.nativeShapeRetries <= 0)
                    stop()
            }
        }

        FrameAnimation {
            running: widgetWindow.nativeShapeDirty
            onTriggered: {
                widgetWindow.syncNativeShapes()
                widgetWindow.nativeShapeDirty = false
            }
        }

        Component.onCompleted: scheduleNativeShapeResync()
        Component.onDestruction:
            Platform.NativeBlur.dispatch("velora-blur:shared-widgets-shape 0")

        Region {
            id: individualBlurRegion
            Region { item: sharedScene.translucentWidget(sharedScene.clockHitItem) ? sharedScene.clockHitItem : null; radius: Math.round(27 * sharedScene.clockHitItem.scale); intersection: Intersection.Combine }
            Region { item: sharedScene.translucentWidget(sharedScene.calendarHitItem) ? sharedScene.calendarHitItem : null; radius: Math.round(28 * sharedScene.calendarHitItem.scale); intersection: Intersection.Combine }
            Region { item: sharedScene.translucentWidget(sharedScene.weatherHitItem) ? sharedScene.weatherHitItem : null; radius: Math.round(28 * sharedScene.weatherHitItem.scale); intersection: Intersection.Combine }
            Region { item: sharedScene.translucentWidget(sharedScene.mediaHitItem) ? sharedScene.mediaHitItem : null; radius: Math.round(28 * sharedScene.mediaHitItem.scale); intersection: Intersection.Combine }
            Region { item: sharedScene.translucentWidget(sharedScene.galleryHitItem) ? sharedScene.galleryHitItem : null; radius: Math.round(28 * sharedScene.galleryHitItem.scale); intersection: Intersection.Combine }
            Region { item: sharedScene.translucentWidget(sharedScene.systemHitItem) ? sharedScene.systemHitItem : null; radius: Math.round(28 * sharedScene.systemHitItem.scale); intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 0 ? sharedScene.dynamicBlurItem(0) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 1 ? sharedScene.dynamicBlurItem(1) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 2 ? sharedScene.dynamicBlurItem(2) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 3 ? sharedScene.dynamicBlurItem(3) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 4 ? sharedScene.dynamicBlurItem(4) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 5 ? sharedScene.dynamicBlurItem(5) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 6 ? sharedScene.dynamicBlurItem(6) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 7 ? sharedScene.dynamicBlurItem(7) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 8 ? sharedScene.dynamicBlurItem(8) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 9 ? sharedScene.dynamicBlurItem(9) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 10 ? sharedScene.dynamicBlurItem(10) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 11 ? sharedScene.dynamicBlurItem(11) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 12 ? sharedScene.dynamicBlurItem(12) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 13 ? sharedScene.dynamicBlurItem(13) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 14 ? sharedScene.dynamicBlurItem(14) : null; radius: 28; intersection: Intersection.Combine }
            Region { item: root.config.sceneLayers.length > 15 ? sharedScene.dynamicBlurItem(15) : null; radius: 28; intersection: Intersection.Combine }
        }
        BackgroundEffect.blurRegion: root.config.widgetBlurEnabled ? individualBlurRegion : noWidgetBlur
        Region { id: noWidgetBlur }

        mask: Region {
            Region { item: sharedScene.clockHitItem; intersection: Intersection.Combine }
            Region { item: sharedScene.calendarHitItem; intersection: Intersection.Combine }
            Region { item: sharedScene.weatherHitItem; intersection: Intersection.Combine }
            Region { item: sharedScene.mediaHitItem; intersection: Intersection.Combine }
            Region { item: sharedScene.galleryHitItem; intersection: Intersection.Combine }
            Region { item: sharedScene.systemHitItem; intersection: Intersection.Combine }
        }

        // A covered pixel keeps the desktop material host mapped even when
        // all widgets are hidden. It is underneath the fixed sidebar/frame.
        Rectangle {
            x: root.barOnRight ? parent.width - 2 : 1
            y: parent.height - 2
            width: 1; height: 1
            color: "#01000000"
            visible: root.nativeBarMaterial
        }

        Lock.AudioVisualizer {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 180
            theme: root.theme
            visualizer: root.visualizer
            darkPalette: true
            clipSideInset: root.visualizerRailInset
            clipCornerRadius: 0
            clipBottomInset: 0
            clipSideOnRight: root.barOnRight
            visible: !root.nativeBarMaterial
                && root.config.desktopVisualizerEnabled && root.visualizer.running && !root.preview.shown
                && !(root.settings.shown && root.settings.mode === "editing")
            opacity: 0.78
        }

        Widgets.SharedWidgetsScene {
            id: sharedScene
            barOnRight: root.barOnRight
            anchors.fill: parent
            config: root.config
            theme: root.theme
            motion: root.motion
            clock: root.clock
            calendarService: root.calendarService
            media: root.media
            weather: root.weather
            status: root.status
            transition: root.transition
            editor: root.editor
            profileService: root.profileService
            causticsClock: root.causticsClock
            lockPresented: root.preview.shown
            editing: root.settings.shown
                && root.settings.mode === "editing"
        }

        component ShapeConnections: Connections {
            required property Item watchedItem
            target: watchedItem
            function onXChanged() { widgetWindow.queueNativeShapes() }
            function onYChanged() { widgetWindow.queueNativeShapes() }
            function onWidthChanged() { widgetWindow.queueNativeShapes() }
            function onHeightChanged() { widgetWindow.queueNativeShapes() }
            function onScaleChanged() { widgetWindow.queueNativeShapes() }
            function onRotationChanged() { widgetWindow.queueNativeShapes() }
            function onOpacityChanged() { widgetWindow.queueNativeShapes() }
            function onVisibleChanged() { widgetWindow.queueNativeShapes() }
        }

        ShapeConnections { watchedItem: sharedScene.clockHitItem }
        ShapeConnections { watchedItem: sharedScene.calendarHitItem }
        ShapeConnections { watchedItem: sharedScene.weatherHitItem }
        ShapeConnections { watchedItem: sharedScene.mediaHitItem }
        ShapeConnections { watchedItem: sharedScene.galleryHitItem }
        ShapeConnections { watchedItem: sharedScene.systemHitItem }

        Connections {
            target: root.preview
            function onShownChanged() { widgetWindow.queueNativeShapes() }
        }

        Connections {
            target: root.config
            function onConfigurationChanged() { widgetWindow.queueNativeShapes() }
        }
    }
}
