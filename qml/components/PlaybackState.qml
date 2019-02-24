/**
 * Hutspot. 
 * Copyright (C) 2018 Maciej Janiszewski
 *
 * License: MIT
 */

import QtQuick 2.0

import org.nemomobile.mpris 1.0
import "../Util.js" as Util

Item {   
    MprisPlayer {
        id: mprisPlayer
        serviceName: "hutspot"
        playbackStatus: is_playing ? Mpris.Playing : Mpris.Paused

        identity: qsTr("Simple Spotify Controller")

        canControl: true

        canPause: true
        canPlay: true
        canGoNext: true
        canGoPrevious: true

        canSeek: false

        onPauseRequested: app.controller.playPause()
        onPlayRequested: app.controller.play()
        onPlayPauseRequested: app.controller.playPause()
        onNextRequested: app.controller.next()
        onPreviousRequested: app.controller.previous()
    }
    onItemChanged: {
        artistsString = Util.createItemsString(item.artists, qsTr("no artist known"))
        if (item.album.images && item.album.images.length > 0)
            coverArtUrl = item.album.images[0].url;
        else coverArtUrl = "";

        var metadata = {}
        metadata[Mpris.metadataToString(Mpris.Title)] = item.name
        metadata[Mpris.metadataToString(Mpris.Artist)] = artistsString
        mprisPlayer.metadata = metadata
    }
    property string artistsString: ""
    property string coverArtUrl: ""

    property var device: {
        "id": "-1",
        "is_active": true,
        "is_private_session": false,
        "is_restricted": false,
        "type": "Nothing",
        "name": "No device",
        "volume_percent": 100
    }
    property string repeat_state: "off"
    property bool shuffle_state: false
    property var context: undefined
    property var contextDetails: undefined
    property int timestamp: 0
    property int progress_ms: 0
    property bool is_playing: false
    property var item: {
        "id": -1,
        "duration_ms": 0,
        "artists": [],
        "name": "",
        "album": {"name": "", "id": -1, "images": []}
    }

    function nextRepeatState() {
        if (repeat_state === "off")
            return "context"
        else if (repeat_state === "context")
            return "track";
        return "off";
    }

    function importState(state) {
        device = state.device;
        repeat_state = state.repeat_state;
        shuffle_state = state.shuffle_state;
        context = state.context;
        timestamp = state.timestamp;
        progress_ms = state.progress_ms;
        is_playing = state.is_playing;
        item = state.item;
    }
}
