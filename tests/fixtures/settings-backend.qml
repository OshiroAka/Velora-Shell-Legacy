import QtQuick
import Quickshell
import "../../core" as Core
import "../../components" as Components
import "../../services" as Services
ShellRoot {
    id: root
    Core.ConfigStore { id: config }
    Core.Motion { id: motion; config: config }
    Core.PreviewController { id: preview; motion: motion; keepWarm: false }
    Services.SceneEditorService { id: editor; config: config }
    Components.VeloraTheme { id: historical }
    QtObject {
        id: wallpaper
        property bool ready: true
        property string currentPath: "/tmp/fixture-wallpaper-a.png"
        function localPath(path) { return String(path).replace("file://", "") }
    }
    QtObject {
        id: profiles
        property var wallpaperService: wallpaper
        property string activeProfileId: ""
        signal profileApplying(string profileId)
        signal profileApplied(string profileId)
        signal operationFinished(string operation, bool ok, string message)
    }
    QtObject { id: shell; property var unifiedTheme: historical; property var composition: null }
    Core.SettingsController { id: controller; motion: motion; config: config; preview: preview; editor: editor; profileService: profiles; shell: shell }
    Services.WallpaperCompositionService { id: store; config: config; wallpaperService: wallpaper; profileService: profiles }
    Services.VisualizerDemand { id: demand }
    Components.VeloraSettingsPanel { id: fallback; visible: false; theme: historical; config: config }
    property int nativeSyncs: 0
    property int savedScenes: 0
    property int baselineSaves: 0
    property var sceneSnapshot: null
    function syncNativeAppearance() { nativeSyncs++ }
    function syncLiquidStyle() {}
    function syncBarBlur() {}
    function syncWallpaperEffects() {}
    // The test runner inserts the production Connections and debounce timer.
    // APPEARANCE_SYNC
    Connections { target: store; function onCompositionSaved() { root.savedScenes++ } }
    Timer {
        id: appearanceEdit; interval: 1000
        onTriggered: {
            root.nativeSyncs=0; root.baselineSaves=root.savedScenes
            config.setValue("appearance.reflection",0.21)
        }
    }
    property int step: 0
    function check(ok, message) { if (!ok) throw new Error(message) }
    Timer {
        interval: root.step === 0 ? 1200 : root.step === 1 ? 1600 : 400; running: true; repeat: true
        onTriggered: {
            if (!config.ready || !store.ready) return
            try {
                if (root.step === 0) {
                    check(config.userData.customAuditKey === "keep", "unknown legacy key preserved")
                    const invalid=config.parse("{bad", "fixture", config.userData)
                    check(!invalid.ok && invalid.data.customAuditKey === "keep", "malformed config preserves prior state")
                    for (let bits=0; bits<32; bits++) {
                        demand.desktopEnabled=!!(bits&1); demand.editingDesktop=!!(bits&2)
                        demand.lockOccluding=!!(bits&4); demand.railVisible=!!(bits&8); demand.mediaPlaying=!!(bits&16)
                        const expected=(!!(bits&1)&&!(bits&2)&&!(bits&4)) || !!(bits&4) || (!!(bits&8)&&!!(bits&16)&&!(bits&4))
                        check(demand.active===expected,"visualizer demand "+bits)
                    }
                    demand.desktopEnabled=false;demand.lockOccluding=false;demand.mediaPlaying=false
                    check(!demand.active,"no consumer suspends capture demand")
                    demand.mediaPlaying=true;check(demand.active,"new consumer immediately reactivates demand")
                    fallback.moveSelection(1); check(fallback.activePage === "bar", "historical navigation API preserved")
                    controller.show("desktop"); controller.setSettingsPage("system")
                    config.setValue("appearance.reducedMotion",true)
                    // Opening an old config can normalize its desktop template.
                    // Wait for that independent migration before measuring appearance.
                    appearanceEdit.start()
                } else if (root.step === 1) {
                    check(controller.mounted && root.nativeSyncs>0,"native appearance syncs while mounted")
                    check(controller.integrations.hyprlandBlurState===1,"global blur read")
                    controller.integrations.setHyprlandBlur(false)
                } else if (root.step === 2) {
                    check(controller.integrations.operationError.indexOf("fixture failure")>=0,"external failure visible")
                    check(root.savedScenes===root.baselineSaves,"appearance does not save scene-only document")
                    controller.integrations.setHyprlandBlur(true)
                    controller.hide()
                } else if (root.step === 3) {
                    check(!controller.mounted && !!controller.integrations,"closing retains pending write")
                    controller.show("desktop"); controller.setSettingsPage("bar")
                } else if (root.step === 4) {
                    check(controller.integrations.operationError==="","successful retry clears error")
                    controller.hide()
                    const id=editor.addText("persisted fixture")
                    editor.setTransform(id,"x",432)
                    store.saveActive();root.sceneSnapshot=store.document.wallpapers[store.activeKey].composition
                    check(!root.sceneSnapshot.appearance && !root.sceneSnapshot.topbar,"scene-only contract")
                    config.setCustomColor("text","#c0ffee");editor.addText("discarded fixture")
                    store.applyScene(root.sceneSnapshot,"fixture")
                    check(config.customColors.text==="#c0ffee","wallpaper restore keeps palette")
                    check(config.sceneLayers.filter(layer=>layer.text==="discarded fixture").length===0,"scene restored")
                } else if (root.step === 6) {
                    check(!controller.integrations,"no settings backend after writes settle")
                    check(!config.savePending,"configuration flushed")
                    console.info("SETTINGS_BACKEND_OK");Qt.quit()
                }
                root.step++
            } catch(error) { console.error("SETTINGS_BACKEND_FAILED",String(error));Qt.quit() }
        }
    }
    Timer { interval: 15000; running: true; onTriggered: {console.error("SETTINGS_BACKEND_FAILED timeout");Qt.quit()} }
}
