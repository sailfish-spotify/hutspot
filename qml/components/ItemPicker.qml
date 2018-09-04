/*
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: itemPicker

    property ListModel items
    property int selectedIndex: -1
    property string label: ""


    SilicaListView
    {
        id: view

        anchors.fill: parent
        model: items

        VerticalScrollDecorator { flickable: view }

        header: PageHeader {
            title: label
        }

        delegate: BackgroundItem {
            id: delegateItem

            onClicked: {
                selectedIndex = index
                accept()
            }

            Label {
                x: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - x*2
                wrapMode: Text.Wrap
                text: name
                color: (selectedIndex === index || delegateItem.selected)
                       ? Theme.highlightColor
                       : Theme.primaryColor
            }
        }
    }
}

