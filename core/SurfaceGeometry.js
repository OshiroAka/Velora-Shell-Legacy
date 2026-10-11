.pragma library

function clamp(value, low, high) {
    return Math.max(low, Math.min(Math.max(low, high), value))
}

// Inputs are logical surface dimensions. QScreen already accounts for scale;
// physical monitor pixels must never be scaled again inside these functions.
function area(width, height, rail, rightSide, top, bottom, margin) {
    const left = Math.min(width, margin + (rightSide ? 0 : rail))
    const right = Math.max(left, width - margin - (rightSide ? rail : 0))
    const y = Math.min(height, top + margin)
    return { x: left, y: y, width: Math.max(0, right - left),
        height: Math.max(0, height - bottom - margin - y) }
}

function fit(bounds, wantedWidth, wantedHeight, wantedX, wantedY) {
    const width = Math.max(0, Math.min(wantedWidth, bounds.width))
    const height = Math.max(0, Math.min(wantedHeight, bounds.height))
    return { x: clamp(wantedX, bounds.x, bounds.x + bounds.width - width),
        y: clamp(wantedY, bounds.y, bounds.y + bounds.height - height),
        width: width, height: height }
}

function designBounds(width, height, rail, rightSide, top, bottom) {
    const scale = Math.max(0.000001, Math.min(width / 1600, height / 900))
    const bounds = area(width, height, rail, rightSide, top, bottom, 0)
    return { x: (bounds.x - (width - 1600 * scale) / 2) / scale,
        y: (bounds.y - (height - 900 * scale) / 2) / scale,
        width: bounds.width / scale, height: bounds.height / scale }
}

function pose(value, width, height, bounds) {
    if (!bounds) return value
    const result = Object.assign({}, value)
    const radians = Number(value.rotation || 0) * Math.PI / 180
    const c = Math.cos(radians), s = Math.sin(radians)
    const spanX = Math.abs(width * c) + Math.abs(height * s)
    const spanY = Math.abs(width * s) + Math.abs(height * c)
    const scale = Math.max(0, Math.min(Number(value.scale === undefined ? 1 : value.scale),
        bounds.width / Math.max(0.000001, spanX), bounds.height / Math.max(0.000001, spanY)))
    const minX = Math.min(0, width * scale * c) + Math.min(0, -height * scale * s)
    const minY = Math.min(0, width * scale * s) + Math.min(0, height * scale * c)
    result.x = clamp(Number(value.x || 0), bounds.x - minX, bounds.x + bounds.width - minX - spanX * scale)
    result.y = clamp(Number(value.y || 0), bounds.y - minY, bounds.y + bounds.height - minY - spanY * scale)
    result.scale = scale
    return result
}
