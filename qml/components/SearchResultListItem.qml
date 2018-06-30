import QtQuick 2.0
import Sailfish.Silica 1.0

Row {

    width: parent.width
    height: column.height
    spacing: Theme.paddingMedium

    Image {
        id: image
        width: 120
        height: width
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
            id: metaLabel
            width: parent.width
            color: Theme.primaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
            truncationMode: TruncationMode.Fade
            text: getMetaString(model)
            enabled: type === 3
            visible: enabled
        }

        Label {
            id: artistsLabel
            width: parent.width
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
            textFormat: Text.StyledText
            truncationMode: TruncationMode.Fade
            text: getArtistsString(model)
            enabled: type === 3
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
            else
                url = images[0].url
        }
        return url
    }

    function getMetaString(model) {
        if(type !== 3)
            return ""
        if(track.album)
            return track.album.name
    }

    function getArtistsString(model) {
        if(type !== 3)
            return ""
        var i
        var artists = []
        if(track.artists)
            artists = track.artists
        else if(track.album && track.album.artists)
            artists = track.album.artists
        if(artists.length === 0)
            return qStr("no artists known")
        var str = ""
        for(i=0;i<artists.length;i++) {
            if(i>0)
                str += ", "
            str += artists[i].name
        }
        return str
    }
}
