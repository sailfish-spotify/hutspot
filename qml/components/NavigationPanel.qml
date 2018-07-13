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
                app.showPage('playing')
            }
        }
        IconButton {
            icon.source: "image://theme/icon-m-health"
            onClicked: {
                open = false
                app.showPage('new')
            }
        }
        IconButton {
            icon.source: "image://theme/icon-m-events"
            onClicked: {
                open = false
                app.showPage('mine')
            }
        }
        IconButton {
            icon.source: "image://theme/icon-m-search"
            onClicked: {
                open = false
                app.showPage('search')
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

