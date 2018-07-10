import QtQuick 2.0
import Sailfish.Silica 1.0
//import QtWebKit.experimental 1.0

Page {
    id: webAuth

    property alias url: webView.url
    property real scale: 1.0
    allowedOrientations: Orientation.All

    SilicaWebView {
        id: webView
        anchors.fill: parent

        //experimental.preferences.developerExtrasEnabled: true
        //experimental.preferences.navigatorQtObjectEnabled: true

        Component.onCompleted: {
            webAuth.scale = scale
        }
    }
}
