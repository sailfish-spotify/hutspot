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

    property int currentIndex: -1

    property var searchTargets: [qsTr("Albums"), qsTr("Artists"), qsTr("Playlists"), qsTr("Tracks")]
    property var scMap: []

    allowedOrientations: Orientation.All

    ListModel {
        id: searchModel
    }

    ListModel {
        id: searchHistoryModel
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
            //spacing: Theme.paddingSmall

            PageHeader {
                id: pHeader
                width: parent.width
                title: {
                    switch(_itemClass) {
                    case 0: return Util.createPageHeaderLabel(qsTr("Search "), qsTr("Albums"), Theme)
                    case 1: return Util.createPageHeaderLabel(qsTr("Search "), qsTr("Artists"), Theme)
                    case 2: return Util.createPageHeaderLabel(qsTr("Search "), qsTr("Playlists"), Theme)
                    case 3: return Util.createPageHeaderLabel(qsTr("Search "), qsTr("Tracks"), Theme)
                    default: qsTr("Search")
                    }
                }
                MenuButton { z: 1} // set z so you can still click the button
                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: true
                    onClicked: {
                        nextItemClass()
                        refresh()
                    }
                }
            }

            //LoadPullMenus {}
            //LoadPushMenus {}

            SearchFieldWithMenu {
                id: searchField
                width: parent.width
                placeholderText: qsTr("Search text")
                Binding {
                    target: searchPage
                    property: "searchString"
                    value: searchField.text.toLowerCase().trim()
                }
                EnterKey.enabled: text.length > 0
                EnterKey.onClicked: {
                    refresh()
                    Util.updateSearchHistory(searchField.text.trim(),
                                             app.search_history,
                                             app.search_history_max_size.value)
                }
                EnterKey.iconSource: "image://theme/icon-m-search"
                Component.onCompleted: searchField.forceActiveFocus()

                menu: ContextMenu {
                    onActiveChanged: {
                        // somehow the menu is opened by scrolling up. very annoying.
                        // and also causing the button to become too close to the 'next page' bulb
                        // so if the menu opens or closes scroll back to the top
                        listView.positionViewAtBeginning()
                    }

                    MenuItem {
                        text: qsTr("Clear Current Text")
                        onClicked: {
                            searchField.text = ""
                            searchField.forceActiveFocus()
                        }
                    }
                    MenuItem {
                        text: qsTr("Select Recently Used Query")
                        onClicked: {
                            searchHistoryModel.clear()
                            var sh = app.search_history.value
                            for(var i=0;i<sh.length;i++)
                                searchHistoryModel.append({id: i, name: sh[i]})
                            var ms = pageStack.push(Qt.resolvedUrl("../components/ItemPicker.qml"),
                                                    {items: searchHistoryModel, label: qsTr("Search History")} );
                            ms.accepted.connect(function() {
                                if(ms.selectedIndex === -1)
                                    return
                                searchField.text = ms.items.get(ms.selectedIndex).name
                                searchField.forceActiveFocus()
                                refresh()
                                Util.updateSearchHistory(searchField.text.trim(),
                                                         app.search_history,
                                                         app.search_history_max_size.value)                            })
                                listView.positionViewAtBeginning() // see above
                        }
                    }
                    MenuItem {
                        text: qsTr("Clear Recently Used Queries")
                        onClicked: {
                            app.showConfirmDialog(qsTr("Please confirm Clearing the Search History"), function() {
                                app.search_history.value = []
                            })
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: Theme.paddingMedium
                opacity: 0
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
                    app.pushPage(Util.HutspotPage.Album, {album: item})
                    break;
                case 1:
                    app.pushPage(Util.HutspotPage.Artist, {currentArtist: item})
                    break;
                case 2:
                    app.pushPage(Util.HutspotPage.Playlist, {playlist: item})
                    break;
                case 3:
                    app.pushPage(Util.HutspotPage.Album, {album: item.album})
                    break;
                }
            }
        }

        VerticalScrollDecorator {}

        ViewPlaceholder {
            enabled: listView.count === 0
            text: qsTr("Nothing found")
        }

        onAtYEndChanged: {
            if(listView.atYEnd && searchModel.count > 0) {
                if(searchString === "")
                    return
                if(_itemClass === -1)
                    nextItemClass()
                append()
            }
        }
    }

    property alias cursorHelper: cursorHelper

    CursorHelper {
        id: cursorHelper

        onLoadNext: refresh()
        onLoadPrevious: refresh()
    }

    // 0: Albums, 1: Artists, 2: Playlists, 3: Tracks
    property int _itemClass: app.current_item_classes.search

    function nextItemClass() {
        var i = _itemClass
        i++
        if(i > 3)
            i = 0
        _itemClass = i
        app.current_item_classes.search = i
    }

    function refresh() {
        if(searchString === "")
            return
        if(_itemClass === -1)
            nextItemClass()
        showBusy = true
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
        var types = []
        if(_itemClass === 0)
            types.push('album')
        else if(_itemClass === 1)
            types.push('artist')
        else if(_itemClass === 2)
            types.push('playlist')
        else if(_itemClass === 3)
            types.push('track')

        var options = {offset: searchModel.count, limit: cursorHelper.limit}
        if(app.query_for_market.value)
            options.market = "from_token"
        Spotify.search(Util.processSearchString(searchString), types, options, function(error, data) {
            if(data) {
                var artistIds = []
                try {
                    // albums
                    if(data.hasOwnProperty('albums')) {
                        for(i=0;i<data.albums.items.length;i++) {
                            searchModel.append({type: 0,
                                                name: data.albums.items[i].name,
                                                item: data.albums.items[i],
                                                following: false,
                                                saved: app.spotifyDataCache.isAlbumSaved(data.albums.items[i].id)})
                        }
                        cursorHelper.offset = data.albums.offset
                        cursorHelper.total = data.albums.total
                    }

                    // artists
                    if(data.hasOwnProperty('artists')) {
                        for(i=0;i<data.artists.items.length;i++) {
                            searchModel.append({type: 1,
                                                name: data.artists.items[i].name,
                                                item: data.artists.items[i],
                                                following: app.spotifyDataCache.isArtistFollowed(data.artists.items[i].id),
                                                saved: false})
                            artistIds.push(data.artists.items[i].id)
                        }
                        cursorHelper.offset = data.artists.offset
                        cursorHelper.total = data.artists.total
                    }

                    // playlists
                    if(data.hasOwnProperty('playlists')) {
                        for(i=0;i<data.playlists.items.length;i++) {
                            searchModel.append({type: 2,
                                                name: data.playlists.items[i].name,
                                                item: data.playlists.items[i],
                                                following: app.spotifyDataCache.isPlaylistFollowed(data.playlists.items[i].id),
                                                saved: false})
                        }
                        cursorHelper.offset = data.playlists.offset
                        cursorHelper.total = data.playlists.total
                    }

                    // tracks
                    if(data.hasOwnProperty('tracks')) {
                        cursorHelper.offset = data.tracks.offset
                        cursorHelper.total = data.tracks.total
                        var trackIds = []
                        for(i=0;i<data.tracks.items.length;i++) {
                            var track = data.tracks.items[i]
                            searchModel.append({type: 3,
                                                name: track.name,
                                                item: track,
                                                following: false,
                                                saved: false})
                            trackIds.push(track.id)
                        }
                        Spotify.containsMySavedTracks(trackIds, function(error, data) {
                            if(data) {
                                Util.setSavedInfo(Spotify.ItemType.Track, trackIds, data, searchModel)
                            }
                        })                    }

                } catch (err) {
                    console.log("Search.refresh error: " + err)
                }
            } else {
                console.log("Search for: " + searchString + " returned no results.")
            }
            // unfortunately Spotify does not return an error when it has an invalid query
            if(error)
                app.showErrorMessage(error, qsTr("Search Failed"))
            showBusy = false
            _loading = false
        })
    }

    Connections {
        target: app
        onFavoriteEvent: {
            switch(event.type) {
            case Util.SpotifyItemType.Album:
            case Util.SpotifyItemType.Artist:
            case Util.SpotifyItemType.Playlist:
                Util.setSavedInfo(event.type, [event.id], [event.isFavorite], searchModel)
                break
            }
        }
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
