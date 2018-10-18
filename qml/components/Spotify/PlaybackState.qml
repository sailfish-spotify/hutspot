/**
 * Hutspot. 
 * Copyright (C) 2018 Maciej Janiszewski
 *
 * License: MIT
 */

import QtQuick 2.0
import "../../Util.js" as Util
import "../../Spotify.js" as Spotify

Item {   

    onItemChanged: {
        artistsString = Util.createItemsString(item.artists, qsTr("no artist known"))
        if (item.album.images.length > 0)
            coverArtUrl = item.album.images[0].url;
        else coverArtUrl = "";
    }

    function getCurrentId() {
        if (contextDetails)
            return contextDetails.id
        return item.id
    }

    function getContextType() {
        if(!item)
            return -1

        if (context)
            switch(context.type) {
            case 'album':
                return Spotify.ItemType.Album
            case 'artist':
                return Spotify.ItemType.Artist
            case 'playlist':
                return Spotify.ItemType.Playlist
            }
        return Spotify.ItemType.Track
    }

    property string artistsString: ""
    property string coverArtUrl: ""
    property string currentSnapshotId: ""

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
        timestamp = state.timestamp;
        progress_ms = state.progress_ms;
        is_playing = state.is_playing;

        // don't overwrite context if ID didn't change
        if (!context || !state.context || context.id !== state.context.id)
            context = state.context

        // don't overwrite item if ID didn't change
        if (!item || !state.item || item.id !== state.item.id)
            item = state.item;
    }
}
