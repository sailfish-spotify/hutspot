/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: createPlaylist

    property string titleText: qsTr("Create Playlist")

    property string name: ""
    property bool publicPL: true
    property bool collaborativePL: false
    property string description: ""

    onStatusChanged: {
        if (status === PageStatus.Activating) {
            nameField.text = name
            descriptionField.text = description
        }
    }

    SilicaListView  {
        id: view

        anchors.fill: parent

        Column {
            id: column
            width: parent.width

            DialogHeader {
                acceptText: qsTr("OK")
                cancelText: qsTr("Cancel")
            }

            Text {
                width: parent.width
                text: titleText
                font.bold: true
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.highlightColor
                horizontalAlignment: Text.AlignRight
            }

            TextField {
                id: nameField
                width: parent.width
                placeholderText: qsTr("Name for the new playlist")
                onTextChanged: name = text
            }

            TextSwitch {
                id: publicTS
                width: parent.width
                checked: true
                onCheckedChanged: {
                    publicPL = checked
                    if(checked) // a collaborative playlist cannot be public
                        collaborativeTS.checked = false
                }
                text: qsTr("Public")
            }

            TextSwitch {
                id: collaborativeTS
                width: parent.width
                onCheckedChanged: {
                    collaborativePL = checked
                    if(checked) // a collaborative playlist cannot be public
                        publicTS.checked = false
                }
                text: qsTr("Collaborative")
            }

            TextField {
                id: descriptionField
                width: parent.width
                placeholderText: qsTr("Description (optional)")
                onTextChanged: description = text
            }
        }

        VerticalScrollDecorator { flickable: view }

    }
}

