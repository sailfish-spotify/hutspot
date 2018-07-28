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
    property alias start_stop_librespot: start_stop_librespot

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

    function loadFirstPage() {
        pageStack.replace(Qt.resolvedUrl("pages/MainPage.qml"), {}, PageStackAction.Immediate)
        pageStack.pushAttached(Qt.resolvedUrl("pages/Playing.qml"))
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

    signal newPlayingTrackInfo(var track)

    onNewPlayingTrackInfo: {
        //item.track_number item.duration_ms
        var uri = track.album.images[0].url

        var metaData = {}
        metaData['title'] = track.name
        metaData['album'] = track.album.name
        metaData['artUrl'] = uri
        if(track.artists)
            metaData['artist'] = Util.createItemsString(track.artists, qsTr("no artist known"))
        else
            metaData['artist'] = ''
        cover.updateDisplayData(metaData)
        mprisPlayer.metaData = metaData
    }

    function refreshPlayingInfo() {
        Spotify.getMyCurrentPlayingTrack({}, function(error, data) {
            if(data)
                newPlayingTrackInfo(data.item)
        })
    }

    property var myDevices: []

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
        if (!spotify.isLinked()) {
            spotify.doO2Auth(Spotify._scope, auth_using_browser.value)
        } else {
            // with Spotify's stupid short living tokens, we can totally assume
            // it's already expired
            spotify.refreshToken();

            loadFirstPage()
        }

        //serviceBrowser.browse("_spotify-connect._tcp")
    }

    Connections {
        target: librespot
        onServiceEnabledChanged: {
            if(start_stop_librespot.value) {
                if(librespot.serviceEnabled)
                    librespot.start()
            }
        }
    }

    // thanks to harbour-storeman.qml
    Connections {
        target: __quickWindow
        onClosing: {
            if(start_stop_librespot.value) {
                librespot.stop()
            }
        }
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
            loadUser()

            refreshPlayingInfo()
            reloadDevices()
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

    signal detailsChangedOfPlaylist(string playlistId, var playlistDetails)

    function editPlaylistDetails(playlist, callback) {
        var ms = pageStack.push(Qt.resolvedUrl("components/CreatePlaylist.qml"),
                                {titleText: qsTr("Edit Playlist Details"),
                                 name: playlist.name, description: playlist.description,
                                 publicPL: playlist['public'], collaborative: playlist.collaborative} );
        ms.accepted.connect(function() {
            if(ms.name && ms.name.length > 0) {
                var options = {name: ms.name,
                               'public': ms.publicPL,
                               collaborative: ms.collaborativePL}
                if(ms.description && ms.description.length > 0)
                    options.description = ms.description
                Spotify.changePlaylistDetails(id, playlist.id, options, function(error, data) {
                    if(callback)
                        callback(error, data)
                    if(!error)
                        detailsChangedOfPlaylist(playlist.id, options)
                })
            }
        })
    }

    signal addedToPlaylist(string playlistId, string trackId)

    function addToPlaylist(track) {

        var ms = pageStack.push(Qt.resolvedUrl("components/PlaylistPicker.qml"),
                                { label: qsTr("Select a Playlist") } );
        ms.accepted.connect(function() {
            if(ms.selectedItem && ms.selectedItem.playlist) {
                Spotify.addTracksToPlaylist(ms.selectedItem.playlist.owner.id,
                                            ms.selectedItem.playlist.id,
                                            [track.uri], {}, function(error, data) {
                    if(data) {
                        addedToPlaylist(ms.selectedItem.playlist.id, track.id)
                        console.log("addToPlaylist: added \"")
                    } else
                        console.log("addToPlaylist: failed to add \"")
                    console.log(track.name + "\" to \"" + ms.selectedItem.playlist.name + "\"")
                })
            }
        })
    }

    signal removedFromPlaylist(string playlistId, string trackId)

    function removeFromPlaylist(playlist, track, callback) {
        app.showConfirmDialog(qsTr("Please confirm to remove:<br><br><b>" + track.name + "</b>"),
                              function() {
            Spotify.removeTracksFromPlaylist(id, playlist.id, [track.uri], function(error, data) {
                callback(error, data)
                removedFromPlaylist(playlist.id, track.id)
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
                    options.description = ms.description
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
        if(confirm_un_follow_save.value)
            app.showConfirmDialog(qsTr("Please confirm to unfollow playlist:<br><br><b>" + playlist.name + "</b>"),
                                  function() {
                Spotify.unfollowPlaylist(id, playlist.id, function(error, data) {
                    callback(error, data)
                })
            })
        else
            Spotify.unfollowPlaylist(id, playlist.id, function(error, data) {
                callback(error, data)
            })
    }

    function followArtist(artist, callback) {
        Spotify.followArtists([artist.id], function(error, data) {
            callback(error, data)
        })
    }

    function unfollowArtist(artist, callback) {
        if(confirm_un_follow_save.value)
            app.showConfirmDialog(qsTr("Please confirm to unfollow artist:<br><br><b>" + artist.name + "</b>"),
                                  function() {
                Spotify.unfollowArtists([artist.id], function(error, data) {
                    callback(error, data)
                })
            })
        else
            Spotify.unfollowArtists([artist.id], function(error, data) {
                callback(error, data)
            })
    }

    function saveAlbum(album, callback) {
        Spotify.addToMySavedAlbums([album.id], function(error, data) {
            callback(error, data)
        })
    }

    function unSaveAlbum(album, callback) {
        if(confirm_un_follow_save.value)
            app.showConfirmDialog(qsTr("Please confirm to un-save album:<br><br><b>" + album.name + "</b>"),
                                  function() {
                Spotify.removeFromMySavedAlbums([album.id], function(error, data) {
                    callback(error, data)
                })
            })
        else
            Spotify.removeFromMySavedAlbums([album.id], function(error, data) {
                callback(error, data)
            })
    }

    function saveTrack(track, callback) {
        Spotify.addToMySavedTracks([track.id], function(error, data) {
            callback(error, data)
        })
    }

    function unSaveTrack(track, callback) {
        if(confirm_un_follow_save.value)
            app.showConfirmDialog(qsTr("Please confirm to un-save track:<br><br><b>" + track.name + "</b>"),
                                  function() {
                Spotify.removeFromMySavedTracks([track.id], function(error, data) {
                    callback(error, data)
                })
            })
        else
            Spotify.removeFromMySavedTracks([track.id], function(error, data) {
                callback(error, data)
            })
    }

    function toggleSavedTrack(model) {
        if(model.saved)
            unSaveTrack(model.track, function(error,data) {
                if(!error)
                    model.saved = false
            })
        else
            saveTrack(model.track, function(error,data) {
                if(!error)
                    model.saved = true
            })
    }

    function toggleSavedAlbum(album, isAlbumSaved, callback) {
        if(isAlbumSaved)
            unSaveAlbum(album, function(error,data) {
                if(!error)
                    callback(false)
            })
        else
            saveAlbum(album, function(error,data) {
                if(!error)
                    callback(true)
            })
    }

    function toggleFollowArtist(artist, isFollowed, callback) {
        if(isFollowed)
            unfollowArtist(artist, function(error,data) {
                if(data)
                    callback(false)
            })
        else
            followArtist(artist, function(error,data) {
                if(data)
                    callback(true)
            })
    }

    function toggleFollowPlaylist(playlist, isFollowed, callback) {
        if(isFollowed)
             unfollowPlaylist(playlist, function(error, data) {
                 if(data)
                     callback(false)
             })
         else
             followPlaylist(playlist, function(error, data) {
                 if(data)
                     callback(true)
             })
    }

    function loadArtist(artists) {
        if(artists.length > 1) {
            // choose
            var ms = pageStack.push(Qt.resolvedUrl("components/ArtistPicker.qml"),
                                    { label: qsTr("View an Artist"), artists: artists } );
            ms.accepted.connect(function() {
                if(ms.selectedItem) {
                    pageStack.replace(Qt.resolvedUrl("pages/Artist.qml"), {currentArtist: ms.selectedItem.artist})
                }
            })
        } else if(artists.length === 1) {
            pageStack.push(Qt.resolvedUrl("pages/Artist.qml"), {currentArtist:artists[0]})
        }
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

    Librespot {
        id: librespot
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

    ConfigurationValue {
            id: start_stop_librespot
            key: "/hutspot/start_stop_librespot"
            defaultValue: true
    }

    ConfigurationValue {
            id: confirm_un_follow_save
            key: "/hutspot/confirm_un_follow_save"
            defaultValue: true
    }
}

