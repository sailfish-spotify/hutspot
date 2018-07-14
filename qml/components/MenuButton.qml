import QtQuick 2.2
import Sailfish.Silica 1.0

IconButton {
    id: menuIcon
    width: icon.width
    height: icon.height

    x: Theme.paddingMedium
    y: Theme.paddingMedium
    icon.height: Theme.iconSizeMedium
    icon.fillMode: Image.PreserveAspectFit
    icon.source: "image://theme/icon-m-menu" /*navPanel.expanded
                 ? "image://theme/icon-m-down"
                 : "image://theme/icon-m-up"*/
    onClicked: {
        if(!navPanel.modal) {
            navPanel.open = true
            navPanel.modal = true
        }
    }
}
