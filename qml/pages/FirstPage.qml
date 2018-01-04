/**
 * Copyright (C) 2017 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

import "../Spotify.js" as Spotify

Page {
    id: page

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    ListModel {
        id: itemsModel
    }

    SilicaListView {
        id: genreView
        model: itemsModel
        anchors.fill: parent
        anchors {
            topMargin: 0
            bottomMargin: 0
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Login")
                onClicked: spotify.doO2Auth(Spotify._scope)
            }
            MenuItem {
                text: qsTr("Reload")
                onClicked: reload()
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
                title: qsTr("Items")
                BusyIndicator {
                    id: busyThingy
                    parent: pHeader.extraContent
                    anchors.left: parent.left
                    //running: showBusy
                }
                anchors.horizontalCenter: parent.horizontalCenter
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
                    text: {
                        switch(section) {
                        case "0": return qsTr("Playlists")
                        case "1": return qsTr("Recently Played Tracks")
                        case "2": return qsTr("Devices")
                        }
                    }
                    font.bold: true
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.highlightColor
                }
            }
        }

        delegate: ListItem {
            id: delegate
            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium

            Item {
                width: parent.width

                Label {
                    id: nameLabel
                    color: Theme.primaryColor
                    textFormat: Text.StyledText
                    truncationMode: TruncationMode.Fade
                    //width: parent.width - countLabel.width
                    text: name ? name : qsTr("No Name")
                }
            }
        }

        Label {
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignBottom
            visible: parent.count == 0
            text: qsTr("No Items")
            color: Theme.secondaryColor
        }

        VerticalScrollDecorator {}
    }

    Connections {
        target: spotify

        onExtraTokensReady: { // (const QVariantMap &extraTokens);
            // extraTokens
            //   scope: ""
            //   token_type: "Bearer"
        }

        onLinkingFailed: {
            console.log("Connections.onLinkingFailed")
        }

        onLinkingSucceeded: {
            console.log("Connections.onLinkingSucceeded")
            console.log("username: " + spotify.getUserName())
            console.log("token   : " + spotify.getToken())
            Spotify._accessToken = spotify.getToken()
            Spotify._username = spotify.getUserName()
        }
    }

    property var myPlayLists: []
    property var myDevices: []
    property var myRecentlyPlayedTracks: []

    function reload() {
        var i
        itemsModel.clear()

        myPlayLists = []
        Spotify.getUserPlaylists({},function(data) {
            if(data) {
                try {
                    myPlayLists = data.items
                    console.log("number of playlists: " + myPlayLists.length)
                    for(i=0;i<myPlayLists.length;i++)
                        itemsModel.append({type: 0, name: myPlayLists[i].name, index: i})
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getUserPlaylists")
            }
        })

        myRecentlyPlayedTracks = []
        Spotify.getMyRecentlyPlayedTracks({},function(data) {
            if(data) {
                try {
                    myRecentlyPlayedTracks = data.items
                    console.log("number of RecentlyPlayedTracks: " + myRecentlyPlayedTracks.length)
                    for(i=0;i<myRecentlyPlayedTracks.length;i++)
                        itemsModel.append({type: 1, name: myRecentlyPlayedTracks[i].track.name, index: i})
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getUserPlaylists")
            }
        })

        myDevices = []
        Spotify.getMyDevices(function(data) {
            if(data) {
                try {
                    myDevices = data.devices
                    console.log("number of devices: " + myDevices.length)
                    for(i=0;i<myDevices.length;i++)
                        itemsModel.append({type: 2, name: myDevices[i].name, index: i})
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getMyDevices")
            }
        })

    }
}

