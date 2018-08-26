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
    id: topStuffPage
    objectName: "TopStuffPage"

    property int searchInType: 0
    property bool showBusy: false

    property bool canLoadNext: (cursor_offset + cursor_limit) <= cursor_total
    property bool canLoadPrevious: cursor_offset >= cursor_limit
    property int currentIndex: -1

    property int cursor_limit: app.searchLimit.value
    property int cursor_offset: 0
    property int cursor_total: 0

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

        LoadPullMenus {}
        LoadPushMenus {}

        header: Column {
            id: lvColumn

            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium
            anchors.bottomMargin: Theme.paddingLarge
            spacing: Theme.paddingLarge

            PageHeader {
                id: pHeader
                width: parent.width
                title: qsTr("Top Stuff")
                MenuButton {}
            }

        }

        section.property: "stype"
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
                        case "1": return qsTr("Top Artists")
                        case "3": return qsTr("Top Tracks")
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
                dataModel: model
            }

            menu: SearchResultContextMenu {}

            onClicked: {
                switch(type) {
                case 1:
                    app.pushPage(Util.HutspotPage.Artist, {currentArtist: artist})
                    break;
                case 3:
                    app.pushPage(Util.HutspotPage.Album, {album: track.album})
                    break;
                }
            }
        }

        VerticalScrollDecorator {}

        ViewPlaceholder {
            enabled: listView.count === 0
            text: qsTr("Nothing found")
            hintText: qsTr("Pull down to reload")
        }
    }

    NavigationPanel {
        id: navPanel
    }

    property var topTracks
    property var topArtists
    property int pendingRequests
    property var topTracksCursor
    property var topArtistsCursor

    function loadData() {
        var i
        if(topTracks)
            for(i=0;i<topTracks.items.length;i++)
                searchModel.append({type: 3,
                                    stype: 3,
                                    name: topTracks.items[i].name,
                                    track: topTracks.items[i]})
        if(topArtists)
            for(i=0;i<topArtists.items.length;i++) {
                searchModel.append({type: 1,
                                    stype: 1,
                                    name: topArtists.items[i].name,
                                    following: true,
                                    artist: topArtists.items[i]})
            }

    }

    function loadNext() {
        cursor_offset += cursor_limit
        refresh()
    }

    function loadPrevious() {
        cursor_offset -= cursor_limit
        if(cursor_offset < 0)
            cursor_offset = 0
        refresh()
    }

    function refresh() {
        var i;

        searchModel.clear()
        topTracks = undefined
        topArtists = undefined
        pendingRequests = 2

        Spotify.getMyTopTracks({offset: cursor_offset, limit: cursor_limit}, function(error, data) {
            if(data) {
                cursor_offset = data.offset
                cursor_total = data.total
                console.log("number of TopTracks: " + data.items.length)
                topTracks = data
                topTracksCursor = Util.loadCursor(data)
            } else
                console.log("No Data for getMyTopTracks")
            if(--pendingRequests == 0) // load when all requests are done
                loadData()
        })

        Spotify.getMyTopArtists({offset: cursor_offset, limit: cursor_limit}, function(error, data) {
            if(data) {
                console.log("number of MyTopArtists: " + data.items.length)
                topArtists = data
                topArtistsCursor = Util.loadCursor(data)
            } else
                console.log("No Data for getMyTopArtists")
            if(--pendingRequests == 0) // load when all requests are done
                loadData()
        })

        var cinfo = Util.getCursorsInfo([topArtistsCursor, topTracksCursor])
        cursor_offset = cinfo.offset
        cursor_total = cinfo.maxTotal
    }

    Connections {
        target: app
        onLoggedInChanged: {
            if(app.loggedIn)
                refresh()
        }
        onHasValidTokenChanged: refresh()
    }

    Component.onCompleted: {
        if(app.hasValidToken)
            refresh()
    }

}
