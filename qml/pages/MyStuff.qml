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
    id: myStuffPage
    objectName: "MyStuffPage"

    property int searchInType: 0
    property bool showBusy: false
    property string searchString: ""

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
                title: qsTr("My Stuff")
                BusyIndicator {
                    id: busyThingy
                    parent: pHeader.extraContent
                    anchors.left: parent.left
                    running: showBusy;
                }
                anchors.horizontalCenter: parent.horizontalCenter
            }

        }

        section.property: "type"
        section.delegate : Component {
            id: sectionHeading
            Item {
                width: parent.width - 2*Theme.paddingMedium
                x: Theme.paddingMedium
                height: childrenRect.height

                Text {
                    width: parent.width
                    text: {
                        switch(section) {
                        case "0": return qsTr("Albums")
                        case "1": return qsTr("Artists")
                        case "2": return qsTr("Playlists")
                        case "3": return qsTr("Tracks")
                        }
                    }
                    font.bold: true
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.highlightColor
                    horizontalAlignment: Text.AlignRight
                }
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
                        onClicked: {
                            switch(type) {
                            case 0:
                                app.playContext(album)
                                break;
                            case 1:
                                app.playContext(artist)
                                break;
                            case 2:
                                app.playContext(playlist)
                                break;
                            case 3:
                                app.playTrack(track)
                                break;
                            }
                        }
                    }
                    MenuItem {
                        text: qsTr("View")
                        enabled: type === 0 || type === 2
                        onClicked: {
                            switch(type) {
                            case 0:
                                pageStack.push(Qt.resolvedUrl("Album.qml"), {album: album})
                                break;
                            case 2:
                                pageStack.push(Qt.resolvedUrl("Playlist.qml"), {playlist: playlist})
                                break;
                            }
                        }
                    }
                }
            }
            //onClicked: app.loadStation(model.id, Shoutcast.createInfo(model), tuneinBase)
        }

        VerticalScrollDecorator {}

        Label {
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignBottom
            visible: parent.count == 0
            text: qsTr("Nothing found")
            color: Theme.secondaryColor
        }

    }

    function refresh() {
        var i;
        //showBusy = true
        searchModel.clear()

        Spotify.getMySavedAlbums({}, function(data) {
            if(data) {
                try {
                    console.log("number of SavedAlbums: " + data.items.length)
                    for(i=0;i<data.items.length;i++)
                        searchModel.append({type: 0,
                                            name: data.items[i].name,
                                            album: data.items[i]})
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getMySavedAlbums")
            }
        })

        Spotify.getUserPlaylists({},function(data) {
            if(data) {
                try {
                    console.log("number of playlists: " + data.items.length)
                    for(i=0;i<data.items.length;i++) {
                        searchModel.append({type: 2,
                                            name: data.items[i].name,
                                            playlist: data.items[i]})
                    }
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getUserPlaylists")
            }
        })

        Spotify.getMyRecentlyPlayedTracks({}, function(data) {
            if(data) {
                try {
                    console.log("number of RecentlyPlayedTracks: " + data.items.length)
                    for(i=0;i<data.items.length;i++) {
                        searchModel.append({type: 3,
                                            name: data.items[i].track.name,
                                            track: data.items[i].track})
                    }
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getMyRecentlyPlayedTracks")
            }
        })

        Spotify.getMySavedTracks({}, function(data) {
            if(data) {
                try {
                    console.log("number of SavedTracks: " + data.items.length)
                    for(i=0;i<data.items.length;i++) {
                        searchModel.append({type: 3,
                                            name: data.items[i].track.name,
                                            track: data.items[i].track})
                    }
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getMySavedTracks")
            }
        })

        /*Spotify.getMyTopArtists({}, function(data) {
            if(data) {
                try {
                    console.log("number of TopArtists: " + data.items.length)
                    for(i=0;i<data.items.length;i++) {
                        searchModel.append({type: 1,
                                            name: data.items[i].track.name,
                                            track: data.items[i].track})
                    }
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getMyTopArtists")
            }
        })*/

    }

    Component.onCompleted: refresh()
}
