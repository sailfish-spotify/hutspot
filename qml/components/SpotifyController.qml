import QtQuick 2.0
import "../Spotify.js" as Spotify


Item {
    property var playbackState;
    property bool isPlaying: false;

    Connections {
        target: spotify
        onLinkingSucceeded: {
            Spotify._accessToken = spotify.getToken()
            Spotify._username = spotify.getUserName()
            refreshPlaybackState();
        }
    }

    function play(callback) {
        Spotify.play({}, function(error, data) {
            if(!error) {
                isPlaying = true;
                playbackState.is_playing = isPlaying;
            }
            if (callback) callback(error, data)
        })
    }

    function pause(callback) {
        Spotify.pause({}, function(error, data) {
            if(!error) {
                isPlaying = false;
                playbackState.is_playing = isPlaying;
            }
            if (callback) callback(error, data)
        })
    }

    function playPause(callback) {
        if (isPlaying)
            pause(callback);
        else
            play(callback);
    }

    function refreshPlaybackState() {
        Spotify.getMyCurrentPlaybackState({}, function (error, state) {
            if (state) {
                playbackState = state;
                isPlaying = playbackState.is_playing;
            }
        });
    }
}
