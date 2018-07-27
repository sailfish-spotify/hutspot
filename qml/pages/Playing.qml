/**
 * Copyright (C) 2018 Willem-Jan de Hoog
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

    property var playingObject
    property var playbackState
    property var contextObject: null
    property bool isContextFavorite: false
    property string currentId: ""
    property string currentTrackId: ""

    property string viewMenuText: ""

    property int offset: 0
    property int limit: app.searchLimit.value
    property bool canLoadNext: true
    property bool canLoadPrevious: offset >= limit
    property int currentIndex: -1
    property int playbackProgress: 0

    allowedOrientations: Orientation.All

    ListModel {
        id: searchModel
    }

    Item {
        id: upper
        anchors.left: parent.left
        anchors.top: parent.top
        height: parent.height - controlPanel.height
        width: parent.width

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

                PageHeader {
                    id: pHeader
                    width: parent.width
                    title: pageHeaderText
                    anchors.horizontalCenter: parent.horizontalCenter
                    MenuButton {}
                }

                Image {
                    id: imageItem
                    anchors.horizontalCenter: parent.horizontalCenter
                    source:  (playingObject && playingObject.item)
                             ? playingObject.item.album.images[0].url : defaultImageSource
                    width: parent.width * 0.75
                    height: width
                    fillMode: Image.PreserveAspectFit
                    onPaintedHeightChanged: height = Math.min(parent.width, paintedHeight)
                }

                Item {
                    id: infoContainer

                    // put MetaInfoPanel in Item to be able to make room for context menu
                    width: parent.width
                    height: info.height + (cmenu ? cmenu.height : 0)

                    MetaInfoPanel {
                        id: info
                        anchors.top: parent.top
                        firstLabelText: getFirstLabelText(playbackState, contextObject)
                        secondLabelText: getSecondLabelText(playbackState, contextObject)
                        thirdLabelText: getThirdLabelText(playbackState, contextObject)

                        isFavorite: isContextFavorite
                        onToggleFavorite: toggleSavedFollowed(playbackState, contextObject)
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
                                pageStack.push(Qt.resolvedUrl("../pages/Album.qml"), {album: contextObject})
                                break
                            case Spotify.ItemType.Track:
                                pageStack.push(Qt.resolvedUrl("../pages/Album.qml"), {album: playingObject.item.album})
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
                                app.loadArtist(contextObject.artists)
                                break
                            case Spotify.ItemType.Artist:
                                pageStack.push(Qt.resolvedUrl("../pages/Artist.qml"), {currentArtist: contextObject})
                                break
                            case Spotify.ItemType.Track:
                                app.loadArtist(playingObject.item.artists)
                                break
                            }
                        }
                    }
                    MenuItem {
                        id: viewPlaylist
                        visible: enabled
                        text: qsTr("View Playlist")
                        onClicked: pageStack.push(Qt.resolvedUrl("../pages/Playlist.qml"), {playlist: contextObject})
                    }
                }

                /*Label {
                    truncationMode: TruncationMode.Fade
                    width: parent.width
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.Wrap
                    text:  (playbackState && playbackState.device)
                            ? qsTr("on: ") + playbackState.device.name + " (" + playbackState.device.type + ")"
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

                onClicked: app.playTrack(track)
            }

            VerticalScrollDecorator {}

            /*Label {
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignBottom
                visible: parent.count == 0
                text: qsTr("No tracks found")
                color: Theme.secondaryColor
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
        opacity: navPanel.open ? 0.0 : 1.0

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
                    text: Util.getDurationString(playbackProgress)
                }
                Slider {
                    height: progressLabel.height * 1.5
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - durationLabel.width - progressLabel.width
                    minimumValue: 0
                    maximumValue: (playbackState && playbackState.item)
                                  ? playbackState.item.duration_ms
                                  : 0
                    handleVisible: false
                    value: playbackProgress
                    onReleased: {
                        Spotify.seek(Math.round(value), function(error, data) {
                            if(!error)
                                refresh()
                        })
                    }
                }
                Label {
                    id: durationLabel
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.verticalCenter: parent.verticalCenter
                    text: (playbackState && playbackState.item)
                          ? Util.getDurationString(playbackState.item.duration_ms)
                          : ""
                }
            }

            Slider {
                id: volumeSlider
                width: parent.width
                minimumValue: 0
                maximumValue: 100
                handleVisible: false
                value: (playbackState && playbackState.device)
                       ? playbackState.device.volume_percent : 0
                onReleased: {
                    Spotify.setVolume(Math.round(value), function(error, data) {
                        if(!error)
                            refresh()
                    })
                }
            }

            Row {
                id: buttonRow
                width: parent.width
                property real itemWidth : width / 5

                IconButton {
                    width: buttonRow.itemWidth
                    enabled: app.mprisPlayer.canGoPrevious
                    icon.source: "image://theme/icon-m-previous"
                    onClicked: app.previous(function(error,data) {
                        if(!error)
                            refresh()
                    })
                }
                IconButton {
                    width: buttonRow.itemWidth
                    icon.source: app.playing
                                 ? "image://theme/icon-cover-pause"
                                 : "image://theme/icon-cover-play"
                    onClicked: app.pause(function(error,data) {
                        if(!error)
                            refresh()
                    })
                }
                IconButton {
                    width: buttonRow.itemWidth
                    enabled: app.mprisPlayer.canGoNext
                    icon.source: "image://theme/icon-m-next"
                    onClicked: app.next(function(error,data) {
                        if(!error)
                            refresh()
                    })
                }
                IconButton {
                    width: buttonRow.itemWidth
                    icon.source: (playbackState && playbackState.repeat_state)
                                 ? "image://theme/icon-m-repeat?" + Theme.highlightColor
                                 : "image://theme/icon-m-repeat"
                    onClicked: app.setRepeat(checked, function(error,data) {
                        if(!error)
                            refresh()
                    })
                }
                IconButton {
                    width: buttonRow.itemWidth
                    icon.source: (playbackState && playbackState.shuffle_state)
                                 ? "image://theme/icon-m-shuffle?" + Theme.highlightColor
                                 : "image://theme/icon-m-shuffle"
                    onClicked: app.setShuffle(checked, function(error,data) {
                        if(!error)
                            refresh()
                    })
                }
            }
        }
    } // Control Panel

    NavigationPanel {
        id: navPanel
        height: controlPanel.height
    }

    property int failedAttempts: 0
    property int refreshCount: 0
    Timer {
        id: handleRendererInfo
        interval: 1000;
        running: app.playing
        repeat: true
        onTriggered: {
            if(++refreshCount>=5) {
                refresh()
                refreshCount = 0
            }
            // pretend progress (ms), refresh() will set the actual value
            if( playbackState.item && playbackProgress < playbackState.item.duration_ms)
                playbackProgress += 1000
        }
    }

    function getFirstLabelText(playbackState) {
        return (playbackState && playbackState.item) ? playbackState.item.name : ""
    }

    function getSecondLabelText(playbackState, contextObject) {
        var s = ""
        if(playbackState === undefined)
             return s
        if(!playbackState.context) {
            // no context (a single track?)
            if(playbackState.item && playbackState.item.album) {
                s += playbackState.item.album.name
                s += ", " + Util.getYearFromReleaseDate(playbackState.item.album.release_date)
            }
            return s
        }
        switch(playbackState.context.type) {
        case 'album':
            if(contextObject)
                s += Util.createItemsString(contextObject.artists, qsTr("no artist known"))
            break
        case 'artist':
            if(contextObject)
                s += Util.createItemsString(contextObject.genres, qsTr("no genre known"))
            break
        case 'playlist':
            if(contextObject)
                s+= contextObject.description
            break
        }
        return s
    }

    function getThirdLabelText(playbackState, contextObject) {
        var s = ""
        if(playbackState === undefined)
             return s
        if(!playbackState.context) {
            // no context (a single track?)
            if(playbackState.item && playbackState.item.artists)
                s += Util.createItemsString(playbackState.item.artists, qsTr("no artist known"))
            return s
        }
        switch(playbackState.context.type) {
        case 'album':
            if(contextObject) {
                if(contextObject.tracks)
                    s += contextObject.tracks.total + " " + qsTr("tracks")
                else if(contextObject.album_type === "single")
                    s += "1 " + qsTr("track")
                s += ", " + Util.getYearFromReleaseDate(contextObject.release_date)
                if(contextObject.genres)
                    s += ", " + Util.createItemsString(contextObject.genres, "")
            }
            break
        case 'artist':
            if(contextObject && contextObject.followers.total > 0)
                s += Util.abbreviateNumber(contextObject.followers.total) + " " + qsTr("followers")
            break
        case 'playlist':
            if(contextObject) {
                s += contextObject.tracks.total + " " + qsTr("tracks")
                s += ", " + qsTr("by") + " " + contextObject.owner.display_name
                if(contextObject.followers && contextObject.followers.total > 0)
                    s += ", " + Util.abbreviateNumber(contextObject.followers.total) + " " + qsTr("followers")
                if(contextObject["public"])
                    s += ", " +  qsTr("public")
                if(contextObject.collaborative)
                    s += ", " +  qsTr("collaborative")
            }
            break
        }
        return s
    }

    function getContextType() {
        if(!playbackState || !playbackState.context || !contextObject)
            return -1
        switch(playbackState.context.type) {
        case 'album':
            return Spotify.ItemType.Album
        case 'artist':
            return Spotify.ItemType.Artist
        case 'playlist':
            return Spotify.ItemType.Playlist
        }
        if(playingObject && playingObject.item)
            return Spotify.ItemType.Track
        return -1
    }

    function refresh() {
        var i;

        Spotify.getMyCurrentPlaybackState({}, function(error, data) {
            if(data) {
                playbackState = data
                if(playbackState.context) {
                    var cid = Util.getIdFromURI(playbackState.context.uri)
                    if(currentId !== cid) {
                        currentId = cid
                        contextObject = null
                        switch(playbackState.context.type) {
                        case 'album':
                            Spotify.getAlbum(cid, {}, function(error, data) {
                                contextObject = data
                                pageHeaderText = qsTr("Playing Album")
                            })
                            loadAlbumTracks(cid)
                            break
                        case 'artist':
                            Spotify.getArtist(cid, {}, function(error, data) {
                                contextObject = data
                                pageHeaderText = qsTr("Playing Artist")
                            })
                            break
                        case 'playlist':
                            Spotify.getPlaylist(app.id, cid, {}, function(error, data) {
                                contextObject = data
                                pageHeaderText = qsTr("Playing Playlist")
                            })
                            loadPlaylistTracks(app.id, cid)
                            break
                        default:
                            pageHeaderText = qsTr("Playing Album")
                            break
                        }
                    }
                } else {
                    // no context (a single track?)
                    currentId = playbackState.item.id
                    contextObject = null
                    pageHeaderText = qsTr("Playing")
                }

                playbackProgress = playbackState.progress_ms
                app.playing = playbackState.is_playing

                // we have a connection
                failedAttempts = 0
            } else {
                // lost connection
                if(++failedAttempts >= 3) {
                    showErrorMessage(null, qsTr("Connection lost with Spotify servers"))
                    app.playing = false
                    searchModel.clear()
                }
            }

        })

        Spotify.getMyCurrentPlayingTrack({}, function(error, data) {
            if(data) {
                playingObject = data
                app.newPlayingTrackInfo(data.item)
                currentTrackId = playingObject.item.id
            }
        })

    }

    function loadPlaylistTracks(id, pid) {
        searchModel.clear()
        Spotify.getPlaylistTracks(id, pid, {offset: offset, limit: limit}, function(error, data) {
            if(data) {
                try {
                    console.log("number of PlaylistTracks: " + data.items.length)
                    offset = data.offset
                    for(var i=0;i<data.items.length;i++) {
                        searchModel.append({type: Spotify.ItemType.Track,
                                            stype: Spotify.ItemType.Playlist,
                                            name: data.items[i].track.name,
                                            track: data.items[i].track})
                    }
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getPlaylistTracks")
            }
        })
    }

    function loadAlbumTracks(id) {
        searchModel.clear()
        Spotify.getAlbumTracks(id,
                               {offset: offset, limit: limit},
                               function(error, data) {
            if(data) {
                try {
                    console.log("number of AlbumTracks: " + data.items.length)
                    offset = data.offset
                    var trackIds = []
                    for(var i=0;i<data.items.length;i++) {
                        searchModel.append({type: Spotify.ItemType.Track,
                                            stype: Spotify.ItemType.Album,
                                            name: data.items[i].name,
                                            saved: false,
                                            track: data.items[i]})
                        trackIds.push(data.items[i].id)
                        // get info about saved tracks
                        Spotify.containsMySavedTracks(trackIds, function(error, data) {
                            if(data) {
                                Util.setSavedInfo(Spotify.ItemType.Track, trackIds, data, searchModel)
                            }
                        })
                    }
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getAlbumTracks")
            }
        })
    }

    function toggleSavedFollowed(playbackState, contextObject) {
        if(!playbackState || !playbackState.context || !contextObject)
            return
        switch(playbackState.context.type) {
        case 'album':
            app.toggleSavedAlbum(contextObject, isContextFavorite, function(saved) {
                isContextFavorite = saved
            })
            break
        case 'artist':
            app.toggleFollowArtist(contextObject, isContextFavorite, function(followed) {
                isContextFavorite = followed
            })
            break
        case 'playlist':
            app.toggleFollowPlaylist(contextObject, isContextFavorite, function(followed) {
                isContextFavorite = followed
            })
            break
        default: // track?
            if(playingObject && playingObject.item) { // Note uses globals
                if(isContextFavorite)
                    app.unSaveTrack(playingObject.item, function(error,data) {
                        if(!error)
                            isContextFavorite = false
                    })
                else
                    app.saveTrack(playingObject.item, function(error,data) {
                        if(!error)
                            isContextFavorite = true
                    })
            }
            break
        }
    }

    Connections {
        target: app
        onLoggedInChanged: {
            if(app.loggedIn)
                refresh()
        }
        onNewPlayingTrackInfo: {
            // track change?
            if(currentTrackId !== track.id)
                refresh()
        }
        onRemovedFromPlaylist: {
            if(getContextType() === Spotify.ItemType.Playlist
               && contextObject.id === playlistId) {
                Util.removeFromListModel(searchModel, trackId)
            }
        }
    }

    Component.onCompleted: {
        if(app.loggedIn)
            refresh()
    }

}
