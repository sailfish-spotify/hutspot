/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

import "../Spotify.js" as Spotify
import "../Util.js" as Util

Dialog {
    id: artistPicker

    property string label: ""
    property var selectedItem
    property var artists
    property int currentIndex: -1

    canAccept: false

    ListModel { id: items }

    SilicaListView {
        id: view

        anchors.fill: parent
        model: items

        VerticalScrollDecorator { flickable: view }

        /*header: DialogHeader {
            acceptText: qsTr("OK")
            cancelText: qsTr("Cancel")
        }*/
        header: PageHeader {
            title: qsTr("Choose Artist")
        }

        delegate: ListItem {
            id: delegateItem

            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium
            contentHeight: Theme.itemSizeLarge

            onClicked: {
                selectedItem = items.get(index)
                currentIndex = index
                closeIt()
            }

            SearchResultListItem {
                id: searchResultListItem
                dataModel: model
            }
        }

    }

    onLabelChanged: refresh() // ToDo come up with a better trigger

    function refresh() {
        items.clear()
        for (var i=0;i<artists.length;i++) {
            items.append({type: 1,
                          stype: 0,
                          name: artists[i].name,
                          item: artists[i]});
        }
    }

    function closeIt() {
        // we want the dialog to be removed from the page stack before
        // the caller acts. pop() will make sure the 'done' signal is raised.
        pageStack.pop(undefined, PageStackAction.Immediate)
    }
}

