import QtQuick 2.0
import org.nemomobile.dbus 2.0

import "../Util.js" as Util

Item {

    //
    // Detect network connect/disconnect using DBus
    //
    property int networkConnected: Util.NetworkState.Unknown
    property var connmanConnections: {"wifi": Util.NetworkState.Unknown, "cellular": Util.NetworkState.Unknown}

    function updateConnection(technology, connected) {
        console.log("updateConnection " + technology + " = " + connected)
        connmanConnections[technology] = connected ? Util.NetworkState.Connected : Util.NetworkState.Disconnected
        var hasConnection = false
        var hasUnknown = false
        for(var tech in connmanConnections) {
            if(connmanConnections[tech] === Util.NetworkState.Connected)
                hasConnection = true
            if(connmanConnections[tech] === Util.NetworkState.Unknown)
                hasUnknown = true
        }
        if(hasConnection)
            networkConnected = Util.NetworkState.Connected
        else if(!hasUnknown)
            networkConnected = Util.NetworkState.Disconnected
    }

    DBusInterface {
        id: connmanWifi

        bus:DBus.SystemBus
        service: 'net.connman'
        iface: 'net.connman.Technology'
        path: '/net/connman/technology/wifi'
        signalsEnabled: true
        function propertyChanged (name, value) {
            console.log("WiFi changed name=%1, value=%2".arg(name).arg(value))
            if(name === "Connected")
                updateConnection("wifi", value)
        }
        onPropertiesChanged: console.log('/net/connman/technology/wifi onPropertiesChanged')
        Component.onCompleted: {
            // result. Connected|Name|Powered|Tethering|TetheringIdentifier|Type
            //         true      "WiFi" true  false     "One"               "wifi"
            connmanWifi.typedCall('GetProperties', [],
                function (result) {
                    console.log('/net/connman/technology/wifi Getproperties: ' + JSON.stringify(result))
                    updateConnection("wifi", result.Connected)
                },
                function () {console.log('/net/connman/technology/wifi GetProperties: ERROR')}
            );
        }
    }

    // ToDo weird but we have to create a whole DBusInterface for the path
    // /net/connman/technology/cellular but it gets the same properties.
    // so maybe the wifi one above is enough. Someone with data will need to verify.
    DBusInterface {
        id: connmanCellular

        bus:DBus.SystemBus
        service: 'net.connman'
        iface: 'net.connman.Technology'
        path: '/net/connman/technology/cellular'
        signalsEnabled: true
        function propertyChanged (name,value) {
            console.log("Cellular changed name=%1, value=%2".arg(name).arg(value))
            if(name === "Connected")
                updateConnection("cellular", value)
        }
        Component.onCompleted: {
            // result. Connected|Name|Powered|Tethering|TetheringIdentifier|Type
            // ToDo. Someone with data should check this
            connmanCellular.typedCall('GetProperties', [],
                function (result) {
                    console.log('/net/connman/technology/cellular GetProperties: ' + JSON.stringify(result))
                    updateConnection("cellular", result.Connected)
                },
                function () {console.log('/net/connman/technology/cellular GetProperties: ERROR')}
            )
        }
    }
}
