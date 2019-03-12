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
    property string featuredPlaylistsMessage: ""

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
                    case 0: return Util.createPageHeaderLabel("", qsTr("New Releases"), Theme)
                    case 1: return Util.createPageHeaderLabel("", qsTr("Featured"), Theme)
                    }
                }
                MenuButton { z: 1} // set z so you can still click the button
                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: true
                    onClicked: nextItemClass()
                }
            }

            SectionHeader {
                width: parent.width
                x: 0
                text: featuredPlaylistsMessage
                visible: _itemClass == 1
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
                case Util.SpotifyItemType.Album:
                    app.pushPage(Util.HutspotPage.Album, {album: item})
                    break
                case Util.SpotifyItemType.Playlist:
                    app.pushPage(Util.HutspotPage.Playlist, {playlist: item})
                    break
                }
            }
        }

        VerticalScrollDecorator {}

        ViewPlaceholder {
            enabled: listView.count === 0
            text: qsTr("Nothing found")
        }

        onAtYEndChanged: {
            if(listView.atYEnd && searchModel.count > 0)
                append()
        }
    }

    property var topTracks
    property var topArtists
    property int _itemClass: app.current_item_classes.featuredStuff

    function nextItemClass() {
        var i = _itemClass
        i++
        if(i > 1)
            i = 0
        _itemClass = i
        app.current_item_classes.featuredStuff = i
        refresh()
    }

    function refresh() {
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

        var i
        var options
        switch(_itemClass) {
        case 0:
            options = {offset: searchModel.count, limit: cursorHelper.limit}
            Spotify.getNewReleases(options, function(error, data) {
                try {
                    if(data) {
                        cursorHelper.offset = data.albums.offset
                        cursorHelper.total = data.albums.total
                        try {
                            for(i=0;i<data.albums.items.length;i++) {
                                searchModel.append({type: Util.SpotifyItemType.Album,
                                                    name: data.albums.items[i].name,
                                                    item: data.albums.items[i],
                                                    following: false,
                                                    saved: app.spotifyDataCache.isPlaylistFollowed(data.albums.items[i].id)})
                            }
                        } catch (err) {
                            console.log(err)
                        }
                    } else {
                        console.log("getNewReleases returned no results.")
                    }
                } catch(err) {
                    console.log("getNewReleases exception: " + err)
                } finally {
                    showBusy = false
                    _loading = false
                }
            })
            break
        case 1:
            options = {offset: searchModel.count, limit: cursorHelper.limit}
            options.timestamp = new Date().toISOString()
            if(app.locale_config.country.length === 2)
                options.country = app.locale_config.country
            Spotify.getFeaturedPlaylists(options, function(error, data) {
                try {
                    if(data) {
                        cursorHelper.offset = data.playlists.offset
                        cursorHelper.total = data.playlists.total
                        featuredPlaylistsMessage = data.message
                        try {
                            for(i=0;i<data.playlists.items.length;i++) {
                                searchModel.append({type: Util.SpotifyItemType.Playlist,
                                                    name: data.playlists.items[i].name,
                                                    item: data.playlists.items[i],
                                                    following: app.spotifyDataCache.isPlaylistFollowed(data.playlists.items[i].id),
                                                    saved: false})
                            }
                        } catch (err) {
                            console.log(err)
                        }
                    } else {
                        console.log("getFeaturedPlaylists returned no results.")
                    }
                } catch(err) {
                    console.log("getFeaturedPlaylists exception: " + err)
                } finally {
                    showBusy = false
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
            case Util.SpotifyItemType.Album:
            case Util.SpotifyItemType.Playlist:
                Util.setSavedInfo(event.type, [event.id], [event.isFavorite], searchModel)
                break
            }
        }
        // if this is the first page data might already be loaded before the data cache is ready
        onSpotifyDataCacheReady: Util.updateFollowingSaved(app.spotifyDataCache, searchModel)
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
