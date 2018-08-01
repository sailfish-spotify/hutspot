/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

import "../Util.js" as Util

CoverBackground {
    id: cover
    Image {
        id: coverImage
        anchors.fill: parent
        source: app.controller.getCoverArt(app.controller.playbackState, "image://theme/icon-m-music")
        fillMode: Image.PreserveAspectCrop
    }

    OpacityRampEffect {
        slope: 1.0
        offset: 0.15
        opacity: 0.5
        sourceItem: coverImage
        direction: OpacityRamp.TopToBottom
    }

    Column {
        spacing: Theme.paddingLarge
        anchors.fill: parent
        anchors.margins: Theme.paddingLarge;
        Label {
            anchors.left: parent.left
            anchors.right: parent.right
            font.pixelSize: Theme.fontSizeExtraLarge
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            maximumLineCount: 6
            elide: Text.ElideRight
            text: app.controller.playbackState.item.name
        }
        Label {
            anchors.left: parent.left
            anchors.right: parent.right
            font.pixelSize: Theme.fontSizeLarge
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            maximumLineCount: 6
            elide: Text.ElideRight
            text: Util.createItemsString(app.controller.playbackState.item.artists, "")
            color: Theme.secondaryColor
            visible: text != ""
        }
        Row {
            spacing: Theme.paddingMedium
            visible: app.controller.playbackState.item.id !== -1
            Image {
                height: Theme.iconSizeSmall
                width: Theme.iconSizeSmall
                sourceSize.width: Theme.iconSizeSmall
                sourceSize.height: Theme.iconSizeSmall
                smooth: true
                anchors.verticalCenter: spotifyLabel.verticalCenter
                source: Qt.resolvedUrl("../pages/spotify.svg")
            }

            Label {
                id: spotifyLabel
                text: "Spotify"
            }
        }

    /*Column {
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

        Text {
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
            /*horizontalAlignment: otherLabel.width > cover.width
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

        CoverActionList {
            id: coverAction
            CoverAction {
                iconSource: "image://theme/icon-cover-previous-song"
                onTriggered: app.controller.previous()
            }

            CoverAction {
                iconSource: app.controller.playbackState.is_playing
                            ? "image://theme/icon-cover-pause"
                            : "image://theme/icon-cover-play"
                onTriggered: app.controller.playPause()
            }

            CoverAction {
                iconSource: "image://theme/icon-cover-next-song"
                onTriggered: app.controller.next()
            }

        }
    }
}

