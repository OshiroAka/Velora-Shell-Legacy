import QtQuick
import QtQuick.Window
import Quickshell
import "components" as Components

ShellRoot {
    Window {
        id: preview
        visible: true
        width: 170; height: 150
        color: "#77716f"
        Rectangle {
            x: 54; y: 12; width: 62; height: 126
            radius: 22
            color: "#605458"
            Components.VeloraFanPlusIndicator {
                id: fan
                anchors.horizontalCenter: parent.horizontalCenter
                y: 15
                active: true
                accent: "#d6b2c8"
                ink: "#f5f0ee"
            }
        }
        Timer {
            interval: 1800; running: true
            onTriggered: preview.contentItem.grabToImage(function(image) {
                image.saveToFile(Quickshell.env("VELORA_FANPLUS_PREVIEW"))
                console.log("VELORA_FANPLUS_PREVIEW_SAVED")
                Qt.quit()
            })
        }
    }
}
