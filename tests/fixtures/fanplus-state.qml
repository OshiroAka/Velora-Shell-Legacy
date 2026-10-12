import QtQuick
import Quickshell
import "services" as Services
import "components" as Components

ShellRoot {
    id: root
    property int step: 0
    property int attempts: 0
    property string testMode: Quickshell.env("VELORA_FANPLUS_TEST_MODE")
    Services.FanPlusService {
        id: fan
        helper: Quickshell.env("VELORA_FANPLUS_TEST_HELPER")
    }
    Components.VeloraFanPlusIndicator {
        id: indicator
        active: fan.state === "active"
    }
    Timer {
        interval: 25; running: true; repeat: true
        onTriggered: {
            try {
                if (++root.attempts > 160) throw new Error("Fan+ test timed out: " + root.step + " " + fan.state)
                if (root.step === 0 && fan.state === "off") {
                    if (indicator.active) throw new Error("Indicator active on startup")
                    fan.enable()
                    if (fan.state !== "starting" || fan.enabled || indicator.active)
                        throw new Error("Fan+ activated before backend acknowledgment")
                    root.step = 1
                } else if (root.step === 1 && fan.state === "active") {
                    if (root.testMode === "error") throw new Error("Failed backend claimed active")
                    if (!indicator.active) throw new Error("Indicator missing after acknowledgment")
                    root.step = 2
                    fan.checkResume(fan.lastTick + 60000)
                } else if (root.step === 1 && fan.state === "error") {
                    if (root.testMode !== "error" || indicator.active || fan.enabled)
                        throw new Error("Failure left Fan+ active")
                    console.log("VELORA_FANPLUS_TEST_OK error")
                    Qt.quit()
                } else if (root.step === 2 && fan.state === "active") {
                    fan.disable(); root.step = 3
                } else if (root.step === 3 && fan.state === "off") {
                    if (indicator.active || fan.enabled) throw new Error("Indicator stayed visible on OFF")
                    console.log("VELORA_FANPLUS_TEST_OK success")
                    Qt.quit()
                }
            } catch (e) {
                console.error("VELORA_FANPLUS_TEST_FAILED " + e)
                Qt.quit()
            }
        }
    }
}
