import QtQuick 2.0
import org.nemomobile.mpris 1.0


Item {
    Connections {
        target: app.controller.playbackState
        onItemChanged: {
            var metadata = {}
            metadata[Mpris.metadataToString(Mpris.Title)] = app.controller.playbackState.item.name
            metadata[Mpris.metadataToString(Mpris.Artist)] = app.controller.playbackState.artistsString
            mprisPlayer.metadata = metadata
        }
    }

    MprisPlayer {
        id: mprisPlayer
        serviceName: "hutspot"
        playbackStatus: app.controller.playbackState.is_playing ? Mpris.Playing : Mpris.Paused

        identity: qsTr("Simple Spotify Controller")

        canControl: true

        canPause: true
        canPlay: true
        canGoNext: true
        canGoPrevious: true

        canSeek: false

        onPauseRequested: app.controller.playPause()
        onPlayRequested: app.controller.play()
        onPlayPauseRequested: app.controller.playPause()
        onNextRequested: app.controller.next()
        onPreviousRequested: app.controller.previous()
    }
}
