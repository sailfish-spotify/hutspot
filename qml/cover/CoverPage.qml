/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 * Copyright (C) 2018 Maciej Janiszewski
 *
 * License: MIT
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

import "../Util.js" as Util;

CoverBackground {
    id: cover
    property string defaultImageSource: "image://theme/icon-m-music"

    BackgroundItem {
        anchors.fill: parent
        Image {
            id: coverBgImage
            fillMode: Image.PreserveAspectCrop
            anchors.fill: parent
            source: "background.svg"
            sourceSize.width: parent.width
            sourceSize.height: parent.height
            smooth: true
        }
        OpacityRampEffect {
            slope: 1
            offset: 0.15
            opacity: 0.5
            z: 1
            sourceItem: coverBgImage
            direction: OpacityRamp.BottomToTop
        }
        Image {
            anchors.fill: parent
            id: coverImage
            fillMode: Image.PreserveAspectCrop
            visible: source != defaultImageSource
            source: app.controller.getCoverArt(defaultImageSource, app.controller.playbackState)  // TODO: this hack is just bad
        }
        OpacityRampEffect {
            slope: 5.0
            offset: 0.8
            sourceItem: coverImage
            direction: OpacityRamp.TopToBottom
        }
    }

    Rectangle {
        id: titleBackground
        y: playbackInfoColumn.y - Theme.paddingLarge*2
        height: playbackInfoColumn.height + Theme.paddingLarge*2 + Theme.iconSizeLauncher
        width: parent.width
        color: "#000"
        visible: playbackInfoColumn.visible
    }
    OpacityRampEffect {
        slope: 2
        offset: 0.5
        opacity: 0.8
        sourceItem: titleBackground
        direction: OpacityRamp.BottomToTop
    }

    Column {
       id: playbackInfoColumn
       visible: !notPlayingCTA.visible
       spacing: Theme.paddingSmall
       anchors {
           bottom: parent.bottom
           left: parent.left
           right: parent.right
           leftMargin: Theme.paddingLarge
           rightMargin: Theme.paddingLarge
           bottomMargin: Theme.iconSizeLauncher
       }
       Label {
           anchors.left: parent.left
           anchors.right: parent.right
           font.pixelSize: Theme.fontSizeExtraLarge
           wrapMode: Text.WordWrap
           //wrapMode: Text.WrapAtWordBoundaryOrAnywhere
           maximumLineCount: 3
           elide: Text.ElideRight
           text: app.controller.playbackState.item.name
       }
       Label {
           anchors.left: parent.left
           anchors.right: parent.right
           font.pixelSize: Theme.fontSizeLarge
           //wrapMode: Text.WrapAtWordBoundaryOrAnywhere
           maximumLineCount: 2
           elide: Text.ElideRight
           text: Util.createItemsString(app.controller.playbackState.item.artists, "")
           color: Theme.secondaryColor
           visible: text != ""
       }
    }

    Column {
        id: notPlayingCTA
        visible: coverImage.source == defaultImageSource || app.controller.playbackState.id === -1
        spacing: Theme.paddingSmall
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
            leftMargin: Theme.horizontalPageMargin
        }

        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeLarge
            text: qsTr("Nothing is playing")
            wrapMode: Text.WordWrap
        }
        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("Tap here to play something")
            wrapMode: Text.WordWrap
            color: Theme.secondaryColor
        }
    }

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

    /*Image {
        id: image
        width: source === defaultImageSource ? sourceSize.width : parent.width
        height: width
        fillMode: Image.PreserveAspectFit
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        source: app.controller.getCoverArt(defaultImageSource, app.controller.playbackState)  // TODO: this hack is just bad
    }*/

    /*
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
                width: source === defaultImageSource ? sourceSize.width : parent.width
                height: width
                fillMode: Image.PreserveAspectFit
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                source: app.controller.getCoverArt(defaultImageSource, app.controller.playbackState)  // TODO: this hack is just bad
            }
        }

        Rectangle {
            width: parent.width
            height: Theme.paddingLarge
            opacity: 0
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.paddingMedium
            Label {
                id: spotifyLabel
                text: qsTr("Hutspot")
            }
        }

        CoverActionList {
            id: coverAction

            CoverAction {
                iconSource: "image://theme/icon-cover-previous"
                onTriggered: app.controller.previous(function(error, data){})
            }

            CoverAction {
                iconSource: app.controller.playbackState.is_playing
                            ? "image://theme/icon-cover-pause"
                            : "image://theme/icon-cover-play"
                onTriggered: app.controller.playPause(function(error, data){})
            }

            CoverAction {
                iconSource: "image://theme/icon-cover-next"
                onTriggered: app.controller.next(function(error, data){})
            }

        }
    }*/
}

