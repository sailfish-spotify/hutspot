import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    property string confirmMessageText : ""

    id: confirmDialog
    canAccept: true

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                acceptText: qsTr("OK")
                cancelText: qsTr("Cancel")
                dialog: confirmDialog
            }

            Label {
                id: msgTextArea
                x: Theme.paddingMedium
                width: parent.width - 2*Theme.paddingMedium
                textFormat: Text.RichText
                truncationMode: TruncationMode.Fade
                text: confirmMessageText
                wrapMode: Label.Wrap
            }

        }

        VerticalScrollDecorator{}
    }
}
