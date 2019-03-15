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
    property bool enableQueueItems: true
    property bool fromPlaying: false

    enabled: Util.isTrackPlayable(item)
    visible: enabled

    MenuItem {
        text: qsTr("Play")
        onClicked: app.controller.playTrackInContext(item, context, index)
    }

    MenuItem {
        text: qsTr("View Album")
        visible: enabled
        enabled: fromPlaying && type === Util.SpotifyItemType.Track
        onClicked: app.pushPage(Util.HutspotPage.Album, {album: item.album}, fromPlaying)
    }

    MenuItem {
        text: qsTr("View Artist")
        visible: enabled
        enabled: fromPlaying && type === Util.SpotifyItemType.Track
        onClicked: app.loadArtist(item.artists, fromPlaying)
    }

    MenuItem {
        visible: enableQueueItems
        text: qsTr("Add to Queue")
        onClicked: app.queue.addToQueue(item)
    }

    MenuItem {
        visible: enableQueueItems
        text: qsTr("Replace Queue")
        onClicked: app.queue.replaceQueueWith([item.uri])
    }

    MenuItem {
        text: qsTr("Add to Playlist")
        onClicked: app.addToPlaylist(item)
    }

}
