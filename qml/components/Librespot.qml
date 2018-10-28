/**
 * Hutspot. Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.0

import org.nemomobile.dbus 2.0

import "../Util.js" as Util

Item {

    property alias serviceEnabled: manager.librespotServiceEnabled
    property alias serviceRunning: librespotUnit.serviceRunning

    /*onLibrespotServiceEnabled: {
        console.log("onLibrespotServiceEnabled: " + librespotServiceEnabled)
    }
    onLibrespotServiceRunningChanged: {
        console.log("onLibrespotServiceRunningChanged: " + librespotServiceRunning)
    }*/

    DBusInterface {
        id: librespotUnit

        property bool serviceRunning: false

        property string serviceName: "librespot.service"
        bus: DBus.SessionBus
        service: "org.freedesktop.systemd1"
        iface: "org.freedesktop.systemd1.Unit"
        signalsEnabled: true

        function updateState() {
            console.log("librespotUnit.updateState: path=" + path)
            if (path !== "") {
                var activeState = librespotUnit.getProperty("ActiveState")
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

    function getName() {
        return getEnvironmentVariable("DEVICE_NAME")
    }

    function getEnvironmentVariable(name) {
        var i
        if(!librespotService.environment)
            return ""
        for(i=0;i<librespotService.environment.length;i++) {
            var s = librespotService.environment[i].split("=")
            if(s[0] === name)
                return s[1]
        }
        return ""
    }

    DBusInterface {
        id: librespotService

        property var environment: null

        bus: DBus.SessionBus
        service: "org.freedesktop.systemd1"
        iface: "org.freedesktop.systemd1.Service"

        function readServiceProperty(property) {
            if (path !== "") {
                environment = librespotService.getProperty(property)
                console.log(JSON.stringify(environment))
            }
        }

        onPathChanged: {
            if(path !== "") {
                //readServiceProperty("ExecStart")
                readServiceProperty("Environment")
            }
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
            typedCall("GetUnitFileState", [{"type": "s", "value": librespotUnit.serviceName}],
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
            typedCall("GetUnit", [{ "type": "s", "value": librespotUnit.serviceName}],
                      function(unit) {
                          librespotUnit.path = unit
                          librespotService.path = unit
                      },
                      function() {
                          librespotUnit.path = ""
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
                librespotUnit.updateState()
            console.log("onJobRemoved id:" + id  + ", path:" + path + ", unit:" + unit + ", result:" + result)
        }
    }

    function start() {
        // when already running we still restart so Librespot will reregister at the Spotify servers
        // so it hopefully appears in the list of available devices
        manager.restartUnit(librespotUnit.serviceName)
    }

    function stop() {
        manager.stopUnit(librespotUnit.serviceName)
    }

    //
    // Spotify Connect
    //

    property var _libreSpotCredentials: null

    function hasLibrespotCredentials() {
        //if(_libreSpotCredentials == null)
        //    loadLibrespotCredentials()
        return _libreSpotCredentials != null
    }

    Component.onCompleted: loadLibrespotCredentials()

    function loadLibrespotCredentials() {
        var xhr = new XMLHttpRequest;
        xhr.open("GET", "/home/nemo/.cache/librespot/credentials.json");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var response = xhr.responseText;
                console.log(response)
                _libreSpotCredentials = JSON.parse(response)
                spConnect.setCredentials(_libreSpotCredentials.username,
                                         _libreSpotCredentials.auth_type,
                                         _libreSpotCredentials.auth_data)
            }
        }
        xhr.send()
    }

    function addUser(device) {
        var addUserData = {}

        addUserData.action = "addUser"
        addUserData.userName = _libreSpotCredentials.username
        addUserData.blob = spConnect.createBlobToSend(device.remoteName, device.publicKey)
        addUserData.clientKey = spConnect.getPublicKey()
        addUserData.deviceName = playerName
        addUserData.deviceId = spConnect.getDeviceId(app.playerName)
        addUserData.version = "0.1"

        // unfortunately we have nothing better to report.
        // (sometimes it is the same as _libreSpotCredentials.username)
        // Librespot does not use it
        addUserData.loginId = app.id

        Util.deviceAddUserRequest(device.deviceInfo, addUserData, function(error, data) {
            var name = device.name
            if(data)
                console.log("deviceAddUserRequest: " + JSON.stringify(data))
            else {
                console.log("deviceAddUserRequest error: " + error)
                app.showErrorMessage(error, qsTr("Failed to connect to " + name))
            }
        })
    }

}
