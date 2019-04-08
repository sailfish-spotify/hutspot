/**
 * Hutspot. Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */


import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"
import "../Spotify.js" as Spotify

Page {
    id: settingsPage

    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("Register Librespot Credentials")
                onClicked: librespot.registerCredentials()
            }
        }

        PushUpMenu {
            MenuItem {
                text: qsTr("Login")
                onClicked: spotify.doO2Auth(Spotify._scope, app.auth_using_browser.value)
            }
            MenuItem {
                text: qsTr("Refresh Token")
                onClicked: spotify.refreshToken()
            }
        }

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

            TextField {
                id: searchHistoryLimit
                label: qsTr("Maximum size of Search History")
                inputMethodHints: Qt.ImhDigitsOnly
                width: parent.width
                onTextChanged: app.search_history_max_size.value = Math.floor(text)
                validator: IntValidator {bottom: 1; top: 50;}
            }

            TextField {
                id: sortedListLimit
                label: qsTr("Maximum length of Sorted Lists.")
                inputMethodHints: Qt.ImhDigitsOnly
                width: parent.width
                onTextChanged: app.sorted_list_limit.value = Math.floor(text)
                validator: IntValidator {bottom: 1;}
            }

            TextSwitch {
                id: enable_connect_discovery
                text: qsTr("Enable Device Discovery")
                description: qsTr("Discover Spotify Connect Devices on your network.")
                checked: app.enable_connect_discovery.value
                onCheckedChanged: {
                    app.enable_connect_discovery.value = checked
                    app.enable_connect_discovery.sync()
                    if(checked)
                        spConnect.startMDNSService()
                    else
                        spConnect.stopMDNSService()
                }
            }

            TextSwitch {
                id: start_stop_librespot
                text: qsTr("Control Librespot")
                description: qsTr("Start Librespot when launched and stop it on exit")
                checked: app.start_stop_librespot.value
                onCheckedChanged: {
                    app.start_stop_librespot.value = checked
                    app.start_stop_librespot.sync()
                }
            }

            TextSwitch {
                id: launchLibrespot
                text: {
                    if(!librespot.serviceEnabled)
                        return qsTr("Cannot start Librespot")
                    else
                        return librespot.serviceRunning
                                ? qsTr("Stop Librespot")
                                : qsTr("Start Librespot")
                }
                description: {
                    if(!librespot.serviceEnabled)
                        return qsTr("Librespot is not available")
                    else
                        return librespot.serviceRunning
                                ? qsTr("Running")
                                : qsTr("Not Running")
                }
                enabled: librespot.serviceEnabled
                checked: librespot.serviceRunning
                onCheckedChanged: {
                    if(checked) {
                        if(!librespot.serviceRunning)
                            librespot.start()
                    } else
                        librespot.stop()
                }
            }

            TextSwitch {
                id: show_devices_page_at_startup
                text: qsTr("Show Devices page at startup")
                description: qsTr("So you can watch the devices become available")
                checked: app.show_devices_page_at_startup.value
                onCheckedChanged: {
                    app.show_devices_page_at_startup.value = checked
                    app.show_devices_page_at_startup.sync()
                }
            }

            TextField {
                id: hutspotQueueName
                label: qsTr("Hutspot Queue Playlist name")
                width: parent.width
                onTextChanged: {
                    if(text.length > 0) // ToDo: can we cancel an edit?
                        app.hutspot_queue_playlist_name.value = text
                }
            }

            TextField {
                id: country
                placeholderText: label
                label: qsTr("Country Code (2 characters)")
                width: parent.width
                maximumLength: 2
                inputMethodHints: Qt.ImhUppercaseOnly
                onTextChanged: {
                    if(text.length > 0)
                        app.locale_config.country = text
                }
            }

            TextSwitch {
                id: queryForMarket
                text: qsTr("Query for Market")
                description: qsTr("Show only content playable in the country associated with the user account")
                checked: app.query_for_market.value
                onCheckedChanged: {
                    app.query_for_market.value = checked
                    app.query_for_market.sync()
                }
            }

            Slider {
                id: delayPanelSlider
                width: parent.width
                minimumValue: 0
                maximumValue: 2000
                label: qsTr("ControlPanel Show Delay")
                valueText: parseFloat(value/1000).toFixed(1) + "s"
                onReleased: app.controlpanel_show_delay.value = value
            }

            TextSwitch {
                id: confirm_un_follow_save
                text: qsTr("Confirm Un-Save/Follow")
                description: qsTr("Ask for confirmation for un-save and un-follow")
                checked: app.confirm_un_follow_save.value
                onCheckedChanged: {
                    app.confirm_un_follow_save.value = checked
                    app.confirm_un_follow_save.sync()
                }
            }

            ComboBox {
                id: navigation_menu_type
                label: qsTr("Navigation Menu Type")

                menu: ContextMenu {
                    MenuItem { text: qsTr("Page with List of Menu Items") }
                    MenuItem { text: qsTr("Menu Page attached to Playing Page") }
                    MenuItem { text: qsTr("Docked Panel with all Icons") }
                    MenuItem { text: qsTr("Docked Panel with Player Controls and Hamburger button") }
                }

                onCurrentIndexChanged: {
                    app.navigation_menu_type.value = currentIndex
                    app.navigation_menu_type.sync()
                }
            }

            TextSwitch {
                id: playing_as_attached_page
                text: qsTr("Playing as Attached Page")
                description: qsTr("Have the Playing page as an Attached Page (available on the Right)")
                checked: app.playing_as_attached_page.value
                onCheckedChanged: {
                    app.playing_as_attached_page.value = checked
                    app.playing_as_attached_page.sync()
                }
            }

            TextSwitch {
                id: handle_network_connection
                text: qsTr("Handle Network Connection")
                description: qsTr("Detect network connect/disconnect and act on it.")
                checked: app.handle_network_connection.value
                onCheckedChanged: {
                    app.handle_network_connection.value = checked
                    app.handle_network_connection.sync()
                }
            }

            TextSwitch {
                id: auth_using_browser
                text: qsTr("Authorize using Browser")
                description: qsTr("Use external Browser to login at Spotify")
                checked: app.auth_using_browser.value
                onCheckedChanged: {
                    app.auth_using_browser.value = checked
                    app.auth_using_browser.sync()
                }
            }


        }

    }

    Librespot {
        id: librespot
    }

    // The shared DockedPanel needs mouse events
    // and some ListView events
    propagateComposedEvents: true

    onStatusChanged: {
        if(status === PageStatus.Activating)
            app.dockedPanel.setHidden()
        else if(status === PageStatus.Deactivating)
            app.dockedPanel.resetHidden()

        if (status === PageStatus.Activating) {
            searchLimit.text = app.searchLimit.value
            searchHistoryLimit.text = app.search_history_max_size.value
            sortedListLimit.text = app.sorted_list_limit.value
            navigation_menu_type.currentIndex = app.navigation_menu_type.value
            hutspotQueueName.text = app.hutspot_queue_playlist_name.value
            delayPanelSlider.value = app.controlpanel_show_delay.value
            country.text = app.locale_config.country
        }
    }
}

