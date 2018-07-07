/*
 * Copyright (C) 2015-2017 kimmoli <kimmo.lindholm@eke.fi>
 * All rights reserved.
 *
 * This file is part of Maira
 *
 * You may use this file under the terms of BSD license
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: itemPicker

    property ListModel items

    property string label: ""
    property var selected

    SilicaListView {
        id: view

        anchors.fill: parent
        model: items

        VerticalScrollDecorator { flickable: view }

        header: DialogHeader {
            acceptText: qsTr("OK")
            cancelText: qsTr("Cancel")
        }

        delegate: BackgroundItem {
            id: delegateItem

            onClicked: {
                selected = items.get(index)
            }

            SearchResultListItem {
                id: searchResultListItem
            }
        }
    }
}

