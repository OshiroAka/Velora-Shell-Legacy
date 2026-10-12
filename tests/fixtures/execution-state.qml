import QtQuick
import Quickshell
import "services" as Services

ShellRoot {
    id: root
    property bool failed: false
    function check(value, message) { if (!value) { failed = true; console.error("EXECUTION_TEST_FAILED", message) } }
    Services.ExecutionStatusService { id: service }
    Timer {
        interval: 20; running: true
        onTriggered: {
            root.check(!service.shown, "No invented execution on startup")
            root.check(!service.update("invalid"), "Malformed input")
            const event = {id: "fixture", agent: "Fixture", phase: "running", label: "Teste", ttlMs: 1000}
            root.check(service.update(JSON.stringify(event)), "Accept running event")
            root.check(service.shown && service.current.progress === -1, "Unknown progress must remain unknown")
            root.check(!service.update(JSON.stringify(Object.assign({}, event, {progress: 2}))), "Reject invalid progress")
            root.check(!service.update(JSON.stringify(Object.assign({}, event, {id: "old", phase: "completed"}))), "Ignore late completion")
            root.check(!service.clear("wrong-id") && service.shown, "Identity-safe clearing")
            root.check(service.update(JSON.stringify(Object.assign({}, event, {phase: "waiting", progress: 0.3}))), "Accept real progress/wait")
            root.check(!service.busy, "Waiting is not running")
            expiryCheck.start()
        }
    }
    Timer {
        id: expiryCheck; interval: 1150
        onTriggered: {
            root.check(!service.shown, "Expired producer must not remain active")
            if (!root.failed) console.info("EXECUTION_TEST_OK")
            Qt.quit()
        }
    }
}
