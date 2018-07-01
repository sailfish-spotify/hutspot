/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0

import "Spotify.js" as Spotify
import "pages"

ApplicationWindow {
    id: app

    initialPage: Component { FirstPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    property var device;
    function setDevice(newDevice) {
        device = newDevice
        deviceId.value = device.id
        deviceName.value = device.name
    }

    function playTrack(track) {
        Spotify.play({'device_id': deviceId.value, 'uris': [track.uri]}, function(data) {
            playing = true
        })
    }

    function playContext(context) {
        Spotify.play({'device_id': deviceId.value, 'context_uri': context.uri}, function(data) {
            playing = true
        })
    }

    property bool playing
    function pause() {
        if(playing) {
            // pause
            Spotify.pause({'device_id': deviceId.value}, function(data) {
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
        Spotify.skipToNext({'device_id': deviceId.value}, function(data) {

        })
    }

    function previous() {
        Spotify.skipToPrevious({'device_id': deviceId.value}, function(data) {

        })
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

