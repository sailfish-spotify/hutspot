/**
 * Hutspot. Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.2
import Sailfish.Silica 1.0

Page {
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            PageHeader {
                title: qsTr("About")
            }

            Item {
                width: parent.width
                height: childrenRect.height

                Image {
                    id: icon

                    anchors.horizontalCenter: parent.horizontalCenter
                    asynchronous: true
                    source: app.getAppIconSource()
                }

                Column {
                    id: appTitleColumn

                    anchors {
                        left: parent.left
                        leftMargin: Theme.horizontalPageMargin
                        right: parent.right
                        rightMargin: Theme.horizontalPageMargin
                        top: icon.bottom
                        topMargin: Theme.paddingMedium
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: Theme.fontSizeLarge
                        text: "hutspot 0.1"
                    }

                    Label {
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTr("Spotify controller for Sailfish OS")
                        width: parent.width
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        horizontalAlignment: implicitWidth > width ? Text.AlignLeft : Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        //: I doubt this needs to be translated
                        text: qsTr("Copyright (C) 2018")
                        truncationMode: TruncationMode.Fade
                        width: parent.width
                    }
                    Label {
                        horizontalAlignment: implicitWidth > width ? Text.AlignLeft : Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        text: qsTr("License: MIT")
                        truncationMode: TruncationMode.Fade
                        width: parent.width
                    }
                    Label {
                        horizontalAlignment: implicitWidth > width ? Text.AlignLeft : Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        text: BUILD_DATE_TIME
                        truncationMode: TruncationMode.Fade
                        width: parent.width
                    }

                }

            }

            SectionHeader {
                text: qsTr("Contributors")
            }

            Label {
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                }
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
                text:
"Willem-Jan de Hoog
Maciej Janiszewski
rgrnetalk"
            }
            SectionHeader {
                text: qsTr("Thanks to")
            }

            Label {
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                }
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
                text:
"Spotify: web api
librespot-org: Librespot
JMPerez: spotify-web-api-js
pipacs: O2
Nathan Osman: qmdnsengine
kimmoli: IconProvider & MultiItemPicker
leszek: DevicePixelRatioHack"
            }
        }

        VerticalScrollDecorator { }
    }

    onStatusChanged: {
        if(status === PageStatus.Activating)
            app.dockedPanel.setHidden()
        else if(status === PageStatus.Deactivating)
            app.dockedPanel.resetHidden()
    }
}
