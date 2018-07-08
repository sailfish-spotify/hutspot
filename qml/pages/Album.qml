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
                width: parent.width
                height: width
                fillMode: Image.PreserveAspectFit
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
                text: {
                    var s = Util.createItemsString(album.artists, qsTr("no artist known"))
                    if(album.release_date && album.release_date.length > 0)
                        s += ", " + album.release_date
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
        var i;
        //showBusy = true
        searchModel.clear()        

        Spotify.getAlbumTracks(album.id,
                               {offset: offset, limit: limit},
                               function(error, data) {
            if(data) {
                try {
                    console.log("number of AlbumTracks: " + data.items.length)
                    offset = data.offset
                    for(i=0;i<data.items.length;i++) {
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

    }

}
