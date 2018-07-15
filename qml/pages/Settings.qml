/**
 * Donnie. Copyright (C) 2017 Willem-Jan de Hoog
 *
 * License: MIT
 */


import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: settingsPage

    allowedOrientations: Orientation.All


    onStatusChanged: {
        if (status === PageStatus.Activating) {
            searchLimit.text = app.searchLimit.value
            auth_using_browser.checked = app.auth_using_browser.value
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        ListModel { id: items }

        Column {
            id: column
            width: parent.width

            PageHeader { title: qsTr("Settings") }

            TextField {
                id: searchLimit
                label: qsTr("Number of results per request (limit)")
                inputMethodHints: Qt.ImhDigitsOnly
                width: parent.width
                onTextChanged: app.searchLimit.value = Math.floor(text)
                validator: IntValidator {bottom: 1; top: 50;}
            }
            TextSwitch {
                id: auth_using_browser
                text: qsTr("Authorize using Browser")
                description: qsTr("Use external Browser to login at Spotify")
                checked: app.auth_using_browser.value
                onCheckedChanged: {
                    app.auth_using_browser.value = checked;
                    app.auth_using_browser.sync();
                }
            }

        }
    }

}

