import QtQuick
import QtQuick.Window
import Quickshell
import "services" as Services
import "features/topbar" as Topbar

ShellRoot {
    id: root
    property string mode: Quickshell.env("VELORA_TEST_MODE")
    property int step: 0
    property int attempts: 0
    function check(condition, message) {
        if (!condition) throw new Error(message)
    }
    function find(item, name) {
        if (item.objectName === name) return item
        for (const child of item.children || []) {
            const found = find(child, name)
            if (found) return found
        }
        return null
    }
    Services.TopBarTimerService { id: timer }
    Services.TopBarSystemService {
        id: tools
        enabled: false
        status: ({wifiDevice: null, activeNetwork: null})
    }
    QtObject {
        id: theme
        property string bodyFont: "Sans Serif"
        property color textPrimary: "white"
        property color textSecondary: "gray"
        property color textMuted: "gray"
        property color accent: "blue"
        property color accentSoft: "lightblue"
        property color borderSubtle: "gray"
        property color surfaceSoft: "black"
        property color danger: "red"
        function withAlpha(color, alpha) { return Qt.rgba(color.r, color.g, color.b, alpha) }
    }
    Window {
        id: window
        visible: true
        width: 352; height: 368
        Topbar.MicroToolsPanel {
            id: panel
            anchors.fill: parent
            type: "notes"; theme: theme; system: tools
            controller: ({}); actions: ({})
        }
    }
    Timer {
        interval: 50; running: true; repeat: true
        onTriggered: {
            try {
                if (++root.attempts > 100) throw new Error("Timed out waiting for services/save")
                if (!tools.loaded || !timer.loaded || !panel.item) return
                const editor = root.find(panel.item, "topbarNoteEditor")
                root.check(editor !== null, "Note editor missing")
                if (root.step === 0) {
                    if (root.mode === "write") {
                        root.check(timer.remaining === 1500000, "Fresh timer default")
                        editor.forceActiveFocus()
                        root.check(editor.activeFocus, "Editor did not receive focus")
                        editor.insert(0, "A")
                        root.check(tools.notes.length === 1 && tools.notes[0].text === "A", "First character was lost")
                        editor.insert(1, "ção")
                        const first = tools.selectedNote
                        tools.newNote("Second")
                        root.check(editor.text === "Second", "New note was not loaded")
                        root.check(tools.notes[0].text === "Ação", "Switch overwrote previous note")
                        tools.selectedNote = first
                        root.check(editor.text === "Ação", "Selection did not reload note")
                        editor.cursorPosition = 1
                        tools.pinNote(first)
                        root.check(editor.cursorPosition === 1, "Save reset the cursor")
                        tools.oneThing = "isolated focus"
                        timer.setDuration(60)
                        timer.toggleTimer()
                        timer.countdown = {running: true, deadline: Date.now() + 42000, remaining: 60000}
                        timer.toggleTimer()
                        root.check(!timer.countdown.running && timer.remaining > 41000 && timer.remaining <= 42000, "Pause lost remaining time")
                        timer.toggleTimer()
                        root.check(timer.countdown.running, "Resume failed")
                        timer.toggleStopwatch()
                    } else if (root.mode === "reload") {
                        root.check(tools.oneThing === "isolated focus", "One Thing not persisted")
                        root.check(tools.notes.length === 2 && tools.notes[0].text === "Ação" && tools.notes[0].pinned, "Notes not persisted")
                        root.check(timer.countdown.running && timer.remaining > 0 && timer.remaining < 42000, "Deadline did not survive reload")
                        root.check(timer.stopwatch.running && timer.elapsed > 0, "Stopwatch did not survive reload")
                        timer.countdown = {running: true, deadline: Date.now() - 1, remaining: 1}
                        timer.tick()
                        root.check(timer.finished && !timer.countdown.running && timer.remaining === 0, "Timer completion failed")
                        timer.tick()
                        timer.toggleStopwatch()
                    } else {
                        root.check(timer.finished && timer.remaining === 0, "Completed timer did not persist")
                        timer.resetTimer()
                        root.check(timer.remaining === 60000 && !timer.finished, "Reset failed")
                    }
                    root.step = 1
                } else if (!tools.saving) {
                    root.check(!tools.saveError && !timer.saveError, "Persistence error: " + tools.saveError + timer.saveError)
                    console.info("VELORA_TOPBAR_TEST_OK", root.mode)
                    Qt.quit()
                }
            } catch (error) {
                console.error("VELORA_TOPBAR_TEST_FAILED", String(error))
                Qt.quit()
            }
        }
    }
}
