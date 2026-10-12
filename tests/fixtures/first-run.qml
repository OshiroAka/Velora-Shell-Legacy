import QtQuick
import Quickshell
import "core" as Core
import "services" as Services

ShellRoot {
    Core.ConfigStore { id: configuration }
    Core.Theme {
        id: freshTheme
        config: configuration
        palette: null
    }
    QtObject {
        id: wallpaper
        property bool ready: true
        property string currentPath: ""
        signal wallpaperApplied(string path)
        function fileUrl(path) { return path ? "file://" + path : "" }
        function applyWallpaper(path) { return false }
    }
    Services.CompositionProfileService {
        id: profiles
        config: configuration
        wallpaperService: wallpaper
    }
    Timer {
        property int attempts: 0
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            attempts += 1
            if (configuration.ready && profiles.ready) {
                const color = freshTheme.withAlpha(undefined, 0.5)
                if (Math.abs(color.a - 0.5) > 0.01 || configuration.referenceAppearance !== true) {
                    console.error("VELORA_FIRST_RUN_FAILED", "theme or official layout")
                    Qt.quit()
                    return
                }
                console.info("VELORA_FIRST_RUN_READY")
                Qt.quit()
            } else if (attempts > 80) {
                console.error("VELORA_FIRST_RUN_FAILED", configuration.error, profiles.error)
                Qt.quit()
            }
        }
    }
}
