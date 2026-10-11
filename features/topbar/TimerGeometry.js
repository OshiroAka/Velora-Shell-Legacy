.pragma library

// Diminishing displacement, capped at ten pixels even for a very long drag.
function resistance(distance) {
    return 10 * distance / (Math.abs(distance) + 56)
}

// Timer-only geometry. The native material and QML fill consume this same rect.
function panel(width, height, barHeight, anchor, anchorWidth, wantedWidth, wantedHeight, progress, leftInset, rightInset) {
    const p = Math.max(0, Math.min(1, progress))
    const left = Math.max(8, Number(leftInset) || 0)
    const right = Math.max(8, Number(rightInset) || 0)
    const available = Math.max(0, width - left - right)
    const targetWidth = Math.min(wantedWidth, available)
    const targetHeight = Math.min(wantedHeight, Math.max(1, height - barHeight - 30))
    const seed = Math.min(targetWidth, Math.max(40, anchorWidth - 8))
    const w = seed + (targetWidth - seed) * p
    const origin = Math.max(left, Math.min(width - right, anchor))
    const x = Math.max(left, Math.min(width - w - right, origin - w / 2))
    return { x: x, y: barHeight + 14 * p, width: w, height: targetHeight * p,
        targetWidth: targetWidth, targetHeight: targetHeight,
        // Keep the neck under its trigger, including when the body hits an edge.
        neck: Math.max(0, Math.min(120, w / 2 - 18,
            origin - left, width - right - origin)) * p }
}
