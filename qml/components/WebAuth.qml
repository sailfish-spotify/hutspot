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

    PullDownMenu {
        MenuItem {
            text: qsTr("Close")
            // sometimes onCloseBrowser is not fired so we need another
            // way to continue
            onClicked: app.loadFirstPage()
        }
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

        // copied from webcat to get scaling of Spotify authentication html
        // usable on phone screen
        property variant devicePixelRatio: {//1.5
            if (Screen.width <= 540) return 1.5;
            else if (Screen.width > 540 && Screen.width <= 768) return 2.0;
            else if (Screen.width > 768) return 3.0;
        }
        experimental.customLayoutWidth: width / devicePixelRatio
        experimental.deviceWidth: width / devicePixelRatio
        experimental.overview: true
        experimental.userScripts: [
            Qt.resolvedUrl("DevicePixelRatioHack.js")
        ]
    }
}
