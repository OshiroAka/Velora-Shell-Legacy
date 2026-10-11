import QtQuick
import "../../platform" as Platform
import QtQuick.Effects
import Quickshell.Hyprland

Item {
    id: root

    FontLoader {
        id: orbitronVariable
        source: "../../assets/fonts/Orbitron-Variable.ttf"
    }

    FontLoader {
        source: "../../assets/fonts/Poppins-Regular.ttf"
    }

    FontLoader {
        source: "../../assets/fonts/Poppins-SemiBold.ttf"
    }

    required property bool presented
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

    signal closeRequested

    property bool profileDialOpticsDirty: true
    readonly property real waterCausticsPhase: causticsClock.phase
    readonly property bool waterCausticsVisible: presented
        && config.waterCausticsEnabled && config.waterCausticsIntensity > 0.001
    readonly property bool waterCausticsAnimating: waterCausticsVisible
        && !motion.reduced

    ListModel { id: retainedLayerModel }

    function layerForId(values, identifier) {
        const layers = Array.isArray(values) ? values : []
        for (let index = 0; index < layers.length; index += 1) {
            if (String(layers[index].id) === String(identifier))
                return layers[index]
        }
        return null
    }

    // ListModel appends preserve existing delegates. Replacing a JavaScript
    // array in a Repeater destroyed every image component during a profile
    // switch, which made an actual crossfade impossible.
    function syncRetainedLayers() {
        const known = ({})
        for (let index = 0; index < retainedLayerModel.count; index += 1)
            known[String(retainedLayerModel.get(index).layerId)] = index
        const layers = Array.isArray(config.sceneLayers) ? config.sceneLayers : []
        for (let layerIndex = 0; layerIndex < layers.length; layerIndex += 1) {
            const identifier = String(layers[layerIndex].id || "")
            if (!identifier)
                continue
            const type = String(layers[layerIndex].type || "image")
            if (known[identifier] === undefined) {
                retainedLayerModel.append({ layerId: identifier, layerType: type })
                known[identifier] = retainedLayerModel.count - 1
            } else if (retainedLayerModel.get(known[identifier]).layerType !== type) {
                retainedLayerModel.setProperty(known[identifier], "layerType", type)
            }
        }
    }

    function cancelProfileGesture() {
        return profileDial.cancelGesture()
    }

    function syncWaterCaustics() {
        const enabled = waterCausticsVisible ? 1 : 0
        Platform.NativeBlur.dispatch("velora-blur:caustics state " + enabled + " "
            + Math.max(0, Math.min(1,
                config.waterCausticsIntensity)).toFixed(4) + " "
            + (config.waterCausticsLines ? "1" : "0") + " "
            + waterCausticsPhase.toFixed(5) + " "
            + (waterCausticsAnimating ? "1" : "0"))
    }

    function resetWaterCaustics() {
        Platform.NativeBlur.dispatch("velora-blur:caustics reset")
    }

    function queueProfileDialOptics() {
        profileDialOpticsDirty = true
    }

    function syncProfileDialOptics() {
        const active = root.presented && root.profileDialVisible
        Platform.NativeBlur.dispatch("velora-blur:dial " + (active ? "1" : "0")
            + " " + root.profileDialDepth.toFixed(3)
            + " " + root.profileDialHalfHeight.toFixed(3)
            + " " + root.profileDialCenterY.toFixed(3))
    }

    readonly property real reveal: transition.progress
    readonly property real opticsReveal: transition.progress
    readonly property real designScale: Math.min(width / 1600, height / 900)
    readonly property real designOriginX: (width - 1600 * designScale) / 2
    readonly property real designOriginY: (height - 900 * designScale) / 2
    readonly property real mainPanelX: 161.5
    readonly property real contentShiftX: mainPanelX - 239
    readonly property bool dimBackground: config.lockDimmingMode === "background"
        || config.lockDimmingMode === "both"
    readonly property bool dimPanel: config.lockDimmingMode === "panel"
        || config.lockDimmingMode === "both"
    readonly property real activeDimming: Math.max(0, Math.min(
        0.72, config.lockDimmingAmount))
    property real backgroundDimmingLevel: dimBackground ? activeDimming : 0
    property real panelDimmingLevel: dimPanel ? activeDimming : 0
    readonly property bool profileDialVisible: !theme.editorial
        && profileDial.railVisible
    readonly property real profileDialDepth: profileDial.surfaceDepth
    readonly property real profileDialHalfHeight: profileDial.surfaceHalfHeight
    readonly property real profileDialCenterX: profileDial.x + profileDial.wallX
    readonly property real profileDialCenterY: profileDial.y + profileDial.centerY

    onPresentedChanged: {
        queueProfileDialOptics()
        syncWaterCaustics()
    }
    onWaterCausticsVisibleChanged: syncWaterCaustics()
    onWaterCausticsAnimatingChanged: syncWaterCaustics()
    onProfileDialVisibleChanged: queueProfileDialOptics()
    onProfileDialDepthChanged: queueProfileDialOptics()
    onProfileDialHalfHeightChanged: queueProfileDialOptics()

    FrameAnimation {
        id: profileDialSync
        running: root.profileDialOpticsDirty
        onTriggered: {
            root.syncProfileDialOptics()
            root.profileDialOpticsDirty = false
        }
    }

    Connections {
        target: root.config
        function onConfigurationChanged() {
            root.syncRetainedLayers()
            root.syncWaterCaustics()
        }
    }

    Connections {
        target: root.causticsClock
        function onActiveChanged() {
            if (root.causticsClock.active)
                Qt.callLater(root.syncWaterCaustics)
        }
    }

    Component.onCompleted: {
        syncRetainedLayers()
        queueProfileDialOptics()
        syncWaterCaustics()
    }
    Component.onDestruction: {
        Platform.NativeBlur.dispatch("velora-blur:dial 0 0 0 408")
        resetWaterCaustics()
    }

    Behavior on backgroundDimmingLevel {
        NumberAnimation { duration: root.motion.selection; easing.type: Easing.OutCubic }
    }
    Behavior on panelDimmingLevel {
        NumberAnimation { duration: root.motion.selection; easing.type: Easing.OutCubic }
    }

    // Draw a real alpha surface instead of sampling a hidden MultiEffect
    // source. The rounded transparent opening is the exact panel footprint:
    // "Somente fundo" can darken the desktop without showing through the
    // translucent glass.
    Canvas {
        id: backgroundShade
        anchors.fill: parent
        z: -2
        antialiasing: true
        renderTarget: Canvas.Image
        renderStrategy: Canvas.Cooperative
        readonly property real cutoutX: root.designOriginX
            + root.mainPanelX * root.designScale
        readonly property real cutoutY: root.designOriginY + 103 * root.designScale
        readonly property real cutoutWidth: 1277 * root.designScale
        readonly property real cutoutHeight: 610 * root.designScale
        readonly property real cutoutRadius: root.theme.panelRadius * root.designScale
        readonly property bool dialCutoutVisible: root.presented
            && root.profileDialVisible && root.profileDialDepth > 0.5
        readonly property real dialCutoutX: root.designOriginX
            + (root.profileDialCenterX - root.profileDialDepth) * root.designScale
        readonly property real dialCutoutY: root.designOriginY
            + (root.profileDialCenterY - root.profileDialHalfHeight) * root.designScale
        readonly property real dialCutoutWidth: root.profileDialDepth * 2
            * root.designScale
        readonly property real dialCutoutHeight: root.profileDialHalfHeight * 2
            * root.designScale
        readonly property real dialCutoutRadius: root.profileDialDepth
            * root.designScale
        readonly property bool editorialBackdrop: root.theme.editorial
        visible: opacity > 0.001
        opacity: root.backgroundDimmingLevel * root.opticsReveal

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onCutoutXChanged: requestPaint()
        onCutoutYChanged: requestPaint()
        onCutoutWidthChanged: requestPaint()
        onCutoutHeightChanged: requestPaint()
        onCutoutRadiusChanged: requestPaint()
        onDialCutoutVisibleChanged: requestPaint()
        onDialCutoutXChanged: requestPaint()
        onDialCutoutYChanged: requestPaint()
        onDialCutoutWidthChanged: requestPaint()
        onDialCutoutHeightChanged: requestPaint()
        onDialCutoutRadiusChanged: requestPaint()
        onEditorialBackdropChanged: requestPaint()

        onPaint: {
            const context = getContext("2d")
            context.reset()
            context.clearRect(0, 0, width, height)
            context.globalCompositeOperation = "source-over"
            context.fillStyle = "black"
            context.fillRect(0, 0, width, height)
            if (!root.theme.editorial) {
                context.globalCompositeOperation = "destination-out"
                context.beginPath()
                context.roundedRect(cutoutX, cutoutY, cutoutWidth,
                                    cutoutHeight, cutoutRadius, cutoutRadius)
                context.fill()
                if (dialCutoutVisible) {
                    context.beginPath()
                    context.roundedRect(dialCutoutX, dialCutoutY,
                                        dialCutoutWidth, dialCutoutHeight,
                                        dialCutoutRadius, dialCutoutRadius)
                    context.fill()
                }
            }
            context.globalCompositeOperation = "source-over"
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        enabled: root.reveal > 0.98
        onClicked: root.closeRequested()
    }

    AudioVisualizer {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 180
        z: 0
        theme: root.theme
        visualizer: root.visualizer
        visible: opacity > 0.001
        opacity: root.visualizer.running
            ? Math.max(0, (root.reveal - 0.28) / 0.72) : 0
    }

    Item {
        id: designCanvas
        z: 1
        width: 1600
        height: 900
        anchors.centerIn: parent
        scale: root.designScale
        transformOrigin: Item.Center
        layer.enabled: !root.motion.reduced && root.reveal > 0.001 && root.reveal < 0.995
        layer.smooth: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: 54
            blur: Math.pow(1 - root.reveal, 0.72) * 0.86
            // MultiEffect uses 0.0 as the neutral saturation. Keep motion blur
            // from changing the scene chroma while this temporary layer exists.
            saturation: 0.0
        }

        GlassPanel {
            id: mainGlass
            x: root.mainPanelX
            y: 103 + (1 - root.opticsReveal) * 50
            width: 1277
            height: 610
            z: 2
            radius: root.theme.panelRadius
            nativeOptics: true
            surfaceColor: root.theme.glass
            borderColor: root.theme.border
            shadowColor: root.theme.shadow
            opacity: root.theme.editorial ? 0 : root.opticsReveal
            visible: opacity > 0.001
            scale: 0.95 + root.opticsReveal * 0.05
            leftOpeningCenter: root.profileDialCenterY - y
            leftOpeningHalfHeight: root.profileDialVisible
                ? root.profileDialHalfHeight : 0
        }

        // The panel shade sits above the optical glass and below every
        // foreground scene layer, so text, images and the character retain
        // their original color while the glass gains contrast.
        Rectangle {
            x: mainGlass.x + 1
            y: mainGlass.y + 1
            width: mainGlass.width - 2
            height: mainGlass.height - 2
            z: 2.2
            radius: Math.max(0, mainGlass.radius - 1)
            color: "black"
            visible: !root.theme.editorial && opacity > 0.001
            opacity: root.panelDimmingLevel * root.opticsReveal
        }

        Repeater {
            model: retainedLayerModel

            SceneLayerItem {
                id: sceneLayer
                required property string layerId
                required property string layerType
                readonly property var currentLayers: root.config.sceneLayers
                readonly property var currentLayer: root.layerForId(
                    currentLayers, layerId)
                readonly property var missingLayer: ({
                    id: layerId,
                    type: layerType,
                    name: layerId,
                    plane: "abovePanel",
                    order: 0,
                    visible: false,
                    locked: false,
                    transform: { x: 0, y: 0, scale: 1, rotation: 0,
                                 opacity: 0, flipX: false }
                })
                layerData: currentLayer || missingLayer
                transientTransform: root.editor.effectiveTransform(
                    layerId, layerData.transform)
                zBase: String(layerData.plane) === "belowPanel" ? 0.4 : 3
                config: root.config
                theme: root.theme
                motion: root.motion
                clock: root.clock
                calendarService: root.calendarService
                media: root.media
                weather: root.weather
                presented: root.presented
                reveal: root.reveal
                profileTransitioning: root.profileService.transitioning
                profileTransitionDuration: root.profileService.transitionDuration
                waterCausticsEnabled: root.waterCausticsVisible
                    && root.config.waterCausticsLines
                    && root.config.waterCausticsModules
                waterCausticsIntensity: root.config.waterCausticsIntensity
                waterCausticsPhase: root.waterCausticsPhase
                suppressed: ["clock", "calendar", "weather", "gallery",
                             "media-player", "media"].includes(layerId)
            }
        }

        CompositionProfileDial {
            id: profileDial
            x: root.mainPanelX - wallX + 4
            y: 243
            z: 12
            presented: root.presented
            profileService: root.profileService
            theme: root.theme
            motion: root.motion
            visible: !root.theme.editorial && presented
        }

    }
}
