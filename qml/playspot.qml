/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0
import org.nemomobile.mpris 1.0

import "Spotify.js" as Spotify
import "Util.js" as Util
import "cover"
import "pages"

ApplicationWindow {
    id: app

    property string connectionText: qsTr("connecting")
    property alias searchLimit: searchLimit

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

    onPlayingChanged: {
        var status = playing ?  Mpris.Playing : Mpris.Paused

        // it seems that in order to use the play button on the Lock screen
        // when canPlay is true so should canPause be.
        mprisPlayer.canPlay = status !== Mpris.Playing
        mprisPlayer.canPause = status !== Mpris.Stopped
        mprisPlayer.playbackStatus = status
    }

    function refreshPlayingInfo() {
        Spotify.getMyCurrentPlayingTrack({}, function(data) {
            if(data) {
                //item.track_number item.duration_ms
                var uri = data.item.album.images[0].url
                cover.updateDisplayData(uri, data.item.name)

                var metaData = {}
                metaData['title'] = data.item.name
                if(data.item.artists)
                    metaData['artist'] = Util.createItemsString(data.item.artists, qsTr("no artist known"))
                else
                    metaData['artist'] = ''
                mprisPlayer.metaData = metaData
            }
        })
    }

    Component.onCompleted: {
        spotify.doO2Auth(Spotify._scope)
    }

    property string mprisServiceName: "playspot"

    MprisPlayer {
        id: mprisPlayer
        serviceName: mprisServiceName

        property var metaData

        identity: qsTrId("Simple Spotify Controller")

        canControl: true

        canPause: playing
        canPlay: !playing

        canGoNext: true
        canGoPrevious: true

        canSeek: false

        playbackStatus: Mpris.Stopped

        onPauseRequested: app.pause()

        onPlayRequested: app.pause()

        onPlayPauseRequested: app.pause()

        onNextRequested: app.next()

        onPreviousRequested: app.previous()

        onMetaDataChanged: {
            var metadata = {}

            if (metaData && 'artist' in metaData)
                metadata[Mpris.metadataToString(Mpris.Artist)] = [metaData['artist']] // List of strings
            if (metaData && 'title' in metaData)
                metadata[Mpris.metadataToString(Mpris.Title)] = metaData['title'] // String

            mprisPlayer.metadata = metadata
        }
    }

    function getAppIconSource() {
        return getAppIconSource2(Theme.iconSizeExtraLarge)
    }

    function getAppIconSource2(iconSize) {
        if (iconSize < 108)
            iconSize = 86
        else if (iconSize < 128)
            iconSize = 108
        else if (iconSize < 256)
            iconSize = 128
        else
            iconSize = 256
        return "/usr/share/icons/hicolor/" + iconSize + "x" + iconSize + "/apps/shoutcast-sailfish.png"
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

    ConfigurationValue {
        id: searchLimit
        key: "/playspot/search_limit"
        defaultValue: 20
    }


}

