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
    id: searchPage
    objectName: "SearchPage"

    property int searchInType: 0
    property bool showBusy: false
    property string searchString: ""

    property bool canLoadNext: searchString.length >= 1
    property bool canLoadPrevious: searchString.length >= 1 && offset >= limit
    property int offset: 0
    property int limit: app.searchLimit.value
    property int currentIndex: -1

    property var searchTargets: [qsTr("Albums"), qsTr("Artists"), qsTr("Playlists"), qsTr("Tracks")]
    property int selectedSearchTargetsMask: app.selected_search_targets.value
    property var scMap: []

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

            LoadPullMenus {}
            LoadPushMenus {}

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

            /* What to search for */
            ValueButton {
                property var indexes: []
                width: parent.width

                label: qsTr("Search For")

                ListModel {
                    id: items
                }

                Component.onCompleted: {
                    var c = 0;
                    value = qsTr("None")
                    indexes = []

                    // load capabilities
                    for (var u=0;u<searchTargets.length;u++) {
                        items.append( {id: c, name: searchTargets[u]});
                        scMap[c] = u;
                        c++;
                    }

                    // the selected
                    value = "";
                    for(var i=0;i<scMap.length;i++) {
                        if(selectedSearchTargetsMask & (0x01 << scMap[i])) {
                            var first = value.length == 0;
                            value = value + (first ? "" : ", ") + items.get(i).name;
                            indexes.push(i);
                        }
                    }
                }

                onClicked: {
                    var ms = pageStack.push(Qt.resolvedUrl("../components/MultiItemPicker.qml"), { items: items, label: label, indexes: indexes } );
                    ms.accepted.connect(function() {
                        indexes = ms.indexes.sort(function (a, b) { return a - b });
                        selectedSearchTargetsMask = 0;
                        if (indexes.length == 0) {
                            value = qsTr("None");
                        } else {
                            value = "";
                            var tmp = [];
                            selectedSearchTargetsMask = 0;
                            for(var i=0;i<indexes.length;i++) {
                                value = value + ((i>0) ? ", " : "") + items.get(indexes[i]).name;
                                selectedSearchTargetsMask |= (0x01 << scMap[indexes[i]]);
                            }
                        }
                        app.selected_search_targets.value = selectedSearchTargetsMask;
                        app.selected_search_targets.sync();
                    })
                }

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
                        visible: enabled
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
                        visible: enabled
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
                    MenuItem {
                        enabled: type === 3
                        visible: enabled
                        text: qsTr("Add to Playlist")
                        onClicked: app.addToPlaylist(track)
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
        var types = []
        if(selectedSearchTargetsMask & 0x01)
            types.push('album')
        if(selectedSearchTargetsMask & 0x02)
            types.push('artist')
        if(selectedSearchTargetsMask & 0x04)
            types.push('playlist')
        if(selectedSearchTargetsMask & 0x08)
            types.push('track')
        Spotify.search(searchString, types, {offset: offset, limit: limit}, function(error, data) {
            if(data) {
                var artistIds = []
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
                                            following: false,
                                            artist: data.artists.items[i]})
                        artistIds.push(data.artists.items[i].id)
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

                    // request additional Info
                    Spotify.isFollowingArtists(artistIds, function(error, data) {
                        if(data) {
                            Util.setFollowedInfo(1, artistIds, data, searchModel)
                        }
                    })

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
