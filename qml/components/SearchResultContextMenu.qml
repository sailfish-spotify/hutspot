/**
 * Hutspot. Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.2
import Sailfish.Silica 1.0

ContextMenu {

    property int contextType: -1

    MenuItem {
        text: qsTr("Play")
        onClicked: {
            switch(type) {
            case 0:
                app.playContext(album)
                break;
            case 1:
                app.playContext(artist)
                break;
            case 2:
                app.playContext(playlist)
                break;
            case 3:
                app.playTrack(track)
                break;
            }
        }
    }
    MenuItem {
        text: qsTr("View")
        enabled: type === 0 || type === 1 || type === 2
        visible: enabled
        onClicked: {
            switch(type) {
            case 0:
                pageStack.push(Qt.resolvedUrl("../pages/Album.qml"), {album: album})
                break;
            case 1:
                pageStack.push(Qt.resolvedUrl("../pages/Artist.qml"), {currentArtist: artist})
                break;
            case 2:
                pageStack.push(Qt.resolvedUrl("../pages/Playlist.qml"), {playlist: playlist})
                break;
            }
        }
    }
    MenuItem {
        enabled: type === 3
        visible: enabled
        text: qsTr("View Album")
        onClicked: pageStack.push(Qt.resolvedUrl("../pages/Album.qml"), {album: track.album})
    }
    MenuItem {
        enabled: type === 3 && contextType !== 2
        visible: enabled
        text: qsTr("Add to Playlist")
        onClicked: app.addToPlaylist(track)
    }
}
