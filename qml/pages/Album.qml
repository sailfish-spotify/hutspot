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
    id: albumPage
    objectName: "AlbumPage"

    property string defaultImageSource : "image://theme/icon-l-music"
    property bool showBusy: false
    property var album
    property var albumArtists
    property bool isAlbumSaved: false

    property int offset: 0
    property int limit: app.searchLimit.value
    property bool canLoadNext: true
    property bool canLoadPrevious: offset >= limit
    property int currentIndex: -1

    property string currentTrackId: ""

    allowedOrientations: Orientation.All

    ListModel {
        id: searchModel
    }

    SilicaListView {
        id: listView
        model: searchModel

        width: parent.width
        anchors.top: parent.top
        anchors.bottom: navPanel.top
        clip: navPanel.expanded

        header: Column {
            id: lvColumn

            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium
            anchors.bottomMargin: Theme.paddingLarge
            spacing: Theme.paddingLarge

            PageHeader {
                id: pHeader
                width: parent.width
                title: qsTr("Album")
                MenuButton {}
            }

            LoadPullMenus {}
            LoadPushMenus {}

            Image {
                id: imageItem
                source:  (album && album.images)
                         ? album.images[0].url : defaultImageSource
                width: parent.width * 0.75
                height: width
                fillMode: Image.PreserveAspectFit
                anchors.horizontalCenter: parent.horizontalCenter
                onPaintedHeightChanged: height = Math.min(parent.width, paintedHeight)
                MouseArea {
                     anchors.fill: parent
                     onClicked: app.playContext(album)
                }
            }

            MetaInfoPanel {
                id: metaLabels
                width: parent.width
                firstLabelText: album.name
                secondLabelText: Util.createItemsString(album.artists, qsTr("no artist known"))
                thirdLabelText: {
                    var s = ""
                    if(album.tracks)
                        s += album.tracks.total + " " + qsTr("tracks")
                    else if(album.album_type === "single")
                        s += "1 " + qsTr("track")
                    if(album.release_date && album.release_date.length > 0)
                        s += ", " + Util.getYearFromReleaseDate(album.release_date)
                    if(album.genres && album.genres.length > 0)
                        s += ", " + Util.createItemsString(album.genres, "")
                    return s
                }
                onSecondLabelClicked: loadArtist(album.artists)
                isFavorite: isAlbumSaved
                onToggleFavorite: toggleSaved(album)
            }

            Separator {
                width: parent.width
                color: Theme.primaryColor
            }

        }

        delegate: ListItem {
            id: listItem
            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium
            contentHeight: Theme.itemSizeExtraSmall

            AlbumTrackListItem {
                id: albumTrackListItem
                dataModel: model
                isFavorite: saved
                onToggleFavorite: toggleSavedTrack(model)
            }

            menu: contextMenu
            Component {
                id: contextMenu
                ContextMenu {
                    MenuItem {
                        text: qsTr("Play")
                        onClicked: app.playTrack(track)
                    }
                    MenuItem {
                        text: qsTr("Add to Playlist")
                        onClicked: app.addToPlaylist(track)
                    }
                }
            }
            onClicked: app.playTrack(track)
        }

        VerticalScrollDecorator {}

        Label {
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignBottom
            visible: parent.count == 0
            text: qsTr("No tracks found")
            color: Theme.secondaryColor
        }

    }

    NavigationPanel {
        id: navPanel
    }

    onAlbumChanged: refresh()

    function refresh() {
        //showBusy = true
        searchModel.clear()        

        Spotify.getAlbumTracks(album.id,
                               {offset: offset, limit: limit},
                               function(error, data) {
            if(data) {
                try {
                    console.log("number of AlbumTracks: " + data.items.length)
                    offset = data.offset
                    var trackIds = []
                    for(var i=0;i<data.items.length;i++) {
                        searchModel.append({type: Spotify.ItemType.Track,
                                            name: data.items[i].name,
                                            saved: false,
                                            track: data.items[i]})
                        trackIds.push(data.items[i].id)
                    }
                    // get info about saved tracks
                    Spotify.containsMySavedTracks(trackIds, function(error, data) {
                        if(data) {
                            Util.setSavedInfo(Spotify.ItemType.Track, trackIds, data, searchModel)
                        }
                    })

                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getAlbumTracks")
            }
        })

        var artists = []
        for(var i=0;i<album.artists.length;i++)
            artists.push(album.artists[i].id)
        Spotify.getArtists(artists, {}, function(error, data) {
            if(data)
                albumArtists = data.artists
        })

        Spotify.containsMySavedAlbums([album.id], {}, function(error, data) {
            if(data)
                isAlbumSaved = data[0]
        })
    }

    function loadArtist(artists) {
        if(albumArtists.length > 1) {
            // choose
            var ms = pageStack.push(Qt.resolvedUrl("../components/ArtistPicker.qml"),
                                    { label: qsTr("View an Artist"), artists: albumArtists } );
            ms.accepted.connect(function() {
                if(ms.selectedItem) {
                    pageStack.replace(Qt.resolvedUrl("Artist.qml"), {currentArtist: ms.selectedItem.artist})
                }
            })
        } else if(albumArtists.length === 1) {
            pageStack.push(Qt.resolvedUrl("Artist.qml"), {currentArtist:albumArtists[0]})
        }
    }

    function toggleSaved(album) {
        if(isAlbumSaved)
            app.unSaveAlbum(album, function(error,data) {
                if(!error)
                    isAlbumSaved = false
            })
        else
            app.saveAlbum(album, function(error,data) {
                if(!error)
                    isAlbumSaved = true
            })
    }

    function toggleSavedTrack(model) {
        if(model.saved)
            app.unSaveTrack(model.track, function(error,data) {
                if(!error)
                    model.saved = false
            })
        else
            app.saveTrack(model.track, function(error,data) {
                if(!error)
                    model.saved = true
            })
    }
}
