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
                source:  (playingObject && playingObject.item)
                         ? playingObject.item.album.images[0].url : defaultImageSource
                width: parent.width
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
                        s += ", " + track.album.release_date
                    }
                    return s
                }
            }


            Row {
                Label {
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
                Switch {
                    checked: playbackState ? playbackState.repeat_state : false
                    icon.source: "image://theme/icon-m-repeat"
                    //text: qsTr("Repeat")
                }
                Switch {
                    checked: playbackState ? playbackState.shuffle_state : false
                    icon.source: "image://theme/icon-m-shuffle"
                    //text: qsTr("Shuffle")
                }
            }

            Label {
                truncationMode: TruncationMode.Fade
                width: parent.width
                wrapMode: Text.Wrap
                text:  (playbackState && playbackState.device)
                        ? playbackState.device.name + " (" + playbackState.device.type + ")"
                        : qsTr("unknown")
            }


            Rectangle {
                width: parent.width
                height:Theme.paddingLarge
                opacity: 0
            }

            /*Label {
                truncationMode: TruncationMode.Fade
                width: parent.width
                font.bold: true
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.highlightColor
                horizontalAlignment: Text.AlignRight
                text: qsTr("Tracks")
            }*/

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
                    case 'artist':
                        Spotify.getArtist(cid, {}, function(error, data) {
                            contextObject = data
                        })
                        break
                    case 'playlist':
                        Spotify.getPlaylist(app.id, cid, {}, function(error, data) {
                            contextObject = data
                        })
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

}
