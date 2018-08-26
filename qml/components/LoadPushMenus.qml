import QtQuick 2.0
import Sailfish.Silica 1.0

PushUpMenu {
    MenuItem {
        text: qsTr("Load Next Set")
        enabled: canLoadNext
        onClicked: loadNext()
    }
    MenuItem {
         text: qsTr("Load Previous Set")
         enabled: canLoadPrevious
         onClicked: loadPrevious()
     }
}
