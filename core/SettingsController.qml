import QtQuick
import Quickshell
import Quickshell.Io
import "../components" as Components
import "../features/editor/SettingsCatalog.js" as Catalog

Scope {
    id: root

    required property var motion
    required property var preview
    required property var config
    required property var profileService
    required property var editor
    property var shell: null
    readonly property var wallpaperService: profileService.wallpaperService || null
    readonly property var integrations: integrationsLoader.item
    property string settingsSection: "main"
    property bool integrationsMounted: false
    property string integrationError: ""
    function releaseIntegrations() {
        // Let Process.onExited drain pending writes before tearing down helpers.
        Qt.callLater(function() {
            if (!root.mounted && (!integrationsLoader.item || !integrationsLoader.item.busy))
                root.integrationsMounted = false
        })
    }
    onMountedChanged: {
        if (mounted) integrationsMounted = true
        else releaseIntegrations()
    }
    Connections {
        target: integrationsLoader.item
        function onBusyChanged() { root.releaseIntegrations() }
        function onOperationErrorChanged() {
            if (integrationsLoader.item) root.integrationError = integrationsLoader.item.operationError
        }
    }
    Loader {
        id: integrationsLoader
        active: root.integrationsMounted
        sourceComponent: Components.VeloraSettingsBackend {
            config: root.config
            theme: root.shell ? root.shell.unifiedTheme : null
            composition: root.shell ? root.shell.composition : null
            active: root.shown && root.mode === "settings"
            activePage: root.settingsPage === "media" && root.settingsSection === "velyrics"
                ? "velyrics" : root.settingsPage
            onLyricsMaskEditorRequested: {
                root.hide()
                if (root.shell) root.shell.openLyricsMaskEditor()
            }
        }
    }
    function openLegacySettings() {
        mode = "settings"
        settingsPage = "system"
        shown = true
        serial += 1
        return true
    }
    property bool mounted: false
    property bool shown: false
    property bool picking: false
    property int pendingTarget: 0
    property string pendingImagePath: ""
    property string profileAvatarError: ""
    property bool avatarProfileSavePending: false
    property string pendingKind: "image"
    property string pendingProfileId: ""
    property string editSpace: "desktop"
    property string mode: "settings"
    property string settingsPage: "wallpapers"
    property string pendingGridLayout: "grid2"
    property bool switchingSpace: false
    property int serial: 0
    property var sessionSnapshot: ({})
    property bool sessionDirty: false
    property bool closePrompt: false
    property bool restoringSnapshot: false

    signal opened
    signal closed

    function show(space) {
        if (picking)
            return false
        closeTimer.stop()
        if (!mounted) {
            mounted = true
            serial += 1
            sessionSnapshot = root.editor.snapshot()
            sessionDirty = false
            closePrompt = false
        }
        editSpace = String(space) === "lock" ? "lock" : "desktop"
        if (editSpace === "lock") settingsPage = "lock"
        mode = "settings"
        root.editor.setEditSpace(editSpace)
        root.preview.hide()
        Qt.callLater(function() {
            if (!root.mounted)
                return
            root.shown = true
            root.serial += 1
            root.opened()
        })
        return true
    }

    function beginEditing(space) {
        const target = String(space) === "lock" ? "lock" : "desktop"
        if (!mounted)
            show(target)
        editSpace = target
        settingsPage = target
        mode = "editing"
        root.editor.setEditSpace(target)
        if (target === "lock")
            root.preview.show()
        else
            root.preview.hide()
        serial += 1
        return true
    }

    function returnToSettings() {
        if (!mounted)
            return false
        root.editor.setToolMode("select")
        root.editor.clearSelection()
        root.preview.hide()
        mode = "settings"
        shown = true
        serial += 1
        return true
    }

    function setSettingsPage(value) {
        settingsPage = Catalog.category(String(value || "wallpapers")).id
        return true
    }

    function hide(force) {
        if (!mounted || !shown)
            return false
        if (switchingSpace) {
            console.info("Velora Composer ignored dismissal while switching edit space")
            return false
        }
        // Every committed edit is persisted by ConfigStore; closing never
        // introduces a second save/discard model.
        closePrompt = false
        shown = false
        serial += 1
        root.preview.hide()
        closeTimer.restart()
        return true
    }

    function saveSession() {
        if (root.profileService.activeProfileId.length > 0)
            root.profileService.updateProfile(root.profileService.activeProfileId)
        sessionSnapshot = root.editor.snapshot()
        sessionDirty = false
        closePrompt = false
        return true
    }

    function deactivate() {
        closeTimer.stop()
        closePrompt = false
        shown = false
        mounted = false
        root.preview.hide()
        serial += 1
        closed()
        return true
    }

    function resolveClose(choice) {
        const action = String(choice || "return")
        if (action === "return") {
            closePrompt = false
            return true
        }
        if (action === "save") {
            saveSession()
        } else if (action === "discard") {
            restoringSnapshot = true
            root.editor.applySnapshot(sessionSnapshot, true)
            root.editor.resetHistory()
            restoringSnapshot = false
            sessionDirty = false
        } else {
            return false
        }
        return hide(true)
    }

    function setEditSpace(value) {
        const next = String(value) === "desktop" ? "desktop" : "lock"
        if (editSpace === next)
            return false
        editSpace = next
        root.editor.setEditSpace(next)
        switchingSpace = true
        spaceSwitchTimer.restart()
        closeTimer.stop()
        if (next === "desktop") {
            root.preview.hide()
            // The settings surface owns this editing session. Closing only the
            // lock preview must never inherit a pending Composer dismissal.
            root.mounted = true
            root.shown = true
        } else {
            root.preview.show()
        }
        serial += 1
        return true
    }

    function chooseImage(target) {
        if (picking || imagePicker.running)
            return false
        pendingTarget = Math.max(0, Math.min(3, Number(target)))
        pendingKind = "image"
        pendingImagePath = ""
        picking = true
        shown = false
        serial += 1
        root.preview.hide()
        pickerDelay.restart()
        return true
    }

    function chooseWallpaper() {
        if (picking || imagePicker.running)
            return false
        pendingKind = "wallpaper"
        pendingImagePath = ""
        picking = true
        shown = false
        serial += 1
        root.preview.hide()
        pickerDelay.restart()
        return true
    }

    function beginPicker(kind) {
        if (picking || imagePicker.running)
            return false
        pendingKind = String(kind)
        pendingImagePath = ""
        picking = true
        shown = false
        serial += 1
        root.preview.hide()
        pickerDelay.restart()
        return true
    }

    function chooseCustomImage() {
        pendingProfileId = ""
        return beginPicker("customImage")
    }

    function choosePhotoGrid(layout) {
        pendingProfileId = ""
        pendingGridLayout = ["feature", "grid2", "grid3", "grid4"]
            .includes(String(layout)) ? String(layout) : "grid2"
        return beginPicker("photoGrid")
    }

    function chooseFont() {
        pendingProfileId = ""
        return beginPicker("font")
    }

    function chooseAvatar() {
        pendingProfileId = ""
        return beginPicker("avatar")
    }

    function chooseBarAvatar() {
        pendingProfileId = ""
        profileAvatarError = ""
        return beginPicker("barAvatar")
    }

    function resetBarAvatar() {
        root.config.setValue("profile.avatar", "")
        if (root.shell && root.shell.unifiedTheme)
            root.shell.unifiedTheme.setProfileImagePath("")
        profileAvatarError = ""
        persistAvatarToProfile()
    }

    function persistAvatarToProfile() {
        if (!root.profileService.ready || !root.profileService.activeProfileId.length)
            return
        if (root.profileService.busy) {
            avatarProfileSaveDelay.restart()
            return
        }
        avatarProfileSavePending = true
        if (!root.profileService.updateProfile(root.profileService.activeProfileId)) {
            avatarProfileSavePending = false
            profileAvatarError = root.profileService.error || "Não foi possível salvar o perfil."
        }
    }

    function syncBarAvatar() {
        if (!root.shell || !root.shell.unifiedTheme || !root.config.ready)
            return
        const path = String(root.config.avatarPath || "")
        if (root.shell.unifiedTheme.profileImagePath !== path)
            root.shell.unifiedTheme.setProfileImagePath(path)
    }

    function importPackage() {
        pendingProfileId = ""
        return beginPicker("packageImport")
    }

    function exportPackage(profileId) {
        if (!root.profileService.profileById(profileId))
            return false
        pendingProfileId = String(profileId)
        return beginPicker("packageExport")
    }

    function basename(value) {
        const parts = String(value || "").split("/")
        return decodeURIComponent(parts.length ? parts[parts.length - 1] : "Imagem")
    }

    function pickerCommand() {
        const command = ["zenity", "--file-selection"]
        if (pendingKind === "packageExport")
            command.push("--save", "--confirm-overwrite")
        if (pendingKind === "photoGrid")
            command.push("--multiple", "--separator=|")
        command.push(pendingKind === "wallpaper"
            ? "--title=Escolha o wallpaper do perfil"
            : (pendingKind === "packageImport" ? "--title=Importar pacote Velora"
                : (pendingKind === "packageExport" ? "--title=Exportar pacote Velora"
                    : ((pendingKind === "avatar" || pendingKind === "barAvatar") ? "--title=Escolha a foto de perfil"
                        : (pendingKind === "photoGrid" ? "--title=Escolha até 16 fotos"
                            : (pendingKind === "font" ? "--title=Importar fonte"
                                : "--title=Escolha uma imagem"))))))
        command.push(pendingKind === "wallpaper"
            ? "--filename=" + config.homeDir + "/Pictures/Wallpapers/"
            : (pendingKind === "packageExport"
                ? "--filename=" + config.homeDir + "/Downloads/composicao.helixpack"
                : (pendingKind === "packageImport"
                    ? "--filename=" + config.homeDir + "/Downloads/"
                    : (pendingKind === "font"
                        ? "--filename=" + config.homeDir + "/.local/share/fonts/"
                        : "--filename=" + config.homeDir + "/Templates de imagens/"))))
        command.push(pendingKind === "wallpaper"
            ? "--file-filter=Wallpapers | *.png *.jpg *.jpeg *.webp *.gif *.mp4 *.webm *.mkv *.mov"
            : (pendingKind === "packageImport" || pendingKind === "packageExport"
                ? "--file-filter=Pacote Velora Shell | *.helixpack"
                : (pendingKind === "font"
                    ? "--file-filter=Fontes | *.ttf *.otf *.woff *.woff2"
                    : (pendingKind === "avatar" || pendingKind === "barAvatar"
                    ? "--file-filter=Foto de perfil | *.png *.jpg *.jpeg *.webp"
                    : (pendingKind === "customImage" || pendingKind === "photoGrid"
                    ? "--file-filter=Imagens estáticas ou animadas | *.png *.jpg *.jpeg *.webp *.gif *.apng"
                    : (pendingTarget === 0
                        ? "--file-filter=Personagem transparente ou animada | *.png *.webp *.gif *.apng *.mng *.mp4 *.webm *.mkv *.mov"
                        : "--file-filter=Imagens | *.png *.jpg *.jpeg *.webp"))))))
        return command
    }

    function restoreAfterPicker(exitCode) {
        if (exitCode === 0 && pendingImagePath.length > 0) {
            const selectedUrl = encodeURI("file://" + pendingImagePath)
            if (pendingKind === "wallpaper")
                root.profileService.setDraftWallpaper(selectedUrl)
            else if (pendingKind === "customImage")
                root.editor.addImage(selectedUrl, basename(pendingImagePath))
            else if (pendingKind === "photoGrid") {
                const paths = pendingImagePath.split("|").filter(function(path) {
                    return String(path).length > 0
                }).slice(0, 16)
                const items = paths.map(function(path, index) {
                    return { id: "photo-" + index, path: encodeURI("file://" + path),
                        crop: { x: 0, y: 0, width: 1, height: 1 }, flipX: false }
                })
                root.editor.addPhotoGrid(items, pendingGridLayout, "Galeria")
            } else if (pendingKind === "font" && root.editor.selectedLayerId.length) {
                root.editor.setItemStyle(root.editor.selectedLayerId,
                    "fontAsset", selectedUrl)
            }
            else if (pendingKind === "avatar" || pendingKind === "barAvatar") {
                avatarImport.command = ["python3",
                    Quickshell.shellDir + "/scripts/import-bar-avatar",
                    pendingImagePath]
                avatarImport.running = true
                return
            }
            else if (pendingKind === "packageImport")
                root.profileService.importPackage(pendingImagePath)
            else if (pendingKind === "packageExport")
                root.profileService.exportPackage(pendingProfileId, pendingImagePath)
            else if (pendingTarget === 0)
                root.config.setCharacterValue("path", selectedUrl)
            else
                root.config.setGalleryValue(pendingTarget - 1, "path", selectedUrl)
        }
        if (editSpace === "lock")
            root.preview.show()
        reopenDelay.restart()
    }

    function finishPickerRestore() {
        picking = false
        mounted = true
        Qt.callLater(function() {
            root.shown = true
            root.serial += 1
            root.opened()
        })
    }

    function status() {
        return {
            mounted: mounted,
            shown: shown,
            picking: picking,
            editSpace: editSpace,
            mode: mode,
            settingsPage: settingsPage,
            dirty: sessionDirty,
            closePrompt: closePrompt,
            lifecycle: picking ? "picking" : (!mounted ? "unloaded"
                : (shown ? "active" : "closing"))
        }
    }

    Connections {
        target: root.config
        function onConfigurationChanged() {
            if (!root.mounted || root.restoringSnapshot)
                return
            root.sessionSnapshot = root.editor.snapshot()
            root.sessionDirty = false
        }
    }

    Timer {
        id: pickerDelay
        interval: root.motion.exit + 110
        repeat: false
        onTriggered: imagePicker.running = true
    }

    Timer {
        id: reopenDelay
        interval: 90
        repeat: false
        onTriggered: root.finishPickerRestore()
    }

    Process {
        id: imagePicker
        command: root.pickerCommand()
        running: false

        stdout: SplitParser {
            onRead: function(line) { root.pendingImagePath = String(line).trim() }
        }

        onExited: function(exitCode) { root.restoreAfterPicker(exitCode) }
    }

    Process {
        id: avatarImport
        running: false
        stdout: StdioCollector { id: importedAvatarPath }
        stderr: StdioCollector { id: avatarImportError }
        onExited: function(exitCode) {
            running = false
            const path = importedAvatarPath.text.trim()
            if (exitCode === 0 && path.startsWith("/")) {
                const url = encodeURI("file://" + path)
                root.config.setValue("profile.avatar", url)
                if (root.shell && root.shell.unifiedTheme)
                    root.shell.unifiedTheme.setProfileImagePath(url)
                root.profileAvatarError = ""
                root.persistAvatarToProfile()
            } else {
                root.profileAvatarError = avatarImportError.text.trim()
                    || "Não foi possível salvar a foto de perfil."
            }
            reopenDelay.restart()
        }
    }

    Connections {
        target: root.config
        function onAvatarPathChanged() { root.syncBarAvatar() }
        function onReadyChanged() { if (root.config.ready) root.syncBarAvatar() }
    }

    Connections {
        target: root.profileService
        function onProfileApplied() { root.syncBarAvatar() }
        function onOperationFinished(operation, ok, message) {
            if (operation !== "update" || !root.avatarProfileSavePending)
                return
            root.avatarProfileSavePending = false
            if (!ok)
                root.profileAvatarError = message || "Não foi possível salvar o perfil."
        }
    }

    Timer {
        id: avatarProfileSaveDelay
        interval: 250
        repeat: false
        onTriggered: root.persistAvatarToProfile()
    }

    Timer {
        id: spaceSwitchTimer
        interval: Math.max(root.motion.widgetOpen, root.motion.widgetExit) + 80
        repeat: false
        onTriggered: root.switchingSpace = false
    }

    Timer {
        id: closeTimer
        interval: root.mode === "settings" ? root.motion.contentExit + root.motion.closeDuration + 30 : root.motion.exit + 80
        repeat: false
        onTriggered: {
            root.mounted = false
            root.shown = false
            root.serial += 1
            root.closed()
        }
    }
}
