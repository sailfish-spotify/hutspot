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
    property alias auth_using_browser: auth_using_browser
    property string playbackStateDeviceId: ""
    property string playbackStateDeviceName: ""
    property alias mprisPlayer: mprisPlayer

    allowedOrientations: defaultAllowedOrientations

    cover: CoverPage {
        id: cover
    }

    Messagebox {
        id: msgBox
    }

    function showPage(page) {
        switch(page) {
        case 'PlayingPage':
            if(pageStack.currentPage.objectName !== "PlayingPage")
                pageStack.push(Qt.resolvedUrl("pages/Playing.qml"))
            break;
        case 'NewReleasePage':
            pageStack.clear()
            pageStack.push(Qt.resolvedUrl("pages/NewRelease.qml"))
            break;
        case 'MyStuffPage':
            pageStack.clear()
            pageStack.push(Qt.resolvedUrl("pages/MyStuff.qml"))
            break;
        case 'TopStuffPage':
            pageStack.clear()
            pageStack.push(Qt.resolvedUrl("pages/TopStuff.qml"))
            break;
        case 'SearchPage':
            pageStack.clear()
            pageStack.push(Qt.resolvedUrl("pages/Search.qml"))
            break;
        default:
            return
        }
        firstPage.value = page
    }

    function loadFirstPage() {
        switch(firstPage.value) {
        default:
        case "PlayingPage":
            pageStack.replace(Qt.resolvedUrl("pages/Playing.qml"))
            break;
        case "NewReleasePage":
            pageStack.replace(Qt.resolvedUrl("pages/NewRelease.qml"))
            break;
        case "MyStuffPage":
            pageStack.replace(Qt.resolvedUrl("pages/MyStuff.qml"))
            break;
        case "TopStuffPage":
            pageStack.replace(Qt.resolvedUrl("pages/TopStuff.qml"))
            break;
        case "SearchPage":
            pageStack.replace(Qt.resolvedUrl("pages/Search.qml"))
            break;
        }
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
            if(!error) {
                playbackStateDeviceId = id
                playbackStateDeviceName = name
            } else
                showErrorMessage(error, qsTr("Transfer Failed"))
        })
    }

    function playTrack(track) {
        Spotify.play({'device_id': deviceId.value, 'uris': [track.uri]}, function(error, data) {
            if(!error) {
                playing = true
                refreshPlayingInfo()
            } else
                showErrorMessage(error, qsTr("Play Failed"))
        })
    }

    function playContext(context) {
        Spotify.play({'device_id': deviceId.value, 'context_uri': context.uri}, function(error, data) {
            if(!error) {
              playing = true
              refreshPlayingInfo()
            } else
                showErrorMessage(error, qsTr("Play Failed"))
        })
    }

    property bool playing
    function pause(callback) {
        if(playing) {
            // pause
            Spotify.pause({}, function(error, data) {
                if(!error)
                    playing = false
                callback(error, data)
            })
        } else {
            // resume
            Spotify.play({}, function(error, data) {
                if(!error)
                    playing = true
                callback(error, data)
            })
        }
    }

    function next(callback) {
        Spotify.skipToNext({}, function(error, data) {
            if(callback)
                callback(error, data)
            refreshPlayingInfo()
        })
    }

    function previous(callback) {
        Spotify.skipToPrevious({}, function(error, data) {
            if(callback)
                callback(error, data)
            refreshPlayingInfo()
        })
    }

    function setRepeat(state, callback) {
        Spotify.setRepeat(state, {}, function(error, data) {
            callback(error, data)
        })
    }

    function setShuffle(state, callback) {
        Spotify.setShuffle(state, {}, function(error, data) {
            callback(error, data)
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

    function newPlayingTrackInfo(track) {
        //item.track_number item.duration_ms
        var uri = track.album.images[0].url
        cover.updateDisplayData(uri, track.name)

        var metaData = {}
        metaData['title'] = track.name
        metaData['album'] = track.album.name
        metaData['artUrl'] = uri
        if(track.artists)
            metaData['artist'] = Util.createItemsString(track.artists, qsTr("no artist known"))
        else
            metaData['artist'] = ''
        mprisPlayer.metaData = metaData
    }

    function refreshPlayingInfo() {
        Spotify.getMyCurrentPlayingTrack({}, function(error, data) {
            if(data)
                newPlayingTrackInfo(data.item)
        })
    }

    property var myDevices: []

    property bool loggedIn: false
    onLoggedInChanged: reloadDevices()

    // using spotify webapi
    function reloadDevices() {
        var i
        //itemsModel.clear()

        myDevices = []
        Spotify.getMyDevices(function(error, data) {
            if(data) {
                try {
                    console.log("number of devices: " + myDevices.length)
                    myDevices = data.devices
                    //refreshDevices()
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getMyDevices")
            }
        })

    }

    Component.onCompleted: {
        spotify.doO2Auth(Spotify._scope, auth_using_browser.value)
        //serviceBrowser.browse("_spotify-connect._tcp")
    }

    property int tokenExpireTime: 0 // in seconds
    Timer  {
        // refresh token on half time
        id: refreshTokenTimer
        interval: tokenExpireTime*1000/2
        running: tokenExpireTime > 0
        repeat: true
        onTriggered: spotify.refreshToken()
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
            tokenExpireTime = spotify.getExpires()
            console.log("expires: " + tokenExpireTime)
            app.connectionText = qsTr("Connected")
            spotify.refreshToken()
            loadUser()
            loggedIn = true
        }

        onLinkedChanged: {
            console.log("Connections.onLinkingChanged")
        }

        onRefreshFinished: {
            console.log("expires: " + tokenExpireTime)
            console.log("Connections.onRefreshFinished")
            console.log("expires: " + tokenExpireTime)
        }

        onOpenBrowser: {
            if(auth_using_browser.value)
                Qt.openUrlExternally(url)
            else
                pageStack.push(Qt.resolvedUrl("components/WebAuth.qml"),
                               {url: url, scale: Screen.widthRatio})
        }

        onCloseBrowser: {
            //pageStack.pop()
            loadFirstPage()
        }
    }

    property var foundDevices: []
    signal devicesChanged()
    onDevicesChanged: {
        firstPage.foundDevicesChanged()
    }

    /* Service Browser has been disabled since it is unknown how to
       register the discovered device at spotify.
    Connections {
        target: serviceBrowser

        onServiceEntryAdded: {
            var serviceJSON = serviceBrowser.getJSON(service)
            console.log("onServiceEntryAdded: " + serviceJSON)
            try {
              var data = JSON.parse(serviceJSON)
              if(data.protocol === "IPv4") {
                  Util.deviceInfoRequest(data, function(error, data) {
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
              }
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
    }*/

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
        app.showConfirmDialog(qsTr("Please confirm to remove:<br><br><b>" + track.name + "</b>"),
                              function() {
            Spotify.removeTracksFromPlaylist(id, playlist.id, [track.uri], function(error, data) {
                callback(error, data)
            })
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

    function isFollowingPlaylist(playlist, callback) {
        Spotify.areFollowingPlaylist(id, playlist.id, [id], function(error, data) {
            callback(error, data)
        })
    }

    function followPlaylist(playlist, callback) {
        Spotify.followPlaylist(id, playlist.id, function(error, data) {
            callback(error, data)
        })
    }

    function unfollowPlaylist(playlist, callback) {
        app.showConfirmDialog(qsTr("Please confirm to unfollow:<br><br><b>" + playlist.name + "</b>"),
                              function() {
            Spotify.unfollowPlaylist(id, playlist.id, function(error, data) {
                callback(error, data)
            })
        })
    }

    function followArtist(artist, callback) {
        Spotify.followArtists([artist.id], function(error, data) {
            callback(error, data)
        })
    }

    function unfollowArtist(artist, callback) {
        app.showConfirmDialog(qsTr("Please confirm to unfollow:<br><br><b>" + artist.name + "</b>"),
                              function() {
            Spotify.unfollowArtists([artist.id], function(error, data) {
                callback(error, data)
            })
        })
    }

    property string mprisServiceName: "hutspot"

    MprisPlayer {
        id: mprisPlayer
        serviceName: mprisServiceName

        property var metaData

        identity: qsTr("Simple Spotify Controller")

        canControl: true

        canPause: playing
        canPlay: !playing

        canGoNext: true
        canGoPrevious: true

        canSeek: false

        playbackStatus: Mpris.Stopped

        onPauseRequested: app.pause(function(error, data){})

        onPlayRequested: app.pause(function(error, data){})

        onPlayPauseRequested: app.pause(function(error, data){})

        onNextRequested: app.next(function(error, data){})

        onPreviousRequested: app.previous(function(error, data){})

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
        return "/usr/share/icons/hicolor/" + iconSize + "x" + iconSize + "/apps/hutspot.png"
    }

    /**
     * can have a 4th param: rejectCallback
     */
    function showConfirmDialog(text, acceptCallback) {
        var dialog = pageStack.push (Qt.resolvedUrl("components/ConfirmDialog.qml"),
                                                   {confirmMessageText: text})
        if(acceptCallback !== null)
            dialog.accepted.connect(acceptCallback)
        if(arguments.length >= 4 && arguments[3] !== null)
            dialog.rejected.connect(arguments[3])
    }

    ConfigurationValue {
            id: deviceId
            key: "/hutspot/device_id"
            defaultValue: ""
    }

    ConfigurationValue {
            id: deviceName
            key: "/hutspot/device_name"
            defaultValue: ""
    }

    ConfigurationValue {
        id: searchLimit
        key: "/hutspot/search_limit"
        defaultValue: 20
    }

    ConfigurationValue {
            id: selected_search_targets
            key: "/hutspot/selected_search_targets"
            defaultValue: 0xFFF
    }

    ConfigurationValue {
            id: auth_using_browser
            key: "/hutspot/auth_using_browser"
            defaultValue: false
    }

    ConfigurationValue {
            id: firstPage
            key: "/hutspot/first_page"
            defaultValue: ""
    }

}

