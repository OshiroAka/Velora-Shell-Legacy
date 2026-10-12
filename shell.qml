import QtQuick
import Quickshell

ShellRoot {
    Timer {
        interval: 1
        running: Quickshell.env("VELORA_VALIDATE") === "1"
        onTriggered: Qt.quit()
    }
    Loader {
        id: shellLoader
        active: Quickshell.env("VELORA_VALIDATE") !== "1"
        sourceComponent: ShellController { composition: compositionLoader.item }
    }
    Loader {
        id: compositionLoader
        active: Quickshell.env("VELORA_VALIDATE") !== "1"
        sourceComponent: CompositionController { shell: shellLoader.item }
    }
}
