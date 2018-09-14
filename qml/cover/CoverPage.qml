/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    id: cover

    property string defaultImageSource : "image://theme/icon-m-music"
    property string imageSource : defaultImageSource
    property string titleText : ""
    property string albumText : ""
    property string artistsText : ""

    Column {
        width: parent.width

        Rectangle {
            width: parent.width
            height: Theme.paddingMedium
            opacity: 0
        }

        Item {
            width: parent.width - (Theme.paddingMedium * 2)
            height: width
            x: Theme.paddingMedium

            Image {
                id: image
                width: imageSource === defaultImageSource ? sourceSize.width : parent.width
                height: width
                fillMode: Image.PreserveAspectFit
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                source: imageSource
            }
        }

        /*Text {
            id: titleLabel
            x: titleLabel.width > cover.width
               ? parent.width
               : (parent.width-titleLabel.width) / 2
            text: titleText.length > 0 ? titleText : qsTr("Hutspot")
            horizontalAlignment: titleLabel.width > cover.width
                                 ? Text.AlignLeft
                                 : Text.AlignHCenter
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.primaryColor

            NumberAnimation on x {
                running: cover.status === Cover.Active
                         && titleLabel.width > cover.width
                from: cover.width
                to: -1 * titleLabel.width //+ cover.width)
                loops: Animation.Infinite
                duration: 5000
            }
        }

        Text {
            id: otherLabel
            x: otherLabel.width > cover.width
               ? parent.width
               : (parent.width-otherLabel.width) / 2
            text: artistsText

            horizontalAlignment: otherLabel.width > cover.width
                                 ? Text.AlignLeft
                                 : Text.AlignHCenter
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.primaryColor

            NumberAnimation on x {
                running: cover.status === Cover.Active
                         && otherLabel.width > cover.width
                from: cover.width
                to: -1 * otherLabel.width //+ cover.width)
                loops: Animation.Infinite
                duration: 5000
            }
        }*/

        /*{
            var s = ""
            if(albumText)
                s += albumText
            if(artistsText && artistsText.length > 0)
                s += (s.length > 0 ? ", " : "") + artistsText
            return s
        }*/

        Rectangle {
            width: parent.width
            height: Theme.paddingLarge
            opacity: 0
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.paddingMedium
            /*Image {
                height: Theme.iconSizeSmall
                width: height
                sourceSize.height: Theme.iconSizeSmall
                sourceSize.width: sourceSize.height
                smooth: true
                anchors.verticalCenter: spotifyLabel.verticalCenter
                source: app.getAppIconSource()
            }*/
            Label {
                id: spotifyLabel
                text: qsTr("Hutspot")
            }
        }

        CoverActionList {
            id: coverAction

            CoverAction {
                iconSource: "image://theme/icon-cover-previous"
                onTriggered: app.previous(function(error, data){})
            }

            CoverAction {
                iconSource: app.playing
                            ? "image://theme/icon-cover-pause"
                            : "image://theme/icon-cover-play"
                onTriggered: app.pause(function(error, data){})
            }

            CoverAction {
                iconSource: "image://theme/icon-cover-next"
                onTriggered: app.next(function(error, data){})
            }

        }
    }

    function updateDisplayData(metaData) {
        titleText = metaData['title']
        albumText = metaData['album']
        artistsText = metaData['artist']
        cover.imageSource = metaData['artUrl'] ? metaData['artUrl'] : defaultImageSource
    }
}

