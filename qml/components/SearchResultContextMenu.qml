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
                app.controller.playContext(album)
                break;
            case Util.SpotifyItemType.Artist:
                app.controller.playContext(artist)
                break;
            case Util.SpotifyItemType.Playlist:
                app.controller.playContext(playlist)
                break;
            case Util.SpotifyItemType.Track:
                app.controller.playTrack(track)
                break;
            }
        }
        enabled: type !== Util.SpotifyItemType.Track || Util.isTrackPlayable(track)
        visible: enabled
    }
    MenuItem {
        text: qsTr("View")
        enabled: type !== Util.SpotifyItemType.Track
        visible: enabled
        onClicked: {
            switch(type) {
            case Util.SpotifyItemType.Album:
                app.pushPage(Util.HutspotPage.Album, {album: album})
                break
            case Util.SpotifyItemType.Artist:
                app.pushPage(Util.HutspotPage.Artist, {currentArtist: artist})
                break
            case Util.SpotifyItemType.Playlist:
                app.pushPage(Util.HutspotPage.Playlist, {playlist: playlist})
                break
            }
        }
    }
    MenuItem {
        enabled: type === Util.SpotifyItemType.Track
        visible: enabled
        text: qsTr("View Album")
        onClicked: app.pushPage(Util.HutspotPage.Album, {album: track.album})
    }
    MenuItem {
        enabled: (type === Util.SpotifyItemType.Track && Util.isTrackPlayable(track))
                 && contextType !== Util.SpotifyItemType.Playlist
        visible: enabled
        text: qsTr("Add to Playlist")
        onClicked: app.addToPlaylist(track)
    }
    MenuItem {
        enabled: type === Util.SpotifyItemType.Playlist
        visible: enabled
        text: qsTr("Use as Seeds for Recommendations")
        onClicked: app.useAsSeeds(playlist)
    }
}
