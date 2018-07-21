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
                                : qsTr("Not Running")
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

    property string systemdJob: ""

    /*onLibrespotServiceEnabled: {
        console.log("onLibrespotServiceEnabled: " + librespotServiceEnabled)
    }
    onLibrespotServiceRunningChanged: {
        console.log("onLibrespotServiceRunningChanged: " + librespotServiceRunning)
    }*/

    DBusInterface {
        id: librespotService

        property string serviceName: "librespot.service"
        bus: DBus.SessionBus
        service: "org.freedesktop.systemd1"
        iface: "org.freedesktop.systemd1.Unit"
        signalsEnabled: true

        function updateState() {
            console.log("librespotService.updateState: path=" + path)
            if (path !== "") {
                var activeState = librespotService.getProperty("ActiveState")
                if (activeState === "active") {
                    librespotServiceRunning = true
                } else if(activeState === "inactive") {
                    librespotServiceRunning = false
                }
            } else {
                librespotServiceRunning = false
            }
        }

        onPropertiesChanged: updateState()
        onPathChanged: {
            if(path !== "")
                updateState()
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
            call("Subscribe", undefined)
            updatePath()
            updateEnabled()
        }

        function startUnit(unit) {
            typedCall("StartUnit",
                      [{"type": "s", "value": unit},
                       {"type": "s", "value": "replace"}],
                      function(job) {
                          systemdJob = job
                          updatePath()
                          console.log("manager.StartUnit: " + job)
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
                      function(job) {
                          systemdJob = job
                          updatePath()
                          console.log("manager.StopUnit: " + job)
                      },
                      function() {
                          updatePath()
                          console.log("manager.StopUnit failed ")
                      })
        }

        function updateEnabled() {
            typedCall("GetUnitFileState", [{"type": "s", "value": librespotService.serviceName}],
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
            typedCall("GetUnit", [{ "type": "s", "value": librespotService.serviceName}],
                      function(unit) {
                          librespotService.path = unit
                      },
                      function() {
                          librespotService.path = ""
                      })
        }

        /*signal unitNew(string unit, string path)
        onUnitNew: {
            console.log("onUnitNew unit:" + unit +", path:" + path)
        }

        signal unitRemoved(string unit, string path)
        onUnitRemoved: {
            console.log("onUnitRemoved unit:" + unit +", path:" + path)
        }*/

        signal jobNew(int id, string path, string unit)
        onJobNew: {
            console.log("onJobNew id:" + id  + ", path:" + path + ", unit:" + unit)
        }

        signal jobRemoved(int id, string path, string unit, string result)
        onJobRemoved: {
            if(systemdJob === path)
                librespotService.updateState()
            console.log("onJobRemoved id:" + id  + ", path:" + path + ", unit:" + unit + ", result:" + result)
        }
    }

}

