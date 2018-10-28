/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 * Copyright (C) 2018 Maciej Janiszewski
 *
 * License: MIT
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"
import "../Spotify.js" as Spotify
import "../Util.js" as Util

Page {
    id: devicesPage

    allowedOrientations: Orientation.All

    SilicaListView {
        id: listView

        width: parent.width
        anchors {
            top: parent.top
            bottom: controlPanel.top
        }

        clip: app.dockedPanel.expanded

        //model: app.controller.devices
        model: itemsModel

        PullDownMenu {
            MenuItem {
                text: qsTr("Reload Devices")
                onClicked: app.controller.reloadDevices()
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
            opacity: sp == 1 ? 1.0 : 0.4

            Column {
                id: column
                width: parent.width
                Label {
                    id: nameLabel
                    //color: is_active ? Theme.highlightColor : Theme.primaryColor
                    color: Theme.primaryColor
                    textFormat: Text.StyledText
                    truncationMode: TruncationMode.Fade
                    //width: parent.width - countLabel.width
                    text: getNameLabelText(sp, deviceIndex, name)
                }
                Label {
                    id: meta1Label
                    width: parent.width
                    //color: is_active ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    truncationMode: TruncationMode.Fade
                    text: getMetaLabelText(sp, deviceIndex)
                }
            }

            menu: contextMenu

            Component {
                id: contextMenu
                ContextMenu {
                    MenuItem {
                        enabled: sp == 1
                        text: qsTr("Set as Current")
                        onClicked: {
                            if(spotify)
                                app.setDevice(model.deviceId, model.name)
                        }
                    }
                    MenuItem {
                        enabled: sp === 0 && app.librespot.hasLibreSpotCredentials()
                        text: qsTr("Connect using Blob")
                        onClicked: {
                            app.librespot.addUser(app.foundDevices[deviceIndex])
                        }
                    }
                }
            }

        }

        ViewPlaceholder {
            enabled: listView.count === 0
            text: qsTr("Nothing Devices found")
            hintText: qsTr("Pull down to reload")
        }

        VerticalScrollDecorator {}
    }

    function getNameLabelText(sp, deviceIndex, name) {
        var str = name ? name : qsTr("Unknown Name")
        if(sp) {
            str += ", " + app.controller.devices.get(deviceIndex).type
            //str += " [Spotify]"
        } else { //if(discovery) {
            str += ", " + app.foundDevices[deviceIndex].deviceType
            //str += " [Discovery]"
        }
        return str
    }

    function getMetaLabelText(sp, deviceIndex) {
        var str = ""
        if(sp) {
            var device = app.controller.devices.get(deviceIndex)
            str = device.volume_percent + "%"
            str += ", "
            str += device.is_active
                    ? qsTr("active") : qsTr("inactive")
            str += ", "
            str += device.is_restricted
                    ? qsTr("restricted") : qsTr("unrestricted")
            return str
        } else {
            str = app.foundDevices[deviceIndex].activeUser.length > 0
                    ? qsTr("inactive") : qsTr("inactive")
        }
        return str
    }

    Connections {
        target: app.controller
        onDevicesReloaded: refreshDevices()
    }

    Connections {
        target: app
        onDevicesChanged: refreshDevices()
        onHasValidTokenChanged: refreshDevices()
    }

    ListModel {
        id: itemsModel
    }

    function refreshDevices() {
        var i
        var j

        itemsModel.clear()

        for(i=0;i<app.controller.devices.count;i++) {
            var device = app.controller.devices.get(i)
            itemsModel.append({deviceId: device.id,
                               name: device.name,
                               deviceIndex: i,
                               is_active: device.is_active,
                               sp: 1,
                               discovery: 0})
        }

        for(i=0;i<app.foundDevices.length;i++) {
            var found = 0
            for(j=0;j<itemsModel.count;j++) {
                if(itemsModel.get(j).name === app.foundDevices[i].remoteName) {
                    itemsModel.get(j).discovery = 1
                    found = 1
                    break
                }
            }
            if(!found) {
                itemsModel.append({deviceId: app.foundDevices[i].deviceID,
                                   name: app.foundDevices[i].remoteName,
                                   deviceIndex: i,
                                   is_active: app.foundDevices[i].activeUser.length > 0,
                                   sp: 0,
                                   discovery: 1})
            }
        }

   }

    PanelBackground {
        id: controlPanel
        x: 0
        y: parent.height - height - app.dockedPanel.visibleSize
        width: parent.width
        height: volumeSlider.height

        Image {
            id: speakerIcon
            x: Theme.horizontalPageMargin
            source: volumeSlider.value <= 0 ? "image://theme/icon-m-speaker-mute" : "image://theme/icon-m-speaker"
            anchors.verticalCenter: parent.verticalCenter
            sourceSize {
                width: Theme.iconSizeSmall
                height: Theme.iconSizeSmall
            }
            height: Theme.iconSizeSmall
        }

        Slider {
            id: volumeSlider
            anchors {
                left: speakerIcon.right
                right: parent.right
            }
            minimumValue: 0
            maximumValue: 100
            handleVisible: false
            value: app.controller.playbackState.device.volume_percent
            onReleased: {
                Spotify.setVolume(Math.round(value), function(error, data) {
                    if(!error)
                        app.controller.refreshPlaybackState();
                })
            }
        }
    }

    /*Connections {
        target: app
        onHasValidTokenChanged: app.controller.reloadDevices()
    }

    Component.onCompleted: app.controller.reloadDevices()*/
    Component.onCompleted: refreshDevices()

    // The shared DockedPanel needs mouse events
    // and some ListView events
    propagateComposedEvents: true
    onStatusChanged: {
        if(status === PageStatus.Activating)
            app.dockedPanel.registerListView(listView)
        else if(status === PageStatus.Deactivating)
            app.dockedPanel.unregisterListView(listView)
    }

}

