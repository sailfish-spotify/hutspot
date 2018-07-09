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
    id: artistPage
    objectName: "ArtistPage"

    property string defaultImageSource : "image://theme/icon-l-music"
    property bool showBusy: false

    property var currentArtist
    property bool isFollowed: false

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
            spacing: Theme.paddingMedium

            PageHeader {
                id: pHeader
                width: parent.width
                title: qsTr("Artist")
                BusyIndicator {
                    id: busyThingy
                    parent: pHeader.extraContent
                    anchors.left: parent.left
                    running: showBusy;
                }
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Image {
                id: imageItem
                source: (currentArtist && currentArtist.images)
                        ? currentArtist.images[0].url : defaultImageSource
                width: parent.width * 0.75
                height: width
                fillMode: Image.PreserveAspectFit
                anchors.horizontalCenter: parent.horizontalCenter
                onPaintedHeightChanged: height = Math.min(parent.width, paintedHeight)
                MouseArea {
                       anchors.fill: parent
                       onClicked: app.playContext(album)
                }
            }

            Label {
                id: nameLabel
                color: Theme.primaryColor
                textFormat: Text.StyledText
                truncationMode: TruncationMode.Fade
                width: parent.width
                text:  currentArtist ? currentArtist.name : qsTr("No Name")
            }

            Label {
                color: Theme.primaryColor
                truncationMode: TruncationMode.Fade
                font.pixelSize: Theme.fontSizeSmall
                width: parent.width
                wrapMode: Text.Wrap
                visible: text.length > 0
                text: {
                    var s = ""
                    if(currentArtist.genres && currentArtist.genres.length > 0)
                        s += Util.createItemsString(currentArtist.genres, "")
                    return s
                }
            }

            TextSwitch {
                checked: isFollowed
                text: qsTr("Following")
                 onClicked: {
                     if(isFollowed)
                          app.unfollowArtist(currentArtist, function(error,data) {
                              if(data)
                                  isFollowed = false
                          })
                      else
                          app.followArtist(currentArtist, function(error,data) {
                              if(data)
                                  isFollowed = true
                          })
                 }
            }

            /*Rectangle {
                width: parent.width
                height:Theme.paddingLarge
                opacity: 0
            }*/
        }

        section.property: "type"
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
                        case "0": return qsTr("Albums")
                        case "1": return qsTr("Related Artists")
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
                            }
                        }
                    }
                    MenuItem {
                        text: qsTr("View")
                        onClicked: {
                            switch(type) {
                            case 0:
                                pageStack.push(Qt.resolvedUrl("Album.qml"), {album: album})
                                break;
                            case 1:
                                pageStack.push(Qt.resolvedUrl("Artist.qml"), {currentArtist: artist})
                                break;
                            }
                        }
                    }
                }
            }
            onClicked: app.playTrack(track)
        }

        VerticalScrollDecorator {}

        Label {
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignBottom
            visible: parent.count == 0
            text: qsTr("No albums found")
            color: Theme.secondaryColor
        }

    }

    onCurrentArtistChanged: refresh()

    property var artistAlbums
    property var relatedArtists
    property int pendingRequests

    function loadData() {
        var i;
        if(artistAlbums)
            for(i=0;i<artistAlbums.items.length;i++) {
                searchModel.append({type: 0,
                                    name: artistAlbums.items[i].name,
                                    album: artistAlbums.items[i]})
            }
        if(relatedArtists) {
            var artistIds = [currentArtist.id]
            for(i=0;i<relatedArtists.artists.length;i++) {
                searchModel.append({type: 1,
                                    name: relatedArtists.artists[i].name,
                                    following: false,
                                    artist: relatedArtists.artists[i]})
                artistIds.push(relatedArtists.artists[i].id)
            }
            // request additional Info
            Spotify.isFollowingArtists(artistIds, function(error, data) {
                if(data) {
                    // first one is the currentArtist
                    isFollowed = data[0]
                    data.shift()
                    Util.setFollowedInfo(1, artistIds, data, searchModel)
                }
            })
        }
    }

    function refresh() {
        var i;
        //showBusy = true
        searchModel.clear()        
        artistAlbums = undefined
        relatedArtists = undefined
        pendingRequests = 2

        Spotify.getArtistAlbums(currentArtist.id,
                                {offset: offset, limit: limit},
                                function(error, data) {
            if(data) {
                console.log("number of ArtistAlbums: " + data.items.length)
                artistAlbums = data
                offset = data.offset
            } else {
                console.log("No Data for getArtistAlbums")
            }
            if(--pendingRequests == 0) // load when all requests are done
                loadData()
        })

        Spotify.getArtistRelatedArtists(currentArtist.id,
                                        {offset: offset, limit: limit},
                                        function(error, data) {
            if(data) {
                console.log("number of ArtistRelatedArtists: " + data.artists.length)
                relatedArtists = data
            } else {
                console.log("No Data for getArtistRelatedArtists")
            }
            if(--pendingRequests == 0) // load when all requests are done
                loadData()
        })
    }
}
