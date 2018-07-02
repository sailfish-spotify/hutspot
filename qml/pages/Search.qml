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
    id: searchPage
    objectName: "SearchPage"

    property int searchInType: 0
    property bool showBusy: false
    property string searchString: ""
    //property alias searchField: listView.header.searchField
    property int offset: 0
    property int limit: app.searchLimit.value

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
                title: qsTr("Search")
                BusyIndicator {
                    id: busyThingy
                    parent: pHeader.extraContent
                    anchors.left: parent.left
                    running: showBusy;
                }
                anchors.horizontalCenter: parent.horizontalCenter
            }

            PullDownMenu {
                MenuItem {
                    text: qsTr("Load Next Set")
                    enabled: searchString.length >= 1
                    onClicked: {
                        offset += limit
                        refresh()
                    }
                }
               MenuItem {
                    text: qsTr("Load Previous Set")
                    enabled: searchString.length >= 1
                             && offset >= limit
                    onClicked: {
                        offset -= limit
                        refresh()
                    }
                }
            }

            PushUpMenu {
                MenuItem {
                    text: qsTr("Load Next Set")
                    enabled: searchString.length >= 1
                    onClicked: {
                        offset += limit
                        refresh()
                    }
                }
                MenuItem {
                     text: qsTr("Load Previous Set")
                     enabled: searchString.length >= 1
                              && offset >= limit
                     onClicked: {
                         offset -= limit
                         refresh()
                     }
                 }
            }

            SearchField {
                id: searchField
                width: parent.width
                placeholderText: qsTr("Search text")
                Binding {
                    target: searchPage
                    property: "searchString"
                    value: searchField.text.toLowerCase().trim()
                }
                EnterKey.onClicked: refresh()
                Component.onCompleted: searchField.forceActiveFocus()
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
            //height: searchResultListItem.height
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
                        enabled: type === 0 || type === 1 || type === 2
                        onClicked: {
                            switch(type) {
                            case 0:
                                pageStack.push(Qt.resolvedUrl("Album.qml"), {album: album})
                                break;
                            case 1:
                                pageStack.push(Qt.resolvedUrl("Artist.qml"), {currentArtist: artist})
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
        if(searchString === "")
            return
        showBusy = true
        searchModel.clear()
        Spotify.search(searchString, ['album', 'artist', 'playlist', 'track'],
                       {offset: offset, limit: limit}, function(data, error) {
            if(data) {
                // for now assume offset is the same for all 4 catagories
                offset = data.albums.offset
                try {
                    // albums
                    for(i=0;i<data.albums.items.length;i++) {
                        searchModel.append({type: 0,
                                            name: data.albums.items[i].name,
                                            album: data.albums.items[i]})
                    }

                    // artists
                    for(i=0;i<data.artists.items.length;i++) {
                        searchModel.append({type: 1,
                                            name: data.artists.items[i].name,
                                            artist: data.artists.items[i]})
                    }

                    // playlists
                    for(i=0;i<data.playlists.items.length;i++) {
                        searchModel.append({type: 2,
                                            name: data.playlists.items[i].name,
                                            playlist: data.playlists.items[i]})
                    }

                    // tracks
                    for(i=0;i<data.tracks.items.length;i++) {
                        searchModel.append({type: 3,
                                            name: data.tracks.items[i].name,
                                            track: data.tracks.items[i]})
                    }

                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("Search for: " + searchString + " returned no results.")
            }
            showBusy = false
        })
    }

}
