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
    id: myStuffPage
    objectName: "MyStuffPage"

    property int searchInType: 0
    property bool showBusy: false

    property int currentIndex: -1

    allowedOrientations: Orientation.All

    SortedListModel {
        id: searchModel
        sortKey: _itemClass != 2 ? "name" : ""
    }

    SilicaListView {
        id: listView
        property alias sectionDelegate: sectionDelegate

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
                    case 0: return Util.createPageHeaderLabel(qsTr("My "), qsTr("Saved Albums"), Theme)
                    case 1: return Util.createPageHeaderLabel(qsTr("My "), qsTr("Playlists"), Theme)
                    case 2: return Util.createPageHeaderLabel(qsTr("My "), qsTr("Recently Played"), Theme)
                    case 3: return Util.createPageHeaderLabel(qsTr("My "), qsTr("Saved Tracks"), Theme)
                    case 4: return Util.createPageHeaderLabel(qsTr("My "), qsTr("Followed Artists"), Theme)
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

        SectionDelegate {
            id: sectionDelegate
        }

        // no name section for Recently Played
        section.property: _itemClass != 2 ? "nameFirstChar" : ""
        section.delegate: sectionDelegate

        delegate: ListItem {
            id: listItem
            width: parent.width
            contentHeight: Theme.itemSizeLarge

            SearchResultListItem {
                id: searchResultListItem
                dataModel: model
            }

            menu: SearchResultContextMenu {
                MenuItem {
                    enabled: type === 1 || type === 2
                    visible: enabled
                    text: qsTr("Unfollow")
                    onClicked: {
                        var idx = index
                        var model = searchModel
                        if(type === 1)
                            app.unfollowArtist(item, function(error,data) {
                               if(!error)
                                   model.remove(idx, 1)
                            })
                        else
                            app.unfollowPlaylist(item, function(error,data) {
                               if(!error)
                                   model.remove(idx, 1)
                            })
                    }
                }
            }

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
            if(listView.atYEnd && searchModel.count > 0)
                append()
        }
    }

    // when the page is on the stack but not on top a refresh can wait
    property bool _needsRefresh: false

    Connections {
        target: app

        onPlaylistEvent: {
            if(_itemClass !== 1)
                return
            switch(event.type) {
            case Util.PlaylistEventType.AddedTrack:
            case Util.PlaylistEventType.ChangedDetails:
            case Util.PlaylistEventType.RemovedTrack:
            case Util.PlaylistEventType.ReplacedAllTracks:
                // check if the playlist is in the current list if so trigger a refresh
                var i = Util.doesListModelContain(searchModel, Spotify.ItemType.Playlist, event.playlistId)
                if(i >= 0) {
                    if(myStuffPage.status === PageStatus.Active)
                        refresh()
                    else
                        _needsRefresh = true
                }
                break
             case Util.PlaylistEventType.CreatedPlaylist:
                 if(myStuffPage.status === PageStatus.Active)
                     refresh()
                 else
                     _needsRefresh = true
                 break
            }
        }
    }

    property var savedAlbums
    property var userPlaylists
    property var recentlyPlayedTracks
    property var savedTracks
    property var followedArtists
    // 0: Saved Albums, 1: User Playlists, 2: Recently Played Tracks, 3: Saved Tracks, 4: Followed Artists
    property int _itemClass: app.current_item_classes.myStuff

    function nextItemClass() {
        var i = _itemClass
        i++
        if(i > 4)
            i = 0
        _itemClass = i
        app.current_item_classes.myStuff = i
        refreshDirection = 0
        refresh()
    }

    function addData(obj) {
        obj.nameFirstChar = Util.getFirstCharForSection(obj.name)
        if(!obj.hasOwnProperty('played_at'))
            obj.played_at = ""
        if(!obj.hasOwnProperty('following'))
            obj.following = false
        searchModel.add(obj)
    }

    function loadData() {
        var i

        // if total too high disable sorting
        if(searchModel.count == 0) {
            if(cursorHelper.total <= app.sorted_list_limit.value) {
                searchModel.sortKey = _itemClass != 2 ? "name" : ""
                listView.section.delegate = listView.sectionDelegate
            } else {
                searchModel.sortKey = ""
                listView.section.delegate = null
            }
        }

        // more to load?
        var count = searchModel.count
        if(savedAlbums)
            count += savedAlbums.items.length
        else if(userPlaylists)
            count += userPlaylists.items.length
        else if(recentlyPlayedTracks)
            count += recentlyPlayedTracks.items.length
        else if(savedTracks)
            count += savedTracks.items.length
        else if(followedArtists)
            count += followedArtists.artists.items
        if(count < cursorHelper.total)
            append()

        // add data
        if(savedAlbums)
            for(i=0;i<savedAlbums.items.length;i++)
                addData({type: 0, stype: 0,
                         name: savedAlbums.items[i].album.name,
                         item: savedAlbums.items[i].album,
                         following: false, saved: true})
        if(userPlaylists)
            for(i=0;i<userPlaylists.items.length;i++) {
                addData({type: 2, stype: 2,
                         name: userPlaylists.items[i].name,
                         item: userPlaylists.items[i],
                         following: true, saved: false})
            }
        if(recentlyPlayedTracks)
            // context, played_at, track
            for(i=0;i<recentlyPlayedTracks.items.length;i++) {
                addData({type: 3, stype: 3,
                         name: recentlyPlayedTracks.items[i].track.name,
                         item: recentlyPlayedTracks.items[i].track,
                         following: false, saved: false,
                         played_at: recentlyPlayedTracks.items[i].played_at})
            }
        if(savedTracks)
            for(i=0;i<savedTracks.items.length;i++) {
                addData({type: 3, stype: 4,
                         name: savedTracks.items[i].track.name,
                         item: savedTracks.items[i].track,
                         following: true, saved: true})
            }
        if(followedArtists)
            for(i=0;i<followedArtists.artists.items.length;i++) {
                addData({type: 1, stype: 1,
                         name: followedArtists.artists.items[i].name,
                         item: followedArtists.artists.items[i],
                         following: true, saved: false})
            }
    }

    property int nextPrevious: 0


    function refresh() {
        searchModel.clear()
        savedAlbums = undefined
        userPlaylists = undefined
        savedTracks = undefined
        recentlyPlayedTracks = undefined
        followedArtists = undefined
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

        var i, options;
        switch(_itemClass) {
        case 0:
            Spotify.getMySavedAlbums({offset: searchModel.count, limit: cursorHelper.limit}, function(error, data) {
                if(data) {
                    console.log("number of SavedAlbums: " + data.items.length)
                    savedAlbums = data
                    cursorHelper.offset = data.offset
                    cursorHelper.total = data.total
                } else
                    console.log("No Data for getMySavedAlbums")
                loadData()
                _loading = false
            })
            break
        case 1:
            Spotify.getUserPlaylists({offset: searchModel.count, limit: cursorHelper.limit},function(error, data) {
                if(data) {
                    console.log("number of playlists: " + data.items.length)
                    userPlaylists = data
                    cursorHelper.offset = data.offset
                    cursorHelper.total = data.total
                } else
                    console.log("No Data for getUserPlaylists")
                loadData()
                _loading = false
            })
            break
        case 2:
            // unfortunately:
            //   Any tracks listened to while the user had “Private Session” enabled in
            //   their client will not be returned in the list of recently played tracks.
            // and it seems Librespot just does that when using credentials
            options = {limit: cursorHelper.limit}
            // 'RecentlyPlayedTracks' has 'before' and 'after' fields
            if(refreshDirection < 0) // previous set is looking forward in time
                options.after = cursorHelper.after
            else if(refreshDirection > 0) // next set is looking back in time
                options.before = cursorHelper.before
            Spotify.getMyRecentlyPlayedTracks(options, function(error, data) {
                if(data) {
                    console.log("number of RecentlyPlayedTracks: " + data.items.length)
                    recentlyPlayedTracks = data
                    cursorHelper.update(Util.loadCursor(data, Util.CursorType.RecentlyPlayed))
                } else
                    console.log("No Data for getMyRecentlyPlayedTracks")
                loadData()
                _loading = false
            })
            break
        case 3:
            Spotify.getMySavedTracks({offset: searchModel.count, limit: cursorHelper.limit}, function(error, data) {
                if(data) {
                    console.log("number of SavedTracks: " + data.items.length)
                    savedTracks = data
                    cursorHelper.offset = data.offset
                    cursorHelper.total = data.total
                } else
                    console.log("No Data for getMySavedTracks")
                loadData()
                _loading = false
            })
            break
        case 4:
            // 'Followed Artists' only has an 'after' field
            options = {limit: cursorHelper.limit}
            if(refreshDirection > 0)
                options.after = cursorHelper.after
            Spotify.getFollowedArtists(options, function(error, data) {
                if(data) {
                    console.log("number of FollowedArtists: " + data.artists.items.length)
                    followedArtists = data
                    cursorHelper.update(Util.loadCursor(data.artists, Util.CursorType.FollowedArtists))
                } else
                    console.log("No Data for getFollowedArtists")
                loadData()
                _loading = false
            })
            break
        }
    }

    property int refreshDirection: 0
    property alias cursorHelper: cursorHelper

    CursorHelper {
        id: cursorHelper

        useHas: true
    }

    Connections {
        target: app
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
        if(status === PageStatus.Activating) {
            app.dockedPanel.registerListView(listView)
            if(_needsRefresh) {
                _needsRefresh = false
                refresh()
            }
        } else if(status === PageStatus.Deactivating)
            app.dockedPanel.unregisterListView(listView)
    }
}
