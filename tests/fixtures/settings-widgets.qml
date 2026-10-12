import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../core" as Core
import "../../services" as Services
import "../../components" as Components
import "../../features/editor" as Editor

ShellRoot {
    id: test
    Core.ConfigStore { id: config }
    Core.Theme { id: theme; config: config; palette: null }
    Core.Motion { id: motion; config: config }
    Services.SceneEditorService { id: editor; config: config }
    Components.VeloraTheme { id: historical }
    QtObject {
        id: controller
        property int chosenImage: -1
        property string editing: ""
        function beginEditing(space) { editing=space; editor.setEditSpace(space) }
        function chooseImage(index) { chosenImage=index }
        function setSettingsPage(page) { }
    }
    Window {
        id: window; width: 960; height: 1000; visible: true; color: "#20232b"
        Editor.SettingsWidgets {
            id: widgets; x: 20; y: 20; width: window.width-40
            config: config; theme: theme; motion: motion; editor: editor; controller: controller
            legacyTheme: historical
        }
        TestCase { id: input; when: false }
    }
    function assert(value, message) { if (!value) throw new Error(message) }
    function find(item, name) {
        if (item.objectName === name || item.label === name) return item
        for (const child of item.children || []) { const found=find(child,name); if(found) return found }
        return null
    }
    property int step: 0
    property bool originalLock: false
    property bool originalDesktop: false
    property var savedChoices: []
    Timer {
        interval: 250; running: true; repeat: true
        onTriggered: {
            if (!config.ready) return
            try {
                if (step === 0) {
                    config.setValue("appearance.reducedMotion",true)
                    originalDesktop=config.sharedWidgets[0].desktopEnabled
                    originalLock=config.sharedWidgets[0].lockEnabled
                    const media=find(widgets,"widgetCard.media")
                    input.mouseClick(media,media.width/2,40)
                    assert(widgets.selectedKind === "media","thumbnail selects context")
                    assert(config.sharedWidgets[0].desktopEnabled === originalDesktop,"selecting does not toggle")
                    const toggle=find(widgets,"widget.clock.desktop")
                    input.mouseClick(toggle,toggle.width/2,toggle.height/2)
                    assert(config.sharedWidgets[0].desktopEnabled !== originalDesktop,"switch click toggles visibility")
                    assert(widgets.selectedKind === "media","switch does not select parent card")
                    assert(config.sharedWidgets[0].lockEnabled === originalLock,"desktop switch preserves lock")
                    savedChoices=config.sharedWidgets.map(item=>item.desktopEnabled)
                    const master=find(widgets,"desktopWidgetsToggle")
                    input.mouseClick(master,master.width-20,18)
                    assert(JSON.stringify(savedChoices) === JSON.stringify(config.sharedWidgets.map(item=>item.desktopEnabled)),"master preserves choices")
                    widgets.space="lock"
                } else if (step === 1) {
                    const toggle=find(widgets,"widget.clock.lock")
                    toggle.forceActiveFocus()
                    input.keyClick(Qt.Key_Space)
                    assert(config.sharedWidgets[0].lockEnabled !== originalLock,"keyboard switch changes lock")
                    assert(config.sharedWidgets[0].desktopEnabled === savedChoices[0],"lock switch preserves desktop")
                    widgets.prepareResult({id:"scene.gallery.2"})
                } else if (step === 2) {
                    const photo=find(widgets,"scene.gallery.2")
                    assert(!!photo && photo.visible,"search opens gallery controls")
                    input.mouseClick(photo,photo.width/2,photo.height/2)
                    assert(controller.chosenImage === photo.assetIndex+1,"gallery retains mapped picker destination")
                    const link=find(widgets,"Posição e estilo ↗")
                    input.mouseClick(link,link.width/2,link.height/2)
                    assert(controller.editing === "lock" && editor.selectedLayerId === widgets.selectedWidget.id,"editor receives selected widget and space")
                    widgets.space="desktop"
                    widgets.prepareResult({id:"legacy.visualizer-mode"})
                } else if (step === 3) {
                    assert(!find(widgets,"scene.gallery.2"),"leaving gallery destroys image previews")
                    const tabs=find(widgets,"legacy.visualizer-mode")
                    assert(!!tabs,"search reveals visualizer context")
                    const wave=find(tabs,"Wave")
                    wave.forceActiveFocus()
                    input.keyClick(Qt.Key_Right)
                    assert(historical.visualizerMode === "pixels","arrow selects exclusive mode")
                    window.width=520
                } else if (step === 4) {
                    assert(widgets.columns === 2,"compact grid wraps")
                    for(const kind of ["clock","calendar","weather","media","gallery","system","visualizer","frame"]) {
                        const card=find(widgets,"widgetCard."+kind)
                        const point=card.mapToItem(widgets,0,0)
                        assert(point.x>=0 && point.x+card.width<=widgets.width+.5,"card stays within content: "+kind)
                    }
                    widgets.prepareResult({id:"legacy.frame-opacity"})
                } else if (step === 5) {
                    assert(!!find(widgets,"legacy.frame-opacity"),"frame context preserved")
                    assert(!find(widgets,"legacy.visualizer-mode"),"inactive context unloaded")
                    assert(!config.savePending,"writes settle")
                    console.info("SETTINGS_WIDGETS_OK pointer keyboard contexts responsive persistence")
                    Qt.quit()
                }
                step++
            } catch(error) { console.error("SETTINGS_WIDGETS_FAILED",String(error),error.stack);Qt.quit() }
        }
    }
    Timer { interval: 9000; running: true; onTriggered: {console.error("SETTINGS_WIDGETS_FAILED timeout");Qt.quit()} }
}
