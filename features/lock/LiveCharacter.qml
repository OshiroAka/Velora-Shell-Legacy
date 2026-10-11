import QtQuick
import QtMultimedia

Item {
    id: root

    property url source
    property bool playing: visible
    property int fillMode: Image.Stretch
    smooth: true
    property bool mipmap: true
    // Callers such as bounded previews may cap still/GIF decode resolution.
    property size sourceSize: Qt.size(-1, -1)

    readonly property string normalizedSource: String(source || "").toLowerCase()
        .split("?")[0].split("#")[0]
    readonly property bool videoSource: [".mp4", ".webm", ".mkv", ".mov"].some(
        function(extension) { return normalizedSource.endsWith(extension) })
    readonly property bool animatedImageSource: [".gif", ".webp", ".apng", ".mng"].some(
        function(extension) { return normalizedSource.endsWith(extension) })
    readonly property bool ready: videoSource ? videoPlayer.hasVideo
        : (animatedImageSource ? animatedImage.status === Image.Ready
            : staticImage.status === Image.Ready)

    function syncVideoPlayback() {
        if (!videoSource) {
            videoPlayer.stop()
            return
        }
        if (playing && visible)
            videoPlayer.play()
        else
            videoPlayer.pause()
    }

    Image {
        id: staticImage
        anchors.fill: parent
        source: !root.videoSource && !root.animatedImageSource ? root.source : ""
        sourceSize: root.sourceSize
        fillMode: root.fillMode
        smooth: root.smooth
        mipmap: root.mipmap
        asynchronous: true
        visible: !root.videoSource && !root.animatedImageSource
            && status === Image.Ready
    }

    AnimatedImage {
        id: animatedImage
        anchors.fill: parent
        source: root.animatedImageSource ? root.source : ""
        sourceSize: root.sourceSize
        fillMode: root.fillMode
        smooth: root.smooth
        mipmap: root.mipmap
        asynchronous: true
        cache: false
        playing: root.playing && root.visible
        visible: root.animatedImageSource && status === Image.Ready
    }

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        fillMode: root.fillMode === Image.PreserveAspectFit
            ? VideoOutput.PreserveAspectFit
            : (root.fillMode === Image.PreserveAspectCrop
                ? VideoOutput.PreserveAspectCrop : VideoOutput.Stretch)
        visible: root.videoSource && videoPlayer.hasVideo
    }

    MediaPlayer {
        id: videoPlayer
        source: root.videoSource ? root.source : ""
        videoOutput: videoOutput
        loops: MediaPlayer.Infinite
        autoPlay: root.videoSource && root.playing && root.visible
        onSourceChanged: Qt.callLater(root.syncVideoPlayback)
    }

    onPlayingChanged: syncVideoPlayback()
    onVisibleChanged: syncVideoPlayback()
    onVideoSourceChanged: Qt.callLater(syncVideoPlayback)
}
