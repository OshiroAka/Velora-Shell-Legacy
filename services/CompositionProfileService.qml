import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    required property var config
    required property var wallpaperService

    readonly property string dataHome: Quickshell.env("XDG_DATA_HOME")
        || root.config.homeDir + "/.local/share"
    readonly property string profilesRoot: dataHome + "/velora-shell/composition-profiles"
    readonly property string indexPath: root.config.configDir + "/profiles.json"
    readonly property string helperPath: Quickshell.shellDir
        + "/scripts/velora-composition-profiles"
    readonly property string packageHelperPath: Quickshell.shellDir
        + "/scripts/velora-composition-package"

    property bool ready: false
    property bool busy: false
    property bool dirty: false
    property string error: ""
    property string activeProfileId: ""
    property var profiles: []
    property var indexDocument: ({})
    property string operation: ""
    property string processOutput: ""
    property string applyAfterReloadId: ""
    property string draftWallpaperPath: ""
    property bool draftWallpaperDirty: false
    property string draftWallpaperProfileId: ""
    property string draftProfileName: ""
    property string editingProfileId: ""
    property string selectAfterReloadId: ""
    property bool transitioning: false
    property string pendingWallpaperPath: ""
    readonly property int transitionDuration: root.config.reducedMotion ? 0 : 680

    signal profilesChangedExternally
    signal profileApplied(string profileId)
    signal profileApplying(string profileId)
    signal operationFinished(string operation, bool ok, string message)

    function clone(value) {
        return value === undefined ? undefined : JSON.parse(JSON.stringify(value))
    }

    function profileById(profileId) {
        for (let index = 0; index < profiles.length; index += 1) {
            if (String(profiles[index].id) === String(profileId))
                return profiles[index]
        }
        return null
    }

    function activeProfile() {
        return profileById(activeProfileId)
    }

    function cleanName(value, fallback) {
        const compact = String(value || "").trim().replace(/\s+/g, " ")
        return compact.length > 0 ? compact.slice(0, 64) : String(fallback || "Perfil")
    }

    function hasProfileAccent(profile) {
        return /^#[0-9a-fA-F]{6}$/.test(String(profile && profile.accent || ""))
    }

    function comparisonComposition(value) {
        const normalized = clone(value || ({}))
        if (!normalized.sharedWidgets || typeof normalized.sharedWidgets !== "object")
            normalized.sharedWidgets = ({})
        normalized.sharedWidgets.items = root.config.normalizedSharedWidgets(
            normalized.sharedWidgets.items)
        if (!normalized.appearance || typeof normalized.appearance !== "object")
            normalized.appearance = ({})
        if (!normalized.topbar || typeof normalized.topbar !== "object")
            normalized.topbar = ({})
        delete normalized.topbar.variant
        normalized.topbarLayout = root.config.normalizedTopbarLayout(
            normalized.topbarLayout)
        if (normalized.appearance.lockDimmingMode === undefined)
            normalized.appearance.lockDimmingMode = "off"
        if (normalized.appearance.lockDimmingAmount === undefined)
            normalized.appearance.lockDimmingAmount = 0.28
        if (normalized.appearance.waterCausticsEnabled === undefined)
            normalized.appearance.waterCausticsEnabled = true
        if (normalized.appearance.waterCausticsIntensity === undefined)
            normalized.appearance.waterCausticsIntensity = 0.32
        if (normalized.appearance.waterCausticsLines === undefined)
            normalized.appearance.waterCausticsLines = true
        if (normalized.appearance.waterCausticsModules === undefined)
            normalized.appearance.waterCausticsModules = false
        return normalized
    }

    function refreshDirty() {
        const active = activeProfile()
        if (!active) {
            dirty = false
            return
        }
        const current = root.comparisonComposition(root.config.compositionSnapshot())
        if (active.composition.wallpaper && active.composition.wallpaper.path) {
            current.wallpaper = { path: root.wallpaperService.fileUrl(
                root.wallpaperService.currentPath) }
        }
        dirty = JSON.stringify(root.comparisonComposition(active.composition))
            !== JSON.stringify(current)
    }

    function setDraftWallpaper(value) {
        const path = String(value || "")
        if (path.length === 0)
            return false
        // Conteúdo always edits the composition which is actually active on
        // screen. A stale row selection must never redirect this asset into a
        // different saved profile.
        if (profileById(activeProfileId))
            selectProfileForEditing(activeProfileId, true)
        draftWallpaperPath = path
        draftWallpaperProfileId = String(editingProfileId || activeProfileId)
        draftWallpaperDirty = true
        // Conteúdo is a live editor: selecting a wallpaper must update the
        // current composition immediately, while the same URL remains in the
        // draft so create/update can copy it into the profile directory.
        return root.wallpaperService.applyWallpaper(draftWallpaperPath)
    }

    function setDraftProfileName(value) {
        draftProfileName = String(value || "").slice(0, 64)
    }

    function wallpaperForProfile(profileId) {
        const profile = profileById(profileId)
        return profile && profile.composition && profile.composition.wallpaper
            ? String(profile.composition.wallpaper.path || "") : ""
    }

    function selectProfileForEditing(profileId, forceReload) {
        const profile = profileById(profileId)
        if (!profile)
            return false
        if (!forceReload && draftWallpaperDirty
                && String(editingProfileId) === String(profile.id))
            return true
        editingProfileId = String(profile.id)
        draftWallpaperProfileId = String(profile.id)
        draftProfileName = String(profile.name || "Perfil")
        draftWallpaperPath = wallpaperForProfile(profileId)
        draftWallpaperDirty = false
        return true
    }

    function storageSnapshot(targetProfileId) {
        const snapshot = root.config.compositionSnapshot()
        const targetId = String(targetProfileId || "")
        const target = profileById(targetId)
        let wallpaper = ""
        if (draftWallpaperDirty && draftWallpaperPath.length > 0
                && (targetId.length === 0
                    || draftWallpaperProfileId === targetId)) {
            wallpaper = draftWallpaperPath
        } else if (target && targetId !== String(activeProfileId)
                && target.composition && target.composition.wallpaper) {
            // Updating metadata for an inactive profile must preserve the
            // wallpaper already owned by that profile.
            wallpaper = String(target.composition.wallpaper.path || "")
        } else {
            wallpaper = root.wallpaperService.fileUrl(
                root.wallpaperService.currentPath)
        }
        if (wallpaper.length > 0)
            snapshot.wallpaper = { path: wallpaper }
        return snapshot
    }

    function parseIndex(text, source) {
        try {
            const document = JSON.parse(text || "{}")
            if (Number(document.schemaVersion) !== 1 || !Array.isArray(document.profiles))
                throw new Error("índice de perfis inválido")
            indexDocument = document
            profiles = clone(document.profiles)
            activeProfileId = String(document.activeProfileId || "")
            if (!profileById(activeProfileId) && profiles.length > 0)
                activeProfileId = String(profiles[0].id)
            ready = profiles.length > 0
            error = ""
            if (!profileById(editingProfileId) && profiles.length > 0)
                selectProfileForEditing(activeProfileId)
            if (selectAfterReloadId.length > 0
                    && profileById(selectAfterReloadId)) {
                selectProfileForEditing(selectAfterReloadId)
                selectAfterReloadId = ""
            }
            refreshDirty()
            profilesChangedExternally()

            const needsAccentMigration = profiles.some(function(profile) {
                return !root.hasProfileAccent(profile)
            })
            if (needsAccentMigration && !busy) {
                Qt.callLater(function() {
                    root.runOperation("ensure", [], "")
                })
            }

            const requested = applyAfterReloadId
            applyAfterReloadId = ""
            if (requested.length > 0) {
                const target = requested === "__active__" ? activeProfileId : requested
                if (["create", "update", "delete", "ensure"].includes(operation))
                    selectProfileForEditing(target, true)
                Qt.callLater(function() { root.applyProfile(target, false) })
            }
            return true
        } catch (parseError) {
            error = source + ": " + String(parseError)
            ready = false
            return false
        }
    }

    function runOperation(name, arguments, applyAfter) {
        if (busy || profileProcess.running)
            return false
        operation = name
        processOutput = ""
        applyAfterReloadId = applyAfter || ""
        profileProcess.command = [helperPath, name, "--index", indexPath,
                                  "--data-root", profilesRoot].concat(arguments || [])
        busy = true
        error = ""
        profileProcess.running = true
        return true
    }

    function ensureInitialized() {
        if (!root.config.ready || !root.wallpaperService.ready || busy || ready)
            return false
        return runOperation("ensure", ["--snapshot-json",
                            JSON.stringify(root.storageSnapshot(activeProfileId))], "__active__")
    }

    function createProfile(name) {
        const targetName = cleanName(name || draftProfileName,
                                     "Perfil " + (profiles.length + 1))
        return runOperation("create", ["--name", targetName, "--snapshot-json",
                            JSON.stringify(root.storageSnapshot(""))], "__active__")
    }

    function updateProfile(profileId) {
        const profile = profileById(profileId)
        if (!profile)
            return false
        if (String(profile.id) !== String(activeProfileId)) {
            error = "Aplique o perfil antes de atualizá-lo."
            return false
        }
        return runOperation("update", ["--id", String(profileId), "--name",
                            String(profile.name), "--snapshot-json",
                            JSON.stringify(root.storageSnapshot(profile.id))], String(profileId))
    }

    function renameProfile(profileId, name) {
        if (!profileById(profileId))
            return false
        return runOperation("rename", ["--id", String(profileId), "--name",
                            cleanName(name || draftProfileName,
                                      profileById(profileId).name)], "")
    }

    function deleteProfile(profileId) {
        if (profiles.length <= 1 || !profileById(profileId))
            return false
        return runOperation("delete", ["--id", String(profileId)], "__active__")
    }

    function runPackageOperation(name, arguments) {
        if (busy || profileProcess.running || packageProcess.running)
            return false
        operation = name
        processOutput = ""
        packageProcess.command = [packageHelperPath, name, "--index", indexPath,
                                  "--data-root", profilesRoot].concat(arguments || [])
        busy = true
        error = ""
        packageProcess.running = true
        return true
    }

    function exportPackage(profileId, packagePath) {
        if (!profileById(profileId) || !String(packagePath || ""))
            return false
        return runPackageOperation("export", ["--id", String(profileId),
                                   "--package", String(packagePath)])
    }

    function importPackage(packagePath) {
        if (!String(packagePath || ""))
            return false
        return runPackageOperation("import", ["--package", String(packagePath)])
    }

    function applyProfile(profileId, persist) {
        const profile = profileById(profileId)
        if (!profile)
            return false
        transitioning = true
        transitionTimer.restart()
        // Wallpaper saves must snapshot the outgoing scene before the shell
        // profile replaces it in ConfigStore.
        profileApplying(String(profile.id))
        if (!root.config.applyComposition(profile.composition, profile.id)) {
            transitioning = false
            transitionTimer.stop()
            return false
        }
        activeProfileId = String(profile.id)
        selectProfileForEditing(activeProfileId, true)
        pendingWallpaperPath = profile.composition.wallpaper
                && profile.composition.wallpaper.path
            ? String(profile.composition.wallpaper.path) : ""
        // A profile dial may cross several entries in a few wheel ticks. Keep
        // the composition response immediate, but only decode the wallpaper
        // belonging to the profile on which the user actually settles.
        wallpaperApplyTimer.restart()
        const next = clone(indexDocument)
        next.activeProfileId = activeProfileId
        indexDocument = next
        if (persist === undefined || persist)
            saveActiveTimer.restart()
        Qt.callLater(refreshDirty)
        profileApplied(activeProfileId)
        return true
    }

    Timer {
        id: transitionTimer
        interval: root.transitionDuration + 140
        repeat: false
        onTriggered: root.transitioning = false
    }

    Timer {
        id: wallpaperApplyTimer
        interval: 140
        repeat: false
        onTriggered: {
            const path = root.pendingWallpaperPath
            root.pendingWallpaperPath = ""
            if (path.length > 0)
                root.wallpaperService.applyWallpaper(path)
        }
    }

    function status() {
        return {
            ready: ready,
            busy: busy,
            dirty: dirty,
            count: profiles.length,
            activeProfileId: activeProfileId,
            draftWallpaperDirty: draftWallpaperDirty,
            error: error
        }
    }

    FileView {
        id: indexFile
        path: root.indexPath
        atomicWrites: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.parseIndex(text(), root.indexPath)
        onLoadFailed: function(errorCode) {
            if (errorCode !== FileViewError.FileNotFound)
                root.error = "Não foi possível carregar " + root.indexPath
            initializeTimer.restart()
        }
    }

    Timer {
        id: initializeTimer
        interval: 80
        repeat: false
        onTriggered: root.ensureInitialized()
    }

    Timer {
        id: saveActiveTimer
        interval: 220
        repeat: false
        onTriggered: indexFile.setText(JSON.stringify(root.indexDocument, null, 2) + "\n")
    }

    Connections {
        target: root.config
        function onReadyChanged() {
            if (root.config.ready && !root.ready)
                initializeTimer.restart()
        }
        function onConfigurationChanged() { Qt.callLater(root.refreshDirty) }
    }

    Connections {
        target: root.wallpaperService
        function onReadyChanged() {
            if (root.wallpaperService.ready && !root.ready)
                initializeTimer.restart()
        }
        function onWallpaperApplied() { Qt.callLater(root.refreshDirty) }
    }

    Process {
        id: profileProcess
        running: false

        stdout: SplitParser {
            onRead: function(line) { root.processOutput = String(line) }
        }

        onExited: function(exitCode) {
            root.busy = false
            let result = ({ ok: exitCode === 0 })
            try {
                if (root.processOutput.length > 0)
                    result = JSON.parse(root.processOutput)
            } catch (parseError) {
                result = { ok: false, error: "resposta inválida do gerenciador de perfis" }
            }
            if (exitCode !== 0 || !result.ok) {
                root.error = String(result.error || "falha ao gerenciar o perfil")
                root.applyAfterReloadId = ""
                root.operationFinished(root.operation, false, root.error)
                return
            }
            if (root.applyAfterReloadId === "__active__" && result.activeProfileId)
                root.applyAfterReloadId = String(result.activeProfileId)
            root.operationFinished(root.operation, true, "")
            indexFile.reload()
        }
    }

    Process {
        id: packageProcess
        running: false

        stdout: SplitParser {
            onRead: function(line) { root.processOutput = String(line) }
        }

        onExited: function(exitCode) {
            root.busy = false
            let result = ({ ok: exitCode === 0 })
            try {
                if (root.processOutput.length > 0)
                    result = JSON.parse(root.processOutput)
            } catch (parseError) {
                result = { ok: false, error: "resposta inválida do pacote" }
            }
            if (exitCode !== 0 || !result.ok) {
                root.error = String(result.error || "falha ao processar pacote")
                root.operationFinished(root.operation, false, root.error)
                return
            }
            if (root.operation === "import" && result.profileId)
                root.selectAfterReloadId = String(result.profileId)
            root.operationFinished(root.operation, true,
                                   String(result.path || result.profileId || ""))
            if (root.operation === "import")
                indexFile.reload()
        }
    }

    Component.onCompleted: initializeTimer.restart()
}
