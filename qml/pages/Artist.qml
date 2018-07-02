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

    allowedOrientations: Orientation.All

    ListModel {
        id: searchModel
    }

    SilicaListView {
        id: listView
        model: searchModel
        anchors.fill: parent
        anchors.topMargin: 0

        PullDownMenu {
            MenuItem {
                text: qsTr("Reload")
                onClicked: refresh()
            }
        }

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

    function refresh() {
        var i;
        //showBusy = true
        searchModel.clear()        

        Spotify.getArtistAlbums(currentArtist.id, {}, function(data) {
            if(data) {
                try {
                    console.log("number of ArtistAlbums: " + data.items.length)
                    for(i=0;i<data.items.length;i++) {
                        searchModel.append({type: 0,
                                            name: data.items[i].name,
                                            album: data.items[i]})
                    }
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getArtistAlbums")
            }
        })

        Spotify.getArtistRelatedArtists(currentArtist.id, {}, function(data) {
            if(data) {
                try {
                    var i;
                    console.log("number of ArtistRelatedArtists: " + data.artists.length)
                    for(i=0;i<data.artists.length;i++) {
                        searchModel.append({type: 1,
                                            name: data.artists[i].name,
                                            artist: data.artists[i]})
                    }
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getArtistRelatedArtists")
            }
        })
    }
}
