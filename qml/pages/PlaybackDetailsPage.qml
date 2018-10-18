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
    objectName: "PlaybackDetailsPage"
    property bool showBusy: false
    property var cursorHelper: app.controller.playlist.cursorHelper

    allowedOrientations: Orientation.All

    Connections {
        target: app.controller.playlist
        onScrollToIndexRequested: {
            listView.positionViewAtIndex(i, ListView.Visible)
        }
    }

    SilicaListView {
        id: listView
        model: app.controller.playlist.model
        anchors.fill: parent
        clip: true

        header: Column {
            anchors.bottomMargin: Theme.paddingLarge
            width: parent.width

            LoadPullMenus {}
            LoadPushMenus {}

            PageHeader {
                width: parent.width
                title: getFirstLabelText(true)
                description: getSecondLabelText(true)
                MenuButton {}
            }

            MetaInfoPanel {
                id: info
                width: parent.width - 2*Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                firstLabelText: getFirstLabelText()
                secondLabelText: getSecondLabelText()
                thirdLabelText: getThirdLabelText()

                isFavorite: app.controller.playlist.isFavorite
                onToggleFavorite: app.controller.playlist.toggleSavedFollowed()
            }

            Row {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*Theme.horizontalPageMargin
                property int buttonCount: viewAlbum.enabled + viewArtist.enabled + viewPlaylist.enabled
                property real buttonWidth: (width - spacing * (buttonCount - 1))/buttonCount
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
                Connections {
                    target: app.controller.playbackState
                    onContextDetailsChanged: update()
                }
                Component.onCompleted: update()
                spacing: Theme.paddingMedium
                Button {
                    id: viewAlbum
                    text: qsTr("View Album")
                    visible: enabled
                    width: parent.buttonWidth
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
                Button {
                    id: viewArtist
                    visible: enabled
                    text: qsTr("View Artist")
                    width: parent.buttonWidth
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
                Button {
                    id: viewPlaylist
                    visible: enabled
                    text: qsTr("View Playlist")
                    width: parent.buttonWidth
                    onClicked: app.pushPage(Util.HutspotPage.Playlist, {playlist: app.controller.playbackState.context}, true)
                }
            }

            Rectangle {
                width: parent.width
                height: Theme.paddingMedium
                opacity: 0
            }

            Separator {
                width: parent.width
                color: Theme.primaryColor
            }

            Rectangle {
                width: parent.width
                height: Theme.paddingMedium
                opacity: 0
            }
        }

        delegate: ListItem {
            id: listItem
            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium
            contentHeight: stype == 0
                           ? Theme.itemSizeExtraSmall
                           : Theme.itemSizeLarge

            Loader {
                id: loader

                width: parent.width

                source: stype > 0
                        ? "../components/SearchResultListItem.qml"
                        : "../components/AlbumTrackListItem.qml"

                Binding {
                  target: loader.item
                  property: "dataModel"
                  value: model
                  when: loader.status == Loader.Ready
                }
                Binding {
                    target: loader.item
                    property: "isFavorite"
                    value: saved
                    when: stype === 0
                }
                Binding {
                    target: loader.item
                    property: "isCurrent"
                    value: track.id === app.controller.playbackState.item.id
                    when: loader.status == Loader.Ready
                }
            }

            menu: AlbumTrackContextMenu {}

            Connections {
                target: loader.item
                onToggleFavorite: app.toggleSavedTrack(model)
            }

            onClicked: app.controller.playTrackInContext(track, app.controller.playbackState.context)
        }

        VerticalScrollDecorator {}
    }

    function refresh() {
        app.controller.playlist.reloadTracks()
    }

    function getFirstLabelText() {
        var s = ""
        if(app.controller.playbackState === undefined)
             return s
        if(!app.controller.playbackState.context)
            return app.controller.playbackState.item ? app.controller.playbackState.item.name : ""
        if(app.controller.playbackState.context === null)
            return s
        return app.controller.playbackState.contextDetails.name
    }

    function getSecondLabelText(header) {
        var s = ""
        if(app.controller.playbackState === undefined)
             return s
        if(!app.controller.playbackState.context) {
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
            if (header)
                return ""
            s+= app.controller.playbackState.contextDetails.description
            break
        }
        return s
    }

    function getThirdLabelText() {
        var s = ""
        if(app.controller.playbackState === undefined)
             return s
        if(!app.controller.playbackState.context) {
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

    function updateGlassBackground() {
        switch(app.controller.playbackState.getContextType()) {
        case Spotify.ItemType.Album:
            app.glassyBackground.showTrackInfo = true
            break
        case Spotify.ItemType.Artist:
            app.glassyBackground.showTrackInfo = true
            break
        case Spotify.ItemType.Playlist:
            app.glassyBackground.showTrackInfo = false
            break
        case Spotify.ItemType.Track:
            app.glassyBackground.showTrackInfo = true
            break
        }

    }

    Connections {
        target: app.controller.playbackState
        onContextDetailsChanged: updateGlassBackground()
    }

    // The shared DockedPanel needs mouse events
    // and some ListView events
    propagateComposedEvents: true
    onStatusChanged: {
        switch (status) {
        case PageStatus.Active:
            // reset transition on glassyBackground
            app.glassyBackground.state = ""
            app.glassyBackground.state = "Visible"
            updateGlassBackground()
            break;
        case PageStatus.Activating:
            app.glassyBackground.state = ""
            app.glassyBackground.state = "Visible"
            app.dockedPanel.setHidden()
            app.dockedPanel.registerListView(listView)
            break;
        case PageStatus.Deactivating:
            app.dockedPanel.unregisterListView(listView)
            break;
        }
    }
}
