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
        height: parent.height - app.dockedPanel.visibleSize
        clip: app.dockedPanel.expanded

        //LoadPullMenus {}
        //LoadPushMenus {}

        header: Column {
            id: lvColumn

            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium
            anchors.bottomMargin: Theme.paddingLarge
            spacing: Theme.paddingLarge

            PageHeader {
                id: pHeader
                width: parent.width
                title: {
                    switch(_itemClass) {
                    case 0: return Util.createPageHeaderLabel(qsTr("Top "), qsTr("Tracks"), Theme)
                    case 1: return Util.createPageHeaderLabel(qsTr("Top "), qsTr("Artists"), Theme)
                    }
                }
                MenuButton { z: 1} // set z so you can still click the button
                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: true
                    onClicked: nextItemClass()
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
                    app.pushPage(Util.HutspotPage.Artist, {currentArtist: item})
                    break;
                case 3:
                    app.pushPage(Util.HutspotPage.Album, {album: item.album})
                    break;
                }
            }
        }

        VerticalScrollDecorator { id: vsd }

        ViewPlaceholder {
            enabled: listView.count === 0
            text: qsTr("Nothing found")
            hintText: qsTr("Pull down to reload")
        }

        onAtYEndChanged: {
            if(listView.atYEnd && searchModel.count > 0)
                append()
        }
    }

    property var topTracks
    property var topArtists
    property int _itemClass: app.current_item_classes.topStuff

    function nextItemClass() {
        var i = _itemClass
        i++
        if(i > 1)
            i = 0
        _itemClass = i
        app.current_item_classes.topStuff = i
        refresh()
    }

    function loadData() {
        var i

        // I don't understand why I have to make the objects being appended
        // have the same properties. Before I did that the artist property
        // would be missing in the delegate of the ListView. That did never happen
        // when both tracks as well as artists were added in this function.

        if(topTracks)
            for(i=0;i<topTracks.items.length;i++)
                searchModel.append({type: 3,
                                    name: topTracks.items[i].name,
                                    item: topTracks.items[i],
                                    following: false})
        if(topArtists) {
            for(i=0;i<topArtists.items.length;i++) {
                searchModel.append({type: 1,
                                    name: topArtists.items[i].name,
                                    item: topArtists.items[i],
                                    following: app.spotifyDataCache.isArtistFollowed(topArtists.items[i].id)})
            }
        }
    }

    function refresh() {
        searchModel.clear()
        topTracks = undefined
        topArtists = undefined
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
        switch(_itemClass) {
        case 0:
            Spotify.getMyTopTracks({offset: searchModel.count, limit: cursorHelper.limit}, function(error, data) {
                try {
                    if(data) {
                        console.log("number of TopTracks: " + data.items.length)
                        topTracks = data
                        cursorHelper.offset = data.offset
                        cursorHelper.total = data.total
                    } else
                        console.log("No Data for getMyTopTracks")
                    loadData()
                } catch(err) {
                    console.log("getMyTopTracks exception: " + err)
                } finally {
                    _loading = false
                }
            })
            break
        case 1:
            Spotify.getMyTopArtists({offset: searchModel.count, limit: cursorHelper.limit}, function(error, data) {
                try {
                    if(data) {
                        console.log("number of MyTopArtists: " + data.items.length)
                        topArtists = data
                        cursorHelper.offset = data.offset
                        cursorHelper.total = data.total
                    } else
                        console.log("No Data for getMyTopArtists")
                    loadData()
                } catch(err) {
                    console.log("getMyTopArtists exception: " + err)
                } finally {
                    _loading = false
                }
            })
            break
        }
    }

    property alias cursorHelper: cursorHelper

    CursorHelper {
        id: cursorHelper

        onLoadNext: refresh()
        onLoadPrevious: refresh()
    }

    Connections {
        target: app
        onLoggedInChanged: {
            if(app.loggedIn)
                refresh()
        }
        onHasValidTokenChanged: refresh()
        onFavoriteEvent: {
            switch(event.type) {
            case Util.SpotifyItemType.Artist:
                Util.setSavedInfo(event.type, [event.id], [event.isFavorite], searchModel)
                break
            }
        }
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
