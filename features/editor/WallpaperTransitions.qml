import QtQuick
import "../../components" as Components

Column {
    id: root
    required property var theme
    required property var motion
    required property var backend
    readonly property string mode: backend ? backend.wallpaperTransition : "fade"
    readonly property var descriptions: ({
        fade:["Fade", "Uma imagem desaparece enquanto a outra ganha presença."],
        wave:["Wave", "Uma frente ondulada revela o próximo wallpaper."],
        wipe:["Wipe", "Uma passagem lateral troca a imagem de ponta a ponta."],
        grow:["Grow", "A nova imagem se expande a partir do centro."],
        outer:["Outer", "A troca vem das bordas e se encontra no centro."],
        random:["Random", "Uma transição diferente a cada troca."]
    })
    spacing: 22
    Components.VeloraSettingsTabs {
        objectName: "wallpaper.transition"
        theme: root.theme; motion: root.motion
        width: Math.min(parent.width, 570); tabWidth: 80
        options: root.backend ? root.backend.wallpaperTransitionOptions() : []
        selected: root.mode
        onChosen: id => { if (root.backend) root.backend.setWallpaperTransition(id) }
    }
    Item {
        width: parent.width
        readonly property bool stacked: width < 720
        implicitHeight: stacked ? illustration.height+details.height+20 : Math.max(illustration.height,details.height)
        WallpaperTransitionPreview {
            id: illustration
            width: parent.stacked ? Math.min(parent.width,420) : Math.min(420,parent.width*.42)
            height: implicitHeight
            theme: root.theme; motion: root.motion; mode: root.mode
            duration: root.backend ? root.backend.wallpaperTransitionDuration : 1
        }
        Column {
            id: details
            x: parent.stacked ? 0 : illustration.width+28
            y: parent.stacked ? illustration.height+20 : 6
            width: parent.stacked ? parent.width : parent.width-x
            spacing: 8
            Text { text: (root.descriptions[root.mode] || root.descriptions.fade)[0]
                color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 20 }
            Text { width: parent.width; wrapMode: Text.WordWrap
                text: (root.descriptions[root.mode] || root.descriptions.fade)[1]
                color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 12 }
            Components.VeloraSettingsSlider {
                objectName: "wallpaper.duration"
                theme: root.theme; label: "Duração"; minimum: .15; maximum: 3
                value: root.backend ? root.backend.wallpaperTransitionDuration : 1
                valueText: value.toFixed(2)+" s"
                onEdited: value => { if(root.backend) root.backend.setWallpaperTransitionDuration(value) }
            }
            Components.VeloraSettingsSlider {
                objectName: "wallpaper.delay"
                theme: root.theme; label: "Atraso da imagem estática"; minimum: 0; maximum: .8
                value: root.backend ? root.backend.wallpaperStaticDelay : .12
                valueText: value.toFixed(2)+" s"
                onEdited: value => { if(root.backend) root.backend.setWallpaperStaticDelay(value) }
            }
        }
    }
    Rectangle { width: parent.width; height: 1; color: root.theme.borderSubtle }
    Column {
        width: parent.width; spacing: 10
        Text { text: "Wallpapers animados"; color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 14 }
        Components.VeloraSettingsTabs {
            objectName: "wallpaper.live-engine"
            theme: root.theme; motion: root.motion; tabWidth: 135
            options: [{id:"shader",label:"Shaders"},{id:"native",label:"Nativa do awww"}]
            selected: root.backend ? root.backend.wallpaperLiveTransition : "shader"
            onChosen: id => { if(root.backend) root.backend.setWallpaperLiveTransition(id) }
        }
        Text { width: parent.width; text: "Escolha como trocar entre vídeos. Imagens estáticas usam a transição nativa."
            wrapMode: Text.WordWrap; color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 11 }
    }
}
