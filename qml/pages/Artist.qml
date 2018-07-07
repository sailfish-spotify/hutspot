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

    property int offset: 0
    property int limit: app.searchLimit.value
    property bool canLoadNext: true
    property bool canLoadPrevious: offset >= limit

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
                width: parent.width
                height: width
                fillMode: Image.PreserveAspectFit
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

            Rectangle {
                width: parent.width
                height:Theme.paddingLarge
                opacity: 0
            }
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
        if(relatedArtists)
            for(i=0;i<relatedArtists.artists.length;i++) {
                searchModel.append({type: 1,
                                    name: relatedArtists.artists[i].name,
                                    artist: relatedArtists.artists[i]})
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
