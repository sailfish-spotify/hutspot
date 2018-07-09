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
    property bool isFollowed: false

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

        LoadPullMenus {}
        LoadPushMenus {}

        header: Column {
            id: lvColumn

            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium
            anchors.bottomMargin: Theme.paddingLarge
            spacing: Theme.paddingMedium

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
                width: parent.width * 0.5
                height: width
                fillMode: Image.PreserveAspectFit
                anchors.horizontalCenter: parent.horizontalCenter
                onPaintedHeightChanged: height = Math.min(parent.width, paintedHeight)
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
                text: playlist.name
            }

            TextSwitch {
                checked: isFollowed
                text: qsTr("Following")
                 onClicked: {
                     if(isFollowed)
                          app.unfollowPlaylist(playlist, function(error,data) {
                              if(data)
                                  isFollowed = false
                          })
                      else
                          app.followPlaylist(playlist, function(error,data) {
                              if(data)
                                  isFollowed = true
                          })
                 }
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

            /*Rectangle {
                width: parent.width
                height:Theme.paddingLarge
                opacity: 0
            }*/
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
                    MenuItem {
                        text: qsTr("Remove from Playlist")
                        onClicked: {
                            var idx = index
                            var model = searchModel
                            app.removeFromPlaylist(playlist, track, function(error, data) {
                                if(!error)
                                    model.remove(idx, 1)
                            })
                        }
                    }
                    MenuItem {
                        text: qsTr("Add to another Playlist")
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

    onPlaylistChanged: refresh()

    function refresh() {
        var i;
        //showBusy = true
        searchModel.clear()        

        Spotify.getPlaylistTracks(playlist.owner.id, playlist.id,
                                  {offset: offset, limit: limit}, function(error, data) {
            if(data) {
                try {
                    console.log("number of PlaylistTracks: " + data.items.length)
                    offset = data.offset
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

        app.isFollowingPlaylist(playlist, function(error, data) {
            if(data)
                isFollowed = data[0]
        })
    }

}
