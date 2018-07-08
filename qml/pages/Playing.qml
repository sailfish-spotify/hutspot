/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */


import QtQuick 2.2
import Sailfish.Silica 1.0

import "../components"
import "../Spotify.js" as Spotify
import "../Util.js" as Util

Page {
    id: playingPage
    objectName: "PlayingPage"

    property string defaultImageSource : "image://theme/icon-l-music"
    property bool showBusy: false

    property var playingObject
    property var playbackState
    property var contextObject

    property int offset: 0
    property int limit: app.searchLimit.value
    property bool canLoadNext: true
    property bool canLoadPrevious: offset >= limit
    property int currentIndex: -1

    allowedOrientations: Orientation.All

    ListModel {
        id: searchModel
    }

    SilicaListView {
        id: listView
        model: searchModel
        anchors.fill: parent
        anchors.topMargin: 0

        header: Column {
            id: lvColumn

            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium
            anchors.bottomMargin: Theme.paddingLarge
            spacing: Theme.paddingLarge

            PageHeader {
                id: pHeader
                width: parent.width
                title: qsTr("Playing")
                BusyIndicator {
                    id: busyThingy
                    parent: pHeader.extraContent
                    anchors.left: parent.left
                    running: showBusy;
                }
                anchors.horizontalCenter: parent.horizontalCenter
            }

            //LoadPullMenus {}
            //LoadPushMenus {}

            /* playbackState
                  .context type uri
                  .is_playing
                  .progress_ms
                  .item = track
            */

            Image {
                id: imageItem
                anchors.horizontalCenter: parent.horizontalCenter
                source:  (playingObject && playingObject.item)
                         ? playingObject.item.album.images[0].url : defaultImageSource
                width: parent.width / 2
                height: width
                fillMode: Image.PreserveAspectFit
            }

            Label {
                id: nameLabel
                color: Theme.highlightColor
                font.bold: true
                truncationMode: TruncationMode.Fade
                width: parent.width
                wrapMode: Text.Wrap
                text: (playbackState && playbackState.item)
                      ? playbackState.item.name : "none"
            }

            Label {
                id: artistLabel
                color: Theme.primaryColor
                truncationMode: TruncationMode.Fade
                width: parent.width
                wrapMode: Text.Wrap
                text: {
                    var s = ""
                    if(playbackState && playbackState.item) {
                        var track = playbackState.item
                        s += Util.createItemsString(track.artists, qsTr("no artist known"))
                        s += " (" + Util.getYearFromReleaseDate(track.album.release_date) + ")"
                    }
                    return s
                }
            }


            Label {
                width: parent.width
                text:  {
                    var s = ""
                    if(playbackState) {
                        s += playbackState.context.type
                        if(contextObject)
                            s += ": " + contextObject.name
                    }
                    return s
                }
                wrapMode: Text.Wrap
            }

            Label {
                truncationMode: TruncationMode.Fade
                width: parent.width
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.Wrap
                text:  (playbackState && playbackState.device)
                        ? qsTr("on: ") + playbackState.device.name + " (" + playbackState.device.type + ")"
                        : qsTr("none")
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: app.mprisPlayer.canGoPrevious
                    icon.source: "image://theme/icon-m-previous"
                    onClicked: app.previous(function(error,data) {
                        if(!error)
                            refresh()
                    })
                }
                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon.source: app.playing
                                 ? "image://theme/icon-cover-pause"
                                 : "image://theme/icon-cover-play"
                    onClicked: app.pause()
                }
                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: app.mprisPlayer.canGoNext
                    icon.source: "image://theme/icon-m-next"
                    onClicked: app.next(function(error,data) {
                        if(!error)
                            refresh()
                    })
                }
                Switch {
                    checked: playbackState ? playbackState.repeat_state : false
                    icon.source: "image://theme/icon-m-repeat"
                    onClicked: app.setRepeat(checked, function(error,data) {
                        if(!error)
                            refresh()
                    })
                }
                Switch {
                    checked: playbackState ? playbackState.shuffle_state : false
                    icon.source: "image://theme/icon-m-shuffle"
                    onClicked: app.setShuffle(checked, function(error,data) {
                        if(!error)
                            refresh()
                    })
                }
            }

            /*Rectangle {
                width: parent.width
                height:Theme.paddingLarge
                opacity: 0
            }*/

            /*Label {
                truncationMode: TruncationMode.Fade
                width: parent.width
                font.bold: true
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.highlightColor
                horizontalAlignment: Text.AlignRight
                text: qsTr("Tracks")
            }*/
            Separator{}
        }

        delegate: ListItem {
            id: listItem
            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium
            //contentHeight: Theme.itemSizeLarge

            Column {
                width: parent.width
                Label {
                    color: Theme.primaryColor
                    textFormat: Text.StyledText
                    truncationMode: TruncationMode.Fade
                    width: parent.width
                    text: name ? name : qsTr("No Name")
                }

                Label {
                    width: parent.width
                    color: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                    truncationMode: TruncationMode.Fade
                    text: track.track_number + ", " + Util.getDurationString(track.duration_ms)
                    enabled: text.length > 0
                    visible: enabled
                }
            }

            onClicked: app.playTrack(track)
        }

        VerticalScrollDecorator {}

        Label {
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignBottom
            visible: parent.count == 0
            text: qsTr("No tracks found")
            color: Theme.secondaryColor
        }

    }

    Component.onCompleted: refresh()

    function refresh() {
        var i;
        //showBusy = true
        //searchModel.clear()

        Spotify.getMyCurrentPlaybackState({}, function(error, data) {
            if(data) {
                playbackState = data
                if(playbackState.context)
                    var cid = Util.getIdFromURI(playbackState.context.uri)
                    switch(playbackState.context.type) {
                    case 'album':
                        Spotify.getAlbum(cid, {}, function(error, data) {
                            contextObject = data
                        })
                        loadAlbumTracks(cid)
                        break
                    case 'artist':
                        Spotify.getArtist(cid, {}, function(error, data) {
                            contextObject = data
                        })
                        break
                    case 'playlist':
                        Spotify.getPlaylist(app.id, cid, {}, function(error, data) {
                            contextObject = data
                        })
                        loadPlaylistTracks(app.id, cid)
                        break
                    }

            }
        })
        Spotify.getMyCurrentPlayingTrack({}, function(error, data) {
            if(data) {
                playingObject = data
            }
        })

    }

    function loadPlaylistTracks(id, pid) {
        searchModel.clear()
        Spotify.getPlaylistTracks(id, pid, {offset: offset, limit: limit}, function(error, data) {
            if(data) {
                try {
                    console.log("number of PlaylistTracks: " + data.items.length)
                    offset = data.offset
                    for(var i=0;i<data.items.length;i++) {
                        searchModel.append({type: 3,
                                            name: data.items[i].track.name,
                                            track: data.items[i].track})
                    }
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getPlaylistTracks")
            }
        })
    }

    function loadAlbumTracks(id) {
        searchModel.clear()
        Spotify.getAlbumTracks(id,
                               {offset: offset, limit: limit},
                               function(error, data) {
            if(data) {
                try {
                    console.log("number of AlbumTracks: " + data.items.length)
                    offset = data.offset
                    for(var i=0;i<data.items.length;i++) {
                        searchModel.append({type: 3,
                                            name: data.items[i].name,
                                            track: data.items[i]})
                    }
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getAlbumTracks")
            }
        })
    }
}
