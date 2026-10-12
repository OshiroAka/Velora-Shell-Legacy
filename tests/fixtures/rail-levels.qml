import QtQuick
import Quickshell
import "components" as Components

ShellRoot {
    id: test
    property int stage: 0
    property int ticks: 0
    property var current: null
    property var pose: null
    function check(ok, message) { if (!ok) throw new Error(message) }
    QtObject { id: theme; property string language: "pt" }
    QtObject { id: system }
    Item {
        width: 800; height: 600
        Components.VeloraRailControls {
            id: levels
            anchors.fill: parent
            theme: theme
            handoffSource: test.current
            onLevelOpening: popover => test.current = popover
            volumeCenter: 180; brightnessCenter: 320
            extraPanel: other.outline
        }
        Components.VeloraRailPopover {
            id: other
            anchors.fill: parent
            theme: theme; system: system
            preferredWidth: 330; preferredHeight: 366; anchorY: 380
            handoffSource: test.current
            customContent: Component { Item {} }
            onOpening: { test.current = other; levels.volumeOpen = false; levels.brightnessOpen = false }
        }
    }
    Timer {
        interval: 25; running: true; repeat: true
        onTriggered: {
            if (++test.ticks > 220) { console.error("RAIL_LEVELS_FAILED timeout",test.stage); Qt.quit(); return }
            try {
                let active = test.current
                switch (test.stage) {
                case 0: levels.volumeOpen = true; break
                case 1:
                    test.check(active.bodyHeight < 130, "height grows with the surface")
                    test.check(active.contentReveal === 0, "slider waits for surface")
                    break
                case 2:
                    if (active.contentReveal < .99) return
                    test.pose = [active.bodyWidth,active.bodyHeight,active.bodyY]
                    other.open()
                    test.check(Math.abs(other.bodyWidth-test.pose[0])<.1 && Math.abs(other.bodyHeight-test.pose[1])<.1, "wide menu inherits slider geometry")
                    break
                case 3:
                    test.pose = [other.bodyWidth,other.bodyHeight,other.bodyY]
                    levels.brightnessOpen = true
                    active=test.current
                    test.check(!other.mounted, "one surface owns the handoff")
                    test.check(Math.abs(active.bodyWidth-test.pose[0])<.1 && Math.abs(active.bodyY-test.pose[2])<.1, "spam reversal preserves current pose")
                    break
                case 4:
                    levels.brightnessOpen = false
                    levels.volumeOpen = true
                    test.check(test.current.opened && !other.mounted, "volume takes over brightness")
                    break
                case 5:
                    if (active.animating) return
                    test.check(Math.abs(active.bodyWidth-48)<.1 && Math.abs(active.bodyHeight-130)<.1, "slider settles at compact size")
                    test.check(levels.nativePanel.width === active.bodyWidth, "native and QML shape agree")
                    levels.volumeOpen=false
                    test.check(active.mounted && active.bodyWidth>47, "exit keeps surface during content fade")
                    break
                case 6:
                    levels.volumeOpen=true
                    test.check(test.current.mounted, "reenter during exit stays mounted")
                    break
                case 7:
                    if (active.animating) return
                    levels.motion.reduced=true
                    levels.volumeOpen=false
                    levels.brightnessOpen=true
                    test.check(test.current.contentReveal===1 && !test.current.animating, "reduced motion settles immediately")
                    levels.brightnessOpen=false
                    test.check(!levels.mounted, "all masks removed after close")
                    console.info("RAIL_LEVELS_OK"); Qt.quit(); return
                }
                test.stage++
            } catch (error) { console.error("RAIL_LEVELS_FAILED",test.stage,error.message); Qt.quit() }
        }
    }
}
