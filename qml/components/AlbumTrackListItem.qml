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

    property int contextType: -1 // not used but needed for Loader in Playing page

    property var dataModel
    signal toggleFavorite()

    width: parent.width - 2 * Theme.horizontalPageMargin
    x: Theme.horizontalPageMargin
    height: Math.max(labelss.height, savedImage.height)
    anchors.verticalCenter: parent.verticalCenter

    opacity: Util.isTrackPlayable(dataModel.item) ? 1.0 : 0.4

    Image {
        id: savedImage
        x: Theme.horizontalPageMargin
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.iconSizeSmall
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        source: {
            if(isFavorite)
                return currentIndex === dataModel.index
                        ? "image://theme/icon-m-favorite-selected?" + Theme.highlightColor
                        : "image://theme/icon-m-favorite-selected"
            else
                return currentIndex === dataModel.index
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
        anchors.rightMargin: Theme.horizontalPageMargin
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Theme.paddingMedium

        Label {
            id: label
            anchors.left: parent.left
            anchors.right: duration.left
            anchors.rightMargin: Theme.paddingLarge
            anchors.verticalCenter: parent.verticalCenter
            color: currentIndex === dataModel.index ? Theme.highlightColor : Theme.primaryColor
            textFormat: Text.StyledText
            truncationMode: TruncationMode.Fade
            text: dataModel.name ? dataModel.name : qsTr("No Name")
        }

        Label {
            id: duration
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: currentIndex === dataModel.index ? Theme.highlightColor : Theme.primaryColor
            font.pixelSize: Theme.fontSizeSmall
            text: Util.getDurationString(dataModel.item.duration_ms)
            enabled: text.length > 0
            visible: enabled
        }
    }

}
