/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 * Copyright (C) 2018 Maciej Janiszewski
 *
 * License: MIT
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    id: cover
    property string defaultImageSource: "image://theme/icon-m-music"

    Column {
        width: parent.width

        Rectangle {
            width: parent.width
            height: Theme.paddingMedium
            opacity: 0
        }

        Item {
            width: parent.width - (Theme.paddingMedium * 2)
            height: width
            x: Theme.paddingMedium

            Image {
                id: image
                width: source === defaultImageSource ? sourceSize.width : parent.width
                height: width
                fillMode: Image.PreserveAspectFit
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                source: app.controller.getCoverArt(defaultImageSource, app.controller.playbackState)  // TODO: this hack is just bad
            }
        }

        Rectangle {
            width: parent.width
            height: Theme.paddingLarge
            opacity: 0
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.paddingMedium
            Label {
                id: spotifyLabel
                text: qsTr("Hutspot")
            }
        }

        CoverActionList {
            id: coverAction

            CoverAction {
                iconSource: "image://theme/icon-cover-previous"
                onTriggered: app.controller.previous(function(error, data){})
            }

            CoverAction {
                iconSource: app.controller.playbackState.is_playing
                            ? "image://theme/icon-cover-pause"
                            : "image://theme/icon-cover-play"
                onTriggered: app.controller.playPause(function(error, data){})
            }

            CoverAction {
                iconSource: "image://theme/icon-cover-next"
                onTriggered: app.controller.next(function(error, data){})
            }

        }
    }
}

