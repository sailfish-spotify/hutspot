import QtQuick 2.0
import Sailfish.Silica 1.0

Component {
    Item {
        width: parent.width - 2*Theme.paddingMedium
        x: Theme.paddingMedium
        height: childrenRect.height
        Text {
            width: parent.width
            text: section
            font.bold: true
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.highlightColor
            horizontalAlignment: Text.AlignRight
        }
    }
}
