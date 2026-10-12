import QtQuick
import "platform" as Platform
import "core/SurfaceGeometry.js" as SurfaceGeometry
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import "components"

Scope {
    id: root

    required property var composition
    property var edgeMediaPanels: ({})
    readonly property bool edgeMediaOpen: Object.keys(edgeMediaPanels).length > 0
    property var edgeSpectrumPanels: ({})
    readonly property bool edgeSpectrumOpen: Object.keys(edgeSpectrumPanels).length > 0
    property var edgeDockProgress: ({})
    readonly property real visualizerDockProgress: Math.max(0, ...Object.values(edgeDockProgress))
    function setEdgeDockProgress(screenName, progress) {
        const next = Object.assign({}, edgeDockProgress)
        if (progress > .0001) next[screenName] = progress
        else delete next[screenName]
        edgeDockProgress = next
    }
    function setEdgeSpectrumVisible(screenName, visible) {
        const next = Object.assign({}, edgeSpectrumPanels)
        if (visible) next[screenName] = true
        else delete next[screenName]
        edgeSpectrumPanels = next
    }
    function setEdgeMediaVisible(screenName, visible) {
        const next = Object.assign({}, edgeMediaPanels)
        if (visible) next[screenName] = true
        else delete next[screenName]
        edgeMediaPanels = next
    }
    property alias unifiedTheme: veloraTheme
    function openUnifiedSettings() { closeQuickPopup(); composition.openEditor("desktop") }

    VeloraTheme {
        id: veloraTheme
        // The reference defines geometry, not a fixed blue palette. The
        // existing pywal pipeline remains the single color source.
        referencePalette: false
    }

    Component.onCompleted: Qt.callLater(function() {
        root.syncTopBarWindowGaps()
    })


    NotificationServer {
        id: veloraNotificationServer

        keepOnReload: true
        persistenceSupported: true
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: function(notification) {
            if (!notification)
                return

            notification.tracked = true
            root.upsertNotificationHistory(notification)
            root.playNotificationSound()
            root.showNotificationToast(notification)
        }
    }

    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    PwNodePeakMonitor {
        id: audioPeakMonitor

        node: Pipewire.defaultAudioSink
        // Velora.Native owns signal detection. The old peak monitor emitted
        // JavaScript changes continuously even after the text analyzer was
        // removed, keeping the qs main thread awake.
        enabled: false
    }

    Timer {
        id: audioSignalHoldTimer

        interval: 2200
        repeat: false
        onTriggered: {
            if (audioPeakMonitor.peak > 0.003) {
                restart()
                return
            }
            root.audioSignalRecentlyActive = false
        }
    }

    readonly property bool notificationsInTopbar: !!root.composition && root.composition.connectedNotifications
    property bool notificationToastVisible: false
    property bool notificationToastMounted: false
    property string notificationToastTitle: ""
    property string notificationToastBody: ""
    property string notificationToastApp: ""
    property string notificationToastIconKey: "bell"
    property int notificationToastSerial: 0
    property var trackedNotificationObjects: ({})
    property var notificationDismissQueue: []
    readonly property string notificationSoundPath: Quickshell.env("VELORA_NOTIFICATION_SOUND") || "/usr/share/sounds/freedesktop/stereo/message.oga"
    readonly property int notificationHistoryCount: notificationHistoryModel.count
    property bool wallpaperSelectorOpen: false
    property bool settingsPanelOpen: false
    property bool idlePreloadEnabled: false
    property string quickPopupType: ""
    property string hoverPopupType: ""
    property bool quickPopupHoldOpen: false
    property bool sidebarPopupHovering: false
    property bool quickPopupHovering: false
    property bool weatherTopOpen: false
    // Temporarily inactive at the user's request; keep the weather widget visible.
    readonly property bool weatherMenuEnabled: false
    property bool weatherTopWindowOpen: false
    property bool weatherTopKeyboardFocus: false
    property string weatherTopMode: "weather"
    property bool weatherTopTriggerHovering: false
    property bool weatherTopPanelHovering: false
    property int weatherTopFocusRequest: 0
    property bool wallpaperSelectorHovering: false
    property bool settingsPanelHovering: false
    property bool wallpaperSelectorWindowOpen: false
    property bool settingsPanelWindowOpen: false
    property bool wallpaperPreloadEnabled: false
    property bool settingsPanelPreloadEnabled: false
    property bool quickPopupPreloadEnabled: false
    property int quickPopupPreloadCount: 0
    property bool wallpaperWaveMounted: false
    property string wallpaperWaveFrameDir: ""
    property string wallpaperWaveToken: ""
    property string wallpaperWaveSourcePath: ""
    property real wallpaperWaveDirectionX: 1
    property real wallpaperWaveDirectionY: 0
    property real wallpaperWavePhase: 0
    property string wallpaperWaveTransition: "wave"
    property int wallpaperWaveLastDirection: -1
    property real wallpaperWaveProgress: 0
    property int wallpaperWaveDurationMs: 1000
    property string appLaunchCommand: ""
    property string appliedWindowGaps: ""
    property string pendingWindowGaps: ""
    property int searchPopupFocusAttempts: 0
    property bool rightDashboardOpen: false
    property real topBarPopupCenterX: 0
    property bool topWallpaperPopupOpen: false
    property var wallpaperSelectorViews: ({})
    property bool topWallpaperKeyboardFocus: false
    property bool topWallpaperCardsMounted: false
    property real topWallpaperFrameReveal: topWallpaperPopupOpen ? 1 : 0
    property bool topWallpaperWithoutFrame: true
    readonly property bool topWallpaperMounted: (topWallpaperPopupOpen || topWallpaperFrameReveal > 0.01) && (frameVisualsMounted || topWallpaperWithoutFrame)
    readonly property real topWallpaperSurfaceReveal: frameVisualsMounted ? frameVisualsReveal : (topWallpaperMounted ? 1 : 0)
    property int topWallpaperOffset: 0
    property int topWallpaperSlideDirection: 0
    property int topWallpaperQueuedDirection: 0
    property real topWallpaperSlideProgress: 0
    property var topWallpaperAllEntries: topWallpaperFallbackEntries
    property string topWallpaperMediaFilter: "all"
    property string topWallpaperColorFilter: ""
    property string topWallpaperSearchQuery: ""
    property bool topWallpaperFavoritesOnly: false
    property bool topWallpaperGridMode: false
    property var topWallpaperFavorites: []
    property var topWallpaperHidden: []
    property string topWallpaperActiveKey: ""
    property string topWallpaperErrorMessage: ""
    property var topWallpaperApplyingEntry: null
    property bool topWallpaperLibrarySaveQueued: false
    property bool topWallpaperLibraryReady: false
    property string activeRailControl: ""
    property string railControlHoverTarget: ""
    property bool railControlPanelHovered: false
    property int railFeedbackSerial: 0
    readonly property bool volumeControlOpen: activeRailControl === "volume"
    readonly property bool brightnessControlOpen: activeRailControl === "brightness"
    readonly property bool batteryControlOpen: activeRailControl === "battery"
    property bool leftMenuOpen: false
    property bool leftMenuHovering: false
    property bool leftMenuPinned: false
    property bool leftMenuTriggerHovering: false
    property bool leftMenuHandleHovering: false
    property bool leftMenuHandleRevealHold: false
    property bool leftMenuPanelHovering: false
    property bool leftMediaWindowOpen: false
    property bool leftMediaWindowHovering: false
    property bool leftMediaWindowEntranceHold: false
    property real leftMenuFrameReveal: leftMenuOpen ? 1 : 0
    property real leftMenuHandleSurfaceReveal: (!leftMenuOpen && (leftMenuTriggerHovering || leftMenuHandleHovering || leftMenuHandleRevealHold)) ? 1 : 0
    property real leftMediaWindowCenterY: 300
    property string leftDetailWindowType: "media"
    signal railMediaRequested()
    property real leftDetailSwitchProgress: 1
    property bool leftMenuInteractiveFocus: false
    property bool leftMenuPreloadEnabled: false
    property string rightDashboardSection: "weather"
    property bool focusMode: false
    property int focusIndex: 0
    property real layoutSwitchOpacity: 1
    property string pendingLayoutPosition: ""
    readonly property bool topBarLayout: false
    readonly property bool sideBarLayoutEnabled: !topBarLayout
    // Temporarily hide the rail's media card; retain the shared media service.
    readonly property bool sidebarMediaEnabled: false
    readonly property int focusedWorkspaceId: Hyprland.focusedWorkspace
        ? Number(Hyprland.focusedWorkspace.id)
        : -1
    readonly property bool activeWorkspaceFullscreen: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.hasFullscreen : false
    readonly property bool shellSuppressedByFullscreen: activeWorkspaceFullscreen || (composition && composition.lockOccluding)
    property string infiniteDesktopCommand: ""
    property bool infiniteDesktopCanvasEnabled: false
    property bool infiniteDesktopStateReady: false
    readonly property string infiniteDesktopStatePath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/velora-infinite-desktop.state"
    readonly property bool infiniteDesktopGestureMounted: infiniteDesktopCommand.length > 0 && infiniteDesktopCanvasEnabled && !shellSuppressedByFullscreen
    readonly property bool barOnRight: veloraTheme.barPosition === "right"
    readonly property bool topWallpaperUsesBottomSelector: veloraTheme.wallpaperSelectorPosition === "bottom"
    readonly property bool topWallpaperUsesCenterSelector: !topWallpaperUsesBottomSelector
    readonly property bool leftMenuOnLeft: true
    readonly property string leftMenuAttachSide: leftMenuOnLeft ? "left" : "right"
    readonly property bool rightSoftLayout: true
    readonly property real referenceScale: 1
    readonly property int sidebarVisualWidth: 63
    readonly property real unifiedBarWavePhase: root.composition
        ? root.composition.unifiedBarWavePhase : 0
    readonly property int desktopFrameMargin: 0
    readonly property int sidebarOuterMargin: 0
    readonly property int sidebarVerticalMargin: 0
    readonly property int sidebarCornerRadius: 24
    readonly property int bottomBarHeight: 16
    readonly property int oppositeFrameWidth: 4
    readonly property int screenCornerRadius: 24
    readonly property int sideVisualizerWaveWidth: 58
    readonly property real sideVisualizerCapReach: Math.min(38, sideVisualizerWaveWidth * 0.46)
    readonly property int barPanelWidth: sideBarLayoutEnabled ? sidebarVisualWidth + sidebarOuterMargin : 0
    readonly property int barReserveWidth: sideBarLayoutEnabled ? barPanelWidth : 0
    readonly property int desktopFrameRadius: 24
    readonly property bool frameVisualsEnabled: veloraTheme.desktopFrameEnabled && !topBarLayout
    readonly property int frameVisualInset: frameVisualsEnabled ? desktopFrameMargin : 0
    readonly property bool frameVisualsMounted: frameVisualsEnabled || frameVisualsReveal > 0.01
    // The topbar is an independent overlay: the desktop frame must never rise
    // behind it or draw a second outline around the wallpaper.
    readonly property bool topBarFrameVisualsMounted: false
    readonly property bool topBarCenterVisualizerMounted: topBarLayout
        && !shellSuppressedByFullscreen
        && veloraTheme.visualizerStrength > 0.01
    readonly property bool systemControlCenterVisualizerMounted: topBarQuickPopupPanelVisible
        && visibleQuickPopupType === "system"
        && topBarSystemPage === "settings"
        && !shellSuppressedByFullscreen
    // The top-bar visualizer is part of the frame/cutout, not a separate rail.
    readonly property bool topBarFrameVisualizerMounted: false
    property real frameVisualsReveal: frameVisualsEnabled ? 1 : 0
    property bool sideVisualizerWithoutFrame: true
    readonly property bool screenVisualizerWanted: false
    readonly property bool sideVisualizerMounted: false
    readonly property bool screenVisualizerMounted: screenVisualizerWanted
    readonly property bool audioVisualizerMounted: sideVisualizerMounted
        || screenVisualizerMounted
        || topBarCenterVisualizerMounted
    property bool audioSignalRecentlyActive: false
    readonly property bool audioVisualizerProcessWanted: audioVisualizerMounted && audioSignalRecentlyActive
    property var topBarCavaValues: []

    readonly property real sideVisualizerReveal: frameVisualsMounted ? frameVisualsReveal : (sideVisualizerMounted ? 1 : 0)
    property real screenVisualizerReveal: screenVisualizerMounted ? 1 : 0
    readonly property real desktopFrameMatteOpacity: sidebarPanelGlassAlpha()
    readonly property int popupFrameGap: veloraTheme.popupAttachedToBar ? 0 : 14
    readonly property int sideQuickPopupBarClearance: 14
    readonly property string popupAttachSide: barOnRight ? "right" : "left"
    readonly property int topWallpaperPopupMargin: 8
    readonly property int topWallpaperPopupRadius: 28
    readonly property int topWallpaperSliceCount: 10
    readonly property int topWallpaperSelectedSlot: Math.floor(topWallpaperSliceCount / 2)
    readonly property string topWallpaperHomeDir: Quickshell.env("HOME") || ""
    readonly property string topWallpaperDir: topWallpaperHomeDir + "/Pictures/Wallpapers"
    readonly property string topWallpaperScanScript: Quickshell.shellDir + "/scripts/velora-wallpaper-scan"
    readonly property string topWallpaperApplyScript: Quickshell.shellDir + "/scripts/velora-wallpaper-apply"
    readonly property string topWallpaperLibraryStateScript: Quickshell.shellDir + "/scripts/velora-wallpaper-library-state"
    readonly property string lyricsStateScript: Quickshell.shellDir + "/scripts/velora-lyrics-state"
    readonly property string filesCommand: "if command -v dolphin >/dev/null 2>&1; then dolphin \"$HOME\" >/dev/null 2>&1 & elif command -v thunar >/dev/null 2>&1; then thunar \"$HOME\" >/dev/null 2>&1 & else xdg-open \"$HOME\" >/dev/null 2>&1 & fi"
    readonly property string browserCommand: '"' + Quickshell.shellDir + '/scripts/velora-browser"'
    readonly property var topWallpaperFallbackEntries: []
    property var topWallpaperEntries: topWallpaperFallbackEntries
    readonly property int leftMenuWidth: 820
    readonly property int leftMenuPreferredHeight: 600
    readonly property int leftMenuTriggerWidth: 18
    readonly property int leftMenuHandleWidth: 52
    readonly property int leftMenuHandleHeight: 158
    readonly property int leftMenuFrameInset: frameVisualsEnabled ? desktopFrameMargin + 1 : desktopFrameMargin
    readonly property int leftMediaWindowWidth: 640
    readonly property int leftMediaWindowHeight: 690
    readonly property int leftMediaWindowGap: 12
    property real quickPopupCenterY: 300
    property bool quickPopupWindowOpen: false
    property string renderedQuickPopupType: ""
    property string pendingQuickPopupType: ""
    property real pendingQuickPopupCenterY: 0
    property real pendingTopBarPopupCenterX: 0
    property bool quickPopupSwitching: false
    property bool systemPopupKeyboardFocus: false
    property int systemPopupFocusWorkspaceId: -1
    property string topBarSystemPage: "settings"
    property int topBarSystemSlideDirection: 1
    property string topBarSystemPopupPreferredPage: ""
    property int topBarSystemPopupPreferredWidth: 0
    property int topBarSystemPopupPreferredHeight: 0
    readonly property var topBarSystemPages: ["settings", "wallpaper", "volume", "wifi", "display", "notifications", "bluetooth", "battery"]

    function applyInfiniteDesktopState(data) {
        const line = String(data || "").trim()
        if (line === "enabled=1")
            infiniteDesktopCanvasEnabled = true
        else if (line === "enabled=0")
            infiniteDesktopCanvasEnabled = false
    }

    function updateInfiniteDesktopFeature() {
        infiniteDesktopCommand = String(infiniteDesktopFeatureFile.text() || "").trim()
    }

    onInfiniteDesktopCommandChanged: {
        infiniteDesktopCanvasEnabled = false
        infiniteDesktopStateReady = false
        if (infiniteDesktopCommand.length <= 0)
            return
        Qt.callLater(function() {
            if (!infiniteDesktopStateSync.running && root.infiniteDesktopCommand.length > 0)
                infiniteDesktopStateSync.running = true
        })
    }
    property bool lyricsAvailable: false
    property string lyricsTitle: ""
    property string lyricsArtist: ""
    property string lyricsLine: ""
    property string lyricsReason: ""
    property string lyricsTimingMode: ""
    property var lyricsContextLines: []
    property bool lyricsMaskEditorOpen: false
    property var lyricsMaskEditorPoints: []
    property var lyricsWords: []
    property int lyricsActiveIndex: -1
    property real lyricsPositionSeconds: 0
    property real lyricsDurationSeconds: 0
    property string lyricsGhostText: ""
    property int lyricsGhostSide: 0
    property real lyricsPhraseProgress: 1
    readonly property bool lyricsOverlayMounted: veloraTheme.lyricsEnabled && !shellSuppressedByFullscreen && (lyricsWords.length > 0 || lyricsReason === "between-lines")
    readonly property bool controlCenterLyricsWanted: topBarLayout
        && topBarQuickPopupPanelVisible
        && activeQuickPopupType === "system"
        && topBarSystemPage === "settings"
    readonly property bool lyricsServiceWanted: !shellSuppressedByFullscreen
        && (veloraTheme.lyricsEnabled
            || (topBarLayout && activeQuickPopupType === "media")
            || controlCenterLyricsWanted)
    readonly property bool wallpaperSelectorHoverPreview: hoverPopupType === "theme" && !wallpaperSelectorOpen
    readonly property bool settingsPanelHoverPreview: hoverPopupType === "settings" && !settingsPanelOpen
    readonly property bool wallpaperSelectorPreview: false
    readonly property bool wallpaperSelectorVisible: wallpaperSelectorOpen || wallpaperSelectorPreview
    readonly property bool settingsPanelVisible: settingsPanelOpen || settingsPanelHoverPreview
    readonly property bool wallpaperSelectorPanelVisible: wallpaperSelectorVisible || wallpaperSelectorWindowOpen
    readonly property bool settingsPanelPanelVisible: settingsPanelVisible || settingsPanelWindowOpen
    readonly property bool quickPopupOpen: quickPopupType.length > 0
    readonly property string quickPopupPreviewType: focusMode ? quickPopupForFocus(focusTarget) : ((hoverPopupType !== "theme" && hoverPopupType !== "settings") ? hoverPopupType : "")
    readonly property string activeQuickPopupType: quickPopupOpen ? quickPopupType : quickPopupPreviewType
    readonly property bool quickPopupVisible: activeQuickPopupType.length > 0
    readonly property bool quickPopupPanelVisible: quickPopupVisible || quickPopupWindowOpen
    readonly property bool sideQuickPopupPanelVisible: sideBarLayoutEnabled && quickPopupPanelVisible
    readonly property bool topBarQuickPopupPanelVisible: topBarLayout && quickPopupPanelVisible
    readonly property string visibleQuickPopupType: quickPopupVisible ? activeQuickPopupType : renderedQuickPopupType
    readonly property bool batteryPopupVisualActive: sideQuickPopupPanelVisible && visibleQuickPopupType === "battery" && quickPopupSurfaceReveal > 0.015
    readonly property var cachedQuickPopupTypes: [
        "time",
        "agenda",
        "weatherPanel",
        "search",
        "volume",
        "wifi",
        "brightness",
        "quickSettings",
        "settingsQuick",
        "notifications",
        "battery",
        "bluetooth",
        "wallpaperVisibility"
    ]
    readonly property var topBarCachedQuickPopupTypes: [
        "time",
        "search",
        "apps",
        "workspaces",
        "media",
        "system",
        "profile",
        "quickSettings",
        "settingsQuick"
    ]
    property real quickPopupSurfaceReveal: 0
    property real systemSheetOffsetY: 0
    property real systemSheetOffsetX: 0
    property bool systemSheetClosing: false
    readonly property int quickPopupLineCloseDuration: veloraTheme.motionEnabled ? Math.max(180, veloraTheme.motionPanelOut) : 1
    readonly property int notificationToastOpenDuration: veloraTheme.motionEnabled ? Math.max(240, veloraTheme.motionPanelIn) : 1
    readonly property int notificationToastCloseDuration: veloraTheme.motionEnabled ? Math.max(300, Math.round(quickPopupLineCloseDuration * 1.35)) : 1
    readonly property bool sideQuickPopupAttachedToBar: quickPopupVisible && sideQuickPopupPanelVisible && quickPopupTypeAttachedToBar(visibleQuickPopupType)
    readonly property int sideQuickPopupBridgeWidth: sideQuickPopupAttachedToBar && sideVisualizerMounted && barOnRight ? Math.max(popupFrameGap, sideQuickPopupBarClearance) : 0
    readonly property bool quickPopupJoinedToBar: sideQuickPopupAttachedToBar && (popupFrameGap <= 0 || sideQuickPopupBridgeWidth > 0)
    readonly property real quickPopupTransitionContrast: (quickPopupVisible && sideQuickPopupPanelVisible) ? (quickPopupSurfaceReveal < 0.98 ? 0.30 : 0.12) : 0

    function shellQuote(value) {
        return "'" + String(value || "").replace(/'/g, "'\"'\"'") + "'"
    }

    function noteAudioSignal(peak) {
        const value = Number(peak)
        if (isNaN(value) || value <= 0.003)
            return

        audioSignalRecentlyActive = true
        audioSignalHoldTimer.restart()
    }

    function wallpaperWaveSafeName(value) {
        return String(value || "eDP-1").replace(/[^A-Za-z0-9_]/g, "-")
    }

    function wallpaperWaveReadyPath(screenName) {
        if (!wallpaperWaveFrameDir || !wallpaperWaveToken)
            return ""
        return wallpaperWaveFrameDir + "/" + wallpaperWaveToken + "-" + wallpaperWaveSafeName(screenName) + ".ready"
    }

    function wallpaperWaveUrl(path) {
        const value = String(path || "")
        if (value.indexOf("file://") === 0)
            return value
        return value.length > 0 ? "file://" + value : ""
    }

    function randomizeWallpaperWaveDirection() {
        const directions = [
            [1, 0],
            [-1, 0],
            [0, 1],
            [0, -1],
            [1, 1],
            [1, -1],
            [-1, 1],
            [-1, -1]
        ]
        let next = Math.floor(Math.random() * directions.length)
        if (directions.length > 1 && next === wallpaperWaveLastDirection)
            next = (next + 1 + Math.floor(Math.random() * (directions.length - 1))) % directions.length

        wallpaperWaveLastDirection = next
        wallpaperWaveDirectionX = directions[next][0]
        wallpaperWaveDirectionY = directions[next][1]
        wallpaperWavePhase = Math.random() * Math.PI * 2
    }

    function prepareWallpaperWave(frameDir, token, durationMs, sourcePath, transitionType) {
        wallpaperWaveAnimation.stop()
        wallpaperWaveMounted = false
        wallpaperWaveFrameDir = String(frameDir || "")
        wallpaperWaveToken = String(token || "")
        wallpaperWaveSourcePath = String(sourcePath || "")
        wallpaperWaveTransition = transitionType === "grow" || transitionType === "outer" || transitionType === "fade"
            ? transitionType
            : "wave"
        wallpaperWaveDurationMs = Math.max(150, Math.min(3000, Number(durationMs) || 1000))
        wallpaperWaveProgress = 0
        randomizeWallpaperWaveDirection()
        wallpaperWaveMounted = wallpaperWaveFrameDir.length > 0 && wallpaperWaveToken.length > 0 && wallpaperWaveSourcePath.length > 0
    }

    function revealWallpaperWave(token) {
        if (!wallpaperWaveMounted || String(token || "") !== wallpaperWaveToken)
            return

        wallpaperWaveProgress = 0
        wallpaperWaveAnimation.restart()
    }

    function cancelWallpaperWave(token) {
        if (token && String(token) !== wallpaperWaveToken)
            return

        wallpaperWaveAnimation.stop()
        wallpaperWaveProgress = 0
        wallpaperWaveMounted = false
        wallpaperWaveFrameDir = ""
        wallpaperWaveToken = ""
        wallpaperWaveSourcePath = ""
        wallpaperWaveTransition = "wave"
    }

    function launchApp(command) {
        if (!command || command.length <= 0 || appLaunchProcess.running)
            return

        dismissTransientSurfaces()
        appLaunchCommand = command
        appLaunchProcess.running = true
    }

    function dismissTransientSurfaces() {
        closeQuickPopup()
        wallpaperSelectorOpen = false
        settingsPanelOpen = false
        closeWeatherTop()
        closeRightDashboard()
        closeLegacyLeftMenu()
        toggleTopWallpaperPopup(false, false)
    }

    function syncTopBarWindowGaps() {
        const target = topBarLayout ? "92,30,25,30" : "25,25,25,25"
        if (target === appliedWindowGaps && pendingWindowGaps.length <= 0)
            return

        pendingWindowGaps = target
        if (typeof windowGapProcess === "undefined" || windowGapProcess.running)
            return

        applyPendingWindowGaps()
    }

    function clearLyricsOverlay(reason) {
        lyricsAvailable = false
        lyricsTitle = ""
        lyricsArtist = ""
        lyricsLine = ""
        lyricsReason = String(reason || "")
        lyricsTimingMode = ""
        lyricsContextLines = []
        lyricsWords = []
        lyricsActiveIndex = -1
        lyricsPositionSeconds = 0
        lyricsDurationSeconds = 0
        lyricsGhostText = ""
        lyricsGhostSide = 0
        lyricsPhraseProgress = 1
    }

    function applyLyricsPayload(payload) {
        if (!payload || payload.ok !== true || !payload.words || payload.words.length <= 0) {
            clearLyricsOverlay(payload && payload.reason ? payload.reason : "no-lyrics")
            return
        }

        const oldPhrase = lyricsPhraseForWords(lyricsWords, lyricsActiveIndex, 0)
        const nextWords = payload.words.slice()
        const nextActiveIndex = Math.max(0, Math.min(nextWords.length - 1, Number(payload.activeIndex) || 0))
        const nextPhrase = lyricsPhraseForWords(nextWords, nextActiveIndex, 0)

        if (lyricsCinematicModeActive() && oldPhrase.text.length > 0 && nextPhrase.text.length > 0 && oldPhrase.text !== nextPhrase.text) {
            lyricsGhostText = oldPhrase.text
            lyricsGhostSide = oldPhrase.side
            lyricsPhraseAnimation.stop()
            lyricsPhraseProgress = 0
            lyricsPhraseAnimation.start()
        } else if (lyricsPhraseProgress < 1 && nextPhrase.text.length <= 0) {
            lyricsPhraseProgress = 1
        }

        lyricsAvailable = true
        lyricsTitle = String(payload.title || "")
        lyricsArtist = String(payload.artist || "")
        lyricsLine = String(payload.line || "")
        lyricsTimingMode = String(payload.timingMode || "")
        lyricsContextLines = Array.isArray(payload.contextLines) ? payload.contextLines.slice(0, 4) : [{ text: lyricsLine, active: true }]
        lyricsWords = nextWords
        lyricsActiveIndex = nextActiveIndex
        lyricsPositionSeconds = Number(payload.position) || 0
        lyricsDurationSeconds = Number(payload.duration) || 0
        lyricsReason = ""
    }

    function lyricsCinematicModeActive() {
        return topBarLayout && veloraTheme.lyricsCinematicEnabled && veloraTheme.lyricsLayoutMode === "two"
    }

    function lyricsWordText(value) {
        return String(value || "").replace(/\s+/g, " ").trim()
    }

    function lyricsPhraseChunksFor(words) {
        const chunks = []
        const source = Array.isArray(words) ? words : []
        var current = []
        var start = 0

        for (let i = 0; i < source.length; i += 1) {
            const word = lyricsWordText(source[i])
            if (word.length <= 0)
                continue

            if (current.length <= 0)
                start = i
            current.push(word)

            const punctuationBreak = /[,;:?!]$/.test(word)
            const longWord = word.length >= 9
            const maxChunk = longWord ? 2 : 3
            if (punctuationBreak || current.length >= maxChunk || i === source.length - 1) {
                chunks.push({
                    text: current.join(" "),
                    start: start,
                    end: i + 1,
                    index: chunks.length,
                    side: chunks.length % 2
                })
                current = []
            }
        }

        return chunks
    }

    function lyricsPhraseForWords(words, activeIndex, offset) {
        const chunks = lyricsPhraseChunksFor(words)
        if (chunks.length <= 0)
            return { text: "", start: 0, end: 0, index: 0, side: 0 }

        const active = Math.max(0, Math.min((Array.isArray(words) ? words.length : 1) - 1, Number(activeIndex) || 0))
        var chunkIndex = 0
        for (let i = 0; i < chunks.length; i += 1) {
            if (active >= chunks[i].start && active < chunks[i].end) {
                chunkIndex = i
                break
            }
        }

        chunkIndex = Math.max(0, Math.min(chunks.length - 1, chunkIndex + (Number(offset) || 0)))
        return chunks[chunkIndex]
    }

    function lyricsCurrentPhrase() {
        return lyricsPhraseForWords(lyricsWords, lyricsActiveIndex, 0)
    }

    function lyricsNextPhrase() {
        return lyricsPhraseForWords(lyricsWords, lyricsActiveIndex, 1)
    }

    function renderedLyricsWords() {
        const words = Array.isArray(lyricsWords) ? lyricsWords : []
        if (words.length <= 0)
            return []

        const active = Math.max(0, Math.min(words.length - 1, lyricsActiveIndex))
        const mode = (veloraTheme.lyricsLayoutMode === "two" || veloraTheme.lyricsLayoutMode === "four")
            ? "progressive"
            : (veloraTheme.lyricsLayoutMode === "simple" ? "current" : veloraTheme.lyricsRevealMode)
        let first = 0
        let last = words.length

        if (mode === "current") {
            first = active
            last = active + 1
        } else if (mode === "progressive") {
            last = active + 1
        }

        const visible = []
        for (let i = first; i < last; i += 1)
            visible.push({ text: words[i], sourceIndex: i })
        return visible
    }

    function lyricsBlockSplitStart(blockIndex, blockCount) {
        const words = Array.isArray(lyricsWords) ? lyricsWords : []
        const count = Math.max(1, Number(blockCount) || 1)
        const index = Math.max(0, Math.min(count - 1, Number(blockIndex) || 0))
        return Math.floor(words.length * index / count)
    }

    function lyricsBlockSplitEnd(blockIndex, blockCount) {
        const words = Array.isArray(lyricsWords) ? lyricsWords : []
        const count = Math.max(1, Number(blockCount) || 1)
        const index = Math.max(0, Math.min(count - 1, Number(blockIndex) || 0))
        return Math.floor(words.length * (index + 1) / count)
    }

    function renderedLyricsBlockWords(blockIndex, blockCount) {
        const visible = renderedLyricsWords()
        const start = lyricsBlockSplitStart(blockIndex, blockCount)
        const end = lyricsBlockSplitEnd(blockIndex, blockCount)
        const blockWords = []
        for (let i = 0; i < visible.length; i += 1) {
            const word = visible[i]
            const sourceIndex = Number(word.sourceIndex)
            if (sourceIndex >= start && sourceIndex < end)
                blockWords.push(word)
        }
        return blockWords
    }

    function renderedLyricsSideWords(side) {
        return renderedLyricsBlockWords(side === "right" ? 1 : 0, 2)
    }

    function lyricsWordColor(sourceIndex, blockIndex) {
        const useBlockStyle = blockIndex !== undefined && Number(blockIndex) >= 0
        const blockMode = useBlockStyle ? veloraTheme.lyricsBlockColorMode(blockIndex) : "inherit"
        const colorMode = blockMode === "inherit" ? veloraTheme.lyricsColorMode : blockMode
        if (colorMode === "manual")
            return useBlockStyle && blockMode !== "inherit" ? veloraTheme.lyricsBlockManualColor(blockIndex) : veloraTheme.lyricsManualColor
        if (colorMode === "palette" && veloraTheme.lyricsPalette && veloraTheme.lyricsPalette.length > 0)
            return veloraTheme.lyricsPalette[Math.abs(Number(sourceIndex) || 0) % veloraTheme.lyricsPalette.length]
        return veloraTheme.lyricsPywalColor
    }

    function lyricsClampUnit(value) {
        const n = Number(value)
        if (isNaN(n))
            return 0
        return Math.max(0, Math.min(1, n))
    }

    function lyricsMixColor(a, b, amount, opacity) {
        const t = lyricsClampUnit(amount)
        const o = opacity === undefined ? (a.a + (b.a - a.a) * t) : lyricsClampUnit(opacity)
        return Qt.rgba(
            lyricsClampUnit(a.r + (b.r - a.r) * t),
            lyricsClampUnit(a.g + (b.g - a.g) * t),
            lyricsClampUnit(a.b + (b.b - a.b) * t),
            o
        )
    }

    function lyricsTextureNoise(sourceIndex) {
        const seed = Math.sin((Number(sourceIndex) + 1) * 12.9898) * 43758.5453
        return seed - Math.floor(seed)
    }

    function lyricsMaterialTarget(red, green, blue, alpha, texture) {
        return Qt.rgba(
            lyricsClampUnit(red + texture),
            lyricsClampUnit(green + texture),
            lyricsClampUnit(blue + texture),
            lyricsClampUnit(alpha)
        )
    }

    function lyricsMaterialColor(baseColor, sourceIndex, active) {
        const mode = veloraTheme.lyricsMaterialMode
        const intensity = lyricsClampUnit(veloraTheme.lyricsMaterialIntensity)
        const noise = lyricsTextureNoise(sourceIndex)
        const texture = (noise - 0.5) * 0.18 * intensity
        let result = baseColor

        if (mode === "cloud") {
            const target = lyricsMaterialTarget(0.72, 0.84, 0.98, baseColor.a, texture)
            result = lyricsMixColor(result, target, 0.34 + intensity * 0.42, baseColor.a)
        } else if (mode === "glass") {
            const target = lyricsMaterialTarget(0.88, 0.95, 1.0, baseColor.a, texture * 0.65)
            result = lyricsMixColor(result, target, 0.28 + intensity * 0.50, baseColor.a)
        } else if (mode === "metal") {
            const highlight = noise > 0.52 ? 0.80 : 0.42
            const target = lyricsMaterialTarget(highlight, highlight + 0.04, highlight + 0.10, baseColor.a, texture * 1.15)
            result = lyricsMixColor(result, target, 0.22 + intensity * 0.48, baseColor.a)
        } else if (mode === "sky") {
            const target = lyricsMaterialTarget(0.50, 0.68, 0.90, baseColor.a, texture * 0.80)
            result = lyricsMixColor(result, target, 0.28 + intensity * 0.44, baseColor.a)
        }

        if (veloraTheme.lyricsFogEnabled) {
            const fog = lyricsClampUnit(veloraTheme.lyricsFogIntensity)
            const target = Qt.rgba(0.68, 0.78, 0.90, result.a)
            result = lyricsMixColor(result, target, fog * (active ? 0.26 : 0.38), result.a)
        }

        return result
    }

    function lyricsRenderedWordOpacity(active) {
        let opacity = active ? 1.0 : 0.46
        const mode = veloraTheme.lyricsMaterialMode
        if (mode === "glass")
            opacity *= 1 - lyricsClampUnit(veloraTheme.lyricsMaterialIntensity) * 0.14
        else if (mode === "cloud" || mode === "sky")
            opacity *= 1 - lyricsClampUnit(veloraTheme.lyricsMaterialIntensity) * 0.07

        if (veloraTheme.lyricsFogEnabled)
            opacity *= 1 - lyricsClampUnit(veloraTheme.lyricsFogIntensity) * (active ? 0.18 : 0.26)

        return Math.max(active ? 0.48 : 0.18, Math.min(1, opacity))
    }

    function lyricsOutlineColor(active) {
        if (veloraTheme.lyricsDepthEnabled) {
            const depth = lyricsClampUnit(veloraTheme.lyricsDepthIntensity)
            const alpha = (active ? 0.18 : 0.12) + depth * (active ? 0.24 : 0.16)
            return Qt.rgba(0.05, 0.12, 0.20, alpha)
        }
        return veloraTheme.themeMode === "dark" ? Qt.rgba(0, 0, 0, 0.55) : Qt.rgba(0, 0, 0, 0.28)
    }

    function normalizedLyricsRepeatWord(value) {
        return String(value || "")
            .toLowerCase()
            .replace(/[^0-9a-zà-öø-ÿ]+/g, "")
            .replace(/(.)\1+/g, "$1")
    }

    function lyricsWordScale(sourceIndex) {
        const words = Array.isArray(lyricsWords) ? lyricsWords : []
        const index = Math.max(0, Math.min(words.length - 1, Number(sourceIndex) || 0))
        const current = normalizedLyricsRepeatWord(words[index])
        if (!current)
            return 1

        let repeat = 0
        for (let i = index - 1; i >= 0; i -= 1) {
            if (normalizedLyricsRepeatWord(words[i]) !== current)
                break
            repeat += 1
        }
        return 1 + Math.min(0.28, repeat * 0.08)
    }

    function lyricsBlockPositionX(panelWidth, blockIndex) {
        if (blockIndex === 1)
            return Math.round(Math.max(0, Math.min(panelWidth - 24, panelWidth * veloraTheme.lyricsSecondPositionX / 100)))
        if (blockIndex === 2)
            return Math.round(Math.max(0, Math.min(panelWidth - 24, panelWidth * veloraTheme.lyricsThirdPositionX / 100)))
        if (blockIndex === 3)
            return Math.round(Math.max(0, Math.min(panelWidth - 24, panelWidth * veloraTheme.lyricsFourthPositionX / 100)))
        return Math.round(Math.max(0, Math.min(panelWidth - 24, panelWidth * veloraTheme.lyricsPositionX / 100)))
    }

    function lyricsBlockPositionY(panelHeight, blockIndex) {
        if (blockIndex === 1)
            return Math.round(Math.max(0, Math.min(panelHeight - 24, panelHeight * veloraTheme.lyricsSecondPositionY / 100)))
        if (blockIndex === 2)
            return Math.round(Math.max(0, Math.min(panelHeight - 24, panelHeight * veloraTheme.lyricsThirdPositionY / 100)))
        if (blockIndex === 3)
            return Math.round(Math.max(0, Math.min(panelHeight - 24, panelHeight * veloraTheme.lyricsFourthPositionY / 100)))
        return Math.round(Math.max(0, Math.min(panelHeight - 24, panelHeight * veloraTheme.lyricsPositionY / 100)))
    }

    function lyricsBlockWidth(panelWidth, blockIndex) {
        const x = lyricsBlockPositionX(panelWidth, blockIndex)
        if (veloraTheme.lyricsLayoutMode === "four")
            return Math.max(140, panelWidth * 0.32)
        if (blockIndex === 0 && veloraTheme.lyricsLayoutMode === "two")
            return Math.max(160, panelWidth * 0.42)
        return Math.max(160, panelWidth - x - 24)
    }

    function lyricsBlockGlowEnabled(blockIndex) {
        if (blockIndex === undefined || Number(blockIndex) < 0)
            return veloraTheme.lyricsGlowEnabled
        return veloraTheme.lyricsBlockGlowEnabled(blockIndex)
    }

    function lyricsBlockGlowIntensity(blockIndex) {
        if (blockIndex === undefined || Number(blockIndex) < 0)
            return veloraTheme.lyricsGlowIntensity
        return veloraTheme.lyricsBlockGlowIntensity(blockIndex)
    }

    function openLyricsMaskEditor() {
        veloraTheme.applyLyricsMaskSettings(true, veloraTheme.lyricsMaskBrushSize, veloraTheme.lyricsMaskData, true)
        lyricsMaskEditorPoints = []
        lyricsMaskEditorOpen = true
        settingsPanelOpen = false
    }

    function closeLyricsMaskEditor() {
        lyricsMaskEditorPoints = []
        lyricsMaskEditorOpen = false
    }

    function normalizedMaskPoint(item, x, y) {
        return {
            x: Math.max(0, Math.min(1, Number(x) / Math.max(1, item.width))),
            y: Math.max(0, Math.min(1, Number(y) / Math.max(1, item.height)))
        }
    }

    function appendLyricsMaskPoint(item, x, y) {
        const next = normalizedMaskPoint(item, x, y)
        const points = Array.isArray(lyricsMaskEditorPoints) ? lyricsMaskEditorPoints.slice() : []
        const last = points.length > 0 ? points[points.length - 1] : null
        if (last) {
            const minDistance = Math.max(0.0025, veloraTheme.lyricsMaskBrushSize / Math.max(1, Math.max(item.width, item.height)) * 0.20)
            const dx = next.x - last.x
            const dy = next.y - last.y
            if (Math.sqrt(dx * dx + dy * dy) < minDistance)
                return
        }
        if (points.length >= 180)
            points[points.length - 1] = next
        else
            points.push(next)
        lyricsMaskEditorPoints = points
    }

    function commitLyricsMaskStroke() {
        const points = Array.isArray(lyricsMaskEditorPoints) ? lyricsMaskEditorPoints.slice() : []
        if (points.length < 2) {
            lyricsMaskEditorPoints = []
            return
        }

        let strokes = []
        try {
            strokes = JSON.parse(veloraTheme.lyricsMaskData || "[]")
        } catch (e) {
            strokes = []
        }
        if (!Array.isArray(strokes))
            strokes = []
        strokes.push({ brush: veloraTheme.lyricsMaskBrushSize, points: points })
        if (strokes.length > 14)
            strokes = strokes.slice(strokes.length - 14)
        veloraTheme.applyLyricsMaskSettings(true, veloraTheme.lyricsMaskBrushSize, JSON.stringify(strokes), true)
        lyricsMaskEditorPoints = []
    }

    function pollLyricsNow() {
        if (!lyricsServiceWanted) {
            clearLyricsOverlay("disabled")
            return
        }

        if (!lyricsQuery.running)
            lyricsQuery.running = true
    }

    function lyricsPollIntervalMs() {
        if (!lyricsAvailable && lyricsReason.length > 0 && lyricsReason !== "between-lines")
            return topBarLayout ? 700 : 360

        return topBarLayout ? 180 : 110
    }

    function applyPendingWindowGaps() {
        if (pendingWindowGaps.length <= 0 || typeof windowGapProcess === "undefined")
            return

        const target = pendingWindowGaps
        pendingWindowGaps = ""
        appliedWindowGaps = target
        windowGapProcess.command = ["hyprctl", "keyword", "general:gaps_out", target]
        windowGapProcess.running = true
    }

    function notificationCleanText(value) {
        return String(value || "").replace(/<[^>]*>/g, "").replace(/&nbsp;/g, " ").trim()
    }

    function notificationField(notification, keys, fallback) {
        if (!notification)
            return fallback || ""

        for (let i = 0; i < keys.length; ++i) {
            const value = notification[keys[i]]
            if (value !== undefined && value !== null && String(value).trim().length > 0)
                return notificationCleanText(value)
        }

        return fallback || ""
    }

    function notificationIconKey(appName, title, body, iconName) {
        const value = String((appName || "") + " " + (title || "") + " " + (body || "") + " " + (iconName || "")).toLowerCase()
        if (value.indexOf("whatsapp") >= 0 || value.indexOf("whats app") >= 0 || value.indexOf("web.whatsapp") >= 0 || value.indexOf("com.whatsapp") >= 0)
            return "whatsapp"
        if (value.indexOf("discord") >= 0 || value.indexOf("vesktop") >= 0)
            return "discord"
        if (value.indexOf("spotify") >= 0)
            return "spotify"
        if (value.indexOf("telegram") >= 0)
            return "telegram"
        if (value.indexOf("firefox") >= 0 || value.indexOf("zen") >= 0 || value.indexOf("browser") >= 0)
            return "browser"
        if (value.indexOf("velora") >= 0)
            return "velora"
        return "bell"
    }

    function notificationTimeText(notification) {
        const value = notificationField(notification, ["timeText", "time", "timestamp"], "")
        if (value.length > 0) {
            const parsed = new Date(value)
            if (!isNaN(parsed.getTime()))
                return Qt.formatDateTime(parsed, "HH:mm")
            return value
        }

        return Qt.formatTime(new Date(), "HH:mm")
    }

    function notificationActionsJson(notification) {
        const output = []
        const actions = notification && notification.actions ? notification.actions : []
        for (let i = 0; i < actions.length; ++i) {
            const action = actions[i]
            if (!action)
                continue
            output.push({
                identifier: String(action.identifier || ""),
                text: String(action.text || action.identifier || "Ação")
            })
        }
        return JSON.stringify(output)
    }

    function normalizeNotification(notification) {
        const summary = notificationField(notification, ["summary", "title"], "")
        const body = notificationField(notification, ["body"], "")
        const appName = notificationField(notification, ["appName", "app", "app_name", "application", "desktopEntry", "desktop_entry", "app-name"], "Sistema")
        const iconName = notificationField(notification, ["appIcon", "app_icon", "icon", "image", "imagePath", "desktopEntry", "desktop_entry"], "")
        const desktopEntry = notificationField(notification, ["desktopEntry", "desktop_entry"], "")
        const title = summary.length > 0 ? summary : (body.length > 0 ? body : "Notificação")
        let id = notificationField(notification, ["id", "ID", "notificationId", "notification_id"], "")
        if (id.length <= 0)
            id = appName + "|" + title + "|" + body

        return {
            id: String(id),
            app: appName,
            summary: title,
            body: summary.length > 0 ? body : "",
            timeText: notificationTimeText(notification),
            iconKey: notificationIconKey(appName, title, body, iconName),
            appIcon: iconName,
            desktopEntry: desktopEntry,
            urgency: notification && notification.urgency !== undefined ? Number(notification.urgency) : 1,
            resident: Boolean(notification && notification.resident),
            actionsJson: notificationActionsJson(notification)
        }
    }

    function upsertNotificationHistory(notification) {
        const item = normalizeNotification(notification)
        if (item.summary.length <= 0 && item.body.length <= 0)
            return

        const tracked = Object.assign({}, trackedNotificationObjects)
        tracked[item.id] = notification
        trackedNotificationObjects = tracked

        for (let i = 0; i < notificationHistoryModel.count; ++i) {
            const current = notificationHistoryModel.get(i)
            if ((item.id.length > 0 && current.id === item.id)
                    || (current.app === item.app && current.summary === item.summary && current.body === item.body)) {
                notificationHistoryModel.set(i, item)
                if (i > 0)
                    notificationHistoryModel.move(i, 0, 1)
                return
            }
        }

        notificationHistoryModel.insert(0, item)
        while (notificationHistoryModel.count > 24)
            notificationHistoryModel.remove(notificationHistoryModel.count - 1)
    }

    function removeNotificationHistoryById(notificationId) {
        const id = String(notificationId || "")
        if (id.length <= 0)
            return

        for (let i = notificationHistoryModel.count - 1; i >= 0; --i) {
            if (notificationHistoryModel.get(i).id === id)
                notificationHistoryModel.remove(i)
        }

        const tracked = Object.assign({}, trackedNotificationObjects)
        delete tracked[id]
        trackedNotificationObjects = tracked
    }

    function clearNotificationHistory() {
        notificationHistoryModel.clear()
        trackedNotificationObjects = ({})
    }

    function notificationHistoryItem(notificationId) {
        const id = String(notificationId || "")
        for (let i = 0; i < notificationHistoryModel.count; ++i) {
            const item = notificationHistoryModel.get(i)
            if (String(item.id || "") === id)
                return item
        }
        return null
    }

    function queueNotificationDismiss(commandArguments) {
        const next = notificationDismissQueue.slice()
        next.push(commandArguments)
        notificationDismissQueue = next
        startNextNotificationDismiss()
    }

    function startNextNotificationDismiss() {
        if (notificationHistoryDismissProcess.running || notificationDismissQueue.length <= 0)
            return
        const next = notificationDismissQueue.slice()
        notificationHistoryDismissProcess.command = next.shift()
        notificationDismissQueue = next
        notificationHistoryDismissProcess.running = true
    }

    function launchNotificationApplication(item) {
        if (!item)
            return false

        const desktopNeedle = String(item.desktopEntry || "").toLowerCase().replace(/\.desktop$/, "")
        const appNeedle = String(item.app || "").toLowerCase().trim()
        const applications = DesktopEntries.applications.values || []
        let fallback = null

        for (let i = 0; i < applications.length; ++i) {
            const entry = applications[i]
            if (!entry || entry.noDisplay)
                continue
            const entryId = String(entry.id || "").toLowerCase().replace(/\.desktop$/, "")
            const entryName = String(entry.name || "").toLowerCase()
            const entryGeneric = String(entry.genericName || "").toLowerCase()
            if (desktopNeedle.length > 0 && entryId === desktopNeedle) {
                entry.execute()
                return true
            }
            if (!fallback && appNeedle.length > 0
                    && (entryName === appNeedle || entryName.indexOf(appNeedle) >= 0 || appNeedle.indexOf(entryName) >= 0
                        || entryGeneric.indexOf(appNeedle) >= 0))
                fallback = entry
        }

        if (fallback) {
            fallback.execute()
            return true
        }

        const body = String(item.body || "")
        const pathMatch = body.match(/(\/[^\n]+\.(?:png|jpe?g|webp|gif|pdf))/i)
        if (pathMatch && pathMatch[1]) {
            launchApp("xdg-open " + shellQuote(pathMatch[1].trim()))
            return true
        }
        return false
    }

    function dismissNotificationHistory(notificationId) {
        const id = String(notificationId || "")
        const notification = trackedNotificationObjects[id]
        if (notification) {
            try { notification.dismiss() } catch (error) {}
        } else if (/^[0-9]+$/.test(id)) {
            queueNotificationDismiss(["makoctl", "dismiss", "-n", id])
        }
        removeNotificationHistoryById(id)
    }

    function invokeNotificationHistoryAction(notificationId, actionIdentifier) {
        const id = String(notificationId || "")
        const wanted = String(actionIdentifier || "default")
        const notification = trackedNotificationObjects[id]
        let invoked = false

        if (notification && notification.actions) {
            for (let i = 0; i < notification.actions.length; ++i) {
                const action = notification.actions[i]
                if (action && String(action.identifier || "") === wanted) {
                    try {
                        action.invoke()
                        invoked = true
                    } catch (error) {}
                    break
                }
            }
        }

        const item = notificationHistoryItem(id)
        if (!invoked && wanted === "default")
            invoked = launchNotificationApplication(item)

        if (invoked && (!item || !item.resident))
            dismissNotificationHistory(id)
        return invoked
    }

    function clearTrackedNotificationHistory() {
        const tracked = trackedNotificationObjects
        const ids = Object.keys(tracked)
        for (let i = 0; i < ids.length; ++i) {
            const notification = tracked[ids[i]]
            if (notification) {
                try { notification.dismiss() } catch (error) {}
            }
        }
        clearNotificationHistory()
        queueNotificationDismiss(["makoctl", "dismiss", "--all"])
    }

    function notificationIconSurfaceColor(iconKey) {
        if (iconKey === "whatsapp")
            return Qt.rgba(46 / 255, 168 / 255, 101 / 255, 0.82)
        if (iconKey === "discord")
            return Qt.rgba(112 / 255, 132 / 255, 255 / 255, 0.82)
        if (iconKey === "spotify")
            return Qt.rgba(34 / 255, 197 / 255, 94 / 255, 0.82)
        if (iconKey === "telegram")
            return Qt.rgba(56 / 255, 164 / 255, 220 / 255, 0.82)
        if (iconKey === "browser")
            return Qt.rgba(69 / 255, 160 / 255, 245 / 255, 0.82)
        if (iconKey === "velora")
            return veloraTheme.alpha(veloraTheme.accentPrimary, 0.82)
        return veloraTheme.alpha(veloraTheme.accentTertiary, 0.78)
    }

    function showNotificationToast(notification) {
        if (shellSuppressedByFullscreen)
            return

        const item = normalizeNotification(notification)

        notificationToastTitle = item.summary
        notificationToastBody = item.body
        notificationToastApp = item.app
        notificationToastIconKey = item.iconKey
        notificationToastSerial += 1
        notificationToastUnmountTimer.stop()
        notificationToastMounted = true
        notificationToastVisible = true
        notificationToastHideTimer.toastSerial = notificationToastSerial
        notificationToastHideTimer.restart()
    }

    function playNotificationSound() {
        if (notificationSoundProcess.running)
            notificationSoundProcess.running = false

        notificationSoundProcess.command = [
            "bash",
            "-lc",
            "sound=" + shellQuote(notificationSoundPath) + "; " +
            "if [ -f \"$sound\" ]; then " +
            "if command -v pw-play >/dev/null 2>&1; then pw-play \"$sound\" >/dev/null 2>&1; " +
            "elif command -v paplay >/dev/null 2>&1; then paplay \"$sound\" >/dev/null 2>&1; " +
            "elif command -v mpv >/dev/null 2>&1; then mpv --no-video --really-quiet \"$sound\" >/dev/null 2>&1; " +
            "fi; fi"
        ]
        notificationSoundProcess.running = true
    }

    function hideNotificationToast() {
        notificationToastHideTimer.stop()
        notificationToastVisible = false
        notificationToastUnmountTimer.toastSerial = notificationToastSerial
        notificationToastUnmountTimer.restart()
    }

    onShellSuppressedByFullscreenChanged: {
        if (!shellSuppressedByFullscreen)
            return

        closeQuickPopup()
        closeWeatherTop()
        hideNotificationToast()
        wallpaperSelectorOpen = false
        wallpaperSelectorWindowOpen = false
        settingsPanelOpen = false
        settingsPanelWindowOpen = false
        rightDashboardOpen = false
        leftMenuOpen = false
        leftMediaWindowOpen = false
        toggleTopWallpaperPopup(false, false)
    }

    Timer {
        id: notificationToastHideTimer

        property int toastSerial: -1

        interval: 4300
        repeat: false
        onTriggered: if (toastSerial === root.notificationToastSerial) root.hideNotificationToast()
    }

    Timer {
        id: notificationToastUnmountTimer

        property int toastSerial: -1

        interval: Math.max(veloraTheme.motionUnmountDelay, root.notificationToastCloseDuration + 160)
        repeat: false
        onTriggered: if (toastSerial === root.notificationToastSerial && !root.notificationToastVisible) root.notificationToastMounted = false
    }

    ListModel {
        id: notificationHistoryModel
    }

    SequentialAnimation {
        id: layoutSwitchAnimation

        NumberAnimation {
            target: root
            property: "layoutSwitchOpacity"
            to: 0.18
            duration: veloraTheme.motionEnabled ? 95 : 1
            easing.type: Easing.OutCubic
        }

        ScriptAction {
            script: root.applyPendingLayoutSwitch()
        }

        PauseAnimation {
            duration: veloraTheme.motionEnabled ? 18 : 1
        }

        NumberAnimation {
            target: root
            property: "layoutSwitchOpacity"
            to: 1
            duration: veloraTheme.motionEnabled ? 210 : 1
            easing.type: Easing.OutCubic
        }
    }

    function clockAlertCommand(title, message) {
        const sound = "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"
        return "title=" + shellQuote(title || "Velora") + "; body=" + shellQuote(message || "Clock alert") + "; sound=" + shellQuote(sound) + "; " +
            "notify-send -a Velora -u critical -t 12000 \"$title\" \"$body\" >/dev/null 2>&1 || true; " +
            "if [ -f \"$sound\" ]; then " +
            "for i in 1 2 3; do " +
            "if command -v pw-play >/dev/null 2>&1; then pw-play \"$sound\" >/dev/null 2>&1; " +
            "elif command -v paplay >/dev/null 2>&1; then paplay \"$sound\" >/dev/null 2>&1; " +
            "elif command -v mpv >/dev/null 2>&1; then mpv --no-video --really-quiet \"$sound\" >/dev/null 2>&1; " +
            "fi; sleep 0.18; done; fi"
    }

    function sendClockNotification(message, title) {
        if (leftClockNotifyProcess.running)
            leftClockNotifyProcess.running = false
        leftClockNotifyProcess.command = ["bash", "-lc", clockAlertCommand(title || "Velora", message)]
        leftClockNotifyProcess.running = true
    }

    QtObject {
        id: leftClockState

        property date currentDate: new Date()
        property var alarms: [
            { time: "07:00", detail: "Weekday", enabled: true },
            { time: "08:30", detail: "Weekend", enabled: true },
            { time: "22:00", detail: "Daily", enabled: true }
        ]
        property string lastAlarmMinute: ""
        property int timerSeconds: 1800
        property int timerRemaining: 1800
        property bool timerRunning: false

        function alarmAt(index) {
            if (index >= 0 && index < alarms.length)
                return alarms[index]
            return { time: "07:00", detail: "", enabled: false }
        }

        function replaceAlarms(next) {
            alarms = next.slice()
            lastAlarmMinute = ""
        }

        function setAlarmEnabled(index, enabled) {
            if (index < 0 || index >= alarms.length)
                return
            var next = alarms.slice()
            var item = Object.assign({}, next[index])
            item.enabled = enabled
            next[index] = item
            replaceAlarms(next)
        }

        function addAlarm() {
            var d = new Date(currentDate.getTime() + 60 * 60 * 1000)
            var next = alarms.slice()
            next.push({
                time: String(d.getHours()).padStart(2, "0") + ":" + String(d.getMinutes()).padStart(2, "0"),
                detail: "Custom",
                enabled: true
            })
            replaceAlarms(next)
        }

        function shiftAlarmMinutes(index, delta) {
            if (index < 0 || index >= alarms.length)
                return
            var item = Object.assign({}, alarms[index])
            var parts = String(item.time || "07:00").split(":")
            var total = ((parseInt(parts[0]) || 0) * 60 + (parseInt(parts[1]) || 0) + delta + 1440) % 1440
            item.time = String(Math.floor(total / 60)).padStart(2, "0") + ":" + String(total % 60).padStart(2, "0")
            var next = alarms.slice()
            next[index] = item
            replaceAlarms(next)
        }

        function removeAlarm(index) {
            if (alarms.length <= 1 || index < 0 || index >= alarms.length)
                return
            var next = alarms.slice()
            next.splice(index, 1)
            replaceAlarms(next)
        }

        function checkAlarms() {
            const hhmm = Qt.formatTime(currentDate, "HH:mm")
            const dayKey = Qt.formatDate(currentDate, "yyyyMMdd") + "-" + hhmm
            for (var i = 0; i < alarms.length; ++i) {
                const alarm = alarmAt(i)
                if (alarm.enabled && hhmm === alarm.time && lastAlarmMinute !== dayKey) {
                    lastAlarmMinute = dayKey
                    root.sendClockNotification("Alarm " + alarm.time, "Velora alarm")
                    break
                }
            }
        }

        function adjustTimerSeconds(delta) {
            const next = Math.max(60, Math.min(24 * 3600, timerSeconds + delta))
            timerSeconds = next
            if (!timerRunning)
                timerRemaining = next
            else
                timerRemaining = Math.max(1, Math.min(24 * 3600, timerRemaining + delta))
        }

        function setTimerPreset(seconds) {
            timerSeconds = seconds
            timerRemaining = seconds
            timerRunning = false
        }

        function toggleTimer() {
            if (timerRemaining <= 0)
                timerRemaining = timerSeconds
            timerRunning = !timerRunning
        }

        function resetTimer() {
            timerRunning = false
            timerRemaining = timerSeconds
        }

        function finishTimer() {
            timerRunning = false
            timerRemaining = 0
            root.sendClockNotification("Timer finished", "Velora timer")
        }

    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            leftClockState.currentDate = new Date()
            leftClockState.checkAlarms()
        }
    }

    Timer {
        interval: 1000
        running: leftClockState.timerRunning
        repeat: true
        onTriggered: {
            if (leftClockState.timerRemaining > 1)
                leftClockState.timerRemaining -= 1
            else
                leftClockState.finishTimer()
        }
    }

    Process {
        id: leftClockNotifyProcess

        running: false
        command: ["bash", "-lc", "true"]
        onExited: running = false
    }

    Process {
        id: notificationSoundProcess

        running: false
        command: ["bash", "-lc", "true"]
        onExited: running = false
    }

    Process {
        id: notificationHistoryDismissProcess

        running: false
        command: ["true"]
        onExited: {
            running = false
            Qt.callLater(root.startNextNotificationDismiss)
        }
    }

    Process {
        id: appLaunchProcess

        running: false
        command: ["bash", "-lc", root.appLaunchCommand]
        onExited: running = false
    }

    FileView {
        id: infiniteDesktopFeatureFile

        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/velora-shell/infinite-desktop"
        preload: true
        watchChanges: true
        printErrors: false

        onLoaded: root.updateInfiniteDesktopFeature()
        onTextChanged: root.updateInfiniteDesktopFeature()
        onLoadFailed: root.infiniteDesktopCommand = ""
    }

    Process {
        id: infiniteDesktopStateSync

        running: false
        command: root.infiniteDesktopCommand.length > 0
            ? [root.infiniteDesktopCommand, "sync-state"]
            : ["true"]

        stdout: SplitParser {
            onRead: function(data) {
                root.applyInfiniteDesktopState(data)
            }
        }

        onExited: {
            running = false
            root.infiniteDesktopStateReady = root.infiniteDesktopCommand.length > 0
        }
    }

    FileView {
        id: infiniteDesktopStateFile

        path: root.infiniteDesktopStateReady ? root.infiniteDesktopStatePath : ""
        preload: root.infiniteDesktopStateReady
        watchChanges: true
        printErrors: false

        onLoaded: root.applyInfiniteDesktopState(text())
        onTextChanged: root.applyInfiniteDesktopState(text())
    }

    Process {
        id: lyricsQuery

        running: false
        command: [root.lyricsStateScript, "status", "--lead", (veloraTheme.lyricsSyncOffsetMs / 1000).toFixed(3)]

        stdout: SplitParser {
            onRead: function(data) {
                const line = String(data || "").trim()
                if (line.length <= 0)
                    return

                try {
                    root.applyLyricsPayload(JSON.parse(line))
                } catch (error) {
                    root.clearLyricsOverlay("parse-error")
                }
            }
        }

        onExited: running = false
    }

    NumberAnimation {
        id: lyricsPhraseAnimation

        target: root
        property: "lyricsPhraseProgress"
        from: 0
        to: 1
        duration: veloraTheme.motionEnabled ? 260 : 1
        easing.type: Easing.OutCubic
    }

    Timer {
        id: lyricsPollTimer

        interval: root.lyricsPollIntervalMs()
        repeat: true
        running: root.lyricsServiceWanted
        triggeredOnStart: true
        onTriggered: root.pollLyricsNow()
    }

    Connections {
        target: veloraTheme
        function onLyricsEnabledChanged() {
            if (root.lyricsServiceWanted)
                root.pollLyricsNow()
            else if (!root.lyricsServiceWanted)
                root.clearLyricsOverlay("disabled")
        }
    }

    Process {
        id: windowGapProcess

        running: false
        command: ["hyprctl", "keyword", "general:gaps_out", "25,25,25,25"]
        onExited: {
            running = false
            root.applyPendingWindowGaps()
        }
    }

    Process {
        id: topWallpaperScan

        running: false
        property var tmp: []
        property bool sawEnd: false
        property string preferredKey: ""
        command: [root.topWallpaperScanScript, "--json"]

        onStarted: {
            tmp = []
            sawEnd = false
            const currentKey = root.topWallpaperEntryKey(root.topWallpaperEntry(0))
            preferredKey = root.topWallpaperAllEntries.length > root.topWallpaperFallbackEntries.length
                ? currentKey
                : root.topWallpaperActiveKey
        }

        stdout: SplitParser {
            onRead: function(data) {
                const line = String(data).trim()
                if (!line || line === "BEGIN")
                    return

                if (line === "END") {
                    topWallpaperScan.sawEnd = true
                    if (topWallpaperScan.tmp.length > 0) {
                        root.topWallpaperAllEntries = topWallpaperScan.tmp.slice()
                        root.recomputeTopWallpaperEntries(topWallpaperScan.preferredKey)
                    }
                    return
                }

                try {
                    const entry = root.normalizeTopWallpaperEntry(JSON.parse(line))
                    if (entry.path && entry.path.length > 0)
                        topWallpaperScan.tmp.push(entry)
                } catch (error) {
                    // Ignore malformed records while retaining every valid entry.
                }
            }
        }

        onExited: {
            running = false
            root.topWallpaperLibraryReady = true
            if (!sawEnd && tmp.length > 0) {
                root.topWallpaperAllEntries = tmp.slice()
                root.recomputeTopWallpaperEntries(preferredKey)
            }
            command = [root.topWallpaperScanScript, "--json"]
        }
    }

    Process {
        id: topWallpaperLibraryLoad

        running: false
        command: [root.topWallpaperLibraryStateScript, "get"]

        stdout: SplitParser {
            onRead: function(data) {
                try {
                    const payload = JSON.parse(String(data).trim() || "{}")
                    root.topWallpaperFavorites = Array.isArray(payload.favorites) ? payload.favorites : []
                    root.topWallpaperHidden = Array.isArray(payload.hidden) ? payload.hidden : []
                    root.recomputeTopWallpaperEntries(root.topWallpaperActiveKey)
                } catch (error) {
                    root.topWallpaperFavorites = []
                    root.topWallpaperHidden = []
                }
            }
        }

        onExited: running = false
    }

    Process {
        id: topWallpaperActiveLoad

        running: false
        command: [root.topWallpaperLibraryStateScript, "active"]

        stdout: SplitParser {
            onRead: function(data) {
                try {
                    const payload = JSON.parse(String(data).trim() || "{}")
                    root.topWallpaperActiveKey = String(payload.key || "")
                    root.recomputeTopWallpaperEntries(root.topWallpaperActiveKey)
                } catch (error) {
                    root.topWallpaperActiveKey = ""
                }
            }
        }

        onExited: running = false
    }

    Timer {
        id: topWallpaperLibrarySaveTimer

        interval: 160
        repeat: false
        onTriggered: root.flushTopWallpaperLibraryState()
    }

    Process {
        id: topWallpaperLibrarySave

        running: false
        command: [root.topWallpaperLibraryStateScript, "set", "{}"]
        onExited: {
            running = false
            if (root.topWallpaperLibrarySaveQueued)
                topWallpaperLibrarySaveTimer.restart()
        }
    }

    Process {
        id: topWallpaperApply

        running: false
        command: [root.topWallpaperApplyScript, "static", ""]
        onExited: function(exitCode, exitStatus) {
            running = false
            if (exitCode === 0 && root.topWallpaperApplyingEntry) {
                root.topWallpaperActiveKey = root.topWallpaperEntryKey(root.topWallpaperApplyingEntry)
                root.topWallpaperErrorMessage = ""
                root.topWallpaperApplyingEntry = null
                if (root.topWallpaperPopupOpen)
                    root.toggleTopWallpaperPopup(false, false)
            } else if (exitCode !== 0) {
                root.topWallpaperApplyingEntry = null
                root.topWallpaperErrorMessage = "Não foi possível aplicar este wallpaper."
            }
            if (root.topWallpaperPopupOpen && exitCode === 0)
                topWallpaperPreloadRefreshTimer.restart()
        }
    }

    Process {
        id: topWallpaperPreload

        running: false
        command: [root.topWallpaperApplyScript, "__transition-preload-current"]
        onExited: running = false
    }

    Process {
        id: topWallpaperPreloadStop

        running: false
        command: [root.topWallpaperApplyScript, "__transition-preload-stop"]
        onExited: running = false
    }

    Timer {
        id: topWallpaperPreloadRefreshTimer

        interval: 1100
        repeat: false
        onTriggered: {
            if (root.topWallpaperPopupOpen && !topWallpaperPreload.running) {
                topWallpaperPreload.command = [root.topWallpaperApplyScript, "__transition-preload-current"]
                topWallpaperPreload.running = true
            }
        }
    }

    Timer {
        id: topWallpaperPreloadStopTimer

        interval: 1600
        repeat: false
        onTriggered: {
            if (!root.topWallpaperPopupOpen && !topWallpaperPreloadStop.running) {
                topWallpaperPreloadStop.command = [root.topWallpaperApplyScript, "__transition-preload-stop"]
                topWallpaperPreloadStop.running = true
            }
        }
    }

    NumberAnimation {
        id: wallpaperWaveAnimation

        target: root
        property: "wallpaperWaveProgress"
        from: 0
        to: 1
        duration: root.wallpaperWaveDurationMs
        easing.type: Easing.InOutSine

        onFinished: {
            root.wallpaperWaveProgress = 1
            root.wallpaperWaveMounted = false
            root.wallpaperWaveFrameDir = ""
            root.wallpaperWaveToken = ""
            root.wallpaperWaveSourcePath = ""
            root.wallpaperWaveTransition = "wave"
        }
    }

    Timer {
        id: topWallpaperCardsMountTimer

        interval: 170
        repeat: false
        onTriggered: root.topWallpaperCardsMounted = root.topWallpaperPopupOpen
    }

    Timer {
        id: topWallpaperDeferredScanTimer

        interval: 30
        repeat: false
        onTriggered: {
            if (root.topWallpaperPopupOpen && !topWallpaperScan.running)
                topWallpaperScan.running = true
        }
    }

    NumberAnimation {
        id: topWallpaperSlideAnimation

        target: root
        property: "topWallpaperSlideProgress"
        from: 0
        to: 1
        duration: veloraTheme.motionEnabled ? 360 : 1
        easing.type: Easing.Linear

        onStopped: {
            if (root.topWallpaperSlideDirection !== 0 && root.topWallpaperSlideProgress >= 1) {
                const entries = Array.isArray(root.topWallpaperEntries) ? root.topWallpaperEntries : []
                if (entries && entries.length > 0)
                    root.topWallpaperOffset = ((root.topWallpaperOffset + root.topWallpaperSlideDirection) % entries.length + entries.length) % entries.length
            }

            const queuedSteps = root.topWallpaperQueuedDirection
            const queuedDirection = queuedSteps > 0 ? 1 : (queuedSteps < 0 ? -1 : 0)
            root.topWallpaperQueuedDirection = queuedSteps - queuedDirection
            root.topWallpaperSlideProgress = 0
            root.topWallpaperSlideDirection = 0

            const entries = Array.isArray(root.topWallpaperEntries) ? root.topWallpaperEntries : []
            if (queuedDirection !== 0 && entries && entries.length > 1 && root.topWallpaperPopupOpen) {
                root.topWallpaperSlideDirection = queuedDirection
                root.topWallpaperSlideProgress = 0
                topWallpaperSlideAnimation.start()
            }
        }
    }

    readonly property var focusItems: sideBarLayoutEnabled
        ? ["caffeine", "notes", "discord", "volume",
            "brightness", "notifications", "bluetooth", "wifi", "avatar"] : [
        "clock",
        "search",
        "workspace1",
        "workspace2",
        "workspace3",
        "workspace4",
        "files",
        "browser",
        "discord",
        "volume",
        "wifi",
        "brightness",
        "notifications",
        "bluetooth",
        "battery",
        "settings",
        "layout",
        "avatar"
    ]
    readonly property string focusTarget: focusItems[Math.max(0, Math.min(focusIndex, focusItems.length - 1))]

    Behavior on frameVisualsReveal {
        enabled: veloraTheme.motionEnabled
        NumberAnimation {
            duration: root.frameVisualsEnabled ? veloraTheme.motionPanelIn : veloraTheme.motionPanelOut
            easing.type: root.frameVisualsEnabled ? veloraTheme.motionEaseEnter : veloraTheme.motionEaseExit
        }
    }

    Behavior on topWallpaperFrameReveal {
        enabled: veloraTheme.motionEnabled && !(root.composition && root.composition.reducedMotion)
        SequentialAnimation {
            PauseAnimation { duration: root.topWallpaperPopupOpen ? 0 : (root.composition ? root.composition.motionTokens.contentExit : 65) }
            NumberAnimation {
                duration: root.composition ? (root.topWallpaperPopupOpen ? root.composition.motionTokens.accordionDuration : root.composition.motionTokens.accordionCloseDuration)
                    : (root.topWallpaperPopupOpen ? veloraTheme.motionPanelIn : veloraTheme.motionPanelOut)
                easing.type: Easing.InOutCubic
            }
        }
    }

    Behavior on screenVisualizerReveal {
        enabled: veloraTheme.motionEnabled
        NumberAnimation {
            duration: root.screenVisualizerMounted ? veloraTheme.motionPanelIn : veloraTheme.motionPanelOut
            easing.type: root.screenVisualizerMounted ? veloraTheme.motionEaseEnter : veloraTheme.motionEaseExit
        }
    }

    function desktopFrameMatteColor() {
        if (!frameVisualsMounted)
            return "transparent"
        return veloraTheme.alpha(veloraTheme.surfaceSidebar, desktopFrameMatteOpacity)
    }

    function topBarFrameMatteColor() {
        if (!topBarFrameVisualsMounted)
            return "transparent"
        return veloraTheme.alpha(veloraTheme.surfaceSidebar, sidebarPanelGlassAlpha())
    }

    function topBarFrameBorderColor() {
        if (!topBarFrameVisualsMounted)
            return "transparent"
        if (veloraTheme.themeId === "pywal16")
            return veloraTheme.alpha(veloraTheme.sidebarBorderGlow, Math.min(0.14, Math.max(0.055, veloraTheme.sidebarBorderGlow.a * 0.36)))
        return veloraTheme.alpha(veloraTheme.borderSoft, veloraTheme.themeMode === "dark" ? 0.075 : 0.17)
    }

    function topBarFrameInnerLineColor() {
        if (!topBarFrameVisualsMounted)
            return "transparent"
        if (veloraTheme.themeMode === "dark")
            return Qt.rgba(1, 1, 1, 0.035)
        return veloraTheme.alpha(topBarFrameBorderColor(), veloraTheme.themeId === "pywal16" ? 0.12 : 0.18)
    }

    function sidebarPanelGlassAlpha() {
        const base = Math.max(veloraTheme.minOpacityForRole("sidebar"), Math.min(veloraTheme.sidebarOpacity, 0.98))
        return base
    }

    function sidebarBarGlassAlpha() {
        const base = Math.max(veloraTheme.minOpacityForRole("sidebar"), Math.min(veloraTheme.barOpacity, 0.98))
        return base
    }

    function sidebarPanelMaterialColor() {
        if (!frameVisualsMounted)
            return "transparent"
        return veloraTheme.alpha(veloraTheme.surfaceSidebar, sidebarPanelGlassAlpha())
    }

    function batteryNeutralPanelColor() {
        return sidebarBarMaterialColor()
    }

    function batteryNeutralBarColor() {
        return sidebarBarMaterialColor()
    }

    function batteryAdaptiveGlassColor(r, g, b, alpha, tintAmount) {
        const tint = veloraTheme.surfacePopup
        const amount = veloraTheme.themeId === "pywal16" ? tintAmount : tintAmount * 0.55
        return Qt.rgba(
            r * (1 - amount) + tint.r * amount,
            g * (1 - amount) + tint.g * amount,
            b * (1 - amount) + tint.b * amount,
            alpha
        )
    }

    function quickPopupSurfaceGlass(type) {
        if (type === "battery")
            return batteryNeutralPanelColor()
        return sidebarBarMaterialColor()
    }

    function topWallpaperPopupWidth(screenWidth) {
        const available = Math.max(0, Math.floor(screenWidth - barReserveWidth - desktopFrameMargin * 4))
        return Math.round(Math.min(available, 1340, Math.max(960, screenWidth * 0.82)))
    }

    function topWallpaperPopupHeight(screenHeight) {
        const available = Math.max(0, Math.floor(screenHeight - 64))
        return Math.min(available, Math.round(Math.min(840, Math.max(640, screenHeight * 0.72))))
    }

    function topWallpaperFrameLiftHeight(screenHeight) {
        if (!topWallpaperUsesBottomSelector)
            return 0

        const available = Math.max(0, screenHeight - desktopFrameMargin * 2)
        const target = Math.round(Math.min(280, Math.max(210, screenHeight * 0.185)))
        return Math.round(Math.min(target, available * 0.45) * topWallpaperFrameReveal)
    }

    function desktopFrameY(screenHeight) {
        return desktopFrameMargin
    }

    function topBarPanelTopMargin(screenHeight) {
        return 0
    }

    function topBarPanelHeight(screenHeight) {
        return Math.round(Math.min(54, Math.max(50, screenHeight * 0.045)))
    }

    function topBarPanelStageWidth(screenWidth) {
        return Math.round(Math.min(1040, Math.max(860, screenWidth * 0.540)))
    }

    function topBarFrameMargin(screenWidth) {
        return Math.round(Math.min(8, Math.max(5, screenWidth * 0.0042)))
    }

    function topBarFrameTop(screenHeight) {
        return Math.round(topBarPanelTopMargin(screenHeight) + topBarPanelHeight(screenHeight) - 24)
    }

    function topBarFrameBottomInset(screenHeight) {
        return Math.round(Math.min(8, Math.max(5, screenHeight * 0.006)))
    }

    function topBarFrameRadius(screenHeight) {
        return Math.round(Math.min(37, Math.max(30, screenHeight * 0.030)))
    }

    function desktopFrameBottomInset(screenHeight) {
        return desktopFrameMargin + topWallpaperFrameLiftHeight(screenHeight)
    }

    function desktopFrameHeight(screenHeight) {
        return Math.max(0, screenHeight - desktopFrameY(screenHeight) - desktopFrameBottomInset(screenHeight))
    }

    function desktopFrameBottom(screenHeight) {
        return desktopFrameY(screenHeight) + desktopFrameHeight(screenHeight)
    }

    function normalizeTopWallpaperEntry(entry) {
        const source = entry || {}
        const kind = String(source.kind || "static").toLowerCase()
        const path = String(source.path || "")
        const lowerPath = path.toLowerCase()
        let mediaType = String(source.mediaType || "").toLowerCase()
        if (mediaType.length <= 0) {
            if (lowerPath.endsWith(".gif"))
                mediaType = "gif"
            else if (kind === "engine")
                mediaType = "engine"
            else if (kind === "live")
                mediaType = "vid"
            else
                mediaType = "img"
        }

        return {
            key: String(source.key || (kind + ":" + path)),
            kind: kind,
            mediaType: mediaType,
            path: path,
            preview: String(source.preview || path),
            title: String(source.title || source.label || path.split("/").pop() || "Wallpaper"),
            dominantColor: String(source.dominantColor || "#808080"),
            colorGroup: String(source.colorGroup || "neutral").toLowerCase()
        }
    }

    function topWallpaperEntryKey(entry) {
        if (!entry)
            return ""
        return String(entry.key || (String(entry.kind || "static") + ":" + String(entry.path || "")))
    }

    function topWallpaperMatchesFilters(entry) {
        if (!entry || !entry.path)
            return false

        const key = topWallpaperEntryKey(entry)
        if (topWallpaperHidden.indexOf(String(entry.path)) >= 0 || topWallpaperHidden.indexOf(key) >= 0)
            return false

        const media = String(entry.mediaType || "img")
        if (topWallpaperMediaFilter === "img" && media !== "img")
            return false
        if (topWallpaperMediaFilter === "gif" && media !== "gif")
            return false
        if (topWallpaperMediaFilter === "vid" && media !== "vid" && media !== "engine")
            return false

        if (topWallpaperColorFilter.length > 0 && String(entry.colorGroup || "neutral") !== topWallpaperColorFilter)
            return false
        if (topWallpaperFavoritesOnly && topWallpaperFavorites.indexOf(key) < 0)
            return false

        const query = topWallpaperSearchQuery.trim().toLowerCase()
        if (query.length > 0) {
            const searchable = (String(entry.title || "") + " " + String(entry.path || "")).toLowerCase()
            if (searchable.indexOf(query) < 0)
                return false
        }
        return true
    }

    function topWallpaperControlCenterEntries() {
        const source = topWallpaperAllEntries && topWallpaperAllEntries.length > 0
            ? topWallpaperAllEntries
            : topWallpaperFallbackEntries
        const visible = []

        for (let index = 0; index < source.length; ++index) {
            const entry = normalizeTopWallpaperEntry(source[index])
            const key = topWallpaperEntryKey(entry)
            if (!entry.path)
                continue
            if (topWallpaperHidden.indexOf(String(entry.path)) >= 0
                    || topWallpaperHidden.indexOf(key) >= 0)
                continue
            visible.push(entry)
        }
        return visible
    }

    function ensureTopWallpaperLibraryLoaded(refresh) {
        topWallpaperErrorMessage = ""
        if (!topWallpaperLibraryLoad.running)
            topWallpaperLibraryLoad.running = true
        if (!topWallpaperActiveLoad.running)
            topWallpaperActiveLoad.running = true
        if (!topWallpaperScan.running && (refresh === true || !topWallpaperLibraryReady)) {
            topWallpaperScan.command = refresh === true
                ? [root.topWallpaperScanScript, "--json", "--refresh"]
                : [root.topWallpaperScanScript, "--json"]
            topWallpaperScan.running = true
        }
    }

    function recomputeTopWallpaperEntries(preferredKey) {
        const currentKey = String(preferredKey || topWallpaperEntryKey(topWallpaperEntry(0)))
        const source = topWallpaperAllEntries && topWallpaperAllEntries.length > 0
            ? topWallpaperAllEntries
            : topWallpaperFallbackEntries
        const next = []

        for (let i = 0; i < source.length; ++i) {
            const entry = normalizeTopWallpaperEntry(source[i])
            if (topWallpaperMatchesFilters(entry))
                next.push(entry)
        }

        if (topWallpaperSlideAnimation.running) {
            topWallpaperQueuedDirection = 0
            topWallpaperSlideDirection = 0
            topWallpaperSlideProgress = 0
            topWallpaperSlideAnimation.stop()
        }

        topWallpaperEntries = next
        let targetIndex = 0
        if (currentKey.length > 0) {
            for (let index = 0; index < next.length; ++index) {
                if (topWallpaperEntryKey(next[index]) === currentKey) {
                    targetIndex = index
                    break
                }
            }
        }
        topWallpaperOffset = targetIndex
    }

    function setTopWallpaperMediaFilter(filter) {
        const preferred = topWallpaperEntryKey(topWallpaperEntry(0))
        topWallpaperMediaFilter = ["all", "img", "vid", "gif"].indexOf(filter) >= 0 ? filter : "all"
        recomputeTopWallpaperEntries(preferred)
    }

    function setTopWallpaperColorFilter(filter) {
        const preferred = topWallpaperEntryKey(topWallpaperEntry(0))
        topWallpaperColorFilter = String(filter || "")
        recomputeTopWallpaperEntries(preferred)
    }

    function setTopWallpaperSearch(query) {
        const preferred = topWallpaperEntryKey(topWallpaperEntry(0))
        topWallpaperSearchQuery = String(query || "")
        recomputeTopWallpaperEntries(preferred)
    }

    function setTopWallpaperFavoritesOnly(enabled) {
        const preferred = topWallpaperEntryKey(topWallpaperEntry(0))
        topWallpaperFavoritesOnly = enabled === true
        recomputeTopWallpaperEntries(preferred)
    }

    function queueTopWallpaperLibrarySave() {
        topWallpaperLibrarySaveQueued = true
        topWallpaperLibrarySaveTimer.restart()
    }

    function flushTopWallpaperLibraryState() {
        if (topWallpaperLibrarySave.running)
            return
        topWallpaperLibrarySaveQueued = false
        topWallpaperLibrarySave.command = [
            topWallpaperLibraryStateScript,
            "set",
            JSON.stringify({ favorites: topWallpaperFavorites, hidden: topWallpaperHidden })
        ]
        topWallpaperLibrarySave.running = true
    }

    function toggleTopWallpaperFavorite(entry) {
        const key = topWallpaperEntryKey(entry)
        if (key.length <= 0)
            return
        const next = topWallpaperFavorites.slice()
        const index = next.indexOf(key)
        if (index >= 0)
            next.splice(index, 1)
        else
            next.push(key)
        topWallpaperFavorites = next
        queueTopWallpaperLibrarySave()
        if (topWallpaperFavoritesOnly)
            recomputeTopWallpaperEntries(key)
    }

    function hideTopWallpaper(entry) {
        if (!entry || !entry.path)
            return
        const next = topWallpaperHidden.slice()
        const path = String(entry.path)
        const key = topWallpaperEntryKey(entry)
        if (next.indexOf(path) < 0 && next.indexOf(key) < 0)
            next.push(path)
        topWallpaperHidden = next
        topWallpaperErrorMessage = ""
        recomputeTopWallpaperEntries("")
        queueTopWallpaperLibrarySave()
    }

    function selectTopWallpaperRelative(delta) {
        const step = Math.round(Number(delta))
        if (step === 0 || topWallpaperEntries.length <= 0)
            return
        if (Math.abs(step) === 1) {
            moveTopWallpaper(step)
            return
        }
        if (topWallpaperSlideAnimation.running) {
            topWallpaperQueuedDirection = 0
            topWallpaperSlideAnimation.complete()
        }
        topWallpaperOffset = ((topWallpaperOffset + step) % topWallpaperEntries.length + topWallpaperEntries.length) % topWallpaperEntries.length
    }

    function selectTopWallpaperAbsolute(index) {
        if (topWallpaperEntries.length <= 0)
            return
        if (topWallpaperSlideAnimation.running) {
            topWallpaperQueuedDirection = 0
            topWallpaperSlideAnimation.complete()
        }
        topWallpaperOffset = ((Math.round(index) % topWallpaperEntries.length) + topWallpaperEntries.length) % topWallpaperEntries.length
    }

    function chooseRandomTopWallpaper() {
        const count = topWallpaperEntries.length
        if (count <= 1)
            return
        let next = Math.floor(Math.random() * count)
        if (next === topWallpaperOffset)
            next = (next + 1 + Math.floor(Math.random() * (count - 1))) % count
        selectTopWallpaperAbsolute(next)
    }

    function refreshTopWallpaperLibrary() {
        if (topWallpaperScan.running)
            return
        topWallpaperErrorMessage = ""
        topWallpaperScan.command = [topWallpaperScanScript, "--json", "--refresh"]
        topWallpaperScan.running = true
    }

    function topWallpaperEntry(index) {
        const entries = Array.isArray(topWallpaperEntries) ? topWallpaperEntries : topWallpaperFallbackEntries
        if (!entries || entries.length <= 0)
            return null
        const normalizedIndex = ((topWallpaperOffset + index) % entries.length + entries.length) % entries.length
        return entries[normalizedIndex]
    }

    function topWallpaperSlideEase() {
        const t = Math.max(0, Math.min(1, topWallpaperSlideProgress))
        return t * t * (3 - 2 * t)
    }

    function moveTopWallpaper(delta) {
        const entries = Array.isArray(topWallpaperEntries) ? topWallpaperEntries : []
        if (!entries || entries.length <= 1)
            return

        const direction = delta > 0 ? 1 : -1

        if (topWallpaperUsesCenterSelector) {
            selectTopWallpaperAbsolute(Math.max(0, Math.min(entries.length - 1, topWallpaperOffset + direction)))
            return
        }

        if (topWallpaperSlideAnimation.running) {
            topWallpaperQueuedDirection = Math.max(-6, Math.min(6, topWallpaperQueuedDirection + direction))
            return
        }

        topWallpaperQueuedDirection = 0
        topWallpaperSlideDirection = direction
        topWallpaperSlideProgress = 0
        topWallpaperSlideAnimation.start()
    }

    function applyTopWallpaperSelection(entryOverride) {
        if (topWallpaperApply.running)
            return

        let item = entryOverride && entryOverride.path ? entryOverride : topWallpaperEntry(0)
        if (topWallpaperSlideAnimation.running) {
            topWallpaperQueuedDirection = 0
            topWallpaperSlideAnimation.complete()
            item = topWallpaperEntry(0)
        }

        if (!item || !item.path)
            return

        topWallpaperErrorMessage = ""
        topWallpaperApplyingEntry = item
        topWallpaperApply.command = [
            topWallpaperApplyScript,
            item.kind || "static",
            item.path,
            item.preview || item.path
        ]
        topWallpaperApply.running = true
    }

    function toggleTopWallpaperPopup(forceOpen, withKeyboardFocus) {
        const nextOpen = forceOpen === true ? true : (forceOpen === false ? false : !topWallpaperPopupOpen)
        topWallpaperPopupOpen = nextOpen
        topWallpaperKeyboardFocus = nextOpen && withKeyboardFocus === true

        if (topWallpaperPopupOpen) {
            activeRailControl = ""
            topWallpaperErrorMessage = ""
            topWallpaperPreloadStopTimer.stop()
            if (!topWallpaperPreload.running) {
                topWallpaperPreload.command = [root.topWallpaperApplyScript, "__transition-preload-current"]
                topWallpaperPreload.running = true
            }
            wallpaperSelectorOpen = false
            wallpaperSelectorWindowOpen = false
            settingsPanelOpen = false
            settingsPanelWindowOpen = false
            quickPopupType = ""
            rightDashboardOpen = false

            root.topWallpaperCardsMounted = false
            topWallpaperCardsMountTimer.restart()
            topWallpaperDeferredScanTimer.restart()
            if (!topWallpaperLibraryLoad.running)
                topWallpaperLibraryLoad.running = true
            if (!topWallpaperActiveLoad.running)
                topWallpaperActiveLoad.running = true
            recomputeTopWallpaperEntries(topWallpaperActiveKey)
        } else {
            topWallpaperPreloadRefreshTimer.stop()
            topWallpaperPreloadStopTimer.restart()
            topWallpaperCardsMountTimer.stop()
            topWallpaperDeferredScanTimer.stop()
            root.topWallpaperCardsMounted = false
        }
    }

    function openWeatherTop(withKeyboardFocus, mode) {
        if (topBarLayout || (!weatherMenuEnabled && mode !== "search")) {
            disableWeatherTopNow()
            return
        }

        exitFocus()
        closeQuickPopup()
        wallpaperSelectorOpen = false
        wallpaperSelectorWindowOpen = false
        settingsPanelOpen = false
        settingsPanelWindowOpen = false
        closeRightDashboard()
        closeLegacyLeftMenu()
        toggleTopWallpaperPopup(false, false)
        weatherTopUnmountTimer.stop()
        weatherTopMode = mode === "search" ? "search" : "weather"
        weatherTopKeyboardFocus = withKeyboardFocus === true
        weatherTopWindowOpen = true
        weatherTopOpen = true
        if (weatherTopKeyboardFocus)
            weatherTopFocusRequest += 1
    }

    function openWeatherTopFromMouse() {
        if (topBarLayout || !weatherMenuEnabled)
            return

        weatherTopHoverCloseTimer.stop()
        if (!weatherTopOpen)
            openWeatherTop(false, "weather")
    }

    function disableWeatherTopNow() {
        weatherTopOpen = false
        weatherTopWindowOpen = false
        weatherTopKeyboardFocus = false
        weatherTopTriggerHovering = false
        weatherTopPanelHovering = false
        if (typeof weatherTopHoverCloseTimer !== "undefined")
            weatherTopHoverCloseTimer.stop()
        if (typeof weatherTopUnmountTimer !== "undefined")
            weatherTopUnmountTimer.stop()
    }

    function closeWeatherTop() {
        weatherTopOpen = false
        weatherTopKeyboardFocus = false
        weatherTopTriggerHovering = false
        weatherTopPanelHovering = false
        weatherTopHoverCloseTimer.stop()
        weatherTopUnmountTimer.restart()
    }

    function toggleWeatherTop() {
        if (topBarLayout || !weatherMenuEnabled) {
            disableWeatherTopNow()
            return
        }

        if (weatherTopOpen && weatherTopMode === "weather")
            closeWeatherTop()
        else
            openWeatherTop(false, "weather")
    }

    function toggleTopSearch() {
        if (topBarLayout) {
            disableWeatherTopNow()
            openAdaptiveBarPopup("search", topBarPopupCenterX > 0 ? topBarPopupCenterX : defaultQuickPopupCenterY("search"))
            return
        }

        if (weatherTopOpen && weatherTopMode === "search")
            closeWeatherTop()
        else
            openWeatherTop(true, "search")
    }

    function switchToSideBarLayout(position) {
        veloraTheme.applyLayout(position, true)
    }

    function applyPendingLayoutSwitch() {
        if (pendingLayoutPosition.length <= 0)
            return

        switchToSideBarLayout(pendingLayoutPosition)
        pendingLayoutPosition = ""
    }

    function switchToSideBarLayoutWithFade(position) {
        pendingLayoutPosition = String(position || "left") === "right" ? "right" : "left"
        layoutSwitchAnimation.stop()
        layoutSwitchOpacity = 1
        layoutSwitchAnimation.restart()
    }

    function cycleBarLayout() {
        closeQuickPopup()
        closeWeatherTop()
        closeRightDashboard()
        settingsPanelOpen = false
        settingsPanelWindowOpen = false

        switchToSideBarLayoutWithFade((!barOnRight) ? "right" : "left")
    }

    function engageWeatherTop() {
        if (!weatherTopOpen)
            return
        weatherTopKeyboardFocus = true
        weatherTopHoverCloseTimer.stop()
    }

    function setWeatherTopPanelHovering(inside) {
        weatherTopPanelHovering = inside
        if (inside)
            weatherTopHoverCloseTimer.stop()
        else
            scheduleWeatherTopHoverClose()
    }

    function scheduleWeatherTopHoverClose() {
        if (weatherTopKeyboardFocus)
            return
        if (!weatherTopTriggerHovering && !weatherTopPanelHovering)
            weatherTopHoverCloseTimer.restart()
    }

    function sidebarBarMaterialColor() {
        if (root.composition)
            return root.composition.unifiedBarSurface
        if (!frameVisualsMounted)
            return "transparent"
        return veloraTheme.alpha(veloraTheme.surfaceSidebar, sidebarBarGlassAlpha())
    }

    function sideRailMaterialColor() {
        if (!sideVisualizerMounted)
            return "transparent"
        return veloraTheme.alpha(veloraTheme.surfaceSidebar, sidebarPanelGlassAlpha())
    }

    function topBarRailMaterialColor() {
        if (!topBarCenterVisualizerMounted)
            return "transparent"
        return veloraTheme.alpha(veloraTheme.surfaceSidebar, sidebarPanelGlassAlpha())
    }

    function sidebarPanelBorderColor() {
        if (!frameVisualsMounted && !sideVisualizerMounted)
            return "transparent"
        if (veloraTheme.themeId === "pywal16")
            return veloraTheme.alpha(veloraTheme.sidebarBorderGlow, Math.min(0.18, Math.max(0.08, veloraTheme.sidebarBorderGlow.a * 0.50)))
        return veloraTheme.alpha(veloraTheme.borderSoft, veloraTheme.themeMode === "dark" ? 0.11 : 0.26)
    }

    function sidebarPanelInnerLineColor() {
        if (!frameVisualsMounted && !sideVisualizerMounted)
            return "transparent"
        if (veloraTheme.themeMode === "dark")
            return Qt.rgba(1, 1, 1, 0.055)
        return veloraTheme.alpha(sidebarPanelBorderColor(), veloraTheme.themeId === "pywal16" ? 0.16 : 0.24)
    }

    function desktopFrameBorderColor() {
        if (!frameVisualsMounted)
            return "transparent"
        if (veloraTheme.themeId === "pywal16")
            return veloraTheme.alpha(veloraTheme.sidebarBorderGlow, Math.min(0.18, Math.max(0.08, veloraTheme.sidebarBorderGlow.a * 0.50)))
        return veloraTheme.alpha(veloraTheme.borderSoft, veloraTheme.themeMode === "dark" ? 0.11 : 0.26)
    }

    function desktopFrameHighlightLineColor() {
        if (!frameVisualsMounted)
            return "transparent"
        return veloraTheme.alpha(veloraTheme.activeText, veloraTheme.themeMode === "dark" ? 0.24 : 0.32)
    }

    function desktopFrameHighlightColor() {
        return "transparent"
    }

    function enterFocus() {
        wallpaperSelectorOpen = false
        settingsPanelOpen = false
        closeQuickPopup()
        focusIndex = Math.max(0, Math.min(focusIndex, focusItems.length - 1))
        focusMode = true
    }

    function exitFocus() {
        focusMode = false
    }

    function toggleFocus() {
        if (focusMode)
            exitFocus()
        else
            enterFocus()
    }

    function moveFocus(dir) {
        focusIndex = Math.max(0, Math.min(focusIndex + dir, focusItems.length - 1))
    }

    function quickPopupForFocus(target) {
        return target === "search" ? "search" : ""
    }

    function cachedQuickPopupIndex(type) {
        for (let i = 0; i < cachedQuickPopupTypes.length; ++i) {
            if (cachedQuickPopupTypes[i] === type)
                return i
        }
        return -1
    }

    function topBarQuickPopupIndex(type) {
        for (let i = 0; i < topBarCachedQuickPopupTypes.length; ++i) {
            if (topBarCachedQuickPopupTypes[i] === type)
                return i
        }
        return -1
    }

    function topBarSystemPageForType(type) {
        const value = String(type || "")
        if (value === "quickSettings" || value === "settingsQuick" || value === "settings" || value === "system")
            return "settings"
        if (value === "brightness")
            return "display"
        return topBarSystemPages.indexOf(value) >= 0 ? value : ""
    }

    function topBarSystemPageIndex(page) {
        const index = topBarSystemPages.indexOf(String(page || ""))
        return index >= 0 ? index : topBarSystemPages.length - 1
    }

    function topBarQuickPopupWidth(type) {
        if (type === "system"
                && topBarSystemPopupPreferredPage === topBarSystemPage
                && topBarSystemPopupPreferredWidth > 0)
            return topBarSystemPopupPreferredWidth
        if (typeof topBarPopupLoader !== "undefined") {
            topBarPopupLoader.cacheGeneration
            const loadedPopup = topBarPopupLoader.itemForType(type)
            if (loadedPopup && Number(loadedPopup.preferredWidth) > 0)
                return Math.round(Number(loadedPopup.preferredWidth))
        }
        if (type === "system") {
            if (topBarSystemPage === "settings") return 720
            if (topBarSystemPage === "wallpaper") return 660
            if (topBarSystemPage === "volume") return 520
            if (topBarSystemPage === "wifi") return 560
            if (topBarSystemPage === "display" || topBarSystemPage === "brightness") return 560
            if (topBarSystemPage === "notifications" || topBarSystemPage === "bluetooth" || topBarSystemPage === "battery") return 560
            return 600
        }
        if (type === "time") return 390
        if (type === "apps") return 470
        if (type === "workspaces") return 470
        if (type === "media") return lyricsAvailable ? 760 : 700
        if (type === "profile") return 390
        return quickPopupWidth(type)
    }

    function topBarQuickPopupHeight(type) {
        if (type === "system"
                && topBarSystemPopupPreferredPage === topBarSystemPage
                && topBarSystemPopupPreferredHeight > 0)
            return topBarSystemPopupPreferredHeight
        if (typeof topBarPopupLoader !== "undefined") {
            topBarPopupLoader.cacheGeneration
            const loadedPopup = topBarPopupLoader.itemForType(type)
            if (loadedPopup && Number(loadedPopup.preferredHeight) > 0)
                return Math.round(Number(loadedPopup.preferredHeight))
        }
        if (type === "system") {
            if (topBarSystemPage === "wallpaper") return 540
            if (topBarSystemPage === "volume") return 500
            if (topBarSystemPage === "wifi") return 500
            if (topBarSystemPage === "display" || topBarSystemPage === "brightness") return 440
            if (topBarSystemPage === "notifications") return 320
            if (topBarSystemPage === "bluetooth") return 190
            if (topBarSystemPage === "battery") return 340
            return 468
        }
        if (type === "time") return 520
        if (type === "apps") return 420
        if (type === "workspaces") return 360
        if (type === "media") return lyricsAvailable ? 350 : 330
        if (type === "profile") return 340
        return quickPopupHeight(type)
    }

    onActiveQuickPopupTypeChanged: {
        if (activeQuickPopupType.length > 0)
            activeRailControl = ""
        if (quickPopupVisible && activeQuickPopupType.length > 0) {
            renderedQuickPopupType = activeQuickPopupType
        }
        if (lyricsServiceWanted)
            pollLyricsNow()
        else if (!veloraTheme.lyricsEnabled)
            clearLyricsOverlay("disabled")
    }

    onFocusedWorkspaceIdChanged: {
        if (systemPopupKeyboardFocus
                && systemPopupFocusWorkspaceId >= 0
                && focusedWorkspaceId !== systemPopupFocusWorkspaceId) {
            releaseSystemPopupKeyboardFocus()
        }
    }

    onQuickPopupVisibleChanged: {
        if (quickPopupVisible) {
            quickPopupUnmountTimer.stop()
            quickPopupWindowOpen = true
            renderedQuickPopupType = activeQuickPopupType
            if (topBarLayout && activeQuickPopupType === "system") {
                quickPopupSurfaceRevealAnimation.stop()
                quickPopupSurfaceReveal = 1
                Qt.callLater(function() {
                    if (root.quickPopupVisible && root.activeQuickPopupType === "system")
                        root.animateSystemSheetOpen()
                })
            } else {
                systemSheetOpenAnimation.stop()
                systemSheetCloseAnimation.stop()
                systemSheetOffsetY = 0
                systemSheetOffsetX = 0
                systemSheetClosing = false
                animateQuickPopupSurfaceReveal(1)
            }
            if (activeQuickPopupType === "search" || activeQuickPopupType === "apps")
                scheduleSearchPopupFocus()
        } else if (renderedQuickPopupType.length > 0) {
            prepareQuickPopupCloseAnimation()
            if (topBarLayout && renderedQuickPopupType === "system") {
                quickPopupSurfaceRevealAnimation.stop()
                quickPopupSurfaceReveal = 1
                animateSystemSheetClose()
            } else {
                animateQuickPopupSurfaceReveal(0)
            }
            quickPopupUnmountTimer.restart()
        }
    }

    onWallpaperSelectorVisibleChanged: {
        if (wallpaperSelectorVisible) {
            wallpaperSelectorUnmountTimer.stop()
            wallpaperSelectorWindowOpen = true
        } else if (wallpaperSelectorWindowOpen) {
            wallpaperSelectorUnmountTimer.restart()
        }
    }

    onSettingsPanelVisibleChanged: {
        if (settingsPanelVisible) {
            settingsPanelUnmountTimer.stop()
            settingsPanelWindowOpen = true
        } else if (settingsPanelWindowOpen) {
            settingsPanelUnmountTimer.restart()
        }
    }

    onLeftMenuOpenChanged: {
        if (!leftMenuOpen) {
            leftMenuPinned = false
            leftMenuInteractiveFocus = false
            leftMediaWindowOpen = false
            leftMediaWindowHovering = false
            leftMediaWindowEntranceHold = false
            leftDetailSwitchProgress = 1
        }
    }

    function quickPopupArrowCenter(type) {
        if (type === "volume")
            return 78
        if (type === "wifi")
            return 288
        if (type === "brightness")
            return 248
        if (type === "notifications")
            return 414
        if (type === "bluetooth")
            return 456
        if (type === "wallpaperVisibility")
            return 132
        return 38
    }

    function defaultQuickPopupCenterY(type) {
        if (type === "theme")
            return 212
        if (type === "settings")
            return 1018
        if (type === "weatherPanel")
            return 520
        if (type === "time")
            return 84
        if (type === "search")
            return 180
        if (type === "files")
            return 424
        if (type === "browser")
            return 474
        if (type === "volume")
            return 782
        if (type === "wifi")
            return 888
        if (type === "brightness")
            return 938
        if (type === "quickSettings")
            return 760
        if (type === "settingsQuick")
            return 1018
        if (type === "notifications")
            return 982
        if (type === "battery")
            return 1038
        if (type === "bluetooth")
            return 1028
        if (type === "wallpaperVisibility")
            return defaultQuickPopupCenterY("theme")
        return 290
    }

    function setQuickPopupCenter(type, centerY) {
        const value = Number(centerY)
        quickPopupCenterY = value > 0 ? value : defaultQuickPopupCenterY(type)
    }

    function animateQuickPopupSurfaceReveal(targetValue) {
        const opening = targetValue > quickPopupSurfaceReveal
        quickPopupSurfaceRevealAnimation.stop()
        quickPopupSurfaceRevealAnimation.from = quickPopupSurfaceReveal
        quickPopupSurfaceRevealAnimation.to = targetValue
        quickPopupSurfaceRevealAnimation.duration = opening ? veloraTheme.motionPanelIn : quickPopupLineCloseDuration
        quickPopupSurfaceRevealAnimation.easing.type = opening ? veloraTheme.motionEaseEnter : Easing.InOutCubic
        quickPopupSurfaceRevealAnimation.restart()
    }

    function systemSheetTravelDistance() {
        if (veloraTheme.controlCenterPosition === "right"
                && topBarSystemPage === "settings") {
            if (typeof topBarPanel !== "undefined" && topBarPanel.popupWidth > 0)
                return topBarPanel.popupWidth + 96
            return 596
        }
        if (typeof topBarPanel !== "undefined" && topBarPanel.popupHeight > 0)
            return topBarPanel.popupHeight + 28
        return 680
    }

    function systemSheetUsesHorizontalMotion() {
        return veloraTheme.controlCenterPosition === "right"
            && topBarSystemPage === "settings"
    }

    function currentSystemSheetOffset() {
        return systemSheetUsesHorizontalMotion() ? systemSheetOffsetX : systemSheetOffsetY
    }

    function setCurrentSystemSheetOffset(value) {
        if (systemSheetUsesHorizontalMotion()) {
            systemSheetOffsetX = value
            systemSheetOffsetY = 0
        } else {
            systemSheetOffsetY = value
            systemSheetOffsetX = 0
        }
    }

    function animateSystemSheetOpen() {
        systemSheetCloseAnimation.stop()
        systemSheetOpenAnimation.stop()
        systemSheetClosing = false
        if (!veloraTheme.motionEnabled) {
            systemSheetOffsetY = 0
            systemSheetOffsetX = 0
            return
        }
        const travel = systemSheetTravelDistance()
        const currentOffset = currentSystemSheetOffset()
        if (currentOffset <= 0.5 || currentOffset > travel + 40)
            setCurrentSystemSheetOffset(travel)
        systemSheetRiseAnimation.property = systemSheetUsesHorizontalMotion() ? "systemSheetOffsetX" : "systemSheetOffsetY"
        systemSheetSettleAnimation.property = systemSheetRiseAnimation.property
        systemSheetRiseAnimation.from = currentSystemSheetOffset()
        systemSheetRiseAnimation.to = -10
        systemSheetOpenAnimation.restart()
    }

    function animateSystemSheetClose() {
        systemSheetOpenAnimation.stop()
        systemSheetCloseAnimation.stop()
        systemSheetClosing = true
        if (!veloraTheme.motionEnabled) {
            setCurrentSystemSheetOffset(systemSheetTravelDistance())
            return
        }
        systemSheetCloseAnimation.property = systemSheetUsesHorizontalMotion() ? "systemSheetOffsetX" : "systemSheetOffsetY"
        systemSheetCloseAnimation.from = currentSystemSheetOffset()
        systemSheetCloseAnimation.to = systemSheetTravelDistance()
        systemSheetCloseAnimation.restart()
    }

    function queueQuickPopupSwitch(type, centerY, topCenterX) {
        const requestedType = String(type || "")
        if (requestedType.length <= 0)
            return

        quickPopupSwitchTimer.stop()
        pendingQuickPopupType = ""
        pendingQuickPopupCenterY = 0
        pendingTopBarPopupCenterX = 0
        quickPopupSwitching = true
        quickPopupHoldOpen = false
        hoverPopupType = ""
        sidebarPopupHovering = false
        quickPopupHovering = false
        hoverCloseTimer.stop()
        if (Number(topCenterX) > 0)
            setTopBarPopupCenter(topCenterX)
        setQuickPopupCenter(requestedType, centerY)
        renderedQuickPopupType = requestedType
        quickPopupWindowOpen = true
        quickPopupUnmountTimer.stop()
        quickPopupType = requestedType
        if (requestedType === "search" || requestedType === "apps")
            scheduleSearchPopupFocus()
        Qt.callLater(function() {
            root.quickPopupSwitching = false
        })
    }

    function prepareWallpaperSelector(centerY) {
        toggleTopWallpaperPopup(false, false)
        topBarPopupCenterX = 0
        setQuickPopupCenter("theme", centerY)
        discardQuickPopupAnimation()
        settingsPanelOpen = false
    }

    function openWallpaperVisibility(centerY) {
        const value = Number(centerY)
        wallpaperSelectorOpen = false
        wallpaperSelectorWindowOpen = false
        wallpaperSelectorHovering = false
        wallpaperSelectorUnmountTimer.stop()
        openQuickPopup("wallpaperVisibility", value > 0 ? value : defaultQuickPopupCenterY("theme"))
    }

    function showWallpaperSelector(centerY) {
        exitFocus()
        toggleTopWallpaperPopup(true, true)
    }

    function toggleWallpaperSelector(centerY, forceOpen) {
        exitFocus()
        toggleTopWallpaperPopup(forceOpen === true ? true : (forceOpen === false ? false : null), true)
    }

    function focusWallpaperSelectorInput() {
        if (!wallpaperSelectorOpen)
            return

        Qt.callLater(function() {
            if (!root.wallpaperSelectorOpen)
                return

            if (typeof inlineModalLayer !== "undefined")
                inlineModalLayer.forceActiveFocus()
            if (typeof inlineWallpaperLoader !== "undefined" && inlineWallpaperLoader.item)
                inlineWallpaperLoader.item.forceActiveFocus()
        })
    }

    function prepareSettingsPanel(centerY) {
        toggleTopWallpaperPopup(false, false)
        topBarPopupCenterX = 0
        setQuickPopupCenter("settings", centerY)
        discardQuickPopupAnimation()
        wallpaperSelectorOpen = false
    }

    function toggleSettingsPanel(centerY, forceOpen) {
        exitFocus()
        prepareSettingsPanel(centerY)
        settingsPanelOpen = forceOpen ? true : !settingsPanelOpen
    }

    function openQuickPopup(type, centerY, topCenterX) {
        exitFocus()
        toggleTopWallpaperPopup(false, false)
        if (weatherTopOpen)
            closeWeatherTop()
        if (!quickPopupSwitching && activeQuickPopupType.length > 0 && activeQuickPopupType !== type && quickPopupSurfaceReveal > 0.08) {
            queueQuickPopupSwitch(type, centerY, topCenterX)
            return
        }
        if (type !== "search")
            quickPopupHoldOpen = false
        if (Number(topCenterX) > 0)
            setTopBarPopupCenter(topCenterX)
        setQuickPopupCenter(type, centerY)
        renderedQuickPopupType = type
        quickPopupWindowOpen = true
        quickPopupUnmountTimer.stop()
        hoverPopupType = ""
        hoverCloseTimer.stop()
        wallpaperSelectorOpen = false
        settingsPanelOpen = false
        quickPopupType = type
        if (type === "search" || type === "apps")
            scheduleSearchPopupFocus()
    }

    function scheduleSearchPopupFocus() {
        searchPopupFocusAttempts = 0
        searchPopupFocusTimer.restart()
    }

    function focusSearchPopupInput() {
        if (quickPopupType !== "search" && quickPopupType !== "apps")
            return

        if (typeof topBarPanel !== "undefined")
            topBarPanel.requestActivate()

        if (typeof panel !== "undefined")
            panel.forceActiveFocus(Qt.ShortcutFocusReason)

        if (typeof inlineQuickPopupLoader !== "undefined") {
            const popup = inlineQuickPopupLoader.itemForType("search")
            if (popup) {
                popup.forceActiveFocus()
                if (typeof popup.requestSearchFocus === "function")
                    popup.requestSearchFocus()
            }
        }

        if (typeof topBarPopupLoader !== "undefined") {
            topBarPopupLoader.forceActiveFocus(Qt.ShortcutFocusReason)
            const popup = topBarPopupLoader.itemForType(quickPopupType === "apps" ? "apps" : "search")
            if (popup) {
                popup.forceActiveFocus(Qt.ShortcutFocusReason)
                if (typeof popup.requestSearchFocus === "function")
                    popup.requestSearchFocus()
            }
        }
    }

    function setTopBarPopupCenter(centerX) {
        const value = Number(centerX)
        topBarPopupCenterX = value > 0 ? value : Math.round(mainAreaX(1920) + mainAreaWidth(1920) / 2)
    }

    function defaultTopBarPopupCenterX(type) {
        const screenWidth = 1920
        const stageWidth = Math.round(Math.min(1265, Math.max(1043, screenWidth * 0.658)))
        const barX = Math.round((screenWidth - stageWidth) / 2)
        const contentX = barX + 22
        const utilityRight = barX + stageWidth - 18 - 44
        const utilitiesX = utilityRight - 36 - (6 * 18 + 5 * 30)

        if (type === "time")
            return 55
        if (type === "apps" || type === "search")
            return 210
        if (type === "workspaces")
            return 395
        if (type === "media")
            return screenWidth / 2
        if (type === "system" || type === "profile")
            return screenWidth - 24
        if (type === "volume")
            return utilitiesX + 9
        if (type === "wifi")
            return utilitiesX + 57
        if (type === "brightness")
            return utilitiesX + 105
        if (type === "notifications")
            return utilitiesX + 153
        if (type === "bluetooth")
            return utilitiesX + 201
        if (type === "battery")
            return utilitiesX + 249
        return barX + stageWidth / 2
    }

    function normalizeTopBarPopupCenterX(type, centerX) {
        const value = Number(centerX)
        if (!(value > 0) || Math.abs(value - defaultQuickPopupCenterY(type)) < 0.5)
            return defaultTopBarPopupCenterX(type)
        return value
    }

    function toggleTopBarQuickPopup(type, centerX) {
        const normalizedCenterX = normalizeTopBarPopupCenterX(type, centerX)
        if (quickPopupVisible && activeQuickPopupType !== type && quickPopupSurfaceReveal > 0.08) {
            toggleQuickPopup(type, defaultQuickPopupCenterY(type), normalizedCenterX)
            return
        }
        setTopBarPopupCenter(normalizedCenterX)
        toggleQuickPopup(type, defaultQuickPopupCenterY(type), normalizedCenterX)
    }

    function openTopBarSystemPage(page, centerX) {
        const nextPage = topBarSystemPageForType(page)
        if (nextPage.length <= 0)
            return

        const alreadyOpen = quickPopupType === "system"
        if (alreadyOpen && topBarSystemPage === nextPage) {
            closeQuickPopup()
            return
        }

        topBarSystemSlideDirection = topBarSystemPageIndex(nextPage) >= topBarSystemPageIndex(topBarSystemPage) ? 1 : -1
        topBarSystemPage = nextPage
        const rightCenter = Math.max(Number(centerX) || 0, defaultTopBarPopupCenterX("system"))
        setTopBarPopupCenter(rightCenter)

        if (alreadyOpen) {
            quickPopupWindowOpen = true
            quickPopupUnmountTimer.stop()
            return
        }
        armSystemPopupKeyboardFocus()
        toggleTopBarQuickPopup("system", rightCenter)
    }

    function armSystemPopupKeyboardFocus() {
        systemPopupFocusWorkspaceId = focusedWorkspaceId
        systemPopupKeyboardFocus = true
    }

    function releaseSystemPopupKeyboardFocus() {
        systemPopupKeyboardFocus = false
        systemPopupFocusWorkspaceId = -1
    }

    function moveTopBarSystemPage(direction) {
        if (quickPopupType !== "system" || topBarSystemPages.length <= 0)
            return

        const current = topBarSystemPageIndex(topBarSystemPage)
        const count = topBarSystemPages.length
        const next = (current + (direction < 0 ? -1 : 1) + count) % count
        topBarSystemSlideDirection = direction < 0 ? -1 : 1
        topBarSystemPage = String(topBarSystemPages[next])
    }

    function toggleSystemPanel() {
        if (!topBarLayout)
            return
        if (quickPopupType === "system") {
            closeQuickPopup()
            return
        }
        topBarSystemSlideDirection = topBarSystemPageIndex("settings") >= topBarSystemPageIndex(topBarSystemPage) ? 1 : -1
        topBarSystemPage = "settings"
        openTopBarSystemPage("settings", defaultTopBarPopupCenterX("system"))
    }

    function previewTopBarPopup(type, centerX) {
        setTopBarPopupCenter(normalizeTopBarPopupCenterX(type, centerX))
        previewSidebarPopup(type, defaultQuickPopupCenterY(type))
    }

    function prepareQuickPopupCloseAnimation() {
        const closingType = activeQuickPopupType.length > 0 ? activeQuickPopupType : visibleQuickPopupType
        if (closingType.length <= 0)
            return

        renderedQuickPopupType = closingType
        quickPopupWindowOpen = true
        quickPopupUnmountTimer.stop()
    }

    function closeQuickPopup() {
        activeRailControl = ""
        if (!quickPopupSwitching) {
            quickPopupSwitchTimer.stop()
            pendingQuickPopupType = ""
            pendingQuickPopupCenterY = 0
            pendingTopBarPopupCenterX = 0
        }
        prepareQuickPopupCloseAnimation()
        releaseSystemPopupKeyboardFocus()
        quickPopupHoldOpen = false
        quickPopupType = ""
        hoverPopupType = ""
        sidebarPopupHovering = false
        quickPopupHovering = false
        hoverCloseTimer.stop()
    }

    function discardQuickPopupAnimation() {
        closeQuickPopup()
        quickPopupSurfaceRevealAnimation.stop()
        quickPopupSurfaceReveal = 0
        quickPopupUnmountTimer.stop()
        quickPopupWindowOpen = false
        renderedQuickPopupType = ""
    }

    function previewSidebarPopup(type, centerY) {
        if (!type || type.length <= 0)
            return

        if (weatherTopOpen && weatherTopMode === "search")
            return

        if (wallpaperSelectorOpen || settingsPanelOpen)
            return

        if (type !== "search")
            quickPopupHoldOpen = false

        exitFocus()
        setQuickPopupCenter(type, centerY)
        renderedQuickPopupType = type
        quickPopupWindowOpen = true
        quickPopupUnmountTimer.stop()
        hoverCloseTimer.stop()
        sidebarPopupHovering = true
        quickPopupType = ""
        hoverPopupType = type
        wallpaperSelectorOpen = false
        settingsPanelOpen = false
    }

    function endSidebarPopupHover(type) {
        if (hoverPopupType !== type)
            return

        sidebarPopupHovering = false
        scheduleHoverClose()
    }

    function scheduleHoverClose() {
        if (quickPopupHoldOpen)
            return
        if (hoverPopupType.length > 0)
            hoverCloseTimer.restart()
    }

    function clearHoveredSidebarPopup() {
        if (quickPopupHoldOpen)
            return
        if (quickPopupType.length > 0 || wallpaperSelectorOpen || settingsPanelOpen)
            return

        if (!quickPopupHovering && !wallpaperSelectorHovering && !settingsPanelHovering) {
            prepareQuickPopupCloseAnimation()
            sidebarPopupHovering = false
            hoverPopupType = ""
        }
    }

    function toggleQuickPopup(type, centerY, topCenterX) {
        hoverPopupType = ""
        hoverCloseTimer.stop()
        if (quickPopupType === type) {
            prepareQuickPopupCloseAnimation()
            quickPopupHoldOpen = false
            quickPopupType = ""
            return
        }

        openQuickPopup(type, centerY, topCenterX)
    }

    function setQuickPopupHoldOpen(type, held) {
        if (type !== "search" && type !== "apps")
            return

        const nextHeld = held === true && (quickPopupType === type || hoverPopupType === type || activeQuickPopupType === type)
        quickPopupHoldOpen = nextHeld
        if (!nextHeld)
            return

        hoverCloseTimer.stop()
        if (hoverPopupType === type && quickPopupType.length <= 0) {
            hoverPopupType = ""
            quickPopupType = type
        }
    }

    function openAdaptiveBarPopup(type, centerY) {
        if (sideBarLayoutEnabled) {
            if (["volume", "brightness", "battery"].indexOf(type) >= 0) {
                const nextControl = activeRailControl === type ? "" : type
                exitFocus()
                discardQuickPopupAnimation()
                disableWeatherTopNow()
                toggleTopWallpaperPopup(false, false)
                closeLegacyLeftMenu()
                closeRightDashboard()
                wallpaperSelectorOpen = false
                wallpaperSelectorWindowOpen = false
                settingsPanelOpen = false
                settingsPanelWindowOpen = false
                activeRailControl = nextControl
                return
            }
            if (["wifi", "notifications", "bluetooth"].indexOf(type) >= 0)
                return
        }
        if (!sideBarLayoutEnabled) {
            const systemPage = topBarSystemPageForType(type)
            if (systemPage.length > 0) {
                openTopBarSystemPage(systemPage, centerY)
                return
            }
            toggleTopBarQuickPopup(type, centerY)
            return
        }

        closeTopBarPopup()
        closeLegacyLeftMenu()
        closeRightDashboard()
        toggleQuickPopup(type, centerY)
    }

    function openTopBarPopup(type, centerX) {
        const systemPage = topBarSystemPageForType(type)
        if (systemPage.length > 0)
            openTopBarSystemPage(systemPage, centerX)
        else
            toggleTopBarQuickPopup(type, centerX)
    }

    function closeTopBarPopup() {
        topBarPopupCenterX = 0
    }

    function previewAdaptiveBarPopup(type, centerY) {
        if (sideBarLayoutEnabled && (type === "volume" || type === "brightness")) {
            railControlHoverTarget = type
            railControlCloseTimer.stop()
            if (activeRailControl !== type) railControlOpenTimer.restart()
            return
        }
        if (sideBarLayoutEnabled && ["battery", "wifi", "notifications", "bluetooth"].indexOf(type) >= 0)
            return
        if (weatherTopOpen && weatherTopMode === "search")
            return

        if (!sideBarLayoutEnabled) {
            const systemPage = topBarSystemPageForType(type)
            if (systemPage.length > 0) {
                topBarSystemSlideDirection = topBarSystemPageIndex(systemPage) >= topBarSystemPageIndex(topBarSystemPage) ? 1 : -1
                topBarSystemPage = systemPage
                previewTopBarPopup("system", defaultTopBarPopupCenterX("system"))
            } else {
                previewTopBarPopup(type, centerY)
            }
            return
        }

        closeLegacyLeftMenu()
        closeRightDashboard()
        previewSidebarPopup(type, centerY)
    }

    function endAdaptiveBarPopupHover(type) {
        if (sideBarLayoutEnabled && (type === "volume" || type === "brightness")) {
            if (railControlHoverTarget === type) railControlHoverTarget = ""
            railControlOpenTimer.stop()
            railControlCloseTimer.restart()
            return
        }
        if (!sideBarLayoutEnabled) {
            const systemPage = topBarSystemPageForType(type)
            endSidebarPopupHover(systemPage.length > 0 ? "system" : type)
            return
        }

        endSidebarPopupHover(type)
    }

    function openRightDashboard(section) {
        if (rightSoftLayout) {
            rightDashboardOpen = false
            return
        }

        const value = section && section.length > 0 ? section : "weather"
        activeRailControl = ""
        rightDashboardSection = value
        rightDashboardOpen = true
    }

    function closeRightDashboard() {
        rightDashboardOpen = false
    }

    function closeLegacyLeftMenu() {
        leftMenuPinned = false
        leftMenuInteractiveFocus = false
        leftMenuOpen = false
        leftMenuTriggerHovering = false
        leftMenuHandleHovering = false
        leftMenuHandleRevealHold = false
        leftMenuPanelHovering = false
        leftMediaWindowOpen = false
        leftMediaWindowHovering = false
        leftMediaWindowEntranceHold = false
        leftDetailSwitchProgress = 1
        leftMenuCloseTimer.stop()
        leftMenuHandleRevealTimer.stop()
        leftMediaWindowEntranceHoldTimer.stop()
    }

    function openLeftMenu() {
        closeLegacyLeftMenu()
    }

    function updateLeftMenuHovering() {
        leftMenuHovering = leftMenuTriggerHovering || leftMenuHandleHovering || leftMenuPanelHovering || leftMediaWindowHovering || leftMediaWindowEntranceHold
    }

    function holdLeftMenuHandleReveal() {
        leftMenuHandleRevealHold = true
        leftMenuHandleRevealTimer.restart()
    }

    function releaseLeftMenuHandleRevealSoon() {
        if (!leftMenuTriggerHovering && !leftMenuHandleHovering)
            leftMenuHandleRevealTimer.restart()
    }

    function scheduleLeftMenuClose() {
        updateLeftMenuHovering()
        if (!leftMenuHovering)
            leftMenuCloseTimer.restart()
    }

    function openLeftDetailWindow(type, centerY, pinned) {
        const value = Number(centerY)
        const nextType = type && type.length > 0 ? type : "media"
        leftMenuPinned = false
        leftMenuInteractiveFocus = false
        const switching = leftMediaWindowOpen && leftDetailWindowType !== nextType
        leftDetailWindowType = nextType
        if (switching) {
            leftDetailSwitchProgress = 0
            Qt.callLater(function() {
                if (root.leftMediaWindowOpen)
                    root.leftDetailSwitchProgress = 1
            })
        } else {
            leftDetailSwitchProgress = 1
        }
        leftMediaWindowCenterY = value > 0 ? value : 300
        leftMediaWindowEntranceHold = true
        leftMediaWindowEntranceHoldTimer.restart()
        leftMediaWindowOpen = true
        openLeftMenu()
    }

    function openLeftMediaWindow(centerY) {
        openLeftDetailWindow("media", centerY)
    }

    function leftDetailWindowWidth(type) {
        if (type === "paint")
            return 720
        if (type === "clock")
            return 430
        if (type === "wallpaper")
            return 380
        return leftMediaWindowWidth
    }

    function leftMenuHeightForScreen(screenHeight) {
        const available = Math.max(390, screenHeight - leftMenuFrameInset * 2 - 250)
        return Math.round(Math.max(390, Math.min(leftMenuPreferredHeight, available)))
    }

    function leftMenuYForScreen(screenHeight, menuHeight) {
        const centered = Math.round((screenHeight - menuHeight) / 2 + 18)
        return Math.round(Math.max(leftMenuFrameInset, Math.min(screenHeight - leftMenuFrameInset - menuHeight, centered)))
    }

    function leftDetailWindowHeight(type, screenHeight) {
        const available = Math.max(360, screenHeight - leftMenuFrameInset * 2)
        if (type === "paint")
            return Math.min(920, available)
        if (type === "clock")
            return Math.min(900, available)
        if (type === "wallpaper")
            return Math.min(1040, available)
        return Math.min(leftMediaWindowHeight, available)
    }

    function leftMediaWindowY(panelHeight, screenHeight) {
        const edgeMargin = leftMenuFrameInset
        const wanted = leftMediaWindowCenterY - panelHeight / 2
        return Math.round(Math.max(edgeMargin, Math.min(screenHeight - panelHeight - edgeMargin, wanted)))
    }

    function barX(screenWidth) {
        return barOnRight ? Math.max(0, screenWidth - sidebarOuterMargin - sidebarVisualWidth) : sidebarOuterMargin
    }

    function mainAreaX(screenWidth) {
        if (!sideBarLayoutEnabled)
            return frameVisualInset
        return barOnRight ? frameVisualInset : barPanelWidth
    }

    function mainAreaRightInset(screenWidth) {
        if (!sideBarLayoutEnabled)
            return frameVisualInset
        return barOnRight ? barPanelWidth : frameVisualInset
    }

    function mainAreaWidth(screenWidth) {
        return Math.max(0, screenWidth - mainAreaX(screenWidth) - mainAreaRightInset(screenWidth))
    }

    function quickPopupX(type, screenWidth, popupWidth) {
        const left = mainAreaX(screenWidth)
        const right = screenWidth - mainAreaRightInset(screenWidth)
        return SurfaceGeometry.clamp(Math.round(preferredQuickPopupX(type, screenWidth, popupWidth)), Math.ceil(left), Math.floor(right - popupWidth))
    }

    function preferredQuickPopupX(type, screenWidth, popupWidth) {
        if (quickPopupUsesReferencePlacement(type)) {
            const edge = Math.max(0, frameVisualInset)
            if (type === "settingsQuick" || type === "notifications")
                return Math.round(Math.max(edge, screenWidth - popupWidth - edge))
            if (type === "wifi")
                return 0

            return Math.round(Math.max(edge, Math.min(screenWidth - popupWidth - edge, (screenWidth - popupWidth) / 2)))
        }

        if (type === "agenda" || type === "weatherPanel") {
            const areaLeft = mainAreaX(screenWidth)
            const areaRight = screenWidth - mainAreaRightInset(screenWidth)
            const maxX = Math.max(frameVisualInset, areaRight - popupWidth)
            const wanted = areaLeft + (mainAreaWidth(screenWidth) - popupWidth) / 2
            return Math.round(Math.max(frameVisualInset, Math.min(maxX, wanted)))
        }
        if (barOnRight) {
            const clearance = Math.max(popupFrameGap, sideQuickPopupBarClearance)
            return Math.round(Math.max(frameVisualInset, barX(screenWidth) - clearance - popupWidth))
        }
        return barX(screenWidth) + sidebarVisualWidth + popupFrameGap
    }

    function quickPopupLeftBleed(type) {
        return topBarLayout && type === "wifi" ? 2 : 0
    }

    function quickPopupTypeAttachedToBar(type) {
        return !quickPopupUsesReferencePlacement(type) && type !== "agenda" && type !== "weatherPanel"
    }

    function quickPopupUsesReferencePlacement(type) {
        // The corner/reference arrangement belongs to the top bar only.
        // Side bars keep their popups attached to the originating control.
        return topBarLayout && (type === "quickSettings"
            || type === "settingsQuick"
            || type === "search"
            || type === "bluetooth"
            || type === "wifi"
            || type === "battery"
            || type === "volume"
            || type === "brightness"
            || type === "notifications")
    }

    function attachedPopupX(screenWidth, popupWidth) {
        if (barOnRight) {
            const clearance = Math.max(popupFrameGap, sideQuickPopupBarClearance)
            return Math.round(Math.max(frameVisualInset, barX(screenWidth) - clearance - popupWidth))
        }
        return barX(screenWidth) + sidebarVisualWidth + popupFrameGap
    }

    function leftMenuAttachedPopupX(screenWidth, popupWidth) {
        if (leftMenuOnLeft)
            return leftMenuFrameInset + leftMenuWidth + leftMediaWindowGap
        return Math.round(Math.max(frameVisualInset, screenWidth - leftMenuFrameInset - leftMenuWidth - leftMediaWindowGap - popupWidth))
    }

    function quickPopupWidth(type) {
        if (type === "theme")
            return 820
        if (type === "settings")
            return 1510
        if (type === "agenda")
            return 1510
        if (type === "weatherPanel")
            return 1510
        if (type === "time")
            return 470
        if (type === "search")
            return 540
        if (type === "files")
            return 548
        if (type === "browser")
            return 1265
        if (type === "volume")
            return 342
        if (type === "wifi")
            return 410
        if (type === "brightness")
            return 448
        if (type === "quickSettings")
            return 520
        if (type === "settingsQuick")
            return 410
        if (type === "notifications")
            return 522
        if (type === "battery")
            return 365
        if (type === "bluetooth")
            return 520
        if (type === "wallpaperVisibility")
            return 372
        if (type === "workspaces")
            return 520
        if (type === "apps")
            return 560
        if (type === "media")
            return 470
        if (type === "profile")
            return 390
        return 286
    }

    function quickPopupWidthForScreen(type, screenWidth) {
        const available = Math.max(0, Math.floor(mainAreaWidth(screenWidth) - 16))
        if (type === "agenda" || type === "weatherPanel") {
            return Math.round(Math.min(available, Math.max(1510, Math.min(1680, mainAreaWidth(screenWidth) - 110))))
        }
        return Math.min(quickPopupWidth(type), available)
    }

    function quickPopupHeight(type) {
        if (type === "theme")
            return 520
        if (type === "settings")
            return 920
        if (type === "agenda")
            return 900
        if (type === "weatherPanel")
            return 900
        if (type === "time")
            return 990
        if (type === "search")
            return 470
        if (type === "files")
            return 720
        if (type === "browser")
            return 795
        if (type === "volume")
            return 565
        if (type === "wifi")
            return 735
        if (type === "brightness")
            return 570
        if (type === "quickSettings")
            return 440
        if (type === "settingsQuick")
            return 605
        if (type === "notifications") {
            const count = Math.min(7, Math.max(0, notificationHistoryCount))
            return count <= 0 ? 310 : Math.min(760, 142 + count * 82)
        }
        if (type === "battery")
            return 450
        if (type === "bluetooth")
            return 450
        if (type === "wallpaperVisibility")
            return 470
        if (type === "workspaces")
            return 390
        if (type === "apps")
            return 440
        if (type === "media")
            return 330
        if (type === "profile")
            return 340
        return 324
    }

    function quickPopupHeightForScreen(type, screenHeight) {
        if (type === "agenda" || type === "weatherPanel") {
            const available = Math.max(0, Math.floor(screenHeight - frameVisualInset * 2 - 64))
            return Math.min(1040, available)
        }
        return Math.min(quickPopupHeight(type), Math.max(0, Math.floor(screenHeight - 64)))
    }

    function quickPopupTopMargin(type) {
        if (type === "time" || type === "search" || type === "battery")
            return Math.max(frameVisualInset + popupFrameGap, 38)
        return frameVisualInset + popupFrameGap
    }

    function quickPopupY(type, panelHeight, screenHeight) {
        const edgeMargin = frameVisualInset + popupFrameGap
        const maxY = Math.floor(screenHeight - panelHeight - edgeMargin)
        function clampY(wanted) {
            if (maxY < edgeMargin)
                return Math.round(Math.max(edgeMargin, maxY))
            return Math.round(Math.max(edgeMargin, Math.min(maxY, wanted)))
        }

        if (quickPopupUsesReferencePlacement(type)) {
            if (type === "settingsQuick")
                return clampY(Math.max(frameVisualInset, Math.round(screenHeight * 0.18)))
            if (type === "quickSettings")
                return clampY(Math.round(screenHeight * 0.32))
            if (type === "search")
                return clampY(Math.round(screenHeight * 0.29))
            if (type === "wifi")
                return clampY(Math.max(frameVisualInset, Math.round(screenHeight * 0.066)))
            if (type === "bluetooth")
                return clampY(Math.round(screenHeight * 0.49))
            if (type === "battery")
                return clampY(screenHeight - panelHeight - frameVisualInset)
            if (type === "notifications")
                return clampY(Math.max(frameVisualInset, Math.round(screenHeight * 0.066)))
            return clampY(screenHeight - panelHeight - frameVisualInset)
        }

        if (type === "agenda" || type === "weatherPanel") {
            const wanted = (screenHeight - panelHeight) / 2
            return clampY(wanted)
        }

        const center = quickPopupCenterY > 0 ? quickPopupCenterY : defaultQuickPopupCenterY(type)
        const topMargin = quickPopupTopMargin(type)
        const wanted = center - panelHeight / 2
        if (maxY < topMargin)
            return Math.round(Math.max(edgeMargin, maxY))
        return Math.round(Math.max(topMargin, Math.min(maxY, wanted)))
    }

    Timer {
        id: hoverCloseTimer

        interval: 360
        repeat: false
        onTriggered: root.clearHoveredSidebarPopup()
    }

    Timer {
        id: leftMenuCloseTimer

        interval: 280
        repeat: false
        onTriggered: {
            root.updateLeftMenuHovering()
            if (!root.leftMenuHovering) {
                root.leftMenuInteractiveFocus = false
                root.leftMenuOpen = false
            }
        }
    }

    Timer {
        id: leftMenuHandleRevealTimer

        interval: Math.max(460, veloraTheme.motionHover + 260)
        repeat: false
        onTriggered: {
            if (!root.leftMenuTriggerHovering && !root.leftMenuHandleHovering)
                root.leftMenuHandleRevealHold = false
        }
    }

    Timer {
        id: leftMediaWindowEntranceHoldTimer

        interval: Math.max(520, veloraTheme.motionPanelIn + 180)
        repeat: false
        onTriggered: {
            root.leftMediaWindowEntranceHold = false
            root.scheduleLeftMenuClose()
        }
    }

    Behavior on leftMenuFrameReveal {
        enabled: veloraTheme.motionEnabled
        NumberAnimation {
            duration: root.leftMenuOpen ? veloraTheme.motionPanelIn : root.quickPopupLineCloseDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.leftMenuOpen ? veloraTheme.motionCurveEmphasizedAccel : veloraTheme.motionCurveStandard
        }
    }

    Behavior on leftMenuHandleSurfaceReveal {
        enabled: veloraTheme.motionEnabled
        NumberAnimation {
            duration: veloraTheme.motionHover
            easing.type: Easing.OutCubic
        }
    }

    Behavior on leftDetailSwitchProgress {
        enabled: veloraTheme.motionEnabled
        NumberAnimation {
            duration: veloraTheme.motionPanelGeometry
            easing.type: veloraTheme.motionEaseEmphasized
            easing.bezierCurve: veloraTheme.motionEmphasizedCurve
        }
    }

    Timer {
        id: leftMenuPreloadTimer

        interval: 700
        running: root.idlePreloadEnabled
        repeat: false
        onTriggered: root.leftMenuPreloadEnabled = false
    }

    Timer {
        id: quickPopupPreloadTimer

        interval: 1000
        running: false
        repeat: false
        onTriggered: {
            root.quickPopupPreloadEnabled = true
            root.quickPopupPreloadCount = Math.max(root.quickPopupPreloadCount, 1)
            quickPopupCacheWarmupTimer.restart()
        }
    }

    Timer {
        id: railControlOpenTimer
        interval: 110
        onTriggered: if (root.railControlHoverTarget && root.sideBarLayoutEnabled) root.activeRailControl = root.railControlHoverTarget
    }
    Timer {
        id: railControlCloseTimer
        interval: 180
        onTriggered: if (!root.railControlHoverTarget && !root.railControlPanelHovered) root.activeRailControl = ""
    }
    Timer {
        id: railControlFeedbackTimer
        interval: 1800
        onTriggered: if (!root.railControlHoverTarget && !root.railControlPanelHovered) root.activeRailControl = ""
    }

    Timer {
        id: quickPopupCacheWarmupTimer

        interval: 90
        repeat: true
        onTriggered: {
            if (!root.quickPopupPreloadEnabled) {
                stop()
                return
            }

            if (root.quickPopupPreloadCount >= root.cachedQuickPopupTypes.length) {
                stop()
                return
            }

            root.quickPopupPreloadCount += 1
        }
    }

    NumberAnimation {
        id: quickPopupSurfaceRevealAnimation

        target: root
        property: "quickPopupSurfaceReveal"
        from: root.quickPopupSurfaceReveal
        to: root.quickPopupVisible ? 1 : 0
        duration: veloraTheme.motionPanelIn
        easing.type: veloraTheme.motionEaseEnter
    }

    SequentialAnimation {
        id: systemSheetOpenAnimation

        NumberAnimation {
            id: systemSheetRiseAnimation
            target: root
            property: "systemSheetOffsetY"
            duration: 260
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            id: systemSheetSettleAnimation
            property: "systemSheetOffsetY"
            from: -10
            to: 0
            duration: 110
            easing.type: Easing.OutBack
        }
    }

    NumberAnimation {
        id: systemSheetCloseAnimation

        target: root
        property: "systemSheetOffsetY"
        duration: 220
        easing.type: Easing.InCubic
        onFinished: root.systemSheetClosing = false
    }

    Timer {
        id: quickPopupUnmountTimer

        interval: Math.max(veloraTheme.motionUnmountDelay, root.quickPopupLineCloseDuration + 160)
        repeat: false
        onTriggered: {
            if (!root.quickPopupVisible) {
                root.quickPopupWindowOpen = false
                root.renderedQuickPopupType = ""
                root.quickPopupSurfaceReveal = 0
                root.systemSheetClosing = false
            }
        }
    }

    Timer {
        id: quickPopupSwitchTimer

        interval: Math.max(220, root.quickPopupLineCloseDuration + 20)
        repeat: false
        onTriggered: {
            const nextType = root.pendingQuickPopupType
            const nextCenterY = root.pendingQuickPopupCenterY
            const nextCenterX = root.pendingTopBarPopupCenterX
            root.pendingQuickPopupType = ""
            root.pendingQuickPopupCenterY = 0
            root.pendingTopBarPopupCenterX = 0
            if (nextType.length <= 0) {
                root.quickPopupSwitching = false
                return
            }
            root.quickPopupSwitching = true
            root.openQuickPopup(nextType, nextCenterY, nextCenterX)
            root.quickPopupSwitching = false
        }
    }

    Timer {
        id: weatherTopUnmountTimer

        interval: Math.max(veloraTheme.motionUnmountDelay, root.quickPopupLineCloseDuration + 180)
        repeat: false
        onTriggered: if (!root.weatherTopOpen) root.weatherTopWindowOpen = false
    }

    Timer {
        id: weatherTopHoverCloseTimer

        interval: 320
        repeat: false
        onTriggered: if (!root.weatherTopKeyboardFocus && !root.weatherTopTriggerHovering && !root.weatherTopPanelHovering) root.closeWeatherTop()
    }

    Timer {
        id: searchPopupFocusTimer

        interval: 80
        repeat: false
        onTriggered: {
            if (root.quickPopupType !== "search"
                    && root.quickPopupType !== "apps") {
                return
            }

            root.focusSearchPopupInput()
            root.searchPopupFocusAttempts += 1
            if (root.searchPopupFocusAttempts < 10)
                restart()
        }
    }

    Timer {
        id: wallpaperSelectorUnmountTimer

        interval: veloraTheme.motionUnmountDelay
        repeat: false
        onTriggered: {
            if (!root.wallpaperSelectorVisible)
                root.wallpaperSelectorWindowOpen = false
        }
    }

    Timer {
        id: wallpaperPreloadTimer

        interval: 900
        running: root.idlePreloadEnabled
        repeat: false
        onTriggered: root.wallpaperPreloadEnabled = true
    }

    Timer {
        id: settingsPanelPreloadTimer

        interval: 1300
        running: root.idlePreloadEnabled
        repeat: false
        onTriggered: root.settingsPanelPreloadEnabled = true
    }

    Timer {
        id: settingsPanelUnmountTimer

        interval: veloraTheme.motionUnmountDelay
        repeat: false
        onTriggered: {
            if (!root.settingsPanelVisible)
                root.settingsPanelWindowOpen = false
        }
    }

    IpcHandler {
        target: "velora"

        function focus(): void {
            root.enterFocus()
        }

        function unfocus(): void {
            root.exitFocus()
        }

        function toggleFocus(): void {
            root.toggleFocus()
        }

        function theme(): void {
            root.showWallpaperSelector(root.defaultQuickPopupCenterY("theme"))
        }

        function wallpaper(): void {
            theme()
        }

        function wallpaperWavePrepare(frameDir: string, token: string, durationMs: int, sourcePath: string, transitionType: string): void {
            root.prepareWallpaperWave(frameDir, token, durationMs, sourcePath, transitionType)
        }

        function wallpaperWaveReveal(token: string): void {
            root.revealWallpaperWave(token)
        }

        function wallpaperWaveCancel(token: string): void {
            root.cancelWallpaperWave(token)
        }

        function topWallpaper(): void {
            root.toggleTopWallpaperPopup(null, true)
        }

        function wallpaperSelectorState(): string {
            const state = {}
            for (const name in root.wallpaperSelectorViews)
                state[name] = root.wallpaperSelectorViews[name].diagnostics()
            return JSON.stringify(state)
        }

        function topWallpaperNext(): void {
            root.moveTopWallpaper(1)
        }

        function topWallpaperPrevious(): void {
            root.moveTopWallpaper(-1)
        }

        function topWallpaperApply(): void {
            root.applyTopWallpaperSelection()
        }

        function closeTopWallpaper(): void {
            root.toggleTopWallpaperPopup(false, false)
        }

        function wallpaperFilter(): void {
            root.openWallpaperVisibility(root.defaultQuickPopupCenterY("theme"))
        }

        function filter(): void {
            wallpaperFilter()
        }

        function settings(): void {
            root.openUnifiedSettings()
        }

        function systemPanel(): void {
            root.toggleSystemPanel()
        }

        function systemPanelPage(page: string): void {
            const nextPage = root.topBarSystemPageForType(page)
            if (nextPage.length <= 0)
                return
            if (root.quickPopupType !== "system") {
                root.openTopBarSystemPage(nextPage, root.defaultTopBarPopupCenterX("system"))
                return
            }
            root.topBarSystemSlideDirection = root.topBarSystemPageIndex(nextPage)
                >= root.topBarSystemPageIndex(root.topBarSystemPage)
                ? 1
                : -1
            root.topBarSystemPage = nextPage
        }

        function systemPanelState(): string {
            return JSON.stringify({
                "topBarLayout": root.topBarLayout,
                "quickPopupType": root.quickPopupType,
                "quickPopupVisible": root.quickPopupVisible,
                "quickPopupWindowOpen": root.quickPopupWindowOpen,
                "renderedQuickPopupType": root.renderedQuickPopupType,
                "systemPage": root.topBarSystemPage,
                "systemKeyboardFocus": root.systemPopupKeyboardFocus,
                "focusedWorkspaceId": root.focusedWorkspaceId,
                "focusWorkspaceId": root.systemPopupFocusWorkspaceId,
                "sheetOffsetY": root.systemSheetOffsetY
            })
        }

        function preferences(): void {
            root.openUnifiedSettings()
        }

        function lock(): void {
            root.composition.showLock()
        }

        function lockHide(): void {
            root.composition.hideLock()
        }

        function lockToggle(): void {
            root.composition.toggleLock()
        }

        function editDesktop(): void {
            root.composition.openEditor("desktop")
        }

        function editLock(): void {
            root.composition.openEditor("lock")
        }

        function pywal16(): void {
            veloraTheme.applyTheme("pywal16")
        }

        function reloadPywal16(): void {
            veloraTheme.reloadPywal16()
        }

        function search(): void {
            root.toggleTopSearch()
        }

        function notificationState(): string {
            return JSON.stringify({ count: root.notificationHistoryCount,
                toastVisible: root.notificationToastVisible,
                toastTitle: root.notificationToastTitle, toastBody: root.notificationToastBody })
        }

        function weatherTop(): void {
            root.toggleWeatherTop()
        }

        function profile(): void {
            root.openAdaptiveBarPopup("quickSettings", root.defaultQuickPopupCenterY("quickSettings"))
        }

        function topbarWorkspaces(): void {
            if (root.topBarLayout)
                root.openTopBarPopup("workspaces", root.defaultTopBarPopupCenterX("workspaces"))
        }

        function topbarApps(): void {
            if (root.topBarLayout)
                root.openTopBarPopup("apps", root.defaultTopBarPopupCenterX("apps"))
        }

        function topbarMedia(): void {
            if (root.topBarLayout)
                root.openTopBarPopup("media", root.defaultTopBarPopupCenterX("media"))
        }

        function topbarProfile(): void {
            if (root.topBarLayout)
                root.openTopBarPopup("profile", root.defaultTopBarPopupCenterX("profile"))
        }

        function time(): void {
            root.openAdaptiveBarPopup("time", root.defaultQuickPopupCenterY("time"))
        }

        function agenda(): void {
            root.openAdaptiveBarPopup("agenda", root.defaultQuickPopupCenterY("agenda"))
        }

        function weatherPanel(): void {
            root.openAdaptiveBarPopup("weatherPanel", root.defaultQuickPopupCenterY("weatherPanel"))
        }

        function clima(): void {
            weatherPanel()
        }

        function files(): void {
            root.launchApp(root.filesCommand)
        }

        function browser(): void {
            root.launchApp(root.browserCommand)
        }

        function volume(): void {
            root.openAdaptiveBarPopup("volume", root.defaultQuickPopupCenterY("volume"))
        }

        function railLevel(kind: string): void {
            if (kind !== "volume" && kind !== "brightness") return
            root.railFeedbackSerial += 1
            if (!root.sideBarLayoutEnabled) return
            railControlCloseTimer.stop()
            root.activeRailControl = kind
            railControlFeedbackTimer.restart()
        }

        function wifi(): void {
            root.openAdaptiveBarPopup("wifi", root.defaultQuickPopupCenterY("wifi"))
        }

        function brightness(): void {
            root.openAdaptiveBarPopup("brightness", root.defaultQuickPopupCenterY("brightness"))
        }

        function notifications(): void {
            root.openAdaptiveBarPopup("notifications", root.defaultQuickPopupCenterY("notifications"))
        }

        function bluetooth(): void {
            if (root.sideBarLayoutEnabled) {
                for (const surface of sidebarPanels.instances)
                    surface.bluetoothMenu.toggle()
                return
            }
            root.openAdaptiveBarPopup("bluetooth", root.defaultQuickPopupCenterY("bluetooth"))
        }

        function bluetoothState(): string {
            return JSON.stringify(sidebarPanels.instances.map(surface => {
                const menu = surface.bluetoothMenu
                return { monitor: surface.modelData.name, opened: menu.opened,
                    mounted: menu.mounted, managing: menu.managing,
                    available: menu.available, powered: menu.powered,
                    scanning: menu.manager.scanning, devices: menu.devices.length,
                    error: menu.manager.error }
            }))
        }

        function battery(): void {
            root.openAdaptiveBarPopup("battery", root.defaultQuickPopupCenterY("battery"))
        }

        function weather(): void {
            root.openRightDashboard("weather")
        }

        function system(): void {
            root.toggleSystemPanel()
        }

        function calendar(): void {
            root.openRightDashboard("calendar")
        }

        function media(): void {
            if (root.sideBarLayoutEnabled) root.railMediaRequested()
            else root.openRightDashboard("media")
        }

        function leftMenu(): void {
            root.leftMenuPinned = false
            root.leftMediaWindowOpen = false
            root.leftMediaWindowEntranceHold = false
            root.leftDetailSwitchProgress = 1
            root.updateLeftMenuHovering()
            root.openLeftMenu()
            root.scheduleLeftMenuClose()
        }

        function closeLeftMenu(): void {
            root.closeLegacyLeftMenu()
        }

        function leftMedia(): void {
            root.openLeftDetailWindow("media", root.leftMediaWindowCenterY > 0 ? root.leftMediaWindowCenterY : 560, true)
        }

        function leftClock(): void {
            root.openLeftDetailWindow("clock", root.leftMediaWindowCenterY > 0 ? root.leftMediaWindowCenterY : 560, true)
        }

        function leftPaint(): void {
            root.openLeftDetailWindow("paint", root.leftMediaWindowCenterY > 0 ? root.leftMediaWindowCenterY : 560, true)
        }

        function leftWallpaper(): void {
            root.openLeftDetailWindow("wallpaper", root.leftMediaWindowCenterY > 0 ? root.leftMediaWindowCenterY : 560, true)
        }

        function closeLeftMedia(): void {
            root.leftMenuPinned = false
            root.leftMediaWindowOpen = false
            root.leftMediaWindowEntranceHold = false
            root.leftDetailSwitchProgress = 1
        }

        function memo(): void {
            root.openRightDashboard("memo")
        }

        function todo(): void {
            root.openRightDashboard("todo")
        }

        function closeDashboard(): void {
            root.closeRightDashboard()
        }

        function barLeft(): void {
            veloraTheme.setBarPosition("left")
        }

        function barRight(): void {
            veloraTheme.setBarPosition("right")
        }

        function frameOn(): void {
            veloraTheme.setDesktopFrameEnabled(true)
        }

        function frameOff(): void {
            veloraTheme.setDesktopFrameEnabled(false)
        }







        function layoutCycle(): void {
            root.cycleBarLayout()
        }
    }

    Variants {
        model: root.infiniteDesktopGestureMounted ? Quickshell.screens : []

        PanelWindow {
            id: infiniteDesktopGesturePanel

            required property var modelData

            screen: modelData
            color: "transparent"
            implicitWidth: modelData.width > 0 ? modelData.width : 1
            implicitHeight: modelData.height > 0 ? modelData.height : 1
            exclusionMode: ExclusionMode.Ignore
            focusable: false

            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "velora-infinite-desktop-gesture"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            mask: Region {
                item: infiniteDesktopGesture
            }

            VeloraInfiniteDesktopGesture {
                id: infiniteDesktopGesture

                anchors.fill: parent
                bridgePath: root.infiniteDesktopCommand
            }
        }
    }

    Variants {
        model: root.wallpaperWaveMounted ? Quickshell.screens : []

        PanelWindow {
            id: wallpaperWavePanel

            required property var modelData
            readonly property string outputName: modelData && modelData.name ? String(modelData.name) : "eDP-1"

            screen: modelData
            color: "transparent"
            implicitWidth: modelData.width > 0 ? modelData.width : 1
            implicitHeight: modelData.height > 0 ? modelData.height : 1
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            focusable: false

            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "velora-wallpaper-transition"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            mask: Region {}

            VeloraWallpaperTransition {
                anchors.fill: parent
                source: root.wallpaperWaveUrl(root.wallpaperWaveSourcePath)
                directionX: root.wallpaperWaveDirectionX
                directionY: root.wallpaperWaveDirectionY
                wavePhase: root.wallpaperWavePhase
                transitionType: root.wallpaperWaveTransition
                readyPath: root.wallpaperWaveReadyPath(wallpaperWavePanel.outputName)
                transitionProgress: root.wallpaperWaveProgress
            }
        }
    }

    Variants {
        model: root.lyricsOverlayMounted ? Quickshell.screens : []

        PanelWindow {
            id: lyricsPanel

            required property var modelData
            readonly property int panelWidth: modelData.width > 0 ? modelData.width : 1920
            readonly property int panelHeight: modelData.height > 0 ? modelData.height : 1200
            readonly property color lyricsTextColor: veloraTheme.lyricsColorMode === "manual" ? veloraTheme.lyricsManualColor : veloraTheme.lyricsPywalColor
            property real floatPhase: 0

            function wordFloatX(sourceIndex) {
                return veloraTheme.lyricsFloatEnabled && !root.topBarLayout ? Math.sin(floatPhase + Number(sourceIndex) * 1.37) * veloraTheme.lyricsFloatIntensity : 0
            }

            function wordFloatY(sourceIndex) {
                return veloraTheme.lyricsFloatEnabled && !root.topBarLayout ? Math.cos(floatPhase * 0.82 + Number(sourceIndex) * 1.11) * veloraTheme.lyricsFloatIntensity * 0.45 : 0
            }

            function lyricsGlowRadius(blockIndex) {
                const glowRadius = root.lyricsBlockGlowEnabled(blockIndex) ? Math.round(8 + root.lyricsBlockGlowIntensity(blockIndex) * 30) : 0
                const depthRadius = veloraTheme.lyricsDepthEnabled ? Math.round(4 + veloraTheme.lyricsDepthIntensity * 16) : 0
                return Math.max(1, glowRadius, depthRadius)
            }

            function lyricsGlowSamples(blockIndex) {
                const glowRadius = lyricsGlowRadius(blockIndex)
                return Math.max(17, glowRadius * 2 + 1)
            }

            function lyricsEffectEnabled(blockIndex) {
                return (root.lyricsBlockGlowEnabled(blockIndex) && root.lyricsBlockGlowIntensity(blockIndex) > 0.01) || veloraTheme.lyricsDepthEnabled
            }

            function lyricsEffectHorizontalOffset(blockIndex) {
                if (!veloraTheme.lyricsDepthEnabled)
                    return 0
                return Math.round(1 + veloraTheme.lyricsDepthIntensity * 4)
            }

            function lyricsEffectVerticalOffset(blockIndex) {
                if (!veloraTheme.lyricsDepthEnabled)
                    return 0
                return Math.round(2 + veloraTheme.lyricsDepthIntensity * 6)
            }

            function lyricsGlowColor(colorValue, active, blockIndex) {
                if (root.lyricsBlockGlowEnabled(blockIndex) && root.lyricsBlockGlowIntensity(blockIndex) > 0.01) {
                    const intensity = root.lyricsBlockGlowIntensity(blockIndex)
                    const alpha = Math.min(0.92, (active ? 0.28 : 0.16) + intensity * (active ? 0.50 : 0.34))
                    return veloraTheme.withAlpha(colorValue, alpha)
                }

                const depth = veloraTheme.lyricsDepthEnabled ? veloraTheme.lyricsDepthIntensity : 0
                return Qt.rgba(0.04, 0.10, 0.18, (active ? 0.20 : 0.13) + depth * (active ? 0.28 : 0.20))
            }

            function cinematicPhraseWidth(side) {
                return Math.round(Math.min(panelWidth * 0.36, Math.max(320, panelWidth * 0.26)))
            }

            function cinematicPhraseX(side, role) {
                const widthHint = cinematicPhraseWidth(side)
                const progress = root.lyricsPhraseProgress
                const dir = side === 0 ? -1 : 1
                const pct = side === 0 ? veloraTheme.lyricsPositionX : veloraTheme.lyricsSecondPositionX
                const base = Math.max(18, Math.min(panelWidth - widthHint - 18, panelWidth * pct / 100))

                if (role === "previous")
                    return Math.round(base + dir * (38 + 70 * progress))
                if (role === "next")
                    return Math.round(base - dir * 76)
                return Math.round(base - dir * (56 * (1 - progress)))
            }

            function cinematicPhraseY(side, role) {
                const progress = root.lyricsPhraseProgress
                const pct = side === 0 ? veloraTheme.lyricsPositionY : veloraTheme.lyricsSecondPositionY
                const base = Math.max(root.topBarPanelTopMargin(panelHeight) + root.topBarPanelHeight(panelHeight) + 18, Math.min(panelHeight * 0.62, panelHeight * pct / 100))

                if (role === "previous")
                    return Math.round(base + 20 + progress * 24)
                if (role === "next")
                    return Math.round(base + 16)
                return Math.round(base + (1 - progress) * 10)
            }

            function cinematicTextColor(side, sourceIndex, active) {
                const color = root.lyricsWordColor(sourceIndex, side)
                return root.lyricsMaterialColor(color, sourceIndex, active)
            }

            NumberAnimation on floatPhase {
                from: 0
                to: 6.28318
                duration: 5200
                loops: Animation.Infinite
                running: veloraTheme.lyricsFloatEnabled && root.lyricsOverlayMounted && !root.topBarLayout
            }

            screen: modelData
            color: "transparent"
            implicitWidth: panelWidth
            implicitHeight: panelHeight
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            focusable: false

            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "velora-shell-lyrics"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            mask: Region {}

            Item {
                id: lyricsContent

                anchors.fill: parent
                layer.enabled: veloraTheme.lyricsMaskEnabled && veloraTheme.lyricsMaskHasStrokes
                layer.smooth: true
                layer.effect: OpacityMask {
                    maskSource: lyricsCutMaskSource
                }

            Item {
                id: lyricsCinematicLayer

                anchors.fill: parent
                visible: root.lyricsCinematicModeActive()
                z: 3

                Text {
                    id: lyricsPreviousPhraseText

                    readonly property int phraseSide: root.lyricsGhostSide
                    readonly property real progress: root.lyricsPhraseProgress

                    visible: root.lyricsGhostText.length > 0 && progress < 0.995
                    text: root.lyricsGhostText
                    x: lyricsPanel.cinematicPhraseX(phraseSide, "previous")
                    y: lyricsPanel.cinematicPhraseY(phraseSide, "previous")
                    width: lyricsPanel.cinematicPhraseWidth(phraseSide)
                    wrapMode: Text.WordWrap
                    lineHeight: 0.92
                    color: lyricsPanel.cinematicTextColor(phraseSide, root.lyricsActiveIndex, false)
                    opacity: Math.max(0, 0.42 * (1 - progress))
                    scale: Math.max(0.78, 0.94 - progress * 0.12)
                    transformOrigin: Item.Center
                    font.family: veloraTheme.uiFont
                    font.pixelSize: Math.round(veloraTheme.lyricsFontSize * 0.92)
                    font.weight: Font.Black
                    font.letterSpacing: 0
                    style: Text.Outline
                    styleColor: root.lyricsOutlineColor(false)
                    renderType: Text.NativeRendering
                    layer.enabled: lyricsPanel.lyricsEffectEnabled(phraseSide)
                    layer.smooth: true
                    layer.effect: DropShadow {
                        horizontalOffset: lyricsPanel.lyricsEffectHorizontalOffset(lyricsPreviousPhraseText.phraseSide)
                        verticalOffset: lyricsPanel.lyricsEffectVerticalOffset(lyricsPreviousPhraseText.phraseSide)
                        radius: lyricsPanel.lyricsGlowRadius(lyricsPreviousPhraseText.phraseSide)
                        samples: lyricsPanel.lyricsGlowSamples(lyricsPreviousPhraseText.phraseSide)
                        spread: 0
                        transparentBorder: true
                        color: lyricsPanel.lyricsGlowColor(lyricsPreviousPhraseText.color, false, lyricsPreviousPhraseText.phraseSide)
                    }
                }

                Text {
                    id: lyricsNextPhraseText

                    readonly property var phrase: root.lyricsNextPhrase()
                    readonly property int phraseSide: Number(phrase.side) || 0
                    readonly property int phraseStart: Number(phrase.start) || 0

                    visible: phrase.text.length > 0 && phrase.text !== root.lyricsCurrentPhrase().text
                    text: phrase.text
                    x: lyricsPanel.cinematicPhraseX(phraseSide, "next")
                    y: lyricsPanel.cinematicPhraseY(phraseSide, "next")
                    width: lyricsPanel.cinematicPhraseWidth(phraseSide)
                    wrapMode: Text.WordWrap
                    lineHeight: 0.92
                    color: lyricsPanel.cinematicTextColor(phraseSide, phraseStart, false)
                    opacity: Math.min(0.20, 0.06 + root.lyricsPhraseProgress * 0.14)
                    scale: 0.82
                    transformOrigin: Item.Center
                    font.family: veloraTheme.uiFont
                    font.pixelSize: Math.round(veloraTheme.lyricsFontSize * 0.86)
                    font.weight: Font.Black
                    font.letterSpacing: 0
                    style: Text.Outline
                    styleColor: root.lyricsOutlineColor(false)
                    renderType: Text.NativeRendering
                }

                Text {
                    id: lyricsCurrentPhraseText

                    readonly property var phrase: root.lyricsCurrentPhrase()
                    readonly property int phraseSide: Number(phrase.side) || 0
                    readonly property int phraseStart: Number(phrase.start) || 0
                    readonly property real progress: root.lyricsPhraseProgress

                    visible: phrase.text.length > 0
                    text: phrase.text
                    x: lyricsPanel.cinematicPhraseX(phraseSide, "current")
                    y: lyricsPanel.cinematicPhraseY(phraseSide, "current")
                    width: lyricsPanel.cinematicPhraseWidth(phraseSide)
                    wrapMode: Text.WordWrap
                    lineHeight: 0.90
                    color: lyricsPanel.cinematicTextColor(phraseSide, phraseStart, true)
                    opacity: Math.max(0.22, 0.18 + progress * 0.82)
                    scale: 0.92 + progress * 0.08
                    transformOrigin: Item.Center
                    font.family: veloraTheme.uiFont
                    font.pixelSize: Math.round(veloraTheme.lyricsFontSize * 1.08)
                    font.weight: Font.Black
                    font.letterSpacing: 0
                    style: Text.Outline
                    styleColor: root.lyricsOutlineColor(true)
                    renderType: Text.NativeRendering
                    layer.enabled: lyricsPanel.lyricsEffectEnabled(phraseSide)
                    layer.smooth: true
                    layer.effect: DropShadow {
                        horizontalOffset: lyricsPanel.lyricsEffectHorizontalOffset(lyricsCurrentPhraseText.phraseSide)
                        verticalOffset: lyricsPanel.lyricsEffectVerticalOffset(lyricsCurrentPhraseText.phraseSide)
                        radius: lyricsPanel.lyricsGlowRadius(lyricsCurrentPhraseText.phraseSide)
                        samples: lyricsPanel.lyricsGlowSamples(lyricsCurrentPhraseText.phraseSide)
                        spread: 0
                        transparentBorder: true
                        color: lyricsPanel.lyricsGlowColor(lyricsCurrentPhraseText.color, true, lyricsCurrentPhraseText.phraseSide)
                    }
                }
            }

            Item {
                id: lyricsBlock

                readonly property real wordStep: Math.round(veloraTheme.lyricsFontSize + veloraTheme.lyricsWordSpacing)
                readonly property bool centered: veloraTheme.lyricsLayoutMode === "centered"
                readonly property bool cascade: veloraTheme.lyricsLayoutMode === "cascade"
                readonly property var visibleWords: root.renderedLyricsWords()

                visible: veloraTheme.lyricsLayoutMode !== "two" && veloraTheme.lyricsLayoutMode !== "four"
                x: Math.round(Math.max(0, Math.min(parent.width - 24, parent.width * veloraTheme.lyricsPositionX / 100)))
                y: Math.round(Math.max(0, Math.min(parent.height - 24, parent.height * veloraTheme.lyricsPositionY / 100)))
                width: Math.max(240, parent.width - x - 24)
                height: Math.max(80, visibleWords.length * wordStep + 20)
                opacity: veloraTheme.lyricsOpacity
                clip: false
                scale: veloraTheme.lyricsScale
                rotation: veloraTheme.lyricsRotation
                transformOrigin: Item.TopLeft
                transform: [
                    Rotation {
                        origin.x: 0
                        origin.y: 0
                        axis.x: 1
                        axis.y: 0
                        axis.z: 0
                        angle: veloraTheme.lyricsTiltX
                    },
                    Rotation {
                        origin.x: 0
                        origin.y: 0
                        axis.x: 0
                        axis.y: 1
                        axis.z: 0
                        angle: veloraTheme.lyricsTiltY
                    }
                ]

                Repeater {
                    model: lyricsBlock.visibleWords

                    Text {
                        id: lyricsMainWordText

                        required property int index
                        required property var modelData

                        readonly property int sourceIndex: Number(modelData.sourceIndex)
                        readonly property bool activeWord: root.lyricsTimingMode === "plain-estimated" || !veloraTheme.lyricsActiveWordEnabled || sourceIndex === root.lyricsActiveIndex
                        readonly property string displayWord: veloraTheme.lyricsUppercase ? String(modelData.text).toUpperCase() : String(modelData.text)
                        readonly property color baseWordColor: root.lyricsWordColor(sourceIndex, -1)

                        text: displayWord
                        x: (lyricsBlock.centered ? -paintedWidth / 2 : (lyricsBlock.cascade ? index * Math.max(8, veloraTheme.lyricsFontSize * 0.18) : 0)) + lyricsPanel.wordFloatX(sourceIndex)
                        y: index * lyricsBlock.wordStep + lyricsPanel.wordFloatY(sourceIndex)
                        color: root.lyricsMaterialColor(baseWordColor, sourceIndex, activeWord)
                        opacity: root.lyricsRenderedWordOpacity(activeWord)
                        scale: root.lyricsWordScale(sourceIndex)
                        transformOrigin: Item.Center
                        font.family: veloraTheme.uiFont
                        font.pixelSize: Math.round(veloraTheme.lyricsFontSize)
                        font.weight: Font.Black
                        font.letterSpacing: 0
                        style: (veloraTheme.lyricsShadowEnabled || veloraTheme.lyricsDepthEnabled) ? Text.Outline : Text.Normal
                        styleColor: root.lyricsOutlineColor(activeWord)
                        renderType: Text.NativeRendering
                        layer.enabled: lyricsPanel.lyricsEffectEnabled(-1)
                        layer.smooth: true
                        layer.effect: DropShadow {
                            horizontalOffset: lyricsPanel.lyricsEffectHorizontalOffset(-1)
                            verticalOffset: lyricsPanel.lyricsEffectVerticalOffset(-1)
                            radius: lyricsPanel.lyricsGlowRadius(-1)
                            samples: lyricsPanel.lyricsGlowSamples(-1)
                            spread: 0
                            transparentBorder: true
                            color: lyricsPanel.lyricsGlowColor(lyricsMainWordText.color, lyricsMainWordText.activeWord, -1)
                        }
                    }
                }
            }

            Item {
                id: lyricsLeftBlock

                readonly property real wordStep: Math.round(veloraTheme.lyricsFontSize + veloraTheme.lyricsWordSpacing)
                readonly property var visibleWords: root.renderedLyricsSideWords("left")

                visible: veloraTheme.lyricsLayoutMode === "two" && !root.lyricsCinematicModeActive()
                x: Math.round(Math.max(0, Math.min(parent.width - 24, parent.width * veloraTheme.lyricsPositionX / 100)))
                y: Math.round(Math.max(0, Math.min(parent.height - 24, parent.height * veloraTheme.lyricsPositionY / 100)))
                width: Math.max(160, parent.width * 0.42)
                height: Math.max(80, visibleWords.length * wordStep + 20)
                opacity: veloraTheme.lyricsOpacity
                clip: false
                scale: veloraTheme.lyricsScale
                rotation: veloraTheme.lyricsRotation
                transformOrigin: Item.TopLeft
                transform: [
                    Rotation {
                        origin.x: 0
                        origin.y: 0
                        axis.x: 1
                        axis.y: 0
                        axis.z: 0
                        angle: veloraTheme.lyricsTiltX
                    },
                    Rotation {
                        origin.x: 0
                        origin.y: 0
                        axis.x: 0
                        axis.y: 1
                        axis.z: 0
                        angle: veloraTheme.lyricsTiltY
                    }
                ]

                Repeater {
                    model: lyricsLeftBlock.visibleWords

                    Text {
                        id: lyricsLeftWordText

                        required property int index
                        required property var modelData

                        readonly property int sourceIndex: Number(modelData.sourceIndex)
                        readonly property bool activeWord: root.lyricsTimingMode === "plain-estimated" || !veloraTheme.lyricsActiveWordEnabled || sourceIndex === root.lyricsActiveIndex
                        readonly property string displayWord: veloraTheme.lyricsUppercase ? String(modelData.text).toUpperCase() : String(modelData.text)
                        readonly property color baseWordColor: root.lyricsWordColor(sourceIndex, 0)

                        text: displayWord
                        x: lyricsPanel.wordFloatX(sourceIndex)
                        y: index * lyricsLeftBlock.wordStep + lyricsPanel.wordFloatY(sourceIndex)
                        color: root.lyricsMaterialColor(baseWordColor, sourceIndex, activeWord)
                        opacity: root.lyricsRenderedWordOpacity(activeWord)
                        scale: root.lyricsWordScale(sourceIndex)
                        transformOrigin: Item.Center
                        font.family: veloraTheme.uiFont
                        font.pixelSize: Math.round(veloraTheme.lyricsFontSize)
                        font.weight: Font.Black
                        font.letterSpacing: 0
                        style: (veloraTheme.lyricsShadowEnabled || veloraTheme.lyricsDepthEnabled) ? Text.Outline : Text.Normal
                        styleColor: root.lyricsOutlineColor(activeWord)
                        renderType: Text.NativeRendering
                        layer.enabled: lyricsPanel.lyricsEffectEnabled(0)
                        layer.smooth: true
                        layer.effect: DropShadow {
                            horizontalOffset: lyricsPanel.lyricsEffectHorizontalOffset(0)
                            verticalOffset: lyricsPanel.lyricsEffectVerticalOffset(0)
                            radius: lyricsPanel.lyricsGlowRadius(0)
                            samples: lyricsPanel.lyricsGlowSamples(0)
                            spread: 0
                            transparentBorder: true
                            color: lyricsPanel.lyricsGlowColor(lyricsLeftWordText.color, lyricsLeftWordText.activeWord, 0)
                        }
                    }
                }
            }

            Item {
                id: lyricsRightBlock

                readonly property real wordStep: Math.round(veloraTheme.lyricsFontSize + veloraTheme.lyricsWordSpacing)
                readonly property var visibleWords: root.renderedLyricsSideWords("right")

                visible: veloraTheme.lyricsLayoutMode === "two" && !root.lyricsCinematicModeActive()
                x: Math.round(Math.max(0, Math.min(parent.width - 24, parent.width * veloraTheme.lyricsSecondPositionX / 100)))
                y: Math.round(Math.max(0, Math.min(parent.height - 24, parent.height * veloraTheme.lyricsSecondPositionY / 100)))
                width: Math.max(160, parent.width - x - 24)
                height: Math.max(80, visibleWords.length * wordStep + 20)
                opacity: veloraTheme.lyricsOpacity
                clip: false
                scale: veloraTheme.lyricsScale
                rotation: veloraTheme.lyricsRotation
                transformOrigin: Item.TopLeft
                transform: [
                    Rotation {
                        origin.x: 0
                        origin.y: 0
                        axis.x: 1
                        axis.y: 0
                        axis.z: 0
                        angle: veloraTheme.lyricsTiltX
                    },
                    Rotation {
                        origin.x: 0
                        origin.y: 0
                        axis.x: 0
                        axis.y: 1
                        axis.z: 0
                        angle: veloraTheme.lyricsTiltY
                    }
                ]

                Repeater {
                    model: lyricsRightBlock.visibleWords

                    Text {
                        id: lyricsRightWordText

                        required property int index
                        required property var modelData

                        readonly property int sourceIndex: Number(modelData.sourceIndex)
                        readonly property bool activeWord: root.lyricsTimingMode === "plain-estimated" || !veloraTheme.lyricsActiveWordEnabled || sourceIndex === root.lyricsActiveIndex
                        readonly property string displayWord: veloraTheme.lyricsUppercase ? String(modelData.text).toUpperCase() : String(modelData.text)
                        readonly property color baseWordColor: root.lyricsWordColor(sourceIndex, 1)

                        text: displayWord
                        x: lyricsPanel.wordFloatX(sourceIndex)
                        y: index * lyricsRightBlock.wordStep + lyricsPanel.wordFloatY(sourceIndex)
                        color: root.lyricsMaterialColor(baseWordColor, sourceIndex, activeWord)
                        opacity: root.lyricsRenderedWordOpacity(activeWord)
                        scale: root.lyricsWordScale(sourceIndex)
                        transformOrigin: Item.Center
                        font.family: veloraTheme.uiFont
                        font.pixelSize: Math.round(veloraTheme.lyricsFontSize)
                        font.weight: Font.Black
                        font.letterSpacing: 0
                        style: (veloraTheme.lyricsShadowEnabled || veloraTheme.lyricsDepthEnabled) ? Text.Outline : Text.Normal
                        styleColor: root.lyricsOutlineColor(activeWord)
                        renderType: Text.NativeRendering
                        layer.enabled: lyricsPanel.lyricsEffectEnabled(1)
                        layer.smooth: true
                        layer.effect: DropShadow {
                            horizontalOffset: lyricsPanel.lyricsEffectHorizontalOffset(1)
                            verticalOffset: lyricsPanel.lyricsEffectVerticalOffset(1)
                            radius: lyricsPanel.lyricsGlowRadius(1)
                            samples: lyricsPanel.lyricsGlowSamples(1)
                            spread: 0
                            transparentBorder: true
                            color: lyricsPanel.lyricsGlowColor(lyricsRightWordText.color, lyricsRightWordText.activeWord, 1)
                        }
                    }
                }
            }

            Repeater {
                model: veloraTheme.lyricsLayoutMode === "four" ? [0, 1, 2, 3] : []

                Item {
                    id: lyricsFourBlock

                    required property int index
                    required property int modelData

                    readonly property int blockIndex: Number(modelData)
                    readonly property real wordStep: Math.round(veloraTheme.lyricsFontSize + veloraTheme.lyricsWordSpacing)
                    readonly property var visibleWords: root.renderedLyricsBlockWords(blockIndex, 4)

                    x: root.lyricsBlockPositionX(parent.width, blockIndex)
                    y: root.lyricsBlockPositionY(parent.height, blockIndex)
                    width: root.lyricsBlockWidth(parent.width, blockIndex)
                    height: Math.max(80, visibleWords.length * wordStep + 20)
                    opacity: veloraTheme.lyricsOpacity
                    clip: false
                    scale: veloraTheme.lyricsScale
                    rotation: veloraTheme.lyricsRotation
                    transformOrigin: Item.TopLeft
                    transform: [
                        Rotation {
                            origin.x: 0
                            origin.y: 0
                            axis.x: 1
                            axis.y: 0
                            axis.z: 0
                            angle: veloraTheme.lyricsTiltX
                        },
                        Rotation {
                            origin.x: 0
                            origin.y: 0
                            axis.x: 0
                            axis.y: 1
                            axis.z: 0
                            angle: veloraTheme.lyricsTiltY
                        }
                    ]

                    Repeater {
                        model: lyricsFourBlock.visibleWords

                        Text {
                            id: lyricsFourWordText

                            required property int index
                            required property var modelData

                            readonly property int sourceIndex: Number(modelData.sourceIndex)
                            readonly property bool activeWord: root.lyricsTimingMode === "plain-estimated" || !veloraTheme.lyricsActiveWordEnabled || sourceIndex === root.lyricsActiveIndex
                            readonly property string displayWord: veloraTheme.lyricsUppercase ? String(modelData.text).toUpperCase() : String(modelData.text)
                            readonly property color baseWordColor: root.lyricsWordColor(sourceIndex, lyricsFourBlock.blockIndex)

                            text: displayWord
                            x: lyricsPanel.wordFloatX(sourceIndex)
                            y: index * lyricsFourBlock.wordStep + lyricsPanel.wordFloatY(sourceIndex)
                            color: root.lyricsMaterialColor(baseWordColor, sourceIndex, activeWord)
                            opacity: root.lyricsRenderedWordOpacity(activeWord)
                            scale: root.lyricsWordScale(sourceIndex)
                            transformOrigin: Item.Center
                            font.family: veloraTheme.uiFont
                            font.pixelSize: Math.round(veloraTheme.lyricsFontSize)
                            font.weight: Font.Black
                            font.letterSpacing: 0
                            style: (veloraTheme.lyricsShadowEnabled || veloraTheme.lyricsDepthEnabled) ? Text.Outline : Text.Normal
                            styleColor: root.lyricsOutlineColor(activeWord)
                            renderType: Text.NativeRendering
                            layer.enabled: lyricsPanel.lyricsEffectEnabled(lyricsFourBlock.blockIndex)
                            layer.smooth: true
                            layer.effect: DropShadow {
                                horizontalOffset: lyricsPanel.lyricsEffectHorizontalOffset(lyricsFourBlock.blockIndex)
                                verticalOffset: lyricsPanel.lyricsEffectVerticalOffset(lyricsFourBlock.blockIndex)
                                radius: lyricsPanel.lyricsGlowRadius(lyricsFourBlock.blockIndex)
                                samples: lyricsPanel.lyricsGlowSamples(lyricsFourBlock.blockIndex)
                                spread: 0
                                transparentBorder: true
                                color: lyricsPanel.lyricsGlowColor(lyricsFourWordText.color, lyricsFourWordText.activeWord, lyricsFourBlock.blockIndex)
                            }
                        }
                    }
                }
            }
            }

            Canvas {
                id: lyricsCutMaskCanvas

                anchors.fill: parent
                visible: veloraTheme.lyricsMaskEnabled && veloraTheme.lyricsMaskHasStrokes

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.clearRect(0, 0, width, height)
                    ctx.fillStyle = "rgba(255,255,255,1)"
                    ctx.fillRect(0, 0, width, height)
                    const strokes = veloraTheme.lyricsMaskStrokes || []
                    ctx.globalCompositeOperation = "destination-out"
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    const feather = Math.max(0, Number(veloraTheme.lyricsMaskFeather) || 0)
                    function drawMaskStroke(points, lineWidth, alpha) {
                        ctx.globalAlpha = Math.max(0, Math.min(1, alpha))
                        ctx.lineWidth = Math.max(1, lineWidth)
                        ctx.beginPath()
                        ctx.moveTo(points[0].x * width, points[0].y * height)
                        for (let p = 1; p < points.length; p += 1)
                            ctx.lineTo(points[p].x * width, points[p].y * height)
                        ctx.stroke()
                    }
                    for (let i = 0; i < strokes.length; i += 1) {
                        const stroke = strokes[i] || {}
                        const points = stroke.points || []
                        if (points.length < 2)
                            continue
                        const brush = Math.max(1, Number(stroke.brush) || veloraTheme.lyricsMaskBrushSize)
                        if (feather > 0) {
                            drawMaskStroke(points, brush + feather * 2.0, 0.16)
                            drawMaskStroke(points, brush + feather, 0.34)
                        }
                        drawMaskStroke(points, brush, 1)
                    }
                    ctx.globalAlpha = 1
                    ctx.globalCompositeOperation = "source-over"
                }

                Connections {
                    target: veloraTheme
                    function onLyricsMaskRevisionChanged() { lyricsCutMaskCanvas.requestPaint() }
                    function onLyricsMaskFeatherChanged() { lyricsCutMaskCanvas.requestPaint() }
                }

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onVisibleChanged: if (visible) requestPaint()
            }

            ShaderEffectSource {
                id: lyricsCutMaskSource

                anchors.fill: parent
                visible: false
                sourceItem: lyricsCutMaskCanvas
                hideSource: true
                live: true
                recursive: true
            }
        }
    }

    Variants {
        model: root.lyricsMaskEditorOpen ? Quickshell.screens : []

        PanelWindow {
            id: lyricsMaskEditorPanel

            required property var modelData
            readonly property int panelWidth: modelData.width > 0 ? modelData.width : 1920
            readonly property int panelHeight: modelData.height > 0 ? modelData.height : 1200

            screen: modelData
            color: "transparent"
            implicitWidth: panelWidth
            implicitHeight: panelHeight
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            focusable: true

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "velora-shell-lyrics-mask-editor"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            mask: Region {
                item: lyricsMaskEditorInputMask
            }

            Item {
                id: lyricsMaskEditorInputMask
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: root.closeLyricsMaskEditor()
                Component.onCompleted: forceActiveFocus()
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.12)
            }

            Canvas {
                id: lyricsMaskEditorCanvas

                anchors.fill: parent
                opacity: 0.82

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.clearRect(0, 0, width, height)
                    const strokes = veloraTheme.lyricsMaskStrokes || []
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    for (let i = 0; i < strokes.length; i += 1) {
                        const stroke = strokes[i] || {}
                        const points = stroke.points || []
                        if (points.length < 2)
                            continue
                        ctx.strokeStyle = "rgba(255,80,160,0.56)"
                        ctx.lineWidth = Math.max(1, Number(stroke.brush) || veloraTheme.lyricsMaskBrushSize)
                        ctx.beginPath()
                        ctx.moveTo(points[0].x * width, points[0].y * height)
                        for (let p = 1; p < points.length; p += 1)
                            ctx.lineTo(points[p].x * width, points[p].y * height)
                        ctx.stroke()
                    }

                    const live = root.lyricsMaskEditorPoints || []
                    if (live.length >= 2) {
                        ctx.strokeStyle = "rgba(255,255,255,0.78)"
                        ctx.lineWidth = Math.max(1, veloraTheme.lyricsMaskBrushSize)
                        ctx.beginPath()
                        ctx.moveTo(live[0].x * width, live[0].y * height)
                        for (let j = 1; j < live.length; j += 1)
                            ctx.lineTo(live[j].x * width, live[j].y * height)
                        ctx.stroke()
                    }
                }

                Connections {
                    target: veloraTheme
                    function onLyricsMaskRevisionChanged() { lyricsMaskEditorCanvas.requestPaint() }
                }

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.CrossCursor
                onPressed: function(mouse) {
                    root.lyricsMaskEditorPoints = []
                    root.appendLyricsMaskPoint(lyricsMaskEditorPanel, mouse.x, mouse.y)
                    lyricsMaskEditorCanvas.requestPaint()
                }
                onPositionChanged: function(mouse) {
                    if (!pressed)
                        return
                    root.appendLyricsMaskPoint(lyricsMaskEditorPanel, mouse.x, mouse.y)
                    lyricsMaskEditorCanvas.requestPaint()
                }
                onReleased: {
                    root.commitLyricsMaskStroke()
                    lyricsMaskEditorCanvas.requestPaint()
                }
            }

            Row {
                z: 4
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 18
                anchors.rightMargin: 18
                spacing: 8

                Rectangle {
                    width: 86
                    height: 36
                    radius: 10
                    color: veloraTheme.withAlpha(veloraTheme.surfacePopup, 0.72)
                    border.width: 1
                    border.color: veloraTheme.withAlpha(veloraTheme.borderSoft, 0.38)

                    Text {
                        anchors.centerIn: parent
                        text: "Limpar"
                        color: veloraTheme.textPrimary
                        font.family: veloraTheme.uiFont
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            veloraTheme.clearLyricsMask(true)
                            lyricsMaskEditorCanvas.requestPaint()
                        }
                    }
                }

                Rectangle {
                    width: 86
                    height: 36
                    radius: 10
                    color: veloraTheme.withAlpha(veloraTheme.accentPrimary, 0.76)

                    Text {
                        anchors.centerIn: parent
                        text: "Concluir"
                        color: veloraTheme.buttonPrimaryText
                        font.family: veloraTheme.uiFont
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.closeLyricsMaskEditor()
                    }
                }
            }
        }
    }



    // The selector shares the lock's native clear lens, below the overlay bars.
    Variants {
        model: root.topWallpaperUsesCenterSelector && root.topWallpaperMounted && !root.shellSuppressedByFullscreen ? Quickshell.screens : []

        PanelWindow {
            id: wallpaperSelectorPanel

            required property var modelData
            readonly property int panelWidth: modelData.width > 0 ? modelData.width : 1920
            readonly property int panelHeight: modelData.height > 0 ? modelData.height : 1200

            screen: modelData
            color: "transparent"
            implicitWidth: panelWidth
            implicitHeight: panelHeight
            exclusionMode: ExclusionMode.Ignore
            focusable: root.topWallpaperKeyboardFocus

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "velora-wallpaper-selector"
            BackgroundEffect.blurRegion: Region {}
            WlrLayershell.keyboardFocus: root.topWallpaperKeyboardFocus ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            property bool glassDirty: true
            function syncGlass() {
                const rect = wallpaperLayerCarousel.glassRect
                const fields = [modelData.name, wallpaperLayerCarousel.glassEnabled ? 1 : 0,
                    (wallpaperLayerCarousel.x + rect.x) / width,
                    (wallpaperLayerCarousel.y + rect.y) / height,
                    rect.width / width, rect.height / height,
                    wallpaperLayerCarousel.glassRadius / width,
                    root.topWallpaperFrameReveal]
                Platform.NativeBlur.dispatch("velora-blur:selector-shape " + fields.join(" "))
            }
            FrameAnimation {
                running: wallpaperSelectorPanel.glassDirty
                onTriggered: {
                    wallpaperSelectorPanel.glassDirty = false
                    wallpaperSelectorPanel.syncGlass()
                }
            }
            Connections {
                target: root.composition
                function onOpticsGenerationChanged() { wallpaperSelectorPanel.glassDirty = true }
            }
            Component.onDestruction: Platform.NativeBlur.dispatch("velora-blur:selector-shape "
                + modelData.name + " 0 0 0 0 0 0 0")

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            mask: Region {
                item: wallpaperSelectorInputMask
                radius: root.desktopFrameRadius
            }

            VeloraWallpaperCarousel {
                id: wallpaperLayerCarousel
                Component.onCompleted: root.wallpaperSelectorViews[wallpaperSelectorPanel.modelData.name] = wallpaperLayerCarousel
                Component.onDestruction: delete root.wallpaperSelectorViews[wallpaperSelectorPanel.modelData.name]

                readonly property int frameClearance: root.frameVisualsMounted ? 2 : 0

                x: root.mainAreaX(parent.width) + frameClearance
                y: (root.composition ? root.composition.barHeight : 40)
                    + frameClearance
                width: Math.max(0, root.mainAreaWidth(parent.width) - frameClearance * 2)
                height: Math.max(0, parent.height - y - frameClearance)
                clip: true
                visible: root.topWallpaperPopupOpen || root.topWallpaperFrameReveal > 0.01
                theme: veloraTheme
                motion: root.composition.motionTokens
                reducedMotion: root.composition ? root.composition.reducedMotion : false
                glassEnabled: root.composition.wallpaperSelectorGlassEnabled
                onGlassEnabledChanged: wallpaperSelectorPanel.glassDirty = true
                open: root.topWallpaperPopupOpen
                revealProgress: root.topWallpaperFrameReveal
                onGlassRectChanged: wallpaperSelectorPanel.glassDirty = true
                onRevealProgressChanged: wallpaperSelectorPanel.glassDirty = true
                onXChanged: wallpaperSelectorPanel.glassDirty = true
                onYChanged: wallpaperSelectorPanel.glassDirty = true
                entries: root.topWallpaperEntries
                selectedIndex: root.topWallpaperOffset
                slideDirection: root.topWallpaperSlideDirection
                slideProgress: root.topWallpaperSlideProgress
                activeKey: root.topWallpaperActiveKey
                favorites: root.topWallpaperFavorites
                mediaFilter: root.topWallpaperMediaFilter
                colorFilter: root.topWallpaperColorFilter
                searchQuery: root.topWallpaperSearchQuery
                favoritesOnly: root.topWallpaperFavoritesOnly
                gridMode: root.topWallpaperGridMode
                applying: topWallpaperApply.running
                errorMessage: root.topWallpaperErrorMessage
                keyboardFocus: root.topWallpaperKeyboardFocus

                onNavigateRequested: function(delta) { root.moveTopWallpaper(delta) }
                onSelectRelativeRequested: function(delta) { root.selectTopWallpaperRelative(delta) }
                onSelectAbsoluteRequested: function(index) { root.selectTopWallpaperAbsolute(index) }
                onApplyRequested: function(entry) { root.applyTopWallpaperSelection(entry) }
                onRandomRequested: root.chooseRandomTopWallpaper()
                onFavoriteRequested: function(entry) { root.toggleTopWallpaperFavorite(entry) }
                onHideRequested: function(entry) { root.hideTopWallpaper(entry) }
                onRefreshRequested: root.refreshTopWallpaperLibrary()
                onCloseRequested: root.toggleTopWallpaperPopup(false, false)
                onMediaFilterRequested: function(filter) { root.setTopWallpaperMediaFilter(filter) }
                onColorFilterRequested: function(filter) { root.setTopWallpaperColorFilter(filter) }
                onSearchRequested: function(query) { root.setTopWallpaperSearch(query) }
                onFavoritesOnlyRequested: function(enabled) { root.setTopWallpaperFavoritesOnly(enabled) }
                onGridModeRequested: function(enabled) { root.topWallpaperGridMode = enabled }
            }

            Item {
                id: wallpaperSelectorInputMask
                x: wallpaperLayerCarousel.x
                y: wallpaperLayerCarousel.y
                width: root.topWallpaperPopupOpen ? wallpaperLayerCarousel.width : 0
                height: root.topWallpaperPopupOpen ? wallpaperLayerCarousel.height : 0
            }
        }
    }



    Variants {
        model: root.systemPopupKeyboardFocus
            && root.quickPopupType === "system"
            ? Quickshell.screens
            : []

        PanelWindow {
            id: systemKeyboardWindow

            required property var modelData
            readonly property bool focusedScreen: !Hyprland.focusedMonitor
                || modelData.name === Hyprland.focusedMonitor.name

            screen: modelData
            color: "transparent"
            implicitWidth: 1
            implicitHeight: 1
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            focusable: focusedScreen

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "velora-system-keyboard"
            WlrLayershell.keyboardFocus: focusedScreen
                ? WlrKeyboardFocus.Exclusive
                : WlrKeyboardFocus.None

            anchors {
                top: true
                left: true
            }

            mask: Region {
                item: systemKeyboardInputMask
            }

            Item {
                id: systemKeyboardInputMask

                width: 0
                height: 0
            }

            Item {
                id: systemKeyboardReceiver

                anchors.fill: parent
                focus: systemKeyboardWindow.focusedScreen
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Left) {
                        root.moveTopBarSystemPage(-1)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Right) {
                        root.moveTopBarSystemPage(1)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Escape) {
                        root.closeQuickPopup()
                        event.accepted = true
                    }
                }

                Component.onCompleted: {
                    if (systemKeyboardWindow.focusedScreen)
                        forceActiveFocus(Qt.ShortcutFocusReason)
                }
            }
        }
    }

    Variants {
        model: root.topBarCenterVisualizerMounted
            ? Quickshell.screens
            : []

        PanelWindow {
            id: bottomVisualizerWindow

            required property var modelData
            readonly property int visualizerHeight: Math.max(
                48,
                Math.min(
                    76,
                    Math.round(
                        46 + veloraTheme.visualizerStrength * 24
                    )
                )
            )

            screen: modelData
            color: "transparent"
            implicitWidth: modelData.width > 0 ? modelData.width : 1920
            implicitHeight: visualizerHeight
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            focusable: false

            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "velora-bottom-glava"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                bottom: true
                left: true
                right: true
            }

            mask: Region {
                item: bottomVisualizerInputMask
            }

            Item {
                id: bottomVisualizerInputMask

                width: 0
                height: 0
            }

            VeloraGlavaTopSpectrum {
                anchors.fill: parent
                theme: veloraTheme
                values: root.topBarCavaValues
                active: root.topBarCenterVisualizerMounted
                growUpward: true
                referenceHeight: height - 2
                strength: veloraTheme.visualizerStrength
            }
        }
    }

    Variants {
        model: []

        PanelWindow {
            id: weatherTopWindow

            required property var modelData
            readonly property int panelWidth: modelData.width > 0 ? modelData.width : 1920
            readonly property int panelHeight: modelData.height > 0 ? modelData.height : 1200
            readonly property int areaX: root.mainAreaX(panelWidth)
            readonly property int areaWidth: root.mainAreaWidth(panelWidth)
            readonly property bool expanded: false
            readonly property int targetWidth: Math.round(Math.min(820, Math.max(760, panelWidth * 0.417)))
            readonly property int compactHeight: 390
            readonly property int expandedHeight: Math.round(Math.min(620, Math.max(480, panelHeight * 0.56)))
            readonly property int targetHeight: expanded ? expandedHeight : compactHeight
            readonly property int targetX: Math.round((panelWidth - targetWidth) / 2)
            readonly property int targetY: root.weatherTopOpen ? 0 : -targetHeight - 18

            screen: modelData
            color: "transparent"
            implicitWidth: panelWidth
            implicitHeight: panelHeight
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            focusable: true
            visible: true

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "velora-shell-weather-top"
            WlrLayershell.keyboardFocus: root.weatherTopKeyboardFocus ? WlrKeyboardFocus.Exclusive : (root.weatherTopOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None)

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            mask: Region {
                Region {
                    item: weatherTopTriggerMask
                    radius: 0
                }

                Region {
                    item: weatherTopInputMask
                    radius: 24
                }

            }

            Item {
                id: weatherTopTriggerMask

                x: 0
                y: 0
                width: weatherTopWindow.panelWidth
                height: root.weatherTopOpen ? 0 : 12
                z: 1

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    onEntered: {
                        root.weatherTopTriggerHovering = true
                        root.openWeatherTopFromMouse()
                    }
                    onExited: {
                        root.weatherTopTriggerHovering = false
                        root.scheduleWeatherTopHoverClose()
                    }
                }
            }

            Item {
                id: weatherTopOutsideMask

                x: 0
                y: 0
                width: 0
                height: 0
                z: 1

                MouseArea {
                    anchors.fill: parent
                    enabled: false
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: root.closeWeatherTop()
                }
            }

            Item {
                id: weatherTopInputMask

                x: weatherTopFrame.x
                y: weatherTopFrame.y
                width: root.weatherTopWindowOpen ? weatherTopFrame.width : 0
                height: root.weatherTopWindowOpen ? weatherTopFrame.height : 0
                z: 2
            }

            Loader {
                id: weatherTopPanel

                x: weatherTopFrame.x
                y: weatherTopFrame.y
                width: weatherTopFrame.width
                height: weatherTopFrame.height
                active: root.weatherTopWindowOpen
                visible: active
                z: 4

                sourceComponent: Component {
                    VeloraWeatherTopPanel {
                        theme: veloraTheme
                        barSurface: root.composition
                            ? root.composition.unifiedBarSurface : root.desktopFrameMatteColor()
                        weather: root.composition ? root.composition.forecastService : null
                        open: root.weatherTopOpen
                        onActivated: root.engageWeatherTop()
                        onCloseRequested: root.closeWeatherTop()
                        onPointerInsideChanged: function(inside) {
                            root.setWeatherTopPanelHovering(inside)
                        }
                    }
                }
            }

            Item {
                id: weatherTopFrame

                width: weatherTopWindow.targetWidth
                height: weatherTopWindow.targetHeight
                x: weatherTopWindow.targetX
                y: weatherTopWindow.targetY
                opacity: 1

                Behavior on y {
                    enabled: veloraTheme.motionEnabled
                    NumberAnimation {
                        duration: root.weatherTopOpen ? veloraTheme.motionPanelIn : root.quickPopupLineCloseDuration
                        easing.type: root.weatherTopOpen ? Easing.BezierSpline : Easing.InOutCubic
                        easing.bezierCurve: root.weatherTopOpen ? veloraTheme.motionCurveEmphasizedAccel : veloraTheme.motionCurveStandard
                    }
                }

                Behavior on height {
                    enabled: veloraTheme.motionEnabled
                    NumberAnimation {
                        duration: veloraTheme.motionPanelGeometry
                        easing.type: veloraTheme.motionEaseEnter
                    }
                }

                Behavior on opacity {
                    enabled: veloraTheme.motionEnabled
                    NumberAnimation {
                        duration: root.weatherTopOpen ? Math.max(180, veloraTheme.motionPanelIn * 0.62) : Math.max(320, root.quickPopupLineCloseDuration * 0.52)
                        easing.type: root.weatherTopOpen ? Easing.BezierSpline : Easing.InOutCubic
                        easing.bezierCurve: root.weatherTopOpen ? veloraTheme.motionCurveEmphasizedAccel : veloraTheme.motionCurveStandard
                    }
                }
            }
        }
    }

    Variants {
        model: []

        PanelWindow {
            id: topWallpaperPopupPanel

            required property var modelData
            readonly property int popupWidth: root.topWallpaperPopupWidth(modelData.width > 0 ? modelData.width : 1920)
            readonly property int popupHeight: root.topWallpaperPopupHeight(modelData.height > 0 ? modelData.height : 1200)

            screen: modelData
            color: "transparent"
            implicitWidth: modelData.width > 0 ? modelData.width : popupWidth
            implicitHeight: root.topWallpaperPopupMargin + popupHeight + 18
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            focusable: root.topWallpaperKeyboardFocus

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "velora-shell-wallpaper-top-popup"
            WlrLayershell.keyboardFocus: root.topWallpaperKeyboardFocus ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            anchors {
                top: true
                left: true
                right: true
            }

            mask: Region {
                Region {
                    item: topWallpaperPopupSurface
                    radius: root.topWallpaperPopupRadius
                }
            }

            Item {
                id: topWallpaperPopupStage

                x: Math.round((parent.width - width + (root.barOnRight ? root.barReserveWidth : -root.barReserveWidth)) / 2)
                y: root.topWallpaperPopupMargin
                width: topWallpaperPopupPanel.popupWidth
                height: topWallpaperPopupPanel.popupHeight
                focus: root.topWallpaperKeyboardFocus

                Keys.onEscapePressed: {
                    root.toggleTopWallpaperPopup(false, false)
                }

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Left || event.key === Qt.Key_A) {
                        root.moveTopWallpaper(-1)
                        event.accepted = true
                        return
                    }

                    if (event.key === Qt.Key_Right || event.key === Qt.Key_D) {
                        root.moveTopWallpaper(1)
                        event.accepted = true
                        return
                    }

                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.applyTopWallpaperSelection()
                        event.accepted = true
                        return
                    }
                }

                Component.onCompleted: {
                    if (root.topWallpaperKeyboardFocus)
                        forceActiveFocus()
                }

                Connections {
                    target: root

                    function onTopWallpaperKeyboardFocusChanged() {
                        if (root.topWallpaperKeyboardFocus)
                            topWallpaperPopupStage.forceActiveFocus()
                    }
                }

                DropShadow {
                    anchors.fill: topWallpaperPopupSurface
                    horizontalOffset: 0
                    verticalOffset: 12
                    radius: 34
                    samples: 57
                    color: veloraTheme.alpha(veloraTheme.shadowColor, veloraTheme.themeMode === "dark" ? 0.16 : 0.10)
                    source: topWallpaperPopupSurface
                }

                Rectangle {
                    id: topWallpaperPopupSurface

                    anchors.fill: parent
                    radius: root.topWallpaperPopupRadius
                    color: "transparent"
                    border.width: 0
                    border.color: root.desktopFrameBorderColor()
                    antialiasing: true
                }

                Item {
                    id: topWallpaperImageSlices

                    readonly property int edgeFadeHeight: Math.round(Math.min(46, Math.max(26, height * 0.23)))

                    anchors.fill: topWallpaperPopupSurface
                    visible: root.topWallpaperPopupOpen || root.topWallpaperFrameReveal > 0.01
                    clip: true
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: topWallpaperClipMask
                    }

                    Canvas {
                        id: topWallpaperClipMask

                        anchors.fill: parent
                        visible: false

                        onPaint: {
                            const ctx = getContext("2d")
                            const fadeRatio = Math.max(0.12, Math.min(0.27, topWallpaperImageSlices.edgeFadeHeight / Math.max(1, height)))
                            const r = Math.min(root.topWallpaperPopupRadius, width / 2, height / 2)
                            const gradient = ctx.createLinearGradient(0, 0, 0, height)

                            ctx.clearRect(0, 0, width, height)
                            gradient.addColorStop(0.00, "rgba(255,255,255,0.00)")
                            gradient.addColorStop(fadeRatio * 0.34, "rgba(255,255,255,0.28)")
                            gradient.addColorStop(fadeRatio, "rgba(255,255,255,1.00)")
                            gradient.addColorStop(1.00, "rgba(255,255,255,1.00)")

                            ctx.beginPath()
                            ctx.moveTo(r, 0)
                            ctx.lineTo(width - r, 0)
                            ctx.quadraticCurveTo(width, 0, width, r)
                            ctx.lineTo(width, height - r)
                            ctx.quadraticCurveTo(width, height, width - r, height)
                            ctx.lineTo(r, height)
                            ctx.quadraticCurveTo(0, height, 0, height - r)
                            ctx.lineTo(0, r)
                            ctx.quadraticCurveTo(0, 0, r, 0)
                            ctx.closePath()
                            ctx.fillStyle = gradient
                            ctx.fill()
                        }

                        Component.onCompleted: requestPaint()
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()
                    }

                    Repeater {
                        model: root.topWallpaperSliceCount + 2

                        delegate: Item {
                            id: wallpaperSlice

                            readonly property int logicalIndex: index - 1 - root.topWallpaperSelectedSlot
                            readonly property real slotWidth: topWallpaperImageSlices.width / Math.max(1, root.topWallpaperSliceCount)
                            readonly property real sliceSkew: Math.max(22, Math.min(36, topWallpaperImageSlices.width * 0.038))
                            readonly property real slideOffset: -root.topWallpaperSlideDirection * root.topWallpaperSlideEase() * slotWidth
                            readonly property var entry: root.topWallpaperEntry(logicalIndex)

                            anchors.fill: parent
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: wallpaperSliceMask
                            }

                            Canvas {
                                id: wallpaperSliceMask

                                anchors.fill: parent
                                visible: false

                                onPaint: {
                                    const ctx = getContext("2d")
                                    const left = wallpaperSlice.logicalIndex * wallpaperSlice.slotWidth + wallpaperSlice.slideOffset
                                    const right = left + wallpaperSlice.slotWidth
                                    const skew = wallpaperSlice.sliceSkew

                                    ctx.clearRect(0, 0, width, height)
                                    ctx.beginPath()
                                    ctx.moveTo(left + skew, -8)
                                    ctx.lineTo(right + skew, -8)
                                    ctx.lineTo(right - skew, height + 8)
                                    ctx.lineTo(left - skew, height + 8)
                                    ctx.closePath()
                                    ctx.fillStyle = "white"
                                    ctx.fill()
                                }

                                Component.onCompleted: requestPaint()
                                onWidthChanged: requestPaint()
                                onHeightChanged: requestPaint()

                                Connections {
                                    target: root

                                    function onTopWallpaperSlideProgressChanged() { wallpaperSliceMask.requestPaint() }
                                    function onTopWallpaperSlideDirectionChanged() { wallpaperSliceMask.requestPaint() }
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: root.desktopFrameMatteColor()
                            }

                            Image {
                                anchors.fill: parent
                                source: wallpaperSlice.entry && wallpaperSlice.entry.preview ? wallpaperSlice.entry.preview : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                smooth: true
                                mipmap: true
                                opacity: 0.90
                                sourceSize.width: 560
                                sourceSize.height: 360
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: root.desktopFrameMatteColor()
                                opacity: veloraTheme.themeMode === "dark" ? 0.22 : 0.14
                            }
                        }
                    }

                    Repeater {
                        model: 2

                        delegate: Item {
                            id: selectedWallpaperLayer

                            readonly property bool incoming: index === 1
                            readonly property real progress: root.topWallpaperSlideDirection === 0 ? 0 : root.topWallpaperSlideEase()
                            readonly property real slotWidth: topWallpaperImageSlices.width / Math.max(1, root.topWallpaperSliceCount)
                            readonly property real activeWidth: Math.min(topWallpaperImageSlices.width * 0.44, slotWidth * 4.35)
                            readonly property real inactiveWidth: slotWidth * 1.04
                            readonly property real currentWidth: incoming
                                ? inactiveWidth + (activeWidth - inactiveWidth) * progress
                                : activeWidth - (activeWidth - inactiveWidth) * progress
                            readonly property real travel: slotWidth * 1.18
                            readonly property real centerX: topWallpaperImageSlices.width / 2
                                + (incoming ? root.topWallpaperSlideDirection * travel * (1 - progress) : -root.topWallpaperSlideDirection * travel * progress)
                            readonly property real sliceSkew: Math.max(26, Math.min(42, topWallpaperImageSlices.width * 0.052))
                            readonly property var entry: root.topWallpaperEntry(incoming ? root.topWallpaperSlideDirection : 0)

                            anchors.fill: parent
                            visible: !incoming || root.topWallpaperSlideDirection !== 0
                            opacity: incoming ? progress : 1 - progress * 0.34
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: selectedWallpaperMask
                            }

                            Canvas {
                                id: selectedWallpaperMask

                                anchors.fill: parent
                                visible: false

                                onPaint: {
                                    const ctx = getContext("2d")
                                    const half = selectedWallpaperLayer.currentWidth / 2
                                    const left = selectedWallpaperLayer.centerX - half
                                    const right = selectedWallpaperLayer.centerX + half
                                    const skew = selectedWallpaperLayer.sliceSkew

                                    ctx.clearRect(0, 0, width, height)
                                    ctx.beginPath()
                                    ctx.moveTo(left + skew, -8)
                                    ctx.lineTo(right + skew, -8)
                                    ctx.lineTo(right - skew, height + 8)
                                    ctx.lineTo(left - skew, height + 8)
                                    ctx.closePath()
                                    ctx.fillStyle = "white"
                                    ctx.fill()
                                }

                                Component.onCompleted: requestPaint()
                                onWidthChanged: requestPaint()
                                onHeightChanged: requestPaint()

                                Connections {
                                    target: root

                                    function onTopWallpaperSlideProgressChanged() { selectedWallpaperMask.requestPaint() }
                                    function onTopWallpaperSlideDirectionChanged() { selectedWallpaperMask.requestPaint() }
                                }
                            }

                            Image {
                                anchors.fill: parent
                                source: selectedWallpaperLayer.entry && selectedWallpaperLayer.entry.preview ? selectedWallpaperLayer.entry.preview : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                smooth: true
                                mipmap: true
                                opacity: 0.98
                                sourceSize.width: 720
                                sourceSize.height: 420
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: root.desktopFrameMatteColor()
                                opacity: veloraTheme.themeMode === "dark" ? 0.10 : 0.06
                            }
                        }
                    }

                    Rectangle {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                        }
                        height: topWallpaperImageSlices.edgeFadeHeight
                        color: "transparent"
                        gradient: Gradient {
                            GradientStop { position: 0.00; color: root.desktopFrameMatteColor() }
                            GradientStop { position: 0.32; color: veloraTheme.alpha(veloraTheme.surfaceSidebar, root.desktopFrameMatteOpacity * 0.42) }
                            GradientStop { position: 1.00; color: veloraTheme.alpha(veloraTheme.surfaceSidebar, 0.0) }
                        }
                    }

                }

                Rectangle {
                    anchors.fill: topWallpaperPopupSurface
                    anchors.margins: 1
                    radius: Math.max(0, topWallpaperPopupSurface.radius - 1)
                    color: "transparent"
                    border.width: 1
                    border.color: root.sidebarPanelInnerLineColor()
                    antialiasing: true
                }

                Canvas {
                    id: topWallpaperSliceCanvas

                    anchors.fill: topWallpaperPopupSurface
                    visible: root.topWallpaperPopupOpen || root.topWallpaperFrameReveal > 0.01
                    antialiasing: true

                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        const sliceCount = root.topWallpaperSliceCount
                        const slotWidth = width / Math.max(1, sliceCount)
                        const lean = Math.max(22, Math.min(36, width * 0.038))
                        const slideOffset = -root.topWallpaperSlideDirection * root.topWallpaperSlideEase() * slotWidth
                        const selectedProgress = root.topWallpaperSlideDirection === 0 ? 0 : root.topWallpaperSlideEase()
                        const selectedCenter = width / 2 - root.topWallpaperSlideDirection * slotWidth * 1.18 * selectedProgress
                        const selectedWidth = Math.min(width * 0.44, slotWidth * 4.35) - (Math.min(width * 0.44, slotWidth * 4.35) - slotWidth * 1.04) * selectedProgress
                        const selectedLeft = selectedCenter - selectedWidth / 2
                        const selectedRight = selectedCenter + selectedWidth / 2
                        const incomingCenter = width / 2 + root.topWallpaperSlideDirection * slotWidth * 1.18 * (1 - selectedProgress)
                        const incomingWidth = root.topWallpaperSlideDirection === 0 ? 0 : slotWidth * 1.04 + (Math.min(width * 0.44, slotWidth * 4.35) - slotWidth * 1.04) * selectedProgress
                        const incomingLeft = incomingCenter - incomingWidth / 2
                        const incomingRight = incomingCenter + incomingWidth / 2
                        const lineColor = root.desktopFrameBorderColor()
                        const highlightColor = root.sidebarPanelInnerLineColor()

                        ctx.lineCap = "round"
                        ctx.lineJoin = "round"

                        for (let i = 0; i <= sliceCount; ++i) {
                            const baseX = slotWidth * i + slideOffset
                            if ((baseX > selectedLeft + lean * 0.25 && baseX < selectedRight - lean * 0.25)
                                    || (root.topWallpaperSlideDirection !== 0 && baseX > incomingLeft + lean * 0.25 && baseX < incomingRight - lean * 0.25))
                                continue

                            ctx.beginPath()
                            ctx.moveTo(baseX + lean, -8)
                            ctx.lineTo(baseX - lean, height + 8)
                            ctx.strokeStyle = veloraTheme.alpha(lineColor, veloraTheme.themeMode === "dark" ? 0.34 : 0.42)
                            ctx.lineWidth = 1.45
                            ctx.stroke()

                            ctx.beginPath()
                            ctx.moveTo(baseX + lean + 3, -5)
                            ctx.lineTo(baseX - lean + 3, height + 5)
                            ctx.strokeStyle = veloraTheme.alpha(highlightColor, veloraTheme.themeMode === "dark" ? 0.18 : 0.24)
                            ctx.lineWidth = 0.85
                            ctx.stroke()
                        }

                        function drawSelectedEdge(edgeX, edgeLean, edgeAlpha) {
                            ctx.beginPath()
                            ctx.moveTo(edgeX + edgeLean, -8)
                            ctx.lineTo(edgeX - edgeLean, height + 8)
                            ctx.strokeStyle = veloraTheme.alpha(lineColor, edgeAlpha)
                            ctx.lineWidth = 2.1
                            ctx.stroke()

                            ctx.beginPath()
                            ctx.moveTo(edgeX + edgeLean + 3, -4)
                            ctx.lineTo(edgeX - edgeLean + 3, height + 4)
                            ctx.strokeStyle = veloraTheme.alpha(highlightColor, edgeAlpha * 0.72)
                            ctx.lineWidth = 0.95
                            ctx.stroke()
                        }

                        drawSelectedEdge(selectedLeft, lean, veloraTheme.themeMode === "dark" ? 0.42 : 0.50)
                        drawSelectedEdge(selectedRight, lean, veloraTheme.themeMode === "dark" ? 0.42 : 0.50)

                        if (root.topWallpaperSlideDirection !== 0) {
                            drawSelectedEdge(incomingLeft, lean, (veloraTheme.themeMode === "dark" ? 0.42 : 0.50) * selectedProgress)
                            drawSelectedEdge(incomingRight, lean, (veloraTheme.themeMode === "dark" ? 0.42 : 0.50) * selectedProgress)
                        }
                    }

                    Component.onCompleted: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()

                    Connections {
                        target: veloraTheme
                        function onSurfaceSidebarChanged() { topWallpaperSliceCanvas.requestPaint() }
                        function onBorderSoftChanged() { topWallpaperSliceCanvas.requestPaint() }
                        function onThemeModeChanged() { topWallpaperSliceCanvas.requestPaint() }
                        function onSidebarBorderGlowChanged() { topWallpaperSliceCanvas.requestPaint() }
                    }

                    Connections {
                        target: root

                        function onTopWallpaperSlideProgressChanged() { topWallpaperSliceCanvas.requestPaint() }
                        function onTopWallpaperSlideDirectionChanged() { topWallpaperSliceCanvas.requestPaint() }
                    }
                }

                Item {
                    id: topWallpaperNavLeft

                    visible: root.topWallpaperPopupOpen
                    anchors {
                        top: topWallpaperPopupSurface.top
                        bottom: topWallpaperPopupSurface.bottom
                        left: topWallpaperPopupSurface.left
                    }
                    width: Math.min(74, topWallpaperPopupSurface.width * 0.16)
                    opacity: topWallpaperNavLeftMouse.containsMouse || root.topWallpaperKeyboardFocus ? 0.82 : 0.30

                    Behavior on opacity {
                        enabled: veloraTheme.motionEnabled
                        NumberAnimation { duration: veloraTheme.motionFast; easing.type: Easing.OutCubic }
                    }

                    Rectangle {
                        width: 30
                        height: 64
                        radius: 15
                        anchors {
                            left: parent.left
                            leftMargin: 8
                            verticalCenter: parent.verticalCenter
                        }
                        color: veloraTheme.alpha(veloraTheme.surfaceSidebar, veloraTheme.themeMode === "dark" ? 0.36 : 0.42)
                        border.width: 1
                        border.color: root.sidebarPanelInnerLineColor()
                    }

                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: 16
                            verticalCenter: parent.verticalCenter
                        }
                        text: "‹"
                        color: veloraTheme.alpha(veloraTheme.textPrimary, veloraTheme.themeMode === "dark" ? 0.76 : 0.68)
                        font.pixelSize: 28
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: topWallpaperNavLeftMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.moveTopWallpaper(-1)
                            topWallpaperPopupStage.forceActiveFocus()
                        }
                    }
                }

                Item {
                    id: topWallpaperNavRight

                    visible: root.topWallpaperPopupOpen
                    anchors {
                        top: topWallpaperPopupSurface.top
                        bottom: topWallpaperPopupSurface.bottom
                        right: topWallpaperPopupSurface.right
                    }
                    width: Math.min(74, topWallpaperPopupSurface.width * 0.16)
                    opacity: topWallpaperNavRightMouse.containsMouse || root.topWallpaperKeyboardFocus ? 0.82 : 0.30

                    Behavior on opacity {
                        enabled: veloraTheme.motionEnabled
                        NumberAnimation { duration: veloraTheme.motionFast; easing.type: Easing.OutCubic }
                    }

                    Rectangle {
                        width: 30
                        height: 64
                        radius: 15
                        anchors {
                            right: parent.right
                            rightMargin: 8
                            verticalCenter: parent.verticalCenter
                        }
                        color: veloraTheme.alpha(veloraTheme.surfaceSidebar, veloraTheme.themeMode === "dark" ? 0.36 : 0.42)
                        border.width: 1
                        border.color: root.sidebarPanelInnerLineColor()
                    }

                    Text {
                        anchors {
                            right: parent.right
                            rightMargin: 16
                            verticalCenter: parent.verticalCenter
                        }
                        text: "›"
                        color: veloraTheme.alpha(veloraTheme.textPrimary, veloraTheme.themeMode === "dark" ? 0.76 : 0.68)
                        font.pixelSize: 28
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: topWallpaperNavRightMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.moveTopWallpaper(1)
                            topWallpaperPopupStage.forceActiveFocus()
                        }
                    }
                }

            }
        }
    }

    Variants {
        model: []

        PanelWindow {
            id: leftMenuPanel

            required property var modelData
            property real reveal: root.leftMenuFrameReveal
            property real mediaReveal: root.leftMenuOpen && root.leftMediaWindowOpen ? 1 : 0
            readonly property int slideDistance: root.leftMenuWidth + root.leftMenuFrameInset + root.leftMenuTriggerWidth + 8
            readonly property bool mediaWindowVisible: root.leftMediaWindowOpen || mediaReveal > 0.01
            readonly property bool menuOnLeft: root.leftMenuOnLeft
            readonly property real detailReveal: mediaReveal * root.leftDetailSwitchProgress
            readonly property int detailWindowWidth: root.leftDetailWindowWidth(root.leftDetailWindowType)
            readonly property int detailWindowHeight: root.leftDetailWindowHeight(root.leftDetailWindowType, height)
            readonly property int menuOpenX: menuOnLeft ? root.leftMenuFrameInset : width - root.leftMenuFrameInset - root.leftMenuWidth
            readonly property int menuSlideOffset: Math.round((1 - reveal) * slideDistance)
            readonly property int menuX: menuOpenX + (menuOnLeft ? -menuSlideOffset : menuSlideOffset)
            readonly property int mediaWindowX: menuOnLeft ? menuOpenX + root.leftMenuWidth + root.leftMediaWindowGap : menuOpenX - root.leftMediaWindowGap - detailWindowWidth
            readonly property int mediaWindowSlideDistance: Math.min(118, Math.max(82, Math.round(detailWindowWidth * 0.18)))

            screen: modelData
            color: "transparent"
            implicitWidth: Math.max(root.leftMenuHandleWidth, root.leftMenuFrameInset + root.leftMenuWidth + 1, mediaWindowVisible ? root.leftMenuFrameInset + root.leftMenuWidth + root.leftMediaWindowGap + detailWindowWidth + root.leftMenuFrameInset : 0)
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            focusable: root.leftMenuOpen

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "velora-shell-left-menu"
            WlrLayershell.keyboardFocus: root.leftMenuOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: root.leftMenuOnLeft
                right: !root.leftMenuOnLeft
            }

            mask: Region {
                Region {
                    item: leftMenuTrigger
                    radius: 0
                }

                Region {
                    item: leftMenuHandle
                    radius: Math.min(root.desktopFrameRadius, 16)
                }

                Region {
                    item: leftMenuInputMask
                    radius: leftMenuLoader.item ? leftMenuLoader.item.cornerRadius : 13
                }

                Region {
                    item: leftMediaWindowInputMask
                    radius: leftMediaWindowLoader.cornerRadius
                }
            }

            Behavior on mediaReveal {
                enabled: veloraTheme.motionEnabled
                NumberAnimation {
                    duration: root.leftMediaWindowOpen ? veloraTheme.motionPanelIn : veloraTheme.motionPanelOut
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.leftMediaWindowOpen ? veloraTheme.motionCurveEmphasizedDecel : veloraTheme.motionCurveEmphasizedAccel
                }
            }

            Item {
                id: leftMenuTrigger

                x: leftMenuPanel.menuOnLeft ? 0 : parent.width - width
                y: root.leftMenuYForScreen(parent.height, root.leftMenuHeightForScreen(parent.height))
                width: root.leftMenuHandleWidth
                height: root.leftMenuHeightForScreen(parent.height)

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    onEntered: {
                        root.leftMenuTriggerHovering = true
                        root.holdLeftMenuHandleReveal()
                        root.updateLeftMenuHovering()
                    }
                    onPositionChanged: {
                        root.leftMenuTriggerHovering = true
                        root.holdLeftMenuHandleReveal()
                        root.updateLeftMenuHovering()
                    }
                    onExited: {
                        root.leftMenuTriggerHovering = false
                        root.releaseLeftMenuHandleRevealSoon()
                        root.updateLeftMenuHovering()
                        root.scheduleLeftMenuClose()
                    }
                }
            }

            Item {
                id: leftMenuHandle

                readonly property real reveal: root.leftMenuHandleSurfaceReveal

                x: leftMenuPanel.menuOnLeft
                    ? Math.round(-10 - (1 - reveal) * (root.leftMenuHandleWidth - 10))
                    : parent.width - root.leftMenuHandleWidth + 10 + Math.round((1 - reveal) * (root.leftMenuHandleWidth - 10))
                y: root.leftMenuYForScreen(parent.height, root.leftMenuHeightForScreen(parent.height)) + Math.round((root.leftMenuHeightForScreen(parent.height) - root.leftMenuHandleHeight) / 2)
                width: root.leftMenuHandleWidth
                height: root.leftMenuHandleHeight
                opacity: reveal
                visible: reveal > 0.01
                z: 30

                Canvas {
                    id: leftMenuHandleSurfaceCanvas

                    anchors.fill: parent
                    antialiasing: true
                    z: -1

                    function path(ctx) {
                        const r = Math.min(root.desktopFrameRadius, 16, width / 2, height / 2)
                        const x2 = width
                        const y2 = height

                        ctx.beginPath()
                        if (leftMenuPanel.menuOnLeft) {
                            ctx.moveTo(0, 0)
                            ctx.lineTo(x2 - r, 0)
                            ctx.arcTo(x2, 0, x2, r, r)
                            ctx.lineTo(x2, y2 - r)
                            ctx.arcTo(x2, y2, x2 - r, y2, r)
                            ctx.lineTo(0, y2)
                            ctx.lineTo(0, 0)
                        } else {
                            ctx.moveTo(r, 0)
                            ctx.arcTo(0, 0, 0, r, r)
                            ctx.lineTo(0, y2 - r)
                            ctx.arcTo(0, y2, r, y2, r)
                            ctx.lineTo(x2, y2)
                            ctx.lineTo(x2, 0)
                            ctx.lineTo(r, 0)
                        }
                        ctx.closePath()
                    }

                    function openStrokePath(ctx) {
                        const r = Math.min(root.desktopFrameRadius, 16, width / 2, height / 2)
                        const x2 = width
                        const y2 = height

                        ctx.beginPath()
                        if (leftMenuPanel.menuOnLeft) {
                            ctx.moveTo(0, 0.5)
                            ctx.lineTo(x2 - r, 0.5)
                            ctx.arcTo(x2 - 0.5, 0.5, x2 - 0.5, r, r)
                            ctx.lineTo(x2 - 0.5, y2 - r)
                            ctx.arcTo(x2 - 0.5, y2 - 0.5, x2 - r, y2 - 0.5, r)
                            ctx.lineTo(0, y2 - 0.5)
                        } else {
                            ctx.moveTo(x2, 0.5)
                            ctx.lineTo(r, 0.5)
                            ctx.arcTo(0.5, 0.5, 0.5, r, r)
                            ctx.lineTo(0.5, y2 - r)
                            ctx.arcTo(0.5, y2 - 0.5, r, y2 - 0.5, r)
                            ctx.lineTo(x2, y2 - 0.5)
                        }
                    }

                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        if (width <= 1 || height <= 1)
                            return

                        ctx.fillStyle = root.desktopFrameMatteColor()
                        path(ctx)
                        ctx.fill()

                        ctx.strokeStyle = root.desktopFrameBorderColor()
                        ctx.lineWidth = 1
                        ctx.lineCap = "round"
                        ctx.lineJoin = "round"
                        openStrokePath(ctx)
                        ctx.stroke()
                    }

                    Component.onCompleted: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()

                    Connections {
                        target: veloraTheme
                        function onSurfaceSidebarChanged() { leftMenuHandleSurfaceCanvas.requestPaint() }
                        function onSidebarOpacityChanged() { leftMenuHandleSurfaceCanvas.requestPaint() }
                        function onThemeModeChanged() { leftMenuHandleSurfaceCanvas.requestPaint() }
                        function onThemeIdChanged() { leftMenuHandleSurfaceCanvas.requestPaint() }
                        function onBorderSoftChanged() { leftMenuHandleSurfaceCanvas.requestPaint() }
                    }
                }

                Text {
                    width: 22
                    height: 34
                    x: leftMenuPanel.menuOnLeft ? parent.width - width - 5 : 5
                    anchors.verticalCenter: parent.verticalCenter
                    text: leftMenuPanel.menuOnLeft ? "›" : "‹"
                    color: veloraTheme.alpha(veloraTheme.textPrimary, veloraTheme.themeMode === "dark" ? 0.76 : 0.70)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: veloraTheme.uiFont
                    font.pixelSize: 27
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: {
                        root.leftMenuHandleHovering = true
                        root.holdLeftMenuHandleReveal()
                        root.updateLeftMenuHovering()
                    }
                    onExited: {
                        root.leftMenuHandleHovering = false
                        root.releaseLeftMenuHandleRevealSoon()
                        root.updateLeftMenuHovering()
                        root.scheduleLeftMenuClose()
                    }
                    onClicked: {
                        root.leftMenuPinned = false
                        root.leftMenuInteractiveFocus = false
                        root.openLeftMenu()
                        root.updateLeftMenuHovering()
                        root.scheduleLeftMenuClose()
                    }
                }
            }

            Item {
                id: leftMenuInputMask

                x: leftMenuLoader.x
                y: leftMenuLoader.y
                width: (root.leftMenuOpen || leftMenuPanel.reveal > 0.01) ? leftMenuLoader.width : 0
                height: (root.leftMenuOpen || leftMenuPanel.reveal > 0.01) ? leftMenuLoader.height : 0
            }

            Item {
                id: leftMediaWindowInputMask

                x: leftMediaWindowLoader.x
                y: leftMediaWindowLoader.y
                width: leftMediaWindowLoader.active ? leftMediaWindowLoader.width : 0
                height: leftMediaWindowLoader.active ? leftMediaWindowLoader.height : 0
            }

            Canvas {
                id: leftMenuSurfaceCanvas

                x: leftMenuLoader.x
                y: leftMenuLoader.y
                width: leftMenuLoader.width
                height: leftMenuLoader.height
                opacity: Math.min(1, leftMenuPanel.reveal * 1.35)
                visible: (root.leftMenuOpen || leftMenuPanel.reveal > 0.01) && leftMenuLoader.contentReady
                antialiasing: true
                z: 0

                function surfacePath(ctx) {
                    const r = Math.min(leftMenuLoader.item ? leftMenuLoader.item.cornerRadius : 22, width / 2, height / 2)
                    const x2 = width
                    const y2 = height

                    ctx.beginPath()
                    if (leftMenuPanel.menuOnLeft) {
                        ctx.moveTo(0, 0)
                        ctx.lineTo(x2 - r, 0)
                        ctx.arcTo(x2, 0, x2, r, r)
                        ctx.lineTo(x2, y2 - r)
                        ctx.arcTo(x2, y2, x2 - r, y2, r)
                        ctx.lineTo(0, y2)
                        ctx.lineTo(0, 0)
                    } else {
                        ctx.moveTo(r, 0)
                        ctx.arcTo(0, 0, 0, r, r)
                        ctx.lineTo(0, y2 - r)
                        ctx.arcTo(0, y2, r, y2, r)
                        ctx.lineTo(x2, y2)
                        ctx.lineTo(x2, 0)
                        ctx.lineTo(r, 0)
                    }
                    ctx.closePath()
                }

                function openStrokePath(ctx) {
                    const r = Math.min(leftMenuLoader.item ? leftMenuLoader.item.cornerRadius : 22, width / 2, height / 2)
                    const x2 = width
                    const y2 = height

                    ctx.beginPath()
                    if (leftMenuPanel.menuOnLeft) {
                        ctx.moveTo(0, 0.5)
                        ctx.lineTo(x2 - r, 0.5)
                        ctx.arcTo(x2 - 0.5, 0.5, x2 - 0.5, r, r)
                        ctx.lineTo(x2 - 0.5, y2 - r)
                        ctx.arcTo(x2 - 0.5, y2 - 0.5, x2 - r, y2 - 0.5, r)
                        ctx.lineTo(0, y2 - 0.5)
                    } else {
                        ctx.moveTo(x2, 0.5)
                        ctx.lineTo(r, 0.5)
                        ctx.arcTo(0.5, 0.5, 0.5, r, r)
                        ctx.lineTo(0.5, y2 - r)
                        ctx.arcTo(0.5, y2 - 0.5, r, y2 - 0.5, r)
                        ctx.lineTo(x2, y2 - 0.5)
                    }
                }

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    if (width <= 1 || height <= 1)
                        return

                    ctx.fillStyle = root.desktopFrameMatteColor()
                    surfacePath(ctx)
                    ctx.fill()

                    ctx.strokeStyle = root.desktopFrameBorderColor()
                    ctx.lineWidth = 1
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    openStrokePath(ctx)
                    ctx.stroke()
                }

                Component.onCompleted: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onVisibleChanged: if (visible) requestPaint()

                Connections {
                    target: veloraTheme
                    function onSurfaceSidebarChanged() { leftMenuSurfaceCanvas.requestPaint() }
                    function onSidebarOpacityChanged() { leftMenuSurfaceCanvas.requestPaint() }
                    function onThemeModeChanged() { leftMenuSurfaceCanvas.requestPaint() }
                    function onThemeIdChanged() { leftMenuSurfaceCanvas.requestPaint() }
                    function onBorderSoftChanged() { leftMenuSurfaceCanvas.requestPaint() }
                }
            }

            VeloraAttachedSurface {
                theme: veloraTheme
                useCustomGlass: root.frameVisualsMounted
                customGlass: root.desktopFrameMatteColor()
                lineReveal: true
                transitionContrast: 0
                slideOffsetOverride: 76
                flattenAttachedEdge: true
                attachSide: leftMenuPanel.menuOnLeft ? "left" : "right"
                x: leftMenuLoader.x
                y: leftMenuLoader.y
                width: leftMenuLoader.width
                height: leftMenuLoader.height
                radius: leftMenuLoader.item ? leftMenuLoader.item.cornerRadius : 13
                revealProgress: leftMenuPanel.reveal
                visible: false
            }

            Loader {
                id: leftMenuLoader

                active: root.leftMenuPreloadEnabled || root.leftMenuOpen || leftMenuPanel.reveal > 0.01
                asynchronous: false
                readonly property bool contentReady: item !== null
                width: root.leftMenuWidth
                height: root.leftMenuHeightForScreen(parent.height)
                x: leftMenuPanel.menuX
                y: root.leftMenuYForScreen(parent.height, height)
                visible: root.leftMenuOpen || leftMenuPanel.reveal > 0.01
                opacity: 1
                z: 1

                sourceComponent: Component {
                    VeloraLeftOverview {
                        theme: veloraTheme
                        clockState: leftClockState
                        externalSurface: true
                        attachSide: leftMenuPanel.menuOnLeft ? "left" : "right"
                        popupType: "search"
                        open: root.leftMenuOpen || leftMenuPanel.reveal > 0.01
                        preload: root.leftMenuPreloadEnabled
                        interactiveFocus: root.leftMenuInteractiveFocus
                        width: leftMenuLoader.width
                        height: leftMenuLoader.height
                        visible: leftMenuLoader.visible

                        onMediaWindowRequested: function(centerY) {
                            root.openLeftMediaWindow(leftMenuLoader.y + centerY)
                        }

                        onDetailWindowRequested: function(detailType, centerY) {
                            root.openLeftDetailWindow(detailType, leftMenuLoader.y + centerY)
                        }

                        onAgendaRequested: function(centerY) {
                            root.leftMenuPinned = false
                            root.leftMenuInteractiveFocus = false
                            root.leftMediaWindowOpen = false
                            root.leftMediaWindowEntranceHold = false
                            root.leftMenuOpen = false
                            root.openAdaptiveBarPopup("agenda", root.defaultQuickPopupCenterY("agenda"))
                        }

                        onSettingsRequested: function(centerY) {
                            root.leftMenuPinned = false
                            root.leftMenuInteractiveFocus = false
                            root.leftMediaWindowOpen = false
                            root.leftMediaWindowEntranceHold = false
                            root.leftDetailSwitchProgress = 1
                            root.openLeftMenu()
                            root.toggleSettingsPanel(leftMenuLoader.y + centerY)
                        }

                        onCloseRequested: {
                            root.leftMenuPinned = false
                            root.leftMenuInteractiveFocus = false
                            root.leftMediaWindowOpen = false
                            root.leftMediaWindowEntranceHold = false
                            root.leftDetailSwitchProgress = 1
                            root.leftMenuOpen = false
                            root.leftMenuTriggerHovering = false
                            root.leftMenuPanelHovering = false
                            root.leftMediaWindowHovering = false
                        }

                        HoverHandler {
                            margin: 18
                            onHoveredChanged: {
                                root.leftMenuPanelHovering = hovered
                                root.updateLeftMenuHovering()
                                if (hovered)
                                    root.openLeftMenu()
                                else
                                    root.scheduleLeftMenuClose()
                            }
                        }
                    }
                }
            }

            VeloraAttachedSurface {
                theme: veloraTheme
                sidebarMaterial: true
                attachSide: leftMenuPanel.menuOnLeft ? "left" : "right"
                x: leftMediaWindowLoader.x
                y: leftMediaWindowLoader.y
                width: leftMediaWindowLoader.width
                height: leftMediaWindowLoader.height
                radius: leftMediaWindowLoader.cornerRadius
                revealProgress: leftMenuPanel.mediaReveal
                visible: leftMenuPanel.mediaWindowVisible
            }

            Loader {
                id: leftMediaWindowLoader

                readonly property int cornerRadius: 22

                active: leftMenuPanel.mediaWindowVisible
                asynchronous: false
                width: leftMenuPanel.detailWindowWidth
                height: leftMenuPanel.detailWindowHeight
                x: leftMenuPanel.mediaWindowX + (leftMenuPanel.menuOnLeft ? -1 : 1) * Math.round((1 - leftMenuPanel.mediaReveal) * leftMenuPanel.mediaWindowSlideDistance)
                y: root.leftMediaWindowY(height, parent.height) + Math.round((1 - leftMenuPanel.mediaReveal) * 14)
                visible: active
                opacity: leftMenuPanel.mediaReveal
                scale: 0.94 + leftMenuPanel.mediaReveal * 0.06
                transformOrigin: leftMenuPanel.menuOnLeft ? Item.Left : Item.Right

                onActiveChanged: if (!active) root.leftMediaWindowHovering = false

                sourceComponent: Component {
                    Item {
                        width: leftMediaWindowLoader.width
                        height: leftMediaWindowLoader.height
                        visible: leftMediaWindowLoader.active
                        opacity: leftMenuPanel.detailReveal
                        scale: 0.975 + leftMenuPanel.detailReveal * 0.025
                        x: (leftMenuPanel.menuOnLeft ? -1 : 1) * Math.round((1 - leftMenuPanel.detailReveal) * 28)
                        transformOrigin: leftMenuPanel.menuOnLeft ? Item.Left : Item.Right

                        VeloraDashboard {
                            anchors.fill: parent
                            theme: veloraTheme
                            compact: true
                            externalSurface: true
                            entryProgress: leftMenuPanel.detailReveal
                            activeSection: "media"
                            visible: root.leftDetailWindowType === "media"
                        }

                        VeloraLeftDetailPanel {
                            anchors.fill: parent
                            theme: veloraTheme
                            clockState: leftClockState
                            attachSide: leftMenuPanel.menuOnLeft ? "left" : "right"
                            detailType: root.leftDetailWindowType
                            entryProgress: leftMenuPanel.detailReveal
                            visible: root.leftDetailWindowType !== "media"
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: leftMediaWindowLoader.active
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                            onEntered: {
                                root.leftMediaWindowHovering = true
                                root.updateLeftMenuHovering()
                                root.openLeftMenu()
                            }
                            onExited: {
                                root.leftMediaWindowHovering = false
                                root.scheduleLeftMenuClose()
                            }
                        }
                    }
                }

                Behavior on y {
                    enabled: veloraTheme.motionEnabled && leftMediaWindowLoader.active
                    NumberAnimation {
                        duration: veloraTheme.motionPanelGeometry
                        easing.type: veloraTheme.motionEaseEmphasized
                        easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                    }
                }

                Behavior on scale {
                    enabled: veloraTheme.motionEnabled && leftMediaWindowLoader.active
                    NumberAnimation {
                        duration: veloraTheme.motionPanelGeometry
                        easing.type: veloraTheme.motionEaseEmphasized
                        easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                    }
                }
            }
        }
    }

    Variants {
        model: root.frameVisualsMounted && !root.shellSuppressedByFullscreen ? Quickshell.screens : []

        PanelWindow {
            id: framePanel

            required property var modelData
            readonly property bool compositorReservedBarSpace: root.sideBarLayoutEnabled && modelData.width > 0 && width <= modelData.width - root.barPanelWidth + 2
            readonly property color frameMatteColor: root.desktopFrameMatteColor()
            readonly property color frameBorderColor: root.desktopFrameBorderColor()
            readonly property color frameHighlightColor: root.desktopFrameHighlightColor()

            visible: false
            screen: modelData
            color: "transparent"
            implicitWidth: modelData.width > 0 ? modelData.width : 1
            implicitHeight: modelData.height > 0 ? modelData.height : 1
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            focusable: false

            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "velora-shell-frame"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            mask: Region {}

            function frameX() {
                if (compositorReservedBarSpace)
                    return root.desktopFrameMargin
                return root.mainAreaX(width)
            }

            function frameY() {
                return root.desktopFrameY(height)
            }

            function frameWidth() {
                if (compositorReservedBarSpace)
                    return Math.max(0, width - root.desktopFrameMargin * 2)
                return Math.max(0, root.mainAreaWidth(width))
            }

            function frameHeight() {
                return root.desktopFrameHeight(height)
            }

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Canvas {
                id: frameMatteCanvas

                anchors.fill: parent
                antialiasing: true
                visible: false
                opacity: root.frameVisualsReveal

                function paintCorner(ctx, corner, fx, fy, fw, fh, radius) {
                    const x2 = fx + fw
                    const y2 = fy + fh
                    ctx.beginPath()

                    if (corner === "topLeft") {
                        ctx.moveTo(fx, fy)
                        ctx.lineTo(fx + radius, fy)
                        ctx.arc(fx + radius, fy + radius, radius, -Math.PI / 2, Math.PI, true)
                        ctx.lineTo(fx, fy)
                    } else if (corner === "topRight") {
                        ctx.moveTo(x2, fy)
                        ctx.lineTo(x2 - radius, fy)
                        ctx.arc(x2 - radius, fy + radius, radius, -Math.PI / 2, 0, false)
                        ctx.lineTo(x2, fy)
                    } else if (corner === "bottomRight") {
                        ctx.moveTo(x2, y2)
                        ctx.lineTo(x2, y2 - radius)
                        ctx.arc(x2 - radius, y2 - radius, radius, 0, Math.PI / 2, false)
                        ctx.lineTo(x2, y2)
                    } else if (corner === "bottomLeft") {
                        ctx.moveTo(fx, y2)
                        ctx.lineTo(fx + radius, y2)
                        ctx.arc(fx + radius, y2 - radius, radius, Math.PI / 2, Math.PI, false)
                        ctx.lineTo(fx, y2)
                    }

                    ctx.closePath()
                    ctx.fill()
                }

                function paintFrameOutline(ctx, fx, fy, fw, fh, radius) {
                    const x2 = fx + fw
                    const y2 = fy + fh
                    const barSide = root.sideBarLayoutEnabled ? (root.barOnRight ? "right" : "left") : ""
                    const openSideTrim = root.sideVisualizerMounted ? Math.max(radius, root.sideVisualizerCapReach) : radius
                    const bottomOpenCorner = root.sideBarLayoutEnabled && root.topWallpaperUsesBottomSelector && root.topWallpaperFrameReveal > 0.01
                    const openCornerRadius = bottomOpenCorner ? Math.max(radius, Math.min(34, root.sideVisualizerWaveWidth * 0.52)) : radius
                    const horizontalStart = barSide === "left" ? fx + openSideTrim : fx + radius
                    const horizontalEnd = barSide === "right" ? x2 - openSideTrim : x2
                    const bottomHorizontalStart = barSide === "left" && bottomOpenCorner ? fx + openCornerRadius : horizontalStart
                    const bottomHorizontalEnd = barSide === "right" && bottomOpenCorner ? x2 - openCornerRadius : horizontalEnd

                    ctx.save()
                    ctx.strokeStyle = framePanel.frameBorderColor
                    ctx.lineWidth = 1
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    ctx.beginPath()

                    if (barSide !== "left") {
                        ctx.moveTo(fx + radius, fy)
                        ctx.arc(fx + radius, fy + radius, radius, -Math.PI / 2, Math.PI, true)
                        ctx.lineTo(fx, y2 - radius)
                        ctx.arc(fx + radius, y2 - radius, radius, Math.PI, Math.PI / 2, true)
                    } else {
                        ctx.moveTo(fx + radius, fy)
                    }

                    if (barSide !== "right") {
                        ctx.moveTo(x2, fy)
                        ctx.lineTo(x2, y2 - radius)
                        ctx.arc(x2 - radius, y2 - radius, radius, 0, Math.PI / 2, false)
                    }

                    if (horizontalEnd > horizontalStart) {
                        ctx.moveTo(horizontalStart, fy)
                        ctx.lineTo(horizontalEnd, fy)
                    }

                    if (bottomHorizontalEnd > bottomHorizontalStart) {
                        ctx.moveTo(bottomHorizontalStart, y2)
                        ctx.lineTo(bottomHorizontalEnd, y2)
                    }

                    if (bottomOpenCorner) {
                        if (barSide === "right") {
                            ctx.moveTo(x2, y2 - openCornerRadius)
                            ctx.arc(x2 - openCornerRadius, y2 - openCornerRadius, openCornerRadius, 0, Math.PI / 2, false)
                        } else {
                            ctx.moveTo(fx, y2 - openCornerRadius)
                            ctx.arc(fx + openCornerRadius, y2 - openCornerRadius, openCornerRadius, Math.PI, Math.PI / 2, true)
                        }
                    }

                    ctx.stroke()
                    ctx.restore()
                }

                onPaint: {
                    const ctx = getContext("2d")
                    const fx = Math.round(framePanel.frameX())
                    const fy = Math.round(framePanel.frameY())
                    const fw = Math.round(framePanel.frameWidth())
                    const fh = Math.round(framePanel.frameHeight())
                    const radius = Math.min(root.desktopFrameRadius, Math.max(0, fw / 2), Math.max(0, fh / 2))

                    ctx.clearRect(0, 0, width, height)
                    if (!root.frameVisualsMounted || fw <= 0 || fh <= 0)
                        return

                    const barSide = root.sideBarLayoutEnabled ? (root.barOnRight ? "right" : "left") : ""
                    const openCornerRadius = root.topWallpaperUsesBottomSelector && root.topWallpaperFrameReveal > 0.01
                        ? Math.max(radius, Math.min(34, root.sideVisualizerWaveWidth * 0.52))
                        : radius

                    ctx.fillStyle = framePanel.frameMatteColor
                    ctx.fillRect(0, 0, width, fy)
                    ctx.fillRect(0, fy + fh, width, Math.max(0, height - fy - fh))
                    if (barSide !== "left") {
                        ctx.fillRect(0, fy, fx, fh)
                        paintCorner(ctx, "topLeft", fx, fy, fw, fh, radius)
                        paintCorner(ctx, "bottomLeft", fx, fy, fw, fh, radius)
                    }
                    if (barSide !== "right") {
                        ctx.fillRect(fx + fw, fy, Math.max(0, width - fx - fw), fh)
                        paintCorner(ctx, "bottomRight", fx, fy, fw, fh, radius)
                    }
                    if (root.sideBarLayoutEnabled && root.topWallpaperUsesBottomSelector && root.topWallpaperFrameReveal > 0.01) {
                        paintCorner(ctx, barSide === "right" ? "bottomRight" : "bottomLeft", fx, fy, fw, fh, openCornerRadius)
                    }
                    paintFrameOutline(ctx, fx, fy, fw, fh, radius)
                }

                Component.onCompleted: if (root.frameVisualsMounted) requestPaint()
                onWidthChanged: if (root.frameVisualsMounted) requestPaint()
                onHeightChanged: if (root.frameVisualsMounted) requestPaint()
                onVisibleChanged: if (visible) requestPaint()
            }

            Rectangle {
                id: desktopFrame

                x: framePanel.frameX()
                y: framePanel.frameY()
                width: framePanel.frameWidth()
                height: framePanel.frameHeight()
                radius: root.desktopFrameRadius
                color: "transparent"
                border.width: 0
                border.color: framePanel.frameBorderColor
                opacity: root.frameVisualsReveal
                antialiasing: true
            }

            Rectangle {
                x: desktopFrame.x + 1
                y: desktopFrame.y + 1
                width: Math.max(0, desktopFrame.width - 2)
                height: Math.max(0, desktopFrame.height - 2)
                radius: Math.max(0, desktopFrame.radius - 1)
                color: "transparent"
                visible: false
                border.width: 1
                border.color: framePanel.frameHighlightColor
                antialiasing: true
            }

            Connections {
                target: veloraTheme
                function onSurfaceBaseChanged() { if (root.frameVisualsMounted) frameMatteCanvas.requestPaint() }
                function onSidebarOpacityChanged() { if (root.frameVisualsMounted) frameMatteCanvas.requestPaint() }
                function onThemeModeChanged() { if (root.frameVisualsMounted) frameMatteCanvas.requestPaint() }
                function onPopupBorderGlowChanged() { if (root.frameVisualsMounted) frameMatteCanvas.requestPaint() }
                function onBorderSoftChanged() { if (root.frameVisualsMounted) frameMatteCanvas.requestPaint() }
            }

            Connections {
                target: root
                function onBarOnRightChanged() { if (root.frameVisualsMounted) frameMatteCanvas.requestPaint() }
                function onDesktopFrameMarginChanged() { if (root.frameVisualsMounted) frameMatteCanvas.requestPaint() }
                function onDesktopFrameRadiusChanged() { if (root.frameVisualsMounted) frameMatteCanvas.requestPaint() }
                function onTopWallpaperFrameRevealChanged() { if (root.frameVisualsMounted) frameMatteCanvas.requestPaint() }
            }
        }
    }

    Variants {
        model: []

        PanelWindow {
            id: notificationToastPanel

            required property var modelData
            readonly property int screenWidth: modelData.width > 0 ? modelData.width : 1920
            readonly property int surfaceWidth: width > 0 ? width : Math.max(320, screenWidth - root.barReserveWidth)
            readonly property int toastWidth: Math.round(Math.min(Math.max(320, surfaceWidth - 96), Math.max(340, surfaceWidth * 0.18)))
            readonly property int toastHeight: 48
            readonly property int toastRadius: 17

            visible: root.notificationToastMounted
            screen: modelData
            color: "transparent"
            implicitWidth: screenWidth
            implicitHeight: toastHeight
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            focusable: false

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "velora-notification-frame"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                left: true
                right: true
            }

            mask: Region {
                Region {
                    item: notificationToastInputMask
                    radius: notificationToastPanel.toastRadius
                }
            }

            Item {
                id: notificationToastInputMask

                x: notificationToastStage.x
                y: 0
                width: root.notificationToastMounted ? notificationToastStage.width : 0
                height: root.notificationToastMounted ? notificationToastStage.height : 0
            }

            Item {
                id: notificationToastStage

                width: notificationToastPanel.toastWidth
                height: notificationToastPanel.toastHeight
                x: Math.round((notificationToastPanel.surfaceWidth - width) / 2)
                y: root.notificationToastVisible ? 0 : -height - 14
                opacity: root.notificationToastVisible ? 1 : 0
                scale: root.notificationToastVisible ? 1 : 0.98
                transformOrigin: Item.Top

                Behavior on y {
                    enabled: veloraTheme.motionEnabled
                    NumberAnimation {
                        duration: root.notificationToastVisible ? 300 : 230
                        easing.type: root.notificationToastVisible ? Easing.OutCubic : Easing.InCubic
                    }
                }

                Behavior on opacity {
                    enabled: veloraTheme.motionEnabled
                    NumberAnimation {
                        duration: root.notificationToastVisible ? 170 : 140
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on scale {
                    enabled: veloraTheme.motionEnabled
                    NumberAnimation {
                        duration: 240
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    id: notificationToastBubble

                    anchors.fill: parent
                    radius: notificationToastPanel.toastRadius
                    color: root.frameVisualsMounted
                        ? root.desktopFrameMatteColor()
                        : veloraTheme.alpha(veloraTheme.surfaceSidebar, veloraTheme.themeMode === "dark" ? 0.82 : 0.74)
                    border.width: 0
                    antialiasing: true
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                    }
                    height: notificationToastPanel.toastRadius
                    color: notificationToastBubble.color
                }

                Item {
                    id: notificationToastIcon

                    width: 32
                    height: 32
                    x: 10
                    y: Math.round((parent.height - height) / 2)

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: root.notificationIconSurfaceColor(root.notificationToastIconKey)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.22)
                        antialiasing: true
                    }

                    Canvas {
                        id: notificationToastIconCanvas

                        anchors.fill: parent
                        antialiasing: true

                        function drawBell(ctx) {
                            ctx.beginPath()
                            ctx.moveTo(27, 15)
                            ctx.bezierCurveTo(19, 16, 17, 24, 17, 31)
                            ctx.lineTo(14, 37)
                            ctx.quadraticCurveTo(27, 42, 40, 37)
                            ctx.lineTo(37, 31)
                            ctx.bezierCurveTo(37, 24, 35, 16, 27, 15)
                            ctx.stroke()
                            ctx.beginPath()
                            ctx.arc(27, 41, 3.1, 0, Math.PI, false)
                            ctx.stroke()
                        }

                        function drawWhatsapp(ctx) {
                            ctx.beginPath()
                            ctx.arc(27, 26, 15, 0.22 * Math.PI, 1.86 * Math.PI, false)
                            ctx.stroke()
                            ctx.beginPath()
                            ctx.moveTo(17, 37)
                            ctx.lineTo(14, 45)
                            ctx.lineTo(23, 41)
                            ctx.stroke()
                            ctx.beginPath()
                            ctx.moveTo(22, 20)
                            ctx.bezierCurveTo(20, 22, 22, 28, 27, 33)
                            ctx.bezierCurveTo(31, 37, 36, 38, 38, 35)
                            ctx.moveTo(23, 20)
                            ctx.lineTo(26, 25)
                            ctx.moveTo(31, 32)
                            ctx.lineTo(37, 35)
                            ctx.stroke()
                        }

                        onPaint: {
                            const ctx = getContext("2d")

                            ctx.clearRect(0, 0, width, height)
                            ctx.save()
                            ctx.scale(width / 54, height / 54)
                            ctx.lineWidth = 3
                            ctx.lineCap = "round"
                            ctx.lineJoin = "round"
                            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.88)
                            ctx.fillStyle = Qt.rgba(1, 1, 1, 0.88)

                            if (root.notificationToastIconKey === "whatsapp")
                                drawWhatsapp(ctx)
                            else
                                drawBell(ctx)

                            ctx.restore()
                        }

                        Component.onCompleted: requestPaint()

                        Connections {
                            target: root
                            function onNotificationToastIconKeyChanged() { notificationToastIconCanvas.requestPaint() }
                            function onNotificationToastSerialChanged() { notificationToastIconCanvas.requestPaint() }
                        }
                    }
                }

                Text {
                    x: notificationToastIcon.x + notificationToastIcon.width + 13
                    y: Math.round((parent.height - height) / 2) - 1
                    width: parent.width - x - 16
                    text: root.notificationToastTitle
                    color: veloraTheme.textPrimary
                    font.family: veloraTheme.uiFont
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: root.hideNotificationToast()
                }
            }
        }
    }

    Variants {
        id: sidebarPanels
        model: root.shellSuppressedByFullscreen ? [] : Quickshell.screens

        PanelWindow {
            id: panel
            readonly property var bluetoothMenu: bluetoothPopover

            required property var modelData
            readonly property int panelWidth: width
            readonly property int panelHeight: height
            readonly property bool weatherTopSearchMode: root.weatherTopMode === "search"
            readonly property bool weatherTopConversationExpanded: false
            readonly property bool weatherTopNotificationAttached: root.weatherTopWindowOpen && root.notificationToastMounted
            readonly property int weatherTopOpenY: Math.max(root.desktopFrameMargin + 18, 30)
            readonly property int weatherTopTargetWidth: Math.round(Math.min(panelWidth - 100, weatherTopSearchMode ? 720 : 800))
            readonly property int weatherTopCompactHeight: 390
            readonly property int weatherTopNotificationHeight: weatherTopCompactHeight
            readonly property int weatherTopExpandedHeight: Math.round(Math.min(560, Math.max(420, panelHeight * 0.50)))
            readonly property int weatherTopSearchHeight: Math.round(Math.min(540, panelHeight - weatherTopOpenY - 70))
            readonly property int weatherTopTargetHeight: weatherTopSearchMode
                ? weatherTopSearchHeight
                : (weatherTopConversationExpanded
                    ? weatherTopExpandedHeight
                    : (weatherTopNotificationAttached ? weatherTopNotificationHeight : weatherTopCompactHeight))
            readonly property int weatherTopTargetX: Math.round((panelWidth - weatherTopTargetWidth) / 2)
            readonly property int weatherTopTargetY: root.weatherTopOpen ? weatherTopOpenY : -weatherTopTargetHeight - 18
            readonly property int weatherTopCornerRadius: 24
            property var activeRailSystemPopover: null
            readonly property bool wantsDrawerKeyboard: railControls.mounted || edgePopover.mounted || coffeePopover.mounted || notesPopover.mounted || bluetoothPopover.mounted || notificationsPopover.mounted || wifiPopover.mounted || root.focusMode || root.quickPopupType === "search" || root.quickPopupType === "agenda" || root.quickPopupType === "weatherPanel" || root.settingsPanelOpen || root.wallpaperSelectorOpen || (root.topWallpaperKeyboardFocus && root.topWallpaperUsesBottomSelector) || (!root.topBarLayout && root.weatherTopKeyboardFocus) || root.leftMenuInteractiveFocus

            screen: modelData
            color: "transparent"
            implicitWidth: Math.max(1, modelData.width)
            exclusiveZone: root.barReserveWidth
            exclusionMode: ExclusionMode.Normal
            focusable: wantsDrawerKeyboard

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "velora-shell-unified-bar"
            WlrLayershell.keyboardFocus: root.weatherTopKeyboardFocus
                ? WlrKeyboardFocus.OnDemand
                : (wantsDrawerKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None)

            // ExclusionMode.Normal places this window below the 40 px topbar.
            // Its local origin already is the join: adding barHeight here
            // would leave an unpainted band behind the analog clock.
            BackgroundEffect.blurRegion: Region {
                item: root.composition && root.composition.barBlurEnabled
                    && (root.composition.barMaterial === "glass" || !Platform.NativeBlur.supports("unified-bar-shape")) ? unifiedFrameCanvas : null
            }

            function syncUnifiedBarNativeShape() {
                const active = root.composition
                    && (root.composition.barMaterial === "liquid" || root.composition.nativeBarMaterial)
                    && width > 0 && height > 0
                if (!active) {
                    Platform.NativeBlur.dispatch("velora-blur:unified-bar-shape " + modelData.name + " 0")
                    return
                }
                // Extend the vertical lens above this LayerShell surface.
                // Its own rounded top edge stays off-screen; the visible
                // L-shaped corner is drawn separately by the unified frame.
                const opticalTopOverlap = Math.max(64, root.sidebarCornerRadius * 3)
                const top = -opticalTopOverlap / height
                const rail = root.sidebarVisualWidth / width
                // Move the vertical lens' medial axis outside the visible
                // rail, mirroring the clipped horizontal lens above.
                const left = root.barOnRight
                    ? (width - root.sidebarVisualWidth) / width : -rail
                Platform.NativeBlur.dispatch("velora-blur:unified-bar-shape " + modelData.name + " 1 "
                    + Number(left).toFixed(6) + " "
                    + Number(top).toFixed(6) + " "
                    + Number(rail * 2).toFixed(6) + " "
                    + Number(1 - top).toFixed(6) + " "
                    + Number(root.sidebarCornerRadius / width).toFixed(6) + " "
                    + Number(railControls.nativePanel ? railControls.nativePanel.y / height : 0).toFixed(6) + " "
                    + Number(railControls.nativePanel ? railControls.nativePanel.width / width : 0).toFixed(6) + " "
                    + Number(railControls.nativePanel ? railControls.nativePanel.height / height : 0).toFixed(6) + " "
                    + Number(root.bottomBarHeight / height).toFixed(6) + " "
                    + Number(railControls.nativePanel && railControls.nativePanel.extension ? railControls.nativePanel.extension.y / height : 0).toFixed(6) + " "
                    + Number(railControls.nativePanel && railControls.nativePanel.extension ? railControls.nativePanel.extension.width / width : 0).toFixed(6) + " "
                    + Number(railControls.nativePanel && railControls.nativePanel.extension ? railControls.nativePanel.extension.height / height : 0).toFixed(6) + " "
                    + Number(root.oppositeFrameWidth / width).toFixed(6) + " "
                    + Number(edgePopover.bodyY / height).toFixed(6) + " "
                    + Number(edgePopover.mounted ? edgePopover.bodyWidth / width : 0).toFixed(6) + " "
                    + Number(edgePopover.bodyHeight / height).toFixed(6) + " "
                    + Number(edgePopover.contour).toFixed(6) + " "
                    + Number(edgePopover.extension.y / height).toFixed(6) + " "
                    + Number(edgePopover.extension.width / width).toFixed(6) + " "
                    + Number(edgePopover.extension.height / height).toFixed(6) + " "
                    + edgePopover.contourSamples.map(value => Number(value).toFixed(6)).join(" ") + " "
                    + Number(edgePopover.sidebarWaveScale).toFixed(6) + " "
                    + Number(edgePopover.dockProgress).toFixed(6) + " "
                    + Number(edgePopover.sidebarWaveWidth / width).toFixed(6) + " "
                    + edgePopover.sidebarSamples.map(value => Number(value).toFixed(6)).join(" "))
            }

            DesktopBarMaterial {
                monitorName: panel.modelData.name
                composition: root.composition
                enabled: root.sideBarLayoutEnabled
            }

            Component.onCompleted: Qt.callLater(syncUnifiedBarNativeShape)
            Component.onDestruction:
                Platform.NativeBlur.dispatch("velora-blur:unified-bar-shape " + modelData.name + " 0")
            onWidthChanged: Qt.callLater(syncUnifiedBarNativeShape)
            onHeightChanged: Qt.callLater(syncUnifiedBarNativeShape)

            HyprlandFocusGrab {
                id: weatherTopFocusGrab

                active: !root.topBarLayout && root.weatherTopOpen && root.weatherTopKeyboardFocus
                windows: [panel]
                onCleared: {
                    if (root.weatherTopOpen && root.weatherTopKeyboardFocus)
                        root.closeWeatherTop()
                }
            }

            mask: Region {
                intersection: Intersection.Combine

                Region {
                    item: barRoot.panelMaskItem
                    radius: barRoot.cornerRadius
                }

                // Allow the 24 px concave join to extend beyond the
                // 66 px sidebar instead of clipping it at x=66.
                Region {
                    item: sidebarTopJoinMask
                    radius: 0
                }

                Region {
                    item: inlineWeatherTopTriggerMask
                    radius: 0
                }

                Region {
                    item: inlineWeatherTopInputMask
                    radius: panel.weatherTopCornerRadius
                }

                Region {
                    item: inlineTopSearchOutsideInputMask
                    radius: 0
                }

                Region { item: edgeTrigger }
                Region { item: edgePopover.maskItem }
                Region { item: edgePopover.labelMask }
                Region { item: railControls.volumeMask }
                Region { item: railControls.brightnessMask }
                Region { item: railControls.batteryMask }
                Region { item: coffeePopover.maskItem }
                Region { item: notesPopover.maskItem }
                Region { item: bluetoothPopover.maskItem }
                Region { item: bluetoothPopover.nameMask }
                Region { item: notificationsPopover.maskItem }
                Region { item: wifiPopover.maskItem }
                Region { item: railToolOutsideInput }

                Region {
                    item: inlineNotificationToastInputMask
                    radius: inlineNotificationToastStage.bubbleRadius
                }

                Region {
                    item: inlineQuickPopupInputMask
                    radius: inlineQuickPopupLoader.cornerRadius
                }

                Region {
                    item: inlineQuickPopupOutsideInputMask
                    radius: 0
                }

                Region {
                    item: inlineModalOverlayInputMask
                    radius: 0
                }

                Region {
                    item: inlineWallpaperInputMask
                    radius: inlineWallpaperLoader.cornerRadius
                }

                Region {
                    item: inlineSettingsInputMask
                    radius: inlineSettingsLoader.cornerRadius
                }

                Region {
                    item: topWallpaperCarouselInputMask
                    radius: root.desktopFrameRadius
                }

                Region {
                    item: topWallpaperStripInputMask
                    radius: 0
                }

                Region {
                    y: 0
                    width: 0
                    height: 0
                    radius: 0
                }
            }

            Item {
                id: sidebarTopJoinMask

                x: root.barOnRight
                    ? Math.max(0, panel.width - root.sidebarVisualWidth
                        - root.sidebarCornerRadius)
                    : 0
                y: 0
                width: root.sideBarLayoutEnabled
                    ? root.sidebarVisualWidth + root.sidebarCornerRadius : 0
                height: root.sideBarLayoutEnabled
                    ? root.sidebarCornerRadius : 0
            }

            anchors {
                top: true
                bottom: true
                left: !root.sideBarLayoutEnabled || !root.barOnRight
                right: !root.sideBarLayoutEnabled || root.barOnRight
            }

            Canvas {
                id: unifiedFrameCanvas

                anchors.fill: parent
                antialiasing: true
                visible: root.frameVisualsMounted || root.sideBarLayoutEnabled
                opacity: root.layoutSwitchOpacity
                z: 0

                function roundedRectPath(ctx, x, y, w, h, radius) {
                    const r = Math.min(radius, Math.max(0, w / 2), Math.max(0, h / 2))
                    const x2 = x + w
                    const y2 = y + h

                    ctx.beginPath()
                    ctx.moveTo(x + r, y)
                    ctx.lineTo(x2 - r, y)
                    ctx.arcTo(x2, y, x2, y + r, r)
                    ctx.lineTo(x2, y2 - r)
                    ctx.arcTo(x2, y2, x2 - r, y2, r)
                    ctx.lineTo(x + r, y2)
                    ctx.arcTo(x, y2, x, y2 - r, r)
                    ctx.lineTo(x, y + r)
                    ctx.arcTo(x, y, x + r, y, r)
                    ctx.closePath()
                }

                function paintCorner(ctx, corner, fx, fy, fw, fh, radius) {
                    const x2 = fx + fw
                    const y2 = fy + fh
                    ctx.beginPath()

                    if (corner === "topLeft") {
                        ctx.moveTo(fx, fy)
                        ctx.lineTo(fx + radius, fy)
                        ctx.arc(fx + radius, fy + radius, radius, -Math.PI / 2, Math.PI, true)
                        ctx.lineTo(fx, fy)
                    } else if (corner === "topRight") {
                        ctx.moveTo(x2, fy)
                        ctx.lineTo(x2 - radius, fy)
                        ctx.arc(x2 - radius, fy + radius, radius, -Math.PI / 2, 0, false)
                        ctx.lineTo(x2, fy)
                    } else if (corner === "bottomRight") {
                        ctx.moveTo(x2, y2)
                        ctx.lineTo(x2, y2 - radius)
                        ctx.arc(x2 - radius, y2 - radius, radius, 0, Math.PI / 2, false)
                        ctx.lineTo(x2, y2)
                    } else if (corner === "bottomLeft") {
                        ctx.moveTo(fx, y2)
                        ctx.lineTo(fx + radius, y2)
                        ctx.arc(fx + radius, y2 - radius, radius, Math.PI / 2, Math.PI, false)
                        ctx.lineTo(fx, y2)
                    }

                    ctx.closePath()
                    ctx.fill()
                }

                function paintFrameOutline(ctx, fx, fy, fw, fh, radius) {
                    const x2 = fx + fw
                    const y2 = fy + fh
                    const barSide = root.sideBarLayoutEnabled ? (root.barOnRight ? "right" : "left") : ""
                    const openSideTrim = root.sideVisualizerMounted ? Math.max(radius, root.sideVisualizerCapReach) : radius
                    const bottomOpenCorner = root.sideBarLayoutEnabled && root.topWallpaperUsesBottomSelector && root.topWallpaperFrameReveal > 0.01
                    const openCornerRadius = bottomOpenCorner ? Math.max(radius, Math.min(34, root.sideVisualizerWaveWidth * 0.52)) : radius
                    const horizontalStart = barSide === "left" ? fx + openSideTrim : fx + radius
                    const horizontalEnd = barSide === "right" ? x2 - openSideTrim : x2 - radius
                    const bottomHorizontalStart = barSide === "left" && bottomOpenCorner ? fx + openCornerRadius : horizontalStart
                    const bottomHorizontalEnd = barSide === "right" && bottomOpenCorner ? x2 - openCornerRadius : horizontalEnd

                    ctx.save()
                    ctx.strokeStyle = root.desktopFrameBorderColor()
                    ctx.lineWidth = 1
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    ctx.beginPath()

                    if (barSide !== "left") {
                        ctx.moveTo(fx + radius, fy)
                        ctx.arc(fx + radius, fy + radius, radius, -Math.PI / 2, Math.PI, true)
                        ctx.lineTo(fx, y2 - radius)
                        ctx.arc(fx + radius, y2 - radius, radius, Math.PI, Math.PI / 2, true)
                    }

                    if (barSide !== "right") {
                        ctx.moveTo(x2 - radius, fy)
                        ctx.arc(x2 - radius, fy + radius, radius, -Math.PI / 2, 0, false)
                        ctx.lineTo(x2, y2 - radius)
                        ctx.arc(x2 - radius, y2 - radius, radius, 0, Math.PI / 2, false)
                    }

                    if (horizontalEnd > horizontalStart) {
                        ctx.moveTo(horizontalStart, fy)
                        ctx.lineTo(horizontalEnd, fy)
                    }

                    if (bottomHorizontalEnd > bottomHorizontalStart) {
                        ctx.moveTo(bottomHorizontalStart, y2)
                        ctx.lineTo(bottomHorizontalEnd, y2)
                    }

                    if (bottomOpenCorner) {
                        if (barSide === "right") {
                            ctx.moveTo(x2, y2 - openCornerRadius)
                            ctx.arc(x2 - openCornerRadius, y2 - openCornerRadius, openCornerRadius, 0, Math.PI / 2, false)
                        } else {
                            ctx.moveTo(fx, y2 - openCornerRadius)
                            ctx.arc(fx + openCornerRadius, y2 - openCornerRadius, openCornerRadius, Math.PI, Math.PI / 2, true)
                        }
                    }

                    ctx.stroke()
                    ctx.restore()
                }

                function paintSidebarGutterFill(ctx) {
                    if (!root.sideBarLayoutEnabled)
                        return
                    ctx.save()
                    if (root.barOnRight) {
                        ctx.translate(width, 0)
                        ctx.scale(-1, 1)
                    }
                    const w = root.sidebarVisualWidth
                    const r = root.sidebarCornerRadius
                    // The compositor already accounts for the topbar's
                    // exclusive zone. Paint from this window's local origin.
                    const top = 0
                    const bottomStrip = Math.min(height, root.bottomBarHeight)
                    const innerRadius = Math.min(r, Math.max(0, width - w),
                        Math.max(0, (height - bottomStrip - top) / 2))
                    // A concave corner joins the two bars into one L-shaped
                    // surface. Keep the old sidebar controls inside this rail.
                    ctx.beginPath()
                    ctx.moveTo(0, top)

                    // Smooth L-shaped join with the topbar:
                    // extend along the top, then curve back into the
                    // straight right edge of the sidebar.
                    ctx.lineTo(w + r, top)
                    ctx.arcTo(w, top, w, top + r, r)

                    railControls.appendOutline(ctx, w)
                    ctx.lineTo(w, height - bottomStrip - innerRadius)
                    ctx.arcTo(w, height - bottomStrip,
                        w + innerRadius, height - bottomStrip, innerRadius)
                    const edge = width - root.oppositeFrameWidth
                    ctx.lineTo(edge - innerRadius, height - bottomStrip)
                    ctx.arcTo(edge, height - bottomStrip, edge, height - bottomStrip - innerRadius, innerRadius)
                    if (edgePopover.mounted && !root.barOnRight) {
                        const reach = edgePopover.bodyWidth
                        const by = edgePopover.bodyY
                        const bh = edgePopover.bodyHeight
                        const join = Math.min(24, reach * .5)
                        const nose = edge - reach
                        ctx.lineTo(edge, by + bh + join)
                        ctx.bezierCurveTo(edge, by + bh - join, nose, by + bh + join, nose, by + bh - join)
                        if (edgePopover.contour > .01) {
                            for (let i = 160; i >= 0; --i) {
                                const t = i / 160
                                const wave = edgePopover.contourOffset(t)
                                ctx.lineTo(nose + wave, by + bh * t)
                            }
                        } else if (edgePopover.extension.width > .01) {
                            const ey = edgePopover.extension.y
                            const ew = edgePopover.extension.width
                            ctx.lineTo(nose, ey + 52)
                            ctx.bezierCurveTo(nose, ey + 40, nose - ew, ey + 56, nose - ew, ey + 34)
                            ctx.lineTo(nose - ew, ey + 10)
                            ctx.bezierCurveTo(nose - ew, ey - 12, nose, ey + 4, nose, ey - 8)
                        }
                        ctx.lineTo(nose, by + join)
                        ctx.bezierCurveTo(nose, by - join, edge, by + join, edge, by - join)
                    }
                    ctx.lineTo(edge, top + innerRadius)
                    ctx.arcTo(edge, top, edge - innerRadius, top, innerRadius)
                    ctx.lineTo(width, top)
                    ctx.lineTo(width, height)
                    ctx.lineTo(0, height)
                    ctx.closePath()
                    if (edgePopover.sidebarWaveScale > 0 && !root.barOnRight) {
                        // Same samples and one fill as the right menu: no overlay tint.
                        ctx.moveTo(0, top)
                        for (let i = 0; i <= 160; ++i) {
                            const t = i / 160
                            ctx.lineTo(w + edgePopover.sidebarOffset(t), height * t)
                        }
                        ctx.lineTo(0, height)
                        ctx.closePath()
                    }
                    // Only this outline is supplied by the native material.
                    // Other attached QML panels still need their own tint.
                    ctx.fillStyle = root.composition && root.composition.nativeBarMaterial
                        ? "transparent" : root.sidebarBarMaterialColor()
                    ctx.fill()
                    ctx.restore()
                }

                function paintSidebarSurface(ctx) {
                    if (!root.sideBarLayoutEnabled)
                        return
                    // The unified bar has no internal border between its two
                    // legs. The wallpaper contrast defines the inner edge.
                    if (root.composition)
                        return

                    ctx.save()
                    if (root.barOnRight) {
                        ctx.translate(width, 0)
                        ctx.scale(-1, 1)
                    }
                    const w = root.sidebarVisualWidth
                    const r = root.sidebarCornerRadius
                    const bottom = height - root.bottomBarHeight
                    ctx.strokeStyle = "#303e4b66"
                    ctx.lineWidth = 1
                    ctx.beginPath()
                    ctx.moveTo(w + r, 0.5)
                    ctx.arcTo(w - 0.5, 0.5, w - 0.5, r, r)
                    railControls.appendOutline(ctx, w - 0.5)
                    ctx.lineTo(w - 0.5, bottom - r - 0.5)
                    ctx.arcTo(w - 0.5, bottom - 0.5,
                        w + r, bottom - 0.5, r)
                    ctx.lineTo(width, bottom - 0.5)
                    ctx.stroke()
                    ctx.restore()
                }

                function paintInlineNotificationToast(ctx) {
                    if (!inlineNotificationToastStage.visible || !root.notificationToastMounted || inlineNotificationToastStage.width <= 0 || inlineNotificationToastStage.height <= 0 || inlineNotificationToastStage.opacity <= 0.01)
                        return

                    const tx = Math.round(inlineNotificationToastStage.x)
                    const ty = Math.round(inlineNotificationToastStage.y)
                    const tw = Math.round(inlineNotificationToastStage.width)
                    const th = Math.round(inlineNotificationToastStage.height)
                    const attachY = Math.max(ty, root.desktopFrameY(height))
                    const bottomY = ty + th
                    const bodyHeight = Math.max(0, bottomY - attachY)
                    const radius = Math.min(inlineNotificationToastStage.bubbleRadius, Math.max(0, tw / 2), Math.max(0, bodyHeight / 2))

                    if (bodyHeight <= 0)
                        return

                    ctx.save()
                    ctx.globalAlpha = root.frameVisualsReveal * inlineNotificationToastStage.opacity
                    ctx.fillStyle = root.composition
                        ? root.composition.unifiedBarSurface
                        : root.desktopFrameMatteColor()
                    ctx.beginPath()
                    ctx.moveTo(tx, attachY)
                    ctx.lineTo(tx + tw, attachY)
                    ctx.lineTo(tx + tw, bottomY - radius)
                    ctx.arcTo(tx + tw, bottomY, tx + tw - radius, bottomY, radius)
                    ctx.lineTo(tx + radius, bottomY)
                    ctx.arcTo(tx, bottomY, tx, bottomY - radius, radius)
                    ctx.lineTo(tx, attachY)
                    ctx.closePath()
                    ctx.fill()

                    ctx.strokeStyle = root.desktopFrameBorderColor()
                    ctx.lineWidth = 1
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    ctx.beginPath()
                    ctx.moveTo(tx + tw - 0.5, attachY + 0.5)
                    ctx.lineTo(tx + tw - 0.5, bottomY - radius)
                    ctx.arcTo(tx + tw - 0.5, bottomY - 0.5, tx + tw - radius, bottomY - 0.5, radius)
                    ctx.lineTo(tx + radius, bottomY - 0.5)
                    ctx.arcTo(tx + 0.5, bottomY - 0.5, tx + 0.5, bottomY - radius, radius)
                    ctx.lineTo(tx + 0.5, attachY + 0.5)
                    ctx.stroke()
                    ctx.restore()
                }

                function paintWeatherTopSurface(ctx) {
                    if (panel.weatherTopSearchMode) return
                    if (root.topBarLayout)
                        return
                    if (!root.weatherTopWindowOpen && inlineWeatherTopFrame.opacity <= 0.001)
                        return
                    if (inlineWeatherTopFrame.width <= 0 || inlineWeatherTopFrame.height <= 0 || inlineWeatherTopFrame.opacity <= 0.001)
                        return

                    const gx = Math.round(inlineWeatherTopFrame.x)
                    const gw = Math.round(inlineWeatherTopFrame.width)
                    const gy = Math.round(inlineWeatherTopFrame.surfaceY)
                    const gh = Math.round(inlineWeatherTopFrame.surfaceHeight)
                    const radius = Math.min(panel.weatherTopCornerRadius, Math.max(0, gw / 2), Math.max(0, gh / 2))
                    if (gh <= 0)
                        return

                    ctx.save()
                    ctx.globalAlpha = root.frameVisualsReveal * inlineWeatherTopFrame.opacity
                    ctx.fillStyle = root.composition
                        ? root.composition.unifiedBarSurface
                        : root.desktopFrameMatteColor()
                    ctx.beginPath()
                    ctx.moveTo(gx, gy)
                    ctx.lineTo(gx + gw, gy)
                    ctx.lineTo(gx + gw, gy + gh - radius)
                    ctx.arcTo(gx + gw, gy + gh, gx + gw - radius, gy + gh, radius)
                    ctx.lineTo(gx + radius, gy + gh)
                    ctx.arcTo(gx, gy + gh, gx, gy + gh - radius, radius)
                    ctx.lineTo(gx, gy)
                    ctx.closePath()
                    ctx.fill()

                    ctx.strokeStyle = root.desktopFrameBorderColor()
                    ctx.lineWidth = 1
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    ctx.beginPath()
                    ctx.moveTo(gx + gw - 0.5, gy + 0.5)
                    ctx.lineTo(gx + gw - 0.5, gy + gh - radius)
                    ctx.arcTo(gx + gw - 0.5, gy + gh - 0.5, gx + gw - radius, gy + gh - 0.5, radius)
                    ctx.lineTo(gx + radius, gy + gh - 0.5)
                    ctx.arcTo(gx + 0.5, gy + gh - 0.5, gx + 0.5, gy + gh - radius, radius)
                    ctx.lineTo(gx + 0.5, gy + 0.5)
                    ctx.stroke()
                    ctx.restore()
                }

                function attachedSidePath(ctx, x, y, w, h, radius, side) {
                    const r = Math.min(radius, Math.max(0, w / 2), Math.max(0, h / 2))
                    const x2 = x + w
                    const y2 = y + h

                    ctx.beginPath()
                    if (side === "right") {
                        ctx.moveTo(x + r, y)
                        ctx.lineTo(x2, y)
                        ctx.lineTo(x2, y2)
                        ctx.lineTo(x + r, y2)
                        ctx.arcTo(x, y2, x, y2 - r, r)
                        ctx.lineTo(x, y + r)
                        ctx.arcTo(x, y, x + r, y, r)
                    } else {
                        ctx.moveTo(x, y)
                        ctx.lineTo(x2 - r, y)
                        ctx.arcTo(x2, y, x2, y + r, r)
                        ctx.lineTo(x2, y2 - r)
                        ctx.arcTo(x2, y2, x2 - r, y2, r)
                        ctx.lineTo(x, y2)
                        ctx.lineTo(x, y)
                    }
                    ctx.closePath()
                }

                function strokeAttachedSide(ctx, x, y, w, h, radius, side) {
                    const r = Math.min(radius, Math.max(0, w / 2), Math.max(0, h / 2))
                    const x2 = x + w
                    const y2 = y + h

                    ctx.beginPath()
                    if (side === "right") {
                        ctx.moveTo(x + r, y + 0.5)
                        ctx.arcTo(x + 0.5, y + 0.5, x + 0.5, y + r, r)
                        ctx.lineTo(x + 0.5, y2 - r)
                        ctx.arcTo(x + 0.5, y2 - 0.5, x + r, y2 - 0.5, r)
                        ctx.lineTo(x2, y2 - 0.5)
                    } else {
                        ctx.moveTo(x, y + 0.5)
                        ctx.lineTo(x2 - r, y + 0.5)
                        ctx.arcTo(x2 - 0.5, y + 0.5, x2 - 0.5, y + r, r)
                        ctx.lineTo(x2 - 0.5, y2 - r)
                        ctx.arcTo(x2 - 0.5, y2 - 0.5, x2 - r, y2 - 0.5, r)
                        ctx.lineTo(x, y2 - 0.5)
                    }
                    ctx.stroke()
                }

                function paintFrameAttachedSurface(ctx, x, y, w, h, radius, side, alpha) {
                    if (w <= 1 || h <= 1 || alpha <= 0.001)
                        return

                    ctx.save()
                    ctx.globalAlpha = root.frameVisualsReveal * alpha
                    ctx.fillStyle = root.desktopFrameMatteColor()
                    attachedSidePath(ctx, x, y, w, h, radius, side)
                    ctx.fill()

                    ctx.strokeStyle = root.desktopFrameBorderColor()
                    ctx.lineWidth = 1
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    strokeAttachedSide(ctx, x, y, w, h, radius, side)
                    ctx.restore()
                }

                function paintSettingsFrameSurface(ctx) {
                    if (!root.settingsPanelPanelVisible || !inlineSettingsLoader.active)
                        return

                    const reveal = Math.max(0, Math.min(1, inlineSettingsLoader.revealProgress))
                    if (reveal <= 0.001)
                        return

                    paintFrameAttachedSurface(
                        ctx,
                        Math.round(inlineSettingsLoader.x),
                        Math.round(inlineSettingsLoader.y),
                        Math.round(inlineSettingsLoader.width),
                        Math.round(inlineSettingsLoader.height),
                        inlineSettingsLoader.cornerRadius,
                        root.popupAttachSide,
                        reveal
                    )
                }

                onPaint: {
                    const ctx = getContext("2d")
                    const fx = root.mainAreaX(width)
                    const fy = root.desktopFrameY(height)
                    const fw = root.mainAreaWidth(width)
                    const fh = root.desktopFrameHeight(height)
                    const radius = Math.min(root.desktopFrameRadius, Math.max(0, fw / 2), Math.max(0, fh / 2))
                    const barSide = root.sideBarLayoutEnabled ? (root.barOnRight ? "right" : "left") : ""

                    ctx.clearRect(0, 0, width, height)
                    if (!root.frameVisualsMounted || fw <= 0 || fh <= 0) {
                        paintSidebarGutterFill(ctx)
                        return
                    }

                    ctx.save()
                    ctx.globalAlpha = root.frameVisualsReveal
                    ctx.fillStyle = root.desktopFrameMatteColor()
                    // The native frame already owns these strips and rounded
                    // corners. Its interior starts at the topbar seam, while
                    // the legacy frame uses desktopFrameMargin; painting both
                    // produces a second, displaced corner on bright wallpaper.
                    if (!root.composition || !root.composition.nativeBarMaterial) {
                        // Split the canvas at the main-area edge.  The frame owns the
                        // content side; paintSidebarGutterFill owns the sidebar side.
                        // Previously these strips crossed behind the translucent bar,
                        // which made the overlap reappear whenever opacity was lowered.
                        const matteLeft = barSide === "left" ? fx : 0
                        const matteRight = barSide === "right" ? fx + fw : width
                        const matteWidth = Math.max(0, matteRight - matteLeft)
                        ctx.fillRect(matteLeft, 0, matteWidth, fy)
                        ctx.fillRect(matteLeft, fy + fh, matteWidth, Math.max(0, height - fy - fh))

                        if (barSide !== "left") {
                            ctx.fillRect(0, fy, fx, fh)
                            paintCorner(ctx, "topLeft", fx, fy, fw, fh, radius)
                            paintCorner(ctx, "bottomLeft", fx, fy, fw, fh, radius)
                        }

                        if (barSide !== "right") {
                            ctx.fillRect(fx + fw, fy, Math.max(0, width - fx - fw), fh)
                            paintCorner(ctx, "topRight", fx, fy, fw, fh, radius)
                            paintCorner(ctx, "bottomRight", fx, fy, fw, fh, radius)
                        }
                        // When the wallpaper strip is open, the visualizer's molded
                        // cap is the bottom corner on the bar side.  Painting another
                        // frame corner here produced the small translucent overlap.

                        paintFrameOutline(ctx, fx, fy, fw, fh, radius)
                    }
                    paintWeatherTopSurface(ctx)
                    paintSettingsFrameSurface(ctx)
                    ctx.restore()

                    paintSidebarGutterFill(ctx)
                    paintSidebarSurface(ctx)
                    paintInlineNotificationToast(ctx)
                }

                Component.onCompleted: if (visible) requestPaint()
                onWidthChanged: if (visible) requestPaint()
                onHeightChanged: if (visible) requestPaint()
                onVisibleChanged: if (visible) requestPaint()
            }

            // Physical screen corner cutouts. They suggest a rounded display
            // without painting black strips along any straight edge.
            Canvas {
                id: bottomScreenCorners
                z: 100
                anchors.fill: parent
                visible: root.sideBarLayoutEnabled
                opacity: 1
                antialiasing: true

                onPaint: {
                    const ctx = getContext("2d")
                    const radius = Math.min(root.screenCornerRadius,
                        width / 2, height)
                    ctx.clearRect(0, 0, width, height)
                    ctx.globalAlpha = 1
                    ctx.fillStyle = "#000000"

                    ctx.beginPath()
                    ctx.moveTo(0, height)
                    ctx.lineTo(0, height - radius)
                    ctx.arc(radius, height - radius, radius,
                        Math.PI, Math.PI / 2, true)
                    ctx.closePath()
                    ctx.fill()

                    ctx.beginPath()
                    ctx.moveTo(width, height)
                    ctx.lineTo(width - radius, height)
                    ctx.arc(width - radius, height - radius, radius,
                        Math.PI / 2, 0, true)
                    ctx.closePath()
                    ctx.fill()
                }
                Component.onCompleted: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onVisibleChanged: if (visible) requestPaint()
            }

            Connections {
                target: veloraTheme
                function onSurfaceBaseChanged() { if (unifiedFrameCanvas.visible) unifiedFrameCanvas.requestPaint() }
                function onSurfaceSidebarChanged() { if (unifiedFrameCanvas.visible) unifiedFrameCanvas.requestPaint() }
                function onSidebarOpacityChanged() { if (unifiedFrameCanvas.visible) unifiedFrameCanvas.requestPaint() }
                function onBarOpacityChanged() { if (unifiedFrameCanvas.visible) unifiedFrameCanvas.requestPaint() }
                function onBarWidthChanged() { if (unifiedFrameCanvas.visible) unifiedFrameCanvas.requestPaint() }
                function onThemeModeChanged() { if (unifiedFrameCanvas.visible) unifiedFrameCanvas.requestPaint() }
                function onThemeIdChanged() { if (unifiedFrameCanvas.visible) unifiedFrameCanvas.requestPaint() }
                function onPopupBorderGlowChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onSidebarBorderGlowChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onBorderSoftChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
            }

            Connections {
                target: root.composition
                function onUnifiedBarSurfaceChanged() {
                    unifiedFrameCanvas.requestPaint()
                }
                function onUnifiedBarBorderChanged() {
                    unifiedFrameCanvas.requestPaint()
                }
                function onUnifiedBarTextPrimaryChanged() {
                    unifiedFrameCanvas.requestPaint()
                }
                function onUnifiedBarAccentChanged() {
                    unifiedFrameCanvas.requestPaint()
                }
                function onBarMaterialChanged() {
                    panel.syncUnifiedBarNativeShape()
                    unifiedFrameCanvas.requestPaint()
                }
                function onOpticsGenerationChanged() {
                    panel.syncUnifiedBarNativeShape()
                    unifiedFrameCanvas.requestPaint()
                }
                function onNativeBarMaterialChanged() {
                    panel.syncUnifiedBarNativeShape()
                    unifiedFrameCanvas.requestPaint()
                }
                function onBarWaveStrengthChanged() {
                    unifiedFrameCanvas.requestPaint()
                }
            }

            Connections {
                target: root
                function onSettingsPanelOpenChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onSettingsPanelWindowOpenChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onNotificationToastMountedChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onNotificationToastVisibleChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onNotificationToastSerialChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
            }

            Connections {
                target: root
                function onBarOnRightChanged() { if (unifiedFrameCanvas.visible) unifiedFrameCanvas.requestPaint() }
                function onSideBarLayoutEnabledChanged() { if (unifiedFrameCanvas.visible) unifiedFrameCanvas.requestPaint() }
                function onUnifiedBarWavePhaseChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onDesktopFrameMarginChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onDesktopFrameRadiusChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onFrameVisualsMountedChanged() { unifiedFrameCanvas.requestPaint() }
                function onFrameVisualsRevealChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onWeatherTopOpenChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onWeatherTopWindowOpenChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onLeftMenuFrameRevealChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onLeftMenuHandleSurfaceRevealChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onQuickPopupJoinedToBarChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onTopWallpaperFrameRevealChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
            }

            Rectangle {
                id: inlineTopSearchBackdrop

                anchors.fill: parent
                visible: !root.topBarLayout && root.weatherTopWindowOpen && panel.weatherTopSearchMode
                color: "#28000000"
                opacity: !root.topBarLayout && root.weatherTopOpen && panel.weatherTopSearchMode ? 1 : 0
                z: 24

                Behavior on opacity {
                    enabled: true
                    NumberAnimation {
                        duration: root.weatherTopOpen ? 420 : 240
                        easing.type: root.weatherTopOpen && panel.weatherTopSearchMode ? Easing.InOutSine : veloraTheme.motionEaseExit
                    }
                }
            }

            Item {
                id: inlineWeatherTopTriggerMask

                x: Math.round(root.mainAreaX(panel.panelWidth))
                y: 0
                width: root.topBarLayout ? 0 : Math.round(root.mainAreaWidth(panel.panelWidth))
                height: root.topBarLayout ? 0 : (root.weatherTopWindowOpen ? Math.max(12, panel.weatherTopOpenY + 2) : Math.max(12, root.desktopFrameMargin + 2))
                z: 35

                MouseArea {
                    anchors.fill: parent
                    enabled: !root.topBarLayout
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    onEntered: {
                        root.weatherTopTriggerHovering = true
                        root.openWeatherTopFromMouse()
                    }
                    onExited: {
                        root.weatherTopTriggerHovering = false
                        root.scheduleWeatherTopHoverClose()
                    }
                }
            }

            Item {
                id: inlineTopSearchOutsideInputMask

                width: !root.topBarLayout && root.weatherTopOpen && panel.weatherTopSearchMode ? parent.width : 0
                height: !root.topBarLayout && root.weatherTopOpen && panel.weatherTopSearchMode ? parent.height : 0
                z: 25

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: root.closeWeatherTop()
                }
            }

            Item {
                id: inlineWeatherTopFrame

                readonly property bool mounted: !root.topBarLayout && root.weatherTopWindowOpen
                readonly property int surfaceY: root.weatherTopWindowOpen && y >= root.desktopFrameMargin
                    ? root.desktopFrameMargin
                    : Math.round(y)
                readonly property int surfaceHeight: Math.max(0, Math.round(y + height - surfaceY))

                property real searchReveal: root.weatherTopOpen ? 1 : 0
                Behavior on searchReveal {
                    NumberAnimation { duration: root.weatherTopOpen ? 480 : 280; easing.type: root.weatherTopOpen ? Easing.OutExpo : Easing.InOutCubic }
                }
                width: panel.weatherTopSearchMode ? 440 + (panel.weatherTopTargetWidth - 440) * searchReveal : panel.weatherTopTargetWidth
                height: panel.weatherTopSearchMode ? 56 + (panel.weatherTopTargetHeight - 56) * searchReveal : panel.weatherTopTargetHeight
                x: Math.round((panel.panelWidth - width) / 2)
                y: panel.weatherTopSearchMode ? -80 + (panel.weatherTopOpenY + 80) * searchReveal : panel.weatherTopTargetY
                opacity: 1
                visible: mounted
                z: 26

                Rectangle {
                    anchors.fill: parent
                    visible: panel.weatherTopSearchMode
                    radius: 24
                    color: root.composition ? root.composition.topbarTheme.wallpaperSurfaceTone : veloraTheme.surfaceBase
                    opacity: inlineWeatherTopFrame.searchReveal
                    border.width: 1
                    border.color: root.composition ? root.composition.topbarTheme.borderStrong : veloraTheme.borderSoft
                }

                onXChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                onYChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                onWidthChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                onHeightChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                onSurfaceYChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                onSurfaceHeightChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                Behavior on y {
                    enabled: !panel.weatherTopSearchMode && veloraTheme.motionEnabled
                    NumberAnimation {
                        duration: root.weatherTopOpen ? veloraTheme.motionPanelIn : root.quickPopupLineCloseDuration
                        easing.type: root.weatherTopOpen ? Easing.BezierSpline : Easing.InOutCubic
                        easing.bezierCurve: root.weatherTopOpen ? veloraTheme.motionCurveEmphasizedAccel : veloraTheme.motionCurveStandard
                    }
                }

                Behavior on height {
                    enabled: !panel.weatherTopSearchMode && veloraTheme.motionEnabled
                    NumberAnimation {
                        duration: veloraTheme.motionPanelGeometry
                        easing.type: veloraTheme.motionEaseEnter
                    }
                }
            }

            Item {
                id: inlineWeatherTopInputMask

                x: inlineWeatherTopFrame.x
                y: inlineWeatherTopFrame.surfaceY
                width: !root.topBarLayout && root.weatherTopWindowOpen ? inlineWeatherTopFrame.width : 0
                height: !root.topBarLayout && root.weatherTopWindowOpen ? inlineWeatherTopFrame.surfaceHeight : 0
                z: 27
            }

            Loader {
                id: inlineWeatherTopPanel

                x: inlineWeatherTopFrame.x
                y: inlineWeatherTopFrame.y
                width: inlineWeatherTopFrame.width
                height: inlineWeatherTopFrame.height
                active: !root.topBarLayout && root.weatherTopWindowOpen
                visible: active
                clip: panel.weatherTopSearchMode
                opacity: inlineWeatherTopFrame.opacity
                z: 32

                sourceComponent: panel.weatherTopSearchMode ? inlineTopSearchComponent : inlineTopWeatherComponent

                onLoaded: {
                    if (panel.weatherTopSearchMode && item && item.requestSearchFocus)
                        item.requestSearchFocus()
                }
            }

            Component {
                id: inlineTopWeatherComponent

                VeloraWeatherTopPanel {
                    theme: veloraTheme
                    weather: root.composition ? root.composition.forecastService : null
                    open: root.weatherTopOpen
                    embeddedInFrame: true
                    onActivated: root.engageWeatherTop()
                    onCloseRequested: root.closeWeatherTop()
                    onPointerInsideChanged: function(inside) {
                        root.setWeatherTopPanelHovering(inside)
                    }
                }
            }

            Component {
                id: inlineTopSearchComponent

                VeloraSearchPanel {
                    theme: root.composition ? root.composition.topbarTheme : null
                    open: root.weatherTopOpen
                    onCloseRequested: root.closeWeatherTop()
                    onSettingsRequested: root.openUnifiedSettings()
                    onPointerInsideChanged: inside => root.setWeatherTopPanelHovering(inside)
                }
            }

            Item {
                id: screenVisualizerFrame

                readonly property int frameX: Math.round(root.mainAreaX(parent.width))
                readonly property int frameY: Math.round(root.desktopFrameY(parent.height))
                readonly property int frameWidth: Math.round(root.mainAreaWidth(parent.width))
                readonly property int frameHeight: Math.round(root.desktopFrameHeight(parent.height))
                readonly property int band: Math.max(18, Math.min(64, Math.round(16 + veloraTheme.visualizerStrength * 70)))
                readonly property bool activeForPaint: root.screenVisualizerReveal > 0.001 && visible && panel.visible && frameWidth > 0 && frameHeight > 0

                anchors.fill: parent
                visible: root.screenVisualizerReveal > 0.001
                opacity: root.screenVisualizerReveal
                z: 1

                function requestFramePaint(force) {
                    if (!activeForPaint) {
                        screenVisualizerPaintTimer.stop()
                        if (force)
                            screenVisualizerCanvas.requestPaint()
                        return
                    }

                    if (force) {
                        screenVisualizerPaintTimer.stop()
                        screenVisualizerCanvas.requestPaint()
                        return
                    }

                    if (!screenVisualizerPaintTimer.running)
                        screenVisualizerPaintTimer.restart()
                }

                onActiveForPaintChanged: requestFramePaint(true)
                onFrameXChanged: requestFramePaint(true)
                onFrameYChanged: requestFramePaint(true)
                onFrameWidthChanged: requestFramePaint(true)
                onFrameHeightChanged: requestFramePaint(true)
                onBandChanged: requestFramePaint(true)

                Canvas {
                    id: screenVisualizerCanvas

                    readonly property int sampleCount: Math.max(96, Math.min(260, Math.round((width + height) / 12)))
                    readonly property real perimeter: Math.max(1, width * 2 + height * 2)
                    readonly property bool pixelMode: veloraTheme.visualizerMode === "pixels"

                    x: screenVisualizerFrame.frameX
                    y: screenVisualizerFrame.frameY
                    width: screenVisualizerFrame.frameWidth
                    height: screenVisualizerFrame.frameHeight
                    visible: screenVisualizerFrame.visible && width > 0 && height > 0
                    antialiasing: true

                    function rgbaCss(colorValue, opacityValue) {
                        const alphaValue = Math.max(0, Math.min(1, opacityValue))
                        return "rgba(" + Math.round(colorValue.r * 255) + "," + Math.round(colorValue.g * 255) + "," + Math.round(colorValue.b * 255) + "," + alphaValue.toFixed(3) + ")"
                    }

                    function accentColor() {
                        if (veloraTheme.themeId === "pywal16")
                            return veloraTheme.sidebarBorderGlow
                        return veloraTheme.accentPrimary
                    }

                    function rawVisualizerValue(index) {
                        if (!barRoot.cavaValues || barRoot.cavaValues.length <= 0)
                            return 0

                        const value = Number(barRoot.cavaValues[Math.max(0, Math.min(index, barRoot.cavaValues.length - 1))])
                        return Math.max(0, Math.min(1, isNaN(value) ? 0 : value))
                    }

                    function interpolatedVisualizerValue(unit) {
                        const count = Math.max(2, barRoot.cavaBandCount || 28)
                        const normalized = ((unit % 1) + 1) % 1
                        const scaled = normalized * count
                        const left = Math.floor(scaled) % count
                        const right = (left + 1) % count
                        const mix = scaled - left
                        return rawVisualizerValue(left) * (1 - mix) + rawVisualizerValue(right) * mix
                    }

                    function sampleValue(unit) {
                        return interpolatedVisualizerValue(unit)
                    }

                    function sideForDistance(distance) {
                        const w = Math.max(1, width)
                        const h = Math.max(1, height)
                        const d = ((distance % perimeter) + perimeter) % perimeter

                        if (d <= w)
                            return "top"
                        if (d <= w + h)
                            return "right"
                        if (d <= w * 2 + h)
                            return "bottom"
                        return "left"
                    }

                    function sideStrength(side) {
                        if (side === "left")
                            return 1.0
                        if (side === "right")
                            return 0.18
                        return 0.14
                    }

                    function amplitudeFor(unit, sample, side) {
                        const value = sampleValue(unit)
                        const strength = sideStrength(side)
                        const base = side === "left"
                            ? Math.max(5, Math.min(12, screenVisualizerFrame.band * 0.15))
                            : Math.max(2, Math.min(5, screenVisualizerFrame.band * 0.075))
                        const maxAmp = Math.max(base + 1, screenVisualizerFrame.band * Math.min(0.86, 0.30 + veloraTheme.visualizerStrength * 0.62) * strength)
                        const pulse = 0.90 + Math.sin(sample * 0.61) * 0.07
                        return Math.max(3, Math.min(screenVisualizerFrame.band - 1, base + Math.pow(value, 0.76) * maxAmp * pulse))
                    }

                    function pointAtUnit(unit, sample) {
                        const distance = ((unit % 1) + 1) % 1 * perimeter
                        const side = sideForDistance(distance)
                        const amp = amplitudeFor(unit, sample, side)
                        const w = Math.max(1, width)
                        const h = Math.max(1, height)

                        if (distance <= w)
                            return { x: distance, y: amp, side: side }

                        if (distance <= w + h)
                            return { x: w - amp, y: distance - w, side: side }

                        if (distance <= w * 2 + h)
                            return { x: w - (distance - w - h), y: h - amp, side: side }

                        return { x: amp, y: h - (distance - w * 2 - h), side: side }
                    }

                    function pixelPointAtDistance(distance, inward, cell) {
                        const w = Math.max(1, width)
                        const h = Math.max(1, height)
                        const d = ((distance % perimeter) + perimeter) % perimeter

                        if (d <= w)
                            return { x: Math.min(w - cell, Math.max(0, d - cell / 2)), y: inward, side: "top" }

                        if (d <= w + h)
                            return { x: w - cell - inward, y: Math.min(h - cell, Math.max(0, d - w - cell / 2)), side: "right" }

                        if (d <= w * 2 + h)
                            return { x: Math.min(w - cell, Math.max(0, w - (d - w - h) - cell / 2)), y: h - cell - inward, side: "bottom" }

                        return { x: inward, y: Math.min(h - cell, Math.max(0, h - (d - w * 2 - h) - cell / 2)), side: "left" }
                    }

                    function traceClosedPath(ctx, points) {
                        if (points.length <= 0)
                            return

                        ctx.moveTo(points[0].x, points[0].y)
                        for (var i = 1; i <= points.length; i += 1) {
                            const previous = points[(i - 1) % points.length]
                            const current = points[i % points.length]
                            const midX = (previous.x + current.x) / 2
                            const midY = (previous.y + current.y) / 2
                            ctx.quadraticCurveTo(previous.x, previous.y, midX, midY)
                        }
                    }

                    function paintWaveFrame(ctx, points, peak) {
                        const materialAlpha = Math.max(0.035, Math.min(0.08, root.sidebarPanelGlassAlpha() * 0.08))
                        const accentAlpha = Math.min(0.13, 0.035 + peak * 0.12)
                        const accent = accentColor()
                        var fill = rgbaCss(veloraTheme.surfaceSidebar, materialAlpha)

                        if (veloraTheme.visualizerGradientEnabled) {
                            fill = ctx.createLinearGradient(0, 0, width, height)
                            fill.addColorStop(0.0, rgbaCss(veloraTheme.surfaceSidebar, materialAlpha))
                            fill.addColorStop(0.46, rgbaCss(accent, accentAlpha))
                            fill.addColorStop(1.0, rgbaCss(veloraTheme.surfaceSidebar, materialAlpha))
                        }

                        ctx.save()
                        ctx.fillStyle = fill
                        ctx.beginPath()
                        ctx.moveTo(0, 0)
                        ctx.lineTo(width, 0)
                        ctx.lineTo(width, height)
                        ctx.lineTo(0, height)
                        ctx.closePath()
                        ctx.moveTo(points[points.length - 1].x, points[points.length - 1].y)
                        for (var i = points.length - 2; i >= 0; i -= 1)
                            ctx.lineTo(points[i].x, points[i].y)
                        ctx.closePath()
                        ctx.fill()

                        ctx.lineCap = "round"
                        ctx.lineJoin = "round"

                        for (var i = 0; i < points.length; i += 1) {
                            const current = points[i]
                            const next = points[(i + 1) % points.length]
                            const segmentStrength = Math.min(sideStrength(current.side), sideStrength(next.side))
                            const segmentAlpha = Math.min(0.62, (0.16 + peak * 0.46) * (0.30 + segmentStrength * 0.70))
                            ctx.strokeStyle = rgbaCss(accent, segmentAlpha)
                            ctx.lineWidth = current.side === "left" || next.side === "left" ? 1.15 : 0.65
                            ctx.beginPath()
                            ctx.moveTo(current.x, current.y)
                            ctx.quadraticCurveTo(current.x, current.y, next.x, next.y)
                            ctx.stroke()
                        }

                        ctx.restore()
                    }

                    function paintPixelFrame(ctx, peak) {
                        const cell = Math.max(3, Math.min(12, Math.round(veloraTheme.visualizerPixelSize)))
                        const gap = Math.max(1, Math.round(cell * 0.30))
                        const slots = Math.max(24, Math.floor((perimeter + gap) / (cell + gap)))
                        const steps = Math.max(1, Math.floor((screenVisualizerFrame.band + gap) / (cell + gap)))
                        const accent = accentColor()

                        ctx.save()
                        for (var slot = 0; slot < slots; slot += 1) {
                            const unit = slot / Math.max(1, slots)
                            const value = sampleValue(unit)
                            const side = sideForDistance(unit * perimeter)
                            const sideScale = sideStrength(side)
                            const activeSteps = peak >= 0.025
                                ? Math.min(steps, Math.max(1, Math.ceil(Math.pow(value, 0.72) * steps * Math.max(0.16, veloraTheme.visualizerStrength) * sideScale)))
                                : 0
                            const distance = unit * perimeter

                            for (var step = 0; step < activeSteps; step += 1) {
                                const alphaValue = Math.min(0.56, 0.16 + value * 0.42) * (0.35 + sideScale * 0.65) * (1 - step / Math.max(1, steps) * 0.30)
                                const point = pixelPointAtDistance(distance, step * (cell + gap), cell)

                                ctx.fillStyle = rgbaCss(accent, alphaValue)
                                ctx.fillRect(Math.round(point.x), Math.round(point.y), cell, cell)
                            }
                        }
                        ctx.restore()
                    }

                    onPaint: {
                        const ctx = getContext("2d")
                        const points = []
                        var peak = 0

                        ctx.clearRect(0, 0, width, height)
                        if (!screenVisualizerFrame.activeForPaint || width <= 0 || height <= 0)
                            return

                        for (var i = 0; i < sampleCount; i += 1) {
                            const unit = i / Math.max(1, sampleCount)
                            peak = Math.max(peak, sampleValue(unit))
                            points.push(pointAtUnit(unit, i))
                        }

                        if (pixelMode) {
                            paintPixelFrame(ctx, peak)
                            return
                        }

                        paintWaveFrame(ctx, points, peak)
                    }

                    Component.onCompleted: screenVisualizerFrame.requestFramePaint(true)
                    onWidthChanged: screenVisualizerFrame.requestFramePaint(true)
                    onHeightChanged: screenVisualizerFrame.requestFramePaint(true)
                    onVisibleChanged: if (visible) screenVisualizerFrame.requestFramePaint(true)
                }

                Timer {
                    id: screenVisualizerPaintTimer

                    interval: 16
                    repeat: false
                    onTriggered: {
                        if (screenVisualizerFrame.activeForPaint)
                            screenVisualizerCanvas.requestPaint()
                    }
                }

                Connections {
                    target: barRoot
                    function onCavaValuesChanged() {
                        if (root.screenVisualizerReveal > 0.001)
                            screenVisualizerFrame.requestFramePaint(false)
                    }
                }

                Connections {
                    target: veloraTheme
                    function onActiveTextChanged() { screenVisualizerFrame.requestFramePaint(true) }
                    function onThemeModeChanged() { screenVisualizerFrame.requestFramePaint(true) }
                    function onThemeIdChanged() { screenVisualizerFrame.requestFramePaint(true) }
                    function onVisualizerStrengthChanged() { screenVisualizerFrame.requestFramePaint(true) }
                    function onVisualizerModeChanged() { screenVisualizerFrame.requestFramePaint(true) }
                    function onVisualizerPixelSizeChanged() { screenVisualizerFrame.requestFramePaint(true) }
                    function onVisualizerGradientEnabledChanged() { screenVisualizerFrame.requestFramePaint(true) }
                    function onScreenVisualizerEnabledChanged() { screenVisualizerFrame.requestFramePaint(true) }
                    function onSurfaceSidebarChanged() { screenVisualizerFrame.requestFramePaint(true) }
                    function onSidebarBorderGlowChanged() { screenVisualizerFrame.requestFramePaint(true) }
                    function onBorderSoftChanged() { screenVisualizerFrame.requestFramePaint(true) }
                }

                Connections {
                    target: root
                    function onBarOnRightChanged() { screenVisualizerFrame.requestFramePaint(true) }
                    function onDesktopFrameMarginChanged() { screenVisualizerFrame.requestFramePaint(true) }
                    function onScreenVisualizerRevealChanged() { screenVisualizerFrame.requestFramePaint(true) }
                    function onTopWallpaperFrameRevealChanged() { screenVisualizerFrame.requestFramePaint(true) }
                }
            }

            Item {
                id: sideVisualizerRail

                readonly property int frameEdgeX: Math.round(root.barOnRight
                    ? root.mainAreaX(parent.width) + root.mainAreaWidth(parent.width)
                    : root.mainAreaX(parent.width))
                readonly property int barEdgeX: Math.round(root.barOnRight
                    ? root.barX(parent.width)
                    : root.barX(parent.width) + root.sidebarVisualWidth)
                readonly property bool standalone: root.sideVisualizerMounted && !root.frameVisualsMounted
                readonly property int gutterSpan: Math.max(0, root.barOnRight
                    ? barEdgeX - frameEdgeX
                    : frameEdgeX - barEdgeX)
                readonly property int railOverlap: 0
                readonly property int bandCount: barRoot.cavaBandCount || 40
                readonly property int waveWidth: standalone ? Math.max(30, Math.round(root.sideVisualizerWaveWidth * 0.58)) : root.sideVisualizerWaveWidth
                readonly property int railWidth: waveWidth + gutterSpan + railOverlap
                readonly property real waveStrength: veloraTheme.visualizerStrength
                readonly property bool pixelMode: veloraTheme.visualizerMode === "pixels"
                readonly property real centerX: root.barOnRight ? waveWidth - 2 : gutterSpan + railOverlap + 2
                readonly property int waveDirection: root.barOnRight ? -1 : 1
                readonly property real localFrameEdgeX: frameEdgeX - x
                readonly property real localBarEdgeX: barEdgeX - x
                readonly property real bridgeLeftX: Math.max(0, Math.min(localFrameEdgeX, localBarEdgeX) - 1)
                readonly property real bridgeRightX: Math.min(width, Math.max(localFrameEdgeX, localBarEdgeX) + 2)
                readonly property real popupCutLeft: Math.max(0, Math.min(width, inlineQuickPopupSurface.x - x))
                readonly property real popupCutRight: Math.max(0, Math.min(width, inlineQuickPopupSurface.x + inlineQuickPopupSurface.width - x))
                readonly property real popupCutTop: Math.max(0, Math.min(height, inlineQuickPopupSurface.y - y))
                readonly property real popupCutBottom: Math.max(0, Math.min(height, inlineQuickPopupSurface.y + inlineQuickPopupSurface.height - y))
                readonly property bool popupCutActive: root.quickPopupVisible && root.sideQuickPopupPanelVisible && root.quickPopupSurfaceReveal > 0.12 && popupCutBottom > popupCutTop && popupCutRight > popupCutLeft
                readonly property bool activeForPaint: root.sideBarLayoutEnabled && root.sideVisualizerMounted && visible && panel.visible && width > 0 && height > 0

                function requestWaveformPaint(force) {
                    if (!activeForPaint) {
                        waveformPaintTimer.stop()
                        if (force)
                            waveformCanvas.requestPaint()
                        return
                    }

                    if (force) {
                        waveformPaintTimer.stop()
                        waveformCanvas.requestPaint()
                        return
                    }

                    if (!waveformPaintTimer.running)
                        waveformPaintTimer.restart()
                }

                x: standalone
                    ? (root.barOnRight ? barEdgeX - waveWidth : barEdgeX)
                    : (root.barOnRight ? frameEdgeX - waveWidth : barEdgeX)
                y: standalone ? root.sidebarVerticalMargin : root.desktopFrameY(parent.height)
                width: root.sideBarLayoutEnabled && root.sideVisualizerMounted ? railWidth : 0
                height: root.sideBarLayoutEnabled && root.sideVisualizerMounted
                    ? (standalone ? Math.max(0, parent.height - root.sidebarVerticalMargin * 2) : Math.max(0, root.desktopFrameHeight(parent.height)))
                    : 0
                visible: root.sideBarLayoutEnabled && root.sideVisualizerMounted
                opacity: root.sideVisualizerReveal * root.layoutSwitchOpacity
                clip: true
                z: standalone ? 11 : 1

                onActiveForPaintChanged: {
                    if (activeForPaint)
                        requestWaveformPaint(true)
                    else {
                        waveformPaintTimer.stop()
                        waveformCanvas.requestPaint()
                    }
                }
                onCenterXChanged: requestWaveformPaint(true)
                onWaveDirectionChanged: requestWaveformPaint(true)
                onStandaloneChanged: requestWaveformPaint(true)
                onLocalFrameEdgeXChanged: requestWaveformPaint(true)
                onLocalBarEdgeXChanged: requestWaveformPaint(true)

                Canvas {
                    id: waveformCanvas

                    anchors.fill: parent
                    antialiasing: true

                    function rawVisualizerValue(index) {
                        if (!barRoot.cavaValues || barRoot.cavaValues.length <= 0)
                            return 0

                        const value = Number(barRoot.cavaValues[Math.max(0, Math.min(index, barRoot.cavaValues.length - 1))])
                        return Math.max(0, Math.min(1, isNaN(value) ? 0 : value))
                    }

                    function pointAt(index) {
                        const count = Math.max(2, sideVisualizerRail.bandCount)
                        const top = 1
                        const bottom = Math.max(top + 1, height - 1)
                        const step = (bottom - top) / (count - 1)
                        const lifted = rawVisualizerValue(index)
                        const standaloneScale = sideVisualizerRail.standalone ? 0.52 : 1
                        const maxAmp = Math.max(sideVisualizerRail.standalone ? 10 : 16, sideVisualizerRail.waveWidth * sideVisualizerRail.waveStrength * standaloneScale)
                        const edgeFade = Math.min(1, index / 5, (count - 1 - index) / 5)
                        const amp = Math.min(maxAmp, Math.pow(lifted, 0.82) * maxAmp) * edgeFade
                        const pulse = 0.78 + Math.abs(Math.sin(index * 0.70)) * 0.22

                        return {
                            x: sideVisualizerRail.centerX + sideVisualizerRail.waveDirection * amp * pulse,
                            y: top + step * index
                        }
                    }

                    function moldedEdgeX() {
                        if (sideVisualizerRail.standalone)
                            return sideVisualizerRail.localBarEdgeX
                        return root.barOnRight ? width : 0
                    }

                    function continueSmoothLine(ctx, points) {
                        continueSmoothLineRange(ctx, points, 0, points.length - 1)
                    }

                    function continueSmoothLineRange(ctx, points, startIndex, endIndex) {
                        const start = Math.max(0, Math.min(points.length - 1, startIndex))
                        const end = Math.max(start, Math.min(points.length - 1, endIndex))

                        for (let i = start + 1; i <= end; i += 1) {
                            const previous = points[i - 1]
                            const current = points[i]
                            const midX = (previous.x + current.x) / 2
                            const midY = (previous.y + current.y) / 2
                            ctx.quadraticCurveTo(previous.x, previous.y, midX, midY)
                        }

                        const last = points[end]
                        ctx.lineTo(last.x, last.y)
                    }

                    function smoothLine(ctx, points) {
                        if (points.length <= 0)
                            return

                        ctx.moveTo(points[0].x, points[0].y)
                        continueSmoothLine(ctx, points)
                    }

                    function moldedFramePath(ctx, points) {
                        if (points.length <= 0)
                            return

                        const geometry = moldedCapGeometry(points)
                        ctx.moveTo(geometry.capX, 0)
                        ctx.bezierCurveTo(geometry.controlX, 0, geometry.topJoin.x, geometry.topCurveY, geometry.topJoin.x, geometry.topJoin.y)
                        continueSmoothLineRange(ctx, points, geometry.topIndex, geometry.bottomIndex)
                        ctx.bezierCurveTo(geometry.bottomJoin.x, geometry.bottomCurveY, geometry.controlX, height, geometry.capX, height)
                    }

                    function moldedGlassPath(ctx, points) {
                        if (points.length <= 0)
                            return

                        const edgeX = moldedEdgeX()
                        const geometry = moldedCapGeometry(points)

                        ctx.moveTo(geometry.capX, 0)
                        ctx.bezierCurveTo(geometry.controlX, 0, geometry.topJoin.x, geometry.topCurveY, geometry.topJoin.x, geometry.topJoin.y)
                        continueSmoothLineRange(ctx, points, geometry.topIndex, geometry.bottomIndex)
                        ctx.bezierCurveTo(geometry.bottomJoin.x, geometry.bottomCurveY, geometry.controlX, height, geometry.capX, height)

                        if (sideVisualizerRail.standalone) {
                            const side = root.barOnRight ? -1 : 1
                            const innerRadius = Math.min(root.sidebarCornerRadius, height / 2, Math.max(4, sideVisualizerRail.railOverlap))
                            const shoulderX = edgeX + side * innerRadius
                            ctx.lineTo(shoulderX, height)
                            ctx.quadraticCurveTo(edgeX, height, edgeX, height - innerRadius)
                            ctx.lineTo(edgeX, innerRadius)
                            ctx.quadraticCurveTo(edgeX, 0, shoulderX, 0)
                            ctx.lineTo(geometry.capX, 0)
                        } else {
                            ctx.lineTo(edgeX, height)
                            ctx.lineTo(edgeX, 0)
                        }
                        ctx.closePath()
                    }

                    function moldedCapGeometry(points) {
                        const edgeX = moldedEdgeX()
                        const side = root.barOnRight ? -1 : 1
                        const capReach = sideVisualizerRail.standalone ? Math.min(16, width * 0.40) : root.sideVisualizerCapReach
                        const capControl = capReach * 0.52
                        const topIndex = Math.min(points.length - 1, Math.max(2, Math.round(points.length * 0.055)))
                        const bottomIndex = Math.max(topIndex, points.length - 1 - topIndex)
                        const topJoin = points[topIndex]
                        const bottomJoin = points[bottomIndex]
                        const capX = Math.max(0, Math.min(width, edgeX + side * capReach))
                        const controlX = Math.max(0, Math.min(width, edgeX + side * capControl))
                        const topCurveY = Math.max(6, topJoin.y * 0.34)
                        const bottomCurveY = Math.min(height - 6, height - (height - bottomJoin.y) * 0.34)

                        return {
                            topIndex: topIndex,
                            bottomIndex: bottomIndex,
                            topJoin: topJoin,
                            bottomJoin: bottomJoin,
                            capX: capX,
                            controlX: controlX,
                            topCurveY: topCurveY,
                            bottomCurveY: bottomCurveY
                        }
                    }

                    function interpolatedVisualizerValue(row, rows) {
                        const count = Math.max(2, sideVisualizerRail.bandCount)
                        const scaled = row / Math.max(1, rows - 1) * (count - 1)
                        const left = Math.max(0, Math.min(count - 1, Math.floor(scaled)))
                        const right = Math.max(left, Math.min(count - 1, Math.ceil(scaled)))
                        const mix = scaled - left
                        return rawVisualizerValue(left) * (1 - mix) + rawVisualizerValue(right) * mix
                    }

                    function drawPixelVisualizer(ctx, peak) {
                        const edgeX = moldedEdgeX()
                        const side = root.barOnRight ? -1 : 1
                        const cell = Math.max(3, Math.min(12, Math.round(veloraTheme.visualizerPixelSize)))
                        const gap = Math.max(1, Math.round(cell * 0.30))
                        const maxColumns = Math.max(2, Math.floor(Math.max(14, sideVisualizerRail.waveWidth - 6) / (cell + gap)))
                        const usedWidth = maxColumns * cell + Math.max(0, maxColumns - 1) * gap
                        const availableHeight = Math.max(cell, height - 2)
                        const rows = Math.max(1, Math.floor((availableHeight + gap) / (cell + gap)))
                        const usedHeight = rows * cell + Math.max(0, rows - 1) * gap
                        const y0 = 1
                        const x0 = side > 0 ? edgeX : edgeX - usedWidth
                        const activeBase = veloraTheme.themeId === "pywal16" ? veloraTheme.sidebarBorderGlow : veloraTheme.activeText

                        for (let row = 0; row < rows; row += 1) {
                            const value = interpolatedVisualizerValue(row, rows)
                            const activeColumns = peak >= 0.025
                                ? Math.min(maxColumns, Math.max(1, Math.ceil(Math.pow(value, 0.72) * maxColumns * Math.max(0.25, sideVisualizerRail.waveStrength))))
                                : 0
                            const y = y0 + row * (cell + gap)

                            for (let col = 0; col < maxColumns; col += 1) {
                                const x = side > 0
                                    ? x0 + col * (cell + gap)
                                    : x0 + usedWidth - cell - col * (cell + gap)
                                if (col >= activeColumns)
                                    continue

                                const columnFade = 1 - col / Math.max(1, maxColumns) * 0.36
                                const alpha = Math.min(0.62, 0.18 + value * 0.50) * columnFade
                                ctx.fillStyle = veloraTheme.alpha(activeBase, alpha)
                                ctx.fillRect(Math.round(x), Math.round(y), cell, cell)
                            }
                        }
                    }

                    function popupCutTopPx() {
                        return Math.max(0, Math.min(height, Math.floor(sideVisualizerRail.popupCutTop) - 1))
                    }

                    function popupCutBottomPx() {
                        return Math.max(0, Math.min(height, Math.ceil(sideVisualizerRail.popupCutBottom) + 1))
                    }

                    function popupCutLeftPx() {
                        return Math.max(0, Math.min(width, Math.floor(sideVisualizerRail.popupCutLeft) - 1))
                    }

                    function popupCutRightPx() {
                        return Math.max(0, Math.min(width, Math.ceil(sideVisualizerRail.popupCutRight) + 1))
                    }

                    function popupCutCoversCanvas() {
                        return sideVisualizerRail.popupCutActive
                            && popupCutLeftPx() <= 0
                            && popupCutRightPx() >= width
                            && popupCutTopPx() <= 0
                            && popupCutBottomPx() >= height
                    }

                    function clearPopupCut(ctx) {
                        if (!sideVisualizerRail.popupCutActive)
                            return

                        const top = popupCutTopPx()
                        const bottom = popupCutBottomPx()
                        const left = 0
                        const right = width
                        if (bottom <= top || right <= left)
                            return

                        if (!veloraTheme.visualizerGradientEnabled) {
                            ctx.clearRect(left, top, right - left, bottom - top)
                            return
                        }

                        const cutWidth = right - left
                        const fade = Math.max(42, Math.min(112, Math.round(height * 0.12)))

                        ctx.save()
                        ctx.globalCompositeOperation = "destination-out"
                        ctx.fillStyle = "rgba(0,0,0,1)"
                        ctx.fillRect(left, top, cutWidth, bottom - top)

                        if (top > 0) {
                            const fadeTop = Math.max(0, top - fade)
                            const topGradient = ctx.createLinearGradient(0, fadeTop, 0, top)
                            topGradient.addColorStop(0.0, "rgba(0,0,0,0)")
                            topGradient.addColorStop(1.0, "rgba(0,0,0,1)")
                            ctx.fillStyle = topGradient
                            ctx.fillRect(left, fadeTop, cutWidth, top - fadeTop)
                        }

                        if (bottom < height) {
                            const fadeBottom = Math.min(height, bottom + fade)
                            const bottomGradient = ctx.createLinearGradient(0, bottom, 0, fadeBottom)
                            bottomGradient.addColorStop(0.0, "rgba(0,0,0,1)")
                            bottomGradient.addColorStop(1.0, "rgba(0,0,0,0)")
                            ctx.fillStyle = bottomGradient
                            ctx.fillRect(left, bottom, cutWidth, fadeBottom - bottom)
                        }

                        ctx.restore()
                    }

                    onPaint: {
                        const ctx = getContext("2d")
                        const count = Math.max(2, sideVisualizerRail.bandCount)
                        const wave = []
                        var peak = 0

                        ctx.clearRect(0, 0, width, height)
                        if (!sideVisualizerRail.activeForPaint)
                            return

                        if (popupCutCoversCanvas())
                            return

                        for (let i = 0; i < count; i += 1) {
                            peak = Math.max(peak, rawVisualizerValue(i))
                            wave.push(pointAt(i))
                        }

                        ctx.save()
                        ctx.lineCap = "round"
                        ctx.lineJoin = "round"

                        if (sideVisualizerRail.pixelMode) {
                            drawPixelVisualizer(ctx, peak)
                            clearPopupCut(ctx)
                            ctx.restore()
                            return
                        }

                        ctx.fillStyle = root.sideRailMaterialColor()
                        ctx.beginPath()
                        moldedGlassPath(ctx, wave)
                        ctx.fill()

                        const waveAlpha = peak >= 0.045 ? Math.min(0.22, 0.08 + peak * 0.24) : 0.055
                        ctx.strokeStyle = veloraTheme.alpha(root.sidebarPanelBorderColor(), veloraTheme.themeId === "pywal16" ? waveAlpha : Math.min(0.42, waveAlpha + 0.08))
                        ctx.lineWidth = 0.75
                        ctx.beginPath()
                        moldedFramePath(ctx, wave)
                        ctx.stroke()

                        clearPopupCut(ctx)
                        ctx.restore()
                    }

                    Component.onCompleted: sideVisualizerRail.requestWaveformPaint(true)
                    onWidthChanged: sideVisualizerRail.requestWaveformPaint(true)
                    onHeightChanged: sideVisualizerRail.requestWaveformPaint(true)
                }

                Timer {
                    id: waveformPaintTimer

                    interval: 16
                    repeat: false
                    onTriggered: {
                        if (sideVisualizerRail.activeForPaint)
                            waveformCanvas.requestPaint()
                    }
                }

                Connections {
                    target: barRoot
                    function onCavaValuesChanged() {
                        if (root.sideVisualizerMounted)
                            sideVisualizerRail.requestWaveformPaint(false)
                    }
                }

                Connections {
                    target: root

                    function onBarOnRightChanged() {
                        waveformPaintTimer.stop()
                        waveformCanvas.requestPaint()
                        sideVisualizerRelayoutTimer.restart()
                    }
                }

                Timer {
                    id: sideVisualizerRelayoutTimer

                    interval: 1
                    repeat: false
                    onTriggered: sideVisualizerRail.requestWaveformPaint(true)
                }

                Connections {
                    target: veloraTheme
                    function onActiveTextChanged() { if (root.sideVisualizerMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onThemeModeChanged() { if (root.sideVisualizerMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onThemeIdChanged() { if (root.sideVisualizerMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onVisualizerStrengthChanged() { if (root.sideVisualizerMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onVisualizerModeChanged() { if (root.sideVisualizerMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onVisualizerPixelSizeChanged() { if (root.sideVisualizerMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onVisualizerGradientEnabledChanged() { if (root.sideVisualizerMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onSurfaceBaseChanged() { if (root.sideVisualizerMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onSurfaceSidebarChanged() { if (root.sideVisualizerMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onSidebarOpacityChanged() { if (root.sideVisualizerMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onBarWidthChanged() { if (root.sideVisualizerMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onSidebarBorderGlowChanged() { if (root.sideVisualizerMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onBorderSoftChanged() { if (root.sideVisualizerMounted) sideVisualizerRail.requestWaveformPaint(true) }
                }
            }

            Rectangle {
                id: sideVisualizerFrameVeil

                readonly property int frameEdgeX: Math.round(root.barOnRight
                    ? root.mainAreaX(parent.width) + root.mainAreaWidth(parent.width)
                    : root.mainAreaX(parent.width))

                x: frameEdgeX - 1
                y: root.frameVisualInset
                width: 2
                height: root.frameVisualsMounted ? Math.max(0, parent.height - root.frameVisualInset * 2) : 0
                visible: false && root.frameVisualsMounted
                color: root.desktopFrameBorderColor()
                opacity: root.frameVisualsReveal * (veloraTheme.themeMode === "dark" ? 0.72 : 0.86)
                antialiasing: false
                z: 3
            }

            Rectangle {
                id: rightSoftBackRail

                readonly property int railX: Math.round(root.barX(parent.width) + root.sidebarVisualWidth)

                x: railX
                y: root.frameVisualInset
                width: Math.max(0, parent.width - railX)
                height: root.frameVisualsMounted ? Math.max(0, parent.height - root.frameVisualInset * 2) : 0
                visible: false && root.frameVisualsMounted
                color: "transparent"
                border.width: 1
                border.color: veloraTheme.alpha(veloraTheme.sidebarBorderGlow, 0.20)
                antialiasing: false
            }

            // The central selector lives in wallpaperSelectorPanel (Top layer).
            // Keep only this zero-sized marker so the shared drawers mask can
            // retain the same shape without instantiating a second carousel.
            Item {
                id: topWallpaperCarousel
                width: 0
                height: 0
            }

            Item {
                id: topWallpaperCarouselInputMask

                x: topWallpaperCarousel.x
                y: topWallpaperCarousel.y
                width: root.topWallpaperUsesCenterSelector && root.topWallpaperPopupOpen ? topWallpaperCarousel.width : 0
                height: root.topWallpaperUsesCenterSelector && root.topWallpaperPopupOpen ? topWallpaperCarousel.height : 0
            }

            Item {
                id: topWallpaperStrip

                readonly property real reveal: root.topWallpaperFrameReveal
                readonly property int frameBottomY: root.desktopFrameBottom(parent.height)
                readonly property int topGap: Math.max(24, root.desktopFrameMargin + 12)
                readonly property int bottomGap: Math.max(10, root.desktopFrameMargin - 4)
                readonly property int sideGap: Math.max(8, Math.round(parent.width * 0.006))
                readonly property int stripLeftEdge: root.mainAreaX(parent.width)
                readonly property int stripRightEdge: root.mainAreaX(parent.width) + root.mainAreaWidth(parent.width)
                readonly property bool cardsReady: root.topWallpaperCardsMounted && reveal > 0.14
                readonly property int visibleCards: 9
                readonly property int layoutCards: 6
                readonly property int centerSlot: Math.floor(visibleCards / 2)
                readonly property int arrowGutter: Math.max(18, Math.round(width * 0.012))
                readonly property real contentWidth: Math.max(1, width - arrowGutter * 2)
                readonly property real cardGap: -Math.max(14, Math.round(contentWidth * 0.012))

                function entryForSlot(slot) {
                    return root.topWallpaperEntry(slot - centerSlot)
                }

                function cardWidthForDistance(distance) {
                    const available = Math.max(1, contentWidth - cardGap * (layoutCards - 1))
                    const baseWidth = Math.min(326, Math.max(268, contentWidth * 0.174))
                    const scale = Math.min(1, available / (baseWidth * layoutCards))
                    return baseWidth * scale
                }

                function cardCenterForIntegerOffset(offset) {
                    const sign = offset < 0 ? -1 : 1
                    const distance = Math.abs(offset)
                    let x = arrowGutter + contentWidth / 2
                    let previousWidth = cardWidthForDistance(0)

                    for (let i = 1; i <= distance; ++i) {
                        const nextWidth = cardWidthForDistance(i)
                        x += sign * (previousWidth / 2 + cardGap + nextWidth / 2)
                        previousWidth = nextWidth
                    }

                    return x
                }

                function cardCenterForOffset(offset) {
                    if (Math.abs(offset) < 0.001)
                        return cardCenterForIntegerOffset(0)

                    const sign = offset < 0 ? -1 : 1
                    const absolute = Math.abs(offset)
                    const lower = Math.floor(absolute)
                    const upper = Math.ceil(absolute)
                    const t = absolute - lower

                    if (lower === upper)
                        return cardCenterForIntegerOffset(sign * lower)

                    const from = cardCenterForIntegerOffset(sign * lower)
                    const to = cardCenterForIntegerOffset(sign * upper)
                    return from + (to - from) * t
                }

                x: stripLeftEdge + sideGap
                y: frameBottomY + topGap + Math.round((1 - reveal) * 12)
                width: Math.max(0, stripRightEdge - stripLeftEdge - sideGap * 2)
                height: Math.max(0, parent.height - root.desktopFrameMargin - frameBottomY - topGap - bottomGap)
                visible: root.topWallpaperUsesBottomSelector && root.topWallpaperMounted && reveal > 0.01 && width > 420 && height > 78
                opacity: root.topWallpaperSurfaceReveal * Math.min(1, reveal * 1.25)
                z: 60
                clip: true
                focus: root.topWallpaperKeyboardFocus

                Keys.onEscapePressed: root.toggleTopWallpaperPopup(false, false)

                Keys.onPressed: function(event) {
                    if (!root.topWallpaperPopupOpen)
                        return

                    if (event.key === Qt.Key_Left || event.key === Qt.Key_A) {
                        root.moveTopWallpaper(-1)
                        event.accepted = true
                        return
                    }

                    if (event.key === Qt.Key_Right || event.key === Qt.Key_D) {
                        root.moveTopWallpaper(1)
                        event.accepted = true
                        return
                    }

                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.applyTopWallpaperSelection()
                        event.accepted = true
                    }
                }

                onVisibleChanged: {
                    if (visible && root.topWallpaperKeyboardFocus)
                        forceActiveFocus()
                }

                Connections {
                    target: root

                    function onTopWallpaperKeyboardFocusChanged() {
                        if (root.topWallpaperKeyboardFocus && topWallpaperStrip.visible)
                            topWallpaperStrip.forceActiveFocus()
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    z: 0
                    enabled: root.topWallpaperPopupOpen
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onPressed: function(mouse) {
                        mouse.accepted = true
                        if (root.topWallpaperKeyboardFocus)
                            topWallpaperStrip.forceActiveFocus()
                    }
                }

                Repeater {
                    model: topWallpaperStrip.visible && topWallpaperStrip.cardsReady ? 15 : 0

                    delegate: Image {
                        readonly property int preloadOffset: index - 7
                        readonly property var preloadEntry: root.topWallpaperEntry(preloadOffset)

                        width: 1
                        height: 1
                        visible: false
                        source: preloadEntry && preloadEntry.preview ? preloadEntry.preview : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        retainWhileLoading: true
                        smooth: false
                        mipmap: false
                        sourceSize.width: 600
                        sourceSize.height: 360
                    }
                }

                Repeater {
                    model: topWallpaperStrip.visible && topWallpaperStrip.cardsReady ? topWallpaperStrip.visibleCards : 0

                    delegate: Item {
                        id: wallpaperCard

                        readonly property int slotOffset: index - topWallpaperStrip.centerSlot
                        readonly property real slideOffset: root.topWallpaperSlideDirection === 0 ? 0 : root.topWallpaperSlideDirection * root.topWallpaperSlideEase()
                        readonly property real visualOffset: slotOffset - slideOffset
                        readonly property real layoutDistance: Math.abs(slotOffset)
                        readonly property real distance: Math.abs(visualOffset)
                        readonly property real focusAmount: Math.max(0, 1 - Math.min(1, distance / 3.0))
                        readonly property real cardWidth: topWallpaperStrip.cardWidthForDistance(layoutDistance)
                        readonly property real cardHeight: Math.min(topWallpaperStrip.height - 18, Math.max(104, topWallpaperStrip.height * 0.74))
                        readonly property real cardLean: Math.min(64, Math.max(34, cardWidth * 0.21))
                        readonly property var entry: topWallpaperStrip.entryForSlot(index)

                        function cardPath(ctx, w, h, inset) {
                            const pad = Math.max(0, inset || 0)
                            const left = pad
                            const right = Math.max(left + 1, w - pad)
                            const top = pad
                            const bottom = Math.max(top + 1, h - pad)
                            const lean = Math.min(cardLean, Math.max(8, (right - left) * 0.34))

                            ctx.beginPath()
                            ctx.moveTo(Math.min(right - 1, left + lean), top)
                            ctx.lineTo(right, top)
                            ctx.lineTo(Math.max(left + 1, right - lean), bottom)
                            ctx.lineTo(left, bottom)
                            ctx.closePath()
                        }

                        x: Math.round(topWallpaperStrip.cardCenterForOffset(visualOffset) - width / 2)
                        y: Math.round((topWallpaperStrip.height - height) / 2 + 4)
                        width: Math.round(cardWidth)
                        height: Math.round(cardHeight)
                        z: Math.round(40 + focusAmount * 30 - distance)
                        opacity: Math.min(1, Math.max(0.60, 0.78 + focusAmount * 0.22 - Math.max(0, distance - 3.15) * 0.24))
                        visible: height > 40 && width > 80
                        scale: 1.00 + focusAmount * 0.16
                        rotation: 0
                        transformOrigin: Item.Center

                        Rectangle {
                            id: cardShadow

                            anchors.fill: parent
                            visible: false
                            color: "transparent"
                        }

                        Item {
                            id: cardImageClip

                            anchors.fill: parent
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: cardMask
                            }

                            Image {
                                anchors.fill: parent
                                source: wallpaperCard.entry && wallpaperCard.entry.preview ? wallpaperCard.entry.preview : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                retainWhileLoading: true
                                smooth: false
                                mipmap: false
                                opacity: 0.98
                                sourceSize.width: 600
                                sourceSize.height: 360
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: veloraTheme.themeMode === "dark"
                                    ? Qt.rgba(0, 0, 0, wallpaperCard.distance < 0.5 ? 0.04 : 0.10)
                                    : Qt.rgba(1, 1, 1, wallpaperCard.distance < 0.5 ? 0.02 : 0.10)
                            }
                        }

                        Canvas {
                            id: cardMask

                            anchors.fill: parent
                            visible: false

                            onPaint: {
                                const ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                wallpaperCard.cardPath(ctx, width, height, 2)
                                ctx.fillStyle = "white"
                                ctx.fill()
                            }

                            Component.onCompleted: requestPaint()
                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()
                        }

                        Canvas {
                            id: cardBorder

                            anchors.fill: parent
                            antialiasing: true

                            onPaint: {
                                const ctx = getContext("2d")
                                const selected = wallpaperCard.layoutDistance < 0.5

                                ctx.clearRect(0, 0, width, height)
                                ctx.save()
                                wallpaperCard.cardPath(ctx, width, height, selected ? 2.5 : 3.5)
                                ctx.strokeStyle = selected
                                    ? veloraTheme.alpha(veloraTheme.accentPrimary, veloraTheme.themeMode === "dark" ? 0.56 : 0.44)
                                    : veloraTheme.alpha(veloraTheme.borderSoft, veloraTheme.themeMode === "dark" ? 0.26 : 0.34)
                                ctx.lineWidth = selected ? 1.55 : 1.05
                                ctx.stroke()

                                wallpaperCard.cardPath(ctx, width, height, selected ? 6.5 : 7.5)
                                ctx.strokeStyle = Qt.rgba(1, 1, 1, selected ? 0.52 : 0.34)
                                ctx.lineWidth = 0.8
                                ctx.stroke()
                                ctx.restore()
                            }

                            Component.onCompleted: requestPaint()
                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()
                        }
                    }
                }

                Item {
                    id: topWallpaperLeftArrow

                    width: 48
                    height: Math.min(82, Math.max(62, topWallpaperStrip.height * 0.46))
                    x: Math.max(0, Math.round(topWallpaperStrip.arrowGutter / 2 - width / 2))
                    y: Math.round((topWallpaperStrip.height - height) / 2)
                    z: 90
                    visible: false
                    opacity: topWallpaperArrowLeftMouse.containsMouse ? 0.95 : 0.68

                    Rectangle {
                        anchors.fill: parent
                        radius: Math.min(width, height) / 2
                        color: veloraTheme.alpha(veloraTheme.surfaceSidebar, veloraTheme.themeMode === "dark" ? 0.42 : 0.54)
                        border.width: 1
                        border.color: veloraTheme.alpha(veloraTheme.borderSoft, 0.38)
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "‹"
                        color: veloraTheme.textPrimary
                        font.pixelSize: Math.round(parent.height * 0.54)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        id: topWallpaperArrowLeftMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.moveTopWallpaper(-1)
                    }
                }

                Item {
                    id: topWallpaperRightArrow

                    width: 48
                    height: topWallpaperLeftArrow.height
                    x: Math.min(topWallpaperStrip.width - width, Math.round(topWallpaperStrip.width - topWallpaperStrip.arrowGutter / 2 - width / 2))
                    y: topWallpaperLeftArrow.y
                    z: 90
                    visible: false
                    opacity: topWallpaperArrowRightMouse.containsMouse ? 0.95 : 0.68

                    Rectangle {
                        anchors.fill: parent
                        radius: Math.min(width, height) / 2
                        color: veloraTheme.alpha(veloraTheme.surfaceSidebar, veloraTheme.themeMode === "dark" ? 0.42 : 0.54)
                        border.width: 1
                        border.color: veloraTheme.alpha(veloraTheme.borderSoft, 0.38)
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "›"
                        color: veloraTheme.textPrimary
                        font.pixelSize: Math.round(parent.height * 0.54)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        id: topWallpaperArrowRightMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.moveTopWallpaper(1)
                    }
                }
            }

            Item {
                id: topWallpaperStripInputMask

                x: topWallpaperStrip.x
                y: topWallpaperStrip.y
                width: root.topWallpaperUsesBottomSelector && root.topWallpaperPopupOpen ? topWallpaperStrip.width : 0
                height: root.topWallpaperUsesBottomSelector && root.topWallpaperPopupOpen ? topWallpaperStrip.height : 0
            }

            Item {
                id: inlineNotificationToastInputMask

                x: inlineNotificationToastStage.x
                y: inlineNotificationToastStage.y
                width: inlineNotificationToastStage.visible ? inlineNotificationToastStage.width : 0
                height: inlineNotificationToastStage.visible ? inlineNotificationToastStage.height : 0
                z: 139
            }

            Item {
                id: inlineNotificationToastStage

                readonly property bool mounted: root.notificationToastMounted || opacity > 0.001
                readonly property bool attachedToWeather: root.weatherTopWindowOpen && inlineWeatherTopFrame.mounted
                readonly property int panelWidth: Math.max(parent.width, panel.modelData.width)
                readonly property int safeWidth: Math.max(320, panelWidth - 96)
                readonly property int bubbleRadius: attachedToWeather ? panel.weatherTopCornerRadius : Math.min(17, height / 2)
                readonly property int weatherToastGap: 12
                readonly property int openY: attachedToWeather
                    ? Math.min(Math.round(parent.height - root.desktopFrameMargin - height), Math.round(inlineWeatherTopFrame.y + inlineWeatherTopFrame.height + weatherToastGap))
                    : root.desktopFrameMargin

                width: attachedToWeather ? inlineWeatherTopFrame.width : Math.round(Math.min(safeWidth, Math.max(330, panelWidth * 0.18)))
                height: attachedToWeather ? 76 : 48
                x: attachedToWeather ? inlineWeatherTopFrame.x : Math.round((panelWidth - width) / 2)
                y: root.notificationToastVisible || attachedToWeather ? openY : -height - 18
                z: 140
                visible: mounted && !root.notificationsInTopbar
                opacity: root.notificationToastVisible ? 1 : 0
                scale: 1
                transformOrigin: Item.Top

                onYChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                onOpacityChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                onWidthChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                onHeightChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()

                Behavior on y {
                    enabled: veloraTheme.motionEnabled && !inlineNotificationToastStage.attachedToWeather
                    NumberAnimation {
                        duration: root.notificationToastVisible ? root.notificationToastOpenDuration : root.notificationToastCloseDuration
                        easing.type: root.notificationToastVisible ? Easing.BezierSpline : Easing.InOutCubic
                        easing.bezierCurve: root.notificationToastVisible ? veloraTheme.motionCurveEmphasizedAccel : veloraTheme.motionCurveStandard
                    }
                }

                Behavior on opacity {
                    enabled: veloraTheme.motionEnabled
                    NumberAnimation {
                        duration: root.notificationToastVisible ? Math.max(180, Math.round(root.notificationToastOpenDuration * 0.48)) : Math.max(320, Math.round(root.notificationToastCloseDuration * 0.52))
                        easing.type: root.notificationToastVisible ? Easing.BezierSpline : Easing.InOutCubic
                        easing.bezierCurve: root.notificationToastVisible ? veloraTheme.motionCurveEmphasizedAccel : veloraTheme.motionCurveStandard
                    }
                }

                Rectangle {
                    id: inlineNotificationToastBubble

                    anchors.fill: parent
                    radius: inlineNotificationToastStage.bubbleRadius
                    color: "transparent"
                    border.width: 0
                    antialiasing: true
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                    }
                    height: 1
                    visible: inlineNotificationToastStage.attachedToWeather
                    color: root.desktopFrameBorderColor()
                    opacity: 0.52
                }

                Item {
                    id: inlineNotificationToastIcon

                    width: 32
                    height: 32
                    x: inlineNotificationToastStage.attachedToWeather ? 24 : 10
                    y: Math.round((parent.height - height) / 2)

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: root.notificationIconSurfaceColor(root.notificationToastIconKey)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.22)
                        antialiasing: true
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                        }
                        height: parent.height * 0.42
                        radius: 10
                        visible: false
                        color: Qt.rgba(1, 1, 1, 0.14)
                    }

                    Canvas {
                        id: inlineNotificationToastIconCanvas

                        anchors.fill: parent
                        antialiasing: true

                        function drawBell(ctx) {
                            ctx.beginPath()
                            ctx.moveTo(27, 15)
                            ctx.bezierCurveTo(19, 16, 17, 24, 17, 31)
                            ctx.lineTo(14, 37)
                            ctx.quadraticCurveTo(27, 42, 40, 37)
                            ctx.lineTo(37, 31)
                            ctx.bezierCurveTo(37, 24, 35, 16, 27, 15)
                            ctx.stroke()
                            ctx.beginPath()
                            ctx.arc(27, 41, 3.1, 0, Math.PI, false)
                            ctx.stroke()
                        }

                        function drawWhatsapp(ctx) {
                            ctx.beginPath()
                            ctx.arc(27, 26, 15, 0.22 * Math.PI, 1.86 * Math.PI, false)
                            ctx.stroke()
                            ctx.beginPath()
                            ctx.moveTo(17, 37)
                            ctx.lineTo(14, 45)
                            ctx.lineTo(23, 41)
                            ctx.stroke()
                            ctx.beginPath()
                            ctx.moveTo(22, 20)
                            ctx.bezierCurveTo(20, 22, 22, 28, 27, 33)
                            ctx.bezierCurveTo(31, 37, 36, 38, 38, 35)
                            ctx.moveTo(23, 20)
                            ctx.lineTo(26, 25)
                            ctx.moveTo(31, 32)
                            ctx.lineTo(37, 35)
                            ctx.stroke()
                        }

                        onPaint: {
                            const ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.save()
                            ctx.scale(width / 54, height / 54)
                            ctx.lineWidth = 3
                            ctx.lineCap = "round"
                            ctx.lineJoin = "round"
                            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.88)
                            ctx.fillStyle = Qt.rgba(1, 1, 1, 0.88)
                            if (root.notificationToastIconKey === "whatsapp")
                                drawWhatsapp(ctx)
                            else
                                drawBell(ctx)
                            ctx.restore()
                        }

                        Component.onCompleted: requestPaint()

                        Connections {
                            target: root
                            function onNotificationToastIconKeyChanged() { inlineNotificationToastIconCanvas.requestPaint() }
                            function onNotificationToastSerialChanged() { inlineNotificationToastIconCanvas.requestPaint() }
                        }
                    }
                }

                Text {
                    x: inlineNotificationToastIcon.x + inlineNotificationToastIcon.width + 13
                    y: Math.round((parent.height - height) / 2) - 1
                    width: parent.width - x - (inlineNotificationToastStage.attachedToWeather ? 28 : 16)
                    text: root.notificationToastTitle
                    color: veloraTheme.textPrimary
                    font.family: veloraTheme.uiFont
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: root.hideNotificationToast()
                }
            }

            VeloraBarV2 {
                id: barRoot

                theme: veloraTheme
                mediaService: root.composition ? root.composition.mediaService : null
                mediaEnabled: root.sidebarMediaEnabled
                audioVisualizer: root.composition ? root.composition.audioVisualizer : null
                toolsService: root.composition ? root.composition.topbarTools : null
                fanPlusService: root.composition ? root.composition.fanPlusService : null
                bluetoothMenuOpen: bluetoothPopover.opened
                notificationMenuOpen: notificationsPopover.opened
                wifiMenuOpen: wifiPopover.opened
                mediaMenuOpen: edgePopover.opened && edgePopover.mediaPanelActive
                onMediaMenuRequested: centerY => {
                    if (!edgePopover.enabled) return
                    if (edgePopover.opened && edgePopover.mediaPanelActive) edgePopover.close()
                    else { edgePopover.open(); edgePopover.showPage("media") }
                }
                onBluetoothMenuRequested: centerY => {
                    bluetoothPopover.anchorY = barRoot.y + centerY
                    bluetoothPopover.toggle()
                }
                onBluetoothHoverChanged: (inside, centerY) => {
                    bluetoothPopover.anchorY = barRoot.y + centerY
                    bluetoothPopover.triggerHovered = inside
                }
                onNotificationMenuRequested: centerY => {
                    notificationsPopover.anchorY = barRoot.y + centerY
                    notificationsPopover.toggle()
                }
                onNotificationHoverChanged: (inside, centerY) => {
                    notificationsPopover.anchorY = barRoot.y + centerY
                    notificationsPopover.triggerHovered = inside
                }
                onWifiMenuRequested: centerY => {
                    wifiPopover.anchorY = barRoot.y + centerY
                    wifiPopover.toggle()
                }
                onWifiHoverChanged: (inside, centerY) => {
                    wifiPopover.anchorY = barRoot.y + centerY
                    wifiPopover.triggerHovered = inside
                }
                caffeineMenuOpen: coffeePopover.opened
                onCaffeineMenuRequested: centerY => {
                    coffeePopover.anchorY = barRoot.y + centerY
                    coffeePopover.toggle()
                }
                onCaffeineHoverChanged: (inside, centerY) => {
                    coffeePopover.anchorY = barRoot.y + centerY
                    coffeePopover.triggerHovered = inside
                }
                notesMenuOpen: notesPopover.opened
                onNotesMenuRequested: centerY => {
                    notesPopover.anchorY = barRoot.y + centerY
                    notesPopover.toggle()
                }
                unifiedSurface: root.composition ? root.composition.topbarTheme.wallpaperSurfaceTone : veloraTheme.surfaceSidebar
                unifiedPaletteEnabled: Boolean(root.composition)
                unifiedTextPrimary: root.composition
                    ? root.composition.unifiedBarTextPrimary : "white"
                unifiedTextSecondary: root.composition
                    ? root.composition.unifiedBarTextSecondary : "#c4cede"
                unifiedAccent: root.composition
                    ? root.composition.unifiedBarAccent : "#8db8ff"
                unifiedAccentAlt: root.composition
                    ? root.composition.unifiedBarAccentAlt : "#b99cff"
                z: 10
                visible: root.sideBarLayoutEnabled
                opacity: root.layoutSwitchOpacity
                width: root.sideBarLayoutEnabled ? root.sidebarVisualWidth : 0
                x: root.barX(parent.width)
                focusMode: root.focusMode
                focusIndex: root.focusIndex
                focusTarget: root.focusTarget
                visualizerActive: (root.sideVisualizerMounted || root.screenVisualizerMounted)
                    && root.audioVisualizerProcessWanted
                cavaForceActive: false
                shellDrawsPanelSurface: root.sideBarLayoutEnabled
                reducedIconMotion: !!root.composition && root.composition.motionTokens.reduced
                volumeControlOpen: root.volumeControlOpen
                brightnessControlOpen: root.brightnessControlOpen
                batteryControlOpen: root.batteryControlOpen
                activePopupType: root.wallpaperSelectorOpen ? "theme" : root.quickPopupType
                notificationCountOverride: root.notificationHistoryCount
                onMoveFocusRequested: function(dir) {
                    root.moveFocus(dir)
                }
                onExitFocusRequested: root.exitFocus()
                onThemeRequested: function(centerY) {
                    const fromFocusedBrush = root.focusMode && root.focusTarget === "theme"
                    const localCenter = Number(centerY)
                    const popupCenter = localCenter > 0 ? barRoot.y + localCenter : root.defaultQuickPopupCenterY("theme")
                    root.toggleWallpaperSelector(popupCenter, fromFocusedBrush)
                }
                onSettingsRequested: function(centerY) {
                    root.openUnifiedSettings()
                }
                onLayoutRequested: function(centerY) {
                    root.cycleBarLayout()
                }
                onQuickPopupRequested: function(type, centerY) {
                    root.openAdaptiveBarPopup(type, barRoot.y + centerY)
                }
                onQuickPopupHovered: function(type, centerY) {
                    root.previewAdaptiveBarPopup(type, barRoot.y + centerY)
                }
                onQuickPopupHoverEnded: function(type) {
                    root.endAdaptiveBarPopupHover(type)
                }
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    topMargin: root.sidebarVerticalMargin
                    bottomMargin: root.sidebarVerticalMargin
                }
            }

            VeloraRailControls {
                id: railControls
                motion: root.composition.motionTokens
                handoffSource: panel.activeRailSystemPopover
                onLevelOpening: popover => panel.activeRailSystemPopover = popover
                onLevelClosed: type => { if (root.activeRailControl === type) root.activeRailControl = "" }
                anchors.fill: parent
                z: 11
                theme: veloraTheme
                accent: barRoot.pink
                rightSide: root.barOnRight
                railWidth: root.sidebarVisualWidth
                volumeCenter: barRoot.y + barRoot.volumeControlCenter
                brightnessCenter: barRoot.y + barRoot.brightnessControlCenter
                batteryCenter: barRoot.y + barRoot.batteryControlCenter
                volumeOpen: root.volumeControlOpen
                brightnessOpen: root.brightnessControlOpen
                refreshSerial: root.railFeedbackSerial
                batteryOpen: root.batteryControlOpen
                extraPanel: wifiPopover.opened ? wifiPopover.outline : notificationsPopover.opened ? notificationsPopover.outline : bluetoothPopover.opened ? bluetoothPopover.outline : notesPopover.opened ? notesPopover.outline : coffeePopover.opened ? coffeePopover.outline : wifiPopover.mounted ? wifiPopover.outline : notificationsPopover.mounted ? notificationsPopover.outline : bluetoothPopover.mounted ? bluetoothPopover.outline : notesPopover.mounted ? notesPopover.outline : coffeePopover.outline
                onPanelHoverChanged: hovered => {
                    root.railControlPanelHovered = hovered
                    if (hovered) railControlCloseTimer.stop()
                    else if (!root.railControlHoverTarget) railControlCloseTimer.restart()
                }
                onShapeChanged: {
                    Qt.callLater(unifiedFrameCanvas.requestPaint)
                    Qt.callLater(panel.syncUnifiedBarNativeShape)
                }
            }

            Item {
                id: edgeTrigger
                x: parent.width - width; y: edgePopover.anchorY - height / 2
                width: root.sideBarLayoutEnabled && !root.barOnRight ? root.oppositeFrameWidth + 4 : 0
                height: 200
                HoverHandler { id: edgeHover; blocking: false }
            }
            VeloraEdgePopover {
                id: edgePopover
                onMediaPanelActiveChanged: root.setEdgeMediaVisible(panel.modelData.name, mediaPanelActive)
                onSpectrumActiveChanged: root.setEdgeSpectrumVisible(panel.modelData.name, spectrumActive)
                Component.onDestruction: {
                    root.setEdgeMediaVisible(panel.modelData.name, false)
                    root.setEdgeSpectrumVisible(panel.modelData.name, false)
                    root.setEdgeDockProgress(panel.modelData.name, 0)
                }
                anchors.fill: parent
                z: 12
                motion: root.composition.motionTokens
                enabled: root.sideBarLayoutEnabled && !root.barOnRight && !!root.composition
                theme: root.composition ? root.composition.topbarTheme : null
                media: root.composition ? root.composition.mediaService : null
                analyzer: root.composition ? root.composition.audioVisualizer : null
                railWidth: root.oppositeFrameWidth
                // The local origin starts below the reserved topbar.
                anchorY: height - panel.modelData.height / 2
                triggerHovered: edgeHover.hovered
                onOpening: {
                    coffeePopover.close(); notesPopover.close(); bluetoothPopover.close()
                    notificationsPopover.close(); wifiPopover.close()
                    root.activeRailControl = ""
                    root.closeQuickPopup()
                    if (root.composition) root.composition.closeTopbarTool()
                }
                onShapeChanged: {
                    Qt.callLater(unifiedFrameCanvas.requestPaint)
                    Qt.callLater(panel.syncUnifiedBarNativeShape)
                }
                onContourSamplesChanged: {
                    Qt.callLater(unifiedFrameCanvas.requestPaint)
                    Qt.callLater(panel.syncUnifiedBarNativeShape)
                }
                onSidebarWaveScaleChanged: {
                    root.setEdgeDockProgress(panel.modelData.name, dockProgress)
                    Qt.callLater(unifiedFrameCanvas.requestPaint)
                    Qt.callLater(panel.syncUnifiedBarNativeShape)
                }
                onSidebarSamplesChanged: {
                    Qt.callLater(unifiedFrameCanvas.requestPaint)
                    Qt.callLater(panel.syncUnifiedBarNativeShape)
                }
            }

            VeloraRailCoffee {
                id: coffeePopover
                motion: root.composition.motionTokens
                anchors.fill: parent
                z: 12
                enabled: root.sideBarLayoutEnabled && !!root.composition
                theme: root.composition ? root.composition.topbarTheme : null
                system: root.composition ? root.composition.topbarTools : null
                rightSide: root.barOnRight
                railWidth: root.sidebarVisualWidth
                handoffSource: panel.activeRailSystemPopover
                onOpening: { panel.activeRailSystemPopover = coffeePopover; bluetoothPopover.close(); notesPopover.close(); notificationsPopover.close(); wifiPopover.close(); root.activeRailControl = ""; root.closeQuickPopup(); if (root.composition) root.composition.closeTopbarTool() }
                onShapeChanged: Qt.callLater(unifiedFrameCanvas.requestPaint)
            }
            VeloraRailNotes {
                id: notesPopover
                motion: root.composition.motionTokens
                anchors.fill: parent
                z: 12
                enabled: root.sideBarLayoutEnabled && !!root.composition
                theme: root.composition ? root.composition.topbarTheme : null
                system: root.composition ? root.composition.topbarTools : null
                rightSide: root.barOnRight
                railWidth: root.sidebarVisualWidth
                handoffSource: panel.activeRailSystemPopover
                onOpening: { panel.activeRailSystemPopover = notesPopover; bluetoothPopover.close(); coffeePopover.close(); notificationsPopover.close(); wifiPopover.close(); root.activeRailControl = ""; root.closeQuickPopup(); if (root.composition) root.composition.closeTopbarTool() }
                onShapeChanged: Qt.callLater(unifiedFrameCanvas.requestPaint)
            }
            VeloraRailBluetooth {
                id: bluetoothPopover
                motion: root.composition.motionTokens
                anchors.fill: parent
                z: 12
                enabled: root.sideBarLayoutEnabled && !!root.composition
                theme: root.composition ? root.composition.topbarTheme : null
                rightSide: root.barOnRight
                railWidth: root.sidebarVisualWidth
                ink: barRoot.ink
                accent: barRoot.pink
                uiFont: barRoot.uiFont
                handoffSource: panel.activeRailSystemPopover
                onOpening: { panel.activeRailSystemPopover = bluetoothPopover; coffeePopover.close(); notesPopover.close(); notificationsPopover.close(); wifiPopover.close(); root.activeRailControl = ""; root.closeQuickPopup(); if (root.composition) root.composition.closeTopbarTool() }
                onShapeChanged: Qt.callLater(unifiedFrameCanvas.requestPaint)
            }
            VeloraRailNotifications {
                id: notificationsPopover
                motion: root.composition.motionTokens
                anchors.fill: parent
                z: 12
                enabled: root.sideBarLayoutEnabled && !!root.composition
                theme: root.composition ? root.composition.topbarTheme : null
                system: root.composition ? root.composition.topbarTools : null
                rightSide: root.barOnRight
                railWidth: root.sidebarVisualWidth
                notificationsModel: notificationHistoryModel
                ink: barRoot.ink
                accent: barRoot.pink
                uiFont: barRoot.uiFont
                handoffSource: panel.activeRailSystemPopover
                onDismissRequested: id => root.dismissNotificationHistory(id)
                onClearRequested: root.clearTrackedNotificationHistory()
                onOpening: { panel.activeRailSystemPopover = notificationsPopover; coffeePopover.close(); notesPopover.close(); bluetoothPopover.close(); wifiPopover.close(); root.activeRailControl = ""; root.closeQuickPopup() }
                onShapeChanged: Qt.callLater(unifiedFrameCanvas.requestPaint)
            }
            VeloraRailWifi {
                id: wifiPopover
                motion: root.composition.motionTokens
                onOpenedChanged: if (root.composition) root.composition.sidebarNetworkActive = opened
                anchors.fill: parent
                z: 12
                enabled: root.sideBarLayoutEnabled && !!root.composition
                theme: root.composition ? root.composition.topbarTheme : null
                system: root.composition ? root.composition.topbarTools : null
                rightSide: root.barOnRight
                railWidth: root.sidebarVisualWidth
                ink: barRoot.ink
                uiFont: barRoot.uiFont
                handoffSource: panel.activeRailSystemPopover
                onOpening: { panel.activeRailSystemPopover = wifiPopover; coffeePopover.close(); notesPopover.close(); bluetoothPopover.close(); notificationsPopover.close(); root.activeRailControl = ""; root.closeQuickPopup() }
                onShapeChanged: Qt.callLater(unifiedFrameCanvas.requestPaint)
            }
            Connections {
                target: root
                function onRailMediaRequested() {
                    if (!edgePopover.enabled) return
                    if (edgePopover.opened && edgePopover.mediaPanelActive) edgePopover.close()
                    else { edgePopover.open(); edgePopover.showPage("media") }
                }
            }
            MouseArea {
                id: railToolOutsideInput
                z: 9
                width: panel.width
                height: railControls.mounted || edgePopover.mounted || coffeePopover.mounted || notesPopover.mounted || bluetoothPopover.mounted || notificationsPopover.mounted || wifiPopover.mounted ? panel.height : 0
                acceptedButtons: Qt.AllButtons
                onPressed: { root.activeRailControl = ""; edgePopover.close(); coffeePopover.close(); notesPopover.close(); bluetoothPopover.close(); notificationsPopover.close(); wifiPopover.close() }
            }
            Connections {
                target: root
                function onActiveRailControlChanged() {
                    if (!root.activeRailControl) return
                    if (!edgePopover.keepOpenForControl(root.activeRailControl)) edgePopover.close()
                    coffeePopover.close(); notesPopover.close(); bluetoothPopover.close()
                    notificationsPopover.close(); wifiPopover.close()
                }
                function onQuickPopupTypeChanged() {
                    if (!root.quickPopupType) return
                    if (!edgePopover.keepOpenForControl(root.quickPopupType)) edgePopover.close()
                    coffeePopover.close(); notesPopover.close(); bluetoothPopover.close()
                    notificationsPopover.close(); wifiPopover.close()
                }
            }

            Item {
                id: inlineModalOverlayInputMask

                x: 0
                y: 0
                width: root.settingsPanelOpen || root.wallpaperSelectorOpen ? panel.width : 0
                height: root.settingsPanelOpen || root.wallpaperSelectorOpen ? panel.height : 0
            }

            Item {
                id: inlineQuickPopupInputMask

                x: inlineQuickPopupSurface.x
                y: inlineQuickPopupSurface.y
                width: root.sideQuickPopupPanelVisible ? inlineQuickPopupSurface.width : 0
                height: root.sideQuickPopupPanelVisible ? inlineQuickPopupSurface.height : 0
            }

            Item {
                id: inlineQuickPopupOutsideInputMask

                x: 0
                y: 0
                width: root.quickPopupHoldOpen && root.visibleQuickPopupType === "search" ? panel.width : 0
                height: root.quickPopupHoldOpen && root.visibleQuickPopupType === "search" ? panel.height : 0
                z: 1

                MouseArea {
                    anchors.fill: parent
                    enabled: root.quickPopupHoldOpen && root.visibleQuickPopupType === "search"
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: root.closeQuickPopup()
                }
            }

            Rectangle {
                id: inlineQuickPopupJoinStrip

                z: 19
                x: root.barOnRight
                    ? Math.round(root.barX(parent.width) - root.sideQuickPopupBridgeWidth - 1)
                    : Math.round(root.barX(parent.width) + root.sidebarVisualWidth)
                y: inlineQuickPopupSurface.y
                width: root.sideQuickPopupBridgeWidth + 2
	                height: inlineQuickPopupLoader.height
	                visible: false
	                opacity: inlineQuickPopupLoader.revealProgress
	                color: root.sidebarBarMaterialColor()
	            }

                VeloraAttachedSurface {
                    id: inlineQuickPopupSurface

                    readonly property bool batterySurface: root.visibleQuickPopupType === "battery"
                    readonly property int batterySurfaceTop: Math.min(inlineQuickPopupLoader.y, Math.max(root.desktopFrameMargin + 30, inlineQuickPopupLoader.y - 18))
                    readonly property int batterySurfaceBottom: Math.min(parent.height - root.desktopFrameMargin, inlineQuickPopupLoader.y + inlineQuickPopupLoader.height)

                    z: 20
                    theme: veloraTheme
                    attachSide: root.popupAttachSide
                    useCustomGlass: root.frameVisualsMounted || root.visibleQuickPopupType === "battery"
                    customGlass: root.quickPopupSurfaceGlass(root.visibleQuickPopupType)
                    flattenAttachedEdge: root.quickPopupJoinedToBar
                    lineReveal: true
                    transitionContrast: root.quickPopupTransitionContrast
                    slideOffsetOverride: root.visibleQuickPopupType === "search" || root.visibleQuickPopupType === "agenda" || root.visibleQuickPopupType === "weatherPanel" ? 76 : -1
                    x: inlineQuickPopupLoader.x - (root.barOnRight ? 0 : root.sideQuickPopupBridgeWidth)
                    y: batterySurface ? batterySurfaceTop : inlineQuickPopupLoader.y
                    width: inlineQuickPopupLoader.width + root.sideQuickPopupBridgeWidth
                    height: batterySurface ? Math.max(0, batterySurfaceBottom - batterySurfaceTop) : inlineQuickPopupLoader.height
                    radius: batterySurface ? 28 : inlineQuickPopupLoader.cornerRadius
	                revealProgress: root.quickPopupSurfaceReveal
	                visible: root.sideQuickPopupPanelVisible && root.quickPopupSurfaceReveal > 0.015 && inlineQuickPopupLoader.contentReady
	            }

            Item {
                id: inlineQuickPopupLoader

	                property int cacheGeneration: 0
	                readonly property bool active: root.sideQuickPopupPanelVisible || (root.sideBarLayoutEnabled && root.quickPopupPreloadEnabled)
	                readonly property int targetWidth: root.quickPopupWidthForScreen(root.visibleQuickPopupType, parent.width)
	                readonly property int targetHeight: root.quickPopupHeightForScreen(root.visibleQuickPopupType, parent.height)
	                readonly property int targetX: root.quickPopupX(root.visibleQuickPopupType, parent.width, targetWidth)
	                readonly property int targetY: root.quickPopupY(root.visibleQuickPopupType, targetHeight, parent.height)
	                readonly property int geometryDuration: Math.max(180, veloraTheme.motionPanelGeometry)
	                readonly property int fadeInDuration: Math.max(130, Math.round(veloraTheme.motionPanelIn * 0.72))
	                readonly property int switchFadeOutDuration: Math.max(120, Math.round(veloraTheme.motionPanelOut * 0.72))
	                readonly property int closeFadeOutDuration: Math.max(160, root.quickPopupLineCloseDuration)
	                readonly property int cornerRadius: {
	                    cacheGeneration
	                    const popup = itemForType(root.visibleQuickPopupType)
                    return popup ? popup.cornerRadius : 13
                }
                readonly property real revealProgress: root.quickPopupSurfaceReveal

	                z: 21
	                width: targetWidth
	                height: targetHeight
	                x: targetX
	                y: targetY
		                visible: root.sideQuickPopupPanelVisible && root.quickPopupSurfaceReveal > 0.015
	                clip: true

                onActiveChanged: if (!active) root.quickPopupHovering = false

                function itemForType(type) {
                    const index = root.cachedQuickPopupIndex(type)
                    if (index < 0 || typeof inlineQuickPopupCache === "undefined")
                        return null

                    const loader = inlineQuickPopupCache.itemAt(index)
                    return loader && loader.item ? loader.item : null
                }

                function opacityTransitionDuration(showing) {
                    if (showing)
                        return fadeInDuration
                    return root.quickPopupVisible ? switchFadeOutDuration : closeFadeOutDuration
                }

                readonly property bool contentReady: {
                    cacheGeneration
                    if (!root.sideQuickPopupPanelVisible || root.visibleQuickPopupType.length <= 0)
                        return false
                    return itemForType(root.visibleQuickPopupType) !== null
                }

                Repeater {
                    id: inlineQuickPopupCache

                    model: root.cachedQuickPopupTypes

                    Loader {
                        id: popupCacheLoader

	                        property string cacheType: String(modelData)
	                        readonly property bool showing: root.quickPopupVisible && root.visibleQuickPopupType === cacheType
	                        readonly property bool closing: !root.quickPopupVisible && root.quickPopupWindowOpen && root.visibleQuickPopupType === cacheType

	                        active: showing
	                            || closing
	                            || opacity > 0.001
                                || cacheType === "battery"
	                            || (root.quickPopupPreloadEnabled && root.cachedQuickPopupIndex(cacheType) < root.quickPopupPreloadCount)
	                        asynchronous: false
	                        visible: root.sideQuickPopupPanelVisible && (showing || closing || opacity > 0.001)
	                        opacity: showing ? 1 : 0
	                        x: root.barOnRight ? Math.round(inlineQuickPopupLoader.width - width) : 0
	                        y: Math.round((inlineQuickPopupLoader.height - height) / 2)
	                        width: root.quickPopupWidthForScreen(cacheType, panel.width)
	                        height: root.quickPopupHeightForScreen(cacheType, panel.height)
	                        z: showing ? 2 : 1

	                        Behavior on opacity {
	                            enabled: veloraTheme.motionEnabled && inlineQuickPopupLoader.active
	                            NumberAnimation {
	                                duration: inlineQuickPopupLoader.opacityTransitionDuration(popupCacheLoader.showing)
	                                easing.type: popupCacheLoader.showing ? veloraTheme.motionEaseEnter : veloraTheme.motionEaseExit
	                            }
	                        }

                        onLoaded: {
                            inlineQuickPopupLoader.cacheGeneration += 1
                            if (cacheType === "search" && root.quickPopupType === "search")
                                root.scheduleSearchPopupFocus()
                        }

                        sourceComponent: Component {
                            VeloraSidePopup {
                                theme: veloraTheme
                                externalSurface: true
                                lineReveal: true
                                warmSwitch: root.quickPopupSurfaceReveal > 0.35
	                                revealProgressOverride: root.quickPopupSurfaceReveal
	                                attachSide: root.popupAttachSide
	                                popupType: popupCacheLoader.cacheType
                                notificationsModelOverride: notificationHistoryModel
	                                open: popupCacheLoader.showing
	                                interactiveFocus: root.quickPopupType === popupCacheLoader.cacheType
	                                    && (popupCacheLoader.cacheType === "search" || popupCacheLoader.cacheType === "agenda" || popupCacheLoader.cacheType === "weatherPanel")
                                width: popupCacheLoader.width
                                height: popupCacheLoader.height
                                visible: popupCacheLoader.visible
                                onHoldOpenChanged: root.setQuickPopupHoldOpen(popupCacheLoader.cacheType, holdOpen)
                                onOpenChanged: {
                                    if (!open && popupCacheLoader.cacheType === "search")
                                        root.setQuickPopupHoldOpen(popupCacheLoader.cacheType, false)
                                }
                                onCloseRequested: root.closeQuickPopup()
                                onAdvancedSettingsRequested: {
                                    root.closeQuickPopup()
                                    root.toggleSettingsPanel(root.defaultQuickPopupCenterY("settings"), true)
                                }
                                onPopupRequested: function(type) {
                                    root.openAdaptiveBarPopup(type, root.defaultQuickPopupCenterY(type))
                                }
                                onPointerInsideChanged: function(inside) {
                                    root.quickPopupHovering = inside
                                    if (inside)
                                        hoverCloseTimer.stop()
                                    else if (root.hoverPopupType.length > 0)
                                        root.scheduleHoverClose()
                                }
                            }
                        }
                    }
                }

	                Behavior on y {
	                    enabled: veloraTheme.motionEnabled && inlineQuickPopupLoader.active
	                    NumberAnimation {
	                        duration: inlineQuickPopupLoader.geometryDuration
	                        easing.type: veloraTheme.motionEaseEnter
	                    }
	                }

	                Behavior on x {
	                    enabled: veloraTheme.motionEnabled && inlineQuickPopupLoader.active
	                    NumberAnimation {
	                        duration: inlineQuickPopupLoader.geometryDuration
	                        easing.type: veloraTheme.motionEaseEnter
	                    }
	                }

	                Behavior on width {
	                    enabled: veloraTheme.motionEnabled && inlineQuickPopupLoader.active
	                    NumberAnimation {
	                        duration: inlineQuickPopupLoader.geometryDuration
	                        easing.type: veloraTheme.motionEaseEnter
	                    }
	                }

	                Behavior on height {
	                    enabled: veloraTheme.motionEnabled && inlineQuickPopupLoader.active
	                    NumberAnimation {
	                        duration: inlineQuickPopupLoader.geometryDuration
	                        easing.type: veloraTheme.motionEaseEnter
	                    }
	                }
            }

            Item {
                id: inlineModalLayer

                z: 40
                anchors.fill: parent
                visible: root.wallpaperSelectorPanelVisible || root.settingsPanelPanelVisible
                focus: root.wallpaperSelectorOpen || root.settingsPanelOpen

                Keys.onEscapePressed: {
                    root.wallpaperSelectorOpen = false
                    root.settingsPanelOpen = false
                }

                Keys.onPressed: function(event) {
                    if (root.wallpaperSelectorOpen) {
                        const selector = inlineWallpaperLoader.item
                        if (!selector)
                            return

                        if ((event.key === Qt.Key_Left || event.key === Qt.Key_A) && selector.moveSelection) {
                            selector.moveSelection(-1)
                            event.accepted = true
                            return
                        }

                        if ((event.key === Qt.Key_Right || event.key === Qt.Key_D) && selector.moveSelection) {
                            selector.moveSelection(1)
                            event.accepted = true
                            return
                        }

                        if ((event.key === Qt.Key_Down || event.key === Qt.Key_S) && selector.cycleWallpaperMode) {
                            selector.cycleWallpaperMode(1)
                            event.accepted = true
                            return
                        }

                        if ((event.key === Qt.Key_Up || event.key === Qt.Key_W) && selector.cycleWallpaperMode) {
                            selector.cycleWallpaperMode(-1)
                            event.accepted = true
                            return
                        }

                        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && selector.applySelected) {
                            selector.applySelected()
                            event.accepted = true
                            return
                        }
                    }

                    if (root.settingsPanelOpen) {
                        const settings = inlineSettingsLoader.item
                        if (!settings)
                            return

                        if (event.key === Qt.Key_Left || event.key === Qt.Key_A) {
                            settings.moveSelection(-1)
                            event.accepted = true
                            return
                        }

                        if (event.key === Qt.Key_Right || event.key === Qt.Key_D) {
                            settings.moveSelection(1)
                            event.accepted = true
                            return
                        }

                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            settings.applySelected()
                            event.accepted = true
                        }
                    }
                }

                MouseArea {
                    z: 0
                    anchors.fill: parent
                    enabled: root.wallpaperSelectorOpen || root.settingsPanelOpen
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        root.wallpaperSelectorOpen = false
                        root.settingsPanelOpen = false
                    }
                }

                Item {
                    id: inlineWallpaperInputMask

                    x: inlineWallpaperLoader.x
                    y: inlineWallpaperLoader.y
                    width: root.wallpaperSelectorPanelVisible ? inlineWallpaperLoader.width : 0
                    height: root.wallpaperSelectorPanelVisible ? inlineWallpaperLoader.height : 0
                }

                VeloraAttachedSurface {
                    z: 2
                    theme: veloraTheme
                    attachSide: root.popupAttachSide
                    x: inlineWallpaperLoader.x
                    y: inlineWallpaperLoader.y
                    width: inlineWallpaperLoader.width
                    height: inlineWallpaperLoader.height
                    radius: inlineWallpaperLoader.cornerRadius
                    revealProgress: inlineWallpaperLoader.revealProgress
                    visible: false
                }

                Loader {
                    id: inlineWallpaperLoader

                    readonly property int cornerRadius: item ? item.cornerRadius : 28
                    readonly property real revealProgress: item ? item.revealProgress : 0
                    readonly property int availableWidth: root.leftMenuWidth
                    readonly property int availableHeight: Math.max(360, parent.height - root.leftMenuFrameInset * 2)

                    active: root.wallpaperSelectorPanelVisible || root.wallpaperPreloadEnabled
                    asynchronous: false
                    z: 3
                    width: availableWidth
                    height: availableHeight
                    x: root.leftMenuOnLeft ? root.leftMenuFrameInset : Math.round(parent.width - root.leftMenuFrameInset - width)
                    y: root.leftMenuFrameInset
                    visible: root.wallpaperSelectorPanelVisible

                    onActiveChanged: if (!active) root.wallpaperSelectorHovering = false
                    onLoaded: root.focusWallpaperSelectorInput()
                    onVisibleChanged: if (visible) root.focusWallpaperSelectorInput()

                    sourceComponent: Component {
                        VeloraWallpaperSelector {
                            theme: veloraTheme
                            externalSurface: true
                            attachSide: root.popupAttachSide
                            width: inlineWallpaperLoader.width
                            height: inlineWallpaperLoader.height
                            open: root.wallpaperSelectorVisible
                            preload: root.wallpaperPreloadEnabled
                            visible: root.wallpaperSelectorPanelVisible
                            focus: root.wallpaperSelectorOpen
                            onCloseRequested: root.wallpaperSelectorOpen = false
                            onVisibilityRequested: root.openWallpaperVisibility(root.defaultQuickPopupCenterY("theme"))

                            HoverHandler {
                                margin: 24
                                onHoveredChanged: {
                                    root.wallpaperSelectorHovering = hovered
                                    if (hovered)
                                        hoverCloseTimer.stop()
                                    else
                                        root.scheduleHoverClose()
                                }
                            }
                        }
                    }

                    Behavior on y {
                        enabled: veloraTheme.motionEnabled && inlineWallpaperLoader.active
                        NumberAnimation {
                            duration: veloraTheme.motionPanelGeometry
                            easing.type: veloraTheme.motionEaseEmphasized
                            easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                        }
                    }

                    Behavior on width {
                        enabled: veloraTheme.motionEnabled && inlineWallpaperLoader.active
                        NumberAnimation {
                            duration: veloraTheme.motionPanelGeometry
                            easing.type: veloraTheme.motionEaseEmphasized
                            easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                        }
                    }

                    Behavior on height {
                        enabled: veloraTheme.motionEnabled && inlineWallpaperLoader.active
                        NumberAnimation {
                            duration: veloraTheme.motionPanelGeometry
                            easing.type: veloraTheme.motionEaseEmphasized
                            easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                        }
                    }
                }

                Item {
                    id: inlineSettingsInputMask

                    x: inlineSettingsLoader.x
                    y: inlineSettingsLoader.y
                    width: root.settingsPanelPanelVisible ? inlineSettingsLoader.width : 0
                    height: root.settingsPanelPanelVisible ? inlineSettingsLoader.height : 0
                }

                VeloraAttachedSurface {
                    z: 4
                    theme: veloraTheme
                    attachSide: root.popupAttachSide
                    x: inlineSettingsLoader.x
                    y: inlineSettingsLoader.y
                    width: inlineSettingsLoader.width
                    height: inlineSettingsLoader.height
                    radius: inlineSettingsLoader.cornerRadius
                    revealProgress: inlineSettingsLoader.revealProgress
                    flattenAttachedEdge: true
                    visible: root.settingsPanelPanelVisible && !root.frameVisualsMounted
                }

                Loader {
                    id: inlineSettingsLoader

                    readonly property int cornerRadius: item ? item.cornerRadius : 18
                    readonly property real revealProgress: item ? item.revealProgress : 0

                    active: root.settingsPanelPanelVisible || root.settingsPanelPreloadEnabled
                    asynchronous: true
                    z: 5
                    width: Math.round(Math.min(404, root.mainAreaWidth(parent.width) - 48))
                    height: Math.round(parent.height - root.frameVisualInset * 2 - 30)
                    x: root.barOnRight
                        ? Math.round(Math.max(root.frameVisualInset, root.barX(parent.width) - root.popupFrameGap - width))
                        : Math.round(root.barX(parent.width) + root.sidebarVisualWidth + root.popupFrameGap)
                    y: Math.round(root.frameVisualInset + 12)
                    visible: root.settingsPanelPanelVisible

                    onActiveChanged: if (!active) root.settingsPanelHovering = false
                    onXChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                    onYChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                    onWidthChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                    onHeightChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                    onRevealProgressChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()

                    sourceComponent: Component {
                        VeloraSettingsPanel {
                            composition: root.composition
                            theme: veloraTheme
                            externalSurface: true
                            attachSide: root.popupAttachSide
                            width: inlineSettingsLoader.width
                            height: inlineSettingsLoader.height
                            open: root.settingsPanelVisible
                            visible: root.settingsPanelPanelVisible
                            focus: root.settingsPanelOpen
                            onCloseRequested: root.settingsPanelOpen = false
                            onLyricsMaskEditorRequested: root.openLyricsMaskEditor()

                            HoverHandler {
                                margin: 24
                                onHoveredChanged: {
                                    root.settingsPanelHovering = hovered
                                    if (hovered)
                                        hoverCloseTimer.stop()
                                    else
                                        root.scheduleHoverClose()
                                }
                            }
                        }
                    }

                    Behavior on y {
                        enabled: veloraTheme.motionEnabled && inlineSettingsLoader.active
                        NumberAnimation {
                            duration: veloraTheme.motionPanelGeometry
                            easing.type: veloraTheme.motionEaseEmphasized
                            easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                        }
                    }

                    Behavior on width {
                        enabled: veloraTheme.motionEnabled && inlineSettingsLoader.active
                        NumberAnimation {
                            duration: veloraTheme.motionPanelGeometry
                            easing.type: veloraTheme.motionEaseEmphasized
                            easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                        }
                    }

                    Behavior on height {
                        enabled: veloraTheme.motionEnabled && inlineSettingsLoader.active
                        NumberAnimation {
                            duration: veloraTheme.motionPanelGeometry
                            easing.type: veloraTheme.motionEaseEmphasized
                            easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                        }
                    }
                }

                Connections {
                    target: root

                    function onWallpaperSelectorOpenChanged() {
                        if (root.wallpaperSelectorOpen)
                            root.focusWallpaperSelectorInput()
                    }

                    function onSettingsPanelOpenChanged() {
                        if (root.settingsPanelOpen)
                            Qt.callLater(function() {
                                if (inlineSettingsLoader.item)
                                    inlineSettingsLoader.item.forceActiveFocus()
                            })
                    }
                }
            }
        }
    }

    Variants {
        model: root.shellSuppressedByFullscreen ? [] : Quickshell.screens

        PanelWindow {
            id: dashboardPanel

            required property var modelData
            property real dashboardReveal: !root.rightSoftLayout && root.rightDashboardOpen ? 1 : 0
            property bool dashboardCardHovering: false
            readonly property bool dashboardOnLeft: root.barOnRight
            readonly property int triggerWidth: 34
            readonly property int cardWidth: 372
            readonly property int panelWidth: cardWidth + triggerWidth
            readonly property var sections: [
                { id: "weather", y: 16, height: 206 },
                { id: "system", y: 232, height: 162 },
                { id: "calendar", y: 404, height: 218 },
                { id: "media", y: 632, height: 166 },
                { id: "memo", y: 808, height: 154 },
                { id: "todo", y: 972, height: 180 }
            ]
            readonly property int activeCardY: sectionY(root.rightDashboardSection)
            readonly property int activeCardHeight: sectionHeight(root.rightDashboardSection)

            visible: !root.rightSoftLayout
            screen: modelData
            color: "transparent"
            implicitWidth: panelWidth
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            focusable: false

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "velora-shell-drawers"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Behavior on dashboardReveal {
                enabled: veloraTheme.motionEnabled
                NumberAnimation {
                    duration: root.rightDashboardOpen ? veloraTheme.motionPanelIn : veloraTheme.motionPanelOut
                    easing.type: root.rightDashboardOpen ? veloraTheme.motionEaseEnter : veloraTheme.motionEaseExit
                }
            }

            function sectionAtY(localY) {
                for (let i = 0; i < sections.length; i += 1) {
                    const section = sections[i]
                    if (localY >= section.y && localY <= section.y + section.height)
                        return section.id
                }

                return ""
            }

            function sectionData(sectionId) {
                for (let i = 0; i < sections.length; i += 1) {
                    if (sections[i].id === sectionId)
                        return sections[i]
                }

                return sections[0]
            }

            function sectionY(sectionId) {
                return sectionData(sectionId).y
            }

            function sectionHeight(sectionId) {
                return sectionData(sectionId).height
            }

            function requestDashboardOpen(section) {
                if (section && section.length > 0)
                    root.rightDashboardSection = section

                dashboardCloseDelay.stop()
                root.rightDashboardOpen = true
            }

            function dashboardHovering() {
                return dashboardTriggerMouse.containsMouse || dashboardCardHovering
            }

            function requestDashboardClose() {
                if (!dashboardHovering())
                    dashboardCloseDelay.restart()
            }

            mask: Region {
                Region {
                    item: dashboardInteractionArea
                    radius: 0
                }

                Region {
                    item: dashboardCardInputMask
                    radius: dashboardLoader.cornerRadius
                }
            }

            anchors {
                top: true
                bottom: true
                left: dashboardOnLeft
                right: !dashboardOnLeft
            }

            Timer {
                id: dashboardCloseDelay

                interval: 260
                repeat: false
                onTriggered: {
                    if (!dashboardPanel.dashboardHovering())
                        root.rightDashboardOpen = false
                }
            }

            Item {
                id: dashboardInteractionArea

                x: dashboardPanel.dashboardOnLeft ? 0 : dashboardPanel.width - dashboardPanel.triggerWidth
                y: 0
                width: dashboardPanel.triggerWidth
                height: dashboardPanel.height

                MouseArea {
                    id: dashboardTriggerMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    onEntered: {
                        const section = dashboardPanel.sectionAtY(mouseY)
                        if (section.length > 0)
                            dashboardPanel.requestDashboardOpen(section)
                    }
                    onPositionChanged: function(mouse) {
                        const section = dashboardPanel.sectionAtY(mouse.y)
                        if (section.length > 0)
                            dashboardPanel.requestDashboardOpen(section)
                        else
                            dashboardPanel.requestDashboardClose()
                    }
                    onExited: dashboardPanel.requestDashboardClose()
                }
            }

            Item {
                id: dashboardCardInputMask

                x: dashboardLoader.x
                y: dashboardLoader.y
                width: dashboardLoader.active ? dashboardLoader.width : 0
                height: dashboardLoader.active ? dashboardLoader.height : 0
            }

            Loader {
                id: dashboardLoader

                readonly property int cornerRadius: item ? item.cornerRadius : 22

                active: dashboardPanel.visible && (root.rightDashboardOpen || dashboardPanel.dashboardReveal > 0.01)
                asynchronous: true
                width: dashboardPanel.cardWidth
                height: dashboardPanel.activeCardHeight
                x: dashboardPanel.dashboardOnLeft ? dashboardPanel.triggerWidth : dashboardPanel.width - dashboardPanel.triggerWidth - width
                y: dashboardPanel.activeCardY
                visible: active
                opacity: dashboardPanel.dashboardReveal
                scale: 0.982 + dashboardPanel.dashboardReveal * 0.018
                transformOrigin: dashboardPanel.dashboardOnLeft ? Item.Left : Item.Right
                transform: Translate {
                    x: Math.round((1 - dashboardPanel.dashboardReveal) * (dashboardPanel.dashboardOnLeft ? -28 : 28))
                    y: Math.round((1 - dashboardPanel.dashboardReveal) * -4)
                }

                sourceComponent: Component {
                    VeloraDashboard {
                        theme: veloraTheme
                        compact: true
                        activeSection: root.rightDashboardSection
                        width: dashboardLoader.width
                        height: dashboardLoader.height
                        visible: dashboardLoader.active
                        onThemeRequested: function(centerY) {
                            root.rightDashboardOpen = false
                            root.showWallpaperSelector(Number(centerY) > 0 ? centerY : root.defaultQuickPopupCenterY("theme"))
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: dashboardLoader.active
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                            onEntered: {
                                dashboardPanel.dashboardCardHovering = true
                                dashboardPanel.requestDashboardOpen(root.rightDashboardSection)
                            }
                            onExited: {
                                dashboardPanel.dashboardCardHovering = false
                                dashboardPanel.requestDashboardClose()
                            }
                        }
                    }
                }

                Behavior on height {
                    enabled: veloraTheme.motionEnabled && dashboardLoader.active
                    NumberAnimation {
                        duration: veloraTheme.motionPanelGeometry
                        easing.type: veloraTheme.motionEaseEmphasized
                        easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                    }
                }

                Behavior on y {
                    enabled: veloraTheme.motionEnabled && dashboardLoader.active
                    NumberAnimation {
                        duration: veloraTheme.motionPanelGeometry
                        easing.type: veloraTheme.motionEaseEmphasized
                        easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                    }
                }

                Behavior on scale {
                    enabled: veloraTheme.motionEnabled && dashboardLoader.active
                    NumberAnimation {
                        duration: veloraTheme.motionPanelGeometry
                        easing.type: veloraTheme.motionEaseEmphasized
                        easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                    }
                }

            }
        }
    }

}
