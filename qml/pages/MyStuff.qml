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
                title: qsTr("My Stuff")
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
                        case "0": return qsTr("Saved Albums")
                        case "1": return qsTr("Followed Artists")
                        case "2": return qsTr("Playlists")
                        case "3": return qsTr("Recently Played Tracks")
                        case "4": return qsTr("Saved Tracks")
                        }
                    }
                    font.bold: true
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.highlightColor
                    horizontalAlignment: Text.AlignRight
                    /*MouseArea {
                        anchors.fill: parent
                        onClicked: app.showErrorMessage(getSectionHeadingText(section))
                    }*/
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

            menu: SearchResultContextMenu {
                MenuItem {
                    enabled: type === 1 || type === 2
                    visible: enabled
                    text: qsTr("Unfollow")
                    onClicked: {
                        var idx = index
                        var model = searchModel
                        if(type === 1)
                            app.unfollowArtist(artist, function(error,data) {
                               if(!error)
                                   model.remove(idx, 1)
                            })
                        else
                            app.unfollowPlaylist(playlist, function(error,data) {
                               if(!error)
                                   model.remove(idx, 1)
                            })
                    }
                }
            }

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

        ViewPlaceholder {
            enabled: listView.count === 0
            text: qsTr("Nothing found")
            hintText: qsTr("Pull down to reload")
        }
    }

    NavigationPanel {
        id: navPanel
    }

    /*function getSectionHeadingText(section) {
        var s = ""
        switch(section) {
        case "0":
            s += qsTr("Saved Albums<br>")
            s += "total: " + cursors[0].total
            break
        case "1":
            s += qsTr("Followed Artists")
            break
        case "2":
            s += qsTr("Playlists<br>")
            s += "total: " + cursors[1].total
            break
        case "3":
            s += qsTr("Recently Played Tracks")
            s += qsTr("between ") + Date(cursors[2].cursors.before) + qsTr(" and ") + Date(cursors[2].cursors.after)
            break
        case "4":
            s += qsTr("Saved Tracks<br>")
            s += "total: " + cursors[3].total
            break
        }
        return s
    }*/

    // when the page is on the stack but not on top a refresh can wait
    property bool _needsRefresh: false

    onStatusChanged: {
        if (status === PageStatus.Activating) {
            if(_needsRefresh) {
                _needsRefresh = false
                refresh()
            }
        }
    }

    Connections {
        target: app

        onDetailsChangedOfPlaylist: {
            // check if the playist is in the current list if so trigger a refresh
            var i = Util.doesListModelContain(searchModel, Spotify.ItemType.Playlist, playlistId)
            if(i >= 0) {
                if(myStuffPage.status === PageStatus.Active)
                    refresh()
                else
                    _needsRefresh = true
            }
        }
        onCreatedPlaylist: {
            if(myStuffPage.status === PageStatus.Active)
                refresh()
            else
                _needsRefresh = true
        }
    }

    property var savedAlbums
    property var userPlaylists
    property var recentlyPlayedTracks
    property var savedTracks
    property var followedArtists
    property int pendingRequests

    property var cursors: []

    function loadData() {
        var i
        if(savedAlbums)
            for(i=0;i<savedAlbums.items.length;i++)
                searchModel.append({type: 0,
                                    stype: 0,
                                    name: savedAlbums.items[i].album.name,
                                    album: savedAlbums.items[i].album})
        if(userPlaylists)
            for(i=0;i<userPlaylists.items.length;i++) {
                searchModel.append({type: 2,
                                    stype: 2,
                                    name: userPlaylists.items[i].name,
                                    playlist: userPlaylists.items[i]})
            }
        if(recentlyPlayedTracks)
            for(i=0;i<recentlyPlayedTracks.items.length;i++) {
                searchModel.append({type: 3,
                                    stype: 3,
                                    name: recentlyPlayedTracks.items[i].track.name,
                                    track: recentlyPlayedTracks.items[i].track})
            }
        if(savedTracks)
            for(i=0;i<savedTracks.items.length;i++) {
                searchModel.append({type: 3,
                                    stype: 4,
                                    name: savedTracks.items[i].track.name,
                                    track: savedTracks.items[i].track})
            }
        if(followedArtists)
            for(i=0;i<followedArtists.artists.items.length;i++) {
                searchModel.append({type: 1,
                                    stype: 1,
                                    name: followedArtists.artists.items[i].name,
                                    following: true,
                                    artist: followedArtists.artists.items[i]})
            }

        cursorHelper.update(cursors)
    }

    property int nextPrevious: 0


    function refresh() {
        var i;

        searchModel.clear()
        savedAlbums = undefined
        userPlaylists = undefined
        savedTracks = undefined
        recentlyPlayedTracks = undefined
        followedArtists = undefined
        pendingRequests = 0

        pendingRequests++
        Spotify.getMySavedAlbums({offset: cursorHelper.offset, limit: cursorHelper.limit}, function(error, data) {
            if(data) {
                console.log("number of SavedAlbums: " + data.items.length)
                savedAlbums = data
                cursors[0] = Util.loadCursor(data)
            } else
                console.log("No Data for getMySavedAlbums")
            if(--pendingRequests == 0) // load when all requests are done
                loadData()
        })

        pendingRequests++
        Spotify.getUserPlaylists({offset: cursorHelper.offset, limit: cursorHelper.limit},function(error, data) {
            if(data) {
                console.log("number of playlists: " + data.items.length)
                userPlaylists = data
                cursors[1] = Util.loadCursor(data)
            } else
                console.log("No Data for getUserPlaylists")
            if(--pendingRequests == 0) // load when all requests are done
                loadData()
        })

        var options = {limit: cursorHelper.limit}
        // nextPrevious is reversed here
        if(cursors[2] && cursors[2].cursors) {
            if(nextPrevious < 0 && cursors[2].cursors.after)
               options.after = cursors[2].cursors.after
            else if(nextPrevious > 0 && cursors[2].cursors.before)
                options.before = cursors[2].cursors.before
        }
        pendingRequests++
        Spotify.getMyRecentlyPlayedTracks(options, function(error, data) {
            if(data) {
                console.log("number of RecentlyPlayedTracks: " + data.items.length)
                recentlyPlayedTracks = data
                cursors[2] = Util.loadCursor(data, Util.CursorType.RecentlyPlayed)
            } else
                console.log("No Data for getMyRecentlyPlayedTracks")
            if(--pendingRequests == 0) // load when all requests are done
                loadData()
        })

        pendingRequests++
        Spotify.getMySavedTracks({offset: cursorHelper.offset, limit: cursorHelper.limit}, function(error, data) {
            if(data) {
                console.log("number of SavedTracks: " + data.items.length)
                savedTracks = data
                cursors[3] = Util.loadCursor(data)
            } else
                console.log("No Data for getMySavedTracks")
            if(--pendingRequests == 0) // load when all requests are done
                loadData()
        })

        options = {limit: cursorHelper.limit}
        var perform = true
        if(cursors[4] && cursors[4].cursors) {
            if(nextPrevious > 0 && cursors[4].cursors.after)
               options.after = cursors[4].cursors.after
            else if(nextPrevious < 0 && cursors[4].cursors.before)
                options.before = cursors[4].cursors.before
            if(nextPrevious > 0 && cursors[4].cursors.after === null)
                perform = false // no more followed artists
        }
        if(perform) {
            pendingRequests++
            Spotify.getFollowedArtists(options, function(error, data) {
                if(data) {
                    console.log("number of FollowedArtists: " + data.artists.items.length)
                    followedArtists = data
                    cursors[4] = Util.loadCursor(data.artists, Util.CursorType.FollowedArtists)
                } else
                    console.log("No Data for getFollowedArtists")
                if(--pendingRequests == 0) // load when all requests are done
                    loadData()
            })
        }
    }

    property alias cursorHelper: cursorHelper

    CursorHelper {
        id: cursorHelper

        useHas: true
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
    }

    Component.onCompleted: {
        if(app.hasValidToken)
            refresh()
    }

}
