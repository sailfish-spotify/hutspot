/**
 * Hutspot. 
 * Copyright (C) 2018 Willem-Jan de Hoog
 * Copyright (C) 2018 Maciej Janiszewski
 *
 * License: MIT
 */
 
 import QtQuick 2.0
import Sailfish.Silica 1.0

import "../Util.js" as Util

Row {
    id: row

    property var dataModel

    // not used, same as in AlbumTrackListItem so Loader can be used
    property var isFavorite
    property bool saved
    property var contextType: -1

    signal toggleFavorite()    

    width: parent.width
    //height: column.height
    spacing: Theme.paddingMedium

    opacity: (dataModel.type !== Util.SpotifyItemType.Track
              || Util.isTrackPlayable(dataModel.item)) ? 1.0 : 0.4

    Image {
        id: image
        width: height
        height: column.height
        anchors {
            verticalCenter: parent.verticalCenter
        }
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        source: getImageURL(dataModel)
    }

    Column {
        id: column
        width: parent.width - image.width - favorite.width - 2 * Theme.paddingMedium

        Label {
            id: nameLabel
            color: currentIndex === dataModel.index ? Theme.highlightColor : Theme.primaryColor
            textFormat: Text.StyledText
            truncationMode: TruncationMode.Fade
            width: parent.width
            text: dataModel.name ? dataModel.name : qsTr("No Name")
        }

        Label {
            id: meta1Label
            width: parent.width
            color: currentIndex === dataModel.index ? Theme.highlightColor : Theme.primaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
            truncationMode: TruncationMode.Fade
            text: getMeta1String()
            enabled: text.length > 0
            visible: enabled
        }

        Label {
            id: meta2Label
            width: parent.width
            color: currentIndex === dataModel.index ? Theme.secondaryHighlightColor : Theme.secondaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
            textFormat: Text.StyledText
            truncationMode: TruncationMode.Fade
            text: getMeta2String()
            enabled: text.length > 0
            visible: enabled
        }
    }

    Image {
        id: favorite
        width: height
        height: sourceSize.width > 0 ? Theme.iconSizeSmall : 0
        anchors {
            verticalCenter: parent.verticalCenter
            //bottom: parent.bottom
        }
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        source: (dataModel.following || dataModel.saved)
                ? "image://theme/icon-m-favorite-selected?" : ""
    }

    function getImageURL(dataModel) {
        var images
        switch(dataModel.type) {
        case Util.SpotifyItemType.Album:
        case Util.SpotifyItemType.Artist:
        case Util.SpotifyItemType.Playlist:
            if(dataModel.item.images)
                images = dataModel.item.images
            break;
        case Util.SpotifyItemType.Track:
            if(dataModel.item.images)
                images = dataModel.item.images
            else if(dataModel.item.album && dataModel.item.album.images)
                images = dataModel.item.album.images
            break;
        default:
            return ""
        }
        var url = ""
        if(images) {
            // ToDo look for the best image
            if(images.length >= 2)
                url = images[1].url
            else if(images.length > 0)
                url = images[0].url
            else
                 url = ""
        }
        return url
    }

    function getMeta1String() {
        var sb = new Util.Classes.StringBuilder()
        var items = []
        switch(dataModel.type) {
        case Util.SpotifyItemType.Album:
            if(dataModel.item.artists)
                items = dataModel.item.artists
            sb.append(Util.createItemsString(items, qsTr("no artist known")))
            break
        case Util.SpotifyItemType.Artist:
            if(dataModel.item.genres)
                items = dataModel.item.genres
            sb.append(Util.createItemsString(items, qsTr("no genre known")))
            break
        case Util.SpotifyItemType.Playlist:
            if(dataModel.item.owner.display_name)
                sb.append(dataModel.item.owner.display_name)
            else {
                sb.append(qsTr("Id"))
                sb.append(": ")
                sb.append(dataModel.item.owner.id)
            }
            break
        case Util.SpotifyItemType.Track:
            if(dataModel.item.item)
                items = dataModel.item.artists
            else if(dataModel.item.album && dataModel.item.album.artists)
                items = dataModel.item.album.artists
            sb.append(Util.createItemsString(items, qsTr("no artist known")))
            if(dataModel.item.album) {
                if(dataModel.item.album.name.length === 0)
                    sb.append(qsTr("album not specified")) // should not happen but it does
                else
                    sb.append(dataModel.item.album.name)
            }
            break
        }
        return sb.toString(", ")
    }

    function getMeta2String() {
        var sb = new Util.Classes.StringBuilder()
        switch(dataModel.type) {
        case Util.SpotifyItemType.Album:
            /*if(typeof(dataModel.saved) !== 'undefined') {
               if(dataModel.saved)
                    sb.append("<strong>[" + qsTr("saved") + "]</strong>")
            }*/
            if(dataModel.item)
                sb.append(Util.getYearFromReleaseDate(dataModel.item.release_date))
            break
        case Util.SpotifyItemType.Artist:
            /*if(typeof(dataModel.following) !== 'undefined') {
               if(dataModel.following)
                    sb.append("<strong>[" + qsTr("following") + "]</strong>, ")
            }*/
            if(typeof(dataModel.item.followers) !== 'undefined')
                sb.append(Util.abbreviateNumber(dataModel.item.followers.total) + " " + qsTr("followers"))
            break
        case Util.SpotifyItemType.Playlist:
            /*if(typeof(following) !== 'undefined') {
               if(following)
                   sb.append("<strong>[" + qsTr("following") + "]</strong>, ")
            }*/
            sb.append(dataModel.item.tracks.total + " " + qsTr("tracks"))
            break
        case Util.SpotifyItemType.Track:
            /*if(typeof(dataModel.saved) !== 'undefined') {
               if(dataModel.saved)
                   sb.append("<strong>[" + qsTr("saved") + "]</strong>")
            }*/
            if(dataModel.item.duration_ms)
                sb.append(Util.getDurationString(dataModel.item.duration_ms))
            if(dataModel.played_at && dataModel.played_at.length>0)
                sb.append(qsTr("played at ") + Util.getPlayedAtText(dataModel.played_at))
            if(contextType === Util.SpotifyItemType.Playlist && dataModel.added_at)
                sb.append("@" + Util.getAddedAtText(dataModel.added_at)) // qsTr("added on ")
        }
        return sb.toString(", ")
    }

}
