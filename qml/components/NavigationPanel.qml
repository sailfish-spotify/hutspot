import QtQuick 2.0
import Sailfish.Silica 1.0

DockedPanel {
    id: navPanel

    property alias secondRow: secondRow

    width: parent.width
    height: Theme.itemSizeLarge + (secondRow.enabled ? secondRow.height : 0)
    dock: Dock.Bottom
    open: false
    modal: false

    Column {
        id: bar
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        property real itemWidth : width / 5

        Row {
            id: firstRow
            width: parent.width

            IconButton {
                width: bar.itemWidth
                icon.source: "image://theme/icon-m-health"
                onClicked: {
                    open = false
                    app.showPage('NewReleasePage')
                }
            }
            IconButton {
                width: bar.itemWidth
                icon.source: "image://theme/icon-m-person" // -events
                onClicked: {
                    open = false
                    app.showPage('MyStuffPage')
                }
            }
            IconButton {
                width: bar.itemWidth
                icon.source: "image://theme/icon-m-like"
                onClicked: {
                    open = false
                    app.showPage('TopStuffPage')
                }
            }
            IconButton {
                width: bar.itemWidth
                icon.source: "image://theme/icon-m-search"
                onClicked: {
                    open = false
                    app.showPage('SearchPage')
                }
            }
            IconButton {
                width: bar.itemWidth
                icon.source: "image://theme/icon-m-ambience"
                onClicked: {
                    open = false
                    app.showPage('GenreMoodPage')
                }
            }
            /*IconButton {
                id: ib
                icon.source: "image://theme/icon-m-enter-close"
                transform: Rotation {
                    origin.x: ib.width / 2
                    origin.y: ib.height / 2
                    angle: secondRow.visible ? 0 : 180
                }
                onClicked: {
                    secondRow.enabled = !secondRow.enabled
                }
            }*/
        }

        Row {
            id: secondRow

            IconButton {
                width: bar.itemWidth
                icon.source: "image://theme/icon-m-music"
                visible: !app.playing_as_attached_page.value
                onClicked: {
                    open = false
                    app.showPage('PlayingPage')
                }
            }
            IconButton {
                width: bar.itemWidth
                icon.source: "image://theme/icon-m-backup"
                onClicked: {
                    open = false
                    app.showPage('HistoryPage')
                }
            }
            IconButton {
                width: bar.itemWidth
                icon.source: "image://theme/icon-m-acknowledge"
                onClicked: {
                    open = false
                    app.showPage('RecommendedPage')
                }
            }
            IconButton {
                width: bar.itemWidth
                icon.source: "image://theme/icon-m-accessory-speaker"
                onClicked: {
                    open = false
                    pageStack.push(Qt.resolvedUrl("../pages/Devices.qml"))
                }
            }
        }

        Row {
            id: thirdRow

            IconButton {
                width: bar.itemWidth
                icon.source: "image://theme/icon-m-developer-mode"
                onClicked: {
                    open = false
                    pageStack.push(Qt.resolvedUrl("../pages/Settings.qml"))
                }
            }

            IconButton {
                width: bar.itemWidth
                icon.source: "image://theme/icon-m-about"
                onClicked: {
                    open = false
                    pageStack.push(Qt.resolvedUrl("../pages/About.qml"))
                }
            }
        }
    }

    onOpenChanged: {
        if(!open) {
            modal = false
        }
    }

}

