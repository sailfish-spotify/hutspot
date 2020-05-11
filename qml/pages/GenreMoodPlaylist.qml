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
    id: genreMoodPlaylistPage
    objectName: "GenreMoodPlaylistPage"

    property string defaultImageSource : "image://theme/icon-l-music"
    property bool showBusy: false

    property int currentIndex: -1

    property var category

    allowedOrientations: Orientation.All

    ListModel {
        id: searchModel
    }

    SilicaListView {
        id: listView
        model: searchModel

        width: parent.width
        anchors.top: parent.top
        height: parent.height - app.dockedPanel.visibleSize
        clip: app.dockedPanel.expanded

        header: Column {
            id: lvColumn

            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium
            anchors.bottomMargin: Theme.paddingLarge
            spacing: Theme.paddingMedium

            PageHeader {
                id: pHeader
                width: parent.width
                title: category.name
                MenuButton {}
            }
        }

        delegate: ListItem {
            id: listItem
            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium
            contentHeight: Theme.itemSizeLarge

            Image { // ToDo: remove this
                id: categoryIcon
                width: Theme.iconSizeLarge
                height: width
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                source: category.icons[0].url
            }

            SearchResultListItem {
                dataModel: model
            }

            menu: SearchResultContextMenu {}

            onClicked: app.pushPage(Util.HutspotPage.Playlist, {playlist: item})
        }

        VerticalScrollDecorator {}

        ViewPlaceholder {
            enabled: listView.count === 0
            text: qsTr("No Playlists found")
        }

        onAtYEndChanged: {
            if(listView.atYEnd && searchModel.count > 0)
                append()
        }
    }

    function refresh() {
        //showBusy = true
        searchModel.clear()
        append()
    }

    property bool _loading: false

    function append() {
        // if already at the end -> bail out
        if(searchModel.count > 0 && searchModel.count >= cursorHelper.total)
            return

        // guard
        if(_loading)
            return
        _loading = true

        var i;
        Spotify.getCategoryPlaylists(category.id,
                                     {offset: searchModel.count, limit: cursorHelper.limit},
                                     function(error, data) {
            if(data) {
                try {
                    //console.log("number of Playlists: " + data.playlists.items.length)
                    cursorHelper.offset = data.playlists.offset
                    cursorHelper.total = data.playlists.total
                    for(i=0;i<data.playlists.items.length;i++) {
                        searchModel.append({type: 2,
                                            name: data.playlists.items[i].name,
                                            item: data.playlists.items[i],
                                            following: app.spotifyDataCache.isPlaylistFollowed(data.playlists.items[i].id)})
                    }
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getCategoryPlaylists")
            }
            _loading = false
        })

    }

    property alias cursorHelper: cursorHelper

    CursorHelper {
        id: cursorHelper
    }

    Connections {
        target: app
        onFavoriteEvent: {
            switch(event.type) {
            case Util.SpotifyItemType.Playlist:
                Util.setSavedInfo(event.type, [event.id], [event.isFavorite], searchModel)
                break
            }
        }
        onHasValidTokenChanged: refresh()
    }

    Component.onCompleted: {
        if(app.hasValidToken)
            refresh()
    }

    // The shared DockedPanel needs mouse events
    // and some ListView events
    propagateComposedEvents: true
    onStatusChanged: {
        if(status === PageStatus.Activating)
            app.dockedPanel.registerListView(listView)
        else if(status === PageStatus.Deactivating)
            app.dockedPanel.unregisterListView(listView)
    }

}
