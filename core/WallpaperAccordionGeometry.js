.pragma library

function clamp(low, value, high) {
    return Math.max(low, Math.min(high, value))
}

// Dimensions are logical pixels supplied by the actual output, including scale.
function layout(availableWidth, availableHeight, total, aspectRatio) {
    const w = Math.max(0, Number(availableWidth) || 0)
    const h = Math.max(0, Number(availableHeight) || 0)
    const count = Math.max(0, Math.floor(Number(total) || 0))
    const margin = Math.min(w / 4, h / 4, clamp(6, w * 0.006, 12))
    const available = Math.max(0, w - margin * 2)
    const capacity = clamp(1, (available >= 900 ? 3 : 1) + 2 * Math.floor(available / 500), 11)
    const visibleCount = Math.min(count, capacity)
    const stageWidth = Math.min(available, count < 3 ? 760 + Math.max(0, count - 1) * 130 : available)
    const gap = Math.min(stageWidth / 12, clamp(6, w * 0.006, 14))
    const usable = Math.max(0, stageWidth - gap * Math.max(0, visibleCount - 1))
    const ratio = Math.max(0.1, Number(aspectRatio) || 16 / 9)
    const maxHeight = Math.min(Math.max(0, h - margin * 2), clamp(160, h * 0.44, 460))
    const expanded = Math.min(maxHeight * ratio, visibleCount > 1 ? Math.min(980, usable * 0.54) : usable)
    const collapsed = visibleCount > 1 ? (usable - expanded) / (visibleCount - 1) : expanded
    const cardHeight = expanded / ratio
    const actualWidth = visibleCount === 1 ? expanded : stageWidth
    return { margin: margin, gap: gap, visibleCount: visibleCount,
        collapsedWidth: collapsed, expandedWidth: expanded,
        stageWidth: actualWidth, stageX: (w - actualWidth) / 2,
        stageY: (h - cardHeight) / 2, cardHeight: cardHeight }
}

function interpolateMetrics(from, to, progress) {
    const result = {}
    for (const key in to) result[key] = key === "visibleCount" ? to[key]
        : from[key] + (to[key] - from[key]) * progress
    return result
}

function windowStart(total, visible, selected, previousStart) {
    const maximum = Math.max(0, total - visible)
    let start = clamp(0, Number(previousStart) || 0, maximum)
    if (selected < start) start = selected
    if (selected >= start + visible) start = selected - visible + 1
    return clamp(0, start, maximum)
}

function windowIndices(total, visible, start) {
    const result = []
    if (!visible) return result
    for (let i = Math.max(0, start - 1); i < Math.min(total, start + visible + 1); ++i)
        result.push(i)
    return result
}

// A single conserved expansion budget gives adjacent cards the same boundary.
// Retargeting snapshots these weights and the scroll offset, never a guessed
// "dominant" card. Even a reversal halfway through a frame remains continuous.
function blend(weights, selected, progress) {
    const p = clamp(0, progress, 1)
    const result = {}
    for (const key in weights) result[key] = weights[key] * (1 - p)
    result[selected] = (result[selected] || 0) + p
    return result
}

function compact(weights) {
    const result = {}
    let sum = 0
    for (const key in weights) {
        if (weights[key] > 0.000001) { result[key] = weights[key]; sum += weights[key] }
    }
    if (sum > 0) for (const key in result) result[key] /= sum
    return result
}

function rect(metrics, index, weights, offset) {
    let before = 0
    for (const key in weights) if (Number(key) < index) before += weights[key]
    const focus = weights[index] || 0
    const extra = metrics.expandedWidth - metrics.collapsedWidth
    return { x: index * (metrics.collapsedWidth + metrics.gap) + extra * before - offset,
        width: metrics.collapsedWidth + extra * focus, focus: focus }
}

// Recycle only after a card has passed completely outside the clipped stage.
// One warm card per side; no library-sized collection of Image instances.
function visibleIndices(metrics, total, weights, offset) {
    if (!total || !metrics.visibleCount || metrics.stageWidth <= 0) return []
    const step = Math.max(1, metrics.collapsedWidth + metrics.gap)
    const extra = metrics.expandedWidth - metrics.collapsedWidth
    let first = clamp(0, Math.floor((offset - extra) / step), total - 1)
    while (first < total - 1) {
        const r = rect(metrics, first, weights, offset)
        if (r.x + r.width > 0.001) break
        ++first
    }
    let last = first
    while (last < total && rect(metrics, last, weights, offset).x < metrics.stageWidth - 0.001) ++last
    const result = []
    for (let i = Math.max(0, first - 1); i < Math.min(total, last + 1); ++i) result.push(i)
    return result
}

function rectangles(metrics, visible, activeSlot, previousSlot, progress) {
    const weights = {}; weights[previousSlot] = 1
    const blended = blend(weights, activeSlot, progress)
    const result = []
    for (let i = 0; i < visible; ++i) result.push(rect(metrics, i, blended, 0))
    return result
}
