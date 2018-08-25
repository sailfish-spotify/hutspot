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

    property int currentIndex: -1

    property int cursor_limit: app.searchLimit.value
    property int cursor_offset: 0
    property int cursor_total: 0
    property bool canLoadNext: (cursor_offset + cursor_limit) <= cursor_total
    property bool canLoadPrevious: cursor_offset >= cursor_limit

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
            spacing: Theme.paddingMedium

            PageHeader {
                id: pHeader
                width: parent.width
                title: qsTr("Artist")
                MenuButton {}
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
                       onClicked: app.playContext(currentArtist)
                }
            }

            MetaInfoPanel {
                firstLabelText: currentArtist ? currentArtist.name : qsTr("No Name")
                secondLabelText: {
                    var s = ""
                    if(currentArtist.genres && currentArtist.genres.length > 0)
                        s += Util.createItemsString(currentArtist.genres, "")
                    return s
                }
                thirdLabelText: currentArtist.followers && currentArtist.followers.total > 0
                                ? Util.abbreviateNumber(currentArtist.followers.total) + " " + qsTr("followers")
                                : ""

                isFavorite: isFollowed
                onToggleFavorite: app.toggleFollowArtist(currentArtist, isFollowed, function(followed) {
                    isFollowed = followed
                })
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
                dataModel: model
            }

            menu: SearchResultContextMenu {}

            onClicked: {
                switch(type) {
                case 0:
                    app.pushPage(Util.HutspotPage.Album, {album: album})
                    break;
                case 1:
                    app.pushPage(Util.HutspotPage.Artist, {currentArtist: artist})
                    break;
                }
            }
        }

        VerticalScrollDecorator {}

        ViewPlaceholder {
            enabled: parent.count == 0
            text: qsTr("No Artists found")
            hintText: qsTr("Pull down to reload")
        }

    }

    NavigationPanel {
        id: navPanel
    }

    onCurrentArtistChanged: refresh()

    property var artistAlbums
    property var relatedArtists
    property int pendingRequests
    property var artistAlbumsCursor
    property var relatedArtistsCursor

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

        var cinfo = Util.getCursorsInfo([artistAlbumsCursor, relatedArtistsCursor])
        cursor_offset = cinfo.offset
        cursor_total = cinfo.maxTotal
    }

    function refresh() {
        var i;
        //showBusy = true
        searchModel.clear()        
        artistAlbums = undefined
        relatedArtists = undefined
        pendingRequests = 2

        Spotify.getArtistAlbums(currentArtist.id,
                                {offset: cursor_offset, limit: cursor_limit},
                                function(error, data) {
            if(data) {
                console.log("number of ArtistAlbums: " + data.items.length)
                artistAlbums = data
                artistAlbumsCursor = Util.loadCursor(data)
            } else {
                console.log("No Data for getArtistAlbums")
            }
            if(--pendingRequests == 0) // load when all requests are done
                loadData()
        })

        Spotify.getArtistRelatedArtists(currentArtist.id,
                                        {offset: cursor_offset, limit: cursor_limit},
                                        function(error, data) {
            if(data) {
                console.log("number of ArtistRelatedArtists: " + data.artists.length)
                relatedArtists = data
                relatedArtistsCursor = Util.loadCursor(data)
            } else {
                console.log("No Data for getArtistRelatedArtists")
            }
            if(--pendingRequests == 0) // load when all requests are done
                loadData()
        })
    }

}
