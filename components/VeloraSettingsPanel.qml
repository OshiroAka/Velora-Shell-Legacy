import QtQuick

VeloraSettingsBackend {
    id: root
    property alias surfaceItem: compact
    property bool open: visible
    readonly property int cornerRadius: 24
    readonly property real revealProgress: open ? 1 : 0
    active: open && visible
    activePage: ["appearance", "bar", "bar", "wallpapers", "desktop", "media", "velyrics"][compact.activeTab]
    function moveSelection(delta) { compact.activeTab = (compact.activeTab + delta + compact.tabs.length) % compact.tabs.length }
    function applySelected() { if (compact.activeTab === 3) saveWallpaperTransition() }
    VeloraCompactSettings {
        id: compact
        anchors.fill: parent
        theme: root.theme
        controller: root
    }
}
