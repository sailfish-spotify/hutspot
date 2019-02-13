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

    property int contextType: -1

    MenuItem {
        text: qsTr("Play")
        onClicked: {
            switch(type) {
            case Util.SpotifyItemType.Album:
            case Util.SpotifyItemType.Artist:
            case Util.SpotifyItemType.Playlist:
                app.controller.playContext(item)
                break;
            case Util.SpotifyItemType.Track:
                app.controller.playTrack(track)
                break;
            }
        }
        enabled: type !== Util.SpotifyItemType.Track || Util.isTrackPlayable(item)
        visible: enabled
    }
    MenuItem {
        text: qsTr("View")
        enabled: type !== Util.SpotifyItemType.Track
        visible: enabled
        onClicked: {
            switch(type) {
            case Util.SpotifyItemType.Album:
                app.pushPage(Util.HutspotPage.Album, {album: item})
                break
            case Util.SpotifyItemType.Artist:
                app.pushPage(Util.HutspotPage.Artist, {currentArtist: item})
                break
            case Util.SpotifyItemType.Playlist:
                app.pushPage(Util.HutspotPage.Playlist, {playlist: item})
                break
            }
        }
    }
    MenuItem {
        enabled: type === Util.SpotifyItemType.Track
        visible: enabled
        text: qsTr("View Album")
        onClicked: app.pushPage(Util.HutspotPage.Album, {album: item.album})
    }
    MenuItem {
        enabled: (type === Util.SpotifyItemType.Track && Util.isTrackPlayable(item))
                 && contextType !== Util.SpotifyItemType.Playlist
        visible: enabled
        text: qsTr("Add to Playlist")
        onClicked: app.addToPlaylist(item)
    }
    MenuItem {
        enabled: type === Util.SpotifyItemType.Playlist
        visible: enabled
        text: qsTr("Use as Seeds for Recommendations")
        onClicked: app.useAsSeeds(item)
    }
}
