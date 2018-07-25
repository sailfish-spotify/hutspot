/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

import "../Util.js" as Util

Item {
    property var dataModel

    width: parent.width
    height: label.height
    anchors.verticalCenter: parent.verticalCenter

    Label {
        id: label
        anchors.left: parent.left
        anchors.right: duration.left
        anchors.rightMargin: Theme.paddingLarge
        color: currentTrackId === dataModel.track.id ? Theme.highlightColor : Theme.primaryColor
        textFormat: Text.StyledText
        truncationMode: TruncationMode.Fade
        text: dataModel.name ? dataModel.name : qsTr("No Name")
    }

    Label {
        id: duration
        anchors.right: parent.right
        color: currentTrackId === dataModel.track.id ? Theme.highlightColor : Theme.primaryColor
        font.pixelSize: Theme.fontSizeSmall
        text: Util.getDurationString(dataModel.track.duration_ms)
        enabled: text.length > 0
        visible: enabled
    }
}
