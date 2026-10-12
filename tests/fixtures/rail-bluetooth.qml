import QtQuick
import Quickshell
import "components" as Components
import "services" as Services

ShellRoot {
    id: test
    property int stage: 0
    property int ticks: 0
    function check(ok, message) { if (!ok) throw new Error(message) }
    function find(item, name) {
        if (item.objectName === name) return item
        for (const child of item.children || []) { const found = find(child, name); if (found) return found }
        return null
    }
    QtObject { id: theme }
    QtObject {
        id: fakeManager
        property bool available: true
        property bool powered: true
        property bool scanning: false
        property bool busy: false
        property bool needsPin: false
        property string pairPrompt: ""
        property string error: ""
        property int scans: 0
        property int pairs: 0
        property int removals: 0
        property var devices: [
            {address: "headset", name: "QCY H3", icon: "audio-headset", paired: true, connected: true},
            {address: "phone", name: "Phone", icon: "phone", paired: false, connected: false}
        ]
        function scan() { scans++; scanning = true }
        function stopScan() { scanning = false }
        function pair(address) { pairs++ }
        function remove(address) { removals++ }
        function cancel() { busy = false }
    }
    Item {
        width: 800; height: 600
        Components.VeloraRailBluetooth {
            id: menu
            anchors.fill: parent
            theme: theme
            manager: fakeManager
            anchorY: 280
        }
    }
    QtObject { id: adapter; property bool enabled: true; property bool discovering: false }
    Services.RailBluetoothService {
        id: service
        adapter: adapter
        controlScript: Quickshell.shellDir + "/mock-bluetooth"
    }
    Timer {
        interval: 400; running: true; repeat: true
        onTriggered: {
            if (++test.ticks > 45) { console.error("RAIL_BLUETOOTH_FAILED timeout", test.stage); Qt.quit(); return }
            try {
                switch (test.stage) {
                case 0:
                    test.check(fakeManager.scans === 0, "hover must not start discovery")
                    test.check(menu.knownDevices.length === 1, "only paired/connected devices in compact menu")
                    menu.triggerHovered = true
                    break
                case 1:
                    test.check(menu.opened && menu.reveal > 0.98, "hover opens menu")
                    menu.showName(fakeManager.devices[0], 44)
                    break
                case 2:
                    test.check(menu.nameReveal > 0.98 && menu.deviceName === "QCY H3", "name extends from device")
                    test.check(menu.iconFor(fakeManager.devices[0]) === "headphones", "device icon")
                    test.find(menu, "bluetoothAdd").clicked()
                    test.check(fakeManager.scans === 1 && menu.managing, "plus starts search")
                    break
                case 3: {
                    const remove = test.find(menu, "bluetoothActionheadset")
                    remove.clicked()
                    test.check(fakeManager.removals === 0 && menu.removeAddress === "headset", "removal requires confirmation")
                    remove.clicked()
                    test.check(fakeManager.removals === 1, "confirmed removal dispatched")
                    test.find(menu, "bluetoothActionphone").clicked()
                    test.check(fakeManager.pairs === 1, "pair dispatch")
                    menu.triggerHovered = false; menu.close()
                    break
                }
                case 4:
                    test.check(!menu.mounted && !menu.managing && !fakeManager.scanning, "close releases discovery and manager")
                    service.scan(); test.check(adapter.discovering, "scan starts")
                    service.stopScan(); test.check(!adapter.discovering, "own scan stops")
                    adapter.discovering = true; service.scan(); service.stopScan()
                    test.check(adapter.discovering, "external scan remains owned by its client")
                    adapter.discovering = false
                    service.pair("success")
                    break
                case 5:
                    if (!service.pairPrompt) return
                    test.check(service.busy && service.pairPrompt.indexOf("123456") >= 0, "pair confirmation without newline")
                    service.answer("yes")
                    break
                case 6:
                    if (service.busy) return
                    test.check(service.error === "" && service.pairPrompt === "", "pair success")
                    service.remove("failure")
                    break
                case 7:
                    if (service.busy) return
                    test.check(service.error.length > 0, "remove error surfaced")
                    service.pair("failure")
                    break
                case 8:
                    if (service.busy) return
                    test.check(service.error.length > 0, "pair failure with zero exit code surfaced")
                    service.pair("success")
                    break
                case 9:
                    if (!service.pairPrompt) return
                    service.cancel()
                    break
                case 10:
                    test.check(!service.busy && !service.pairPrompt, "pair cancellation clears session")
                    adapter.enabled = false; service.scan()
                    test.check(!adapter.discovering && service.error.length > 0, "disabled adapter reported")
                    console.info("RAIL_BLUETOOTH_OK"); Qt.quit(); return
                }
                test.stage++
            } catch (error) { console.error("RAIL_BLUETOOTH_FAILED", test.stage, error.message); Qt.quit() }
        }
    }
}
