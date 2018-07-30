/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 * Copyright (C) 2018 Maciej Janiszewski
 *
 * License: MIT
 */

import QtQuick 2.2
import Sailfish.Silica 1.0

import "../components"
import "../Spotify.js" as Spotify

Page {
    id: myStuffPage
    objectName: "MainStuffPage"

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

        PullDownMenu {
            MenuItem {
                text: "About"
                onClicked: pageStack.push(Qt.resolvedUrl("About.qml"))
            }

            MenuItem {
                text: "Settings"
                onClicked: pageStack.push(Qt.resolvedUrl("Settings.qml"))
            }
            MenuItem {
                text: "Devices"
                onClicked: pageStack.push(Qt.resolvedUrl("Devices.qml"))
            }
        }

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
            }

            Row {
                width: parent.width
                property int rowWidth: (parent.width / 2) - (Theme.paddingMedium / 2)
                spacing: Theme.paddingMedium
                Button {
                    width: parent.rowWidth
                    text: "New Releases"
                    onClicked: pageStack.push(Qt.resolvedUrl("NewRelease.qml"))
                }
                Button {
                    width: parent.rowWidth
                    text: "Top stuff"
                    onClicked: pageStack.push(Qt.resolvedUrl("TopStuff.qml"))
                }
            }
            Row {
                width: parent.width
                property int rowWidth: (parent.width / 2) - (Theme.paddingMedium / 2)
                spacing: Theme.paddingMedium
                Button {
                    width: parent.rowWidth
                    text: "Genres & Mood"
                    onClicked: pageStack.push(Qt.resolvedUrl("GenreMood.qml"))
                }
                Button {
                    width: parent.rowWidth
                    text: "Search"
                    onClicked: pageStack.push(Qt.resolvedUrl("Search.qml"))
                }
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
                    pageStack.push(Qt.resolvedUrl("Album.qml"), {album: album})
                    break;
                case 1:
                    pageStack.push(Qt.resolvedUrl("Artist.qml"), {currentArtist: artist})
                    break;
                case 2:
                    pageStack.push(Qt.resolvedUrl("Playlist.qml"), {playlist: playlist})
                    break;
                case 3:
                    pageStack.push(Qt.resolvedUrl("Album.qml"), {album: track.album})
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

    }

    Connections {
        target: spotify
        onLinkingSucceeded: refresh()
    }

    Component.onCompleted: refresh()
}

