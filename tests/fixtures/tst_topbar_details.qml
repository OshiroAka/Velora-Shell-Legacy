import QtQuick
import QtTest
import "../../features/topbar" as Topbar

Item {
    width: 720; height: 220
    QtObject {
        id: theme
        property color barSurface: "#292b30"
        property color accent: "#a0c4b6"
        property color accentSoft: "#bfd9d0"
        property color textPrimary: "white"
        property color textSecondary: "gray"
        property color borderSubtle: "#40434a"
        property color success: "#a0c4b6"
        property color danger: "#dd7777"
        property string bodyFont: "Sans Serif"
        function withAlpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    }
    Topbar.WorkspaceSwitcher { id: workspaces; x: 40; y: 10; width: implicitWidth; height: implicitHeight; theme: theme }
    Topbar.RunCatIcon { id: cat; x: 320; y: 30; cpuUsage: 5 }
    Topbar.CoffeeIcon { id: coffee; x: 400; y: 30 }
    QtObject {
        id: execution
        property var current: ({ phase: "idle", agent: "", label: "", detail: "", progress: -1 })
        readonly property bool shown: current.phase !== "idle"
    }
    Topbar.ExecutionIndicator { id: indicator; x: 450; y: 0; theme: theme; service: execution }
    SignalSpy { id: requests; target: workspaces; signalName: "workspaceRequested" }
    TestCase {
        name: "TopbarDetails"
        when: windowShown
        function init() {
            workspaces.workspaceIds = [1, 2, 3, 4, 5]
            workspaces.activeWorkspaceId = 1
            workspaces.pendingId = 0
            requests.clear()
            cat.visible = true; cat.animate = true; cat.cpuUsage = 5
            coffee.active = false
            execution.current = { phase: "idle", agent: "", label: "", detail: "", progress: -1 }
            wait(270)
        }
        function test_workspace_real_acknowledgement_contract() {
            const button = findChild(workspaces, "workspaceButton4")
            mouseClick(button, button.width / 2, 15)
            compare(requests.count, 1)
            compare(requests.signalArguments[0][0], 4)
            compare(workspaces.activeWorkspaceId, 1, "Wait for backend acknowledgement")
            mouseClick(button, button.width / 2, 15)
            compare(requests.count, 1, "No duplicate dispatch while pending")
            const previous = workspaces.selectedCenter
            workspaces.activeWorkspaceId = 4
            compare(workspaces.pendingId, 0)
            wait(70)
            verify(workspaces.selectedCenter > previous && workspaces.selectedCenter < workspaces.targetCenter,
                "Indicator must pass through intermediate positions")
            wait(220)
            fuzzyCompare(workspaces.selectedCenter, workspaces.targetCenter, 0.1)
        }
        function test_workspace_hover_keyboard_and_external_changes() {
            const button = findChild(workspaces, "workspaceButton3")
            const hover = findChild(button, "workspaceHover")
            mouseMove(button, button.width / 2, 15)
            wait(180)
            fuzzyCompare(hover.opacity, 1, 0.01)
            button.forceActiveFocus()
            keyClick(Qt.Key_Return)
            compare(requests.count, 1)
            compare(requests.signalArguments[0][0], 3)
            workspaces.workspaceIds = [1, 2, 3, 4, 5, 8]
            workspaces.activeWorkspaceId = 8
            wait(260)
            compare(workspaces.selectedIndex, 5)
            fuzzyCompare(workspaces.selectedCenter, workspaces.targetCenter, 0.1)
        }
        function test_cat_continuity_cadence_and_stop() {
            const first = cat.phase
            wait(100)
            verify(cat.phase !== first)
            const cadence = cat.cadence
            cat.cpuUsage = 100
            wait(100)
            verify(cat.cadence > cadence && cat.cadence < cat.targetCadence,
                "Speed must interpolate without resetting the cycle")
            cat.animate = false
            const paused = cat.phase
            wait(100)
            compare(cat.phase, paused)
            cat.animate = true; cat.visible = false
            const hidden = cat.phase
            wait(100)
            compare(cat.phase, hidden, "Hidden icon must not animate")
        }
        function test_coffee_reveal_loop_and_idle() {
            const smoke = findChild(coffee, "coffeeSmoke")
            const strand = findChild(coffee, "coffeeSmokeStrand0")
            verify(!smoke.visible)
            coffee.active = true
            wait(90)
            verify(coffee.smokeReveal > 0 && coffee.smokeReveal < 1)
            wait(180)
            fuzzyCompare(coffee.smokeReveal, 1, 0.01)
            const phase = strand.progress
            wait(100)
            verify(strand.progress !== phase)
            coffee.active = false
            wait(90)
            verify(coffee.smokeReveal > 0 && coffee.smokeReveal < 1)
            wait(200)
            verify(!smoke.visible)
            const idle = strand.progress
            wait(100)
            compare(strand.progress, idle, "Inactive smoke must stop")
        }
        function test_execution_structure_before_content_and_reverse() {
            verify(!indicator.mounted)
            execution.current = { phase: "running", agent: "Fixture", label: "Teste de motion", detail: "", progress: -1 }
            wait(70)
            verify(indicator.reveal > 0 && indicator.reveal < 1)
            compare(indicator.contentReveal, 0, "Shape must precede content")
            wait(270)
            fuzzyCompare(indicator.contentReveal, 1, 0.01)
            execution.current = { phase: "running", agent: "Fixture", label: "Próxima etapa do teste", detail: "Etapa 2", progress: 0.5 }
            verify(indicator.mounted, "A state change must reuse the surface")
            wait(370)
            compare(indicator.presented.progress, 0.5)
            execution.current = { phase: "idle", agent: "", label: "", detail: "", progress: -1 }
            wait(30)
            verify(indicator.mounted, "Closing must preserve the surface until contraction ends")
            wait(230)
            verify(!indicator.mounted)
        }
    }
}
