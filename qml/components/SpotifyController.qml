import QtQuick 2.0
import Sailfish.Silica 1.0
import "../Spotify.js" as Spotify


Item {
    PlaybackState {
        id: playbackState
    }

    function getCoverArt(state, default_value) {
        if (state.coverArtUrl !== "")
            return state.coverArtUrl;
        return default_value;
    }

    property alias playbackState: playbackState
    property alias devices: devicesModel

    ListModel {
        id: devicesModel
    }

    Timer {
        id: handleRendererInfo
        interval: 1000
        onRunningChanged: if (running) refreshCount = 0
        running: playbackState.is_playing || (app.state === Qt.ApplicationActive || cover.status === Cover.Active)
        property int refreshCount: 0
        repeat: true
        onTriggered: {
            // pretend progress (ms), refresh() will set the actual value
            if (playbackState.is_playing) {
                if (playbackState.progress_ms < playbackState.item.duration_ms) {
                    playbackState.progress_ms += 1000
                } else playbackState.progress_ms = playbackState.item.duration_ms
            }

            // also reload playbackState if we haven't done it in a long time
            if (++refreshCount >= 5) {
                refreshPlaybackState()
                refreshCount = 0
            }
        }
    }

    Connections {
        target: app
        onStateChanged: {
            if (app.state === Qt.ApplicationActive) {
                app.controller.reloadDevices();
            }
        }
    }

    Connections {
        target: spotify
        onLinkingSucceeded: {
            Spotify._accessToken = spotify.getToken()
            Spotify._username = spotify.getUserName()
            refreshPlaybackState();
            reloadDevices();
        }
    }

    Timer {
        id: timer
        function setTimeout(cb, delayTime) {
            interval = delayTime;
            repeat = false;
            triggered.connect(cb);
            triggered.connect(function() {
                triggered.disconnect(cb); // This is important
            });
            start();
        }
    }

    function setVolume(volume) {
        var value = Math.round(volume);
        Spotify.setVolume(value, function(error, data) {
            if (!error) {
                playbackState.device.volume_percent = value;
            }
        })
    }

    function reloadDevices() {
        Spotify.getMyDevices(function(error, data) {
            if (data) {
                try {
                    devicesModel.clear();
                    for (var i=0; i < data.devices.length; i++) {
                        devicesModel.append(data.devices[i]);
                        if (data.devices[i].is_active)
                            playbackState.device = data.devices[i]
                    }
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getMyDevices")
            }
        })
    }

    function delayedRefreshPlaybackState() {
        // for some reason we need to wait
        // thx spotify
        handleRendererInfo.refreshCount = 0
        timer.setTimeout(function () {
            refreshPlaybackState();
        }, 300)
    }

    function next(callback) {
        // TODO: use playback queue to find out what happens next!
        // exciting!
        Spotify.skipToNext({}, function(error, data) {
            if (callback)
                callback(error, data)
            delayedRefreshPlaybackState()
        })
    }

    function previous(callback) {
        Spotify.skipToPrevious({}, function(error, data) {
            if (callback)
                callback(error, data)
            delayedRefreshPlaybackState()
        })
    }

    function play(callback) {
        Spotify.play({}, function(error, data) {
            if(!error) {
                playbackState.is_playing = true;
            }
            if (callback) callback(error, data)
        })
    }

    function pause(callback) {
        Spotify.pause({}, function(error, data) {
            if(!error) {
                playbackState.is_playing = false;
            }
            if (callback) callback(error, data)
        })
    }

    function playPause(callback) {
        if (playbackState.is_playing)
            pause(callback);
        else
            play(callback);
    }

    function setRepeat(value, callback) {
        Spotify.setRepeat(value, {}, function(error, data) {
            if (!error) {
                playbackState.repeat_state = value;
                delayedRefreshPlaybackState();
            }

            if (callback) callback(error, data)
        })
    }

    function setShuffle(value, callback) {
        Spotify.setShuffle(value, {}, function(error, data) {
            if (!error) {
                playbackState.shuffle_state = value;
                delayedRefreshPlaybackState();
            }

            if (callback) callback(error, data)
        })
    }

    function refreshPlaybackState() {
        Spotify.getMyCurrentPlaybackState({}, function (error, state) {
            if (state) {
                playbackState.importState(state)
            }
        });
        reloadDevices();
    }

    function playTrack(track) {
        Spotify.play({
            'device_id': playbackState.device.id,
            'uris': [track.uri]
        }, function(error, data) {
            if(!error) {
                playbackState.item = track
                refreshPlaybackState();
            } else
                showErrorMessage(error, qsTr("Play Failed"))
        })
    }

    function playContext(context) {
        if (!options) {
            options = {
                'device_id': playbackState.device.id,
                'context_uri': context.uri
            }
        } else {
            options.device_id = playbackState.device.id
            options.context_uri = context.uri
        }

        Spotify.play(options, function(error, data) {
            if (!error) {
              refreshPlaybackState();
            } else
                showErrorMessage(error, qsTr("Play Failed"))
        })
    }

    function playTrackInContext(track, context) {
        if (playbackState.device) {
            Spotify.play({
                "device_id": playbackState.device.id,
                "context_uri": context.uri,
                "offset": {"uri": track.uri}
            }, function (error, data) {
                if (!error) {
                    playbackState.item = track
                    refreshPlaybackState();
                } else {
                    app.showErrorMessage(error, qsTr("Play failed"))
                }
            })
        } else {
            // TODO: handle that
            app.showErrorMessage(error, qsTr("No device selected"))
        }
    }
}
