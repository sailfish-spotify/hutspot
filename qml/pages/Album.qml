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

    property int offset: 0
    property int limit: app.searchLimit.value
    property bool canLoadNext: true
    property bool canLoadPrevious: offset >= limit
    property int currentIndex: -1

    allowedOrientations: Orientation.All

    ListModel {
        id: searchModel
    }

    SilicaListView {
        id: listView
        model: searchModel
        anchors.fill: parent
        anchors.topMargin: 0

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
                BusyIndicator {
                    id: busyThingy
                    parent: pHeader.extraContent
                    anchors.left: parent.left
                    running: showBusy;
                }
                anchors.horizontalCenter: parent.horizontalCenter
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

            Label {
                id: nameLabel
                color: Theme.highlightColor
                font.bold: true
                truncationMode: TruncationMode.Fade
                width: parent.width
                wrapMode: Text.Wrap
                text: album.name
            }

            Label {
                id: artistLabel
                color: Theme.primaryColor
                truncationMode: TruncationMode.Fade
                width: parent.width
                wrapMode: Text.Wrap
                text: Util.createItemsString(album.artists, qsTr("no artist known"))
                MouseArea {
                    anchors.fill: parent
                    onClicked: loadArtist(album.artists)
                }
            }

            Label {
                color: Theme.primaryColor
                truncationMode: TruncationMode.Fade
                font.pixelSize: Theme.fontSizeSmall
                width: parent.width
                wrapMode: Text.Wrap
                text: {
                    var s = ""
                    if(album.release_date && album.release_date.length > 0)
                        s += Util.getYearFromReleaseDate(album.release_date)
                    if(album.genres && album.genres.length > 0)
                        s += ", " + Util.createItemsString(album.genres, "")
                    return s
                }
            }

            Rectangle {
                width: parent.width
                height:Theme.paddingLarge
                opacity: 0
            }

            Label {
                truncationMode: TruncationMode.Fade
                width: parent.width
                font.bold: true
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.highlightColor
                horizontalAlignment: Text.AlignRight
                text: qsTr("Tracks")
            }

        }

        delegate: ListItem {
            id: listItem
            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium
            //contentHeight: Theme.itemSizeLarge

            Column {
                width: parent.width
                Label {
                    color: Theme.primaryColor
                    textFormat: Text.StyledText
                    truncationMode: TruncationMode.Fade
                    width: parent.width
                    text: name ? name : qsTr("No Name")
                }

                Label {
                    width: parent.width
                    color: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                    truncationMode: TruncationMode.Fade
                    text: track.track_number + ", " + Util.getDurationString(track.duration_ms)
                    enabled: text.length > 0
                    visible: enabled
                }
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
                    for(var i=0;i<data.items.length;i++) {
                        searchModel.append({type: 3,
                                            name: data.items[i].name,
                                            track: data.items[i]})
                    }
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
}
