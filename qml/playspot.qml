/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0

import "Spotify.js" as Spotify
import "cover"
import "pages"

ApplicationWindow {
    id: app

    property string connectionText: qsTr("connecting")

    initialPage: Component { FirstPage { } }
    allowedOrientations: defaultAllowedOrientations

    cover: CoverPage {
        id: cover
    }

    property var device;
    function setDevice(newDevice) {
        device = newDevice
        deviceId.value = device.id
        deviceName.value = device.name
        Spotify.transferMyPlayback([deviceId.value],{}, function(data) {

        })
    }

    function playTrack(track) {
        Spotify.play({'device_id': deviceId.value, 'uris': [track.uri]}, function(data) {
            playing = true
            refreshPlayingInfo()
        })
    }

    function playContext(context) {
        Spotify.play({'device_id': deviceId.value, 'context_uri': context.uri}, function(data) {
            playing = true
            refreshPlayingInfo()
        })
    }

    property bool playing
    function pause() {
        if(playing) {
            // pause
            Spotify.pause({}, function(data) {
                playing = false
            })
        } else {
            // resume
            Spotify.play({}, function(data) {
                playing = true
            })
        }
    }

    function next() {
        Spotify.skipToNext({}, function(data) {
            refreshPlayingInfo()
        })
    }

    function previous() {
        Spotify.skipToPrevious({}, function(data) {
            refreshPlayingInfo()
        })
    }

    function refreshPlayingInfo() {
        Spotify.getMyCurrentPlayingTrack({}, function(data) {
            if(data) {
                //item.track_number item.duration_ms
                var uri = data.item.album.images[0].url
                cover.updateDisplayData(uri, data.item.name)
            }
        })
    }

    Component.onCompleted: {
        spotify.doO2Auth(Spotify._scope)
    }

    ConfigurationValue {
            id: deviceId
            key: "/playspot/device_id"
            defaultValue: ""
    }

    ConfigurationValue {
            id: deviceName
            key: "/playspot/device_name"
            defaultValue: ""
    }
}

