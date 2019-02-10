import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: navPanel

    property alias secondRow: secondRow

    width: parent ? parent.width : 0
    height: parent ? parent.height : implicitHeight
    implicitHeight: firstRow.height
                    + (secondRow.enabled ? secondRow.height : 0)
                    + (thirdRow.enabled ? thirdRow.height : 0)

    //dock: Dock.Bottom
    //open: false
    //modal: false

    function whenIconClicked() {
        if(app.navigation_menu_type.value === 1) {
            app.dockedPanel.open = false
        }
    }

    Column {
        id: bar
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        property real itemWidth : width / 5

        Row {
            id: firstRow
            width: parent.width
            height: Theme.itemSizeLarge

            IconButton {
                width: bar.itemWidth
                icon.source: "image://theme/icon-m-health"
                onClicked: {
                    whenIconClicked()
                    app.showPage('NewReleasePage')
                }
            }
            IconButton {
                width: bar.itemWidth
                icon.source: "image://theme/icon-m-person" // -events
                onClicked: {
                    whenIconClicked()
                    app.showPage('MyStuffPage')
                }
            }
            IconButton {
                width: bar.itemWidth
                icon.source: "image://theme/icon-m-like"
                onClicked: {
                    whenIconClicked()
                    app.showPage('TopStuffPage')
                }
            }
            IconButton {
                width: bar.itemWidth
                icon.source: "image://theme/icon-m-search"
                onClicked: {
                    whenIconClicked()
                    app.showPage('SearchPage')
                }
            }
            IconButton {
                width: bar.itemWidth
                icon.source: "image://theme/icon-m-ambience"
                onClicked: {
                    whenIconClicked()
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
            height: Theme.itemSizeLarge

            IconButton {
                width: bar.itemWidth
                icon.source: "image://theme/icon-m-music"
                visible: !app.playing_as_attached_page.value
                onClicked: {
                    whenIconClicked()
                    app.showPage('PlayingPage')
                }
            }
            IconButton {
                width: bar.itemWidth
                icon.source: "image://theme/icon-m-backup"
                onClicked: {
                    whenIconClicked()
                    app.showPage('HistoryPage')
                }
            }
            IconButton {
                width: bar.itemWidth
                icon.source: "image://theme/icon-m-acknowledge"
                onClicked: {
                    whenIconClicked()
                    app.showPage('RecommendedPage')
                }
            }
            IconButton {
                width: bar.itemWidth
                icon.source: "image://theme/icon-m-accessory-speaker"
                onClicked: {
                    whenIconClicked()
                    pageStack.push(Qt.resolvedUrl("../pages/Devices.qml"))
                }
            }
        }

        Row {
            id: thirdRow
            height: Theme.itemSizeLarge

            IconButton {
                width: bar.itemWidth
                icon.source: "image://theme/icon-m-developer-mode"
                onClicked: {
                    whenIconClicked()
                    pageStack.push(Qt.resolvedUrl("../pages/Settings.qml"))
                }
            }

            IconButton {
                width: bar.itemWidth
                icon.source: "image://theme/icon-m-question"
                onClicked: {
                    whenIconClicked()
                    app.doSelectedMenuItem(Util.HutspotMenuItem.ShowHelp)
                }
            }

            IconButton {
                width: bar.itemWidth
                icon.source: "image://theme/icon-m-about"
                onClicked: {
                    whenIconClicked()
                    pageStack.push(Qt.resolvedUrl("../pages/About.qml"))
                }
            }
        }
    }

    /*onOpenChanged: {
        if(!open) {
            modal = false
        }
    }*/

}

