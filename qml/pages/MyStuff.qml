/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */


import QtQuick 2.2
import Sailfish.Silica 1.0

import "../components"
import "../Spotify.js" as Spotify

Page {
    id: myStuffPage
    objectName: "MyStuffPage"

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
        anchors.fill: parent
        anchors.topMargin: 0

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
                BusyIndicator {
                    id: busyThingy
                    parent: pHeader.extraContent
                    anchors.left: parent.left
                    running: showBusy;
                }
                anchors.horizontalCenter: parent.horizontalCenter
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
            }

            menu: contextMenu
            Component {
                id: contextMenu
                ContextMenu {
                    MenuItem {
                        text: qsTr("Play")
                        onClicked: {
                            switch(type) {
                            case 0:
                                app.playContext(album)
                                break;
                            case 1:
                                app.playContext(artist)
                                break;
                            case 2:
                                app.playContext(playlist)
                                break;
                            case 3:
                                app.playTrack(track)
                                break;
                            }
                        }
                    }
                    MenuItem {
                        text: qsTr("View")
                        enabled: type === 0 || type === 1 || type === 2
                        onClicked: {
                            switch(type) {
                            case 0:
                                pageStack.push(Qt.resolvedUrl("Album.qml"), {album: album})
                                break;
                            case 1:
                                pageStack.push(Qt.resolvedUrl("Artist.qml"), {currentArtist: artist})
                                break;
                            case 2:
                                pageStack.push(Qt.resolvedUrl("Playlist.qml"), {playlist: playlist})
                                break;
                            }
                        }
                    }
                    MenuItem {
                        enabled: type === 3
                        visible: enabled
                        text: qsTr("Add to Playlist")
                        onClicked: app.addToPlaylist(track)
                    }
                    MenuItem {
                        enabled: type === 1 || type === 2
                        visible: enabled
                        text: qsTr("Unfollow")
                        onClicked: {
                            if(type === 1)
                                app.unfollowArtist(artist, function(error,data) {
                                   if(data)
                                       searchModel.remove(index, 1)
                                })
                            else
                                app.unfollowPlaylist(playlist, function(error,data) {
                                   if(data)
                                       searchModel.remove(index, 1)
                                })
                        }
                    }
                }
            }
            //onClicked: app.loadStation(model.id, Shoutcast.createInfo(model), tuneinBase)
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

    property var savedAlbums
    property var userPlaylists
    property var recentlyPlayedTracks
    property var savedTracks
    property var followedArtists
    property int pendingRequests

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

    }

    function refresh() {
        var i;
        //showBusy = true
        searchModel.clear()
        savedAlbums = undefined
        userPlaylists = undefined
        savedTracks = undefined
        recentlyPlayedTracks = undefined
        followedArtists = undefined
        pendingRequests = 5

        Spotify.getMySavedAlbums({offset: offset, limit: limit}, function(error, data) {
            if(data) {
                console.log("number of SavedAlbums: " + data.items.length)
                savedAlbums = data
            } else
                console.log("No Data for getMySavedAlbums")
            if(--pendingRequests == 0) // load when all requests are done
                loadData()
        })

        Spotify.getUserPlaylists({offset: offset, limit: limit},function(error, data) {
            if(data) {
                console.log("number of playlists: " + data.items.length)
                userPlaylists = data
            } else
                console.log("No Data for getUserPlaylists")
            if(--pendingRequests == 0) // load when all requests are done
                loadData()
        })

        Spotify.getMyRecentlyPlayedTracks({offset: offset, limit: limit}, function(error, data) {
            if(data) {
                console.log("number of RecentlyPlayedTracks: " + data.items.length)
                recentlyPlayedTracks = data
                // todo offset per request type
            } else
                console.log("No Data for getMyRecentlyPlayedTracks")
            if(--pendingRequests == 0) // load when all requests are done
                loadData()
        })

        Spotify.getMySavedTracks({offset: offset, limit: limit}, function(error, data) {
            if(data) {
                console.log("number of SavedTracks: " + data.items.length)
                offset = data.offset
                savedTracks = data
            } else
                console.log("No Data for getMySavedTracks")
            if(--pendingRequests == 0) // load when all requests are done
                loadData()
        })

        Spotify.getFollowedArtists({}, function(error, data) {
            if(data) {
                console.log("number of FollowedArtists: " + data.artists.items.length)
                followedArtists = data
            } else
                console.log("No Data for getFollowedArtists")
            if(--pendingRequests == 0) // load when all requests are done
                loadData()
        })

        /*Spotify.getMyTopArtists({}, function(error, data) {
            if(data) {
                try {
                    console.log("number of TopArtists: " + data.items.length)
                    for(i=0;i<data.items.length;i++) {
                        searchModel.append({type: 1,
                                            name: data.items[i].track.name,
                                            track: data.items[i].track})
                    }
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getMyTopArtists")
            }
        })*/

    }

    Component.onCompleted: refresh()
}
