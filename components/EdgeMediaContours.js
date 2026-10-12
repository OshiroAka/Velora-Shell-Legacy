.pragma library

// Inner silhouettes sampled from the two supplied references, top to bottom.
// Media has shallow, uneven lobes; Lyrics has the wider lower swell.
const media = [0, 22, 34, 25, 6, 0, 19, 28, 16, 2, 3, 30, 27, 3, 0, 21, 28, 9, 2, 11, 24]
const lyrics = [70, 38, 27, 43, 33, 6, 0, 21, 70, 35, 0, 0, 40, 81, 79, 128, 121, 49, 9, 12, 67]

function samples(mode) {
    const a = Math.min(1, Math.max(0, mode))
    const b = Math.min(1, Math.max(0, mode - 1))
    return media.map((value, i) => a * ((1 - b) * value / 380 + b * lyrics[i] / 330))
}

function audioLevels(frame) {
    return media.map((_, i) => {
        // Average adjacent FFT bands; avoid narrow spikes in the silhouette.
        const center = i * Math.max(0, frame.length - 1) / 20
        let sum = 0, weight = 0
        for (let j = -2; j <= 2; j++) {
            const value = Number(frame[Math.max(0, Math.min(frame.length - 1, Math.round(center) + j))])
            const w = 3 - Math.abs(j)
            sum += (Number.isFinite(value) ? Math.max(0, Math.min(1, value)) : 0) * w
            weight += w
        }
        return sum / weight
    })
}

function animatedSamples(mode, levels, phase, lyricMotion) {
    const base = samples(mode)
    const mediaWeight = Math.min(1, Math.max(0, mode)) * (1 - Math.min(1, Math.max(0, mode - 1)))
    const lyricsWeight = lyricMotion ? Math.min(1, Math.max(0, mode - 1)) : 0
    return base.map((value, i) => {
        // Keep both frame joins fixed, and all content inside its existing inset.
        const envelope = Math.sin(Math.PI * i / 20)
        const audio = mediaWeight * envelope * Math.sqrt(levels[i] || 0) * (.03 + value)
        const lyric = lyricsWeight * envelope * (.03 * Math.sin(i * .65 - phase * .85)
            - value * .14 * (1 - Math.cos(i * .5 - phase * .6)))
        return Math.max(0, Math.min(.40, value + audio + lyric))
    })
}

function offset(samples, progress) {
    const p = Math.max(0, Math.min(1, progress)) * 20
    const i = Math.min(19, Math.floor(p)), t = p - i
    const a = samples[Math.max(0, i - 1)], b = samples[i]
    const c = samples[i + 1], d = samples[Math.min(20, i + 2)]
    // A cubic B-spline keeps curvature continuous without overshoot/clamps
    // that create vertical flats and pointed turns at the narrowest lobes.
    const u = 1 - t
    return (u * u * u * a + (3 * t * t * t - 6 * t * t + 4) * b
        + (-3 * t * t * t + 3 * t * t + 3 * t + 1) * c + t * t * t * d) / 6
}
