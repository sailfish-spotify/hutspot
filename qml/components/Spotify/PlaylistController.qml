import QtQuick 2.0

import ".."
import "../../Util.js" as Util
import "../../Spotify.js" as Spotify

Item {
    property alias model: playlistModel
    property alias cursorHelper: cursorHelper
    property bool isFavorite: false
    signal scrollToIndexRequested(var i);

    ListModel { id: playlistModel }

    CursorHelper {
        id: cursorHelper
        onLoadNext: reloadTracks()
        onLoadPrevious: reloadTracks()
    }

    Connections {
        target: app

        onFavoriteEvent: {
            if(app.controller.playbackState.getCurrentId() === event.id) {
                isFavorite = event.isFavorite
            } else if(event.type === Util.SpotifyItemType.Track) {
                // no easy way to check if the track is in the model so just update
                Util.setSavedInfo(Spotify.ItemType.Track, [event.id], [event.isFavorite], model)
            }
        }

        onPlaylistEvent: {
            if(app.controller.playbackState.getContextType() !== Spotify.ItemType.Playlist
               || app.controller.playbackState.getCurrentId() !== event.playlistId)
                return

            // When a plylist is modified while being played the modifications
            // are ignored, it keeps on playing the snapshot that was started.
            // To try to fix this we:
            //   AddedTrack:
            //      wait for playing to end (last track of original snapshot) and then restart playing
            //   RemovedTrack:
            //      for now nothing
            //   ReplacedAllTracks:
            //      restart playing

            switch(event.type) {
            case Util.PlaylistEventType.AddedTrack:
                // in theory it has been added at the end of the list
                // so we could load the info and add it to the model but ...
                // ToDo what about cursorHelper.offset?
                loadPlaylistTracks(app.id, app.controller.playbackState.getCurrentId())
                if(app.controller.playbackState.is_playing) {
                    waitForEndOfSnapshot = true
                    waitForEndSnapshotData.uri = event.uri
                    waitForEndSnapshotData.snapshotId = event.snapshotId
                    waitForEndSnapshotData.index = app.controller.playbackState.contextDetails.tracks.total // not used
                    waitForEndSnapshotData.trackUri = event.trackUri
                } else
                    currentSnapshotId = event.snapshotId
                break
            case Util.PlaylistEventType.RemovedTrack:
                //Util.removeFromListModel(model, Spotify.ItemType.Track, event.trackId)
                //currentSnapshotId = event.snapshotId
                break
            case Util.PlaylistEventType.ReplacedAllTracks:
                if(app.controller.playbackState.is_playing)
                    app.controller.pause(function(error, data) {
                        playContext({uri: app.controller.playbackState.contextDetails.uri})
                    })
                else {
                    cursorHelper.offset = 0
                    loadPlaylistTracks(app.id, app.controller.playbackState.getCurrentId())
                }
                break
            }
        }
    }

    Connections {
        target: app.controller.playbackState

        onContextDetailsChanged: {
            var contextId = app.controller.playbackState.getCurrentId()
            console.log("onCurrentIdChanged: " + contextId)
            if (app.controller.playbackState.contextDetails) {
                switch (app.controller.playbackState.context.type) {
                    case 'album':
                        loadAlbumTracks(contextId)
                        break
                    case 'artist':
                        model.clear()
                        Spotify.isFollowingArtists([contextId], function(error, data) {
                            if(data)
                                isFavorite = data[0]
                        })
                        break
                    case 'playlist':
                        cursorHelper.offset = 0
                        loadPlaylistTracks(app.id, contextId)
                        loadPlaylistTrackInfo()
                        break
                }
            }
        }
    }

    function toggleSavedFollowed() {
        if(!app.controller.playbackState.context
           || !app.controller.playbackState.contextDetails)
            return
        switch(app.controller.playbackState.context.type) {
        case 'album':
            app.toggleSavedAlbum(app.controller.playbackState.contextDetails, isFavorite, function(saved) {
                isFavorite = saved
            })
            break
        case 'artist':
            app.toggleFollowArtist(app.controller.playbackState.contextDetails, isFavorite, function(followed) {
                isFavorite = followed
            })
            break
        case 'playlist':
            app.toggleFollowPlaylist(app.controller.playbackState.contextDetails, isFavorite, function(followed) {
                isFavorite = followed
            })
            break
        default: // track?
            if (app.controller.playbackState.item) { // Note uses globals
                if(isFavorite)
                    app.unSaveTrack(app.controller.playbackState.item, function(error,data) {
                        if(!error)
                            isFavorite = false
                    })
                else
                    app.saveTrack(app.controller.playbackState.item, function(error,data) {
                        if(!error)
                            isFavorite = true
                    })
            }
            break
        }
    }

    function reloadTracks() {
        switch(app.controller.playbackState.context.type) {
        case 'album':
            loadAlbumTracks(app.controller.playbackState.getCurrentId())
            break
        case 'playlist':
            loadPlaylistTracks(app.id, app.controller.playbackState.getCurrentId())
            break
        default:
            break
        }
    }

    function _loadAlbumTracks(id) {
        // 'market' enables 'track linking'
        var options = {offset: cursorHelper.offset, limit: cursorHelper.limit}
        if(app.query_for_market.value)
            options.market = "from_token"
            Spotify.getAlbumTracks(id, options, function(error, data) {
            if(data) {
                try {
                    console.log("number of AlbumTracks: " + data.items.length)
                    cursorHelper.offset = data.offset
                    cursorHelper.total = data.total
                    var trackIds = []
                    model.clear()
                    for(var i=0;i<data.items.length;i++) {
                        model.append({type: Spotify.ItemType.Track,
                                            stype: Spotify.ItemType.Album,
                                            name: data.items[i].name,
                                            saved: false,
                                            track: data.items[i]})
                        trackIds.push(data.items[i].id)
                    }
                    // get info about saved tracks
                    Spotify.containsMySavedTracks(trackIds, function(error, data) {
                        if(data)
                            Util.setSavedInfo(Spotify.ItemType.Track, trackIds, data, model)
                    })
                    // if the album has more tracks get more
                    if(cursorHelper.total > (cursorHelper.offset+cursorHelper.limit)) {
                        cursorHelper.offset += cursorHelper.limit
                        _loadAlbumTracks(id)
                    }
                    updateForCurrentTrack()
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getAlbumTracks")
            }
        })
    }

    function updateForCurrentTrack() {
        if (app.controller.playbackState.context) {
            switch(app.controller.playbackState.context.type) {
            case 'album':
                updateForCurrentAlbumTrack()
                break
            case 'playlist':
                updateForCurrentPlaylistTrack()
                break
            default:
                break
            }
        }
    }

    function updateForCurrentAlbumTrack() {
        // keep current track visible
        for(var i=0;i<model.count;i++)
            if(model.get(i).track.id === app.controller.playbackState.item.id) {
                scrollToIndexRequested(i)
                break
            }
    }

    // to be able to find the current track and load the correct set of tracks
    // we keep a list of all playlist tracks (Id,Uri)
    // (for albums we just load the first 100 and hope this is enough)
    property var tracksInfo: []

    function updateForCurrentPlaylistTrack() {
        for(var i=0;i<tracksInfo.length;i++) {
            if(tracksInfo[i].id === app.controller.playbackState.item.id) {
                // in currently loaded set?
                if(i >= cursorHelper.offset && i <= (cursorHelper.offset + cursorHelper.limit)) {
                    scrollToIndexRequested(i)
                    break
                } else {
                    // load set
                    cursorHelper.offset = i
                    loadPlaylistTracks(app.id, app.controller.playbackState.getCurrentId())
                }
            }
        }
    }

    function loadAlbumTracks(id) {
        model.clear()
        cursorHelper.offset = 0
        cursorHelper.limit = 50 // for now load as much as possible and hope it is enough
        _loadAlbumTracks(id)
        Spotify.containsMySavedAlbums([id], {}, function(error, data) {
            if(data)
                isFavorite = data[0]
        })
    }

    function loadPlaylistTracks(id, pid) {
        model.clear()
        app.getPlaylistTracks(pid, {offset: cursorHelper.offset, limit: cursorHelper.limit}, function(error, data) {
            if(data) {
                try {
                    console.log("number of PlaylistTracks: " + data.items.length)
                    cursorHelper.offset = data.offset
                    cursorHelper.total = data.total
                    for(var i=0;i<data.items.length;i++) {
                        model.append({type: Spotify.ItemType.Track,
                                            stype: Spotify.ItemType.Playlist,
                                            name: data.items[i].track.name,
                                            saved: false,
                                            track: data.items[i].track})
                    }
                    updateForCurrentTrack()
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getPlaylistTracks")
            }
        })
        app.isFollowingPlaylist(pid, function(error, data) {
            if(data)
                isFavorite = data[0]
        })
    }


    property var waitForEndSnapshotData: ({})
    property bool waitForEndOfSnapshot : false
    function pluOnStopped() {
        if(waitForEndOfSnapshot) {
            waitForEndOfSnapshot = false
            if(waitForEndSnapshotData.snapshotId !== currentSnapshotId) { // only if still needed
                playContext({uri: waitForEndSnapshotData.uri},
                            {offset: {uri: waitForEndSnapshotData.trackUri}})
            }
        }
    }

    function loadPlaylistTrackInfo() {
        if(tracksInfo.length > 0)
            tracksInfo = []
        _loadPlaylistTrackInfo(0)
    }

    function _loadPlaylistTrackInfo(offset) {
        app.getPlaylistTracks(app.controller.playbackState.getCurrentId(), {fields: "items(track(id,uri)),offset,total", offset: offset, limit: 100},
            function(error, data) {
                if(data) {
                    for(var i=0;i<data.items.length;i++)
                        tracksInfo[i+offset] = {id: data.items[i].track.id, uri: data.items[i].track.uri}
                    var nextOffset = data.offset+data.items.length
                    if(nextOffset < data.total)
                        _loadPlaylistTrackInfo(nextOffset)
                }
            })
    }

    // try to detect end of playlist play
    property bool _isPlaying: false
    Connections {
        target: app.controller.playbackState

        onIs_playingChanged: {
            if(!_isPlaying && app.controller.playbackState.is_playing) {
                updateForCurrentTrack()
                console.log("Started Playing")
            } else if(_isPlaying && !app.controller.playbackState.is_playing) {
                console.log("Stopped Playing")
                pluOnStopped()
            }

            _isPlaying = app.controller.playbackState.is_playing
        }
    }
}
