/**
 * Hutspot. 
 * Copyright (C) 2018 Maciej Janiszewski
 *
 * License: MIT
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../Spotify.js" as Spotify
import "../Util.js" as Util


Item {
    PlaybackState {
        id: playbackState
    }

    function getCoverArt(defaultValue, ignoreContext) {
        if (ignoreContext) {
            if (playbackState.coverArtUrl)
                return playbackState.coverArtUrl
            return defaultValue
        }

        if (playbackState.contextDetails)
            if (playbackState.contextDetails.images)
                return playbackState.contextDetails.images[0].url
        return defaultValue;
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
        running: playbackState.is_playing || Qt.application.active || cover.status === Cover.Active
        property int refreshCount: 0
        repeat: true
        onTriggered: {
            // pretend progress (ms), refresh() will set the actual value
            if (playbackState.is_playing) {
                if (playbackState.progress_ms < playbackState.item.duration_ms) {
                    playbackState.progress_ms += 1000
                } else
                    playbackState.progress_ms = playbackState.item.duration_ms
            }

            // close to switching tracks so refresh every time
            // also reload playbackState if we haven't done it in a long time
            if(playbackState.is_playing
               && (playbackState.item.duration_ms - playbackState.progress_ms) < 3000) {
                refreshPlaybackState()
                refreshCount = 0
            } else if (++refreshCount >= 5) {
                refreshPlaybackState()
                refreshCount = 0
            }
        }
    }

    Connections {
        target: app
        onHasValidTokenChanged: {
            if(app.hasValidToken) {
                refreshPlaybackState()
                reloadDevices()
            }
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

    ListModel {
        id: tmpDevicesModel
    }

    function checkForNewDevices() {
        Spotify.getMyDevices(function(error, data) {
            if (data) {
                try {
                    var i, j, added, removed, changed, found, device

                    // a new one has been added?
                    added = false
                    for(i=0; i < data.devices.length; i++) {
                        found = false
                        for(j=0; i < devicesModel.count; j++) {
                            device = devicesModel.get(j)
                            if(data.devices[i].id === device.id) {
                                found = true
                                break
                            }
                        }
                        if(!found) {
                            added = true
                            break
                        }
                    }
                    // an old one has been removed?
                    removed = false
                    for(i=0; i < devicesModel.count; i++) {
                        found = false
                        device = devicesModel.get(i)
                        for(j=0; i < data.devices.length; j++) {
                            if(data.devices[i].id === device.id) {
                                found = true
                                break
                            }
                        }
                        if(!found) {
                            removed = true
                            break
                        }
                    }
                    // changed
                    changed = false
                    for(i=0; i < data.devices.length; i++) {
                        for(j=0; i < devicesModel.count; j++) {
                            device = devicesModel.get(j)
                            if(data.devices[i].id === device.id) {
                                if(Util.hasDeviceChanged(data.devices[i], device))
                                    changed = true
                                break
                            }
                        }
                        if(changed)
                            break
                    }
                    if(added || removed || changed) {
                        devicesModel.clear();
                        for(i=0; i < data.devices.length; i++) {
                            devicesModel.append(data.devices[i])
                            //if (data.devices[i].is_active)
                            //    playbackState.device = data.devices[i]
                        }
                        //console.log("controller.checkForNewDevices: list differs")
                        devicesReloaded()
                    }
                } catch (err) {
                    console.log("controller.checkForNewDevices: error: " + err)
                }
            }
        })
    }

    signal devicesReloaded()

    function reloadDevices() {
        Spotify.getMyDevices(function(error, data) {
            if (data) {
                try {
                    console.log("controller.reloadDevices: #devices: " + data.devices.length)
                    devicesModel.clear();
                    for (var i=0; i < data.devices.length; i++) {
                        devicesModel.append(data.devices[i]);
                        if (data.devices[i].is_active)
                            playbackState.device = data.devices[i]
                    }
                    devicesReloaded()
                } catch (err) {
                    console.log("controller.reloadDevices: error: " + err)
                }
            } else {
                console.log("controller.reloadDevices: No Data for getMyDevices")
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
            refreshPlaybackState()
        })
    }

    function previous(callback) {
        Spotify.skipToPrevious({}, function(error, data) {
            if (callback)
                callback(error, data)
            refreshPlaybackState()
        })
    }

    function play(callback) {
        Spotify.play({'device_id': getDeviceId()}, function(error, data) {
            if(!error) {
                playbackState.is_playing = true;
                if(_waitForPlaybackState)
                    _ignorePlaybackState = true
            }
            if (callback)
                callback(error, data)
            else if(error)
                app.showErrorMessage(error, data)
        })
    }

    function pause(callback) {
        Spotify.pause({'device_id': getDeviceId()}, function(error, data) {
            if(!error) {
                playbackState.is_playing = false;
                if(_waitForPlaybackState)
                    _ignorePlaybackState = true
            }
            if (callback)
                callback(error, data)
            else if(error)
                app.showErrorMessage(error, data)
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

    // this allows to check if a response is underway (with possibly outdated info)
    property bool _waitForPlaybackState: false
    property bool _ignorePlaybackState: false

    function refreshPlaybackState() {
        _waitForPlaybackState = true
        var oldContextId = playbackState.context ? playbackState.context.uri : undefined;

        Spotify.getMyCurrentPlaybackState({}, function (error, state) {
            _waitForPlaybackState = false
            if(_ignorePlaybackState) {
                _ignorePlaybackState = false
                return
            }

            if (state) {
                playbackState.importState(state)
                if (state.context && state.context.uri !== oldContextId) {
                    var cid = Util.getIdFromURI(playbackState.context.uri)
                    switch (state.context.type) {
                        case 'album':
                            Spotify.getAlbum(cid, {}, function(error, data) {
                                playbackState.contextDetails = data
                            })
                            break
                        case 'artist':
                            Spotify.getArtist(cid, {}, function(error, data) {
                                playbackState.contextDetails = data
                            })
                            break
                        case 'playlist':
                            Spotify.getPlaylist(cid, {}, function(error, data) {
                                playbackState.contextDetails = data
                            })
                            break
                    }
                } else {
                    // ToDo why is this?
                    // Disabled since we lose ifo on what is being played
                    //playbackState.contextDetails = undefined
                }
            }
        })
        //reloadDevices() Why is this here? The info is not used.
    }

    function playTrack(track) {
        Spotify.play({
            'device_id': getDeviceId(),
            'uris': [track.uri]
        }, function(error, data) {
            if(!error) {
                playbackState.item = track
                refreshPlaybackState();
            } else
                app.showErrorMessage(error, qsTr("Play Failed"))
        })
    }

    function playContext(context) {
        var options = {
            'device_id': getDeviceId(),
            'context_uri': context.uri
        }
        Spotify.play(options, function(error, data) {
            if (!error) {
              refreshPlaybackState();
            } else
                app.showErrorMessage(error, qsTr("Play Failed"))
        })
    }

    function playTrackInContext(track, context) {
        if (playbackState.device) {
            Spotify.play({
                "device_id": getDeviceId(),
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

    function getDeviceId() {
        return (playbackState.device && playbackState.device.id !== "-1")
               ? playbackState.device.id
               : app.deviceId.value
    }

}
