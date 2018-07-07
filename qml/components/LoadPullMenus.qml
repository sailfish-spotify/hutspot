import QtQuick 2.0
import Sailfish.Silica 1.0


PullDownMenu {
    MenuItem {
        text: qsTr("Load Next Set")
        enabled: canLoadNext
        onClicked: {
            offset += limit
            refresh()
        }
    }
    MenuItem {
        text: qsTr("Load Previous Set")
        enabled: canLoadPrevious
        onClicked: {
            offset -= limit
            refresh()
        }
    }
}
