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
    property bool isBusy: waitForInSpotifyList.running

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
                text: qsTr("Register Librespot Credentials")
                onClicked: librespot.registerCredentials()
            }
            MenuItem {
                text: qsTr("Reload Devices")
                onClicked: app.controller.reloadDevices()
            }
        }

        PushUpMenu {
            MenuItem {
                text: qsTr("Login")
                onClicked: spotify.doO2Auth(Spotify._scope, app.auth_using_browser.value)
            }
            MenuItem {
                text: qsTr("Refresh Token")
                onClicked: spotify.refreshToken()
            }
        }

        header: PageHeader {
            id: pHeader
            width: parent.width
            title: qsTr("Devices")
            BusyIndicator {
                parent: pHeader.extraContent
                running: isBusy
                visible: running
            }
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
                                app.setDevice(model.deviceId, model.name, function(error, data){
                                    if(!error)
                                        refreshDevices()
                                })
                        }
                    }
                    MenuItem {
                        enabled: sp === 0 && app.librespot.hasLibreSpotCredentials()
                        text: qsTr("Connect using Authorization Blob")
                        onClicked: {                            
                            var name = app.foundDevices[deviceIndex].remoteName
                            _toBeAddedName = name
                            app.librespot.addUser(app.foundDevices[deviceIndex], function(error, data) {
                                if(data) {
                                    waitForInSpotifyList.count = 5
                                } else {
                                    app.showErrorMessage(error, qsTr("Failed to connect to " + name))
                                }
                            })
                        }
                    }
                }
            }

        }

        ViewPlaceholder {
            enabled: listView.count === 0
            text: qsTr("Nothing Devices found")
        }

        VerticalScrollDecorator {}
    }

    function isDeviceInList(deviceName) {
        var i
        for(i=0;i<app.controller.devices.count;i++) {
            var device = app.controller.devices.get(i)
            if(device.name === deviceName)
                return true
        }
        return false
    }

    property string _toBeAddedName: ""
    Timer {
        id: waitForInSpotifyList
        interval: 2000
        running: count > 0
        repeat: true
        property int count: -1
        onTriggered: {
            if(isDeviceInList(_toBeAddedName))
                count = 0
            else
                app.controller.reloadDevices()
            count--
        }
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

    Timer { // reload devices list so we see new ones
        id: reloadDevicesTimer
        running: !waitForInSpotifyList.running
        repeat: true
        interval: 3000
        onTriggered: app.controller.checkForNewDevices()
    }

    function refreshDevices() {
        var i
        var j

        itemsModel.clear()

        var devArr = []
        for(i=0;i<app.controller.devices.count;i++)
            devArr[i] = {device: app.controller.devices.get(i), deviceIndex: i}
        devArr.sort(function(a,b) {return a.device.name.localeCompare(b.device.name)})
        for(i=0;i<devArr.length;i++) {
            var item = devArr[i]
            itemsModel.append({deviceId: item.device.id,
                               name: item.device.name,
                               deviceIndex: item.deviceIndex,
                               is_active: item.device.is_active,
                               sp: 1,
                               discovery: 0})
        }

        devArr.length = 0
        for(i=0;i<app.foundDevices.length;i++)
            devArr[i] = {device: app.foundDevices[i], deviceIndex: i}
        devArr.sort(function(a,b) {return a.device.remoteName.localeCompare(b.device.remoteName)})
        for(i=0;i<devArr.length;i++) {
            var found = 0
            for(j=0;j<itemsModel.count;j++) {
                if(itemsModel.get(j).name === devArr[i].device.remoteName) {
                    itemsModel.get(j).discovery = 1
                    found = 1
                    break
                }
            }
            if(!found) {
                itemsModel.append({deviceId: devArr[i].device.deviceID,
                                   name: devArr[i].device.remoteName,
                                   deviceIndex: devArr[i].deviceIndex,
                                   is_active: devArr[i].device.activeUser.length > 0,
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

    Component.onCompleted: {
        if(app.hasValidToken)
            refreshDevices()
    }

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

