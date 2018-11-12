import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    id: messagebox
    z: 20

    visible: messageboxVisibility.running
    width: parent.width
    height: col.height
    anchors.centerIn: parent
    onClicked: messageboxVisibility.stop()

    Column {
        id: col
        anchors.top: parent.top
        width: parent.width
        height: contentHeight

        Rectangle {
            height: Theme.paddingSmall
            width: parent.width
            color: Theme.highlightBackgroundColor
        }

        Row {
            width: parent.width
            height: messageboxText.height// + 2*Theme.paddingSmall
            Rectangle {
                width: Theme.paddingSmall
                height: parent.height
                color: Theme.highlightBackgroundColor
            }
            Rectangle {
                color: Qt.rgba(0, 0, 0, 0.6)
                width: parent.width - 2*Theme.paddingSmall
                height: messageboxText.height
                Label {
                     id: messageboxText
                     width: parent.width - 2*Theme.paddingSmall
                     height: contentHeight + 2*Theme.paddingSmall
                     x: Theme.paddingSmall
                     y: Theme.paddingSmall
                     color: Theme.primaryColor
                     wrapMode: Text.Wrap
                }
            }
            Rectangle {
                width: Theme.paddingSmall
                height: parent.height
                color: Theme.highlightBackgroundColor
            }
        }

        Rectangle {
            height: Theme.paddingSmall
            width: parent.width
            color: Theme.highlightBackgroundColor
        }
    }

    function showMessage(message, delay) {
        messageboxText.text = message
        messageboxVisibility.interval = (delay>0) ? delay : 3000
        messageboxVisibility.restart()
    }


    Timer {
        id: messageboxVisibility
        interval: 3000
    }
}
