/**
 * Copyright (C) 2018 Willem-Jan de Hoog
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
    objectName: "PlayingPage"

    property string defaultImageSource : "image://theme/icon-l-music"
    property bool showBusy: false

    property var contextObject: null
    property bool isContextFavorite: false
    property string currentId: ""

    property string viewMenuText: ""

    property int offset: 0
    property int limit: app.searchLimit.value
    property bool canLoadNext: true
    property bool canLoadPrevious: offset >= limit
    property int currentIndex: -1

    property string pageHeaderTitle: qsTr("Playing")
    property string pageHeaderDescription: ""

    allowedOrientations: Orientation.All

    GlassyBackground {
        anchors.fill: parent
        sourceSize.height: parent.height
        source: app.controller.getCoverArt(app.controller.playbackState, "")
        visible: source !== ""
    }

    ListModel {
        id: searchModel
    }

    SilicaFlickable {
        id: listView
        anchors.fill: parent

        Column {
            id: lvColumn

            width: playingPage.width
            anchors.bottomMargin: Theme.paddingLarge
            spacing: Theme.paddingLarge

            PageHeader {
                width: parent.width
                title: (app.controller.playbackState.context !== undefined && app.controller.playbackState.context.type) ? qsTr("Playing " + app.controller.playbackState.context.type) : qsTr("Playing")

                description: pageHeaderDescription
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Item {
                width: parent.width
                height: albumArt.height
                Image {
                    id: albumArt
                    anchors.horizontalCenter: parent.horizontalCenter
                    source: app.controller.getCoverArt(app.controller.playbackState, defaultImageSource)
                    width: parent.width - 4*Theme.horizontalPageMargin
                    height: sourceSize.height*(width/sourceSize.width)
                    fillMode: Image.PreserveAspectFit
                }
                DropShadow {
                    anchors.fill: albumArt
                    radius: 50.0
                    samples: 30
                    color: "#000"
                    source: albumArt
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: playingPage.width - Theme.horizontalPageMargin*2
                horizontalAlignment: Text.AlignHCenter
                text: app.controller.playbackState.item.name
                truncationMode: TruncationMode.Fade
                font.pixelSize: Theme.fontSizeLarge
            }

            Label {
                x: Theme.horizontalPageMargin
                width: playingPage.width - Theme.horizontalPageMargin*2
                horizontalAlignment: Text.AlignHCenter
                text: app.controller.playbackState.artistsString
                truncationMode: TruncationMode.Fade
            }

            Row {
                x: Theme.horizontalPageMargin
                width: playingPage.width - Theme.horizontalPageMargin*2
                Label {
                    id: progressLabel
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.verticalCenter: parent.verticalCenter
                    text: Util.getDurationString(app.controller.playbackState.progress_ms)
                }
                Slider {
                    //height: progressLabel.height * 1.5
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - durationLabel.width - progressLabel.width
                    minimumValue: 0
                    maximumValue: app.controller.playbackState.item.duration_ms
                    handleVisible: false
                    value: app.controller.playbackState.progress_ms
                    onReleased: {
                        Spotify.seek(Math.round(value), function(error, data) {
                            if (!error)
                                app.controller.refreshPlaybackState()
                        })
                    }
                }
                Label {
                    id: durationLabel
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.verticalCenter: parent.verticalCenter
                    text: Util.getDurationString(app.controller.playbackState.item.duration_ms)
                }
            }

            Rectangle {
                width: parent.width
                height: Theme.paddingMedium
                color: "transparent"
            }

            Row {
                id: buttonRow
                width: parent.width
                property real itemWidth : width / 5

                IconButton {
                    width: buttonRow.itemWidth
                    icon.source: app.controller.playbackState.shuffle_state
                                 ? "image://theme/icon-m-shuffle?" + Theme.highlightColor
                                 : "image://theme/icon-m-shuffle"
                    onClicked: app.controller.setShuffle(!app.controller.playbackState.shuffle_state)
                }

                IconButton {
                    width: buttonRow.itemWidth
                    //enabled: app.mprisPlayer.canGoPrevious
                    icon.source: "image://theme/icon-m-previous"
                    onClicked: app.controller.previous()
                }
                IconButton {
                    width: buttonRow.itemWidth
                    icon.source: app.controller.playbackState.is_playing
                                 ? "image://theme/icon-l-pause"
                                 : "image://theme/icon-l-play"
                    onClicked: app.controller.playPause()
                }
                IconButton {
                    width: buttonRow.itemWidth
                    //enabled: app.mprisPlayer.canGoNext
                    icon.source: "image://theme/icon-m-next"
                    onClicked: app.controller.next()
                }
                IconButton {
                    Rectangle {
                        visible: app.controller.playbackState.repeat_state === "track"
                        color: Theme.highlightColor
                        anchors {
                            rightMargin: (buttonRow.itemWidth - Theme.iconSizeMedium)/2
                            right: parent.right
                            top: parent.top
                        }
                        width: Theme.iconSizeSmall
                        height: width
                        radius: width/2

                        Label {
                            text: "1"
                            anchors.centerIn: parent
                            color: "#000"
                            font.pixelSize: Theme.fontSizeSmall
                            font.bold: true
                        }
                    }

                    width: buttonRow.itemWidth
                    icon.source: app.controller.playbackState.repeat_state !== "off"
                                 ? "image://theme/icon-m-repeat?" + Theme.highlightColor
                                 : "image://theme/icon-m-repeat"
                    onClicked: app.controller.setRepeat(app.controller.playbackState.nextRepeatState())
                }
            }

            Rectangle {
                width: parent.width
                height: Theme.paddingLarge
                color: "transparent"
            }

            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                height: spotifyConnectRow.childrenRect.height
                MouseArea {
                    anchors.fill: spotifyConnectRow
                    onClicked: pageStack.push(Qt.resolvedUrl("../pages/Devices.qml"))
                }

                Row {
                    id: spotifyConnectRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.paddingMedium
                    Image {
                        anchors.verticalCenter: spotifyConnectLabel.verticalCenter
                        source: "image://theme/icon-cover-play"
                    }

                    Label {
                        id: spotifyConnectLabel
                        text: app.controller.playbackState.device !== undefined ? "Listening on <b>" + app.controller.playbackState.device.name + "</b>" : ""
                    }
                    visible: app.controller.playbackState.device !== undefined
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
                            pageStack.push(Qt.resolvedUrl("../pages/Album.qml"), {album: app.controller.playbackState.item.album})
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
                            app.loadArtist(app.controller.playbackState.item.artists)
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

            Rectangle {
                width: parent.width
                height: Theme.paddingMedium
                opacity: 0
            }

            Rectangle {
                width: parent.width
                height: Theme.paddingMedium
                opacity: 0
            }
        }
/*
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

            onClicked: app.controller.playTrackInContext(track, playbackState.context)
        }*/
    }

    function getContextType() {
        if(!app.controller.playbackState || !app.controller.playbackState.context || !contextObject)
            return -1
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
                                            saved: false,
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
            break
        }
    }

    Connections {
        target: app.controller.playbackState
        onItemChanged: {
            if(app.controller.playbackState.context) {
                var cid = Util.getIdFromURI(app.controller.playbackState.context.uri)
                if(currentId !== cid) {
                    currentId = cid
                    contextObject = null
                    switch(app.controller.playbackState.context.type) {
                    case 'album':
                        pageHeaderDescription = app.controller.playbackState.item.album.name
                        break
                    case 'artist':
                        pageHeaderDescription = app.controller.playbackState.artistsString
                        break
                    case 'playlist':
                        Spotify.getPlaylist(app.id, cid, {}, function(error, data) {
                            contextObject = data
                            pageHeaderDescription = contextObject.name
                        })
                        //loadPlaylistTracks(app.id, cid)
                        break
                    default:
                        pageHeaderDescription = ""
                        break
                    }
                }
            } else {
                // no context (a single track?)
                currentId = app.controller.playbackState.item.id
                contextObject = null
                pageHeaderDescription = ""
            }
        }
    }

    Connections {
        target: app

        onAddedToPlaylist: {
            if(getContextType() === Spotify.ItemType.Playlist
               && contextObject.id === playlistId) {
                // in theory it has been added at the end of the list
                // so we could load the info and add it to the model but ...
                //refresh()
            }
        }

        onRemovedFromPlaylist: {
            if(getContextType() === Spotify.ItemType.Playlist
               && contextObject.id === playlistId) {
                Util.removeFromListModel(searchModel, Spotify.ItemType.Track, trackId)
            }
        }
    }

    Component.onCompleted: app.controller.refreshPlaybackState()
}
