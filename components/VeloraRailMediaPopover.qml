pragma ComponentBehavior: Bound
import QtQuick
import "../services" as Services

VeloraRailPopover {
    id: root
    required property var media
    system: media
    preferredWidth: 920
    preferredHeight: 650
    contentPadding: 24
    Services.MediaLibraryService {
        id: library
        media: root.media
        active: root.opened
    }
    customContent: Component {
        VeloraMediaPanel {
            media: root.media
            library: library
            theme: root.theme
            animated: !root.reducedMotion
            onCloseRequested: { root.blocked = root.triggerHovered; root.close() }
        }
    }
}
