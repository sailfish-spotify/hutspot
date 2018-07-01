/**
 * Copyright (C) 2018 Willem-Jan de Hoog
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
                text: qsTr("Refresh Token")
                onClicked: spotify.refreshToken()
            }
            MenuItem {
                text: qsTr("Login")
                onClicked: spotify.doO2Auth(Spotify._scope)
            }
            MenuItem {
                text: qsTr("Devices")
                onClicked: reload()
            }
            MenuItem {
                text: qsTr("Search")
                onClicked: pageStack.push(Qt.resolvedUrl("Search.qml"))
            }
            MenuItem {
                text: qsTr("My Stuff")
                onClicked: pageStack.push(Qt.resolvedUrl("MyStuff.qml"))
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
                anchors.horizontalCenter: parent.horizontalCenter
                Row {
                    parent: pHeader.extraContent
                    BusyIndicator {
                        id: busyThingy
                        //anchors.left: parent.left
                        //running: showBusy
                    }

                    Label {
                        id: connected
                        width: parent.width - busyThingy.width - 2 * Theme.paddingMedium
                        //x: busyThingy.x + busyThingy.width + Theme.paddingMedium
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                        textFormat: Text.StyledText
                        truncationMode: TruncationMode.Fade
                        text: app.connectionText
                    }
                }
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
            app.connectionText = qsTr("Disconnected")
        }

        onLinkingSucceeded: {
            console.log("Connections.onLinkingSucceeded")
            //console.log("username: " + spotify.getUserName())
            //console.log("token   : " + spotify.getToken())
            Spotify._accessToken = spotify.getToken()
            Spotify._username = spotify.getUserName()
            app.connectionText = qsTr("Connected")
        }

    }

    property var myDevices: []

    function reload() {
        var i
        itemsModel.clear()

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

    function setDevice(index) {
        app.setDevice(myDevices[index])
    }

    function play(index) {
        app.playTrack(myRecentlyPlayedTracks[index])
    }

    Component.onCompleted: spotify.doO2Auth(Spotify._scope)
}

