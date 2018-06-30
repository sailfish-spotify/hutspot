import QtQuick 2.0
import Sailfish.Silica 1.0

Column {
    width: parent.width

    Label {
        id: nameLabel
        color: Theme.primaryColor
        textFormat: Text.StyledText
        truncationMode: TruncationMode.Fade
        width: parent.width
        text: name ? name : qsTr("No Name")
    }

}
