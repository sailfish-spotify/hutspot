/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    Label {
        id: label
        anchors.centerIn: parent
        text: qsTr("My Cover")
    }

    CoverActionList {
        id: coverAction

        CoverAction {
            iconSource: "image://theme/icon-cover-previous"
            onTriggered: app.previous()
        }

        CoverAction {
            iconSource: "image://theme/icon-cover-pause"
            onTriggered: app.pause()
        }

        CoverAction {
            iconSource: "image://theme/icon-cover-next"
            onTriggered: app.next()
        }

    }
}

