import QtQuick

Flow {
    id: root
    required property var theme
    required property var motion
    required property var config
    property url imageSource: ""
    spacing: 10
    readonly property int columns: width < 500 ? 2 : 3
    Repeater {
        model: [{id:"solid",label:"Sólido",detail:"Cor uniforme"},
                {id:"glass",label:"Translúcido",detail:"Fundo suavizado"},
                {id:"liquid",label:"Liquid glass",detail:"Luz e profundidade"}]
        Rectangle {
            id: card
            required property var modelData
            required property int index
            property string label: modelData.label
            readonly property bool selected: root.config.barMaterial === modelData.id
            width: Math.floor((root.width-(root.columns-1)*10)/root.columns); height: 150; radius: 14
            color: Qt.rgba(root.theme.accent.r,root.theme.accent.g,root.theme.accent.b,selected ? .18 : .035)
            border.width: 1; border.color: selected || activeFocus ? root.theme.accentSoft : root.theme.borderSubtle
            activeFocusOnTab: true
            Accessible.role: Accessible.RadioButton; Accessible.name: label
            Accessible.checkable: true; Accessible.checked: selected
            function triggered() { root.config.setBarAppearance(modelData.id,root.config.barWaveStrength) }
            Accessible.onPressAction: triggered()
            Keys.onSpacePressed: triggered()
            Keys.onReturnPressed: triggered()
            Item {
                x: 8; y: 8; width: parent.width-16; height: 92; clip: true
                SettingsScenePreview { anchors.fill: parent; theme: root.theme; imageSource: root.imageSource }
                Item {
                    x: 12; y: 23; width: parent.width-24; height: 48; clip: true
                    SettingsScenePreview {
                        x: -12; y: -23; width: parent.parent.width; height: parent.parent.height
                        theme: root.theme; imageSource: root.imageSource
                        blur: card.modelData.id === "glass" || (card.modelData.id === "liquid" && root.config.liquidGlassStyle === "frosted") ? .6 : 0
                    }
                    Rectangle {
                        anchors.fill: parent; radius: card.modelData.id === "liquid" ? 17 : 12
                        color: Qt.rgba(root.theme.barSurface.r,root.theme.barSurface.g,root.theme.barSurface.b,
                            card.modelData.id === "solid" ? 1 : card.selected ? Math.max(.12,root.config.barOpacity) : .32)
                        border.width: card.modelData.id === "liquid" ? 2 : 1
                        border.color: Qt.rgba(1,1,1,card.modelData.id === "liquid" ? .45 : .15)
                        Row { anchors.centerIn: parent; spacing: 12
                            Rectangle { width: 19; height: 19; radius: 10; color: root.theme.accentSoft; opacity: .8 }
                            Text { text: "Velora"; color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 11 }
                            Text { text: "10:08"; color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 10 }
                        }
                    }
                }
            }
            Text { x: 12; y: 108; text: card.label; color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 12 }
            Text { x: 12; y: 127; text: card.modelData.detail; color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 9 }
            Rectangle { anchors.right: parent.right; anchors.rightMargin: 12; y: 112; width: 9; height: 9; radius: 5; color: card.selected ? root.theme.accentSoft : "transparent"; border.color: root.theme.textSecondary; border.width: 1 }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: card.triggered() }
        }
    }
}
