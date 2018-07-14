import QtQuick 2.0
import Sailfish.Silica 1.0

DockedPanel {
    id: navPanel

    width: parent.width
    height: Theme.itemSizeLarge
    dock: Dock.Bottom
    open: false
    modal: false

    Row {
        anchors.centerIn: parent
        spacing: Theme.paddingLarge

        IconButton {
            icon.source: "image://theme/icon-m-music"
            onClicked: {
                open = false
                app.showPage('PlayingPage')
            }
        }
        IconButton {
            icon.source: "image://theme/icon-m-health"
            onClicked: {
                open = false
                app.showPage('NewReleasePage')
            }
        }
        IconButton {
            icon.source: "image://theme/icon-m-events"
            onClicked: {
                open = false
                app.showPage('MyStuffPage')
            }
        }
        IconButton {
            icon.source: "image://theme/icon-m-search"
            onClicked: {
                open = false
                app.showPage('SearchPage')
            }
        }
    }

    /*MouseArea {
        anchors.fill: parent
        onClicked: {
            console.log("click!")
        }
    }*/

    onOpenChanged: {
        if(!open)
            modal = false
    }

}

