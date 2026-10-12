import QtQuick
import Quickshell
import "../../components" as Components
import "../../features/topbar" as TopBar
import "../../core" as Core
import "../../features/editor" as Editor
import "../../services" as Services
import "../../platform" as Platform

Scope {
Item {
    id: fixture
    width: 1920; height: 1200
    Core.Motion { id: motion; reduced: true }
    Core.ConfigStore { id: configuration }
    Core.Theme { id: palette; config: configuration; palette: null }
    Services.SceneEditorService { id: editor; config: configuration }
    QtObject { id: profiles; property var profiles: []; property string activeProfileId: "" }
    QtObject { id: wallpaperStore; property string activeKey: "" }
    QtObject {
        id: settingsController
        property string mode: "editing"
        property string editSpace: "desktop"
        property string settingsPage: "desktop"
        property string profileAvatarError: ""
        property bool closePrompt: false
        property bool shown: true
        property var shell: ({barOnRight: rail.rightSide})
        function setSettingsPage(page) { settingsPage = page }
        function hide() {}
    }
    QtObject { id: controller; property var anchorItem: null; function close() {} }
    Item { id: anchor; x: fixture.width - 36; width: 36; height: 40 }
    Components.VeloraRailPopover {
        id: rail
        anchors.fill: parent
        theme: ({}); system: ({}); motion: motion
        preferredWidth: 920; preferredHeight: 650
        contentPadding: 24
        customContent: Component { Item { property bool interactionHeld: false } }
    }
    TopBar.MorphPopover {
        id: popup
        anchors.fill: parent
        motion: motion; controller: controller
        desiredType: "clock"
        leftInset: rail.rightSide ? 8 : 72
        rightInset: rail.rightSide ? 72 : 8
        Item { anchors.fill: parent }
    }
    Editor.EditorChrome {
        id: chrome
        anchors.fill: parent
        controller: settingsController; config: configuration
        theme: palette; editor: editor; profileService: profiles
        wallpaperStore: wallpaperStore; motion: motion; presented: true
    }
    Item {
        id: validation
        property int position: 0
        property int phase: 0
        readonly property var cases: test_resolution_changes_data()
        function verify(value, message) { if (!value) throw Error(message || "geometry outside logical surface") }
        function test_resolution_changes_data() {
            const data = []
            for (const size of [[1280,800],[1366,768],[1600,900],[1920,1080],[1920,1200],[2560,1440]])
                for (const right of [false,true]) {
                    data.push({tag:"logical-"+size[0]+"x"+size[1]+"-"+right,width:size[0],height:size[1],right:right})
                    for (const scale of [1,1.25,1.5,2])
                    data.push({tag:size[0]+"x"+size[1]+"@"+scale+"-"+right,width:size[0]/scale,height:size[1]/scale,right:right})
                }
            return data
        }
        function test_resolution_changes(data) {
            fixture.width = data.width; fixture.height = data.height - 40
            rail.rightSide = data.right
            rail.anchorY = fixture.height - 8
            rail.open()
            controller.anchorItem = anchor
            popup.anchorX = fixture.width - 18
            verify(rail.targetWidth + 64 + 16 <= fixture.width + .01)
            verify(rail.bodyY >= 0 && rail.bodyY + rail.bodyHeight <= fixture.height + .01)
            verify(popup.panelRect.x >= popup.leftInset)
            verify(popup.panelRect.x + popup.panelRect.width <= fixture.width - popup.rightInset + .01)
            verify(popup.panelRect.y + popup.panelRect.height <= fixture.height + .01)
            // Content retains its preferred dimensions inside a bounded,
            // scrollable viewport instead of losing fixed-size controls.
            verify(rail.contentMinimumWidth >= rail.targetWidth - 48)
            verify(rail.contentMinimumHeight >= rail.targetHeight - 48)
            for (const item of [chrome.toolBarItem, chrome.inspectorItem, chrome.catalogItem,
                               chrome.profilesItem, chrome.barItem, chrome.layersItem, chrome.settingsItem]) {
                const bounds = chrome.surfaceArea
                verify(item.x >= bounds.x - .01 && item.x + item.width <= bounds.x + bounds.width + .01, "horizontal " + JSON.stringify({x:item.x,width:item.width,bounds:bounds}))
                verify(item.y >= bounds.y - .01 && item.y + item.height <= bounds.y + bounds.height + .01, "vertical " + JSON.stringify({y:item.y,height:item.height,bounds:bounds}))
            }
        }
        function test_resize_during_handoff() {
            fixture.width = 640; fixture.height = 344
            rail.handoffFromWidth = 920; rail.handoffFromHeight = 650
            rail.handoffFromY = 900; rail.handoffActive = true
            rail.handoffProgress = .25; rail.reveal = 1
            verify(rail.bodyWidth <= fixture.width - 80)
            verify(rail.bodyHeight <= fixture.height - 48)
            verify(rail.bodyY + rail.bodyHeight <= fixture.height)
        }
        function test_native_capability_recovery() {
            const service = Platform.NativeBlur
            service.applyStatus({available:true,state:"ready",capabilities:["bar-blur","desktop-bar-material"]})
            verify(!service.supportsBarMaterial(null) && !service.supportsBarMaterial({}))
            verify(service.supports("bar-blur"), "missing spectrum API must preserve other native effects")
            verify(service.supportsBarMaterial({materialFrame:function() { return "frame" }}))
            service.applyStatus({available:true,state:"ready",capabilities:["bar-blur"]})
            verify(!service.supportsBarMaterial({materialFrame:function() { return "frame" }}))
            service.applyStatus({available:false,state:"absent",diagnostic:"fixture fallback"})
            const revision = service.revision
            service.applyStatus({available:false,state:"absent",diagnostic:"fixture fallback"})
            verify(service.revision === revision, "identical failures must not resynchronize/spam")
            verify(!service.supports("bar-blur"))
            service.dispatch("velora-blur:bar-blur 1")
            service.applyStatus({available:true,state:"ready",running:{abiHash:"fixture"},capabilities:["bar-blur"]})
            verify(service.supports("bar-blur") && !service.supports("editor-shape"))
            service.dispatch("velora-blur:editor-shape 0")
            service.applyStatus({available:false,state:"absent",diagnostic:"fixture fallback"})
            verify(!service.supports("bar-blur"))
            service.applyStatus({available:true,state:"ready",running:{abiHash:"fixture"},capabilities:["bar-blur","editor-shape"]})
            verify(service.supports("bar-blur") && service.supports("editor-shape"))
            const generation = service.generation
            service.suspend()
            verify(!service.supports("bar-blur") && service.generation > generation)
            service.dispatch("velora-blur:bar-blur 1")
            service.applyStatus({available:true,state:"ready",capabilities:["bar-blur"]})
            verify(!service.available, "stale status must not reactivate a suspended plugin")
            service.resume()
            service.applyStatus({available:true,state:"ready",capabilities:["bar-blur"]})
            verify(service.supports("bar-blur"))
            service.suspend()
            service.suspendedSince = Date.now() - 61000
            service.refresh()
            verify(!service.suspended && !service.available, "interrupted reload must return to capability probing")
            service.applyStatus({available:true,state:"ready",capabilities:["bar-blur"]})
            verify(service.supports("bar-blur"))
            service.lifecycle("unloaded")
            verify(!service.available && !service.supports("bar-blur"))
            service.applyStatus({available:false,state:"absent",diagnostic:"fixture fallback"})
            service.lifecycle("ready")
            service.applyStatus({available:true,state:"ready",capabilities:["bar-blur"]})
            verify(service.supports("bar-blur"))
        }
        Timer {
            interval: 16; running: true; repeat: true
            onTriggered: {
                try {
                    if (!configuration.ready) return
                    if (validation.position < validation.cases.length) {
                        const data = validation.cases[validation.position]
                        if (validation.phase === 0) {
                            fixture.width = data.width; fixture.height = data.height - 40
                            rail.rightSide = data.right; rail.anchorY = fixture.height - 8
                            rail.open(); controller.anchorItem = anchor; popup.anchorX = fixture.width - 18
                            validation.phase = 1
                        } else {
                            validation.test_resolution_changes(data)
                            validation.position++; validation.phase = 0
                        }
                    } else {
                        validation.test_resize_during_handoff()
                        validation.test_native_capability_recovery()
                        console.log("GEOMETRY_RESULT " + JSON.stringify({passed:true,cases:validation.position,
                            devicePixelRatio:Quickshell.screens[0].devicePixelRatio}))
                        Qt.quit()
                    }
                } catch (error) {
                    console.log("GEOMETRY_RESULT " + JSON.stringify({passed:false,case:validation.position,error:String(error)}))
                    Qt.quit()
                }
            }
        }
    }
}
}
