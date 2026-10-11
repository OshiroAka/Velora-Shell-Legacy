import QtQuick
import Quickshell
import "../../core" as Core

Scope {
    id: root
    property var motion: defaultMotion
    Core.Motion { id: defaultMotion }
    property string activeType: ""
    property var owner: null
    property var anchorItem: null
    property var items: []
    readonly property bool opened: activeType.length > 0
    property var hoveredItem: null
    property var blockedItem: null
    property var pendingHost: null
    property string pendingType: ""
    property bool panelHovered: false
    property bool panelHeld: false
    property bool hoverManaged: false
    property string recoverType: ""

    function supportsHover(type) {
        return ["thing", "caffeine", "timer", "notes", "battery", "monitor", "paint", "wifi", "search", "controls", "clock"].includes(type)
    }
    function enter(type, item, host) {
        if (!supportsHover(type)) return
        hoveredItem = item
        pendingType = type
        pendingHost = host
        leaveDelay.stop()
        if (blockedItem === item || (owner === host && anchorItem === item && opened)) return
        openDelay.restart()
    }
    function leave(item) {
        if (blockedItem === item) blockedItem = null
        if (hoveredItem !== item) return
        hoveredItem = null
        openDelay.stop()
        scheduleLeave()
    }
    function scheduleLeave() {
        if (hoverManaged && !hoveredItem && !panelHovered && !panelHeld) leaveDelay.restart()
    }
    function panelPresence(host, inside, held) {
        if (owner !== host) return
        panelHovered = inside
        panelHeld = held
        if (inside || held) {
            leaveDelay.stop()
            // A return during the inverse motion reverses that same surface.
            if (!opened && recoverType) {
                activeType = recoverType
                recoverType = ""
            }
        } else scheduleLeave()
    }
    function show(type, item, host, byHover) {
        openDelay.stop()
        leaveDelay.stop()
        recoverType = ""
        if (owner !== host) { panelHovered = false; panelHeld = false }
        hoverManaged = byHover
        anchorItem = item
        owner = host
        activeType = type
    }

    Timer {
        id: openDelay
        interval: root.motion.intent
        onTriggered: if (root.hoveredItem && root.hoveredItem !== root.blockedItem)
            root.show(root.pendingType, root.hoveredItem, root.pendingHost, true)
    }
    Timer {
        id: leaveDelay
        interval: root.motion.leaveGrace
        onTriggered: if (!root.hoveredItem && !root.panelHovered && !root.panelHeld) root.close(false)
    }

    function registerItem(type, item, host) {
        items = items.concat([{ type: type, item: item, host: host }])
    }
    function unregisterItem(item) {
        if (anchorItem === item) close()
        leave(item)
        items = items.filter(entry => entry.item !== item)
    }
    function toggle(type, item, host) {
        if (activeType === type && owner === host) { close(); return }
        blockedItem = null
        show(type, item, host, supportsHover(type) && hoveredItem === item)
    }
    function close(explicit = true) {
        openDelay.stop()
        leaveDelay.stop()
        recoverType = explicit ? "" : activeType
        if (explicit) blockedItem = hoveredItem
        activeType = ""
    }
    function openByType(type, monitor) {
        const entry = items.find(entry => entry.type === type
            && (!monitor || entry.host.screen.name === monitor))
        if (!entry) return false
        toggle(type, entry.item, entry.host)
        return true
    }
    function snapshot() {
        return { active: activeType, monitor: owner ? owner.screen.name : "",
            keyboard: owner ? owner.keyboardState() : null,
            surface: owner && typeof owner.popoverState === "function" ? owner.popoverState() : null,
            anchors: items.map(entry => ({ type: entry.type, monitor: entry.host.screen.name,
                x: entry.item.mapToItem(null, entry.item.width / 2, 0).x })) }
    }
}
