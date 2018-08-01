/**
 * Hutspot. Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.2
import Sailfish.Silica 1.0

ContextMenu {
    property var context;
    MenuItem {
        text: qsTr("Play")
        onClicked: app.controller.playTrackInContext(track, context)
    }

    MenuItem {
        text: qsTr("Add to Playlist")
        onClicked: app.addToPlaylist(track)
    }

}
