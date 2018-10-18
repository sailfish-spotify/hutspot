/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 * Copyright (C) 2018 Maciej Janiszewski
 *
 * License: MIT
 */


import QtQuick 2.2
import QtGraphicalEffects 1.0
import Sailfish.Silica 1.0

import "../components"
import "../Spotify.js" as Spotify
import "../Util.js" as Util

Page {
    id: playingPage
    objectName: "PlayingPage"

    property string defaultImageSource : "image://theme/icon-l-music"
    property bool showBusy: false
    property string pageHeaderText: qsTr("Playing")
    property string pageHeaderDescription: ""
    property bool showTrackInfo: true

    allowedOrientations: Orientation.All

    Column {
        anchors.fill: parent
        spacing: Theme.paddingLarge

        PageHeader {
            title: pageHeaderText
            description: pageHeaderDescription
            MenuButton {}
        }

        Item {
            width: parent.width
            height: imageItem.height

            Image {
                id: imageItem
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.75
                height: sourceSize.height*(width/sourceSize.width)
                source:  app.controller.getCoverArt(defaultImageSource, showTrackInfo)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                onPaintedHeightChanged: parent.height = Math.min(parent.parent.width, paintedHeight)
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        showTrackInfo = !showTrackInfo
                        app.glassyBackground.showTrackInfo = showTrackInfo
                    }
                }
            }
            DropShadow {
                anchors.fill: imageItem
                radius: 5.0
                samples: 5
                color: "#000"
                source: imageItem
            }
        }

        Item {
            id: infoContainer

            // put MetaInfoPanel in Item to be able to make room for context menu
            width: parent.width
            height: info.height + (cmenu ? cmenu.height : 0)

            MetaInfoPanel {
                id: info
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.top: parent.top
                firstLabelText: getFirstLabelText()
                secondLabelText: getSecondLabelText()
                thirdLabelText: getThirdLabelText()

                isFavorite: app.controller.playlist.isFavorite
                onToggleFavorite: app.controller.playlist.toggleSavedFollowed()
                onFirstLabelClicked: openMenu()
                onSecondLabelClicked: openMenu()
                onThirdLabelClicked: openMenu()
                isCentered: true

                function openMenu() {
                    cmenu.update()
                    cmenu.open(infoContainer)
                }
            }
        }

        ContextMenu {
            id: cmenu

            function update() {
                viewAlbum.enabled = false
                viewArtist.enabled = false
                viewPlaylist.enabled = false
                switch(app.controller.playbackState.getContextType()) {
                case Spotify.ItemType.Album:
                    viewAlbum.enabled = true
                    viewArtist.enabled = true
                    break
                case Spotify.ItemType.Artist:
                    viewArtist.enabled = true
                    break
                case Spotify.ItemType.Playlist:
                    viewPlaylist.enabled = true
                    break
                case Spotify.ItemType.Track:
                    viewAlbum.enabled = true
                    viewArtist.enabled = false
                    break
                }
            }

            MenuItem {
                id: viewAlbum
                text: qsTr("View Album")
                visible: enabled
                onClicked: {
                    switch(app.controller.playbackState.getContextType()) {
                    case Spotify.ItemType.Album:
                        app.pushPage(Util.HutspotPage.Album, {album: app.controller.playbackState.context}, true)
                        break
                    case Spotify.ItemType.Track:
                        app.pushPage(Util.HutspotPage.Album, {album: app.controller.playbackState.item.album}, true)
                        break
                    }
                }
            }
            MenuItem {
                id: viewArtist
                visible: enabled
                text: qsTr("View Artist")
                onClicked: {
                    switch(app.controller.playbackState.getContextType()) {
                    case Spotify.ItemType.Album:
                        app.loadArtist(app.controller.playbackState.contextDetails.artists, true)
                        break
                    case Spotify.ItemType.Artist:
                        app.pushPage(Util.HutspotPage.Artist, {currentArtist: app.controller.playbackState.context}, true)
                        break
                    case Spotify.ItemType.Track:
                        app.loadArtist(app.controller.playbackState.item.artists, true)
                        break
                    }
                }
            }
            MenuItem {
                id: viewPlaylist
                visible: enabled
                text: qsTr("View Playlist")
                onClicked: app.pushPage(Util.HutspotPage.Playlist, {playlist: app.controller.playbackState.context}, true)
            }
        }

        Row {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * Theme.horizontalPageMargin
            height: progressSlider.height
            Label {
                id: progressLabel
                font.pixelSize: Theme.fontSizeSmall
                anchors.verticalCenter: parent.verticalCenter
                text: Util.getDurationString(app.controller.playbackState.progress_ms)
            }
            Slider {
                id: progressSlider
                property bool isPressed: false
                width: parent.width - durationLabel.width - progressLabel.width
                minimumValue: 0
                maximumValue: app.controller.playbackState.item.duration_ms
                handleVisible: false
                onPressed: isPressed = true
                onReleased: {
                    Spotify.seek(Math.round(value), function(error, data) {
                        app.controller.playbackState.progress_ms = Math.round(value)
                     })
                    isPressed = false
                }
                Connections {
                    target: app.controller.playbackState
                    // cannot use 'value: playbackProgress' since press/drag
                    // breaks the link between them
                    onProgress_msChanged: {
                        if(!progressSlider.isPressed)
                            progressSlider.value = app.controller.playbackState.progress_ms
                    }
                }
            }
            Label {
                id: durationLabel
                font.pixelSize: Theme.fontSizeSmall
                anchors.verticalCenter: parent.verticalCenter
                text: Util.getDurationString(app.controller.playbackState.item.duration_ms)
            }
        }

        Rectangle {
            width: 1
            height: Theme.paddingMedium
            color: "transparent"
        }

        Row {
            id: buttonRow
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * Theme.horizontalPageMargin
            property real itemWidth : width / 5

            IconButton {
                width: buttonRow.itemWidth
                icon.source: app.controller.playbackState.shuffle_state
                             ? "image://theme/icon-m-shuffle?" + Theme.highlightColor
                             : "image://theme/icon-m-shuffle"
                onClicked: app.controller.setShuffle(!app.controller.playbackState.shuffle_state)
            }

            IconButton {
                width: buttonRow.itemWidth
                icon.source: "image://theme/icon-m-previous"
                onClicked: app.controller.previous()
            }
            IconButton {
                width: buttonRow.itemWidth
                icon.source: app.controller.playbackState.is_playing
                             ? "image://theme/icon-l-pause"
                             : "image://theme/icon-l-play"
                onClicked: app.controller.playPause()
            }
            IconButton {
                width: buttonRow.itemWidth
                icon.source: "image://theme/icon-m-next"
                onClicked: app.controller.next()
            }
            IconButton {
                Rectangle {
                    visible: app.controller.playbackState.repeat_state === "track"
                    color: Theme.highlightColor
                    anchors {
                        rightMargin: (buttonRow.itemWidth - Theme.iconSizeMedium)/2
                        right: parent.right
                        top: parent.top
                    }
                    width: Theme.iconSizeSmall
                    height: width
                    radius: width/2

                    Label {
                        text: "1"
                        anchors.centerIn: parent
                        color: "#000"
                        font.pixelSize: Theme.fontSizeSmall
                        font.bold: true
                    }
                }

                width: buttonRow.itemWidth
                icon.source: app.controller.playbackState.repeat_state !== "off"
                             ? "image://theme/icon-m-repeat?" + Theme.highlightColor
                             : "image://theme/icon-m-repeat"
                onClicked: app.controller.setRepeat(app.controller.playbackState.nextRepeatState())
            }
        }

        Rectangle {
            width: 1
            height: Theme.paddingMedium
            color: "transparent"
        }

        Item {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * Theme.horizontalPageMargin
            height: spotifyConnectRow.childrenRect.height + Theme.paddingLarge*2
            MouseArea {
                anchors.fill: spotifyConnectRow
                onClicked: pageStack.push(Qt.resolvedUrl("../pages/Devices.qml"))
            }

            Row {
                id: spotifyConnectRow
                y: Theme.paddingLarge
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingMedium
                Image {
                    anchors.verticalCenter: spotifyConnectLabel.verticalCenter
                    source: "image://theme/icon-cover-play"
                }

                Label {
                    id: spotifyConnectLabel
                    text: app.controller.playbackState.device !== undefined ? "Listening on <b>" + app.controller.playbackState.device.name + "</b>" : ""
                }
                visible: app.controller.playbackState.device !== undefined
            }
        }
    }

    function getFirstLabelText() {
        var s = ""
        if(app.controller.playbackState === undefined)
             return s
        if(!app.controller.playbackState.context || showTrackInfo)
            return app.controller.playbackState.item ? app.controller.playbackState.item.name : ""
        if(app.controller.playbackState.context === null)
            return s
        return app.controller.playbackState.contextDetails.name
    }

    function getSecondLabelText() {
        var s = ""
        if(app.controller.playbackState === undefined)
             return s
        if(!app.controller.playbackState.context || showTrackInfo) {
            // no context (a single track?)
            if(app.controller.playbackState.item && app.controller.playbackState.item.album) {
                s += app.controller.playbackState.item.album.name
                if (app.controller.playbackState.item.album.release_date)
                    s += ", " + Util.getYearFromReleaseDate(app.controller.playbackState.item.album.release_date)
            }
            return s
        }
        if(app.controller.playbackState.context === null)
            return s
        switch(app.controller.playbackState.context.type) {
        case 'album':
            s += Util.createItemsString(app.controller.playbackState.contextDetails.artists, qsTr("no artist known"))
            break
        case 'artist':
            s += Util.createItemsString(app.controller.playbackState.contextDetails.genres, qsTr("no genre known"))
            break
        case 'playlist':
            s+= app.controller.playbackState.contextDetails.description
            break
        }
        return s
    }

    function getThirdLabelText() {
        var s = ""
        if(app.controller.playbackState === undefined)
             return s
        if(!app.controller.playbackState.context || showTrackInfo) {
            // no context (a single track?)
            if(app.controller.playbackState.item && app.controller.playbackState.item.artists)
                s += Util.createItemsString(app.controller.playbackState.item.artists, qsTr("no artist known"))
            return s
        }
        if(!app.controller.playbackState.contextDetails)
            return
        switch(app.controller.playbackState.context.type) {
        case 'album':
            if(app.controller.playbackState.contextDetails.tracks)
                s += app.controller.playbackState.contextDetails.tracks.total + " " + qsTr("tracks")
            else if(app.controller.playbackState.contextDetails.album_type === "single")
                s += "1 " + qsTr("track")
            if (app.controller.playbackState.contextDetails.release_date)
                s += ", " + Util.getYearFromReleaseDate(app.controller.playbackState.contextDetails.release_date)
            if(app.controller.playbackState.contextDetails.genres && app.controller.playbackState.contextDetails.genres.lenght > 0)
                s += ", " + Util.createItemsString(app.controller.playbackState.contextDetails.genres, "")
            break
        case 'artist':
            if(app.controller.playbackState.contextDetails.followers && app.controller.playbackState.contextDetails.followers.total > 0)
                s += Util.abbreviateNumber(app.controller.playbackState.contextDetails.followers.total) + " " + qsTr("followers")
            break
        case 'playlist':
            s += app.controller.playbackState.contextDetails.tracks.total + " " + qsTr("tracks")
            s += ", " + qsTr("by") + " " + app.controller.playbackState.contextDetails.owner.display_name
            if(app.controller.playbackState.contextDetails.followers && app.controller.playbackState.contextDetails.followers.total > 0)
                s += ", " + Util.abbreviateNumber(app.controller.playbackState.contextDetails.followers.total) + " " + qsTr("followers")
            if(app.controller.playbackState.context["public"])
                s += ", " +  qsTr("public")
            if(app.controller.playbackState.contextDetails.collaborative)
                s += ", " +  qsTr("collaborative")
            break
        }
        return s
    }


    // try to detect end of playlist play
    Connections {
        target: app.controller.playbackState

        onItemChanged: {
            if (app.controller.playbackState.context) {
                switch (app.controller.playbackState.context.type) {
                    case 'album':
                        pageHeaderDescription = app.controller.playbackState.item.album.name
                        break
                    case 'artist':
                        pageHeaderDescription = app.controller.playbackState.artistsString
                        break
                    case 'playlist':
                        pageHeaderDescription = app.controller.playbackState.contextDetails.name
                        break
                    default:
                        pageHeaderDescription = ""
                        break
                }
            } else {
                pageHeaderDescription = ""
            }
        }
    }

    // The shared DockedPanel needs mouse events
    // and some ListView events
    propagateComposedEvents: true
    onStatusChanged: {
        switch (status) {
        case PageStatus.Active:
            pageStack.pushAttached(
                        Qt.resolvedUrl("PlaybackDetailsPage.qml"), {
                            popOnExit: false
                        })
            break;
        case PageStatus.Activating:
            app.glassyBackground.state = "Visible"
            app.glassyBackground.showTrackInfo = showTrackInfo
            app.dockedPanel.setHidden()
            break;
        case PageStatus.Deactivating:
            app.dockedPanel.resetHidden()
            break;
        case PageStatus.Inactive:
            app.glassyBackground.state = "Hidden"
            break;
        }
    }
}
