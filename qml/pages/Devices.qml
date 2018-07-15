/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"
import "../Spotify.js" as Spotify

Page {
    id: devicesPage

    allowedOrientations: Orientation.All
    //anchors.bottom: navPanel.top
    //clip: navPanel.expanded

    ListModel {
        id: itemsModel
    }

    SilicaListView {
        id: listView
        model: itemsModel
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("Reload Devices")
                onClicked: reloadDevices()
            }
        }

        header: PageHeader {
            id: pHeader
            width: parent.width
            title: qsTr("Devices")
        }

        delegate: ListItem {
            id: delegate
            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium

            Column {
                id: column
                width: parent.width
                Label {
                    id: nameLabel
                    color: deviceId === playbackStateDeviceId ? Theme.highlightColor : Theme.primaryColor
                    textFormat: Text.StyledText
                    truncationMode: TruncationMode.Fade
                    //width: parent.width - countLabel.width
                    text: {
                        var str = name ? name : qsTr("Unknown Name")
                        if(myDevices[index].type)
                            str += ", " + myDevices[index].type
                        /*if(sp && avahi)
                            str += " [Spotify, Avahi]"
                        else if(avahi)
                            str += " [Avahi]"
                        else
                            str += " [Spotify]"*/
                        return str
                    }
                }
                Label {
                    id: meta1Label
                    width: parent.width
                    color: deviceId === playbackStateDeviceId ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    truncationMode: TruncationMode.Fade
                    text: {
                        var str = myDevices[index].volume_percent + "%"
                        str += ", "
                        str += myDevices[index].is_active
                               ? qsTr("active") : qsTr("inactive")
                        str += ", "
                        str += myDevices[index].is_restricted
                               ? qsTr("restricted") : qsTr("unrestricted")
                        return str
                    }
                }
            }

            menu: contextMenu

            Component {
                id: contextMenu
                ContextMenu {
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

    NavigationPanel {
        id: navPanel
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


    Connections {
        target: app
        onLoggedInChanged: {
            if(app.loggedIn)
                reloadDevices()
        }
    }

    Component.onCompleted: {
        if(app.loggedIn)
            reloadDevices()
    }

    property var myDevices: []

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

