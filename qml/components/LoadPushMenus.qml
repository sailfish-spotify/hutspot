import QtQuick 2.0
import Sailfish.Silica 1.0

PushUpMenu {
    MenuItem {
        text: qsTr("Load Next Set")
        enabled: cursorHelper.canLoadNext
        onClicked: cursorHelper.next()
    }
    MenuItem {
         text: qsTr("Load Previous Set")
         enabled: cursorHelper.canLoadPrevious
         onClicked: cursorHelper.previous()
     }
}
