/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

import "../Spotify.js" as Spotify

Page {
    id: firstPage

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
                text: qsTr("About")
                onClicked: pageStack.push(Qt.resolvedUrl("About.qml"))
            }
            MenuItem {
                text: qsTr("Settings")
                onClicked: pageStack.push(Qt.resolvedUrl("Settings.qml"))
            }
            MenuItem {
                text: qsTr("Devices")
                onClicked: reloadDevices()
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

        PushUpMenu {
            MenuItem {
                text: qsTr("Login")
                onClicked: spotify.doO2Auth(Spotify._scope)
            }
            MenuItem {
                text: qsTr("Refresh Token")
                onClicked: spotify.refreshToken()
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
                //title: qsTr("Items")
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
                              + ": " + app.display_name
                              + ", " + app.product
                        //      + ", " + followers + qsTr("followers")
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
                    width: parent.width
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
                    horizontalAlignment: Text.AlignRight
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
                    color: deviceId === playbackStateDeviceId ? Theme.highlightColor : Theme.primaryColor
                    textFormat: Text.StyledText
                    truncationMode: TruncationMode.Fade
                    //width: parent.width - countLabel.width
                    text: {
                        var str = name ? name : qsTr("No Name")
                        if(sp && avahi)
                            str += " [Spotify, Avahi]"
                        else if(avahi)
                            str += " [Avahi]"
                        else
                            str += " [Spotify]"
                        return str
                    }
                }

            }
            menu: contextMenu

            Component {
                id: contextMenu
                ContextMenu {
                    //enabled: (listView.model.get(index).type === "Item")
//                    MenuItem {
//                        enabled: type === 1 || type === 3
//                        text: qsTr("Play")
//                        onClicked: play(index)
//                    }
                    MenuItem {
                        enabled: type === 2
                        text: qsTr("Set as Current")
                        onClicked: {
                            if(spotify)
                                app.setDevice(deviceId, name)
                        }
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

    signal foundDevicesChanged()
    onFoundDevicesChanged: refreshDevices()

    function refreshDevices() {
        var i
        var j

        itemsModel.clear()

        for(i=0;i<myDevices.length;i++)
            itemsModel.append({type: 2,
                               deviceId: myDevices[i].id,
                               name: myDevices[i].name,
                               index: i,
                               sp: 1,
                               avahi: 0})

        for(i=0;i<app.foundDevices.length;i++) {
            var found = 0
            for(j=0;j<itemsModel.count;j++) {
                if(itemsModel.get(j).name === app.foundDevices[i].remoteName) {
                    itemsModel.get(j).avahi = 1
                    found = 1
                    break
                }
            }
            if(!found) {
                itemsModel.append({type: 2,
                                   deviceId: app.foundDevices[i].deviceID,
                                   name: app.foundDevices[i].remoteName,
                                   index: i,
                                   sp: 0,
                                   avahi: 1})
            }
        }

    }

    property var myDevices: []

    signal loginChanged()
    onLoginChanged: reloadDevices()

    // using spotify webapi
    function reloadDevices() {
        var i
        //itemsModel.clear()

        myDevices = []
        Spotify.getMyDevices(function(error, data) {
            if(data) {
                try {
                    console.log("number of devices: " + myDevices.length)
                    myDevices = data.devices
                    refreshDevices()
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getMyDevices")
            }
        })

    }


}

