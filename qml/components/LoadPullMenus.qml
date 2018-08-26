import QtQuick 2.0
import Sailfish.Silica 1.0

import "../Util.js" as Util

PullDownMenu {
    MenuItem {
        text: qsTr("Reload")
        onClicked: refresh()
    }
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
