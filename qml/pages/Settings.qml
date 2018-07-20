/**
 * Donnie. Copyright (C) 2017 Willem-Jan de Hoog
 *
 * License: MIT
 */


import QtQuick 2.0
import Sailfish.Silica 1.0

import org.nemomobile.dbus 2.0

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

            TextSwitch {
                id: launchLibrespot
                text: qsTr("Librespot")
                description: {
                    if(!librespotServiceEnabled)
                        return qsTr("Unavailable")
                    else
                        return librespotServiceRunning
                                ? qsTr("Running")
                                : qsTr("Stopped")
                }
                enabled: librespotServiceEnabled
                checked: librespotServiceRunning
                onCheckedChanged: {
                    if(checked) {
                        if(!librespotServiceRunning)
                            manager.startUnit("librespot.service")
                    } else
                        manager.stopUnit("librespot.service")
                }
            }
        }
    }

    property bool librespotServiceEnabled: false
    property bool librespotServiceRunning: false

    onLibrespotServiceEnabled: {
        console.log("onLibrespotServiceEnabled: " + librespotServiceEnabled)
    }

    onLibrespotServiceRunningChanged: {
        console.log("onLibrespotServiceRunningChanged: " + librespotServiceRunning)
    }

    DBusInterface {
        id: librespotService

        bus: DBus.SessionBus
        service: "org.freedesktop.systemd1"
        iface: "org.freedesktop.systemd1.Unit"
        signalsEnabled: true

        function updateProperties() {
            console.log("librespotService.updateProperties: path=" + path)
            if (path !== "") {
                var activeState = librespotService.getProperty("ActiveState")
                if (activeState === "active" || activeState === "inactive") {
                    //enableSwitch.busy = false
                } else {
                    //enableSwitch.busy = true
                }
                librespotServiceRunning = activeState === "active"
            } else {
                librespotServiceRunning = false
            }
        }

        onPropertiesChanged: updateProperties()
        onPathChanged: {
            manager.subscribe()
            if(path !== "")
                updateProperties()
        }
    }

    DBusInterface {
        id: manager

        bus: DBus.SessionBus
        service: "org.freedesktop.systemd1"
        path: "/org/freedesktop/systemd1"
        iface: "org.freedesktop.systemd1.Manager"
        signalsEnabled: true

        Component.onCompleted: {
            updatePath()
            updateEnabled()
        }

        function startUnit(unit) {
            typedCall("StartUnit",
                      [{"type": "s", "value": unit},
                       {"type": "s", "value": "replace"}],
                function(state) {
                    updatePath()
                    console.log("manager.StartUnit: " + state)
                },
                function() {
                    updatePath()
                    console.log("manager.StartUnit failed ")
                })
        }

        function stopUnit(unit) {
            typedCall("StopUnit",
                      [{"type": "s", "value": unit},
                       {"type": "s", "value": "replace"}],
                function(state) {
                    updatePath()
                    console.log("manager.StopUnit: " + state)
                },
                function() {
                    updatePath()
                    console.log("manager.StopUnit failed ")
                })
        }

        function subscribe() {
            call("Subscribe", undefined)
        }

        function updateEnabled() {
            manager.typedCall("GetUnitFileState", [{"type": "s", "value": "librespot.service"}],
                              function(state) {
                                  // seems to be 'static'
                                  if (state !== "disabled" && state !== "invalid") {
                                      librespotServiceEnabled = true
                                  } else {
                                      librespotServiceEnabled = false
                                  }
                              },
                              function() {
                                  librespotServiceEnabled = false
                              })
        }

        function updatePath() {
            manager.typedCall("GetUnit", [{ "type": "s", "value": "librespot.service"}], function(unit) {
                librespotService.path = unit
            }, function() {
                librespotService.path = ""
            })
        }
    }

    /*Timer {
        id: runningUpdateTimer
        interval: 100
        onTriggered: librespotService.updateProperties()
    }*/
}

