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
import "components"

ApplicationWindow {
    id: app

    property string connectionText: qsTr("connecting")
    property alias searchLimit: searchLimit
    property alias selected_search_targets: selected_search_targets
    property string playbackStateDeviceId: ""
    property string playbackStateDeviceName: ""

    initialPage: firstPage
    allowedOrientations: defaultAllowedOrientations

    cover: CoverPage {
        id: cover
    }

    FirstPage {
        id: firstPage
    }

    Messagebox {
        id: msgBox
    }

    function showErrorMessage(error, text) {
        var msg
        if(error) {
            if(error.status && error.message)
                msg = text + ":" + error.status + ":" + error.message
            else
                msg = error + ":" + text
        } else
            msg = text
        msgBox.showMessage(msg, 3000)
    }

    function setDevice(id, name) {

        deviceId.value = id
        deviceName.value = name

        Spotify.transferMyPlayback([id],{}, function(error, data) {
            if(data) {
                playbackStateDeviceId = id
                playbackStateDeviceName = name
            } else
                showErrorMessage(error, qsTr("Transfer Failed"))
        })
    }

    function playTrack(track) {
        Spotify.play({'device_id': deviceId.value, 'uris': [track.uri]}, function(error, data) {
            if(data) {
                playing = true
                refreshPlayingInfo()
            } else
                showErrorMessage(error, qsTr("Play Failed"))
        })
    }

    function playContext(context) {
        Spotify.play({'device_id': deviceId.value, 'context_uri': context.uri}, function(error, data) {
            if(data) {
              playing = true
              refreshPlayingInfo()
            } else
                showErrorMessage(error, qsTr("Play Failed"))
        })
    }

    property bool playing
    function pause() {
        if(playing) {
            // pause
            Spotify.pause({}, function(error, data) {
                playing = false
            })
        } else {
            // resume
            Spotify.play({}, function(error, data) {
                playing = true
            })
        }
    }

    function next() {
        Spotify.skipToNext({}, function(error, data) {
            refreshPlayingInfo()
        })
    }

    function previous() {
        Spotify.skipToPrevious({}, function(error, data) {
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
        Spotify.getMyCurrentPlayingTrack({}, function(error, data) {
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
        serviceBrowser.browse("_spotify-connect._tcp")
    }

    Connections {
        target: spotify

        onExtraTokensReady: { // (const QVariantMap &extraTokens);
            // extraTokens
            //   scope: ""
            //   token_type: "Bearer"
        }

        onLinkingFailed: {
            console.log("Connections.onLinkingFailed")
            app.connectionText = qsTr("Disconnected")
        }

        onLinkingSucceeded: {
            console.log("Connections.onLinkingSucceeded")
            //console.log("username: " + spotify.getUserName())
            //console.log("token   : " + spotify.getToken())
            Spotify._accessToken = spotify.getToken()
            Spotify._username = spotify.getUserName()
            console.log("expires: " + spotify.getExpires())
            app.connectionText = qsTr("Connected")
            spotify.refreshToken()
            loadUser()
            firstPage.loginChanged()
        }

    }

    property var foundDevices: []
    signal devicesChanged()
    onDevicesChanged: {
        firstPage.foundDevicesChanged()
    }

    Connections {
        target: serviceBrowser

        onServiceEntryAdded: {
            var serviceJSON = serviceBrowser.getJSON(service)
            console.log("onServiceEntryAdded: " + serviceJSON)
            try {
              var data = JSON.parse(serviceJSON)
              if(data.protocol === "IPv4")
                  Util.deviceInfoRequest(data.ip+":"+data.port, function(error, data) {
                      if(data) {
                          //console.log(JSON.stringify(data,null,2))
                          // replace or add
                          var replaced = 0
                          for(var i=0;i<foundDevices.length;i++) {
                            if(foundDevices[i].remoteName === data.remoteName) {
                              foundDevices[i] = data
                                replaced = 1
                            }
                          }
                          if(!replaced)
                              foundDevices.push(data)
                          devicesChanged()
                      }
                  })
            } catch (e) {
              console.error(e)
            }
        }

        onServiceEntryRemoved: {
            console.log("onServiceEntryRemoved: " + service)
            // todo remove from foundDevices
            for(var i=0;i<foundDevices.length;i++) {
              if(foundDevices[i].remoteName === data.remoteName) {
                  foundDevices.splice(i, 1)
                  devicesChanged()
                  break
              }
            }
        }
    }

    property string id: ""
    property string uri: ""
    property string display_name: ""
    property string product: ""
    property string followers: ""

    function loadUser() {
        Spotify.getMe({}, function(error, data) {
            if(data) {
                try {
                    id = data.id
                    uri = data.uri
                    display_name = data.display_name
                    product = data.product
                    followers = data.followers.total
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getMe")
            }
        })
        Spotify.getMyCurrentPlaybackState({}, function(error, data) {
            if(data) {
                try {
                    if(data.device) {
                        playbackStateDeviceId = data.device.id
                        playbackStateDeviceName = data.device.name
                        console.log("Current device: " + data.device.name)
                    }
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getMyCurrentPlaybackState")
            }
        })
    }

    function addToPlaylist(track) {

        var ms = pageStack.push(Qt.resolvedUrl("components/PlaylistPicker.qml"),
                                { label: qsTr("Select a Playlist") } );
        ms.accepted.connect(function() {
            if(ms.selectedItem && ms.selectedItem.playlist) {
                Spotify.addTracksToPlaylist(ms.selectedItem.playlist.owner.id,
                                            ms.selectedItem.playlist.id,
                                            [track.uri], {}, function(error, data) {
                    if(data)
                        console.log("addToPlaylist: added \"")
                    else
                        console.log("addToPlaylist: failed to add \"")
                    console.log(track.name + "\" to \"" + ms.selectedItem.playlist.name + "\"")
                })
            }
        })
    }

    function removeFromPlaylist(playlist, track, callback) {
        Spotify.removeTracksFromPlaylist(id, playlist.id, [track.uri], {}, function(error, data) {
            callback(error, data)
        })
    }

    function unfollowPlaylist(playlist, callback) {
        Spotify.unfollowPlaylist(id, playlist.id, {}, function(error, data) {
            callback(error, data)
        })
    }

    function createPlaylist(callback) {
        var ms = pageStack.push(Qt.resolvedUrl("components/CreatePlaylist.qml"),
                                {} );
        ms.accepted.connect(function() {
            if(ms.name && ms.name.length > 0) {
                var options = {name: ms.name,
                               'public': ms.publicPL,
                               collaborative: ms.collaborativePL}
                if(ms.description && ms.description.length > 0)
                    options.descriptions = ms.description
                Spotify.createPlaylist(id, options, function(error, data) {
                    callback(error, data)
                })
            }
        })
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
        return "/usr/share/icons/hicolor/" + iconSize + "x" + iconSize + "/apps/playspot.png"
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

    ConfigurationValue {
            id: selected_search_targets
            key: "/playspot/selected_search_targets"
            defaultValue: 0xFFF
    }

}

