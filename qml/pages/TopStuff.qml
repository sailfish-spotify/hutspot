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

    property var topTracks
    property var topArtists
    property int pendingRequests

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

    function refresh() {
        var i;

        searchModel.clear()
        topTracks = undefined
        topArtists = undefined
        pendingRequests = 2

        Spotify.getMyTopTracks({offset: offset, limit: limit}, function(error, data) {
            if(data) {
                console.log("number of TopTracks: " + data.items.length)
                topTracks = data
            } else
                console.log("No Data for getMyTopTracks")
            if(--pendingRequests == 0) // load when all requests are done
                loadData()
        })

        Spotify.getMyTopArtists({offset: offset, limit: limit}, function(error, data) {
            if(data) {
                console.log("number of MyTopArtists: " + data.items.length)
                topArtists = data
            } else
                console.log("No Data for getMyTopArtists")
            if(--pendingRequests == 0) // load when all requests are done
                loadData()
        })

    }

    Connections {
        target: app
        onLoggedInChanged: {
            if(app.loggedIn)
                refresh()
        }
    }

    Component.onCompleted: {
        if(app.loggedIn)
            refresh()
    }

}
