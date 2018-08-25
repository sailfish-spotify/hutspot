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
    property int currentIndex: -1

    property int cursor_limit: app.searchLimit.value
    property int cursor_offset: 0
    property int cursor_total: 0

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

        width: parent.width
        anchors.top: parent.top
        anchors.bottom: navPanel.top
        clip: navPanel.expanded

        header: Column {
            id: lvColumn

            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium
            spacing: Theme.paddingLarge

            PageHeader {
                id: pHeader
                width: parent.width
                title: qsTr("Search")
                MenuButton {}
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
                EnterKey.enabled: text.length > 0
                EnterKey.onClicked: refresh()
                EnterKey.iconSource: "image://theme/icon-m-search"
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

                    // load possible choices
                    for(var u=0;u<searchTargets.length;u++) {
                        items.append( {id: c, name: searchTargets[u]});
                        scMap[c] = u;
                        c++;
                    }

                    // read the selected
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
                    var ms = pageStack.push(Qt.resolvedUrl("../components/MultiItemPicker.qml"),
                                            { items: items, label: label, indexes: indexes } );
                    ms.accepted.connect(function() {
                        indexes = ms.indexes.sort(function (a, b) { return a - b });
                        selectedSearchTargetsMask = 0;
                        if (indexes.length == 0) {
                            value = qsTr("None");
                        } else {
                            value = "";
                            for(var i=0;i<indexes.length;i++) {
                                value += ((i>0) ? ", " : "") + items.get(indexes[i]).name;
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
                dataModel: model
            }

            menu: SearchResultContextMenu {}

            onClicked: {
                switch(type) {
                case 0:
                    app.pushPage(Util.HutspotPage.Album, {album: album})
                    break;
                case 1:
                    app.pushPage(Util.HutspotPage.Artist, {currentArtist: artist})
                    break;
                case 2:
                    app.pushPage(Util.HutspotPage.Playlist, {playlist: playlist})
                    break;
                case 3:
                    app.pushPage(Util.HutspotPage.Album, {album: track.album})
                    break;
                }
            }
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

    NavigationPanel {
        id: navPanel
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
        Spotify.search(searchString, types, {offset: cursor_offset, limit: cursor_limit}, function(error, data) {
            if(data) {
                var artistIds = []
                var cursors = []
                try {
                    // albums
                    if(data.albums) {
                        for(i=0;i<data.albums.items.length;i++) {
                            searchModel.append({type: 0,
                                                name: data.albums.items[i].name,
                                                album: data.albums.items[i]})
                        }
                        cursors.push(Util.loadCursor(data.albums))
                    }

                    // artists
                    if(data.artists) {
                        for(i=0;i<data.artists.items.length;i++) {
                            searchModel.append({type: 1,
                                                name: data.artists.items[i].name,
                                                following: false,
                                                artist: data.artists.items[i]})
                            artistIds.push(data.artists.items[i].id)
                        }
                        cursors.push(Util.loadCursor(data.artists))
                    }

                    // playlists
                    if(data.playlists) {
                        for(i=0;i<data.playlists.items.length;i++) {
                            searchModel.append({type: 2,
                                                name: data.playlists.items[i].name,
                                                playlist: data.playlists.items[i]})
                        }
                        cursors.push(Util.loadCursor(data.playlists))
                    }

                    // tracks
                    if(data.tracks) {
                        for(i=0;i<data.tracks.items.length;i++) {
                            searchModel.append({type: 3,
                                                name: data.tracks.items[i].name,
                                                track: data.tracks.items[i]})
                        }
                        cursors.push(Util.loadCursor(data.tracks))
                    }

                    // request additional Info
                    Spotify.isFollowingArtists(artistIds, function(error, data) {
                        if(data) {
                            Util.setFollowedInfo(1, artistIds, data, searchModel)
                        }
                    })

                    // cursors
                    var cinfo = Util.getCursorsInfo(cursors)
                    cursor_offset = cinfo.offset
                    cursor_total = cinfo.maxTotal

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
