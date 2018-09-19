/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

import "../Util.js" as Util

Item {

    property var isFavorite
    property var dataModel
    signal toggleFavorite()

    width: parent.width
    height: Math.max(labelss.height, savedImage.height)

    opacity: Util.isTrackPlayable(dataModel.track) ? 1.0 : 0.4

    Image {
        id: savedImage
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        source: {
            if(isFavorite)
                return currentTrackId === dataModel.track.id
                        ? "image://theme/icon-m-favorite-selected?" + Theme.highlightColor
                        : "image://theme/icon-m-favorite-selected"
            else
                return currentTrackId === dataModel.track.id
                          ? "image://theme/icon-m-favorite?" + Theme.highlightColor
                          : "image://theme/icon-m-favorite"
        }
        // these are used in the Spotify application
        //source: isFavorite ? "image://theme/icon-m-certificates" : "image://theme/icon-m-add"
        MouseArea {
             anchors.fill: parent
             onClicked: toggleFavorite()
        }
    }

    Item {
        id: labelss
        anchors.left: savedImage.right
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        Label {
            id: label
            anchors.left: parent.left
            anchors.right: duration.left
            anchors.rightMargin: Theme.paddingLarge
            anchors.verticalCenter: parent.verticalCenter
            color: currentTrackId === dataModel.track.id ? Theme.highlightColor : Theme.primaryColor
            textFormat: Text.StyledText
            truncationMode: TruncationMode.Fade
            text: dataModel.name ? dataModel.name : qsTr("No Name")
        }

        Label {
            id: duration
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: currentTrackId === dataModel.track.id ? Theme.highlightColor : Theme.primaryColor
            font.pixelSize: Theme.fontSizeSmall
            text: Util.getDurationString(dataModel.track.duration_ms)
            enabled: text.length > 0
            visible: enabled
        }
    }

}
