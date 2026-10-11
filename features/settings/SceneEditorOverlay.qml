import QtQuick
import "../../core/SurfaceGeometry.js" as Geometry

Item {
    id: root

    required property bool active
    required property var config
    required property var editor
    required property var theme
    required property var motion
    property bool barOnRight: false
    readonly property var sceneBounds: Geometry.designBounds(width, height,
        editor.editSpace === "desktop" && config.topbarEnabled ? 64 : 0, barOnRight,
        editor.editSpace === "desktop" && config.topbarEnabled ? 40 : 0,
        editor.editSpace === "desktop" ? 18 : 0)
    function displayTransform(layer) {
        return Geometry.pose(layer.transform || ({}), Number(layer.baseWidth || config.moduleSize(layer.type)[0]),
            Number(layer.baseHeight || config.moduleSize(layer.type)[1]), sceneBounds)
    }

    readonly property real designScale: Math.min(width / 1600, height / 900)
    readonly property real designOriginX: (width - 1600 * designScale) / 2
    readonly property real designOriginY: (height - 900 * designScale) / 2
    readonly property var selectedLayer: editor.layerById(editor.selectedLayerId)
    readonly property var selectedTransform: selectedLayer
        ? displayTransform(selectedLayer) : ({})
    readonly property real selectedX: selectedLayer
        ? designOriginX + Number(selectedTransform.x || 0) * designScale : 0
    readonly property real selectedY: selectedLayer
        ? designOriginY + Number(selectedTransform.y || 0) * designScale : 0
    readonly property real selectedWidth: selectedLayer
        ? Number(selectedLayer.baseWidth || config.moduleSize(selectedLayer.type)[0])
            * Number(selectedTransform.scale || 1) * designScale : 0
    readonly property real selectedHeight: selectedLayer
        ? Number(selectedLayer.baseHeight || config.moduleSize(selectedLayer.type)[1])
            * Number(selectedTransform.scale || 1) * designScale : 0

    property real pressSceneX: 0
    property real pressSceneY: 0
    property real startX: 0
    property real startY: 0
    property real startScale: 1
    property real startRotation: 0
    property var cropBefore: ({ x: 0, y: 0, width: 1, height: 1 })
    property var cropDraft: ({ x: 0, y: 0, width: 1, height: 1 })
    property point cropPressPoint: Qt.point(0, 0)
    property bool verticalGuideVisible: false
    property bool horizontalGuideVisible: false
    property real verticalGuideX: 0
    property real horizontalGuideY: 0

    visible: active

    function clone(value) { return JSON.parse(JSON.stringify(value)) }

    function beginCrop(handle, sceneX, sceneY) {
        if (!selectedLayer || selectedLayer.type !== "image")
            return
        cropBefore = clone(selectedLayer.crop || ({ x: 0, y: 0, width: 1, height: 1 }))
        cropDraft = clone(cropBefore)
        cropPressPoint = Qt.point(sceneX, sceneY)
    }

    function previewCrop(handle, sceneX, sceneY) {
        const dx = (sceneX - cropPressPoint.x) / Math.max(1, selectedWidth)
        const dy = (sceneY - cropPressPoint.y) / Math.max(1, selectedHeight)
        let x = Number(cropBefore.x || 0)
        let y = Number(cropBefore.y || 0)
        let width = Number(cropBefore.width === undefined ? 1 : cropBefore.width)
        let height = Number(cropBefore.height === undefined ? 1 : cropBefore.height)
        if (String(handle).includes("left")) {
            const nextX = Math.max(0, Math.min(x + width - 0.02, x + dx))
            width -= nextX - x
            x = nextX
        }
        if (String(handle).includes("right"))
            width = Math.max(0.02, Math.min(1 - x, width + dx))
        if (String(handle).includes("top")) {
            const nextY = Math.max(0, Math.min(y + height - 0.02, y + dy))
            height -= nextY - y
            y = nextY
        }
        if (String(handle).includes("bottom"))
            height = Math.max(0.02, Math.min(1 - y, height + dy))
        cropDraft = { x: x, y: y, width: width, height: height }
    }

    function finishCrop() {
        if (selectedLayer)
            editor.setCrop(selectedLayer.id, cropDraft)
    }

    function designPoint(sceneX, sceneY) {
        return {
            x: (sceneX - designOriginX) / designScale,
            y: (sceneY - designOriginY) / designScale
        }
    }

    function layerAt(sceneX, sceneY) {
        const point = designPoint(sceneX, sceneY)
        const layers = editor.editableLayers
        for (let index = layers.length - 1; index >= 0; index -= 1) {
            const layer = layers[index]
            if (!layer.visible)
                continue
            const transform = displayTransform(layer)
            const scale = Number(transform.scale || 1)
            const width = Number(layer.baseWidth || config.moduleSize(layer.type)[0]) * scale
            const height = Number(layer.baseHeight || config.moduleSize(layer.type)[1]) * scale
            const x = Number(transform.x || 0)
            const y = Number(transform.y || 0)
            if (point.x >= x && point.x <= x + width
                    && point.y >= y && point.y <= y + height)
                return layer
        }
        return null
    }

    function snappedPosition(x, y, layer, disableSnap) {
        verticalGuideVisible = false
        horizontalGuideVisible = false
        if (disableSnap)
            return { x: x, y: y }
        const scale = Number(layer.transform.scale || 1)
        const width = Number(layer.baseWidth || config.moduleSize(layer.type)[0]) * scale
        const height = Number(layer.baseHeight || config.moduleSize(layer.type)[1]) * scale
        const threshold = 6
        let nextX = x
        let nextY = y
        const xTargets = editor.editSpace === "desktop"
            ? [48, 800, 1552] : [161.5, 800, 1438.5]
        const yTargets = editor.editSpace === "desktop"
            ? [92, 450, 852] : [103, 450, 713]
        for (let index = 0; index < xTargets.length; index += 1) {
            const target = xTargets[index]
            const candidates = [x, x + width / 2, x + width]
            for (let candidate = 0; candidate < candidates.length; candidate += 1) {
                if (Math.abs(candidates[candidate] - target) <= threshold) {
                    nextX += target - candidates[candidate]
                    verticalGuideVisible = true
                    verticalGuideX = designOriginX + target * designScale
                    index = xTargets.length
                    break
                }
            }
        }
        for (let index = 0; index < yTargets.length; index += 1) {
            const target = yTargets[index]
            const candidates = [y, y + height / 2, y + height]
            for (let candidate = 0; candidate < candidates.length; candidate += 1) {
                if (Math.abs(candidates[candidate] - target) <= threshold) {
                    nextY += target - candidates[candidate]
                    horizontalGuideVisible = true
                    horizontalGuideY = designOriginY + target * designScale
                    index = yTargets.length
                    break
                }
            }
        }
        return { x: nextX, y: nextY }
    }

    Rectangle {
        x: root.verticalGuideX
        y: root.designOriginY
        width: 1
        height: 900 * root.designScale
        color: root.theme.accentSoft
        opacity: root.verticalGuideVisible ? 0.82 : 0
        visible: opacity > 0
    }

    Rectangle {
        x: root.designOriginX
        y: root.horizontalGuideY
        width: 1600 * root.designScale
        height: 1
        color: root.theme.accentSoft
        opacity: root.horizontalGuideVisible ? 0.82 : 0
        visible: opacity > 0
    }

    MouseArea {
        id: moveArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: root.selectedLayer && pressed ? Qt.ClosedHandCursor : Qt.ArrowCursor

        onPressed: function(mouse) {
            if (root.editor.toolMode === "crop") {
                mouse.accepted = false
                return
            }
            const layer = root.layerAt(mouse.x, mouse.y)
            if (!layer) {
                root.editor.clearSelection()
                mouse.accepted = false
                return
            }
            root.editor.select(layer.id)
            if (layer.locked || !root.editor.beginGesture(layer.id))
                return
            const point = root.designPoint(mouse.x, mouse.y)
            root.pressSceneX = point.x
            root.pressSceneY = point.y
            const displayed = root.displayTransform(layer)
            root.startX = Number(displayed.x || 0)
            root.startY = Number(displayed.y || 0)
        }

        onPositionChanged: function(mouse) {
            if (!pressed || !root.editor.gestureActive)
                return
            const layer = root.editor.layerById(root.editor.gestureLayerId)
            if (!layer)
                return
            const point = root.designPoint(mouse.x, mouse.y)
            const candidateX = root.startX + point.x - root.pressSceneX
            const candidateY = root.startY + point.y - root.pressSceneY
            const snapped = root.snappedPosition(candidateX, candidateY, layer,
                Boolean(mouse.modifiers & Qt.AltModifier))
            root.editor.previewTransform(layer.id, { x: snapped.x, y: snapped.y })
        }

        onReleased: {
            root.verticalGuideVisible = false
            root.horizontalGuideVisible = false
            root.editor.finishGesture()
        }
        onCanceled: root.editor.cancelGesture()
    }

    Item {
        id: selectionBox
        x: root.selectedX
        y: root.selectedY
        width: root.selectedWidth
        height: root.selectedHeight
        rotation: Number(root.selectedTransform.rotation || 0)
        transformOrigin: Item.Center
        visible: Boolean(root.selectedLayer)

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: 2
            border.color: root.selectedLayer && root.selectedLayer.locked
                ? Qt.rgba(1, 1, 1, 0.52) : root.theme.accentSoft
            radius: 8
        }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 8
            anchors.topMargin: 8
            width: Math.min(nameText.implicitWidth + 20, parent.width - 16)
            height: 25
            radius: 12.5
            color: Qt.rgba(0.03, 0.05, 0.12, 0.82)

            Text {
                id: nameText
                anchors.centerIn: parent
                text: root.selectedLayer ? String(root.selectedLayer.name) : ""
                color: "white"
                font.family: root.theme.bodyFont
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
        }

        Rectangle {
            id: resizeHandle
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: -9
            anchors.bottomMargin: -9
            width: 19
            height: 19
            radius: 9.5
            color: root.theme.accentSoft
            border.width: 2
            border.color: "white"
            visible: root.selectedLayer && !root.selectedLayer.locked
                && root.editor.toolMode !== "crop"

            MouseArea {
                id: resizeMouse
                anchors.fill: parent
                cursorShape: Qt.SizeFDiagCursor
                onPressed: function(mouse) {
                    const point = mapToItem(root, mouse.x, mouse.y)
                    root.pressSceneX = point.x
                    root.startScale = Number(root.selectedTransform.scale || 1)
                    root.editor.beginGesture(root.editor.selectedLayerId)
                }
                onPositionChanged: function(mouse) {
                    if (!pressed || !root.editor.gestureActive)
                        return
                    const point = mapToItem(root, mouse.x, mouse.y)
                    const width = Math.max(40, root.selectedLayer.baseWidth
                        * root.startScale * root.designScale)
                    const factor = 1 + (point.x - root.pressSceneX) / width
                    root.editor.previewTransform(root.editor.selectedLayerId,
                        { scale: Math.max(0.02, Math.min(32, root.startScale * factor)) })
                }
                onReleased: root.editor.finishGesture()
                onCanceled: root.editor.cancelGesture()
            }
        }

        Rectangle {
            id: rotateHandle
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: -38
            width: 18
            height: 18
            radius: 9
            color: Qt.rgba(0.03, 0.05, 0.12, 0.90)
            border.width: 2
            border.color: root.theme.accentSoft
            visible: root.selectedLayer && !root.selectedLayer.locked
                && root.editor.toolMode !== "crop"

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.CrossCursor
                onPressed: function(mouse) {
                    root.startRotation = Number(root.selectedTransform.rotation || 0)
                    root.editor.beginGesture(root.editor.selectedLayerId)
                }
                onPositionChanged: function(mouse) {
                    if (!pressed || !root.editor.gestureActive)
                        return
                    const point = mapToItem(root, mouse.x, mouse.y)
                    const centerX = root.selectedX + root.selectedWidth / 2
                    const centerY = root.selectedY + root.selectedHeight / 2
                    const angle = Math.atan2(point.y - centerY, point.x - centerX)
                        * 180 / Math.PI + 90
                    root.editor.previewTransform(root.editor.selectedLayerId,
                        { rotation: Math.round(angle) })
                }
                onReleased: root.editor.finishGesture()
                onCanceled: root.editor.cancelGesture()
            }
        }

        Rectangle {
            anchors.fill: parent
            visible: root.editor.toolMode === "crop"
                && root.selectedLayer && root.selectedLayer.type === "image"
            color: Qt.rgba(0.02, 0.04, 0.10, 0.14)
            border.width: 2
            border.color: "white"
            radius: 6

            component CropHandle: Rectangle {
                required property string handle
                property int edgeX: 0
                property int edgeY: 0
                x: edgeX === 0 ? -7 : (edgeX === 1
                    ? (parent.width - width) / 2 : parent.width - width + 7)
                y: edgeY === 0 ? -7 : (edgeY === 1
                    ? (parent.height - height) / 2 : parent.height - height + 7)
                width: 15
                height: 15
                radius: 3
                color: root.theme.accentSoft
                border.width: 1
                border.color: "white"

                MouseArea {
                    anchors.fill: parent
                    onPressed: function(mouse) {
                        const point = mapToItem(root, mouse.x, mouse.y)
                        root.beginCrop(parent.handle, point.x, point.y)
                    }
                    onPositionChanged: function(mouse) {
                        if (!pressed)
                            return
                        const point = mapToItem(root, mouse.x, mouse.y)
                        root.previewCrop(parent.handle, point.x, point.y)
                    }
                    onReleased: root.finishCrop()
                }
            }

            CropHandle { handle: "left-top"; edgeX: 0; edgeY: 0 }
            CropHandle { handle: "top"; edgeX: 1; edgeY: 0 }
            CropHandle { handle: "right-top"; edgeX: 2; edgeY: 0 }
            CropHandle { handle: "left"; edgeX: 0; edgeY: 1 }
            CropHandle { handle: "right"; edgeX: 2; edgeY: 1 }
            CropHandle { handle: "left-bottom"; edgeX: 0; edgeY: 2 }
            CropHandle { handle: "bottom"; edgeX: 1; edgeY: 2 }
            CropHandle { handle: "right-bottom"; edgeX: 2; edgeY: 2 }
        }
    }
}
