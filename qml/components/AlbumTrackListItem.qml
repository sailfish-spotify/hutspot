/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

import "../Util.js" as Util

Item {
    width: parent.width
    height: label.height
    anchors.verticalCenter: parent.verticalCenter

    Label {
        id: label
        anchors.left: parent.left
        anchors.right: duration.left
        anchors.rightMargin: Theme.paddingLarge
        color: currentTrackId === track.id ? Theme.highlightColor : Theme.primaryColor
        textFormat: Text.StyledText
        truncationMode: TruncationMode.Fade
        text: name ? name : qsTr("No Name")
    }

    Label {
        id: duration
        anchors.right: parent.right
        color: currentTrackId === track.id ? Theme.highlightColor : Theme.primaryColor
        font.pixelSize: Theme.fontSizeSmall
        text: Util.getDurationString(track.duration_ms)
        enabled: text.length > 0
        visible: enabled
    }
}
