/**
 * Hutspot. Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

import org.nemomobile.dbus 2.0
import org.hildon.components 1.0
import SystemUtils 1.0

import "../Util.js" as Util

Item {

    property alias serviceEnabled: manager.librespotServiceEnabled
    property alias serviceRunning: librespotUnit.serviceRunning

    /*onLibrespotServiceEnabled: {
        console.log("onLibrespotServiceEnabled: " + librespotServiceEnabled)
    }*/

    onServiceRunningChanged: {
        if(librespot.serviceRunning)
            return
        var ldevName = librespot.getName()
        var device = spotifyController.playbackState.device
        if(device.name !== ldevName)
            return
        // Librespot is not running anymore and was the current device
        // Spotify might transfer playing so pause
        spotifyController.pause()
        showErrorMessage(null, qsTr("Librespot service stopped. Playing is paused."))
    }

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
        return _libreSpotCredentials != null
    }

    Component.onCompleted: loadLibrespotCredentials()

    function loadLibrespotCredentials() {
        var xhr = new XMLHttpRequest;
        xhr.open("GET", StandardPaths.home + "/.cache/librespot/credentials.json");
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

    function addUser(device, callback) {
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
            if(callback)
                callback(error, data)
            if(data)
                console.log("deviceAddUserRequest: " + JSON.stringify(data))
            else
                console.log("deviceAddUserRequest error: " + error)
        })
    }

    //
    // Register credentials with librespot.
    //

    function delayedExec(callback, delay) {
        delayTimer.callback = callback
        delayTimer.interval = delay
        delayTimer.running = true
    }

    Timer {
        id: delayTimer
        running: false
        repeat: false
        property var callback
        onTriggered: callback()
    }

    // ToDo: paths and name are hardcoded
    function addCredentials(username, password, callback) {
        var command = "/usr/bin/librespot"
        var args = []
        args.push("--cache")
        args.push(StandardPaths.home + "/.cache/librespot")
        args.push("--name")
        args.push("librespot")
        args.push("--username")
        args.push(username)
        process.callback = callback
        process.start(command, args)
        process.write(password + "\n")
        process.closeWriteChannel()
        delayedExec(function() {
            // ToDo: don't know if this delay is needed, not if it is enough
            //process.terminate() // SIGTERM
            //process.kill() // SIGKILL
            if(process.state === Processes.Running)
                sysUtil.pkill(process.pid, SystemUtils.SIGINT)
        }, 2000)
    }

    // example output of Librespot on successfull login
    //  INFO:librespot: librespot UNKNOWN (UNKNOWN). Built on 2019-01-03. Build ID: YKCM15nl
    //  Password for xxxxxx: INFO:librespot_core::session: Connecting to AP "gew1-accesspoint-b-437f.ap.spotify.com:4070"
    //  INFO:librespot_core::session: Authenticated as "xxxxxxxxxxxxxx" !
    //  INFO:librespot_core::session: Country: "NL"
    function isSuccess(data) {
        if(!data)
            return false
        return data.indexOf("Authenticated as") > -1
    }

    function registerCredentials() {
        var wasRunning = false
        if(!serviceEnabled) {
            app.showErrorMessage(error, qsTr("Librespot seems not available"))
            return
        }
        if(serviceRunning) {
            wasRunning = true
            stop()
        }

        var dialog = pageStack.push(credentialsDialog)
        dialog.accepted.connect(function() {
            if(dialog.usernameField.text.length > 0
               && dialog.passwordField.text.length > 0) {
                addCredentials(dialog.usernameField.text, dialog.passwordField.text, function(error, exitCode, data){
                    console.log("callback error: " + error + ", exitCode: " + exitCode +", data: " + data)
                    if(exitCode !== 0 || !isSuccess(data)) {
                        app.showErrorMessage(error, qsTr("Failed to register credentials for Librespot"))
                    } else {
                        app.showErrorMessage(null, qsTr("Registered credentials for Librespot"))
                    }
                    if(wasRunning) {
                        start()
                    }
                })
            }
            dialog.rejected.connect(function() {
                if(wasRunning) {
                    start()
                }
            })
        })
    }


    Dialog {
        id: credentialsDialog

        property alias usernameField: usernameField
        property alias passwordField: passwordField

        Column {
            width: parent.width

            DialogHeader {
                title: qsTr("Enter Spotify credentials")
                acceptText: qsTr("OK")
                cancelText: qsTr("Cancel")
            }

            TextField {
                id: usernameField
                width: parent.width
                label: qsTr("Username")
                placeholderText: label

                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: passwordField.focus = true
            }

            PasswordField {
                id: passwordField
                width: parent.width
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: credentialsDialog.accept()
            }
        }
    }

    Process {
        id: process

        property var callback: undefined

        workingDirectory: StandardPaths.home

        onExitCodeChanged: {
            console.log("onExitCodeChanged: " + process.exitCode)
        }

        onStateChanged: {
            console.log("onStateChanged: " + process.state)
        }

        onProcessFinished: {
            console.log("onProcessFinished: " + process.error)
        }

        onError: {
            if(callback !== undefined)
                callback(process.error, process.exitCode, undefined)
            console.log("Librespot Process.Error: " + process.error)
            callback = undefined
        }

        onFinished: {
            var stdout = process.readAllStandardOutput()
            var stderr = process.readAllStandardError()
            console.log("Librespot Process.Finished: " + process.exitStatus + ", code: " + process.exitCode)
            console.log("[stdout]:" + stdout)
            console.log("[stderr]:" + stderr)

            if(callback !== undefined)
                callback(null, process.exitCode, stderr)
            callback = undefined
        }
    }

}
