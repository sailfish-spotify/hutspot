/**
 * Hutspot. Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.2
import Sailfish.Silica 1.0

ContextMenu {

    MenuItem {
        text: qsTr("Play")
        onClicked: app.playTrack(track)
    }

    MenuItem {
        text: qsTr("Add to Queue")
        onClicked: app.addToQueue(track)
    }

    MenuItem {
        text: qsTr("Replace Queue")
        onClicked: app.replaceQueueWith([track])
    }

    MenuItem {
        text: qsTr("Add to Playlist")
        onClicked: app.addToPlaylist(track)
    }

}
