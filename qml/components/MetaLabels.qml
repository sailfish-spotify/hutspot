/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Column {
    property string firstLabelText: ""
    property string secondLabelText: ""
    property string thirdLabelText: ""

    width: parent.width
    spacing: Theme.paddingSmall

    Label {
        color: Theme.highlightColor
        font.bold: true
        truncationMode: TruncationMode.Fade
        width: parent.width
        wrapMode: Text.Wrap
        text: firstLabelText
    }
    Label {
        color: Theme.primaryColor
        font.pixelSize: Theme.fontSizeSmall
        truncationMode: TruncationMode.Fade
        width: parent.width
        wrapMode: Text.Wrap
        visible: text.length > 0
        text:  secondLabelText
    }
    Label {
        width: parent.width
        font.pixelSize: Theme.fontSizeSmall
        wrapMode: Text.Wrap
        visible: text.length > 0
        text: thirdLabelText
    }
}
