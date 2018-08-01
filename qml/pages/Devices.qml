/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.0
import Sailfish.Silica 1.0


Page {
    allowedOrientations: Orientation.All

    SilicaListView {
        id: listView
        x: 0
        width: parent.width
        model: app.controller.devices
        anchors {
            top: parent.top
            bottom: controlPanel.top
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Reload Devices")
                onClicked: reloadDevices()
            }
        }

        header: PageHeader {
            title: qsTr("Devices")
        }

        delegate: ListItem {
            id: delegate
            width: parent.width

            Column {
                id: column
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                Label {
                    id: nameLabel
                    color: is_active ? Theme.highlightColor : Theme.primaryColor
                    textFormat: Text.StyledText
                    truncationMode: TruncationMode.Fade
                    text: name
                }
                Label {
                    width: parent.width
                    color: is_active ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    truncationMode: TruncationMode.Fade
                    text: {
                        var str = volume_percent + "%"
                        str += ", "
                        str += is_active
                               ? qsTr("active") : qsTr("inactive")
                        str += ", "
                        str += is_restricted
                               ? qsTr("restricted") : qsTr("unrestricted")
                        return str
                    }
                }
            }
            onClicked: app.setDevice(id, name)
        }

        Label {
            anchors.centerIn: parent
            visible: parent.count == 0
            text: qsTr("No Items")
            color: Theme.secondaryColor
        }

        VerticalScrollDecorator {}
    }
    PanelBackground {
        id: controlPanel
        anchors.bottom: parent.bottom
        x: 0
        width: parent.width
        height: volumeSlider.height

        Image {
            id: speakerIcon
            x: Theme.horizontalPageMargin
            source: "image://theme/icon-m-speaker"
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
            value: app.controller.playbackState.device
                   ? app.controller.playbackState.device.volume_percent : 0
            onReleased: app.controller.setVolume(value)
        }
    } // Control Panel

    Component.onCompleted: app.controller.reloadDevices()
    Component.onDestruction: app.controller.devicesPageOpen = false
}

