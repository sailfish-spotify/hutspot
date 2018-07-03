import QtQuick 2.0
import Sailfish.Silica 1.0


PullDownMenu {
    MenuItem {
        text: qsTr("Load Next Set")
        enabled: searchString.length >= 1
        onClicked: {
            offset += limit
            refresh()
        }
    }
   MenuItem {
        text: qsTr("Load Previous Set")
        enabled: searchString.length >= 1
                 && offset >= limit
        onClicked: {
            offset -= limit
            refresh()
        }
    }
}
