import QtQuick
import QtTest
import "../../core" as Core
import "../../components" as Components
import "../../features/topbar" as Topbar

Item {
    id: fixture
    width: 1366; height: 768
    property url previewPath: ""
    Core.Motion { id: tokens }
    Item { id: anchorA; x: 240; width: 74; height: 40 }
    Item { id: anchorB; x: 880; width: 44; height: 40 }
    QtObject {
        id: controller
        property var anchorItem: anchorA
        function close() { morph.desiredType = "" }
    }
    Topbar.MorphPopover { id: morph; anchors.fill: parent; controller: controller; motion: tokens }
    Components.VeloraWallpaperCarousel {
        id: selector
        anchors.fill: parent
        motion: tokens
        keyboardFocus: true
        onNavigateRequested: delta => selectedIndex = Math.max(0, Math.min(entries.length - 1, selectedIndex + delta))
        onSelectAbsoluteRequested: index => selectedIndex = index
        onGridModeRequested: enabled => gridMode = enabled
        onCloseRequested: open = false
    }
    SignalSpy { id: applied; target: selector; signalName: "applyRequested" }
    TestCase {
        name: "SurfaceMotion"
        when: windowShown
        function library(count) {
            const entries = []
            for (let i = 0; i < count; ++i) entries.push({key: "wall"+i, title: "Wallpaper "+i,
                kind: "static", preview: Qt.resolvedUrl("../../assets/profile-avatar.svg")})
            return entries
        }
        function init() {
            selector.open = false; selector.revealProgress = 0; selector.gridMode = false
            morph.desiredType = ""; tokens.reduced = false; controller.anchorItem = anchorA
            wait(350)
            selector.entries = library(500); selector.selectedIndex = 0; applied.clear()
        }
        function showSelector() { selector.revealProgress = 1; selector.open = true; selector.forceActiveFocus() }
        function test_accordion_continuity_and_identity() {
            showSelector(); wait(tokens.accordionDuration + 100)
            const card = findChild(selector, "wallpaperCard1")
            verify(card !== null)
            selector.selectedIndex = 1; wait(65)
            const x = card.x, w = card.width
            selector.selectedIndex = 3
            fuzzyCompare(card.x, x, .02); fuzzyCompare(card.width, w, .02)
            compare(findChild(selector, "wallpaperCard1"), card, "Keep the Image and delegate alive")
            wait(tokens.accordionDuration + 100)
            for (let i = 4; i < 13; ++i) { selector.selectedIndex = i; wait(35); verify(selector.diagnostics().modelCount <= selector.metrics.visibleCount + 8) }
            tryCompare(selector, "geometryProgress", 1, tokens.accordionDuration * 3)
            verify(selector.diagnostics().modelCount <= selector.metrics.visibleCount + 2, JSON.stringify(selector.diagnostics()))
            tryCompare(selector, "animating", false, tokens.accordionDuration * 3)
        }
        function test_input_and_closed_idle() {
            showSelector(); wait(tokens.accordionDuration + 100)
            keyClick(Qt.Key_Right); compare(selector.selectedIndex, 1)
            keyClick(Qt.Key_A); wait(tokens.accordionDuration * 2 + 80); compare(selector.selectedIndex, 0)
            keyClick(Qt.Key_Left); compare(selector.selectedIndex, 0)
            selector.handleWheel(-120); compare(selector.selectedIndex, 1)
            wait(tokens.accordionDuration + 100)
            const card = findChild(selector, "wallpaperCard2")
            mouseClick(card, card.width / 2, card.height / 2); compare(selector.selectedIndex, 2)
            selector.forceActiveFocus(); keyClick(Qt.Key_Return); compare(applied.count, 1)
            keyClick(Qt.Key_Escape); verify(!selector.open)
            selector.revealProgress = 0; wait(20)
            compare(selector.diagnostics().modelCount, 0); verify(!selector.animating)
        }
        function test_keyboard_spam_keeps_one_bounded_pending_step() {
            showSelector(); wait(tokens.accordionDuration + 100)
            keyClick(Qt.Key_Right)
            for (let i = 0; i < 25; ++i) keyClick(Qt.Key_Right)
            compare(selector.selectedIndex, 1)
            compare(selector.pendingStep, 1)
            wait(tokens.accordionDuration * 2 + 120)
            compare(selector.selectedIndex, 2)
            compare(selector.pendingStep, 0)
            verify(!selector.animating)
        }
        function test_wheel_burst_cannot_run_away_or_wrap() {
            showSelector(); wait(tokens.accordionDuration + 100)
            for (let i = 0; i < 40; ++i) selector.handleWheel(-120)
            compare(selector.selectedIndex, 1, "One accepted wheel intent per geometry transition")
            wait(tokens.accordionDuration + 50)
            selector.handleWheel(-120); compare(selector.selectedIndex, 2)
            wait(tokens.accordionDuration + 50)
            selector.selectedIndex = 499; selector.handleWheel(-120)
            compare(selector.selectedIndex, 499, "No last-to-first jump")
        }
        function test_only_selected_preview_lives() {
            if (!fixture.previewPath) { skip("Video fixture requires ffmpeg"); return }
            const list = library(20)
            for (let i = 0; i < list.length; ++i) { list[i].mediaType = "vid"; list[i].path = fixture.previewPath }
            selector.entries = list; showSelector(); wait(tokens.accordionDuration + 160)
            compare(selector.diagnostics().delegates.filter(d => d.livePreview).length, 1)
            selector.selectedIndex = 2
            compare(selector.diagnostics().delegates.filter(d => d.livePreview).length, 0)
            wait(tokens.accordionDuration + 160)
            const playing = selector.diagnostics().delegates.filter(d => d.livePreview)
            compare(playing.length, 1); compare(playing[0].index, 2)
            selector.open = false; selector.revealProgress = 0
            compare(selector.diagnostics().modelCount, 0)
        }
        function test_reduced_motion_and_small_libraries() {
            tokens.reduced = true
            for (const count of [0,1,2,5,500]) {
                selector.entries = library(count); showSelector()
                compare(selector.geometryProgress, 1); compare(selector.contentProgress, 1)
                verify(!selector.animating)
                selector.selectedIndex = Math.max(0,count-1)
                verify(selector.diagnostics().modelCount <= selector.metrics.visibleCount + 2)
                selector.open = false; selector.revealProgress = 0
                compare(selector.diagnostics().modelCount, 0)
            }
        }
        function test_geometry_precedes_content_and_handoff() {
            morph.desiredType = "timer"; wait(65)
            verify(morph.reveal > 0 && morph.reveal < 1); compare(morph.contentReveal, 0)
            wait(260); verify(morph.interactive)
            const oldWidth = Number(morph.panelRect.width)
            controller.anchorItem = anchorB; morph.desiredType = "clock"
            verify(morph.mounted); fuzzyCompare(morph.panelRect.width, oldWidth, 1)
            wait(80)
            verify(morph.panelRect.width > oldWidth); verify(morph.anchorX > 277)
            compare(morph.contentReveal, 0, "New text waits for the new geometry")
            wait(250); verify(morph.interactive)
            morph.desiredType = ""; wait(30)
            compare(morph.reveal, 1, "Content leaves before geometry")
            wait(240); verify(!morph.mounted)
        }
        function test_reduce_during_transition_and_reverse() {
            morph.desiredType = "timer"; wait(55)
            morph.desiredType = "clock"; wait(40)
            tokens.reduced = true
            compare(morph.reveal, 1); compare(morph.contentReveal, 1); compare(morph.presentedType, "clock")
            morph.desiredType = ""; verify(!morph.mounted)
            showSelector(); tokens.reduced = false; selector.selectedIndex = 3; wait(50)
            tokens.reduced = true; verify(!selector.animating); compare(selector.contentProgress, 1)
        }
    }
}
