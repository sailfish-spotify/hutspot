/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    width: parent.width
    height: labelsColumn.height

    property string firstLabelText: ""
    property string secondLabelText: ""
    property string thirdLabelText: ""
    property bool isFavorite: false

    property alias firstLabel: firstLabel
    property alias secondLabel: secondLabel
    property alias thirdLabel: thirdLabel

    signal firstLabelClicked()
    signal secondLabelClicked()
    signal thirdLabelClicked()

    signal toggleFavorite()

    Column {
        id: labelsColumn
        width: parent.width
        spacing: Theme.paddingSmall

        Label {
            id: firstLabel
            color: Theme.highlightColor
            font.bold: true
            truncationMode: TruncationMode.Fade
            width: parent.width
            wrapMode: Text.Wrap
            text: firstLabelText
            MouseArea {
                anchors.fill: parent
                onClicked: firstLabelClicked()
            }
        }

        Row {
            width: parent.width
            height: col2.height

            Column {
                id: col2
                spacing: Theme.paddingSmall
                width: parent.width - savedImage.width
                Label {
                    id: secondLabel
                    color: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    truncationMode: TruncationMode.Fade
                    width: parent.width
                    wrapMode: Text.Wrap
                    visible: text.length > 0
                    text:  secondLabelText
                    MouseArea {
                        anchors.fill: parent
                        onClicked: secondLabelClicked()
                    }
                }
                Label {
                    id: thirdLabel
                    width: parent.width
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.Wrap
                    visible: text.length > 0
                    text: thirdLabelText
                    MouseArea {
                        anchors.fill: parent
                        onClicked: thirdLabelClicked()
                    }
                }
            }
            Image {
                id: savedImage
                //anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                source: isFavorite ? "image://theme/icon-m-favorite-selected" : "image://theme/icon-m-favorite"
                MouseArea {
                     anchors.fill: parent
                     onClicked: toggleFavorite()
                }
            }
        }
    }
}
