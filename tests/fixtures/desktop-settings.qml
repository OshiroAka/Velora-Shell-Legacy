import QtQuick
import Quickshell
import "core" as Core

ShellRoot {
    Core.ConfigStore { id: config }
    property int stage: 0
    property string widgetSelection: ""
    function check(ok, message) {
        if (!ok) throw new Error(message)
    }
    Timer {
        interval: 80; running: true; repeat: true
        onTriggered: {
            if (!config.ready) return
            try {
                if (stage === 0) {
                    if (Quickshell.env("VELORA_SETTINGS_RELOAD") === "1") {
                        check(config.liquidGlassStyle === "clear", "liquid style survives reload")
                        check(!config.desktopWidgetsEnabled, "hidden state survives reload")
                        check(!config.desktopVisualizerEnabled, "visualizer state survives reload")
                        check(config.wallpaperBlurEnabled && Math.abs(config.wallpaperBlurStrength - 0.72) < 0.001, "blur survives reload")
                        check(Math.abs(config.wallpaperDimming - 0.34) < 0.001, "dimming survives reload")
                        check(config.widgetVisibleAtProgress("clock", 1), "lock widgets stay visible")
                        console.info("DESKTOP_SETTINGS_OK"); Qt.quit(); return
                    }
                    check(config.liquidGlassStyle === "frosted", "readable frosted default")
                    config.setValue("bar.liquidStyle", "clear")
                    check(config.liquidGlassStyle === "clear", "clear variant selected")
                    config.setValue("bar.liquidStyle", "frosted")
                    check(config.liquidGlassStyle === "frosted", "frosted variant selected")
                    config.setValue("bar.liquidStyle", "clear")
                    config.setSharedWidgetVisibility("clock", true, true)
                    widgetSelection = JSON.stringify(config.sharedWidgets)
                    check(config.widgetVisibleAtProgress("clock", 0), "desktop starts visible")
                    config.setValue("desktop.widgetsEnabled", false)
                    check(!config.widgetVisibleAtProgress("clock", 0), "master switch hides desktop")
                    check(config.widgetVisibleAtProgress("clock", 1), "master switch preserves lock")
                    check(JSON.stringify(config.sharedWidgets) === widgetSelection, "individual choices preserved")
                    config.setValue("desktop.widgetsEnabled", true)
                    check(config.widgetVisibleAtProgress("clock", 0), "master switch restores desktop")
                    config.setValue("desktop.widgetsEnabled", false)
                    config.setValue("desktop.visualizerEnabled", false)
                    config.setValue("desktop.wallpaperBlurEnabled", true)
                    config.setValue("desktop.wallpaperBlurStrength", 0.72)
                    config.setValue("desktop.wallpaperDimming", 0.34)
                    stage = 1
                } else if (!config.savePending) {
                    check(!config.saveError, "settings save failed")
                    console.info("DESKTOP_SETTINGS_OK"); Qt.quit()
                }
            } catch (error) {
                console.error("DESKTOP_SETTINGS_FAILED", error.message); Qt.quit()
            }
        }
    }
}
