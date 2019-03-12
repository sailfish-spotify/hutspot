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
        }

        onAtYEndChanged: {
            if(listView.atYEnd && searchModel.count > 0)
                append()
        }
    }

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

    function refresh() {
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
        switch(_itemClass) {
        case 0:
            Spotify.getMyTopTracks({offset: searchModel.count, limit: cursorHelper.limit}, function(error, data) {
                try {
                    if(data) {
                        //console.log("number of TopTracks: " + data.items.length)
                        cursorHelper.offset = data.offset
                        cursorHelper.total = data.total
                        app.loadTracksInModel(data, data.items.length, searchModel, function(data, i) {return data.items[i]})
                    } else
                        console.log("No Data for getMyTopTracks")
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
                        //console.log("number of MyTopArtists: " + data.items.length)
                        cursorHelper.offset = data.offset
                        cursorHelper.total = data.total
                        for(i=0;i<data.items.length;i++) {
                            var artist = data.items[i]
                            searchModel.append({type: 1,
                                                name: artist.name,
                                                item: artist,
                                                following: app.spotifyDataCache.isArtistFollowed(artist.id),
                                                saved: false})
                        }
                    } else
                        console.log("No Data for getMyTopArtists")
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
