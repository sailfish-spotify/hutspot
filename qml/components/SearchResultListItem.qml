import QtQuick 2.0
import Sailfish.Silica 1.0

import "../Util.js" as Util

Row {
    id: row

    width: parent.width
    //height: column.height
    spacing: Theme.paddingMedium

    Image {
        id: image
        width: height
        height: column.height
        anchors {
            verticalCenter: parent.verticalCenter
        }
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        source: getImageURL(model)
    }


    Column {
        id: column
        //width: parent.width
        //anchors.leftMargin: Theme.paddingMedium
        width: parent.width - image.width - Theme.paddingMedium
        // 'album', 'artist', 'playlist', 'track'

        Label {
            id: nameLabel
            color: Theme.primaryColor
            textFormat: Text.StyledText
            truncationMode: TruncationMode.Fade
            width: parent.width
            text: name ? name : qsTr("No Name")
        }

        Label {
            id: meta1Label
            width: parent.width
            color: Theme.primaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
            truncationMode: TruncationMode.Fade
            text: getMeta1String(model)
            enabled: text.length > 0
            visible: enabled
        }

        Label {
            id: meta2Label
            width: parent.width
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
            textFormat: Text.StyledText
            truncationMode: TruncationMode.Fade
            text: getMeta2String(model)
            enabled: text.length > 0
            visible: enabled
        }
    }

    function getImageURL(model) {
        var images
        switch(type) {
        case 0:
            if(album.images)
                images = album.images
            break;
        case 1:
            if(artist.images)
                images = artist.images
            break;
        case 2:
            if(playlist.images)
                images = playlist.images
            break;
        case 3:
            if(track.images)
                images = track.images
            else if(track.album && track.album.images)
                images = track.album.images
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

    function getMeta1String(model) {
        var items = []
        var ts = ""
        switch(type) {
        case 0:
            if(album.artists)
                items = album.artists
            return createItemsString(items, qsTr("no artist known"))
        case 1:
            if(artist.genres)
                items = artist.genres
            return createItemsString(items, qsTr("no genre known"))
        case 2:
            if(playlist.tracks && playlist.tracks.total)
                ts += qsTr("tracks: ") + playlist.tracks.total
            if(playlist.owner)
                ts += ", " + playlist.owner.display_name
            return ts
        case 3:
            if(track.duration_ms)
                ts += Util.getDurationString(track.duration_ms) + " "
            if(track.artists)
                items = track.artists
            else if(track.album && track.album.artists)
                items = track.album.artists
            return ts + createItemsString(items, qsTr("no artist known"))
        default:
            return ""
        }
    }

    function getMeta2String(model) {
        switch(type) {
        case 0:
            return album.release_date
        case 3:
            if(track.album)
                return track.album.name
            break;
        default:
            return ""
        }
    }

    function createItemsString(items, noneString) {
        if(items.length === 0)
            return noneString
        var i
        var str = ""
        for(i=0;i<items.length;i++) {
            if(i>0)
                str += ", "
            if(items[i].name)
                str += items[i].name
            else
                str += items[i]
        }
        return str
    }

}
