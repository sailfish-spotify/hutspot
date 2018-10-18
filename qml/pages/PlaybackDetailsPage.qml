/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 * Copyright (C) 2018 Maciej Janiszewski
 *
 * License: MIT
 */


import QtQuick 2.2
import QtGraphicalEffects 1.0
import Sailfish.Silica 1.0

import "../components"
import "../Spotify.js" as Spotify
import "../Util.js" as Util

Page {
    id: playingPage
    objectName: "PlaybackDetailsPage"

    property string defaultImageSource : "image://theme/icon-l-music"
    property bool showBusy: false
    property string viewMenuText: ""

    property int currentIndex: -1

    allowedOrientations: Orientation.All

    SilicaListView {
        id: listView
        model: app.playingPage.searchModel
        anchors.fill: parent
        clip: true

        header: Column {
            anchors.bottomMargin: Theme.paddingLarge
            width: parent.width

            LoadPullMenus {}
            LoadPushMenus {}

            PageHeader {
                width: parent.width
                title: getFirstLabelText()
                description: getSecondLabelText()
                MenuButton {}
            }

            Item {
                id: infoContainer

                // put MetaInfoPanel in Item to be able to make room for context menu
                width: parent.width - 2*Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                height: info.height + (cmenu ? cmenu.height : 0)

                MetaInfoPanel {
                    id: info
                    anchors.top: parent.top
                    firstLabelText: getFirstLabelText()
                    secondLabelText: getSecondLabelText()
                    thirdLabelText: getThirdLabelText()

                    isFavorite: app.playingPage.isContextFavorite
                    onToggleFavorite: toggleSavedFollowed()
                    onFirstLabelClicked: openMenu()
                    onSecondLabelClicked: openMenu()
                    onThirdLabelClicked: openMenu()

                    function openMenu() {
                        cmenu.update()
                        cmenu.open(infoContainer)
                    }
                }
            }

            ContextMenu {
                id: cmenu

                function update() {
                    viewAlbum.enabled = false
                    viewArtist.enabled = false
                    viewPlaylist.enabled = false
                    switch(getContextType()) {
                    case Spotify.ItemType.Album:
                        viewAlbum.enabled = true
                        viewArtist.enabled = true
                        break
                    case Spotify.ItemType.Artist:
                        viewArtist.enabled = true
                        break
                    case Spotify.ItemType.Playlist:
                        viewPlaylist.enabled = true
                        break
                    case Spotify.ItemType.Track:
                        viewAlbum.enabled = true
                        viewArtist.enabled = false
                        break
                    }
                }

                MenuItem {
                    id: viewAlbum
                    text: qsTr("View Album")
                    visible: enabled
                    onClicked: {
                        switch(getContextType()) {
                        case Spotify.ItemType.Album:
                            app.pushPage(Util.HutspotPage.Album, {album: app.controller.playbackState.context}, true)
                            break
                        case Spotify.ItemType.Track:
                            app.pushPage(Util.HutspotPage.Album, {album: app.controller.playbackState.item.album}, true)
                            break
                        }
                    }
                }
                MenuItem {
                    id: viewArtist
                    visible: enabled
                    text: qsTr("View Artist")
                    onClicked: {
                        switch(getContextType()) {
                        case Spotify.ItemType.Album:
                            app.loadArtist(app.controller.playbackState.contextDetails.artists, true)
                            break
                        case Spotify.ItemType.Artist:
                            app.pushPage(Util.HutspotPage.Artist, {currentArtist: app.controller.playbackState.context}, true)
                            break
                        case Spotify.ItemType.Track:
                            app.loadArtist(app.controller.playbackState.item.artists, true)
                            break
                        }
                    }
                }
                MenuItem {
                    id: viewPlaylist
                    visible: enabled
                    text: qsTr("View Playlist")
                    onClicked: app.pushPage(Util.HutspotPage.Playlist, {playlist: app.controller.playbackState.context}, true)
                }
            }

            Rectangle {
                width: parent.width
                height: Theme.paddingMedium
                opacity: 0
            }

            Separator {
                width: parent.width
                color: Theme.primaryColor
            }

            Rectangle {
                width: parent.width
                height: Theme.paddingMedium
                opacity: 0
            }
        }

        delegate: ListItem {
            id: listItem
            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium
            contentHeight: stype == 0
                           ? Theme.itemSizeExtraSmall
                           : Theme.itemSizeLarge

            Loader {
                id: loader

                width: parent.width

                source: stype > 0
                        ? "../components/SearchResultListItem.qml"
                        : "../components/AlbumTrackListItem.qml"

                Binding {
                  target: loader.item
                  property: "dataModel"
                  value: model
                  when: loader.status == Loader.Ready
                }
                Binding {
                    target: loader.item
                    property: "isFavorite"
                    value: saved
                    when: stype === 0
                }
            }

            menu: AlbumTrackContextMenu {}

            Connections {
                target: loader.item
                onToggleFavorite: app.toggleSavedTrack(model)
            }

            onClicked: app.controller.playTrackInContext(track, app.controller.playbackState.context)
        }

        VerticalScrollDecorator {}

        Connections {
            target: app.playingPage
            onCurrentTrackIdChanged: updateForCurrentTrack()
        }
    }

    function getFirstLabelText() {
        var s = ""
        if(app.controller.playbackState === undefined)
             return s
        if(!app.controller.playbackState.context)
            return app.controller.playbackState.item ? app.controller.playbackState.item.name : ""
        if(app.controller.playbackState.context === null)
            return s
        return app.controller.playbackState.contextDetails.name
    }

    function getSecondLabelText() {
        var s = ""
        if(app.controller.playbackState === undefined)
             return s
        if(!app.controller.playbackState.context) {
            // no context (a single track?)
            if(app.controller.playbackState.item && app.controller.playbackState.item.album) {
                s += app.controller.playbackState.item.album.name
                if (app.controller.playbackState.item.album.release_date)
                    s += ", " + Util.getYearFromReleaseDate(app.controller.playbackState.item.album.release_date)
            }
            return s
        }
        if(app.controller.playbackState.context === null)
            return s
        switch(app.controller.playbackState.context.type) {
        case 'album':
            s += Util.createItemsString(app.controller.playbackState.contextDetails.artists, qsTr("no artist known"))
            break
        case 'artist':
            s += Util.createItemsString(app.controller.playbackState.contextDetails.genres, qsTr("no genre known"))
            break
        case 'playlist':
            s+= app.controller.playbackState.contextDetails.description
            break
        }
        return s
    }

    function getThirdLabelText() {
        var s = ""
        if(app.controller.playbackState === undefined)
             return s
        if(!app.controller.playbackState.context) {
            // no context (a single track?)
            if(app.controller.playbackState.item && app.controller.playbackState.item.artists)
                s += Util.createItemsString(app.controller.playbackState.item.artists, qsTr("no artist known"))
            return s
        }
        if(!app.controller.playbackState.contextDetails)
            return
        switch(app.controller.playbackState.context.type) {
        case 'album':
            if(app.controller.playbackState.contextDetails.tracks)
                s += app.controller.playbackState.contextDetails.tracks.total + " " + qsTr("tracks")
            else if(app.controller.playbackState.contextDetails.album_type === "single")
                s += "1 " + qsTr("track")
            if (app.controller.playbackState.contextDetails.release_date)
                s += ", " + Util.getYearFromReleaseDate(app.controller.playbackState.contextDetails.release_date)
            if(app.controller.playbackState.contextDetails.genres && app.controller.playbackState.contextDetails.genres.lenght > 0)
                s += ", " + Util.createItemsString(app.controller.playbackState.contextDetails.genres, "")
            break
        case 'artist':
            if(app.controller.playbackState.contextDetails.followers && app.controller.playbackState.contextDetails.followers.total > 0)
                s += Util.abbreviateNumber(app.controller.playbackState.contextDetails.followers.total) + " " + qsTr("followers")
            break
        case 'playlist':
            s += app.controller.playbackState.contextDetails.tracks.total + " " + qsTr("tracks")
            s += ", " + qsTr("by") + " " + app.controller.playbackState.contextDetails.owner.display_name
            if(app.controller.playbackState.contextDetails.followers && app.controller.playbackState.contextDetails.followers.total > 0)
                s += ", " + Util.abbreviateNumber(app.controller.playbackState.contextDetails.followers.total) + " " + qsTr("followers")
            if(app.controller.playbackState.context["public"])
                s += ", " +  qsTr("public")
            if(app.controller.playbackState.contextDetails.collaborative)
                s += ", " +  qsTr("collaborative")
            break
        }
        return s
    }

    function getContextType() {
        if(!app.controller.playbackState || !app.controller.playbackState.item)
            return -1

        if (app.controller.playbackState.context)
            switch(app.controller.playbackState.context.type) {
            case 'album':
                return Spotify.ItemType.Album
            case 'artist':
                return Spotify.ItemType.Artist
            case 'playlist':
                return Spotify.ItemType.Playlist
            }
        return Spotify.ItemType.Track
    }

    function updateForCurrentAlbumTrack() {
        // keep current track visible
        currentIndex = -1
        for(var i=0;i<app.playingPage.searchModel.count;i++)
            if(app.playingPage.searchModel.get(i).track.id === app.playingPage.currentTrackId) {
                listView.positionViewAtIndex(i, ListView.Visible)
                currentIndex = i
                break
            }
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

    // to be able to find the current track and load the correct set of tracks
    // we keep a list of all playlist tracks (Id,Uri)
    // (for albums we just load the first 100 and hope this is enough)
    property var tracksInfo: []

    function updateForCurrentPlaylistTrack() {
        currentIndex = -1
        for(var i=0;i<tracksInfo.length;i++) {
            if(tracksInfo[i].id === app.playingPage.currentTrackId) {
                // in currently loaded set?
                if(i >= cursorHelper.offset && i <= (cursorHelper.offset + cursorHelper.limit)) {
                    listView.positionViewAtIndex(i, ListView.Visible)
                    currentIndex = i
                    break
                } else {
                    // load set
                    cursorHelper.offset = i
                    loadPlaylistTracks(app.id, app.playingPage.currentId)
                    currentIndex = 0
                }
            }
        }
    }

    function loadPlaylistTrackInfo() {
        if(tracksInfo.length > 0)
            tracksInfo = []
        _loadPlaylistTrackInfo(0)
    }

    function _loadPlaylistTrackInfo(offset) {
        app.getPlaylistTracks(app.playingPage.currentId, {fields: "items(track(id,uri)),offset,total", offset: offset, limit: 100},
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

    // called by menus
    function refresh() {
        reloadTracks()
    }

    Connections {
        target: app.playingPage
        onCurrentIdChanged: {
            console.log("onCurrentIdChanged: " + app.playingPage.currentId)
            if (app.controller.playbackState.context) {
                switch (app.controller.playbackState.context.type) {
                    case 'album':
                        loadAlbumTracks(app.playingPage.currentId)
                        break
                    case 'artist':
                        app.playingPage.searchModel.clear()
                        Spotify.isFollowingArtists([app.playingPage.currentId], function(error, data) {
                            if(data)
                                app.playingPage.isContextFavorite = data[0]
                        })
                        break
                    case 'playlist':
                        cursorHelper.offset = 0
                        loadPlaylistTracks(app.id, app.playingPage.currentId)
                        loadPlaylistTrackInfo()
                        break
                }
            }
        }
    }

    // try to detect end of playlist play
    property bool _isPlaying: false
    Connections {
        target: app.controller.playbackState

        onContextDetailsChanged: {
            app.playingPage.currentId = app.controller.playbackState.contextDetails.id
            /*switch (app.controller.playbackState.context.type) {
                case 'album':
                    break
                case 'artist':
                    break
                case 'playlist':
                    break
            }*/
        }

        onItemChanged: {
            if (app.controller.playbackState.context) {
            } else {
                // no context (a single track?)
                app.playingPage.currentId = app.controller.playbackState.item.id
                console.log("  no context: " + app.playingPage.currentId)
            }
            app.playingPage.currentTrackId = app.controller.playbackState.item.id
            // still needed? app.playingPage.currentTrackuri = app.controller.playbackState.item.uri
        }
        onIs_playingChanged: {
            if(!_isPlaying && app.controller.playbackState.is_playing) {
                if(currentIndex === -1)
                    updateForCurrentTrack()
                console.log("Started Playing")
            } else if(_isPlaying && !app.controller.playbackState.is_playing) {
                console.log("Stopped Playing")
                pluOnStopped()
            }

            _isPlaying = app.controller.playbackState.is_playing
        }
    }

    function reloadTracks() {
        switch(app.controller.playbackState.context.type) {
        case 'album':
            loadAlbumTracks(app.playingPage.currentId)
            break
        case 'playlist':
            loadPlaylistTracks(app.id, app.playingPage.currentId)
            break
        default:
            break
        }
    }

    function loadPlaylistTracks(id, pid) {
        app.playingPage.searchModel.clear()
        app.getPlaylistTracks(pid, {offset: cursorHelper.offset, limit: cursorHelper.limit}, function(error, data) {
            if(data) {
                try {
                    console.log("number of PlaylistTracks: " + data.items.length)
                    cursorHelper.offset = data.offset
                    cursorHelper.total = data.total
                    for(var i=0;i<data.items.length;i++) {
                        app.playingPage.searchModel.append({type: Spotify.ItemType.Track,
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
                app.playingPage.isContextFavorite = data[0]
        })
    }

    function loadAlbumTracks(id) {
        app.playingPage.searchModel.clear()
        cursorHelper.offset = 0
        cursorHelper.limit = 50 // for now load as much as possible and hope it is enough
        _loadAlbumTracks(id)
        Spotify.containsMySavedAlbums([id], {}, function(error, data) {
            if(data)
                app.playingPage.isContextFavorite = data[0]
        })
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
                    for(var i=0;i<data.items.length;i++) {
                        app.playingPage.searchModel.append({type: Spotify.ItemType.Track,
                                            stype: Spotify.ItemType.Album,
                                            name: data.items[i].name,
                                            saved: false,
                                            track: data.items[i]})
                        trackIds.push(data.items[i].id)
                    }
                    // get info about saved tracks
                    Spotify.containsMySavedTracks(trackIds, function(error, data) {
                        if(data)
                            Util.setSavedInfo(Spotify.ItemType.Track, trackIds, data, app.playingPage.searchModel)
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

    function toggleSavedFollowed() {
        if(!app.controller.playbackState.context
           || !app.controller.playbackState.contextDetails)
            return
        switch(app.controller.playbackState.context.type) {
        case 'album':
            app.toggleSavedAlbum(app.controller.playbackState.contextDetails, app.playingPage.isContextFavorite, function(saved) {
                app.playingPage.isContextFavorite = saved
            })
            break
        case 'artist':
            app.toggleFollowArtist(app.controller.playbackState.contextDetails, app.playingPage.isContextFavorite, function(followed) {
                app.playingPage.isContextFavorite = followed
            })
            break
        case 'playlist':
            app.toggleFollowPlaylist(app.controller.playbackState.contextDetails, app.playingPage.isContextFavorite, function(followed) {
                app.playingPage.isContextFavorite = followed
            })
            break
        default: // track?
            if (app.controller.playbackState.item) { // Note uses globals
                if(app.playingPage.isContextFavorite)
                    app.unSaveTrack(app.controller.playbackState.item, function(error,data) {
                        if(!error)
                            app.playingPage.isContextFavorite = false
                    })
                else
                    app.saveTrack(app.controller.playbackState.item, function(error,data) {
                        if(!error)
                            app.playingPage.isContextFavorite = true
                    })
            }
            break
        }
    }

    property alias cursorHelper: cursorHelper

    CursorHelper {
        id: cursorHelper

        onLoadNext: reloadTracks()
        onLoadPrevious: reloadTracks()
    }

    /*property bool canLoad: {
        var ct = getContextType()
        return ct === Spotify.ItemType.Album || ct === Spotify.ItemType.Playlist
    }*/

    //
    // Playlist Utilities
    //

    property var waitForEndSnapshotData: ({})
    property bool waitForEndOfSnapshot : false
    function pluOnStopped() {
        if(waitForEndOfSnapshot) {
            waitForEndOfSnapshot = false
            if(waitForEndSnapshotData.snapshotId !== app.playingPage.currentSnapshotId) { // only if still needed
                app.playingPage.currentId = "" // trigger reload
                playContext({uri: waitForEndSnapshotData.uri},
                            {offset: {uri: waitForEndSnapshotData.trackUri}})
            }
        }
    }

    Connections {
        target: app

        onPlaylistEvent: {
            if(getContextType() !== Spotify.ItemType.Playlist
               || app.controller.playbackState.contextDetails.id !== event.playlistId)
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
                loadPlaylistTracks(app.id, app.playingPage.currentId)
                if(app.controller.playbackState.is_playing) {
                    waitForEndOfSnapshot = true
                    waitForEndSnapshotData.uri = event.uri
                    waitForEndSnapshotData.snapshotId = event.snapshotId
                    waitForEndSnapshotData.index = app.controller.playbackState.contextDetails.tracks.total // not used
                    waitForEndSnapshotData.trackUri = event.trackUri
                } else
                    app.playingPage.currentSnapshotId = event.snapshotId
                break
            case Util.PlaylistEventType.RemovedTrack:
                //Util.removeFromListModel(app.playingPage.searchModel, Spotify.ItemType.Track, event.trackId)
                //app.playingPage.currentSnapshotId = event.snapshotId
                break
            case Util.PlaylistEventType.ReplacedAllTracks:
                if(app.controller.playbackState.is_playing)
                    app.controller.pause(function(error, data) {
                        app.playingPage.currentId = "" // trigger reload)
                        playContext({uri: app.controller.playbackState.contextDetails.uri})
                    })
                else {
                    cursorHelper.offset = 0
                    loadPlaylistTracks(app.id, app.playingPage.currentId)
                }
                break
            }
        }
        onFavoriteEvent: {
            if(app.playingPage.currentId === event.id) {
                app.playingPage.isContextFavorite = event.isFavorite
            } else if(event.type === Util.SpotifyItemType.Track) {
                // no easy way to check if the track is in the model so just update
                Util.setSavedInfo(Spotify.ItemType.Track, [event.id], [event.isFavorite], app.playingPage.searchModel)
            }
        }
    }

    // The shared DockedPanel needs mouse events
    // and some ListView events
    propagateComposedEvents: true
    onStatusChanged: {
        switch (status) {
        case PageStatus.Active:
            // reset transition on glassyBackground
            app.glassyBackground.state = ""
            app.glassyBackground.state = "Visible"
            app.glassyBackground.showTrackInfo = false
            break;
        case PageStatus.Activating:
            app.glassyBackground.state = ""
            app.glassyBackground.state = "Visible"
            app.dockedPanel.setHidden()
            app.dockedPanel.registerListView(listView)
            break;
        case PageStatus.Deactivating:
            app.dockedPanel.unregisterListView(listView)
            break;
        }
    }
}
