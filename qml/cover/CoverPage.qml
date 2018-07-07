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
    property string labelText : ""

    Column {
        width: parent.width

        //anchors.topMargin: Theme.paddingMedium
        //anchors.top: parent.top + Theme.paddingMedium
        // nothing works. try a filler...
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
            id: label
            anchors.left: parent.left
            anchors.right: parent.right
            text: labelText.length > 0 ? labelText : qsTr("PlaySpot")
            horizontalAlignment: Text.AlignHCenter
            //visible: imageSource === defaultImageSource
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.primaryColor

            NumberAnimation on x {
                running: true
                from: parent.width
                to: -1 * label.width
                loops: Animation.Infinite
                duration: 3000
            }
        }
        /*
        NumberAnimation on x { from: 0; to: -text.width; duration: 6000; loops: Animation.Infinite }
        NumberAnimation {
            target: ball
            properties: "x"
            to: anim.xMove
            duration: 20
        }*/
        CoverActionList {
            id: coverAction

            CoverAction {
                iconSource: "image://theme/icon-cover-previous"
                onTriggered: app.previous()
            }

            CoverAction {
                iconSource: app.playing
                            ? "image://theme/icon-cover-pause"
                            : "image://theme/icon-cover-play"
                onTriggered: app.pause()
            }

            CoverAction {
                iconSource: "image://theme/icon-cover-next"
                onTriggered: app.next()
            }

        }
    }

    function updateDisplayData(imageSource, text) {
        cover.imageSource = imageSource ? imageSource : defaultImageSource
        labelText = text
    }
}

