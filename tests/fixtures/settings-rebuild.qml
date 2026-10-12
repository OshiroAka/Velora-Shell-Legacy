import QtQuick
import QtQuick.Window
import Quickshell
import "../../core" as Core
import "../../services" as Services
import "../../components" as Components
import "../../features/editor" as Editor
import "../../features/editor/SettingsCatalog.js" as Catalog

ShellRoot {
    id: test
    Core.ConfigStore { id: config }
    Core.Theme { id: theme; config: config; palette: null }
    Core.Motion { id: motion; config: config }
    Core.PreviewController { id: preview; motion: motion; keepWarm: false }
    Components.VeloraTheme { id: historical }
    Services.SceneEditorService { id: scene; config: config }
    QtObject {
        id: wallpaper
        property string currentPath: ""
        property string currentPreviewPath: ""
        property string error: ""
        function applyWallpaper(path) { currentPath=path; return true }
    }
    QtObject {
        id: profiles
        signal profileApplied()
        signal operationFinished(string operation, bool ok, string message)
        property var wallpaperService: wallpaper
        property string activeProfileId: ""
        property var profiles: []
        property string error: ""
    }
    QtObject {
        id: shell
        property bool barOnRight: false
        property int bottomBarHeight: 18
        property var unifiedTheme: historical
        property var composition: null
        function openLyricsMaskEditor() { }
    }
    QtObject { id: wallpaperStore; property string activeKey: "fixture" }
    Core.SettingsController { id: controller; config: config; editor: scene; motion: motion; preview: preview; profileService: profiles; shell: shell }
    Window {
        id: window
        width: 1440; height: 900; visible: true; color: "#1b424b"
        Editor.EditorChrome {
            id: chrome; anchors.fill: parent; config: config; controller: controller; editor: scene
            theme: theme; motion: motion; profileService: profiles; wallpaperStore: wallpaperStore
            presented: controller.shown
        }
    }
    function assert(value, message) { if (!value) throw new Error(message) }
    function find(item, name) {
        if (!item) return null
        if (item.objectName === name || item.label === name) return item
        const list=item.children||[]
        for(let i=0;i<list.length;i++) { const result=find(list[i],name); if(result) return result }
        return null
    }
    property var destinations: Catalog.categories.map(entry=>entry.id)
    property int step: -1
    property bool beforeGlass: false
    property int searchIndex: -1
    property var searchable: Catalog.entries.filter(entry => !entry.action)
    property var missingTargets: []
    Timer {
        interval: test.step > test.destinations.length+13 ? 30 : 500; running: true; repeat: true
        onTriggered: {
            if (!config.ready) return
            try {
                test.step++
                const home=chrome.settingsItem
                if (test.step === 0) {
                    if (Quickshell.env("VELORA_SETTINGS_RELOAD") === "1") {
                        assert(config.customColors.text === "#c0ffee", "manual palette survives restart")
                        assert(config.reflectionStrength === 0 && config.blurStrength === 0, "zero endpoints survive restart")
                        assert(!controller.integrations, "closed session does not construct helpers")
                        console.info("SETTINGS_REBUILD_OK reload"); Qt.quit(); return
                    }
                    assert(Catalog.search("reflexos").some(entry=>entry.id==="appearance.reflection"),"reflection search")
                    assert(Catalog.search("aparencia").length>0,"accent insensitive search")
                    assert(Catalog.search("blur").length>=4,"blur options search")
                    config.setValue("appearance.reducedMotion",true)
                    controller.show("desktop")
                } else if (test.step <= destinations.length) {
                    if (home.page === "bar") {
                        const slider=find(home,"settingsSlider")
                        assert(!!slider && slider.height >= 28,"slider has a usable hit area")
                    }
                    controller.setSettingsPage(destinations[test.step-1])
                } else if (test.step === destinations.length+1) {
                    for (const material of ["solid", "glass", "liquid"]) {
                        config.setValue("bar.material",material)
                        assert(home.liquidMaterial === (material === "liquid"),"refraction follows bar material")
                        assert(home.blurMaterial === (material !== "solid"),"blur follows bar material")
                        assert(home.surfaceTint === theme.barSurface,"settings inherit bar tint and opacity")
                    }
                    config.setValue("appearance.reduceTransparency",true)
                    assert(!home.liquidMaterial && !home.blurMaterial && home.surfaceTint.a === 1,"reduced transparency suppresses optics")
                    config.setValue("appearance.reduceTransparency",false)
                    controller.setSettingsPage("wallpapers")
                    home.section="selector"
                } else if (test.step === destinations.length+2) {
                    assert(home.height < 600,"short selector page keeps a large empty surface")
                    assert(home.y+home.height<=window.height,"adapted surface leaves the output")
                    const glass=find(home,"wallpaperSelectorGlassToggle")
                    assert(!!glass,"canonical glass toggle mounted")
                    beforeGlass=config.wallpaperSelectorGlassEnabled
                    glass.triggered()
                    assert(config.wallpaperSelectorGlassEnabled !== beforeGlass,"glass updates ConfigStore")
                    assert(controller.integrations.wallpaperSelectorGlassEnabled===config.wallpaperSelectorGlassEnabled,"adapter shares the same state")
                    controller.integrations.setWallpaperSelectorGlass(beforeGlass)
                    assert(config.wallpaperSelectorGlassEnabled===beforeGlass,"legacy operation updates same state")
                    config.setValue("appearance.reflection",0)
                    config.setValue("appearance.blurStrength",0)
                    controller.setSettingsPage("appearance")
                } else if (test.step === destinations.length+3) {
                    const manual=find(home,"Cor manual")
                    assert(!!manual,"manual palette preserved")
                    manual.triggered()
                    config.setCustomColor("text","#c0ffee")
                    controller.setSettingsPage("media"); home.section="velyrics"
                } else if (test.step === destinations.length+4) {
                    home.section="style"
                } else if (test.step === destinations.length+5) {
                    home.section="position"
                } else if (test.step === destinations.length+6) {
                    home.section="material"
                } else if (test.step === destinations.length+7) {
                    controller.setSettingsPage("bar"); home.section="sidebar"
                } else if (test.step === destinations.length+8) {
                    controller.setSettingsPage("motion")
                    config.setValue("appearance.reducedMotion",false)
                } else if (test.step === destinations.length+9) {
                    assert(!home.animating,"animations settle")
                    home.contentItem.revealSetting("wallpaper.transition")
                } else if (test.step === destinations.length+10) {
                    assert(home.page === "wallpapers" && home.section === "transitions", "context link opens the transitions subsection")
                    controller.hide()
                } else if (test.step === destinations.length+11) {
                    assert(!controller.mounted,"close unmounts")
                    assert(!controller.integrations,"settings-only backend released")
                    controller.show("desktop")
                } else if (test.step === destinations.length+12) {
                    controller.setSettingsPage("motion")
                    controller.setSettingsPage("wallpapers")
                } else if (test.step === destinations.length+13) {
                    assert(home.page==="wallpapers","rapid retarget final page")
                    assert(!home.animating,"retarget settles")
                    config.setValue("appearance.reducedMotion",true)
                } else if (test.step > destinations.length+13) {
                    if (searchIndex >= 0) {
                        const result=searchable[searchIndex]
                        const target=home.findTarget(home.contentItem,result)
                            || (result.fallbackLabel && home.findTarget(home.contentItem,{label:result.fallbackLabel}))
                        if (!target) missingTargets.push(result.id)
                    }
                    searchIndex++
                    if (searchIndex < searchable.length) {
                        home.selectResult(searchable[searchIndex])
                        return
                    }
                    assert(missingTargets.length===0,"missing search targets: "+missingTargets.join(", "))
                    window.contentItem.grabToImage(result=> {
                        const path=Quickshell.env("VELORA_SETTINGS_SCREENSHOT")
                        if(path)result.saveToFile(path)
                        console.info("SETTINGS_REBUILD_OK",JSON.stringify({pages:destinations.length,reflection:config.reflectionStrength,blur:config.blurStrength,pending:config.savePending}))
                        Qt.quit()
                    })
                    running=false
                }
            } catch(error) { console.error("SETTINGS_REBUILD_FAILED",String(error),error.stack); Qt.quit() }
        }
    }
    Timer { interval: 23000; running: true; onTriggered: {console.error("SETTINGS_REBUILD_FAILED timeout");Qt.quit()} }
}
