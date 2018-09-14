import QtQuick 2.0
import Sailfish.Silica 1.0

import "../Util.js" as Util

Row {
    id: row

    property var dataModel

    // not used, same as in AlbumTrackListItem so Loader can be used
    property var isFavorite
    property bool saved
    signal toggleFavorite()

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
        source: getImageURL(dataModel)
    }


    Column {
        id: column
        //width: parent.width
        //anchors.leftMargin: Theme.paddingMedium
        width: parent.width - image.width - Theme.paddingMedium
        // 'album', 'artist', 'playlist', 'track'

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

    function getImageURL(dataModel) {
        var images
        switch(dataModel.type) {
        case 0:
            if(dataModel.album.images)
                images = dataModel.album.images
            break;
        case 1:
            if(dataModel.artist.images)
                images = dataModel.artist.images
            break;
        case 2:
            if(dataModel.playlist.images)
                images = dataModel.playlist.images
            break;
        case 3:
            if(dataModel.track.images)
                images = dataModel.track.images
            else if(dataModel.track.album && dataModel.track.album.images)
                images = dataModel.track.album.images
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
        var items = []
        var ts = ""
        switch(dataModel.type) {
        case 0:
            if(dataModel.album.artists)
                items = dataModel.album.artists
            return Util.createItemsString(items, qsTr("no artist known"))
        case 1:
            if(dataModel.artist.genres)
                items = dataModel.artist.genres
            return Util.createItemsString(items, qsTr("no genre known"))
        case 2:
            if(dataModel.playlist.owner.display_name)
                return dataModel.playlist.owner.display_name
            else
                return qsTr("Id") + ": " + dataModel.playlist.owner.id
        case 3:
            if(dataModel.track.duration_ms)
                ts += Util.getDurationString(dataModel.track.duration_ms) + ", "
            if(dataModel.track.artists)
                items = dataModel.track.artists
            else if(dataModel.track.album && dataModel.track.album.artists)
                items = dataModel.track.album.artists
            return ts + Util.createItemsString(items, qsTr("no artist known"))
        default:
            return ""
        }
    }

    function getMeta2String() {
        var s = "";
        switch(dataModel.type) {
        case 0:
            return Util.getYearFromReleaseDate(dataModel.album.release_date)
        case 1:
            if(typeof(dataModel.following) !== 'undefined') {
               if(dataModel.following)
                   s = qsTr("[following], ")
            }
            if(typeof(dataModel.artist.followers) !== 'undefined')
                s += Util.abbreviateNumber(dataModel.artist.followers.total) + " " + qsTr("followers")
            return s
        case 2:
            /*if(typeof(following) !== 'undefined') {
               if(following)
                   s = qsTr("[following], ")
            }*/
            s += dataModel.playlist.tracks.total + " " + qsTr("tracks")
            return s
        case 3:
            if(dataModel.track.album)
                s += dataModel.track.album.name
            if(dataModel.played_at && dataModel.played_at.length>0)
                s += (s.length>0?", ":"") + qsTr("played at ") + Util.getPlayedAtText(dataModel.played_at)
            return s
        }
        return ""
    }

}
