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
        id: listView
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
                        case "3": return qsTr("Tracks")
                        case "4": return qsTr("Albums")
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
            menu: contextMenu

            Component {
                id: contextMenu
                ContextMenu {
                    //enabled: (listView.model.get(index).type === "Item")
                    MenuItem {
                        enabled: type === 1 || type === 3
                        text: qsTr("Play")
                        onClicked: play(index)
                    }
                    MenuItem {
                        enabled: type === 2
                        text: qsTr("Set as Current")
                        onClicked: setDevice(index)
                    }
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
    property var mySavedTracks: []
    property var mySavedAlbums: []

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
        Spotify.getMyRecentlyPlayedTracks({}, function(data) {
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
                console.log("No Data for getMyRecentlyPlayedTracks")
            }
        })

        mySavedTracks = []
        Spotify.getMySavedTracks({}, function(data) {
            if(data) {
                try {
                    mySavedTracks = data.items
                    console.log("number of SavedTracks: " + mySavedTracks.length)
                    for(i=0;i<mySavedTracks.length;i++)
                        itemsModel.append({type: 3, name: mySavedTracks[i].track.name, index: i})
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getMySavedTracks")
            }
        })

        mySavedAlbums = []
        Spotify.getMySavedAlbums({}, function(data) {
            if(data) {
                try {
                    mySavedAlbums = data.items
                    console.log("number of SavedAlbums: " + mySavedAlbums.length)
                    for(i=0;i<mySavedAlbums.length;i++)
                        itemsModel.append({type: 4, name: mySavedAlbums[i].track.name, index: i})
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getMySavedAlbums")
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

    property var device;
    function setDevice(index) {
        device = myDevices[index]
    }

    function play(index) {
        var track = myRecentlyPlayedTracks[index]
        Spotify.play({'device_id': device.id, 'uris': [track.track.uri]}, function(data){

        })
    }
}

