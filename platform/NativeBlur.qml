pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// One capability check for every native consumer. Compositor blur stays active
// while this optional plugin is absent; loading it later resynchronizes shapes.
Scope {
    id: root
    property bool available: false
    property var capabilities: []
    property var state: ({available: false, loaded: false, state: "checking", diagnostic: ""})
    property int revision: 0
    property string identity: ""
    property bool suspended: false
    property double suspendedSince: 0
    property bool pendingRefresh: false
    property int generation: 0
    property int probeGeneration: -1
    function supports(name) { return available && !suspended && capabilities.indexOf(name) >= 0 }
    function supportsBarMaterial(visualizer) {
        return supports("desktop-bar-material") && !!visualizer
            && typeof visualizer.materialFrame === "function"
    }
    function dispatch(command) {
        const name = String(command).split(" ")[0].replace("velora-blur:", "")
        if (!supports(name)) return
        if (supports("lua-dispatch")) {
            // Lua configs require a callable dispatcher, not legacy text.
            // JSON strings quote monitor names/arguments without evaluating them.
            const arguments = String(command).slice(String(command).indexOf(" ") + 1)
            Hyprland.dispatch("function() hl.plugin.velora.dispatch("
                + JSON.stringify(name) + "," + JSON.stringify(arguments) + ") end")
        } else Hyprland.dispatch(command)
    }
    function refresh() {
        // Recover if the loader was interrupted before its finally/resume IPC.
        if (suspended && Date.now() - suspendedSince >= 60000) suspended = false
        if (suspended || Quickshell.env("VELORA_VALIDATE") === "1") return
        if (probe.running) { pendingRefresh = true; return }
        pendingRefresh = false
        probeGeneration = generation
        probe.running = true
    }
    function suspend() {
        if (suspended) return
        suspended = true
        suspendedSince = Date.now()
        generation += 1
        available = false
        capabilities = []
        state = Object.assign({}, state, {available: false, capabilities: [],
            state: "reloading", diagnostic: "Reconectando efeitos nativos."})
        identity = ""
        revision += 1
    }
    function resume() {
        suspended = false
        refresh()
    }
    function lifecycle(value) {
        if (value === "unloaded") {
            const wasSuspended = suspended
            suspend()
            if (!wasSuspended) resume()
        } else if (value === "ready") {
            refresh()
        }
    }
    function applyStatus(value) {
        if (suspended) return
        const next = JSON.stringify([value.available, value.capabilities || [],
            value.running && (value.running.abiHash || value.running.commit), value.state, value.diagnostic])
        state = value
        capabilities = value.capabilities || []
        available = value.available === true
        if (next !== identity) {
            identity = next
            revision += 1
            if (!available && value.diagnostic) console.warn("Velora blur: " + value.diagnostic)
        }
    }
    Component.onCompleted: refresh()
    // Keep native lifecycle detection independent of raw-event routing by
    // listening only for our event on the compositor's advertised IPC socket.
    Socket {
        id: lifecycleSocket
        path: Hyprland.eventSocketPath
        connected: path.length > 0 && Quickshell.env("VELORA_VALIDATE") !== "1"
        parser: SplitParser {
            onRead: function(line) {
                if (line.startsWith("velora-blur>>")) root.lifecycle(line.slice(13).trim())
            }
        }
    }
    Timer {
        interval: 5000; running: Quickshell.env("VELORA_VALIDATE") !== "1"; repeat: true
        onTriggered: {
            if (!lifecycleSocket.connected && lifecycleSocket.path.length > 0) lifecycleSocket.connected = true
            root.refresh()
        }
    }
    Process {
        id: probe
        command: ["python3", Quickshell.shellDir + "/scripts/native-blur", "status"]
        onExited: {
            if (root.pendingRefresh) Qt.callLater(root.refresh)
        }
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.probeGeneration !== root.generation) return
                try { root.applyStatus(JSON.parse(text)) }
                catch (error) { root.applyStatus({available: false, state: "unavailable", diagnostic: "Diagnóstico nativo inválido: " + error}) }
            }
        }
    }
}
