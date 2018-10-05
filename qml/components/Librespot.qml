/**
 * Hutspot. Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.0

import org.nemomobile.dbus 2.0

Item {

    property alias serviceEnabled: manager.librespotServiceEnabled
    property alias serviceRunning: librespotService.serviceRunning

    /*onLibrespotServiceEnabled: {
        console.log("onLibrespotServiceEnabled: " + librespotServiceEnabled)
    }
    onLibrespotServiceRunningChanged: {
        console.log("onLibrespotServiceRunningChanged: " + librespotServiceRunning)
    }*/

    DBusInterface {
        id: librespotService

        property bool serviceRunning: false

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
                    serviceRunning = true
                } else if(activeState === "inactive") {
                    serviceRunning = false
                }
            } else {
                serviceRunning = false
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

        property bool librespotServiceEnabled: false
        property string systemdJob: ""

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

        function restartUnit(unit) {
            typedCall("RestartUnit",
                      [{"type": "s", "value": unit},
                       {"type": "s", "value": "replace"}],
                      function(job) {
                          systemdJob = job
                          updatePath()
                          console.log("manager.RestartUnit: " + job)
                      },
                      function() {
                          updatePath()
                          console.log("manager.RestartUnit failed ")
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

    function start() {
        // when already running we still restart so Librespot will reregister at the Spotify servers
        // so it hopefully appears in the list of available devices
        manager.restartUnit(librespotService.serviceName)
    }

    function stop() {
        manager.stopUnit(librespotService.serviceName)
    }
}
