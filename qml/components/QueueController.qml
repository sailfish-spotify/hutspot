/**
 * Hutspot. 
 * Copyright (C) 2018 Willem-Jan de Hoog
 * Copyright (C) 2018 Maciej Janiszewski
 *
 * License: MIT
 */

import QtQuick 2.0

import "../Spotify.js" as Spotify
import "../Util.js" as Util

// There is a problem with the Spotify API.
// When adding a track to an already playing playlist it is ignored.
// It will continue with the snapshot it is playing. All modifications are ignored
// See https://github.com/spotify/web-api/issues/462

Item {

    property string queuePlaylistId: ""
    property string queuePlaylistUri: ""
    property string queuePlaylistSnapshotId: ""

    readonly property string queuePlaylistDescription: qsTr("Playlist used as a queue by Hutspot")

    property string queuePlaylistName: app.hutspot_queue_playlist_name.value

    // ToDo: handle change of hutspot_queue_playlist_name.value

    function getQueuePlaylist(callback) {
        loadQueuePlaylist(0, 0, callback)
    }

    // states: 0 search for it
    //         1 create playlist
    function loadQueuePlaylist(state, searchOffset, callback) {
        var i
        if(queuePlaylistUri.length > 0) { // Todo check if it still exists?
            callback(true)
            return
        }
        switch(state) {
        case 0: // search in user's playlists
            Spotify.getUserPlaylists(id, {offset: searchOffset, limit: 50}, function(error, data) {
                if(data && data.items) {
                    for(i=0;i<data.items.length;i++) {
                        if(data.items[i].name === queuePlaylistName) {
                            queuePlaylistId = data.items[i].id
                            queuePlaylistUri = data.items[i].uri
                            queuePlaylistSnapshotId = data.items[i].snapshot_id
                            callback(true)
                            return
                        }
                    }
                    // not found, are there more playlists to search in?
                    if(data.next) {
                        searchOffset = data.offset + data.limit
                        loadQueuePlaylist(0, searchOffset)
                    } else // or we have to create it
                        loadQueuePlaylist(1)
                } else {
                    callback(false)
                    console.log("No Data while looking for Playlist " + queuePlaylistName)
                }
            })
            break
        case 1: // create it
            app.showConfirmDialog(qsTr("Hutspot wants to create playlist:<br><br><b>") + queuePlaylistName + "</b><br><br>"
                                       +qsTr("which will be used as it's player queue. Is that Ok?"),
                                  function() {
                // create the playlist
                var options = {name: queuePlaylistName}
                options.description = queuePlaylistDescription
                Spotify.createPlaylist(options, function(error, data) {
                    if(data && data.id) {
                        queuePlaylistId = data.id
                        queuePlaylistUri = data.uri
                        queuePlaylistSnapshotId = data.snapshot_id
                        callback(true)
                    } else {
                        console.log("No Data while creating Playlist " + queuePlaylistName)
                        callback(false)
                    }
                })
            }, function() {
                callback(false)
            })
        }
    }

    function ensureQueueIsPlaying(category) {
        getQueuePlaylist(function(success) {
            if(!success)
                return

            // If not yet playing the Queue Playlist then do that
            if(app.playingPage.currentId !== queuePlaylistId) {
                app.controller.playContext({uri: queuePlaylistUri})
                return
            }

            // Queue Playlist is loaded but is not being played
            // ToDo dont use _IsPlaying
            if(!app.playingPage._isPlaying) {
                if(app.playingPage.currentSnapshotId === queuePlaylistSnapshotId)
                    app.controller.playPause()
                else
                    app.controller.playContext({uri: queuePlaylistUri})
                return
            }

            // maybe it is already working due to Playing page listening to Playlist edit events

            /*switch(category) {
            case 'AddedTrack':
                // if not yet playing we can start
                if(!app.playingPage.playbackState.is_playing)
                    app.controller.playContext({uri: queuePlaylistUri})
                else {
                    // we cannot restart. it would cause hickups.
                    // since we only allow add or replace all we wait for the current snapshot to end
                    // and then restart at the new track(s)
                }

                break;
            case 'ReplacedAllTracks':
                // stop if needed and start, hopefully Spotify uses the latest snapshot
                if(!app.playingPage.playbackState.is_playing)
                    pause(function(error, data) {
                        app.controller.playContext({uri: queuePlaylistUri})
                    })
                else
                    app.controller.playContext({uri: queuePlaylistUri})
                break;
            }*/
        })
    }

    function addToQueue(track) {
        getQueuePlaylist(function(success) {
            if(success) {
                Spotify.addTracksToPlaylist(queuePlaylistId, [track.uri], {}, function(error, data) {
                    if(data) {
                        queuePlaylistSnapshotId = data.snapshot_id
                        var ev = new Util.PlayListEvent(Util.PlaylistEventType.AddedTrack,
                                                        queuePlaylistId, data.snapshot_id)
                        ev.uri = queuePlaylistUri
                        ev.trackId = track.id
                        app.playlistEvent(ev)
                        ensureQueueIsPlaying('AddedTrack')
                        console.log("addToQueue: snapshot: " + data.snapshot_id + "added " + track.name)
                    } else {
                        showErrorMessage(undefined, qsTr("Failed to add Track to the Queue"))
                        console.log("addToPlaylist: failed to add " + track.name)
                    }
                })
            } else {
                showErrorMessage(undefined, qsTr("Failed to find Playlist for Queue"))
                console.log("addToPlaylist: failed to find  Playlist for Queue")
            }
        })
    }

    // Debugging
    /*Timer {
        interval: 5000
        running: app.hasValidToken && queuePlaylistId.length > 0
        repeat: true
        onTriggered: {
            Spotify.getPlaylist(queuePlaylistId, function(error, data) {
                if(data)
                    console.log("Timer.getPlaylist snapshot: " + data.snapshot_id + ", tracks: " + data.tracks.total)
            })
        }
    }*/

    function replaceQueueWith(uris) {
        getQueuePlaylist(function(success) {
            if(success) {
                app.replaceTracksInPlaylist(queuePlaylistId, uris, function(error, data) {
                    if(data) {
                        queuePlaylistSnapshotId = data.snapshot_id
                        ensureQueueIsPlaying('ReplacedAllTracks')
                    }
                })
            } else {
                showErrorMessage(undefined, qsTr("Failed to find Playlist for Queue"))
                console.log("replaceQueueWith: failed to find  Playlist for Queue")
            }
        })
    }


}
