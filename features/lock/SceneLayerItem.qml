import QtQuick
import "../../core/SurfaceGeometry.js" as Geometry

Item {
    id: root

    required property var layerData
    required property var config
    required property var theme
    required property var motion
    required property var clock
    required property var calendarService
    required property var media
    required property var weather
    required property bool presented
    property real reveal: 1
    property real zBase: 3
    property bool profileTransitioning: false
    property int profileTransitionDuration: 680
    property bool waterCausticsEnabled: false
    property real waterCausticsIntensity: 0.32
    property real waterCausticsPhase: 0
    property bool suppressed: false
    property var transientTransform: null
    property string space: "lock"
    property bool nativeOptics: false
    property var surfaceBounds: null

    readonly property var transformData: transientTransform
        || layerData[space] || layerData.transform || ({})
    readonly property var styleData: layerData[space + "Style"]
        || layerData.style || ({})
    readonly property string materialMode: root.theme.resolvedMaterial(styleData)
    readonly property string variantId: root.theme.resolvedVariant(
        layerData.variantId || "inherit")
    readonly property bool enabledInSpace: space === "desktop"
        ? Boolean(layerData.desktopEnabled) : (layerData.lockEnabled === undefined
            ? Boolean(layerData.visible) : Boolean(layerData.lockEnabled))
    readonly property string layerType: String(layerData.type || "")
    readonly property int transformDuration: profileTransitioning
        ? profileTransitionDuration : motion.selection
    property real configuredX: Number(transformData.x || 0)
    property real configuredY: Number(transformData.y || 0)
    property real configuredScale: Number(
        transformData.scale === undefined ? 1 : transformData.scale)
    property real configuredRotation: Number(transformData.rotation || 0)
    property real configuredOpacity: enabledInSpace
        ? Number(transformData.opacity === undefined ? 1 : transformData.opacity) : 0

    readonly property var displayPose: Geometry.pose({x: configuredX, y: configuredY + (1 - reveal) * 26,
        scale: configuredScale, rotation: configuredRotation}, width, height, surfaceBounds)
    x: displayPose.x
    y: displayPose.y
    width: Number(layerData.baseWidth || config.moduleSize(layerType)[0])
    height: Number(layerData.baseHeight || config.moduleSize(layerType)[1])
    z: zBase + Number(layerData.order || 0) * 0.001
    scale: displayPose.scale
    rotation: configuredRotation
    opacity: configuredOpacity * Math.max(0, Math.min(1, reveal))
    visible: !suppressed && opacity > 0.001
    transformOrigin: Item.TopLeft

    Behavior on configuredX {
        enabled: !root.config.reducedMotion
        NumberAnimation { duration: root.transformDuration; easing.type: Easing.InOutCubic }
    }
    Behavior on configuredY {
        enabled: !root.config.reducedMotion
        NumberAnimation { duration: root.transformDuration; easing.type: Easing.InOutCubic }
    }
    Behavior on configuredScale {
        enabled: !root.config.reducedMotion
        NumberAnimation { duration: root.transformDuration; easing.type: Easing.InOutCubic }
    }
    Behavior on configuredRotation {
        enabled: !root.config.reducedMotion
        NumberAnimation { duration: root.transformDuration; easing.type: Easing.InOutCubic }
    }
    Behavior on configuredOpacity {
        enabled: !root.config.reducedMotion
        NumberAnimation { duration: root.transformDuration; easing.type: Easing.InOutCubic }
    }

    Loader {
        anchors.fill: parent
        active: !root.suppressed
        sourceComponent: root.componentForType(root.layerType)
    }

    function componentForType(type) {
        if (type === "character") return characterComponent
        if (type === "image") return imageComponent
        if (type === "clock") return clockComponent
        if (type === "calendar") return calendarComponent
        if (type === "weather") return weatherComponent
        if (type === "profileHeader") return profileHeaderComponent
        if (type === "greeting") return greetingComponent
        if (type === "verticalLabel") return verticalLabelComponent
        if (type === "gallery") return galleryComponent
        if (type === "mediaPlayer") return mediaComponent
        if (type === "photoGrid") return photoGridComponent
        if (type === "text") return textComponent
        return null
    }

    Component {
        id: characterComponent
        CrossfadeCharacter {
            anchors.fill: parent
            source: root.config.characterPath
            fillMode: Image.Stretch
            smooth: true
            mipmap: true
            playing: root.presented
            reducedMotion: root.motion.reduced
            duration: root.profileTransitioning
                ? root.profileTransitionDuration : (root.motion.reduced ? 0 : 190)
            mirrored: Boolean(root.transformData.flipX)
        }
    }

    Component {
        id: imageComponent
        Item {
            anchors.fill: parent

            GlassPanel {
                anchors.fill: parent
                radius: Number(root.styleData.radius || 28)
                materialMode: root.theme.resolvedMaterial(root.styleData)
                solidColor: String(root.styleData.solidColor || "#20222a")
                materialOpacity: Number(root.styleData.surfaceOpacity === undefined
                    ? 0.82 : root.styleData.surfaceOpacity)
                surfaceColor: root.theme.moduleSurface
                borderColor: root.theme.moduleBorder
                shadowColor: Qt.rgba(root.theme.shadow.r, root.theme.shadow.g,
                                     root.theme.shadow.b, 0.12)
                nativeOptics: root.nativeOptics
                consumeInput: false
            }

            CroppedImage {
                readonly property real inset: String(root.styleData.material || "none")
                    === "none" ? 0 : Math.max(5, Number(root.styleData.gap || 10))
                anchors.fill: parent
                anchors.margins: inset
                source: String(root.layerData.source || "")
                crop: root.layerData.crop || ({ x: 0, y: 0, width: 1, height: 1 })
                radius: Math.max(0, Number(root.styleData.radius || 20) - inset)
                mirrored: Boolean(root.transformData.flipX)
                playing: root.presented
            }
        }
    }

    Component {
        id: clockComponent
        ClockCard {
            theme: root.theme
            clock: root.clock
            itemStyle: root.styleData
            variantId: root.variantId
            causticsEnabled: root.waterCausticsEnabled
            causticsIntensity: root.waterCausticsIntensity
            causticsPhase: root.waterCausticsPhase
            causticsOrigin: Qt.point(root.configuredX, root.configuredY)
            causticsScale: root.configuredScale
            causticsRotation: root.configuredRotation
        }
    }

    Component {
        id: calendarComponent
        CalendarCard {
            theme: root.theme
            motion: root.motion
            clock: root.clock
            calendarService: root.calendarService
            itemStyle: root.styleData
            variantId: root.variantId
            causticsEnabled: root.waterCausticsEnabled
            causticsIntensity: root.waterCausticsIntensity
            causticsPhase: root.waterCausticsPhase
            causticsOrigin: Qt.point(root.configuredX, root.configuredY)
            causticsScale: root.configuredScale
            causticsRotation: root.configuredRotation
        }
    }

    Component {
        id: weatherComponent
        WeatherCard {
            theme: root.theme
            motion: root.motion
            clock: root.clock
            weather: root.weather
            itemStyle: root.styleData
            variantId: root.variantId
            causticsEnabled: root.waterCausticsEnabled
            causticsIntensity: root.waterCausticsIntensity
            causticsPhase: root.waterCausticsPhase
            causticsOrigin: Qt.point(root.configuredX, root.configuredY)
            causticsScale: root.configuredScale
            causticsRotation: root.configuredRotation
        }
    }

    Component {
        id: profileHeaderComponent
        GlassPanel {
            width: root.width
            height: root.height
            radius: root.theme.editorial ? Math.min(34, height / 2) : 29
            surfaceColor: root.theme.moduleSurface
            borderColor: root.theme.moduleBorder
            shadowColor: Qt.rgba(root.theme.shadow.r, root.theme.shadow.g,
                                 root.theme.shadow.b, 0.12)
            causticsEnabled: root.waterCausticsEnabled
            causticsIntensity: root.waterCausticsIntensity
            causticsPhase: root.waterCausticsPhase
            causticsOrigin: Qt.point(root.configuredX, root.configuredY)
            causticsScale: root.configuredScale
            causticsRotation: root.configuredRotation

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: root.theme.editorial ? 28 : 21
                anchors.right: avatar.left
                anchors.rightMargin: 8
                text: root.config.profileName
                color: root.theme.ink
                font.family: root.theme.bodyFont
                font.pixelSize: root.theme.editorial ? 22 : 18
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            RoundedImage {
                id: avatar
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: root.theme.editorial ? 8 : 3
                width: root.theme.editorial ? Math.max(52, parent.height - 16) : 52
                height: width
                source: root.config.avatarPath
                radius: width / 2
                asynchronous: false
                verticalAlignment: Image.AlignTop
            }

            Rectangle {
                anchors.fill: avatar
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: Qt.rgba(root.theme.ink.r, root.theme.ink.g,
                                      root.theme.ink.b, 0.62)
            }
        }
    }

    Component {
        id: greetingComponent
        Text {
            width: root.width
            height: root.height
            text: root.config.greeting
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: root.theme.heroInk
            font.family: root.theme.bodyFont
            font.pixelSize: root.config.greetingFontSize
            font.weight: Font.Bold
            wrapMode: Text.WordWrap
        }
    }

    Component {
        id: verticalLabelComponent
        Text {
            width: root.width
            height: root.height
            text: String(root.config.verticalLabel).split("").join("\n")
            color: root.theme.ink
            horizontalAlignment: Text.AlignHCenter
            font.family: "Noto Sans CJK JP"
            font.pixelSize: root.config.verticalLabelFontSize
            font.weight: Font.DemiBold
            lineHeight: 0.92
        }
    }

    Component {
        id: galleryComponent
        GalleryPanel {
            config: root.config
            theme: root.theme
            motion: root.motion
            profileTransitioning: root.profileTransitioning
            profileTransitionDuration: root.profileTransitionDuration
            itemStyle: root.styleData
            variantId: root.variantId
        }
    }

    Component {
        id: mediaComponent
        MediaCard {
            media: root.media
            theme: root.theme
            motion: root.motion
            fallbackArt: root.config.avatarPath
            itemStyle: root.styleData
            variantId: root.variantId
            causticsEnabled: root.waterCausticsEnabled
            causticsIntensity: root.waterCausticsIntensity
            causticsPhase: root.waterCausticsPhase
            causticsOrigin: Qt.point(root.configuredX, root.configuredY)
            causticsScale: root.configuredScale
            causticsRotation: root.configuredRotation
        }
    }

    Component {
        id: photoGridComponent
        PhotoGrid {
            anchors.fill: parent
            theme: root.theme
            items: root.layerData.items || []
            itemStyle: root.styleData
            nativeOptics: root.nativeOptics
        }
    }

    Component {
        id: textComponent
        GlassPanel {
            anchors.fill: parent
            radius: Number(root.styleData.radius || 24)
            materialMode: root.theme.resolvedMaterial(root.styleData)
            solidColor: String(root.styleData.solidColor || "#20222a")
            materialOpacity: Number(root.styleData.surfaceOpacity === undefined
                ? 0.82 : root.styleData.surfaceOpacity)
            surfaceColor: root.theme.moduleSurface
            borderColor: root.theme.moduleBorder
            shadowColor: Qt.rgba(root.theme.shadow.r, root.theme.shadow.g,
                                 root.theme.shadow.b, 0.12)
            nativeOptics: root.nativeOptics
            consumeInput: false

            FontLoader {
                id: customTextFont
                source: String(root.styleData.fontAsset || "")
            }

            Text {
                anchors.fill: parent
                anchors.margins: String(root.styleData.material || "none")
                    === "none" ? 0 : 12
                text: String(root.layerData.text || "Texto")
                color: String(root.styleData.textColor || "").length
                    ? root.styleData.textColor : root.theme.moduleInk
                font.family: customTextFont.name.length ? customTextFont.name
                    : String(root.styleData.fontFamily || root.theme.bodyFont)
                font.pixelSize: 28 * Number(root.styleData.fontScale || 1)
                font.weight: Number(root.styleData.fontWeight || Font.Medium)
                font.letterSpacing: Number(root.styleData.letterSpacing || 0)
                wrapMode: Text.WordWrap
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
