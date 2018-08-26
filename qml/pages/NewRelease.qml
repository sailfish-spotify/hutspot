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
    id: newRelease
    objectName: "NewReleasePage"

    property bool showBusy: false

    property int currentIndex: -1

    property int cursor_limit: app.searchLimit.value
    property int cursor_offset: 0
    property int cursor_total: 0
    property bool canLoadNext: (cursor_offset + cursor_limit) <= cursor_total
    property bool canLoadPrevious: cursor_offset >= cursor_limit

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
            anchors.bottomMargin: Theme.paddingLarge
            spacing: Theme.paddingLarge

            PageHeader {
                id: pHeader
                width: parent.width
                title: qsTr("New Releases")
                MenuButton {}
            }

            LoadPullMenus {}
            LoadPushMenus {}

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

            onClicked: app.pushPage(Util.HutspotPage.Album, {album: album})
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
        showBusy = true
        searchModel.clear()

        Spotify.getNewReleases({offset: cursor_offset, limit: cursor_limit}, function(error, data) {
            if(data) {
                cursor_offset = data.albums.offset
                cursor_total = data.albums.total
                try {
                    // albums
                    for(i=0;i<data.albums.items.length;i++) {
                        searchModel.append({type: 0,
                                            name: data.albums.items[i].name,
                                            album: data.albums.items[i]})
                    }
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("getNewReleases returned no results.")
            }
            showBusy = false
        })
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
