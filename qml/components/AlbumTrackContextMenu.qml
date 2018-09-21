/**
 * Hutspot. 
 * Copyright (C) 2018 Willem-Jan de Hoog
 * Copyright (C) 2018 Maciej Janiszewski
 *
 * License: MIT
 */

import QtQuick 2.2
import Sailfish.Silica 1.0

import "../Util.js" as Util

ContextMenu {
    property var context;
    enabled: Util.isTrackPlayable(track)
    visible: enabled

    MenuItem {
        text: qsTr("Play")
        onClicked: app.controller.playTrackInContext(track, context)
    }

    MenuItem {
        text: qsTr("Add to Queue")
        onClicked: app.queue.addToQueue(track)
    }

    MenuItem {
        text: qsTr("Replace Queue")
        onClicked: app.queue.replaceQueueWith([track.uri])
    }

    MenuItem {
        text: qsTr("Add to Playlist")
        onClicked: app.addToPlaylist(track)
    }

}
