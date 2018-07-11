import QtQuick 2.0
import Sailfish.Silica 1.0
//import QtWebKit.experimental 1.0

Page {
    id: webAuth

    property alias url: webView.url
    property alias pHeader: pHeader
    property real scale: 1.0
    allowedOrientations: Orientation.All

    PageHeader {
        id: pHeader
        width: parent.width
        title: qsTr("Authorization")
        anchors.horizontalCenter: parent.horizontalCenter
    }

    SilicaWebView {
        id: webView

        y: pHeader.height + Theme.paddingLarge
        width: parent.width - 2*Theme.paddingLarge
        x: parent.x+Theme.paddingLarge
        height: parent.height - pHeader.height - 2*Theme.paddingLarge
        //experimental.preferences.developerExtrasEnabled: true
        //experimental.preferences.navigatorQtObjectEnabled: true

        Component.onCompleted: {
            webAuth.scale = scale
        }
    }
}
