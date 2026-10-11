import QtQuick
import QtQuick.Effects
import "../lock" as Lock
import "../../core/SurfaceGeometry.js" as Geometry

Item {
    id: root

    required property var config
    required property var theme
    required property var motion
    required property var clock
    required property var calendarService
    required property var media
    required property var weather
    required property var status
    required property var transition
    required property var editor
    required property var profileService
    required property var causticsClock
    required property bool lockPresented
    property bool editing: false
    property bool barOnRight: false
    readonly property var sceneBounds: Geometry.designBounds(width, height,
        lockPresented || !config.topbarEnabled ? 0 : 64, barOnRight,
        lockPresented || !config.topbarEnabled ? 0 : 40, lockPresented ? 0 : 18)

    readonly property real designScale: Math.min(width / 1600, height / 900)
    readonly property real designOriginX: (width - 1600 * designScale) / 2
    readonly property real designOriginY: (height - 900 * designScale) / 2
    readonly property bool interactionEnabled: !transition.running && !editing
    readonly property bool layoutMorphing: profileService.transitioning
        || editor.layoutTransitioning
    readonly property int layoutMorphDuration: motion.reduced ? 0 : 680
    readonly property bool moduleCaustics: lockPresented
        && config.waterCausticsEnabled && config.waterCausticsLines
        && config.waterCausticsModules

    property alias clockHitItem: sharedClock
    property alias calendarHitItem: sharedCalendar
    property alias weatherHitItem: sharedWeather
    property alias mediaHitItem: sharedMedia
    property alias galleryHitItem: sharedGallery
    property alias systemHitItem: sharedSystem

    function widget(kind) {
        return config.sharedWidgetByKind(kind)
    }

    function dynamicBlurItem(index) {
        const item = desktopLayerRepeater.itemAt(index)
        if (!item || !item.visible || item.opacity <= 0.001
                || item.materialMode !== "liquid")
            return null
        return item
    }

    function translucentWidget(item) {
        return item && item.visible && item.opacity > 0.001
            && String(item.currentMaterial || "solid") !== "solid"
            && String(item.currentMaterial || "solid") !== "none"
    }

    function mix(first, second, amount) {
        return Number(first) + (Number(second) - Number(first)) * Number(amount)
    }

    function transformFor(widgetData, stagger) {
        const fallback = { x: 0, y: 0, scale: 1, rotation: 0,
                           opacity: 1, flipX: false }
        if (!widgetData)
            return Object.assign({}, fallback, { opacity: 0, activity: 0 })
        const desktopBase = widgetData.desktop || fallback
        const lockBase = widgetData.lock || fallback
        const desktop = editor.editSpace === "desktop"
            ? editor.effectiveTransform(widgetData.id, desktopBase) : desktopBase
        const locked = editor.editSpace === "lock"
            ? editor.effectiveTransform(widgetData.id, lockBase) : lockBase
        const movement = transition.motionProgress(stagger)
        const opacityProgress = transition.staggeredProgress(stagger)
        const activity = transition.activity(stagger)
        const pulse = motion.reduced ? 1
            : 1 + Math.sin(Math.PI * opacityProgress) * 0.012
        const desktopOpacity = root.config.desktopWidgetsEnabled && widgetData.desktopEnabled
            ? Number(desktop.opacity === undefined ? 1 : desktop.opacity) : 0
        const lockOpacity = widgetData.lockEnabled
            ? Number(locked.opacity === undefined ? 1 : locked.opacity) : 0
        const candidate = {
            x: mix(desktop.x, locked.x, movement),
            y: mix(desktop.y, locked.y, movement),
            scale: mix(desktop.scale, locked.scale, movement) * pulse,
            rotation: mix(desktop.rotation, locked.rotation, movement),
            opacity: mix(desktopOpacity, lockOpacity, opacityProgress),
            flipX: opacityProgress < 0.5
                ? Boolean(desktop.flipX) : Boolean(locked.flipX),
            activity: activity
        }
        const constrained = config.constrainWidgetTransform(widgetData, candidate)
        constrained.activity = activity
        return constrained
    }

    function sizeFor(widgetData, stagger) {
        if (!widgetData)
            return { width: 8, height: 8 }
        const desktop = widgetData.desktopSize || {
            width: widgetData.baseWidth, height: widgetData.baseHeight }
        const locked = widgetData.lockSize || {
            width: widgetData.baseWidth, height: widgetData.baseHeight }
        const movement = transition.motionProgress(stagger)
        return {
            width: mix(desktop.width, locked.width, movement),
            height: mix(desktop.height, locked.height, movement)
        }
    }

    component SharedWidget: Item {
        id: widgetItem
        required property string kind
        readonly property var widgetData: root.widget(kind)
        readonly property int stagger: widgetData
            ? Number(widgetData.stagger) : 0
        readonly property var currentStyle: {
            if (!widgetData)
                return ({})
            const baseStyle = root.transition.progress < 0.5
                ? Object.assign({material: "solid", solidColor: "#202634", surfaceOpacity: 0.88}, widgetData.desktopStyle || ({}))
                : (widgetData.lockStyle || ({}))
            if (root.config.widgetSurfaceMode === "bar") {
                return Object.assign({}, baseStyle, {
                    material: root.config.barMaterial,
                    surfaceOpacity: root.config.barMaterial === "solid"
                        ? 1 : root.config.barOpacity,
                    solidColor: root.theme.widgetSolidSurface,
                    matchBarSurface: true
                })
            }
            return Object.assign({}, baseStyle, {
                material: "solid",
                surfaceOpacity: 1,
                solidColor: root.theme.widgetSolidSurface,
                matchBarSurface: false
            })
        }
        readonly property string currentMaterial: root.theme.resolvedMaterial(
            currentStyle)
        readonly property string configuredVariant: widgetData
            ? String(widgetData.variantId || "inherit") : "inherit"
        readonly property string currentVariant:
            root.transition.progress < 0.5 ? "editorial" : "classic"
        readonly property var stateTransform: root.transformFor(widgetData, stagger)
        readonly property var stateSize: root.sizeFor(widgetData, stagger)
        property real configuredX: Number(stateTransform.x || 0)
        property real configuredY: Number(stateTransform.y || 0)
        property real configuredScale: Number(
            stateTransform.scale === undefined ? 1 : stateTransform.scale)
        property real configuredRotation: Number(stateTransform.rotation || 0)
        property real configuredOpacity: Number(
            stateTransform.opacity === undefined ? 0 : stateTransform.opacity)
        property real configuredWidth: Number(stateSize.width || 8)
        property real configuredHeight: Number(stateSize.height || 8)
        property real hoverLift: widgetHover.hovered && root.interactionEnabled
            && !root.lockPresented && !root.motion.reduced ? 1 : 0

        readonly property var displayPose: Geometry.pose({x: configuredX, y: configuredY,
            scale: configuredScale * (1 + hoverLift * 0.014), rotation: configuredRotation}, configuredWidth, configuredHeight, root.sceneBounds)
        x: root.designOriginX + displayPose.x * root.designScale
        y: root.designOriginY + displayPose.y * root.designScale
        // Keep the card and all of its fixed design-space children in the
        // same 1600x900 coordinate system, then scale the whole module once.
        // Scaling only the host rectangle enlarged the glass background while
        // tile/text coordinates stayed unscaled, leaving the empty strip seen
        // below every module on 1920x1200 displays.
        width: configuredWidth
        height: configuredHeight
        scale: displayPose.scale * root.designScale
        rotation: configuredRotation
        opacity: configuredOpacity
        visible: Boolean(widgetData) && opacity > 0.001
        enabled: root.interactionEnabled
        transformOrigin: Item.TopLeft
        z: 3 + stagger
        layer.enabled: !root.motion.reduced && root.transition.running
        layer.smooth: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: 24
            blur: Number(widgetItem.stateTransform.activity || 0) * 0.10
            // Keep the transition layer color-neutral; 0.0 means no change.
            saturation: 0.0
        }

        HoverHandler { id: widgetHover; enabled: root.interactionEnabled }

        Behavior on hoverLift {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Behavior on configuredX {
            enabled: root.layoutMorphing && !root.transition.running
                && !root.editor.gestureActive
            NumberAnimation { duration: root.layoutMorphDuration; easing.type: Easing.InOutCubic }
        }
        Behavior on configuredY {
            enabled: root.layoutMorphing && !root.transition.running
                && !root.editor.gestureActive
            NumberAnimation { duration: root.layoutMorphDuration; easing.type: Easing.InOutCubic }
        }
        Behavior on configuredScale {
            enabled: root.layoutMorphing && !root.transition.running
                && !root.editor.gestureActive
            NumberAnimation { duration: root.layoutMorphDuration; easing.type: Easing.InOutCubic }
        }
        Behavior on configuredRotation {
            enabled: root.layoutMorphing && !root.transition.running
                && !root.editor.gestureActive
            NumberAnimation { duration: root.layoutMorphDuration; easing.type: Easing.InOutCubic }
        }
        Behavior on configuredOpacity {
            enabled: root.layoutMorphing && !root.transition.running
                && !root.editor.gestureActive
            NumberAnimation { duration: root.layoutMorphDuration; easing.type: Easing.InOutCubic }
        }
        Behavior on configuredWidth {
            enabled: root.layoutMorphing && !root.transition.running
                && !root.editor.gestureActive
            NumberAnimation { duration: root.layoutMorphDuration; easing.type: Easing.InOutCubic }
        }
        Behavior on configuredHeight {
            enabled: root.layoutMorphing && !root.transition.running
                && !root.editor.gestureActive
            NumberAnimation { duration: root.layoutMorphDuration; easing.type: Easing.InOutCubic }
        }

        Loader {
            anchors.fill: parent
            active: widgetItem.visible
            property real causticsX: widgetItem.configuredX
            property real causticsY: widgetItem.configuredY
            property real causticsScale: widgetItem.configuredScale
            property real causticsRotation: widgetItem.configuredRotation
            property var itemStyle: widgetItem.currentStyle
            property string itemVariant: widgetItem.currentVariant
            sourceComponent: root.componentForKind(widgetItem.kind)
        }
    }

    function componentForKind(kind) {
        if (kind === "clock") return clockComponent
        if (kind === "calendar") return calendarComponent
        if (kind === "weather") return weatherComponent
        if (kind === "media") return mediaComponent
        if (kind === "gallery") return galleryComponent
        if (kind === "system") return systemComponent
        return null
    }

    Component {
        id: clockComponent
        Lock.ClockCard {
            anchors.fill: parent
            theme: root.theme
            clock: root.clock
            itemStyle: parent.itemStyle
            variantId: parent.itemVariant
            nativeOptics: true
            causticsEnabled: root.moduleCaustics
            causticsIntensity: root.config.waterCausticsIntensity
            causticsPhase: root.causticsClock.phase
            causticsOrigin: Qt.point(parent.causticsX, parent.causticsY)
            causticsScale: parent.causticsScale
            causticsRotation: parent.causticsRotation
        }
    }

    Component {
        id: calendarComponent
        Lock.CalendarCard {
            anchors.fill: parent
            theme: root.theme
            motion: root.motion
            clock: root.clock
            calendarService: root.calendarService
            itemStyle: parent.itemStyle
            variantId: parent.itemVariant
            nativeOptics: true
            causticsEnabled: root.moduleCaustics
            causticsIntensity: root.config.waterCausticsIntensity
            causticsPhase: root.causticsClock.phase
            causticsOrigin: Qt.point(parent.causticsX, parent.causticsY)
            causticsScale: parent.causticsScale
            causticsRotation: parent.causticsRotation
        }
    }

    Component {
        id: weatherComponent
        Lock.WeatherCard {
            anchors.fill: parent
            theme: root.theme
            motion: root.motion
            clock: root.clock
            weather: root.weather
            itemStyle: parent.itemStyle
            variantId: parent.itemVariant
            nativeOptics: true
            causticsEnabled: root.moduleCaustics
            causticsIntensity: root.config.waterCausticsIntensity
            causticsPhase: root.causticsClock.phase
            causticsOrigin: Qt.point(parent.causticsX, parent.causticsY)
            causticsScale: parent.causticsScale
            causticsRotation: parent.causticsRotation
        }
    }

    Component {
        id: mediaComponent
        Lock.MediaCard {
            anchors.fill: parent
            media: root.media
            theme: root.theme
            motion: root.motion
            fallbackArt: root.config.avatarPath
            itemStyle: parent.itemStyle
            variantId: parent.itemVariant
            nativeOptics: true
            causticsEnabled: root.moduleCaustics
            causticsIntensity: root.config.waterCausticsIntensity
            causticsPhase: root.causticsClock.phase
            causticsOrigin: Qt.point(parent.causticsX, parent.causticsY)
            causticsScale: parent.causticsScale
            causticsRotation: parent.causticsRotation
        }
    }

    Component {
        id: galleryComponent
        Lock.GalleryPanel {
            anchors.fill: parent
            config: root.config
            theme: root.theme
            motion: root.motion
            profileTransitioning: root.profileService.transitioning
            profileTransitionDuration: root.profileService.transitionDuration
            interactionsEnabled: root.interactionEnabled
            itemStyle: parent.itemStyle
            variantId: parent.itemVariant
            nativeOptics: true
        }
    }

    Component {
        id: systemComponent
        Lock.SystemPanel {
            anchors.fill: parent
            status: root.status
            theme: root.theme
            motion: root.motion
            itemStyle: parent.itemStyle
            variantId: parent.itemVariant
            nativeOptics: true
            causticsEnabled: root.moduleCaustics
            causticsIntensity: root.config.waterCausticsIntensity
            causticsPhase: root.causticsClock.phase
            causticsOrigin: Qt.point(parent.causticsX, parent.causticsY)
            causticsScale: parent.causticsScale
            causticsRotation: parent.causticsRotation
        }
    }

    // Free-form composition items live on the Desktop surface and fade into
    // their Lock counterparts rendered by LockScene. Keeping them in this
    // permanent window avoids recreating image decoders during editing.
    Item {
        id: desktopScene
        x: root.designOriginX
        y: root.designOriginY
        width: 1600
        height: 900
        scale: root.designScale
        transformOrigin: Item.TopLeft
        opacity: 1 - root.transition.progress
        visible: opacity > 0.001
        z: 2

        Repeater {
            id: desktopLayerRepeater
            model: root.config.sceneLayers

            Lock.SceneLayerItem {
                required property var modelData
                layerData: modelData
                config: root.config
                theme: root.theme
                motion: root.motion
                clock: root.clock
                calendarService: root.calendarService
                media: root.media
                weather: root.weather
                presented: !root.lockPresented
                space: "desktop"
                nativeOptics: true
                surfaceBounds: root.sceneBounds
                transientTransform: root.editor.editSpace === "desktop"
                    ? root.editor.effectiveTransform(modelData.id,
                        modelData.desktop || ({})) : null
                profileTransitioning: root.profileService.transitioning
                profileTransitionDuration: root.profileService.transitionDuration
                suppressed: !root.config.desktopWidgetsEnabled || !Boolean(modelData.desktopEnabled)
            }
        }
    }

    SharedWidget { id: sharedClock; kind: "clock" }
    SharedWidget { id: sharedCalendar; kind: "calendar" }
    SharedWidget { id: sharedWeather; kind: "weather" }
    SharedWidget { id: sharedMedia; kind: "media" }
    SharedWidget { id: sharedGallery; kind: "gallery" }
    SharedWidget { id: sharedSystem; kind: "system" }
}
