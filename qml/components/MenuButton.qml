import QtQuick 2.2
import Sailfish.Silica 1.0

IconButton {
    id: menuIcon

    anchors.verticalCenter: parent._titleItem.verticalCenter
    anchors.right: parent._titleItem.left
    icon.height: Theme.iconSizeSmall
    icon.fillMode: Image.PreserveAspectFit
    icon.source: "image://hutspot-icons/icon-m-toolbar"

    onClicked: {
        if(!navPanel.modal) {
            navPanel.open = true
            navPanel.modal = true
        }
    }
}
