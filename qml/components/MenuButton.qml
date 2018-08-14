import QtQuick 2.2
import Sailfish.Silica 1.0

IconButton {
    id: menuIcon

    anchors.verticalCenter: parent._titleItem.verticalCenter
    anchors.right: parent._titleItem.left
    icon.height: Theme.iconSizeSmall
    icon.fillMode: Image.PreserveAspectFit
    icon.source: "image://theme/icon-m-menu"
    //icon.source: "image://hutspot-icons/icon-m-toolbar"

    onClicked: {
        // menu using dialog
        var dialog = pageStack.push(Qt.resolvedUrl("NavigationMenuDialog.qml"), {}, PageStackAction.Immediate)
        dialog.done.connect(function() {
            if(dialog.selectedMenuItem > -1)
                app.doSelectedMenuItem(dialog.selectedMenuItem)
        })

        // menu using docked panel
        /*if(!navPanel.modal && !navPanel.moving) {
            navPanel.open = true
            navPanel.modal = true
        }*/
    }
}
