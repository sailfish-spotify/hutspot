/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */


import QtQuick 2.2
import Sailfish.Silica 1.0

import "../components"
import "../Spotify.js" as Spotify

Page {
    id: playlistPage
    objectName: "PlaylistPage"

    property string defaultImageSource : "image://theme/icon-l-music"
    property bool showBusy: false
    property var playlist

    allowedOrientations: Orientation.All

    ListModel {
        id: searchModel
    }

    SilicaListView {
        id: listView
        model: searchModel
        anchors.fill: parent
        anchors.topMargin: 0

        PullDownMenu {
            MenuItem {
                text: qsTr("Reload")
                onClicked: refresh()
            }
        }

        header: Column {
            id: lvColumn

            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium
            anchors.bottomMargin: Theme.paddingLarge
            spacing: Theme.paddingLarge

            PageHeader {
                id: pHeader
                width: parent.width
                title: qsTr("Playlist")
                BusyIndicator {
                    id: busyThingy
                    parent: pHeader.extraContent
                    anchors.left: parent.left
                    running: showBusy;
                }
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Image {
                id: imageItem
                source: (playlist && playlist.images)
                        ? playlist.images[0].url : defaultImageSource
                width: parent.width
                height: width
                fillMode: Image.PreserveAspectFit
                MouseArea {
                       anchors.fill: parent
                       onClicked: app.playContext(playlist)
                }
            }

            Label {
                id: nameLabel
                color: Theme.primaryColor
                textFormat: Text.StyledText
                truncationMode: TruncationMode.Fade
                width: parent.width
                text: playlist ? playlist.name : qsTr("No Name")
            }

            Rectangle {
                width: parent.width
                height:Theme.paddingLarge
                opacity: 0
            }
        }

        delegate: ListItem {
            id: listItem
            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium
            contentHeight: Theme.itemSizeLarge

            SearchResultListItem {
                id: searchResultListItem
            }

            menu: contextMenu
            Component {
                id: contextMenu
                ContextMenu {
                    MenuItem {
                        text: qsTr("Play")
                        onClicked: app.playTrack(track)
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

    onPlaylistChanged: refresh()

    function refresh() {
        var i;
        //showBusy = true
        searchModel.clear()        

        Spotify.getPlaylistTracks(playlist.owner.id, playlist.id, {}, function(data) {
            if(data) {
                try {
                    console.log("number of PlaylistTracks: " + data.items.length)
                    for(i=0;i<data.items.length;i++) {
                        searchModel.append({type: 3,
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

}
