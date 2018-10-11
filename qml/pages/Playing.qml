/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 * Copyright (C) 2018 Maciej Janiszewski
 *
 * License: MIT
 */


import QtQuick 2.2
import Sailfish.Silica 1.0

import "../components"
import "../Spotify.js" as Spotify
import "../Util.js" as Util

Page {
    id: playingPage
    objectName: "PlayingPage"

    property string defaultImageSource : "image://theme/icon-l-music"
    property bool showBusy: false
    property string pageHeaderText: qsTr("Playing")
    property string pageHeaderDescription: ""

    property bool isContextFavorite: false

    property string currentId: ""
    property string currentSnapshotId: ""
    property string currentTrackId: ""
    property string currentTrackUri: ""

    property string viewMenuText: ""
    property bool showTrackInfo: true

    property int currentIndex: -1

    property int mutedVolume: -1
    property bool muted: false

    allowedOrientations: Orientation.All

    ListModel {
        id: searchModel
    }

    Item {
        id: upper
        anchors.left: parent.left
        anchors.top: parent.top
        height: parent.height - app.dockedPanel.visibleSize
        clip: app.dockedPanel.expanded

        SilicaListView {
            id: listView
            model: searchModel

            width: parent.width
            anchors.fill: parent
            clip: true

            header: Column {
                id: lvColumn

                width: parent.width - 2*Theme.paddingMedium
                x: Theme.paddingMedium
                anchors.bottomMargin: Theme.paddingLarge

                LoadPullMenus {}
                LoadPushMenus {}

                PageHeader {
                    id: pHeader
                    width: parent.width
                    title: pageHeaderText
                    description: pageHeaderDescription
                    anchors.horizontalCenter: parent.horizontalCenter
                    MenuButton {}
                }

                Image {
                    id: imageItem
                    anchors.horizontalCenter: parent.horizontalCenter
                    source:  app.controller.getCoverArt(defaultImageSource, showTrackInfo)
                    width: parent.width * 0.75
                    height: width
                    fillMode: Image.PreserveAspectFit
                    onPaintedHeightChanged: height = Math.min(parent.width, paintedHeight)
                    MouseArea {
                        anchors.fill: parent
                        onClicked: showTrackInfo = !showTrackInfo
                    }
                }

                Item {
                    id: infoContainer

                    // put MetaInfoPanel in Item to be able to make room for context menu
                    width: parent.width
                    height: info.height + (cmenu ? cmenu.height : 0)

                    MetaInfoPanel {
                        id: info
                        anchors.top: parent.top
                        firstLabelText: getFirstLabelText()
                        secondLabelText: getSecondLabelText()
                        thirdLabelText: getThirdLabelText()

                        isFavorite: isContextFavorite
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

                /*Label {
                    truncationMode: TruncationMode.Fade
                    width: parent.width
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.Wrap
                    text:  (app.controller.playbackState && app.controller.playbackState.device)
                            ? qsTr("on: ") + app.controller.playbackState.device.name + " (" + app.controller.playbackState.device.type + ")"
                            : qsTr("none")
                }*/

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

            /*ViewPlaceholder {
                enabled: listView.count === 0
                text: qsTr("Nothing to play")
            }*/

            Connections {
                target: playingPage
                onCurrentTrackIdChanged: updateForCurrentTrack()
            }
            /* atYEnd is never true. caused by the docked panel?
            onContentYChanged: {
                 if(atYEnd && canLoadNext) {
                     app.showConfirmDialog(qsTr("Reached end of list.<br>Try to the load next set?"),
                         function() {
                            loadNext()
                         })
                 }
            }*/
        }
    } // Item

    PanelBackground { //
    // Item { for transparant controlpanel
        id: controlPanel
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: parent.width
        height: col.height
        opacity: app.dockedPanel.open ? 0.0 : 1.0

        Column {
            id: col
            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium

            Row {
                width: parent.width
                Label {
                    id: progressLabel
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.verticalCenter: parent.verticalCenter
                    text: Util.getDurationString(app.controller.playbackState.progress_ms)
                }
                Slider {
                    id: progressSlider
                    property bool isPressed: false
                    height: progressLabel.height * 1.5
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - durationLabel.width - progressLabel.width
                    minimumValue: 0
                    maximumValue: app.controller.playbackState.item.duration_ms
                    handleVisible: false
                    onPressed: isPressed = true
                    onReleased: {
                        Spotify.seek(Math.round(value), function(error, data) {
                            app.controller.playbackState.progress_ms = Math.round(value)
                         })
                        isPressed = false
                    }
                    Connections {
                        target: app.controller.playbackState
                        // cannot use 'value: playbackProgress' since press/drag
                        // breaks the link between them
                        onProgress_msChanged: {
                            if(!progressSlider.isPressed)
                                progressSlider.value = app.controller.playbackState.progress_ms
                        }
                    }
                }
                Label {
                    id: durationLabel
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.verticalCenter: parent.verticalCenter
                    text: Util.getDurationString(app.controller.playbackState.item.duration_ms)
                }
            }

            // This works but Spotify has no 'mute' so maybe we should not do it as well
            /*Item {
                width: parent.width
                height: Math.max(muteIcon.height, volumeSlider.height)

                Image {
                    id: muteIcon
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    source: muted ? "image://theme/icon-m-speaker" : "image://theme/icon-m-speaker-mute"
                    MouseArea {
                         anchors.fill: parent
                         onClicked: {
                             if(muted) {
                                 Spotify.setVolume(mutedVolume, function(error, data) {
                                     if(!error) {
                                         volumeSlider.value = mutedVolume
                                         app.controller.refreshPlaybackState()
                                     }
                                 })
                             } else {
                                 mutedVolume = volumeSlider.value
                                 Spotify.setVolume(0, function(error, data) {
                                     if(!error) {
                                         volumeSlider.value = 0
                                         app.controller.refreshPlaybackState()
                                     }
                                 })
                             }
                             muted = !muted
                         }
                    }
                }*/

                Slider {
                    id: volumeSlider
                    width: parent.width
                    /*anchors.left: muteIcon.right
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter*/
                    minimumValue: 0
                    maximumValue: 100
                    handleVisible: false
                    value: app.controller.playbackState.device.volume_percent
                    onReleased: {
                        Spotify.setVolume(Math.round(value), function(error, data) {
                            if(!error)
                                app.controller.refreshPlaybackState();
                        })
                    }
                }
            /*}*/

            Row {
                id: buttonRow
                width: parent.width
                property real itemWidth : width / 5

                IconButton {
                    width: buttonRow.itemWidth
                    // enabled: app.mprisPlayer.canGoPrevious
                    icon.source: "image://theme/icon-m-previous"
                    onClicked: app.controller.previous()
                }
                IconButton {
                    width: buttonRow.itemWidth
                    icon.source: app.controller.playbackState.is_playing
                                 ? "image://theme/icon-cover-pause"
                                 : "image://theme/icon-cover-play"
                    onClicked: app.controller.playPause()
                }
                IconButton {
                    width: buttonRow.itemWidth
                    // enabled: app.mprisPlayer.canGoNext
                    icon.source: "image://theme/icon-m-next"
                    onClicked: app.controller.next()
                }
                IconButton {
                    width: buttonRow.itemWidth
                    icon.source: (app.controller.playbackState && app.controller.playbackState.repeat_state)
                                 ? "image://theme/icon-m-repeat?" + Theme.highlightColor
                                 : "image://theme/icon-m-repeat"
                    onClicked: app.controller.setRepeat(checked)
                }
                IconButton {
                    width: buttonRow.itemWidth
                    icon.source: (app.controller.playbackState && app.controller.playbackState.shuffle_state)
                                 ? "image://theme/icon-m-shuffle?" + Theme.highlightColor
                                 : "image://theme/icon-m-shuffle"
                    onClicked: app.controller.setShuffle(checked)
                }
            }
        }
    } // Control Panel

    function getFirstLabelText() {
        var s = ""
        if(app.controller.playbackState === undefined)
             return s
        if(!app.controller.playbackState.context || showTrackInfo)
            return app.controller.playbackState.item ? app.controller.playbackState.item.name : ""
        if(app.controller.playbackState.context === null)
            return s
        return app.controller.playbackState.contextDetails.name
    }

    function getSecondLabelText() {
        var s = ""
        if(app.controller.playbackState === undefined)
             return s
        if(!app.controller.playbackState.context || showTrackInfo) {
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
        if(!app.controller.playbackState.context || showTrackInfo) {
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
        for(var i=0;i<searchModel.count;i++)
            if(searchModel.get(i).track.id === currentTrackId) {
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
            if(tracksInfo[i].id === currentTrackId) {
                // in currently loaded set?
                if(i >= cursorHelper.offset && i <= (cursorHelper.offset + cursorHelper.limit)) {
                    listView.positionViewAtIndex(i, ListView.Visible)
                    currentIndex = i
                    break
                } else {
                    // load set
                    cursorHelper.offset = i
                    loadPlaylistTracks(app.id, currentId)
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
        app.getPlaylistTracks(currentId, {fields: "items(track(id,uri)),offset,total", offset: offset, limit: 100},
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

    onCurrentIdChanged: {
        console.log("onCurrentIdChanged: " + currentId)
        if (app.controller.playbackState.context) {
            switch (app.controller.playbackState.context.type) {
                case 'album':
                    loadAlbumTracks(currentId)
                    break
                case 'artist':
                    searchModel.clear()
                    Spotify.isFollowingArtists([currentId], function(error, data) {
                        if(data)
                            isContextFavorite = data[0]
                    })
                    break
                case 'playlist':
                    cursorHelper.offset = 0
                    loadPlaylistTracks(app.id, currentId)
                    loadPlaylistTrackInfo()
                    break
            }
        }
    }

    // try to detect end of playlist play
    property bool _isPlaying: false
    Connections {
        target: app.controller.playbackState

        onContextDetailsChanged: {
            currentId = app.controller.playbackState.contextDetails.id
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
                switch (app.controller.playbackState.context.type) {
                    case 'album':
                        pageHeaderDescription = app.controller.playbackState.item.album.name
                        break
                    case 'artist':
                        pageHeaderDescription = app.controller.playbackState.artistsString
                        break
                    case 'playlist':
                        pageHeaderDescription = app.controller.playbackState.contextDetails.name
                        break
                    default:
                        pageHeaderDescription = ""
                        break
                }
            } else {
                // no context (a single track?)
                currentId = app.controller.playbackState.item.id
                console.log("  no context: " + currentId)
                pageHeaderDescription = ""
            }
            currentTrackId = app.controller.playbackState.item.id
            // still needed? currentTrackUri = app.controller.playbackState.item.uri
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
            loadAlbumTracks(currentId)
            break
        case 'playlist':
            loadPlaylistTracks(app.id, currentId)
            break
        default:
            break
        }
    }

    function loadPlaylistTracks(id, pid) {
        searchModel.clear()
        app.getPlaylistTracks(pid, {offset: cursorHelper.offset, limit: cursorHelper.limit}, function(error, data) {
            if(data) {
                try {
                    console.log("number of PlaylistTracks: " + data.items.length)
                    cursorHelper.offset = data.offset
                    cursorHelper.total = data.total
                    for(var i=0;i<data.items.length;i++) {
                        searchModel.append({type: Spotify.ItemType.Track,
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
                isContextFavorite = data[0]
        })
    }

    function loadAlbumTracks(id) {
        searchModel.clear()
        cursorHelper.offset = 0
        cursorHelper.limit = 50 // for now load as much as possible and hope it is enough
        _loadAlbumTracks(id)
        Spotify.containsMySavedAlbums([id], {}, function(error, data) {
            if(data)
                isContextFavorite = data[0]
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
                        searchModel.append({type: Spotify.ItemType.Track,
                                            stype: Spotify.ItemType.Album,
                                            name: data.items[i].name,
                                            saved: false,
                                            track: data.items[i]})
                        trackIds.push(data.items[i].id)
                    }
                    // get info about saved tracks
                    Spotify.containsMySavedTracks(trackIds, function(error, data) {
                        if(data)
                            Util.setSavedInfo(Spotify.ItemType.Track, trackIds, data, searchModel)
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
            app.toggleSavedAlbum(app.controller.playbackState.contextDetails, isContextFavorite, function(saved) {
                isContextFavorite = saved
            })
            break
        case 'artist':
            app.toggleFollowArtist(app.controller.playbackState.contextDetails, isContextFavorite, function(followed) {
                isContextFavorite = followed
            })
            break
        case 'playlist':
            app.toggleFollowPlaylist(app.controller.playbackState.contextDetails, isContextFavorite, function(followed) {
                isContextFavorite = followed
            })
            break
        default: // track?
            if (app.controller.playbackState.item) { // Note uses globals
                if(isContextFavorite)
                    app.unSaveTrack(app.controller.playbackState.item, function(error,data) {
                        if(!error)
                            isContextFavorite = false
                    })
                else
                    app.saveTrack(app.controller.playbackState.item, function(error,data) {
                        if(!error)
                            isContextFavorite = true
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
            if(waitForEndSnapshotData.snapshotId !== currentSnapshotId) { // only if still needed
                currentId = "" // trigger reload
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
                loadPlaylistTracks(app.id, currentId)
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
                //Util.removeFromListModel(searchModel, Spotify.ItemType.Track, event.trackId)
                //currentSnapshotId = event.snapshotId
                break
            case Util.PlaylistEventType.ReplacedAllTracks:
                if(app.controller.playbackState.is_playing)
                    app.controller.pause(function(error, data) {
                        currentId = "" // trigger reload)
                        playContext({uri: app.controller.playbackState.contextDetails.uri})
                    })
                else {
                    cursorHelper.offset = 0
                    loadPlaylistTracks(app.id, currentId)
                }
                break
            }
        }
        onFavoriteEvent: {
            if(currentId === event.id) {
                isContextFavorite = event.isFavorite
            } else if(event.type === Util.SpotifyItemType.Track) {
                // no easy way to check if the track is in the model so just update
                Util.setSavedInfo(Spotify.ItemType.Track, [event.id], [event.isFavorite], searchModel)
            }
        }
    }

    // The shared DockedPanel needs mouse events
    // and some ListView events
    propagateComposedEvents: true
    onStatusChanged: {
        if(status === PageStatus.Active && app.playing_as_attached_page.value)
            pageStack.pushAttached(Qt.resolvedUrl("NavigationMenu.qml"), {popOnExit: false})

        if(status === PageStatus.Activating)
            app.dockedPanel.registerListView(listView)
        else if(status === PageStatus.Deactivating)
            app.dockedPanel.unregisterListView(listView)
    }

}
