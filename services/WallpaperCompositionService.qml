import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    required property var config
    required property var wallpaperService
    required property var profileService

    readonly property string statePath: root.config.configDir
        + "/wallpaper-compositions.json"
    property var document: ({ schemaVersion: 1, wallpapers: ({}) })
    property bool ready: false
    property bool restoring: false
    property string activeKey: ""
    property string pendingProfileKey: ""
    property var pendingProfileComposition: null
    property bool outgoingSavedForProfile: false
    property string lastError: ""
    property string observedScene: ""

    signal compositionRestored(string wallpaper)
    signal compositionSaved(string wallpaper)

    function clone(value) {
        return value === undefined ? undefined
            : JSON.parse(JSON.stringify(value))
    }

    function keyFor(value) {
        let path = root.wallpaperService.localPath(value)
        while (path.length > 1 && path.endsWith("/"))
            path = path.slice(0, -1)
        return path
    }

    function sceneOnly(snapshot) {
        const value = snapshot || ({})
        return {
            schemaVersion: 8,
            canvas: clone(value.canvas || ({ width: 1600, height: 900 })),
            character: clone(value.character || ({})),
            gallery: clone(value.gallery || []),
            galleryOrder: clone(value.galleryOrder || [0, 1, 2]),
            scene: clone(value.scene || ({ layers: [] })),
            sharedWidgets: clone(value.sharedWidgets || ({ items: [] })),
            calendar: clone(value.calendar || ({ reminders: [] })),
            profile: clone(value.profile || ({}))
        }
    }

    function saveKey(key, snapshot) {
        const normalized = keyFor(key)
        if (!ready || !normalized.length || restoring)
            return false
        const next = clone(document)
        if (!next.wallpapers || typeof next.wallpapers !== "object")
            next.wallpapers = ({})
        next.schemaVersion = 1
        next.wallpapers[normalized] = {
            path: normalized,
            updatedAt: new Date().toISOString(),
            composition: sceneOnly(snapshot || root.config.compositionSnapshot())
        }
        next.activeWallpaper = normalized
        document = next
        saveTimer.restart()
        compositionSaved(normalized)
        return true
    }

    function saveActive() {
        return saveKey(activeKey, root.config.compositionSnapshot())
    }

    function applyScene(snapshot, seed) {
        const current = root.config.compositionSnapshot()
        const saved = sceneOnly(snapshot)
        saved.appearance = clone(current.appearance)
        saved.topbar = clone(current.topbar)
        saved.topbarLayout = clone(current.topbarLayout)
        restoring = true
        const applied = root.config.applyComposition(saved,
            String(seed || "wallpaper-save"))
        Qt.callLater(function() { root.restoring = false })
        return applied
    }

    function activate(value, initial) {
        const key = keyFor(value)
        if (!ready || !key.length || key === activeKey)
            return false

        const pendingMatches = pendingProfileKey === key
        if (!initial && activeKey.length
                && !(pendingMatches && outgoingSavedForProfile))
            saveActive()

        observedScene = JSON.stringify(sceneOnly(root.config.compositionSnapshot()))
        activeKey = key
        const pending = pendingMatches ? pendingProfileComposition : null
        pendingProfileKey = ""
        pendingProfileComposition = null
        outgoingSavedForProfile = false

        if (pending) {
            saveKey(key, pending)
            compositionRestored(key)
            return true
        }

        const entry = document.wallpapers
            && document.wallpapers[key] ? document.wallpapers[key] : null
        if (entry && entry.composition) {
            applyScene(entry.composition, "wallpaper-save")
        } else if (initial) {
            // The first run adopts the user's current layout as-is.
            saveKey(key, root.config.compositionSnapshot())
        } else {
            const first = root.config.defaultWallpaperComposition()
            applyScene(first, "wallpaper-default-v1")
            saveKey(key, first)
        }
        compositionRestored(key)
        return true
    }

    function load(text) {
        try {
            const parsed = JSON.parse(String(text || "{}"))
            document = parsed && typeof parsed === "object" ? parsed
                : ({ schemaVersion: 1, wallpapers: ({}) })
            if (!document.wallpapers || typeof document.wallpapers !== "object")
                document.wallpapers = ({})
            ready = true
            activate(root.wallpaperService.currentPath, true)
        } catch (error) {
            lastError = String(error)
            document = ({ schemaVersion: 1, wallpapers: ({}) })
            ready = true
            activate(root.wallpaperService.currentPath, true)
        }
    }

    FileView {
        id: stateFile
        path: root.statePath
        atomicWrites: true
        watchChanges: false
        printErrors: false
        onLoaded: root.load(text())
        onLoadFailed: {
            root.document = ({ schemaVersion: 1, wallpapers: ({}) })
            root.ready = true
            root.activate(root.wallpaperService.currentPath, true)
        }
    }

    Timer {
        id: saveTimer
        interval: 240
        repeat: false
        onTriggered: stateFile.setText(
            JSON.stringify(root.document, null, 2) + "\n")
    }

    Timer {
        id: compositionDebounce
        interval: 700
        repeat: false
        onTriggered: root.saveActive()
    }

    Connections {
        target: root.wallpaperService
        function onReadyChanged() {
            if (root.ready && root.wallpaperService.ready)
                root.activate(root.wallpaperService.currentPath,
                    root.activeKey.length === 0)
        }
        function onCurrentPathChanged() {
            if (root.ready)
                root.activate(root.wallpaperService.currentPath, false)
        }
    }

    Connections {
        target: root.config
        function onConfigurationChanged() {
            const scene = JSON.stringify(root.sceneOnly(root.config.compositionSnapshot()))
            const changed = scene !== root.observedScene
            root.observedScene = scene
            if (changed && root.ready && !root.restoring && root.activeKey.length)
                compositionDebounce.restart()
        }
    }

    Connections {
        target: root.profileService
        function onProfileApplying(profileId) {
            // applyComposition() mutates ConfigStore before the wallpaper
            // transition completes, so preserve the outgoing wallpaper now.
            root.outgoingSavedForProfile = root.saveActive()
        }
        function onProfileApplied(profileId) {
            const profile = root.profileService.profileById(profileId)
            const path = profile && profile.composition
                && profile.composition.wallpaper
                ? profile.composition.wallpaper.path : ""
            const key = root.keyFor(path)
            if (key.length && key !== root.activeKey) {
                root.pendingProfileKey = key
                root.pendingProfileComposition = root.config.compositionSnapshot()
            } else {
                root.pendingProfileKey = ""
                root.pendingProfileComposition = null
                root.outgoingSavedForProfile = false
                compositionDebounce.restart()
            }
        }
    }
}
