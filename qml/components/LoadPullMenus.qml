import QtQuick 2.0
import Sailfish.Silica 1.0

PullDownMenu {
    MenuItem {
        text: qsTr("Reload")
        onClicked: refresh()
    }
    MenuItem {
        text: qsTr("Load Previous Set")
        enabled: cursorHelper.canLoadPrevious
        onClicked: cursorHelper.previous()
    }
    MenuItem {
        text: qsTr("Load Next Set")
        enabled: cursorHelper.canLoadNext
        onClicked: cursorHelper.next()
    }
}
